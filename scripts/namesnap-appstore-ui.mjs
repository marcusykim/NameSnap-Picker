#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const canonicalPort = 9800;
const canonicalLeaseKey = "marcus-apple-developer";
const allowedHosts = new Set(["appstoreconnect.apple.com"]);
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

function requireCanonicalSessionLease() {
  if (
    process.env.BROWSER_SESSION_LEASE_HELD !== "1"
    || process.env.BROWSER_SESSION_LEASE_KEY !== canonicalLeaseKey
  ) {
    throw new Error(
      "Refusing App Store Connect UI work without the marcus-apple-developer browser-session lease.",
    );
  }
}

function isAllowedUrl(value) {
  try {
    const url = new URL(value);
    return url.protocol === "https:" && allowedHosts.has(url.hostname.toLowerCase());
  } catch {
    return false;
  }
}

async function waitForJson(url, timeoutMs = 25000) {
  const startedAt = Date.now();
  while (Date.now() - startedAt < timeoutMs) {
    try {
      const response = await fetch(url);
      if (response.ok) return response.json();
    } catch {
      // The canonical Apple project browser may still be starting.
    }
    await sleep(500);
  }
  throw new Error(`Timed out waiting for ${url}`);
}

function connectCdp(wsUrl) {
  const socket = new WebSocket(wsUrl);
  const pending = new Map();
  let nextId = 1;
  socket.addEventListener("message", (event) => {
    const message = JSON.parse(event.data);
    if (!message.id) return;
    const waiter = pending.get(message.id);
    if (!waiter) return;
    pending.delete(message.id);
    if (message.error) waiter.reject(new Error(JSON.stringify(message.error)));
    else waiter.resolve(message.result);
  });
  return new Promise((resolve, reject) => {
    socket.addEventListener("open", () => resolve({
      send(method, params = {}, timeoutMs = 15000) {
        const id = nextId++;
        socket.send(JSON.stringify({ id, method, params }));
        return new Promise((resolveSend, rejectSend) => {
          const timer = setTimeout(() => {
            pending.delete(id);
            rejectSend(new Error(`CDP command timed out: ${method}`));
          }, timeoutMs);
          pending.set(id, {
            resolve(value) { clearTimeout(timer); resolveSend(value); },
            reject(error) { clearTimeout(timer); rejectSend(error); },
          });
        });
      },
      close() { socket.close(); },
    }));
    socket.addEventListener("error", reject);
  });
}

async function evaluate(client, expression) {
  const response = await client.send("Runtime.evaluate", { expression, returnByValue: true });
  if (response.exceptionDetails) throw new Error("Could not inspect the visible App Store Connect page.");
  return response.result?.value;
}

async function getAppStorePage() {
  const pages = await waitForJson(`http://127.0.0.1:${canonicalPort}/json/list`);
  const candidates = pages.filter((candidate) => (
    candidate.type === "page"
    && candidate.webSocketDebuggerUrl
    && isAllowedUrl(candidate.url)
  ));
  const page = candidates.find((candidate) => candidate.url.includes("6759588637"))
    || candidates.find((candidate) => candidate.url.includes("/apps/"))
    || candidates[0];
  if (!page) throw new Error(`The canonical Apple window on port ${canonicalPort} has no App Store Connect tab.`);
  return page;
}

async function mouseClick(client, point, clickCount = 1) {
  await client.send("Input.dispatchMouseEvent", { type: "mouseMoved", x: point.x, y: point.y });
  await client.send("Input.dispatchMouseEvent", { type: "mousePressed", x: point.x, y: point.y, button: "left", clickCount });
  await client.send("Input.dispatchMouseEvent", { type: "mouseReleased", x: point.x, y: point.y, button: "left", clickCount });
  await sleep(400);
}

async function key(client, keyValue, code, windowsVirtualKeyCode, modifiers = 0) {
  await client.send("Input.dispatchKeyEvent", {
    type: "rawKeyDown", key: keyValue, code, windowsVirtualKeyCode,
    nativeVirtualKeyCode: windowsVirtualKeyCode, modifiers,
  });
  await client.send("Input.dispatchKeyEvent", {
    type: "keyUp", key: keyValue, code, windowsVirtualKeyCode,
    nativeVirtualKeyCode: windowsVirtualKeyCode, modifiers,
  });
  await sleep(160);
}

async function selectAllText(client, point) {
  await mouseClick(client, point, 3);
}

function parseArgs(argv) {
  const [command = "inspect", ...rest] = argv;
  const options = {};
  for (let index = 0; index < rest.length; index += 1) {
    const arg = rest[index];
    if (!arg.startsWith("--")) throw new Error(`Unexpected argument: ${arg}`);
    options[arg.slice(2)] = rest[index + 1] ?? "";
    index += 1;
  }
  return { command, options };
}

function visibleUiExpression() {
  return `(() => {
    const visible = (node) => {
      if (!node) return false;
      const rect = node.getBoundingClientRect();
      const style = getComputedStyle(node);
      return rect.width > 0 && rect.height > 0 && style.display !== "none" && style.visibility !== "hidden";
    };
    const clean = (value) => String(value || "").replace(/\\s+/g, " ").trim();
    const center = (node) => {
      const rect = node.getBoundingClientRect();
      return { x: rect.x + rect.width / 2, y: rect.y + rect.height / 2 };
    };
    const labelFor = (input) => {
      const explicit = input.id ? document.querySelector('label[for="' + CSS.escape(input.id) + '"]') : null;
      const wrapping = input.closest("label");
      const parentText = input.parentElement?.innerText;
      return clean(explicit?.innerText || wrapping?.innerText || input.getAttribute("aria-label") || input.placeholder || input.name || parentText);
    };
    const controls = [...document.querySelectorAll("button, a, [role=button], [role=menuitem], [role=option]")]
      .filter(visible)
      .map((node) => ({
        text: clean(node.innerText || node.textContent || node.getAttribute("aria-label")),
        role: node.getAttribute("role") || node.tagName.toLowerCase(),
        href: node instanceof HTMLAnchorElement ? node.href : "",
        disabled: Boolean(node.disabled || node.getAttribute("aria-disabled") === "true"),
        point: center(node),
      }))
      .filter((item) => item.text)
      .slice(0, 180);
    return {
      url: location.href,
      title: document.title,
      viewport: { width: innerWidth, height: innerHeight, scrollY },
      text: clean(document.body?.innerText).slice(0, 12000),
      controls,
      inputs: [...document.querySelectorAll("input, textarea, [contenteditable=true]")]
        .filter(visible)
        .map((input) => ({
          type: String(input.type || input.tagName).toLowerCase(),
          label: labelFor(input),
          name: input.name || "",
          placeholder: input.placeholder || "",
          hasValue: Boolean(input.value || input.innerText),
          point: center(input),
        }))
        .slice(0, 100),
    };
  })()`;
}

async function inspect(client) {
  return evaluate(client, visibleUiExpression());
}

async function findControl(client, target, kind) {
  return evaluate(client, `(() => {
    const target = ${JSON.stringify(target)}.toLowerCase();
    const visible = (node) => {
      if (!node) return false;
      const rect = node.getBoundingClientRect();
      const style = getComputedStyle(node);
      return rect.width > 0 && rect.height > 0 && style.display !== "none" && style.visibility !== "hidden";
    };
    const clean = (value) => String(value || "").replace(/\\s+/g, " ").trim();
    const center = (node) => {
      const rect = node.getBoundingClientRect();
      return { x: rect.x + rect.width / 2, y: rect.y + rect.height / 2 };
    };
    const labelFor = (input) => {
      const explicit = input.id ? document.querySelector('label[for="' + CSS.escape(input.id) + '"]') : null;
      const wrapping = input.closest("label");
      return clean(explicit?.innerText || wrapping?.innerText || input.getAttribute("aria-label") || input.placeholder || input.name || input.parentElement?.innerText);
    };
    if (${JSON.stringify(kind)} === "input") {
      const candidates = [...document.querySelectorAll("input, textarea, [contenteditable=true]")].filter(visible);
      const node = candidates.find((input) => [labelFor(input), input.name, input.placeholder, input.id]
        .some((value) => clean(value).toLowerCase() === target))
        || candidates.find((input) => [labelFor(input), input.name, input.placeholder, input.id]
          .some((value) => clean(value).toLowerCase().includes(target)));
      return node ? { point: center(node), type: String(node.type || node.tagName).toLowerCase(), label: labelFor(node) } : null;
    }
    const candidates = [...document.querySelectorAll("button, a, [role=button], [role=menuitem], [role=option]")].filter(visible);
    const node = candidates.find((item) => clean(item.innerText || item.textContent || item.getAttribute("aria-label")).toLowerCase() === target)
      || candidates.find((item) => clean(item.innerText || item.textContent || item.getAttribute("aria-label")).toLowerCase().includes(target));
    return node ? { point: center(node), text: clean(node.innerText || node.textContent || node.getAttribute("aria-label")) } : null;
  })()`);
}

async function main() {
  requireCanonicalSessionLease();
  const { command, options } = parseArgs(process.argv.slice(2));
  const page = await getAppStorePage();
  const client = await connectCdp(page.webSocketDebuggerUrl);
  try {
    await client.send("Page.enable");
    await client.send("Runtime.enable");
    await client.send("Page.bringToFront");
    await client.send("Input.setIgnoreInputEvents", { ignore: false });

    if (command === "goto") {
      if (!isAllowedUrl(options.url)) throw new Error("Refusing to navigate outside App Store Connect HTTPS pages.");
      await client.send("Page.navigate", { url: options.url }, 20000);
      await sleep(4500);
      console.log(JSON.stringify(await inspect(client), null, 2));
      return;
    }
    if (command === "inspect") {
      console.log(JSON.stringify(await inspect(client), null, 2));
      return;
    }
    if (command === "click") {
      const control = await findControl(client, options.text || "", "button");
      if (!control?.point) throw new Error(`Visible App Store Connect control not found: ${options.text || "(empty)"}`);
      await mouseClick(client, control.point);
      await sleep(Number(options.wait || 1800));
      console.log(JSON.stringify(await inspect(client), null, 2));
      return;
    }
    if (command === "fill") {
      const control = await findControl(client, options.target || "", "input");
      if (!control?.point) throw new Error(`Visible App Store Connect input not found: ${options.target || "(empty)"}`);
      if (control.type === "password" || /password|passcode|verification|code|otp/i.test(control.label || options.target || "")) {
        throw new Error("Refusing to read, generate, or inject a secret into a protected field.");
      }
      await selectAllText(client, control.point);
      await client.send("Input.insertText", { text: options.value || "" });
      await sleep(700);
      console.log(JSON.stringify(await inspect(client), null, 2));
      return;
    }
    if (command === "point-fill") {
      const x = Number(options.x);
      const y = Number(options.y);
      if (!Number.isFinite(x) || !Number.isFinite(y) || x < 0 || y < 0 || x > 5000 || y > 5000) {
        throw new Error("point-fill requires safe visible viewport coordinates.");
      }
      if ((options.purpose || "") !== "identity") {
        throw new Error("point-fill is restricted to the public Apple Account identity field.");
      }
      await selectAllText(client, { x, y });
      await client.send("Input.insertText", { text: options.value || "" });
      await sleep(700);
      console.log(JSON.stringify({ url: (await inspect(client)).url, filled: "identity" }, null, 2));
      return;
    }
    if (command === "point-click") {
      const x = Number(options.x);
      const y = Number(options.y);
      if (!Number.isFinite(x) || !Number.isFinite(y) || x < 0 || y < 0 || x > 5000 || y > 5000) {
        throw new Error("point-click requires safe visible viewport coordinates.");
      }
      await mouseClick(client, { x, y });
      await sleep(Number(options.wait || 1800));
      console.log(JSON.stringify(await inspect(client), null, 2));
      return;
    }
    if (command === "point-autofill") {
      const x = Number(options.x);
      const y = Number(options.y);
      if (!Number.isFinite(x) || !Number.isFinite(y) || x < 0 || y < 0 || x > 5000 || y > 5000) {
        throw new Error("point-autofill requires safe visible viewport coordinates.");
      }
      await mouseClick(client, { x, y });
      await key(client, "ArrowDown", "ArrowDown", 40);
      await key(client, "Enter", "Enter", 13);
      await sleep(900);
      console.log(JSON.stringify({ url: (await inspect(client)).url, autofillAttempted: true }, null, 2));
      return;
    }
    if (command === "scroll") {
      await client.send("Input.dispatchMouseEvent", {
        type: "mouseWheel",
        x: Number(options.x || 900),
        y: Number(options.y || 700),
        deltaX: 0,
        deltaY: Number(options.delta || 700),
      });
      await sleep(900);
      console.log(JSON.stringify(await inspect(client), null, 2));
      return;
    }
    if (command === "screenshot") {
      const targetPath = path.resolve(options.path || "artifacts/browser-captures/namesnap-appstore.png");
      fs.mkdirSync(path.dirname(targetPath), { recursive: true });
      const shot = await client.send("Page.captureScreenshot", { format: "png", captureBeyondViewport: false }, 20000);
      fs.writeFileSync(targetPath, Buffer.from(shot.data, "base64"));
      console.log(targetPath);
      return;
    }
    throw new Error(`Unsupported command: ${command}`);
  } finally {
    client.close();
  }
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
