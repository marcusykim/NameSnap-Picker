"use client";

import { useEffect, useRef, useState } from "react";

const address = "sidequestsoftware@proton.me";
const subject = "NameSnap Support";
const encodedAddress = encodeURIComponent(address);
const encodedSubject = encodeURIComponent(subject);

const providers = [
  {
    label: "Email app",
    href: `mailto:${address}?subject=${encodedSubject}`,
  },
  {
    label: "Gmail",
    href: `https://mail.google.com/mail/?view=cm&fs=1&to=${encodedAddress}&su=${encodedSubject}`,
  },
  {
    label: "Outlook",
    href: `https://outlook.office.com/mail/deeplink/compose?to=${encodedAddress}&subject=${encodedSubject}`,
  },
  {
    label: "Yahoo Mail",
    href: `https://compose.mail.yahoo.com/?to=${encodedAddress}&subject=${encodedSubject}`,
  },
];

export function EmailComposeLink() {
  const [copyStatus, setCopyStatus] = useState<"idle" | "copied" | "failed">("idle");
  const resetTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => () => {
    if (resetTimer.current) clearTimeout(resetTimer.current);
  }, []);

  const copyEmail = async () => {
    let copied = false;

    try {
      await navigator.clipboard.writeText(address);
      copied = true;
    } catch {
      const fallback = document.createElement("textarea");
      fallback.value = address;
      fallback.setAttribute("readonly", "");
      fallback.style.position = "fixed";
      fallback.style.opacity = "0";
      document.body.appendChild(fallback);
      fallback.select();
      copied = document.execCommand("copy");
      fallback.remove();
    }

    setCopyStatus(copied ? "copied" : "failed");
    if (resetTimer.current) clearTimeout(resetTimer.current);
    resetTimer.current = setTimeout(() => setCopyStatus("idle"), 2200);
  };

  return (
    <details className="email-compose">
      <summary aria-label="Choose an email app to contact NameSnap support" className="button button-primary">
        Send us an email
      </summary>
      <div className="email-fallback">
        <strong>Choose your email</strong>
        <span>We’ll address a new message to NameSnap support.</span>
        <div className="email-provider-links">
          {providers.map((provider) => (
            <a key={provider.label} href={provider.href} target="_blank" rel="noreferrer">
              {provider.label}
            </a>
          ))}
          <button
            className={`email-copy-button${copyStatus === "copied" ? " is-copied" : ""}`}
            type="button"
            onClick={copyEmail}
          >
            {copyStatus === "copied" ? "Copied!" : copyStatus === "failed" ? "Copy failed" : "Copy email"}
          </button>
        </div>
        <span className="email-copy-status" aria-live="polite">
          {copyStatus === "copied" ? "Email address copied to clipboard." : copyStatus === "failed" ? `Copy failed. Email us at ${address}.` : ""}
        </span>
      </div>
    </details>
  );
}
