import assert from "node:assert/strict";
import test from "node:test";

const supportEmail = "sidequestsoftware@proton.me";

async function render(pathname = "/") {
  const workerUrl = new URL("../dist/server/index.js", import.meta.url);
  workerUrl.searchParams.set("test", `${process.pid}-${Date.now()}-${pathname}`);
  const { default: worker } = await import(workerUrl.href);

  return worker.fetch(
    new Request(`http://localhost${pathname}`, {
      headers: { accept: "text/html" },
    }),
    {
      ASSETS: {
        fetch: async () => new Response("Not found", { status: 404 }),
      },
    },
    {
      waitUntil() {},
      passThroughOnException() {},
    },
  );
}

async function renderedHtml(pathname) {
  const response = await render(pathname);
  assert.equal(response.status, 200);
  assert.match(response.headers.get("content-type") ?? "", /^text\/html\b/i);
  return response.text();
}

test("server-renders the NameSnap web picker with App Store routing", async () => {
  const html = await renderedHtml("/");

  assert.match(html, /<title>NameSnap Web — Pick a winner live \| NameSnap<\/title>/i);
  assert.match(html, /Contestant list/);
  assert.match(html, /Numbered contestant input/);
  assert.match(html, /Contestant 1/);
  assert.match(html, /class="name-editor-number"[^>]*>1(?:<!-- -->)?\.<\/span>/);
  assert.match(html, /Spin the wheel/);
  assert.match(html, /IN POOL/);
  assert.match(html, /iPhone \+ iPad/);
  assert.match(html, /https:\/\/apps\.apple\.com\/app\/id6759588637/);
  assert.match(html, new RegExp(`mailto:${supportEmail.replace(".", "\\.")}`));
  assert.doesNotMatch(html, /Mracuth@gmail\.com/i);
  assert.doesNotMatch(html, /Upgrade to Unlimited/);
  assert.doesNotMatch(html, /\$6\.99|\$0\.99/);
});

test("publishes a complete support contact for customer requests", async () => {
  const html = await renderedHtml("/support");

  assert.match(html, /NAME SNAP SUPPORT/i);
  assert.match(html, /customer service/i);
  assert.match(html, /complaints or feedback/i);
  assert.match(html, /bug reports/i);
  assert.match(html, /feature requests/i);
  assert.match(html, /cancel Unlimited Monthly/i);
  assert.match(html, /mailto:sidequestsoftware@proton\.me\?subject=NameSnap%20Support/i);
});

test("publishes the privacy policy with the current contact", async () => {
  const html = await renderedHtml("/privacy");

  assert.match(html, /Privacy Policy/);
  assert.match(html, /Contestant data stays local/i);
  assert.match(html, /does not send contestant names or winner history/i);
  assert.match(html, /Cloudflare stores only a one-way hash/i);
  assert.match(html, /Firebase provides website hosting/i);
  assert.match(html, /mailto:sidequestsoftware@proton\.me\?subject=NameSnap%20Privacy/i);
  assert.doesNotMatch(html, /Mracuth@gmail\.com/i);
});

test("publishes web purchase terms and platform entitlement boundaries", async () => {
  const html = await renderedHtml("/terms");

  assert.match(html, /Terms of Use/i);
  assert.match(html, /Unlimited Monthly is a recurring Stripe subscription until canceled/i);
  assert.match(html, /request cancellation of future renewals/i);
  assert.match(html, /Web purchases unlock NameSnap Web only/i);
  assert.match(html, /iPhone and iPad app only/i);
  assert.match(html, /mailto:sidequestsoftware@proton\.me\?subject=NameSnap%20Terms/i);
});
