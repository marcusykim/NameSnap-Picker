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
  const context = await browser.newContext({ viewport, hasTouch: viewport.width <= 720 });
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
  async function clearDraft() {
    await page.getByRole('button', { name: 'Clear this list', exact: true }).click();
    await page.getByRole('button', { name: 'Clear list', exact: true }).click();
  }
  async function screenshot(name) {
    if (artifactDirectory) await page.screenshot({ path: path.join(artifactDirectory, name + '.png') });
  }
  async function beginUpgrade() {
    await add(Array.from({ length: 17 }, (_, i) => `Contestant ${String.fromCharCode(65 + i)}`));
    await page.locator('#purchase-email').fill('buyer@example.test');
    await page.locator('.lifetime-plan').click();
    await page.waitForURL('https://checkout.stripe.com/**');
  }
  return { page, draft, pool, add, typeNames, clearDraft, screenshot, beginUpgrade, setPaid: () => { paid = true; } };
}

for (const [label, viewport] of [['desktop', { width: 1440, height: 1000 }], ['phone', { width: 390, height: 844 }]]) {
  test(`${label}: added names persist until cleared and fresh sessions start without warnings`, async t => {
    const f = await fixture(t, viewport);
    await f.add(['Alex', 'Jordan']);
    assert.deepEqual(await f.draft(), ['Alex', 'Jordan']);
    assert.equal(await f.page.locator('.duplicate-modal').count(), 0);
    assert.equal(await f.page.locator('.add-button').isEnabled(), true);
    await f.screenshot(`${label}-added`);
    await f.page.getByRole('button', { name: 'Clear this list', exact: true }).click();
    await f.page.getByRole('button', { name: 'Cancel', exact: true }).click();
    assert.deepEqual(await f.draft(), ['Alex', 'Jordan']);
    await f.clearDraft();
    assert.deepEqual(await f.draft(), []);
    assert.deepEqual(await f.pool(), ['1. Alex', '2. Jordan']);
    await f.add(['Casey']);
    assert.equal(await f.page.locator('.duplicate-modal').count(), 0);
    assert.deepEqual(await f.pool(), ['1. Alex', '2. Jordan', '3. Casey']);
    assert.deepEqual(await f.draft(), ['Casey']);
    await f.page.reload();
    await f.page.locator('.session-fresh').click();
    assert.deepEqual(await f.pool(), []);
    assert.deepEqual(await f.draft(), []);
    await f.add(['Alex', 'Jordan']);
    assert.equal(await f.page.locator('.duplicate-modal').count(), 0);
    assert.deepEqual(await f.pool(), ['1. Alex', '2. Jordan']);
    assert.deepEqual(await f.draft(), ['Alex', 'Jordan']);
    await f.screenshot(`${label}-fresh`);
  });
}

test('active-pool duplicates offer cancel, skip, and add-all without clearing the input', async t => {
  const f = await fixture(t);
  await f.add(['Alex']);
  await f.add(['Casey']);
  await f.page.locator('.duplicate-modal').waitFor();
  assert.match(await f.page.locator('#duplicate-message').textContent(), /1 duplicate name in the active pool/);
  await f.page.getByRole('button', { name: 'Cancel', exact: true }).click();
  assert.deepEqual(await f.draft(), ['Alex', 'Casey']);
  assert.deepEqual(await f.pool(), ['1. Alex']);
  await f.page.locator('.add-button').click();
  await f.page.getByRole('button', { name: 'Skip duplicates', exact: true }).click();
  assert.deepEqual(await f.pool(), ['1. Alex', '2. Casey']);
  assert.deepEqual(await f.draft(), ['Alex', 'Casey']);
  await f.page.locator('.add-button').click();
  await f.page.getByRole('button', { name: 'Skip duplicates', exact: true }).click();
  assert.deepEqual(await f.draft(), ['Alex', 'Casey']);
  assert.deepEqual(await f.pool(), ['1. Alex', '2. Casey']);
  await f.page.locator('.add-button').click();
  await f.screenshot('actual-duplicate');
  await f.page.setViewportSize({ width: 390, height: 844 });
  await f.screenshot('actual-duplicate-phone');
  await f.page.getByRole('button', { name: 'Add all anyway', exact: true }).click();
  assert.deepEqual(await f.pool(), ['1. Alex', '2. Casey', '3. Alex', '4. Casey']);
  assert.deepEqual(await f.draft(), ['Alex', 'Casey']);
});

test('undo changes the pool without changing the persistent input', async t => {
  const f = await fixture(t);
  await f.add(['Alex', 'Jordan']);
  await f.typeNames(['Casey']);
  await f.page.getByRole('button', { name: 'Undo last add', exact: true }).click();
  assert.deepEqual(await f.pool(), []);
  assert.deepEqual(await f.draft(), ['Alex', 'Jordan', 'Casey']);
  await f.page.locator('.add-button').click();
  assert.equal(await f.page.locator('.duplicate-modal').count(), 0);
  assert.deepEqual(await f.pool(), ['1. Alex', '2. Jordan', '3. Casey']);
  assert.deepEqual(await f.draft(), ['Alex', 'Jordan', 'Casey']);
});

test('continuing a saved session preserves both submitted and unsubmitted input', async t => {
  const f = await fixture(t);
  await f.add(['Alex']);
  await f.typeNames(['Casey']);
  await f.page.reload();
  await f.page.locator('.session-continue').click();
  assert.deepEqual(await f.pool(), ['1. Alex']);
  assert.deepEqual(await f.draft(), ['Alex', 'Casey']);
  await f.page.locator('.add-button').click();
  assert.equal(await f.page.locator('.duplicate-modal').count(), 1);
  await f.page.getByRole('button', { name: 'Skip duplicates', exact: true }).click();
  assert.deepEqual(await f.pool(), ['1. Alex', '2. Casey']);
});

test('checkout cancellation and success both preserve the input', async t => {
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
  assert.equal((await f.draft()).length, 17);
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

test('zero active contestants does not warn when adding names from previous picks', async t => {
  const f = await fixture(t);
  await f.add(['Alex']);
  await f.page.getByRole('button', { name: 'Quick pick', exact: true }).click();
  await f.page.locator('.picker-display').click();
  await f.page.getByRole('button', { name: 'Keep going', exact: true }).click();
  assert.equal(await f.page.locator('.pool-preview-header b').textContent(), '0');
  await f.screenshot('zero-active-before-add');
  await f.page.locator('.add-button').click();
  assert.equal(await f.page.locator('.duplicate-modal').count(), 0);
  assert.equal(await f.page.locator('.pool-preview-header b').textContent(), '1');
  await f.screenshot('zero-active-added');
});

test('zero active pool accepts the first submitted list without a duplicate confirmation', async t => {
  const f = await fixture(t);
  assert.equal(await f.page.locator('.pool-preview-header b').textContent(), '0');
  await f.add(['Alex', 'Alex']);
  assert.equal(await f.page.locator('.duplicate-modal').count(), 0);
  assert.deepEqual(await f.pool(), ['1. Alex', '2. Alex']);
});

test('a duplicate confirmation closes if an in-progress pick empties the active pool', async t => {
  const f = await fixture(t);
  await f.add(['Alex']);
  await f.page.getByRole('button', { name: 'Quick pick', exact: true }).click();
  await f.page.locator('.picker-display').click();
  await f.page.locator('.add-button').click();
  await f.page.locator('.duplicate-modal').waitFor();
  await f.page.getByRole('button', { name: 'Keep going', exact: true }).click();
  assert.equal(await f.page.locator('.pool-preview-header b').textContent(), '0');
  assert.equal(await f.page.locator('.duplicate-modal').count(), 0);
  assert.deepEqual(await f.draft(), ['Alex']);
  await f.screenshot('zero-active-after-pending-pick');
  await f.page.locator('.add-button').click();
  assert.equal(await f.page.locator('.duplicate-modal').count(), 0);
  assert.equal(await f.page.locator('.pool-preview-header b').textContent(), '1');
});

test('clearing the pool preserves the input and permits it to be added without a warning', async t => {
  const f = await fixture(t);
  await f.add(['Alex', 'Jordan']);
  await f.page.getByRole('button', { name: 'Clear pool', exact: true }).first().click();
  await f.page.locator('.confirmation-confirm').click();
  assert.deepEqual(await f.draft(), ['Alex', 'Jordan']);
  assert.equal(await f.page.locator('.pool-preview-header b').textContent(), '0');
  await f.page.locator('.add-button').click();
  assert.equal(await f.page.locator('.duplicate-modal').count(), 0);
  assert.deepEqual(await f.pool(), ['1. Alex', '2. Jordan']);
});

test('inactive picked names do not count as duplicates while other contestants are still active', async t => {
  const f = await fixture(t);
  await f.add(['Alex', 'Jordan']);
  await f.page.getByRole('button', { name: 'Quick pick', exact: true }).click();
  await f.page.locator('.picker-display').click();
  await f.page.getByRole('button', { name: 'Keep going', exact: true }).click();
  const pickedName = (await f.page.locator('.pool-preview li.picked > span').textContent()).replace(/^\d+\. /, '');
  await f.clearDraft();
  await f.add([pickedName]);
  assert.equal(await f.page.locator('.duplicate-modal').count(), 0);
  assert.equal(await f.page.locator('.pool-preview-header b').textContent(), '2');
});

test('repeated incoming names warn when they would create duplicates in a nonempty active pool', async t => {
  const f = await fixture(t);
  await f.add(['Alex']);
  await f.clearDraft();
  await f.add(['Jordan', 'Jordan']);
  await f.page.locator('.duplicate-modal').waitFor();
  assert.match(await f.page.locator('#duplicate-message').textContent(), /1 duplicate name in the active pool/);
  await f.page.getByRole('button', { name: 'Skip duplicates', exact: true }).click();
  assert.deepEqual(await f.pool(), ['1. Alex', '2. Jordan']);
  assert.deepEqual(await f.draft(), ['Jordan', 'Jordan']);
});

for (const [label, viewport] of [
  ['desktop', { width: 1440, height: 1000 }],
  ['phone', { width: 390, height: 844 }],
  ['landscape', { width: 844, height: 390 }],
]) {
  test(`${label}: winner close stays clickable throughout the celebration entrance`, async t => {
    const f = await fixture(t, viewport);
    await f.add(['Alex']);
    // Select a wide, right-side hero deterministically in this isolated fixture.
    await f.page.evaluate(() => {
      const original = crypto.getRandomValues.bind(crypto);
      crypto.getRandomValues = array => {
        crypto.getRandomValues = original;
        array.fill(1);
        return array;
      };
    });
    await f.page.getByRole('button', { name: 'Quick pick', exact: true }).click();
    await f.page.locator('.picker-display').click();
    await f.page.locator('.winner-modal').waitFor({ state: 'attached' });
    const samples = await f.page.evaluate(() => {
      const backdrop = document.querySelector('.winner-celebration-backdrop');
      const animations = backdrop.getAnimations({ subtree: true });
      const button = backdrop.querySelector('.winner-close');
      const samples = [80, 200, 650, 1200, 2100, 4900].map(time => {
        for (const animation of animations) { animation.pause(); animation.currentTime = time; }
        const rect = button.getBoundingClientRect();
        const x = rect.x + rect.width / 2;
        const y = rect.y + rect.height / 2;
        const hit = document.elementFromPoint(x, y);
        return { time, x, y, target: hit?.className, clickable: hit === button };
      });
      return samples;
    });
    await f.screenshot(`winner-close-${label}-late`);
    await f.page.evaluate(() => {
      for (const animation of document.querySelector('.winner-celebration-backdrop').getAnimations({ subtree: true })) {
        animation.currentTime = 200;
      }
    });
    await f.screenshot(`winner-close-${label}`);
    t.diagnostic(JSON.stringify(samples));
    assert.ok(samples.every(sample => sample.clickable), 'Decorative animation must not intercept the close button');
    const first = samples[0];
    assert.ok(samples.every(sample => Math.abs(sample.x - first.x) < 1 && Math.abs(sample.y - first.y) < 1), 'The close target must stay still from its first visible frame');
    const early = samples.find(sample => sample.time === 200);
    if (viewport.width <= 720) await f.page.touchscreen.tap(early.x, early.y);
    else await f.page.mouse.click(early.x, early.y);
    assert.equal(await f.page.locator('.winner-modal').count(), 0);
    assert.deepEqual(await f.draft(), ['Alex']);
    assert.equal(await f.page.locator('.pool-preview-header b').textContent(), '0');
  });
}
