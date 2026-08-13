import { spawn } from "node:child_process";
import { cp, mkdir, rm, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const output = join(root, "firebase-public");
const port = 4187;
const origin = `http://127.0.0.1:${port}`;

const server = spawn("npm", ["run", "start"], {
  cwd: root,
  env: { ...process.env, PORT: String(port) },
  stdio: ["ignore", "pipe", "pipe"],
});

let serverLog = "";
server.stdout.on("data", (chunk) => { serverLog += chunk; });
server.stderr.on("data", (chunk) => { serverLog += chunk; });

async function waitForServer() {
  for (let attempt = 0; attempt < 80; attempt += 1) {
    try {
      const response = await fetch(origin);
      if (response.ok) return;
    } catch {
      // The production server is still starting.
    }
    await new Promise((resolve) => setTimeout(resolve, 250));
  }
  throw new Error(`Production server did not start.\n${serverLog}`);
}

function directImageUrl(url) {
  const decoded = decodeURIComponent(url.replaceAll("&amp;", "&"));
  return decoded.startsWith("/") ? decoded : `/${decoded}`;
}

function makeStatic(html) {
  return html
    .replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, "")
    .replace(/<link\b(?=[^>]*\brel=["']modulepreload["'])[^>]*\/?\s*>/gi, "")
    .replace(/<link\b(?=[^>]*\brel=["']preload["'])(?=[^>]*\bimageSrcSet=)[^>]*\/?\s*>/gi, "")
    .replace(/\s(?:srcSet|imageSrcSet)="[^"]*"/gi, "")
    .replace(/\/_next\/image\?url=([^&"]+)(?:&amp;|&)w=\d+(?:&amp;|&)q=\d+/gi, (_, url) => directImageUrl(url))
    .replace(/\sdata-nimg="[^"]*"/gi, "")
    .replace(/\sdata-rsc-css-href="[^"]*"/gi, "")
    .replace(/\sdata-precedence="[^"]*"/gi, "")
    .replace(/\sfetchPriority="[^"]*"/gi, "")
    .replace(/\sdecoding="[^"]*"/gi, "");
}

async function exportRoute(route, destination) {
  const response = await fetch(`${origin}${route}`);
  if (!response.ok) throw new Error(`${route} returned ${response.status}`);
  const html = makeStatic(await response.text());
  const target = join(output, destination);
  await mkdir(dirname(target), { recursive: true });
  await writeFile(target, html);
}

try {
  await waitForServer();
  await rm(output, { recursive: true, force: true });
  await cp(join(root, "dist", "client"), output, { recursive: true });
  await Promise.all([
    exportRoute("/", "index.html"),
    exportRoute("/privacy", "privacy/index.html"),
    exportRoute("/support", "support/index.html"),
  ]);
  console.log(`Static Firebase site exported to ${output}`);
} finally {
  server.kill("SIGTERM");
}
