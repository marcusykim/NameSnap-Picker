interface D1PreparedStatement {
  bind(...values: unknown[]): D1PreparedStatement;
  first<T>(): Promise<T | null>;
  run(): Promise<unknown>;
}

interface D1Database {
  prepare(query: string): D1PreparedStatement;
}

interface Env {
  DB: D1Database;
  SITE_URL: string;
  STRIPE_MONTHLY_PAYMENT_LINK: string;
  STRIPE_LIFETIME_PAYMENT_LINK: string;
  STRIPE_WEBHOOK_SECRET?: string;
}

type Plan = "monthly" | "lifetime";

interface EntitlementRow {
  identity_hash: string;
  plan: Plan;
  active: number;
  stripe_customer_id: string | null;
  subscription_id: string | null;
  checkout_session_id: string | null;
  subscription_status: string | null;
}

interface StripeCheckoutSession {
  id: string;
  status: string | null;
  payment_status: string;
  mode: "payment" | "subscription" | "setup";
  client_reference_id: string | null;
  customer: string | { id: string } | null;
  subscription: string | { id: string } | null;
  metadata: Record<string, string> | null;
}

interface StripeSubscription {
  id: string;
  customer: string | { id: string };
  status: string;
  metadata: Record<string, string>;
}

interface StripeEvent {
  type: string;
  data: { object: Record<string, unknown> };
}

const LOCAL_ORIGINS = new Set(["http://localhost:3000", "http://localhost:4190"]);
const ACTIVE_SUBSCRIPTION_STATES = new Set(["active", "trialing"]);
const IDENTITY_PATTERN = /^[A-Za-z0-9_-]{43,128}$/;

class ApiError extends Error {
  constructor(public status: number, message: string) {
    super(message);
  }
}

function allowedOrigin(request: Request, env: Env) {
  const origin = request.headers.get("Origin");
  if (origin === env.SITE_URL || (origin && LOCAL_ORIGINS.has(origin))) return origin;
  return null;
}

function corsHeaders(origin: string | null) {
  const headers = new Headers({
    "Cache-Control": "no-store",
    "Content-Type": "application/json; charset=utf-8",
    "Vary": "Origin",
  });
  if (origin) {
    headers.set("Access-Control-Allow-Origin", origin);
    headers.set("Access-Control-Allow-Headers", "Content-Type, X-NameSnap-Identity");
    headers.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    headers.set("Access-Control-Max-Age", "86400");
  }
  return headers;
}

function json(status: number, body: Record<string, unknown>, origin: string | null = null) {
  return new Response(JSON.stringify(body), { status, headers: corsHeaders(origin) });
}

function safePlan(value: unknown): Plan | null {
  return value === "monthly" || value === "lifetime" ? value : null;
}

function objectId(value: unknown) {
  if (typeof value === "string") return value;
  if (value && typeof value === "object" && typeof (value as { id?: unknown }).id === "string") {
    return (value as { id: string }).id;
  }
  return null;
}

async function sha256(value: string) {
  const bytes = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(digest), (byte) => byte.toString(16).padStart(2, "0")).join("");
}

async function requestIdentity(request: Request) {
  const token = request.headers.get("X-NameSnap-Identity") ?? "";
  if (!IDENTITY_PATTERN.test(token)) throw new ApiError(400, "This browser session could not be identified.");
  return sha256(token);
}

async function entitlement(env: Env, identity: string) {
  return env.DB.prepare(`
    SELECT identity_hash, plan, active, stripe_customer_id, subscription_id,
           checkout_session_id, subscription_status
    FROM entitlements WHERE identity_hash = ?
  `).bind(identity).first<EntitlementRow>();
}

async function saveEntitlement(env: Env, values: {
  identity: string;
  plan: Plan;
  active: boolean;
  customerId?: string | null;
  subscriptionId?: string | null;
  checkoutSessionId?: string | null;
  subscriptionStatus?: string | null;
}) {
  await env.DB.prepare(`
    INSERT INTO entitlements (
      identity_hash, plan, active, stripe_customer_id, subscription_id,
      checkout_session_id, subscription_status, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, unixepoch(), unixepoch())
    ON CONFLICT(identity_hash) DO UPDATE SET
      plan = excluded.plan,
      active = excluded.active,
      stripe_customer_id = COALESCE(excluded.stripe_customer_id, entitlements.stripe_customer_id),
      subscription_id = COALESCE(excluded.subscription_id, entitlements.subscription_id),
      checkout_session_id = COALESCE(excluded.checkout_session_id, entitlements.checkout_session_id),
      subscription_status = COALESCE(excluded.subscription_status, entitlements.subscription_status),
      updated_at = unixepoch()
  `).bind(
    values.identity,
    values.plan,
    values.active ? 1 : 0,
    values.customerId ?? null,
    values.subscriptionId ?? null,
    values.checkoutSessionId ?? null,
    values.subscriptionStatus ?? null,
  ).run();
}

async function refreshEntitlement(env: Env, identity: string) {
  const row = await entitlement(env, identity);
  if (!row || row.active !== 1) return { active: false, plan: null };
  return { active: true, plan: row.plan, subscriptionStatus: row.subscription_status };
}

async function readJson(request: Request) {
  try {
    return await request.json() as Record<string, unknown>;
  } catch {
    throw new ApiError(400, "The request could not be read.");
  }
}

async function startCheckout(request: Request, env: Env, identity: string) {
  const body = await readJson(request);
  const plan = safePlan(body.plan);
  if (!plan) throw new ApiError(400, "Choose a valid NameSnap plan.");
  const paymentLink = plan === "monthly" ? env.STRIPE_MONTHLY_PAYMENT_LINK : env.STRIPE_LIFETIME_PAYMENT_LINK;
  if (!paymentLink?.startsWith("https://buy.stripe.com/")) throw new ApiError(503, "NameSnap checkout is not available yet.");
  const url = new URL(paymentLink);
  url.searchParams.set("client_reference_id", identity);
  return { url: url.toString() };
}

function hexBytes(value: string) {
  if (!/^[a-f0-9]+$/i.test(value) || value.length % 2) return null;
  return new Uint8Array(value.match(/.{2}/g)!.map((pair) => Number.parseInt(pair, 16)));
}

function constantTimeEqual(left: Uint8Array, right: Uint8Array) {
  if (left.length !== right.length) return false;
  let difference = 0;
  for (let index = 0; index < left.length; index += 1) difference |= left[index] ^ right[index];
  return difference === 0;
}

async function verifyWebhook(payload: string, signatureHeader: string, secret: string) {
  const fields = signatureHeader.split(",").map((field) => field.split("=", 2));
  const timestamp = fields.find(([key]) => key === "t")?.[1];
  const signatures = fields.filter(([key]) => key === "v1").map(([, value]) => value);
  if (!timestamp || !signatures.length || Math.abs(Date.now() / 1000 - Number(timestamp)) > 300) return false;

  const key = await crypto.subtle.importKey("raw", new TextEncoder().encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const digest = new Uint8Array(await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(`${timestamp}.${payload}`)));
  return signatures.some((signature) => {
    const candidate = hexBytes(signature);
    return candidate ? constantTimeEqual(digest, candidate) : false;
  });
}

async function handleWebhook(request: Request, env: Env) {
  if (!env.STRIPE_WEBHOOK_SECRET) throw new ApiError(503, "Webhook is not configured.");
  const payload = await request.text();
  const signature = request.headers.get("Stripe-Signature") ?? "";
  if (!await verifyWebhook(payload, signature, env.STRIPE_WEBHOOK_SECRET)) throw new ApiError(400, "Invalid webhook signature.");
  const event = JSON.parse(payload) as StripeEvent;
  const object = event.data.object;

  if (event.type === "checkout.session.completed" || event.type === "checkout.session.async_payment_succeeded") {
    const session = object as unknown as StripeCheckoutSession;
    const identity = session.client_reference_id ?? session.metadata?.namesnap_identity;
    const plan = safePlan(session.metadata?.namesnap_plan) ?? (session.mode === "subscription" ? "monthly" : session.mode === "payment" ? "lifetime" : null);
    const paid = plan === "lifetime" ? session.payment_status === "paid" : session.status === "complete";
    if (identity && /^[a-f0-9]{64}$/.test(identity) && plan && paid) {
      const current = await entitlement(env, identity);
      if (current?.plan === "lifetime" && current.active === 1 && plan === "monthly") return json(200, { received: true });
      await saveEntitlement(env, {
        identity,
        plan,
        active: true,
        customerId: objectId(session.customer),
        subscriptionId: objectId(session.subscription),
        checkoutSessionId: session.id,
      });
    }
  }

  if (["customer.subscription.created", "customer.subscription.updated", "customer.subscription.deleted"].includes(event.type)) {
    const subscription = object as unknown as StripeSubscription;
    let identity = subscription.metadata?.namesnap_identity;
    if (!identity) {
      const row = await env.DB.prepare("SELECT identity_hash FROM entitlements WHERE subscription_id = ?")
        .bind(subscription.id).first<{ identity_hash: string }>();
      identity = row?.identity_hash;
    }
    if (identity && /^[a-f0-9]{64}$/.test(identity)) {
      const current = await entitlement(env, identity);
      if (current?.plan === "lifetime" && current.active === 1) return json(200, { received: true });
      await saveEntitlement(env, {
        identity,
        plan: "monthly",
        active: ACTIVE_SUBSCRIPTION_STATES.has(subscription.status),
        customerId: objectId(subscription.customer),
        subscriptionId: subscription.id,
        subscriptionStatus: subscription.status,
      });
    }
  }

  return json(200, { received: true });
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    try {
      if (url.pathname === "/webhook" && request.method === "POST") return await handleWebhook(request, env);
      if (!url.pathname.startsWith("/api/")) return json(404, { error: "Not found." });

      const origin = allowedOrigin(request, env);
      if (!origin) throw new ApiError(403, "This request origin is not allowed.");
      if (request.method === "OPTIONS") return new Response(null, { status: 204, headers: corsHeaders(origin) });
      const identity = await requestIdentity(request);

      if (url.pathname === "/api/status" && request.method === "GET") {
        return json(200, await refreshEntitlement(env, identity), origin);
      }
      if (url.pathname === "/api/checkout" && request.method === "POST") {
        return json(200, await startCheckout(request, env, identity), origin);
      }
      return json(404, { error: "Not found." }, origin);
    } catch (error) {
      const status = error instanceof ApiError ? error.status : 500;
      const message = error instanceof ApiError ? error.message : "NameSnap checkout is temporarily unavailable. Please try again.";
      if (!(error instanceof ApiError)) console.error("NameSnap Worker request failed", error);
      return json(status, { error: message }, allowedOrigin(request, env));
    }
  },
};
