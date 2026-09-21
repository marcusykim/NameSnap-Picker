import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { mkdir } from 'node:fs/promises';
import path from 'node:path';
import { after, before, test } from 'node:test';
import { chromium } from 'playwright';

const baseUrl = 'http://127.0.0.1:4191';
const artifactDirectory = process.env.NAMESNAP_ARTIFACT_DIR;
let browser, server;
before(async () => {
  server = spawn(process.execPath, ['node_modules/vite/bin/vite.js', 'preview', '--config', 'vite.static.config.ts', '--host', '127.0.0.1', '--port', '4191', '--strictPort'], { stdio: 'pipe' });
  let output = '';
  server.stdout.on('data', chunk => { output += chunk; });
  server.stderr.on('data', chunk => { output += chunk; });
  let ready = false;
  for (let attempt = 0; attempt < 100; attempt++) {
    if (server.exitCode !== null) throw new Error(output);
    try { ready = (await fetch(baseUrl)).ok; } catch { /* Wait for the local test server. */ }
    if (ready) break;
    await new Promise(resolve => setTimeout(resolve, 100));
  }
  if (!ready) throw new Error('Picker test server did not start.');
  browser = await chromium.launch({ headless: true });
  if (artifactDirectory) await mkdir(artifactDirectory, { recursive: true });
});
after(async () => {
  await browser?.close();
  server?.kill();
});

async function fixture(t, viewport = { width: 1440, height: 1000 }) {
  const context = await browser.newContext({ viewport });
  t.after(() => context.close());
  const page = await context.newPage();
  let paid = false;
  await page.route('**/api/status', route => route.fulfill({ json: { active: paid, plan: paid ? 'lifetime' : null } }));
  await page.route('**/api/confirm', route => route.fulfill({ json: { active: paid, plan: paid ? 'lifetime' : null } }));
  await page.route('**/api/checkout', route => route.fulfill({ json: { url: 'https://checkout.stripe.com/c/pay/pickerfixture' } }));
  await page.route('https://checkout.stripe.com/**', route => route.fulfill({ contentType: 'text/html', body: '<p>Checkout fixture. No payment is possible.</p>' }));
  await page.goto(baseUrl);
  await page.locator('.session-fresh').click();
  const draft = () => page.locator('.name-editor input').evaluateAll(inputs => inputs.map(input => input.value).filter(Boolean));
  const pool = () => page.locator('.pool-preview li > span').allTextContents();
  async function typeNames(names) {
    for (const name of names) await page.locator('.name-editor-row-new input').fill(name);
  }
  async function add(names) { await typeNames(names); await page.locator('.add-button').click(); }
  async function screenshot(name) {
    if (artifactDirectory) await page.screenshot({ path: path.join(artifactDirectory, name + '.png') });
  }
  async function beginUpgrade() {
    await add(Array.from({ length: 17 }, (_, i) => `Contestant ${String.fromCharCode(65 + i)}`));
    await page.locator('#purchase-email').fill('buyer@example.test');
    await page.locator('.lifetime-plan').click();
    await page.waitForURL('https://checkout.stripe.com/**');
  }
  return { page, draft, pool, add, typeNames, screenshot, beginUpgrade, setPaid: () => { paid = true; } };
}

for (const [label, viewport] of [['desktop', { width: 1440, height: 1000 }], ['phone', { width: 390, height: 844 }]]) {
  test(`${label}: a new batch does not resubmit names from the previous add`, async t => {
    const f = await fixture(t, viewport);
    await f.add(['Alex', 'Jordan']);
    assert.deepEqual(await f.draft(), []);
    await f.add(['Casey']);
    assert.equal(await f.page.locator('.duplicate-modal').count(), 0);
    assert.deepEqual(await f.pool(), ['1. Alex', '2. Jordan', '3. Casey']);
    assert.deepEqual(await f.draft(), []);
    assert.equal(await f.page.locator('.add-button').isDisabled(), true);
    await f.screenshot(`${label}-added`);
    await f.page.reload();
    await f.page.locator('.session-fresh').click();
    assert.deepEqual(await f.pool(), []);
    await f.add(['Alex', 'Jordan']);
    assert.equal(await f.page.locator('.duplicate-modal').count(), 0);
    assert.deepEqual(await f.pool(), ['1. Alex', '2. Jordan']);
    await f.screenshot(`${label}-fresh`);
  });
}

test('real duplicates still offer cancel, skip, and add-all choices', async t => {
  const f = await fixture(t);
  await f.add(['Alex', 'Alex']);
  await f.page.locator('.duplicate-modal').waitFor();
  await f.page.getByRole('button', { name: 'Cancel', exact: true }).click();
  assert.deepEqual(await f.draft(), ['Alex', 'Alex']);
  assert.deepEqual(await f.pool(), []);
  await f.page.locator('.add-button').click();
  await f.page.getByRole('button', { name: 'Skip duplicates', exact: true }).click();
  assert.deepEqual(await f.pool(), ['1. Alex']);
  assert.deepEqual(await f.draft(), []);
  await f.add(['Alex', 'Casey']);
  await f.page.getByRole('button', { name: 'Skip duplicates', exact: true }).click();
  assert.deepEqual(await f.pool(), ['1. Alex', '2. Casey']);
  assert.deepEqual(await f.draft(), []);
  await f.add(['Alex']);
  await f.page.getByRole('button', { name: 'Skip duplicates', exact: true }).click();
  assert.deepEqual(await f.draft(), []);
  assert.deepEqual(await f.pool(), ['1. Alex', '2. Casey']);
  await f.add(['Alex']);
  await f.screenshot('actual-duplicate');
  await f.page.getByRole('button', { name: 'Add all anyway', exact: true }).click();
  assert.deepEqual(await f.pool(), ['1. Alex', '2. Casey', '3. Alex']);
  assert.deepEqual(await f.draft(), []);
});

test('undo returns the added batch to the editor and preserves new unsent names', async t => {
  const f = await fixture(t);
  await f.add(['Alex', 'Jordan']);
  await f.typeNames(['Casey']);
  await f.page.getByRole('button', { name: 'Undo last add', exact: true }).click();
  assert.deepEqual(await f.pool(), []);
  assert.deepEqual(await f.draft(), ['Alex', 'Jordan', 'Casey']);
  await f.page.locator('.add-button').click();
  assert.equal(await f.page.locator('.duplicate-modal').count(), 0);
  assert.deepEqual(await f.pool(), ['1. Alex', '2. Jordan', '3. Casey']);
});

test('continuing a saved session keeps the pool and only the unsubmitted draft', async t => {
  const f = await fixture(t);
  await f.add(['Alex']);
  await f.typeNames(['Casey']);
  await f.page.reload();
  await f.page.locator('.session-continue').click();
  assert.deepEqual(await f.pool(), ['1. Alex']);
  assert.deepEqual(await f.draft(), ['Casey']);
  await f.page.locator('.add-button').click();
  assert.equal(await f.page.locator('.duplicate-modal').count(), 0);
  assert.deepEqual(await f.pool(), ['1. Alex', '2. Casey']);
});

test('exceeding the free limit preserves the draft until the queued add succeeds', async t => {
  const f = await fixture(t);
  await f.beginUpgrade();
  await f.page.goto(baseUrl + '/?checkout=cancelled');
  await f.page.locator('.upgrade-modal').waitFor();
  await f.page.getByRole('button', { name: 'Close upgrade', exact: true }).click();
  assert.equal((await f.draft()).length, 17);
  assert.deepEqual(await f.pool(), []);
  f.setPaid();
  await f.page.goto(baseUrl + '/?checkout=success&session_id=cs_test_pickerfixture');
  await f.page.waitForFunction(() => document.querySelectorAll('.pool-preview li').length === 17);
  assert.deepEqual(await f.draft(), []);
});

test('starting fresh discards pending checkout names without removing paid access', async t => {
  const f = await fixture(t);
  await f.beginUpgrade();
  await f.page.goto(baseUrl);
  await f.page.locator('.session-fresh').click();
  assert.deepEqual(await f.draft(), []);
  assert.deepEqual(await f.pool(), []);
  f.setPaid();
  await f.page.goto(baseUrl + '/?checkout=success&session_id=cs_test_pickerfixture');
  await f.page.locator('.purchase-active-notice').waitFor();
  await f.page.locator('.upgrade-modal').waitFor({ state: 'hidden' });
  assert.deepEqual(await f.pool(), []);
  assert.deepEqual(await f.draft(), []);
  await f.add(['Alex']);
  assert.equal(await f.page.locator('.duplicate-modal').count(), 0);
  assert.deepEqual(await f.pool(), ['1. Alex']);
});

test('a late checkout return preserves a newer unsubmitted draft', async t => {
  const f = await fixture(t);
  await f.beginUpgrade();
  await f.page.goto(baseUrl + '/?checkout=cancelled');
  await f.page.getByRole('button', { name: 'Close upgrade', exact: true }).click();
  await f.page.getByRole('button', { name: 'Clear this list', exact: true }).click();
  await f.page.getByRole('button', { name: 'Clear list', exact: true }).click();
  await f.typeNames(['New participant']);
  f.setPaid();
  await f.page.goto(baseUrl + '/?checkout=success&session_id=cs_test_pickerfixture');
  await f.page.waitForFunction(() => document.querySelectorAll('.pool-preview li').length === 17);
  assert.deepEqual(await f.draft(), ['New participant']);
});
