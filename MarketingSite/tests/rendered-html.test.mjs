import assert from "node:assert/strict";
import { access, readFile } from "node:fs/promises";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const testDirectory = path.dirname(fileURLToPath(import.meta.url));
const marketingDirectory = path.resolve(testDirectory, "..");

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
  assert.doesNotMatch(html, /IN POOL/);
  assert.match(html, /Undo last add/);
  assert.match(html, /Clear this list/);
  assert.match(html, /Reset pool/);
  assert.match(html, /Clear pool/);
  assert.match(html, /stage-status stage-status-toggle/);
  assert.match(html, /stage-status stage-status-recent/);
  assert.match(html, /Open previous winners/);
  assert.match(html, /View full list/);
  assert.match(html, /Names in the draw/);
  assert.match(html, /Add contestants above/);
  assert.match(html, /iPhone \+ iPad/);
  assert.match(html, /https:\/\/apps\.apple\.com\/app\/id6759588637/);
  assert.match(html, /One list\. One fair pick\./i);
  assert.match(html, /hundreds of celebration variations/i);
  assert.match(html, /Web for the room/i);
  assert.match(html, /href="\/support#contact"/);
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
  assert.match(html, />Send us an email<\/summary>/i);
  assert.match(html, /mail\.google\.com\/mail\/\?view=cm/i);
  assert.match(html, /outlook\.office\.com\/mail\/deeplink\/compose/i);
  assert.match(html, /compose\.mail\.yahoo\.com/i);
  assert.match(html, />Copy email<\/button>/i);
  assert.match(html, /aria-live="polite"/i);
});

test("publishes the privacy policy with the current contact", async () => {
  const html = await renderedHtml("/privacy");

  assert.match(html, /Privacy Policy/);
  assert.match(html, /Contestant data stays local/i);
  assert.match(html, /does not send contestant names or winner history/i);
  assert.match(html, /Cloudflare stores only one-way hashes/i);
  assert.match(html, /Firebase provides website hosting/i);
  assert.match(html, /mailto:sidequestsoftware@proton\.me\?subject=NameSnap%20Privacy/i);
  assert.doesNotMatch(html, /Mracuth@gmail\.com/i);
});

test("publishes the app EULA, web terms, and platform entitlement boundaries", async () => {
  const html = await renderedHtml("/terms");

  assert.match(html, /Terms of Use/i);
  assert.match(html, /Standard End User License Agreement/i);
  assert.match(html, /apple\.com\/legal\/internet-services\/itunes\/dev\/stdeula/i);
  assert.match(html, /Apple and its subsidiaries are third-party beneficiaries/i);
  assert.match(html, /Unlimited Monthly is a recurring Stripe subscription until canceled/i);
  assert.match(html, /request cancellation of future renewals/i);
  assert.match(html, /Web purchases unlock NameSnap Web only/i);
  assert.match(html, /iPhone and iPad app only/i);
  assert.match(html, /mailto:sidequestsoftware@proton\.me\?subject=NameSnap%20Terms/i);
});

test("publishes the redesigned NameSnap icon across browser and installed-app surfaces", async () => {
  const staticHtml = await readFile(path.join(marketingDirectory, "static/index.html"), "utf8");
  const manifest = JSON.parse(
    await readFile(path.join(marketingDirectory, "public/site.webmanifest"), "utf8"),
  );

  assert.match(staticHtml, /namesnap-app-icon-v2-32\.png/);
  assert.match(staticHtml, /namesnap-app-icon-v2-192\.png/);
  assert.match(staticHtml, /namesnap-app-icon-v2-180\.png/);
  assert.match(staticHtml, /site\.webmanifest/);
  assert.deepEqual(
    manifest.icons.map((icon) => icon.src),
    ["/namesnap-app-icon-v2-192.png", "/namesnap-app-icon-v2-512.png"],
  );

  await Promise.all([
    "namesnap-app-icon-v2-32.png",
    "namesnap-app-icon-v2-192.png",
    "namesnap-app-icon-v2-512.png",
    "namesnap-app-icon-v2-180.png",
    "namesnap-gravatar.png",
  ].map((filename) => access(path.join(marketingDirectory, "public", filename))));
});

test("ships all 30 celebration heroes and exposes 300 visual variations", async () => {
  const webAppSource = await readFile(
    path.join(marketingDirectory, "app/namesnap-web-app.tsx"),
    "utf8",
  );
  const heroNames = [
    "dancer",
    "guitarist",
    "drummer",
    "breakdancer",
    "skater",
    "dj",
    "trumpet",
    "hype-mascot",
    "dynamite",
    "saxophonist",
    "cheer-captain",
    "magician",
    "skateboarder",
    "soccer-striker",
    "basketball-dunker",
    "astronaut",
    "robot",
    "superhero",
    "opera-singer",
    "punk-vocalist",
    "keytarist",
    "disco-dancer",
    "conductor",
    "juggler",
    "pirate-captain",
    "knight",
    "rocket-scientist",
    "gamer",
    "rodeo-star",
    "pixel-bomb",
  ];

  assert.match(webAppSource, /CELEBRATION_VARIATION_COUNT = 300/);
  await Promise.all(heroNames.map((hero) => {
    const extension = hero === "pixel-bomb" ? "gif" : "png";
    return access(path.join(marketingDirectory, "public/celebrations", `${hero}.${extension}`));
  }));
});

test("offers three duplicate-name outcomes and uses only 120+ BPM winner music", async () => {
  const webAppSource = await readFile(
    path.join(marketingDirectory, "app/namesnap-web-app.tsx"),
    "utf8",
  );
  const musicFiles = [
    "techno_upbeat_alt_01.mp3",
    "techno_upbeat_alt_06.mp3",
    "hype_dance_128.mp3",
    "hype_house_128.mp3",
    "hype_happy_130.mp3",
    "hype_metal_160.mp3",
  ];

  assert.match(webAppSource, />Cancel<\/button>/);
  assert.match(webAppSource, />Skip duplicates<\/button>/);
  assert.match(webAppSource, />Add all anyway<\/button>/);
  assert.match(webAppSource, /namesExcludingDuplicates\(names, entries\.map/);
  assert.doesNotMatch(webAppSource, /celebration_(?:airhorn|crowd|explosion|fanfare|fireworks)\.mp3/);
  await Promise.all(musicFiles.map((filename) => access(path.join(marketingDirectory, "public/sounds", filename))));
});

test("provides a stage-only web presentation fallback when browser fullscreen is unavailable", async () => {
  const [webAppSource, globalStyles] = await Promise.all([
    readFile(path.join(marketingDirectory, "app/namesnap-web-app.tsx"), "utf8"),
    readFile(path.join(marketingDirectory, "app/globals.css"), "utf8"),
  ]);

  assert.match(webAppSource, /setPresentation\(true\)/);
  assert.match(webAppSource, /\(min-width: 821px\) and \(pointer: fine\)/);
  assert.match(webAppSource, /stageRef\.current\?\.requestFullscreen/);
  assert.match(webAppSource, /Exit view/);
  assert.match(webAppSource, /aria-label="Exit presentation mode"/);
  assert.match(globalStyles, /\.web-app\.is-presenting \.producer-panel/);
  assert.match(globalStyles, /\.web-app\.is-presenting \.stage \{/);
  assert.match(globalStyles, /height: 100dvh/);
  assert.match(globalStyles, /\.web-app\.is-presenting \.presentation-exit/);
});

test("retires the old Firebase hostname with path-preserving permanent redirects", async () => {
  const retiredConfig = JSON.parse(
    await readFile(path.join(marketingDirectory, "firebase.retired.json"), "utf8"),
  );

  assert.equal(retiredConfig.hosting.site, "namesnap-picker-6759588637");
  assert.deepEqual(retiredConfig.hosting.redirects, [
    { source: "/", destination: "https://getnamesnap.web.app/", type: 301 },
    { source: "/:path*", destination: "https://getnamesnap.web.app/:path", type: 301 },
  ]);
});
