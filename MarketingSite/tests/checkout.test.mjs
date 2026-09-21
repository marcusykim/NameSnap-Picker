import assert from 'node:assert/strict';
import { readFile, readdir } from 'node:fs/promises';
import { DatabaseSync } from 'node:sqlite';
import { generateKeyPairSync, sign, createHmac } from 'node:crypto';
import test from 'node:test';
import ts from 'typescript';
const source = await readFile(new URL('../worker/src/index.ts', import.meta.url), 'utf8');
const compiled = ts.transpileModule(source, { compilerOptions: { target: ts.ScriptTarget.ES2022, module: ts.ModuleKind.ES2022 } }).outputText;
const worker = (await import(`data:text/javascript;base64,${Buffer.from(compiled).toString('base64')}`)).default;
const { publicKey, privateKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
const jwk = { ...publicKey.export({ format: 'jwk' }), kid: 'fixture-key' };
const identityA = 'a'.repeat(43), identityB = 'b'.repeat(43);
const email = 'buyer@example.test';
function auth(email, uid = 'fixture-user') {
    const encode = o => Buffer.from(JSON.stringify(o)).toString('base64url');
    const data = `${encode({ alg: 'RS256', kid: jwk.kid })}.${encode({ aud: 'test-namesnap', iss: 'https://securetoken.google.com/test-namesnap', sub: uid, exp: Math.floor(Date.now() / 1000) + 3600, email, email_verified: true })}`;
    return `${data}.${sign('RSA-SHA256', Buffer.from(data), privateKey).toString('base64url')}`;
}
async function setup(t) {
    const db = new DatabaseSync(':memory:');
    for (const file of (await readdir(new URL('../worker/migrations/', import.meta.url))).sort())
        db.exec(await readFile(new URL(`../worker/migrations/${file}`, import.meta.url), 'utf8'));
    const env = { DB: { prepare(sql) { const statement = db.prepare(sql); let values = []; return { bind(...args) { values = args; return this; }, async first() { return statement.get(...values) ?? null; }, async run() { return statement.run(...values); } }; } }, SITE_URL: 'https://getnamesnap.web.app', FIREBASE_PROJECT_ID: 'test-namesnap', STRIPE_RESTRICTED_KEY: 'fixture-only', STRIPE_WEBHOOK_SECRET: 'fixture-webhook-only' };
    const sessions = new Map(), customers = new Map(), subscriptions = new Map(), idempotency = new Map(), calls = [];
    let counter = 0, cancelFails = false, readFails = false, expirationRace = null, createConflict = false, creationHold = null;
    t.mock.method(globalThis, 'fetch', async (url, init = {}) => {
        if (String(url).includes('googleapis.com/service_accounts'))
            return Response.json({ keys: [jwk] });
        const path = new URL(url).pathname;
        const method = init.method ?? 'GET';
        const form = new URLSearchParams(init.body);
        const headers = new Headers(init.headers);
        calls.push({ path, method, form });
        const idem = headers.get('Idempotency-Key');
        if (path === '/v1/checkout/sessions' && createConflict) {
            createConflict = false;
            return Response.json({ error: 'Idempotent request still in progress' }, { status: 409 });
        }
        if (idem && idempotency.has(idem)) {
            const previous = idempotency.get(idem);
            if (previous.body !== init.body)
                return Response.json({ error: 'Idempotency parameters changed' }, { status: 400 });
            return Response.json(previous.result);
        }
        let result;
        if (path === '/v1/customers') {
            result = { id: `cus_fixture${++counter}`, email: form.get('email') };
            customers.set(result.id, result);
        }
        else if (path === '/v1/checkout/sessions' && method === 'POST') {
            const metadata = Object.fromEntries([...form].filter(([k]) => /^metadata\[/.test(k)).map(([k, v]) => [k.slice(9, -1), v]));
            result = { id: `cs_test_fixture${++counter}`, status: 'open', payment_status: 'unpaid', mode: form.get('mode'), url: `https://checkout.stripe.com/c/pay/fixture${counter}`, expires_at: Number(form.get('expires_at') ?? (Math.floor(Date.now() / 1000) + 86400)), client_reference_id: form.get('client_reference_id'), customer: form.get('customer'), customer_details: { email: customers.get(form.get('customer'))?.email ?? email }, metadata, subscription: form.get('mode') === 'subscription' ? `sub_fixture${counter}` : null };
            sessions.set(result.id, result);
            if (result.subscription)
                subscriptions.set(result.subscription, { id: result.subscription, customer: result.customer, status: 'active', metadata: { namesnap_identity: metadata.namesnap_identity, namesnap_checkout_version: '2', namesnap_email_hash: metadata.namesnap_email_hash } });
        }
        else if (path.endsWith('/expire')) {
            result = sessions.get(path.split('/').at(-2));
            if (expirationRace) {
                const race = expirationRace;
                expirationRace = null;
                if (race !== 'failure') {
                    result.status = race === 'expired' ? 'expired' : 'complete';
                    result.payment_status = race === 'paid' ? 'paid' : 'unpaid';
                }
                return Response.json({ error: 'Session cannot be expired' }, { status: 400 });
            }
            if (result.status !== 'open')
                return Response.json({ error: 'Session cannot be expired' }, { status: 400 });
            result.status = 'expired';
        }
        else if (path.startsWith('/v1/checkout/sessions/')) {
            if (readFails)
                return new Response('', { status: 503 });
            result = sessions.get(path.split('/').at(-1));
        }
        else if (path.startsWith('/v1/subscriptions/')) {
            result = subscriptions.get(path.split('/').at(-1));
            if (method === 'DELETE') {
                if (cancelFails)
                    return new Response('', { status: 503 });
                result.status = 'canceled';
            }
        }
        if (!result)
            throw new Error(`Unexpected Stripe fixture request: ${method} ${path}`);
        if (idem)
            idempotency.set(idem, { result, body: init.body });
        if (path === '/v1/checkout/sessions' && creationHold) {
            const hold = creationHold;
            creationHold = null;
            hold.created();
            await hold.wait;
        }
        return Response.json(result);
    });
    t.after(() => db.close());
    async function request(path, body, identity = identityA, bearer) { const headers = { Origin: env.SITE_URL, 'X-NameSnap-Identity': identity }; if (bearer)
        headers.Authorization = `Bearer ${bearer}`; const r = await worker.fetch(new Request(`${env.SITE_URL}${path}`, { method: body ? 'POST' : 'GET', headers, body: body ? JSON.stringify(body) : undefined }), env); return { status: r.status, body: await r.json() }; }
    async function checkout(plan = 'lifetime', identity = identityA, bearer, mail = email) { return request('/api/checkout', { plan, email: mail }, identity, bearer); }
    async function confirm(session, identity = identityA, bearer) { return request('/api/confirm', { sessionId: session.id }, identity, bearer); }
    async function webhook(type, object) { const body = JSON.stringify({ type, data: { object } }); const time = Math.floor(Date.now() / 1000); const signature = createHmac('sha256', env.STRIPE_WEBHOOK_SECRET).update(`${time}.${body}`).digest('hex'); return worker.fetch(new Request(`${env.SITE_URL}/webhook`, { method: 'POST', body, headers: { 'Stripe-Signature': `t=${time},v1=${signature}` } }), env); }
    const paid = session => { session.status = 'complete'; session.payment_status = 'paid'; return session; };
    function holdCreation() {
        let created, release;
        const ready = new Promise(resolve => created = resolve);
        const wait = new Promise(resolve => release = resolve);
        creationHold = { created, wait };
        return { ready, release };
    }
    return { env, db, sessions, customers, subscriptions, calls, request, checkout, confirm, webhook, paid, holdCreation, setCreateConflict: () => createConflict = true, pruneIdempotency: () => idempotency.clear(), setExpirationRace: (race) => expirationRace = race, setCancelFails: () => cancelFails = true, setReadFails: () => readFails = true };
}
test('guest checkout requires a valid email and collects payment without Firebase sign-in', async (t) => {
    const f = await setup(t);
    for (const mail of ['', 'a@@b.com', 'invalid'])
        assert.equal((await f.checkout('lifetime', identityA, null, mail)).status, 400);
    assert.equal((await f.checkout()).status, 200);
    const create = f.calls.find(c => c.path === '/v1/checkout/sessions');
    assert.equal(create.form.get('customer'), [...f.customers.keys()][0]);
    assert.equal(create.form.get('line_items[0][price_data][unit_amount]'), '699');
    assert.equal(create.form.has('payment_method_types[0]'), false);
    assert.deepEqual((await f.request('/api/status')).body, { active: false, plan: null });
});
test('concurrent retries share a checkout; another browser gets its own replacement checkout', async (t) => {
    const f = await setup(t);
    const responses = await Promise.all([f.checkout(), f.checkout()]);
    assert.equal(responses[0].body.url, responses[1].body.url);
    assert.equal(f.sessions.size, 1);
    const foreign = await f.checkout('lifetime', identityB);
    assert.equal(foreign.status, 200);
    assert.notEqual(foreign.body.url, responses[0].body.url);
    assert.equal(foreign.body.active, undefined);
    const [original, replacement] = [...f.sessions.values()];
    assert.equal(original.status, 'expired');
    assert.equal(replacement.status, 'open');
    assert.notEqual(original.customer, replacement.customer);
    assert.equal((await f.confirm(f.paid(replacement), identityB)).body.active, true);
    assert.equal((await f.request('/api/status', undefined, identityA)).body.active, false);
    assert.equal((await f.checkout('lifetime', identityA)).body.restoreRequired, true);
});
test('unpaid, canceled and stolen sessions never unlock access', async (t) => {
    const f = await setup(t);
    await f.checkout();
    const s = [...f.sessions.values()][0];
    assert.equal((await f.confirm(s)).body.active, false);
    assert.equal((await f.confirm(s, identityB)).status, 403);
    s.status = 'complete';
    assert.equal((await f.confirm(s)).body.active, false);
    s.status = 'expired';
    assert.equal((await f.confirm(s)).body.active, false);
});
test('paid guest unlocks, survives reload and cannot buy lifetime again', async (t) => {
    const f = await setup(t);
    await f.checkout();
    const s = f.paid([...f.sessions.values()][0]);
    assert.equal((await f.confirm(s)).body.plan, 'lifetime');
    assert.equal((await f.request('/api/status')).body.active, true);
    const repeat = await f.checkout();
    assert.equal(repeat.status, 409);
    assert.equal(repeat.body.active, true);
    assert.equal(f.sessions.size, 1);
});
test('an existing email blocks another charge without granting or exposing ownership', async (t) => {
    const f = await setup(t);
    await f.checkout();
    await f.confirm(f.paid([...f.sessions.values()][0]));
    const response = await f.checkout('lifetime', identityB);
    assert.equal(response.status, 409);
    assert.equal(response.body.restoreRequired, true);
    assert.equal(response.body.active, undefined);
    assert.equal(response.body.plan, undefined);
    assert.equal(f.customers.size, 1);
    assert.equal((await f.request('/api/status', undefined, identityB)).body.active, false);
});
test('verified matching email restores guest purchase on another browser; unrelated email cannot claim it', async (t) => {
    const f = await setup(t);
    await f.checkout();
    await f.confirm(f.paid([...f.sessions.values()][0]));
    const wrong = await f.request('/api/status', undefined, identityA, auth('someoneelse@example.test', 'other'));
    assert.equal(wrong.body.active, false);
    const restored = await f.request('/api/status', undefined, identityB, auth(email));
    assert.equal(restored.body.plan, 'lifetime');
    assert.equal(restored.body.purchaseAccount, true);
});
test('paid monthly purchase upgrades to lifetime, cancels renewal, and webhook replay preserves warning', async (t) => {
    const f = await setup(t);
    await f.checkout('monthly');
    const month = f.paid([...f.sessions.values()][0]);
    assert.equal((await f.confirm(month)).body.plan, 'monthly');
    assert.equal((await f.checkout('monthly')).status, 409);
    f.setCancelFails();
    assert.equal((await f.checkout('lifetime')).status, 200);
    const life = f.paid([...f.sessions.values()][1]);
    const result = await f.confirm(life);
    assert.equal(result.body.plan, 'lifetime');
    assert.equal(result.body.subscriptionStatus, 'cancellation_required');
    await f.confirm(life);
    assert.equal((await f.request('/api/status')).body.subscriptionStatus, 'cancellation_required');
});
test('switching plan expires previous checkout; Stripe lookup failure prevents another session', async (t) => {
    const f = await setup(t);
    await f.checkout('monthly');
    const first = [...f.sessions.values()][0];
    assert.equal((await f.checkout('lifetime')).status, 200);
    assert.equal(first.status, 'expired');
    f.setReadFails();
    assert.equal((await f.checkout()).status, 503);
    assert.equal(f.sessions.size, 2);
});
test('signed webhook unlocks a paid guest even when they never visit success URL', async (t) => {
    const f = await setup(t);
    await f.checkout();
    const session = f.paid([...f.sessions.values()][0]);
    assert.equal((await f.webhook('checkout.session.completed', session)).status, 200);
    assert.equal((await f.request('/api/status')).body.active, true);
});
test('subscription created event before payment cannot unlock; cancellation revokes monthly only', async (t) => {
    const f = await setup(t);
    await f.checkout('monthly');
    const session = [...f.sessions.values()][0];
    const subscription = f.subscriptions.get(session.subscription);
    await f.webhook('customer.subscription.created', subscription);
    assert.equal((await f.request('/api/status')).body.active, false);
    await f.confirm(f.paid(session));
    subscription.status = 'canceled';
    await f.webhook('customer.subscription.deleted', subscription);
    assert.equal((await f.request('/api/status')).body.active, false);
});
test('a Stripe email mismatch does not attach an entitlement to a different address', async (t) => {
    const f = await setup(t);
    await f.checkout();
    const s = f.paid([...f.sessions.values()][0]);
    s.customer_details.email = 'different@example.test';
    assert.equal((await f.confirm(s)).status, 409);
    assert.equal((await f.request('/api/status')).body.active, false);
});
test('verified customers can purchase and restore through the same flow', async (t) => {
    const f = await setup(t);
    const bearer = auth(email);
    assert.equal((await f.checkout('lifetime', identityA, bearer)).status, 200);
    const s = f.paid([...f.sessions.values()][0]);
    assert.equal((await f.confirm(s, identityA, bearer)).body.plan, 'lifetime');
    assert.equal((await f.request('/api/status', undefined, identityB, bearer)).body.active, true);
});
test('canceled monthly can be bought again and stale subscription events cannot revoke it', async (t) => {
    const f = await setup(t);
    await f.checkout('monthly');
    const oldSession = f.paid([...f.sessions.values()][0]);
    await f.confirm(oldSession);
    const oldSub = f.subscriptions.get(oldSession.subscription);
    oldSub.status = 'canceled';
    await f.webhook('customer.subscription.deleted', oldSub);
    assert.equal((await f.checkout('monthly')).status, 200);
    const next = [...f.sessions.values()][1];
    const nextSub = f.subscriptions.get(next.subscription);
    await f.webhook('customer.subscription.created', nextSub);
    assert.equal((await f.request('/api/status')).body.active, false);
    assert.equal((await f.confirm(f.paid(next))).body.active, true);
    await f.webhook('customer.subscription.deleted', oldSub);
    assert.equal((await f.request('/api/status')).body.active, true);
});
test('editing email expires original open session and reserves only one checkout per browser', async (t) => {
    const f = await setup(t);
    await f.checkout('monthly');
    const old = [...f.sessions.values()][0];
    assert.equal((await f.checkout('monthly', identityA, null, 'second@example.test')).status, 200);
    assert.equal(old.status, 'expired');
    assert.equal(f.db.prepare('SELECT COUNT(*) AS count FROM purchase_checkouts').get().count, 1);
});
test('concurrent different-email checkouts cannot reserve the same browser twice', async (t) => {
    const f = await setup(t);
    const r = await Promise.all([f.checkout('monthly'), f.checkout('monthly', identityA, null, 'second@example.test')]);
    assert.ok(r.every(x => [200, 409].includes(x.status)));
    assert.equal([...f.sessions.values()].filter(x => x.status === 'open').length, 1);
    assert.equal(f.db.prepare('SELECT COUNT(*) AS count FROM purchase_checkouts').get().count, 1);
});
test('subscription webhook cannot downgrade paid lifetime', async (t) => {
    const f = await setup(t);
    await f.checkout('monthly');
    const month = f.paid([...f.sessions.values()][0]);
    await f.confirm(month);
    await f.checkout('lifetime');
    await f.confirm(f.paid([...f.sessions.values()][1]));
    const sub = f.subscriptions.get(month.subscription);
    sub.status = 'canceled';
    await f.webhook('customer.subscription.deleted', sub);
    assert.equal((await f.request('/api/status')).body.plan, 'lifetime');
});
test('past-due monthly cannot start a second collectible monthly subscription', async (t) => {
    const f = await setup(t);
    await f.checkout('monthly');
    const s = f.paid([...f.sessions.values()][0]);
    await f.confirm(s);
    const sub = f.subscriptions.get(s.subscription);
    sub.status = 'past_due';
    await f.webhook('customer.subscription.updated', sub);
    assert.equal((await f.checkout('monthly')).status, 409);
    assert.equal(f.sessions.size, 1);
});
test('uncertain Checkout response survives reservation age and recovers the same session', async (t) => {
    const f = await setup(t);
    await f.checkout();
    const first = [...f.sessions.values()][0];
    f.db.exec('UPDATE purchase_checkouts SET session_id = NULL, expires_at = 0');
    assert.equal((await f.checkout()).body.url, first.url);
    assert.equal(f.sessions.size, 1);
});
test('verified account can recover uncertain Checkout from a second browser with identical parameters', async (t) => {
    const f = await setup(t);
    const bearer = auth(email);
    await f.checkout('lifetime', identityA, bearer);
    const first = [...f.sessions.values()][0];
    f.db.exec('UPDATE purchase_checkouts SET session_id = NULL, expires_at = 0');
    assert.equal((await f.checkout('lifetime', identityB, bearer)).body.url, first.url);
    assert.equal(f.sessions.size, 1);
});
test('unknown Checkout cannot be discarded merely by changing email after a timeout', async (t) => {
    const f = await setup(t);
    await f.checkout();
    f.db.exec('UPDATE purchase_checkouts SET session_id = NULL, expires_at = 0');
    assert.equal((await f.checkout('monthly', identityA, null, 'second@example.test')).status, 409);
    assert.equal(f.sessions.size, 1);
});
test('unknown paid Checkout is not replayed after Stripe can prune its idempotency key', async (t) => {
    const f = await setup(t);
    await f.checkout();
    f.paid([...f.sessions.values()][0]);
    f.db.exec('UPDATE purchase_checkouts SET session_id = NULL, first_attempt_at = unixepoch() - 86401');
    f.pruneIdempotency();
    const callsBefore = f.calls.length;
    const retry = await f.checkout();
    assert.equal(retry.status, 409);
    assert.match(retry.body.error, /earlier checkout/);
    assert.equal(f.sessions.size, 1);
    assert.equal(f.calls.length, callsBefore);
});

test('competing browsers can each open checkout while only the latest unpaid session remains payable', async (t) => {
    const f = await setup(t);
    const responses = await Promise.all([f.checkout(), f.checkout('lifetime', identityB)]);
    assert.ok(responses.every(r => r.status === 200));
    assert.notEqual(responses[0].body.url, responses[1].body.url);
    assert.equal([...f.sessions.values()].filter(s => s.status === 'open').length, 1);
    assert.equal(f.db.prepare('SELECT COUNT(*) AS count FROM purchase_checkouts').get().count, 1);
});

test('a different browser recovers a lost Stripe response and replaces it without exposing the original session', async (t) => {
    const f = await setup(t);
    await f.checkout('monthly');
    const old = [...f.sessions.values()][0];
    f.db.exec('UPDATE purchase_checkouts SET session_id = NULL');
    const result = await f.checkout('lifetime', identityB);
    assert.equal(result.status, 200);
    assert.notEqual(result.body.url, old.url);
    assert.equal(old.status, 'expired');
    assert.equal(f.sessions.size, 2);
});

test('a payment completed before replacement is fulfilled and blocks a duplicate purchase', async (t) => {
    const f = await setup(t);
    await f.checkout();
    f.paid([...f.sessions.values()][0]);
    const result = await f.checkout('lifetime', identityB);
    assert.equal(result.status, 409);
    assert.equal(result.body.restoreRequired, true);
    assert.equal(f.sessions.size, 1);
    assert.equal((await f.request('/api/status')).body.active, true);
    assert.equal((await f.request('/api/status', undefined, identityB)).body.active, false);
});

test('payment winning the expiration race is reconciled before a replacement can charge', async (t) => {
    const f = await setup(t);
    await f.checkout();
    f.setExpirationRace('paid');
    const result = await f.checkout('lifetime', identityB);
    assert.equal(result.status, 409);
    assert.equal(result.body.restoreRequired, true);
    assert.equal(f.sessions.size, 1);
    assert.equal((await f.request('/api/status')).body.active, true);
});

test('processing payment or failed expiration cannot leave two collectible sessions', async (t) => {
    for (const race of ['processing', 'failure']) {
        const f = await setup(t);
        await f.checkout();
        f.setExpirationRace(race);
        const result = await f.checkout('lifetime', identityB);
        assert.equal(result.status, race === 'processing' ? 409 : 503);
        assert.equal(f.sessions.size, 1);
        assert.equal((await f.request('/api/status', undefined, identityB)).body.active, false);
    }
});

test('another request expiring the old session does not block replacement', async (t) => {
    const f = await setup(t);
    await f.checkout();
    f.setExpirationRace('expired');
    assert.equal((await f.checkout('monthly', identityB)).status, 200);
    assert.equal([...f.sessions.values()].filter(s => s.status === 'open').length, 1);
});

test('a late creation response cannot overwrite another browser replacement', async (t) => {
    const f = await setup(t);
    const hold = f.holdCreation();
    const original = f.checkout();
    await hold.ready;
    const replacement = await f.checkout('monthly', identityB);
    assert.equal(replacement.status, 200);
    hold.release();
    assert.equal((await original).status, 200);
    assert.equal([...f.sessions.values()].filter(s => s.status === 'open').length, 1);
    const row = f.db.prepare('SELECT session_id FROM purchase_checkouts').get();
    assert.equal(f.sessions.get(row.session_id).status, 'open');
});

test('Stripe idempotency contention is retried without surfacing an open-checkout block', async (t) => {
    const f = await setup(t);
    f.setCreateConflict();
    assert.equal((await f.checkout()).status, 200);
    assert.equal(f.sessions.size, 1);
    assert.equal(f.customers.size, 1);
});
