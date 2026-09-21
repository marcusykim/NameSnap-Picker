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
  FIREBASE_PROJECT_ID: string;
  STRIPE_WEBHOOK_SECRET?: string;
  STRIPE_RESTRICTED_KEY?: string;
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
  account_hash: string | null;
  email_hash: string | null;
}

interface StripeCheckoutSession {
  id: string;
  status: string | null;
  payment_status: string;
  mode: "payment" | "subscription" | "setup";
  url?: string | null;
  expires_at?: number;
  client_reference_id: string | null;
  customer: string | { id: string } | null;
  subscription: string | { id: string } | null;
  metadata: Record<string, string> | null;
  customer_details?: { email?: string | null } | null;
}

interface CheckoutReservation {
  email_hash: string;
  owner_hash: string;
  plan: Plan;
  generation: string;
  session_id: string | null;
  expires_at: number;
  customer_id: string | null;
  identity_hash: string | null;
  buyer_identity: string | null;
  account_hash: string | null;
  first_attempt_at: number | null;
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

interface FirebaseUser {
  uid: string;
  email: string;
}

interface RequestContext {
  identity: string;
  accountHash: string | null;
  emailHash: string | null;
  email: string | null;
}

const LOCAL_ORIGINS = new Set(["http://localhost:3000", "http://localhost:4190"]);
const ACTIVE_SUBSCRIPTION_STATES = new Set(["active", "trialing"]);
const IDENTITY_PATTERN = /^[A-Za-z0-9_-]{43,128}$/;
const BROWSER_REFERENCE_PATTERN = /^b_([a-f0-9]{64})$/;
const ACCOUNT_REFERENCE_PATTERN = /^a_([a-f0-9]{64})$/;
let firebaseJwksCache: { expiresAt: number; keys: Record<string, JsonWebKey> } | null = null;

class ApiError extends Error {
  constructor(public status: number, message: string) {
    super(message);
  }
}

const CHECKOUT_CHANGED = Symbol("checkout changed");

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
    headers.set("Access-Control-Allow-Headers", "Authorization, Content-Type, X-NameSnap-Identity");
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

function base64UrlBytes(value: string) {
  const padded = value.replace(/-/g, "+").replace(/_/g, "/").padEnd(Math.ceil(value.length / 4) * 4, "=");
  const decoded = atob(padded);
  return Uint8Array.from(decoded, (character) => character.charCodeAt(0));
}

function base64UrlJson<T>(value: string) {
  return JSON.parse(new TextDecoder().decode(base64UrlBytes(value))) as T;
}

async function firebaseJwks() {
  if (firebaseJwksCache && firebaseJwksCache.expiresAt > Date.now()) return firebaseJwksCache.keys;
  const response = await fetch("https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com");
  if (!response.ok) throw new ApiError(503, "Purchase accounts are temporarily unavailable.");
  const payload = await response.json() as { keys?: (JsonWebKey & { kid?: string })[] };
  const keys = Object.fromEntries((payload.keys ?? []).flatMap((key) => typeof key.kid === "string" ? [[key.kid, key]] : []));
  if (!Object.keys(keys).length) throw new ApiError(503, "Purchase accounts are temporarily unavailable.");
  const maxAge = Number(response.headers.get("Cache-Control")?.match(/max-age=(\d+)/)?.[1] ?? 3600);
  firebaseJwksCache = { keys, expiresAt: Date.now() + Math.max(300, maxAge) * 1000 };
  return keys;
}

async function verifiedFirebaseUser(request: Request, env: Env): Promise<FirebaseUser | null> {
  const authorization = request.headers.get("Authorization") ?? "";
  if (!authorization.startsWith("Bearer ")) return null;
  const token = authorization.slice(7);
  const parts = token.split(".");
  if (parts.length !== 3) throw new ApiError(401, "Sign in again to manage this purchase.");

  const header = base64UrlJson<{ alg?: string; kid?: string }>(parts[0]);
  const claims = base64UrlJson<{ aud?: string; iss?: string; sub?: string; exp?: number; email?: string; email_verified?: boolean }>(parts[1]);
  if (header.alg !== "RS256" || !header.kid || claims.aud !== env.FIREBASE_PROJECT_ID ||
      claims.iss !== `https://securetoken.google.com/${env.FIREBASE_PROJECT_ID}` ||
      !claims.sub || claims.sub.length > 128 || !claims.exp || claims.exp * 1000 <= Date.now() ||
      !claims.email || claims.email_verified !== true) {
    throw new ApiError(401, "Verify your purchase email and try again.");
  }

  const jwk = (await firebaseJwks())[header.kid];
  if (!jwk) {
    firebaseJwksCache = null;
    throw new ApiError(401, "Sign in again to manage this purchase.");
  }
  const key = await crypto.subtle.importKey("jwk", jwk, { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["verify"]);
  const verified = await crypto.subtle.verify(
    "RSASSA-PKCS1-v1_5",
    key,
    base64UrlBytes(parts[2]),
    new TextEncoder().encode(`${parts[0]}.${parts[1]}`),
  );
  if (!verified) throw new ApiError(401, "Sign in again to manage this purchase.");
  return { uid: claims.sub, email: claims.email.trim().toLocaleLowerCase() };
}

async function requestContext(request: Request, env: Env): Promise<RequestContext> {
  const token = request.headers.get("X-NameSnap-Identity") ?? "";
  if (!IDENTITY_PATTERN.test(token)) throw new ApiError(400, "This browser session could not be identified.");
  const identity = await sha256(token);
  const user = await verifiedFirebaseUser(request, env);
  return {
    identity,
    accountHash: user ? await sha256(user.uid) : null,
    emailHash: user ? await sha256(user.email) : null,
    email: user?.email ?? null,
  };
}

async function entitlement(env: Env, identity: string) {
  return env.DB.prepare(`
    SELECT identity_hash, plan, active, stripe_customer_id, subscription_id,
           checkout_session_id, subscription_status, account_hash, email_hash
    FROM entitlements WHERE identity_hash = ?
  `).bind(identity).first<EntitlementRow>();
}

async function entitlementByAccount(env: Env, accountHash: string) {
  return env.DB.prepare(`
    SELECT identity_hash, plan, active, stripe_customer_id, subscription_id,
           checkout_session_id, subscription_status, account_hash, email_hash
    FROM entitlements WHERE account_hash = ?
  `).bind(accountHash).first<EntitlementRow>();
}

async function entitlementByEmail(env: Env, emailHash: string) {
  return env.DB.prepare(`
    SELECT identity_hash, plan, active, stripe_customer_id, subscription_id,
           checkout_session_id, subscription_status, account_hash, email_hash
    FROM entitlements WHERE email_hash = ?
  `).bind(emailHash).first<EntitlementRow>();
}

async function resolveEntitlement(env: Env, context: RequestContext) {
  if (!context.accountHash) return entitlement(env, context.identity);

  const accountRow = await entitlementByAccount(env, context.accountHash);
  if (accountRow) return accountRow;

  const browserRow = await entitlement(env, context.identity);
  if (context.emailHash) {
    const emailRow = await entitlementByEmail(env, context.emailHash);
    if (emailRow && (!emailRow.account_hash || emailRow.account_hash === context.accountHash)) {
      if (!emailRow.account_hash) {
        await env.DB.prepare("UPDATE entitlements SET account_hash = ?, updated_at = unixepoch() WHERE identity_hash = ? AND account_hash IS NULL")
          .bind(context.accountHash, emailRow.identity_hash).run();
      }
      return { ...emailRow, account_hash: context.accountHash };
    }
  }

  // Never bind a guest receipt to a different verified email on a shared browser.
  if (browserRow?.active === 1 && !browserRow.account_hash && !browserRow.email_hash) {
    await env.DB.prepare("UPDATE entitlements SET account_hash = ?, email_hash = ?, updated_at = unixepoch() WHERE identity_hash = ? AND account_hash IS NULL")
      .bind(context.accountHash, context.emailHash, browserRow.identity_hash).run();
    return { ...browserRow, account_hash: context.accountHash, email_hash: context.emailHash };
  }

  // A browser can be shared. Once an entitlement is bound to a purchase
  // account, signing into a different account on that browser must not expose
  // the previous purchaser's access.
  return browserRow?.account_hash === context.accountHash ? browserRow : null;
}

async function saveEntitlement(env: Env, values: {
  identity: string;
  plan: Plan;
  active: boolean;
  customerId?: string | null;
  subscriptionId?: string | null;
  checkoutSessionId?: string | null;
  subscriptionStatus?: string | null;
  accountHash?: string | null;
  emailHash?: string | null;
}) {
  await env.DB.prepare(`
    INSERT INTO entitlements (
      identity_hash, plan, active, stripe_customer_id, subscription_id,
      checkout_session_id, subscription_status, account_hash, email_hash, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, unixepoch(), unixepoch())
    ON CONFLICT(identity_hash) DO UPDATE SET
      plan = excluded.plan,
      active = excluded.active,
      stripe_customer_id = COALESCE(excluded.stripe_customer_id, entitlements.stripe_customer_id),
      subscription_id = COALESCE(excluded.subscription_id, entitlements.subscription_id),
      checkout_session_id = COALESCE(excluded.checkout_session_id, entitlements.checkout_session_id),
      subscription_status = COALESCE(excluded.subscription_status, entitlements.subscription_status),
      account_hash = COALESCE(excluded.account_hash, entitlements.account_hash),
      email_hash = COALESCE(excluded.email_hash, entitlements.email_hash),
      updated_at = unixepoch()
    WHERE NOT (entitlements.plan = 'lifetime' AND entitlements.active = 1 AND excluded.plan = 'monthly')
  `).bind(
    values.identity,
    values.plan,
    values.active ? 1 : 0,
    values.customerId ?? null,
    values.subscriptionId ?? null,
    values.checkoutSessionId ?? null,
    values.subscriptionStatus ?? null,
    values.accountHash ?? null,
    values.emailHash ?? null,
  ).run();
}

async function refreshEntitlement(env: Env, context: RequestContext) {
  const row = await resolveEntitlement(env, context);
  if (!row || row.active !== 1) return { active: false, plan: null };
  return { active: true, plan: row.plan, subscriptionStatus: row.subscription_status, purchaseAccount: Boolean(row.account_hash) };
}

async function readJson(request: Request) {
  try {
    return await request.json() as Record<string, unknown>;
  } catch {
    throw new ApiError(400, "The request could not be read.");
  }
}

function purchaseEmail(value: unknown) {
  const email = typeof value === "string" ? value.trim().toLowerCase() : "";
  if (email.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw new ApiError(400, "Enter a valid purchase email address.");
  }
  return email;
}

function alreadyOwned(current: EntitlementRow) {
  return {
    status: 409,
    body: {
      error: current.plan === "lifetime" ? "Lifetime is already owned by this purchase account." : "Monthly is already active for this purchase account.",
      active: true,
      plan: current.plan,
      subscriptionStatus: current.subscription_status,
    },
  };
}

async function startCheckout(request: Request, env: Env, context: RequestContext) {
  // A replacement may race another tab. Re-read the winning reservation instead
  // of making the customer wait for a browser-owned checkout to expire.
  for (let attempt = 0; attempt < 20; attempt += 1) {
    try {
      return await startCheckoutAttempt(request.clone(), env, context);
    } catch (error) {
      if (error !== CHECKOUT_CHANGED) throw error;
      await new Promise((resolve) => setTimeout(resolve, 100 + Math.random() * 100));
    }
  }
  throw new ApiError(503, "Checkout is being updated. Please try again in a moment.");
}

async function expireUnpaidCheckout(env: Env, session: StripeCheckoutSession) {
  if (session.status !== "open") return session;
  try {
    const response = await stripeRequest(env, `/v1/checkout/sessions/${encodeURIComponent(session.id)}/expire`, { method: "POST" });
    return await response.json() as StripeCheckoutSession;
  } catch (error) {
    // Payment or another tab can win the race with expiration. Only an expired
    // session is safe to replace; a completed payment must be reconciled first.
    const latest = await stripeCheckoutSession(env, session.id);
    if (latest?.status === "expired" || latest?.status === "complete") return latest;
    throw error;
  }
}

async function startCheckoutAttempt(request: Request, env: Env, context: RequestContext) {
  const body = await readJson(request);
  const plan = safePlan(body.plan);
  if (!plan) throw new ApiError(400, "Choose a valid NameSnap plan.");
  const email = purchaseEmail(context.email ?? body.email);
  const emailHash = await sha256(email);
  const ownerHash = context.accountHash ?? context.identity;
  let current = await resolveEntitlement(env, context);
  if (current?.active === 1 && (current.plan === "lifetime" || current.plan === plan)) return alreadyOwned(current);
  if (current?.plan === "monthly" && current.subscription_id && plan === "monthly") {
    const response = await stripeRequest(env, `/v1/subscriptions/${encodeURIComponent(current.subscription_id)}`);
    const subscription = await response.json() as StripeSubscription;
    if (!["canceled", "incomplete_expired"].includes(subscription.status)) {
      throw new ApiError(409, "Your existing Monthly subscription needs attention. Contact sidequest@ik.me before starting another subscription.");
    }
  }
  const emailRow = await entitlementByEmail(env, emailHash);
  // An address is enough to prevent another charge, never to disclose or grant access.
  if ((emailRow && emailRow.identity_hash !== current?.identity_hash) ||
      (current?.email_hash && current.email_hash !== emailHash)) {
    return { status: 409, body: { restoreRequired: true, error: "Restore the purchase for this email before starting another checkout." } };
  }

  // Preserve an in-flight checkout created by the previous verified-account flow.
  if (context.accountHash) {
    for (const legacyPlan of [plan === "monthly" ? "lifetime" : "monthly", plan]) {
      const legacy = await env.DB.prepare("SELECT session_id, plan FROM checkout_attempts WHERE account_hash = ? AND plan = ?")
        .bind(context.accountHash, legacyPlan).first<{ session_id: string; plan: Plan }>();
      if (legacy) {
        const session = await stripeCheckoutSession(env, legacy.session_id);
        if (session?.status === "open" && session.url) {
          if (legacy.plan === plan) return { status: 200, body: { url: session.url } };
          const retired = await expireUnpaidCheckout(env, session);
          if (retired.status !== "expired") throw CHECKOUT_CHANGED;
        }
        if (session?.status === "complete") {
          await applyCheckoutSession(env, session);
          current = await resolveEntitlement(env, context);
          if (current?.active === 1 && (current.plan === "lifetime" || current.plan === plan)) return alreadyOwned(current);
          if (!current || current.checkout_session_id !== session.id) throw new ApiError(409, "Your payment is still processing. Please restore your purchase in a moment.");
        }
        await deleteCheckoutAttempt(env, context.accountHash, legacy.plan);
      }
    }
  }

  const ownerReservation = await env.DB.prepare("SELECT * FROM purchase_checkouts WHERE owner_hash = ?")
    .bind(ownerHash).first<CheckoutReservation>();
  if (ownerReservation && ownerReservation.email_hash !== emailHash) {
    if (!ownerReservation.session_id) {
      throw new ApiError(409, "Your previous checkout is being prepared. Please try again shortly.");
    }
    const prior = ownerReservation.session_id ? await stripeCheckoutSession(env, ownerReservation.session_id) : null;
    if (prior?.status === "open") {
      const retired = await expireUnpaidCheckout(env, prior);
      if (retired.status !== "expired") throw CHECKOUT_CHANGED;
    } else if (prior?.status === "complete") {
      await applyCheckoutSession(env, prior);
      throw new ApiError(409, "Your previous checkout is complete. Restore that purchase before changing the email.");
    }
    const removed = await env.DB.prepare("DELETE FROM purchase_checkouts WHERE owner_hash = ? AND generation = ? RETURNING generation")
      .bind(ownerHash, ownerReservation.generation).first<{ generation: string }>();
    if (!removed) throw CHECKOUT_CHANGED;
  }
  let reservation = await env.DB.prepare("SELECT * FROM purchase_checkouts WHERE email_hash = ?")
    .bind(emailHash).first<CheckoutReservation>();
  if (reservation) {
    let session = reservation.session_id ? await stripeCheckoutSession(env, reservation.session_id) : null;
    if (!session && (reservation.owner_hash !== ownerHash || reservation.plan !== plan)) {
      // Recover an uncertain creation using its frozen parameters before
      // replacing it. Never return another browser's Checkout URL or Customer.
      const recovered = await createStripeCheckoutSession(env, reservation.plan, email, emailHash, reservation);
      const updated = await env.DB.prepare("UPDATE purchase_checkouts SET session_id = ?, expires_at = ? WHERE email_hash = ? AND generation = ? RETURNING generation")
        .bind(recovered.id, recovered.expires_at, emailHash, reservation.generation).first<{ generation: string }>();
      if (!updated) throw CHECKOUT_CHANGED;
      session = await stripeCheckoutSession(env, recovered.id);
    }
    if (session?.status === "complete") {
      await applyCheckoutSession(env, session);
      current = await resolveEntitlement(env, context);
      if (current?.active === 1 && (current.plan === "lifetime" || current.plan === plan)) return alreadyOwned(current);
      if (await entitlementByEmail(env, emailHash) && !current) {
        return { status: 409, body: { restoreRequired: true, error: "Restore the purchase for this email before starting another checkout." } };
      }
      if (!current || current.checkout_session_id !== session.id) throw new ApiError(409, "Your payment is still processing. Restore your purchase in a moment.");
    } else if (session?.status === "open") {
      if (reservation.owner_hash === ownerHash && reservation.plan === plan && session.url) return { status: 200, body: { url: session.url } };
      const retired = await expireUnpaidCheckout(env, session);
      if (retired.status !== "expired") throw CHECKOUT_CHANGED;
    }
    // An uncertain creation keeps its reservation and stable idempotency keys.
    if (session) {
      const removed = await env.DB.prepare("DELETE FROM purchase_checkouts WHERE email_hash = ? AND generation = ? RETURNING generation")
        .bind(emailHash, reservation.generation).first<{ generation: string }>();
      if (!removed) throw CHECKOUT_CHANGED;
      reservation = null;
    }
  }
  if (!reservation) {
    const generation = crypto.randomUUID();
    await env.DB.prepare(`INSERT INTO purchase_checkouts (email_hash, owner_hash, plan, generation, expires_at, customer_id, identity_hash, buyer_identity, account_hash, first_attempt_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT DO NOTHING`)
      .bind(emailHash, ownerHash, plan, generation, Math.floor(Date.now() / 1000) + 86400,
        current?.stripe_customer_id ?? null, current?.identity_hash ?? context.accountHash ?? context.identity,
        context.identity, context.accountHash, Math.floor(Date.now() / 1000)).run();
    reservation = await env.DB.prepare("SELECT * FROM purchase_checkouts WHERE email_hash = ?")
      .bind(emailHash).first<CheckoutReservation>();
    if (!reservation || reservation.owner_hash !== ownerHash || reservation.plan !== plan) {
      throw CHECKOUT_CHANGED;
    }
  }
  const session = await createStripeCheckoutSession(env, plan, email, emailHash, reservation);
  if (!session.url) throw new ApiError(503, "NameSnap checkout is temporarily unavailable.");
  const updated = await env.DB.prepare("UPDATE purchase_checkouts SET session_id = ?, expires_at = ? WHERE email_hash = ? AND generation = ? RETURNING generation")
    .bind(session.id, session.expires_at, emailHash, reservation.generation).first<{ generation: string }>();
  if (!updated) throw CHECKOUT_CHANGED;
  return { status: 200, body: { url: session.url } };
}

async function stripeRequest(env: Env, path: string, init: RequestInit = {}) {
  if (!env.STRIPE_RESTRICTED_KEY) throw new ApiError(503, "NameSnap checkout is not available yet.");
  const headers = new Headers(init.headers);
  headers.set("Authorization", `Bearer ${env.STRIPE_RESTRICTED_KEY}`);
  headers.set("Stripe-Version", "2026-07-29.dahlia");
  if (init.body) headers.set("Content-Type", "application/x-www-form-urlencoded");
  const response = await fetch(`https://api.stripe.com${path}`, { ...init, headers });
  if (!response.ok) {
    // Stripe returns 409 while another request with this idempotency key is
    // still running. The checkout loop retries the same persisted attempt.
    if (response.status === 409 && headers.has("Idempotency-Key")) throw CHECKOUT_CHANGED;
    console.error("Stripe request failed", response.status, path);
    throw new ApiError(503, "NameSnap checkout is temporarily unavailable.");
  }
  return response;
}

async function stripeCheckoutSession(env: Env, sessionId: string) {
  if (!/^cs_(test_|live_)?[A-Za-z0-9]+$/.test(sessionId)) return null;
  const response = await stripeRequest(env, `/v1/checkout/sessions/${encodeURIComponent(sessionId)}`);
  return await response.json() as StripeCheckoutSession;
}

async function createStripeCheckoutSession(
  env: Env,
  plan: Plan,
  email: string,
  emailHash: string,
  reservation: CheckoutReservation,
) {
  const identity = reservation.identity_hash;
  if (!identity || !reservation.buyer_identity) throw new ApiError(409, "This earlier checkout needs recovery. Contact sidequest@ik.me before starting another purchase.");
  // Stripe may forget idempotency keys after 24 hours. Leave a one-hour margin
  // and fail closed when an uncertain request can no longer be safely replayed.
  if (!reservation.first_attempt_at || Date.now() / 1000 - reservation.first_attempt_at >= 23 * 3600) {
    throw new ApiError(409, "We need to check your earlier checkout before starting another purchase. Contact sidequest@ik.me for help.");
  }
  // A new Customer locks the required address in Checkout. Never look up saved
  // billing details or attach an existing Customer using an unverified email.
  let customerId = reservation.customer_id;
  if (!customerId) {
    const customer = await stripeRequest(env, "/v1/customers", {
      method: "POST",
      headers: { "Idempotency-Key": `namesnap-customer-${reservation.generation}` },
      body: new URLSearchParams({ email }).toString(),
    });
    customerId = (await customer.json() as { id: string }).id;
    // Persist the Customer before issuing Checkout. If either response is lost,
    // retries retain the exact same Checkout parameters and idempotency key.
    await env.DB.prepare("UPDATE purchase_checkouts SET customer_id = ? WHERE email_hash = ? AND generation = ?")
      .bind(customerId, emailHash, reservation.generation).run();
  }
  const form = new URLSearchParams();
  form.set("mode", plan === "monthly" ? "subscription" : "payment");
  form.set("client_reference_id", `b_${identity}`);
  form.set("success_url", `${env.SITE_URL}/?checkout=success&session_id={CHECKOUT_SESSION_ID}`);
  form.set("cancel_url", `${env.SITE_URL}/?checkout=cancelled`);
  form.set("line_items[0][quantity]", "1");
  form.set("line_items[0][price_data][currency]", "usd");
  form.set("line_items[0][price_data][unit_amount]", plan === "monthly" ? "99" : "699");
  form.set("line_items[0][price_data][product_data][name]", plan === "monthly" ? "NameSnap Unlimited Monthly" : "NameSnap Unlimited Lifetime");
  form.set("line_items[0][price_data][product_data][description]", plan === "monthly" ? "Unlimited contestants on NameSnap Web, billed monthly until canceled." : "Unlimited contestants on NameSnap Web, unlocked for life with one payment.");
  form.set("metadata[namesnap_plan]", plan);
  form.set("metadata[namesnap_identity]", identity);
  form.set("metadata[namesnap_buyer_identity]", reservation.buyer_identity);
  form.set("metadata[namesnap_email_hash]", emailHash);
  form.set("metadata[namesnap_checkout_version]", "2");
  if (reservation.account_hash) form.set("metadata[namesnap_account_hash]", reservation.account_hash);
  // Keep Stripe's dynamic payment methods enabled. The suffix identifies this
  // integration in Stripe without exposing a customer or browser identifier.
  form.set("integration_identifier", "namesnap_web_checkout_qhtrpvks");
  form.set("customer", customerId);
  if (plan === "monthly") {
    form.set("line_items[0][price_data][recurring][interval]", "month");
    form.set("subscription_data[metadata][namesnap_identity]", identity);
    form.set("subscription_data[metadata][namesnap_checkout_version]", "2");
    form.set("subscription_data[metadata][namesnap_email_hash]", emailHash);
    if (reservation.account_hash) form.set("subscription_data[metadata][namesnap_account_hash]", reservation.account_hash);
    form.set("subscription_data[metadata][namesnap_plan]", plan);
  } else {
    form.set("payment_intent_data[metadata][namesnap_identity]", identity);
    form.set("payment_intent_data[metadata][namesnap_plan]", plan);
  }

  const response = await stripeRequest(env, "/v1/checkout/sessions", {
    method: "POST",
    // Retries and concurrent clicks share one session per reserved email.
    headers: {
      "Idempotency-Key": `namesnap-checkout-${reservation.generation}`,
    },
    body: form.toString(),
  });
  return await response.json() as StripeCheckoutSession;
}

async function deleteCheckoutAttempt(env: Env, accountHash: string, plan: Plan) {
  await env.DB.prepare("DELETE FROM checkout_attempts WHERE account_hash = ? AND plan = ?")
    .bind(accountHash, plan).run();
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

async function cancelStripeSubscription(env: Env, subscriptionId: string) {
  if (!env.STRIPE_RESTRICTED_KEY) return false;
  try {
    await stripeRequest(env, `/v1/subscriptions/${encodeURIComponent(subscriptionId)}`, { method: "DELETE" });
    return true;
  } catch {
    return false;
  }
}

async function applyCheckoutSession(env: Env, session: StripeCheckoutSession) {
  const reference = session.client_reference_id ?? session.metadata?.namesnap_identity;
  const guestIdentity = reference?.match(BROWSER_REFERENCE_PATTERN)?.[1];
  const accountHash = guestIdentity
    ? session.metadata?.namesnap_account_hash || null
    : reference?.match(ACCOUNT_REFERENCE_PATTERN)?.[1]
      ?? (reference && /^[a-f0-9]{64}$/.test(reference) ? reference : null);
  const identity = guestIdentity ?? accountHash ?? reference;
  const plan = safePlan(session.metadata?.namesnap_plan);
  if (!identity || !/^[a-f0-9]{64}$/.test(identity) || !plan || session.status !== "complete" || session.payment_status !== "paid") return;
  const email = session.customer_details?.email?.trim().toLowerCase();
  const emailHash = email ? await sha256(email) : null;
  if (guestIdentity && (!emailHash || emailHash !== session.metadata?.namesnap_email_hash)) {
    throw new ApiError(409, "The checkout email could not be confirmed. Contact NameSnap billing support.");
  }
  const current = (accountHash ? await entitlementByAccount(env, accountHash) : null) ?? await entitlement(env, identity);
  if (current?.checkout_session_id === session.id && current.active === 1) return;
  if (current?.plan === "lifetime" && current.active === 1) return;
  const subscriptionId = objectId(session.subscription);
  let subscriptionStatus: string | null = null;
  if (plan === "monthly") {
    if (!subscriptionId) return;
    const response = await stripeRequest(env, `/v1/subscriptions/${encodeURIComponent(subscriptionId)}`);
    const subscription = await response.json() as StripeSubscription;
    if (!ACTIVE_SUBSCRIPTION_STATES.has(subscription.status)) return;
    subscriptionStatus = subscription.status;
  }
  if (plan === "lifetime" && current?.plan === "monthly" && current.subscription_id) {
    subscriptionStatus = await cancelStripeSubscription(env, current.subscription_id) ? "canceled" : "cancellation_required";
  }
  await saveEntitlement(env, {
    identity: current?.identity_hash ?? identity,
    plan,
    active: true,
    customerId: objectId(session.customer),
    subscriptionId: objectId(session.subscription),
    checkoutSessionId: session.id,
    subscriptionStatus,
    accountHash,
    emailHash,
  });
  if (accountHash) await deleteCheckoutAttempt(env, accountHash, plan);
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
    await applyCheckoutSession(env, session);
  }

  if (["customer.subscription.created", "customer.subscription.updated", "customer.subscription.deleted"].includes(event.type)) {
    const subscription = object as unknown as StripeSubscription;
    // Only the subscription attached by paid Checkout fulfillment may change
    // access. Old, unpaid, and out-of-order subscriptions cannot overwrite it.
    const row = await env.DB.prepare("SELECT identity_hash FROM entitlements WHERE subscription_id = ?")
      .bind(subscription.id).first<{ identity_hash: string }>();
    if (row) {
      const response = await stripeRequest(env, `/v1/subscriptions/${encodeURIComponent(subscription.id)}`);
      const latest = await response.json() as StripeSubscription;
      await env.DB.prepare(`UPDATE entitlements SET active = ?, subscription_status = ?, updated_at = unixepoch()
        WHERE identity_hash = ? AND subscription_id = ? AND plan = 'monthly'`)
        .bind(ACTIVE_SUBSCRIPTION_STATES.has(latest.status) ? 1 : 0, latest.status, row.identity_hash, subscription.id).run();
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
      const context = await requestContext(request, env);

      if (url.pathname === "/api/status" && request.method === "GET") {
        return json(200, await refreshEntitlement(env, context), origin);
      }
      if (url.pathname === "/api/confirm" && request.method === "POST") {
        const body = await readJson(request);
        const session = typeof body.sessionId === "string" ? await stripeCheckoutSession(env, body.sessionId) : null;
        const ownsSession = session && (
          session.metadata?.namesnap_buyer_identity === context.identity ||
          (context.accountHash && (session.client_reference_id === `a_${context.accountHash}` ||
            session.metadata?.namesnap_account_hash === context.accountHash))
        );
        if (!session || !ownsSession) throw new ApiError(403, "This checkout belongs to another browser. Restore with your purchase email.");
        await applyCheckoutSession(env, session);
        return json(200, await refreshEntitlement(env, context), origin);
      }
      if (url.pathname === "/api/checkout" && request.method === "POST") {
        const result = await startCheckout(request, env, context);
        return json(result.status, result.body, origin);
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
