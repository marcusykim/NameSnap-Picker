#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const canonicalPort = 9812;
const canonicalLeaseKey = "namesnap";
const allowedHosts = new Set(["proton.me", "account.proton.me", "mail.proton.me"]);
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

function requireCanonicalSessionLease() {
  if (
    process.env.BROWSER_SESSION_LEASE_HELD !== "1"
    || process.env.BROWSER_SESSION_LEASE_KEY !== canonicalLeaseKey
  ) {
    throw new Error(
      "Refusing NameSnap Proton UI work without the namesnap browser-session lease. "
      + "Run this helper through the shared browser-lease wrapper.",
    );
  }
  const configuredPort = process.env.NAMESNAP_UI_DEBUG_PORT;
  if (configuredPort && configuredPort !== String(canonicalPort)) {
    throw new Error(`Refusing noncanonical NameSnap debug port ${configuredPort}; expected ${canonicalPort}.`);
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
      // The canonical project browser may still be starting.
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
            resolve(value) {
              clearTimeout(timer);
              resolveSend(value);
            },
            reject(error) {
              clearTimeout(timer);
              rejectSend(error);
            },
          });
        });
      },
      close() {
        socket.close();
      },
    }));
    socket.addEventListener("error", reject);
  });
}

async function evaluate(client, expression) {
  const response = await client.send("Runtime.evaluate", {
    expression,
    returnByValue: true,
  });
  if (response.exceptionDetails) throw new Error("Could not inspect the visible Proton page.");
  return response.result?.value;
}

async function getProtonPage(preferredSurface = "") {
  const pages = await waitForJson(`http://127.0.0.1:${canonicalPort}/json/list`);
  const candidates = pages.filter((candidate) => (
    candidate.type === "page"
    && candidate.webSocketDebuggerUrl
    && isAllowedUrl(candidate.url)
  ));
  const preferredHost = preferredSurface === "account"
    ? "account.proton.me"
    : preferredSurface === "mail"
      ? "mail.proton.me"
      : "";
  const preferredAccountPage = preferredSurface === "account"
    ? candidates.find((candidate) => {
      const url = new URL(candidate.url);
      return url.hostname.toLowerCase() === "account.proton.me" && url.pathname.startsWith("/u/");
    })
    : null;
  const page = preferredAccountPage
    || (preferredHost
      ? candidates.find((candidate) => new URL(candidate.url).hostname.toLowerCase() === preferredHost)
      : null)
    || candidates.find((candidate) => new URL(candidate.url).hostname.toLowerCase() === "mail.proton.me")
    || candidates.find((candidate) => new URL(candidate.url).hostname.toLowerCase() === "account.proton.me")
    || candidates[0];
  if (!page) {
    throw new Error(`The canonical NameSnap window on port ${canonicalPort} has no registered Proton tab.`);
  }
  return page;
}

async function mouseClick(client, point) {
  await client.send("Input.dispatchMouseEvent", { type: "mouseMoved", x: point.x, y: point.y });
  await client.send("Input.dispatchMouseEvent", {
    type: "mousePressed",
    x: point.x,
    y: point.y,
    button: "left",
    clickCount: 1,
  });
  await client.send("Input.dispatchMouseEvent", {
    type: "mouseReleased",
    x: point.x,
    y: point.y,
    button: "left",
    clickCount: 1,
  });
  await sleep(350);
}

async function key(client, keyValue, code, windowsVirtualKeyCode, modifiers = 0) {
  await client.send("Input.dispatchKeyEvent", {
    type: "rawKeyDown",
    key: keyValue,
    code,
    windowsVirtualKeyCode,
    nativeVirtualKeyCode: windowsVirtualKeyCode,
    modifiers,
  });
  await client.send("Input.dispatchKeyEvent", {
    type: "keyUp",
    key: keyValue,
    code,
    windowsVirtualKeyCode,
    nativeVirtualKeyCode: windowsVirtualKeyCode,
    modifiers,
  });
  await sleep(180);
}

function parseArgs(argv) {
  const [command = "inspect", ...rest] = argv;
  const options = {};
  for (let index = 0; index < rest.length; index += 1) {
    const arg = rest[index];
    if (!arg.startsWith("--")) throw new Error(`Unexpected argument: ${arg}`);
    const name = arg.slice(2);
    options[name] = rest[index + 1] ?? "";
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
      return clean(explicit?.innerText || wrapping?.innerText || input.getAttribute("aria-label") || input.placeholder || input.name);
    };
    return {
      url: location.href,
      title: document.title,
      text: clean(document.body?.innerText).slice(0, 6000),
      buttons: [...document.querySelectorAll("button, a[role=button], a")]
        .filter(visible)
        .map((node) => ({
          text: clean(node.innerText || node.textContent),
          role: node.tagName.toLowerCase(),
          href: node instanceof HTMLAnchorElement ? node.href : "",
          disabled: Boolean(node.disabled || node.getAttribute("aria-disabled") === "true"),
          point: center(node),
        }))
        .filter((item) => item.text)
        .slice(0, 120),
      inputs: [...document.querySelectorAll("input, textarea")]
        .filter(visible)
        .map((input) => ({
          type: String(input.type || input.tagName).toLowerCase(),
          label: labelFor(input),
          name: input.name || "",
          placeholder: input.placeholder || "",
          hasValue: Boolean(input.value),
          point: center(input),
        }))
        .slice(0, 80),
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
      return clean(explicit?.innerText || wrapping?.innerText || input.getAttribute("aria-label") || input.placeholder || input.name);
    };
    if (${JSON.stringify(kind)} === "input") {
      const candidates = [...document.querySelectorAll("input, textarea")].filter(visible);
      const node = candidates.find((input) => [labelFor(input), input.name, input.placeholder, input.id]
        .some((value) => clean(value).toLowerCase() === target))
        || candidates.find((input) => [labelFor(input), input.name, input.placeholder, input.id]
          .some((value) => clean(value).toLowerCase().includes(target)));
      return node ? { point: center(node), type: String(node.type || node.tagName).toLowerCase(), label: labelFor(node) } : null;
    }
    const candidates = [...document.querySelectorAll("button, a[role=button], a")].filter(visible);
    const node = candidates.find((item) => clean(item.innerText || item.textContent).toLowerCase() === target)
      || candidates.find((item) => clean(item.innerText || item.textContent).toLowerCase().includes(target));
    return node ? { point: center(node), text: clean(node.innerText || node.textContent) } : null;
  })()`);
}

async function main() {
  requireCanonicalSessionLease();
  const { command, options } = parseArgs(process.argv.slice(2));
  const page = await getProtonPage(options.surface || "");
  const client = await connectCdp(page.webSocketDebuggerUrl);
  try {
    await client.send("Page.enable");
    await client.send("Runtime.enable");
    await client.send("Page.bringToFront");
    await client.send("Input.setIgnoreInputEvents", { ignore: false });

    if (command === "goto") {
      if (!isAllowedUrl(options.url)) throw new Error("Refusing to navigate the Proton tab outside Proton's HTTPS pages.");
      await client.send("Page.navigate", { url: options.url }, 20000);
      await sleep(3500);
      console.log(JSON.stringify(await inspect(client), null, 2));
      return;
    }

    if (command === "inspect") {
      console.log(JSON.stringify(await inspect(client), null, 2));
      return;
    }

    if (command === "click") {
      const control = await findControl(client, options.text || "", "button");
      if (!control?.point) throw new Error(`Visible Proton control not found: ${options.text || "(empty)"}`);
      await mouseClick(client, control.point);
      await sleep(1200);
      console.log(JSON.stringify(await inspect(client), null, 2));
      return;
    }

    if (command === "fill") {
      const control = await findControl(client, options.target || "", "input");
      if (!control?.point) throw new Error(`Visible Proton input not found: ${options.target || "(empty)"}`);
      if (control.type === "password" || /password|passcode|verification|code|otp/i.test(control.label || options.target || "")) {
        throw new Error("Refusing to read, generate, or inject a secret into a protected field.");
      }
      await mouseClick(client, control.point);
      await key(client, "a", "KeyA", 65, 4);
      await client.send("Input.insertText", { text: options.value || "" });
      await sleep(600);
      console.log(JSON.stringify(await inspect(client), null, 2));
      return;
    }

    if (command === "point-fill") {
      const x = Number(options.x);
      const y = Number(options.y);
      if (!Number.isFinite(x) || !Number.isFinite(y) || x < 0 || y < 0 || x > 5000 || y > 5000) {
        throw new Error("point-fill requires safe visible viewport coordinates.");
      }
      if ((options.purpose || "") !== "username") {
        throw new Error("point-fill is restricted to the public Proton username field.");
      }
      await mouseClick(client, { x, y });
      await key(client, "a", "KeyA", 65, 4);
      await client.send("Input.insertText", { text: options.value || "" });
      await sleep(900);
      console.log(JSON.stringify({ url: (await inspect(client)).url, filled: "username" }, null, 2));
      return;
    }

    if (command === "autofill") {
      const control = await findControl(client, options.target || "Password", "input");
      if (!control?.point) throw new Error(`Visible Proton protected input not found: ${options.target || "Password"}`);
      await mouseClick(client, control.point);
      await key(client, "ArrowDown", "ArrowDown", 40);
      await key(client, "Enter", "Enter", 13);
      await sleep(900);
      const state = await inspect(client);
      console.log(JSON.stringify({
        url: state.url,
        title: state.title,
        protectedFields: state.inputs
          .filter((input) => input.type === "password")
          .map((input) => ({ label: input.label, hasValue: input.hasValue })),
      }, null, 2));
      return;
    }

    if (command === "screenshot") {
      const targetPath = path.resolve(options.path || "artifacts/browser-captures/namesnap-proton.png");
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
