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

test("server-renders the NameSnap marketing homepage", async () => {
  const html = await renderedHtml("/");

  assert.match(html, /<title>NameSnap — Fair random picks in seconds \| NameSnap<\/title>/i);
  assert.match(html, /Stop debating\./);
  assert.match(html, /16 names free/);
  assert.match(html, /https:\/\/apps\.apple\.com\/app\/id6759588637/);
  assert.match(html, new RegExp(`mailto:${supportEmail.replace(".", "\\.")}`));
  assert.doesNotMatch(html, /Mracuth@gmail\.com/i);
});

test("publishes a complete support contact for customer requests", async () => {
  const html = await renderedHtml("/support");

  assert.match(html, /NAME SNAP SUPPORT/i);
  assert.match(html, /customer service/i);
  assert.match(html, /complaints or feedback/i);
  assert.match(html, /bug reports/i);
  assert.match(html, /feature requests/i);
  assert.match(html, /mailto:sidequestsoftware@proton\.me\?subject=NameSnap%20Support/i);
});

test("publishes the privacy policy with the current contact", async () => {
  const html = await renderedHtml("/privacy");

  assert.match(html, /Privacy Policy/);
  assert.match(html, /does not transmit this information/i);
  assert.match(html, /mailto:sidequestsoftware@proton\.me\?subject=NameSnap%20Privacy/i);
  assert.doesNotMatch(html, /Mracuth@gmail\.com/i);
});
