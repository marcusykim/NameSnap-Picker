"use client";

/* eslint-disable @next/next/no-html-link-for-pages, @next/next/no-img-element, react-hooks/set-state-in-effect, jsx-a11y/label-has-associated-control */

import { type ClipboardEvent as ReactClipboardEvent, type CSSProperties, type KeyboardEvent as ReactKeyboardEvent, useCallback, useEffect, useMemo, useRef, useState } from "react";
import { isSignInWithEmailLink, onAuthStateChanged, sendSignInLinkToEmail, signInWithEmailLink, signOut } from "firebase/auth";
import { namesnapAuth } from "./firebase-auth";

type Entry = { id: string; drawNumber: number; name: string; included: boolean };
type Winner = { id: string; name: string; number: number; pickedAt: string };
type PickerMode = "classic" | "wheel";
type CelebrationHero =
  | "dancer" | "guitarist" | "dynamite" | "hype-mascot" | "pixel-bomb"
  | "breakdancer" | "dj" | "drummer" | "skater" | "trumpet"
  | "saxophonist" | "cheer-captain" | "magician" | "skateboarder"
  | "soccer-striker" | "basketball-dunker" | "astronaut" | "robot"
  | "superhero" | "opera-singer" | "punk-vocalist" | "keytarist"
  | "disco-dancer" | "conductor" | "juggler" | "pirate-captain"
  | "knight" | "rocket-scientist" | "gamer" | "rodeo-star";
type Celebration = {
  variation: number;
  hero: CelebrationHero;
  palette: number;
  direction: "left" | "right";
  audio: string;
};
type Confirmation = {
  kicker: string;
  message: string;
  confirmLabel: string;
  onConfirm: () => void;
};

const FREE_LIMIT = 16;
const POOL_PREVIEW_LIMIT = 20;
const STORAGE_KEY = "namesnap.web.session.v1";
const PENDING_NAMES_KEY = "namesnap.web.pending-upgrade.v1";
const IDENTITY_KEY = "namesnap.web.identity.v1";
const AUTH_EMAIL_KEY = "namesnap.web.purchase-email.v1";
const API_URL = "https://namesnap-web-payments.royal-fog-6bed.workers.dev";
const APP_STORE_URL = "https://apps.apple.com/app/id6759588637";
const WHEEL_COLORS = [
  "#F7DC60",
  "#6BA3CC",
  "#E0F4AB",
  "rgba(255, 45, 85, .52)",
  "#C7AB8A",
  "rgba(175, 82, 222, .45)",
];
const WHEEL_INK = "#15151B";
const WHEEL_CARD = "#F2F4FA";
const WHEEL_LABEL_FONT = '-apple-system, BlinkMacSystemFont, "SF Pro Text", "Segoe UI", sans-serif';
const AUDIO_TRACKS = Array.from(
  { length: 100 },
  (_, index) => `/sounds/winner_music_${String(index + 1).padStart(3, "0")}.mp3`,
);
const CELEBRATION_HEROES: CelebrationHero[] = [
  "dancer", "guitarist", "dynamite", "hype-mascot", "pixel-bomb",
  "breakdancer", "dj", "drummer", "skater", "trumpet",
  "saxophonist", "cheer-captain", "magician", "skateboarder",
  "soccer-striker", "basketball-dunker", "astronaut", "robot",
  "superhero", "opera-singer", "punk-vocalist", "keytarist",
  "disco-dancer", "conductor", "juggler", "pirate-captain",
  "knight", "rocket-scientist", "gamer", "rodeo-star",
];
const CELEBRATION_VARIATION_COUNT = 300;
const CELEBRATION_HEADLINES = ["THE PICK IS IN", "ABSOLUTE LEGEND", "WINNER ENERGY", "MAKE SOME NOISE", "MAIN CHARACTER MOMENT"];
const HERO_LABELS: Record<CelebrationHero, string> = {
  dancer: "Victory dance",
  guitarist: "Face-melting solo",
  dynamite: "Celebration blast",
  "hype-mascot": "Maximum hype",
  "pixel-bomb": "Bonus explosion",
  breakdancer: "Breakdance victory",
  dj: "Dance-floor takeover",
  drummer: "Thunderous drum solo",
  skater: "Victory on wheels",
  trumpet: "Stadium fanfare",
  saxophonist: "Saxophone victory solo",
  "cheer-captain": "Jump-and-cheer finale",
  magician: "Confetti magic",
  skateboarder: "Kickflip victory",
  "soccer-striker": "Goal celebration",
  "basketball-dunker": "Victory dunk",
  astronaut: "Zero-gravity victory",
  robot: "Robot victory dance",
  superhero: "Hero landing",
  "opera-singer": "Final victory note",
  "punk-vocalist": "Punk encore",
  keytarist: "Keytar takeover",
  "disco-dancer": "Disco victory",
  conductor: "Triumphant finale",
  juggler: "Victory juggling act",
  "pirate-captain": "Treasure champion",
  knight: "Shield-raised champion",
  "rocket-scientist": "Rocket-powered genius",
  gamer: "Game-winning jump",
  "rodeo-star": "Rodeo victory",
};

function makeId() {
  if (typeof crypto !== "undefined" && "randomUUID" in crypto) return crypto.randomUUID();
  return `${Date.now()}-${Math.random().toString(16).slice(2)}`;
}

function randomIndex(length: number) {
  if (length <= 1) return 0;
  const max = Math.floor(0x1_0000_0000 / length) * length;
  const bucket = new Uint32Array(1);
  do crypto.getRandomValues(bucket); while (bucket[0] >= max);
  return bucket[0] % length;
}

function createCelebration(variation = randomIndex(CELEBRATION_VARIATION_COUNT)): Celebration {
  const safeVariation = ((variation % CELEBRATION_VARIATION_COUNT) + CELEBRATION_VARIATION_COUNT) % CELEBRATION_VARIATION_COUNT;
  return {
    variation: safeVariation,
    hero: CELEBRATION_HEROES[safeVariation % CELEBRATION_HEROES.length],
    palette: Math.floor(safeVariation / CELEBRATION_HEROES.length) % 5,
    direction: safeVariation < CELEBRATION_VARIATION_COUNT / 2 ? "right" : "left",
    audio: AUDIO_TRACKS[safeVariation % AUDIO_TRACKS.length],
  };
}

function celebrationParticles(variation: number) {
  return Array.from({ length: 84 }, (_, index) => {
    const seed = variation * 97 + index * 41;
    const x = (seed * 29) % 101;
    const drift = ((seed * 17) % 45) - 22;
    const delay = -((seed * 13) % 1800);
    const duration = 2200 + ((seed * 23) % 2300);
    const rotation = (seed * 31) % 720;
    const size = 7 + ((seed * 7) % 12);
    return {
      index,
      style: {
        "--piece-x": `${x}vw`,
        "--piece-drift": `${drift}vw`,
        "--piece-delay": `${delay}ms`,
        "--piece-duration": `${duration}ms`,
        "--piece-rotation": `${rotation}deg`,
        "--piece-size": `${size}px`,
      } as CSSProperties,
    };
  });
}

function parseNames(input: string) {
  return input
    .split(/[\n,]+/)
    .map((name) => name.replace(/^\s*\d+[.)-]?\s*/, "").trim())
    .filter(Boolean);
}

function normalizedName(name: string) {
  return name
    .trim()
    .normalize("NFD")
    .replace(/\p{Diacritic}/gu, "")
    .toLocaleLowerCase();
}

function namesExcludingDuplicates(names: string[], poolNames: string[]) {
  const seenNames = new Set(poolNames.map(normalizedName));
  return names.filter((name) => {
    const key = normalizedName(name);
    if (seenNames.has(key)) return false;
    seenNames.add(key);
    return true;
  });
}

function stagedInputRows(input: string) {
  return input
    .split("\n")
    .map((name) => name.replace(/^\s*\d+[.)-]?\s*/, "").replace(/\r/g, ""))
    .filter((name) => name.trim().length > 0);
}

function writeInputNames(names: string[]) {
  return names
    .filter((name) => name.trim().length > 0)
    .map((name, index) => `${index + 1}. ${name}`)
    .join("\n");
}

function TrashGlyph({ filled = false }: { filled?: boolean }) {
  return <span className={`trash-glyph ${filled ? "trash-glyph-filled" : "trash-glyph-outline"}`} aria-hidden="true" />;
}

function NumberedNameEditor({ value, onChange, onRequestRemove }: {
  value: string;
  onChange: (next: string) => void;
  onRequestRemove: (name: string, remove: () => void) => void;
}) {
  const rows = stagedInputRows(value);
  const rowRefs = useRef(new Map<number, HTMLInputElement>());

  const focusRow = (index: number, placeCursorAtEnd = false) => {
    window.requestAnimationFrame(() => {
      const input = rowRefs.current.get(index);
      input?.focus();
      if (input && placeCursorAtEnd) input.setSelectionRange(input.value.length, input.value.length);
    });
  };

  const commitRows = (nextRows: string[]) => onChange(writeInputNames(nextRows));

  const updateRow = (index: number, nextValue: string) => {
    if (nextValue.includes("\n") || nextValue.includes(",")) {
      const incoming = parseNames(nextValue);
      const nextRows = [...rows];
      if (index < rows.length) nextRows.splice(index, 1, ...incoming);
      else nextRows.push(...incoming);
      commitRows(nextRows);
      focusRow(Math.min(index + incoming.length, nextRows.length));
      return;
    }

    const nextRows = [...rows];
    if (index < rows.length) {
      if (nextValue.trim().length) nextRows[index] = nextValue;
      else nextRows.splice(index, 1);
    } else if (nextValue.trim().length) {
      nextRows.push(nextValue);
    }
    commitRows(nextRows);
  };

  const pasteAtRow = (event: ReactClipboardEvent<HTMLInputElement>, index: number) => {
    const pasted = event.clipboardData.getData("text");
    if (!pasted.includes("\n") && !pasted.includes(",")) return;
    event.preventDefault();
    const incoming = parseNames(pasted);
    if (!incoming.length) return;
    const nextRows = [...rows];
    if (index < rows.length) nextRows.splice(index, 1, ...incoming);
    else nextRows.push(...incoming);
    commitRows(nextRows);
    focusRow(Math.min(index + incoming.length, nextRows.length));
  };

  const handleRowKey = (event: ReactKeyboardEvent<HTMLInputElement>, index: number) => {
    if (event.key === "Enter") {
      event.preventDefault();
      focusRow(Math.min(index + 1, rows.length));
      return;
    }
    if (event.key === "Backspace" && !event.currentTarget.value && index > 0) {
      event.preventDefault();
      focusRow(index - 1, true);
    }
  };

  return (
    <div className="name-editor" role="group" aria-label="Numbered contestant input">
      {[...rows, ""].map((name, index) => {
        const isEntryRow = index < rows.length;
        return (
          <div className={`name-editor-row ${isEntryRow ? "" : "name-editor-row-new"}`} key={index}>
            <span className="name-editor-number" aria-hidden="true">{index + 1}.</span>
            <input
              id={index === 0 ? "contestant-input" : undefined}
              ref={(node) => { if (node) rowRefs.current.set(index, node); else rowRefs.current.delete(index); }}
              value={name}
              onChange={(event) => updateRow(index, event.target.value)}
              onPaste={(event) => pasteAtRow(event, index)}
              onKeyDown={(event) => handleRowKey(event, index)}
              placeholder={isEntryRow ? undefined : "Type or paste names here…"}
              aria-label={`Contestant ${index + 1}`}
              autoComplete="off"
              spellCheck={false}
            />
            {isEntryRow ? (
              <button
                className="input-trash"
                type="button"
                aria-label={`Remove staged contestant ${index + 1}: ${name.trim()}`}
                onClick={() => onRequestRemove(name.trim(), () => {
                    const nextRows = rows.filter((_, rowIndex) => rowIndex !== index);
                    commitRows(nextRows);
                    focusRow(Math.min(index, nextRows.length));
                  })}
              >
                <TrashGlyph filled />
              </button>
            ) : <span className="trash-spacer" aria-hidden="true" />}
          </div>
        );
      })}
    </div>
  );
}

function renumberEntries(entries: Entry[]) {
  return entries.map((entry, index) => ({ ...entry, drawNumber: index + 1 }));
}

function restoreStoredEntries(value: unknown): Entry[] {
  if (!Array.isArray(value)) return [];
  const valid = value.filter((entry): entry is Partial<Entry> & { name: string } => (
    !!entry && typeof entry === "object" && typeof entry.name === "string" && entry.name.trim().length > 0
  ));
  return valid.map((entry, index) => ({
    id: typeof entry.id === "string" ? entry.id : makeId(),
    drawNumber: index + 1,
    name: entry.name.trim(),
    included: entry.included !== false,
  }));
}

function initials(name: string) {
  return name.split(/\s+/).slice(0, 2).map((part) => part[0]?.toUpperCase()).join("");
}

function fitWheelLabel(context: CanvasRenderingContext2D, entry: Entry, maxWidth: number) {
  const prefix = `${entry.drawNumber}. `;
  const fullLabel = `${prefix}${entry.name}`;
  if (context.measureText(fullLabel).width <= maxWidth) return fullLabel;

  const ellipsis = "…";
  if (context.measureText(`${prefix}${ellipsis}`).width > maxWidth) return `${entry.drawNumber}.`;

  let low = 0;
  let high = entry.name.length;
  while (low < high) {
    const midpoint = Math.ceil((low + high) / 2);
    const candidate = `${prefix}${entry.name.slice(0, midpoint).trimEnd()}${ellipsis}`;
    if (context.measureText(candidate).width <= maxWidth) low = midpoint;
    else high = midpoint - 1;
  }
  return `${prefix}${entry.name.slice(0, low).trimEnd()}${ellipsis}`;
}

async function apiJson(response: Response) {
  try {
    return await response.json();
  } catch {
    throw new Error("NameSnap checkout is temporarily unavailable. Please try again.");
  }
}

function browserIdentity() {
  const existing = localStorage.getItem(IDENTITY_KEY);
  if (existing && /^[A-Za-z0-9_-]{43,128}$/.test(existing)) return existing;
  const bytes = crypto.getRandomValues(new Uint8Array(32));
  const token = btoa(String.fromCharCode(...bytes)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  localStorage.setItem(IDENTITY_KEY, token);
  return token;
}

async function apiFetch(path: string, init: RequestInit = {}) {
  const headers = new Headers(init.headers);
  headers.set("X-NameSnap-Identity", browserIdentity());
  const user = namesnapAuth.currentUser;
  if (user?.emailVerified) headers.set("Authorization", `Bearer ${await user.getIdToken()}`);
  return fetch(`${API_URL}${path}`, { ...init, headers, cache: "no-store" });
}

export function NameSnapWebApp() {
  const [input, setInput] = useState("");
  const [entries, setEntries] = useState<Entry[]>([]);
  const [lastAddedIds, setLastAddedIds] = useState<string[]>([]);
  const [history, setHistory] = useState<Winner[]>([]);
  const [excludedIds, setExcludedIds] = useState<string[]>([]);
  const [mode, setMode] = useState<PickerMode>("wheel");
  const [noRepeats, setNoRepeats] = useState(true);
  const [soundOn, setSoundOn] = useState(true);
  const [presentation, setPresentation] = useState(false);
  const [isSpinning, setIsSpinning] = useState(false);
  const [liveName, setLiveName] = useState("Ready when you are");
  const [winner, setWinner] = useState<Winner | null>(null);
  const [celebration, setCelebration] = useState<Celebration | null>(null);
  const [showPoolSheet, setShowPoolSheet] = useState(false);
  const [showRecentPicks, setShowRecentPicks] = useState(false);
  const [confirmation, setConfirmation] = useState<Confirmation | null>(null);
  const [pendingDuplicateNames, setPendingDuplicateNames] = useState<string[]>([]);
  const [rotation, setRotation] = useState(0);
  const [showUpgrade, setShowUpgrade] = useState(false);
  const [pendingNames, setPendingNames] = useState<string[]>([]);
  const [entitlementPlan, setEntitlementPlan] = useState<"monthly" | "lifetime" | null>(null);
  const [subscriptionCancellationRequired, setSubscriptionCancellationRequired] = useState(false);
  const [checkoutBusy, setCheckoutBusy] = useState<"monthly" | "lifetime" | "restore" | null>(null);
  const [checkoutError, setCheckoutError] = useState<string | null>(null);
  const [authReady, setAuthReady] = useState(false);
  const [accountEmail, setAccountEmail] = useState<string | null>(null);
  const [authEmail, setAuthEmail] = useState("");
  const [authBusy, setAuthBusy] = useState(false);
  const [authNotice, setAuthNotice] = useState<string | null>(null);
  const [emailLinkNeedsAddress, setEmailLinkNeedsAddress] = useState(false);
  const [hydrated, setHydrated] = useState(false);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const stageRef = useRef<HTMLDivElement>(null);
  const fullscreenSessionRef = useRef(false);
  const fullscreenRequestStartedAtRef = useRef(0);
  const poolSheetCloseRef = useRef<HTMLButtonElement>(null);
  const recentPicksCloseRef = useRef<HTMLButtonElement>(null);
  const confirmationCancelRef = useRef<HTMLButtonElement>(null);
  const duplicateCancelRef = useRef<HTMLButtonElement>(null);
  const winnerDoneRef = useRef<HTMLButtonElement>(null);
  const winnerAudioRef = useRef<HTMLAudioElement | null>(null);
  const timersRef = useRef<number[]>([]);

  useEffect(() => {
    try {
      const stored = JSON.parse(localStorage.getItem(STORAGE_KEY) ?? "null");
      if (stored) {
        setEntries(restoreStoredEntries(stored.entries));
        setHistory(Array.isArray(stored.history) ? stored.history : []);
        setExcludedIds(Array.isArray(stored.excludedIds) ? stored.excludedIds : []);
        setMode(stored.mode === "classic" ? "classic" : "wheel");
        setNoRepeats(stored.noRepeats !== false);
        setSoundOn(stored.soundOn !== false);
      }
    } catch {
      localStorage.removeItem(STORAGE_KEY);
    }
    setHydrated(true);
  }, []);

  useEffect(() => onAuthStateChanged(namesnapAuth, (user) => {
    setAccountEmail(user?.emailVerified ? user.email : null);
    setAuthEmail(user?.email ?? localStorage.getItem(AUTH_EMAIL_KEY) ?? "");
    setAuthReady(true);
  }), []);

  useEffect(() => {
    if (!isSignInWithEmailLink(namesnapAuth, window.location.href)) return;
    setShowUpgrade(true);
    const storedEmail = localStorage.getItem(AUTH_EMAIL_KEY);
    if (!storedEmail) {
      setEmailLinkNeedsAddress(true);
      setAuthNotice("Enter the same email address that received the secure sign-in link.");
      return;
    }

    let cancelled = false;
    const complete = async () => {
      setAuthBusy(true);
      setCheckoutError(null);
      try {
        await signInWithEmailLink(namesnapAuth, storedEmail, window.location.href);
        if (cancelled) return;
        localStorage.removeItem(AUTH_EMAIL_KEY);
        setAuthNotice("Purchase account verified. You can buy once and restore on another browser.");
        window.history.replaceState({}, "", window.location.pathname);
      } catch {
        if (!cancelled) setCheckoutError("That sign-in link is invalid or expired. Request a new link below.");
      } finally {
        if (!cancelled) setAuthBusy(false);
      }
    };
    void complete();
    return () => { cancelled = true; };
  }, []);

  useEffect(() => {
    if (!hydrated) return;
    localStorage.setItem(STORAGE_KEY, JSON.stringify({ entries, history, excludedIds, mode, noRepeats, soundOn }));
  }, [entries, excludedIds, history, hydrated, mode, noRepeats, soundOn]);

  useEffect(() => () => {
    timersRef.current.forEach((timer) => window.clearTimeout(timer));
    winnerAudioRef.current?.pause();
    winnerAudioRef.current = null;
  }, []);

  useEffect(() => {
    if (!showPoolSheet) return;
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    const focusFrame = window.requestAnimationFrame(() => poolSheetCloseRef.current?.focus());
    return () => {
      window.cancelAnimationFrame(focusFrame);
      document.body.style.overflow = previousOverflow;
    };
  }, [showPoolSheet]);

  useEffect(() => {
    if (!showRecentPicks) return;
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    const focusFrame = window.requestAnimationFrame(() => recentPicksCloseRef.current?.focus());
    return () => {
      window.cancelAnimationFrame(focusFrame);
      document.body.style.overflow = previousOverflow;
    };
  }, [showRecentPicks]);

  useEffect(() => {
    if (!confirmation) return;
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    const focusFrame = window.requestAnimationFrame(() => confirmationCancelRef.current?.focus());
    return () => {
      window.cancelAnimationFrame(focusFrame);
      document.body.style.overflow = previousOverflow;
    };
  }, [confirmation]);

  useEffect(() => {
    if (!pendingDuplicateNames.length) return;
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    const focusFrame = window.requestAnimationFrame(() => duplicateCancelRef.current?.focus());
    return () => {
      window.cancelAnimationFrame(focusFrame);
      document.body.style.overflow = previousOverflow;
    };
  }, [pendingDuplicateNames]);

  useEffect(() => {
    if (!winner) return;
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    const focusTimer = window.setTimeout(() => winnerDoneRef.current?.focus(), 650);
    return () => {
      window.clearTimeout(focusTimer);
      document.body.style.overflow = previousOverflow;
    };
  }, [winner]);

  useEffect(() => {
    const syncFullscreenState = () => {
      if (document.fullscreenElement === stageRef.current) {
        fullscreenSessionRef.current = true;
        setPresentation(true);
        return;
      }

      if (!fullscreenSessionRef.current) return;
      const browserDroppedFullscreenDuringLaunch = performance.now() - fullscreenRequestStartedAtRef.current < 1200;
      fullscreenSessionRef.current = false;
      if (!browserDroppedFullscreenDuringLaunch) setPresentation(false);
    };
    document.addEventListener("fullscreenchange", syncFullscreenState);
    return () => document.removeEventListener("fullscreenchange", syncFullscreenState);
  }, []);

  useEffect(() => {
    if (!presentation) return;
    const previousOverflow = document.body.style.overflow;
    const exitFallbackOnEscape = (event: KeyboardEvent) => {
      if (event.key === "Escape" && !document.fullscreenElement) setPresentation(false);
    };
    document.body.style.overflow = "hidden";
    window.addEventListener("keydown", exitFallbackOnEscape);
    return () => {
      document.body.style.overflow = previousOverflow;
      window.removeEventListener("keydown", exitFallbackOnEscape);
    };
  }, [presentation]);

  const activeEntries = useMemo(
    () => entries.filter((entry) => entry.included && (!noRepeats || !excludedIds.includes(entry.id))),
    [entries, excludedIds, noRepeats],
  );
  const celebrationPieces = useMemo(
    () => celebrationParticles(celebration?.variation ?? 0),
    [celebration?.variation],
  );
  const isPremium = entitlementPlan !== null;

  const applyEntitlement = useCallback((data: { active?: boolean; plan?: string | null; subscriptionStatus?: string | null }) => {
    setSubscriptionCancellationRequired(data.plan === "lifetime" && data.subscriptionStatus === "cancellation_required");
    if (data.active && (data.plan === "monthly" || data.plan === "lifetime")) {
      setEntitlementPlan(data.plan);
      return true;
    }
    setEntitlementPlan(null);
    return false;
  }, []);

  useEffect(() => {
    if (!authReady) return;
    let cancelled = false;
    const refresh = async () => {
      const query = new URLSearchParams(window.location.search);
      const checkoutSucceeded = query.get("checkout") === "success";
      if (checkoutSucceeded) {
        setShowUpgrade(true);
        setCheckoutBusy("restore");
        setCheckoutError(null);
      }
      try {
        let unlocked = false;
        let cancellationRequired = false;
        const attempts = checkoutSucceeded ? 16 : 1;
        for (let attempt = 0; attempt < attempts && !cancelled; attempt += 1) {
          const response = await apiFetch("/api/status");
          const data = await apiJson(response);
          if (!response.ok) throw new Error(data.error ?? "Could not check web purchase status.");
          unlocked = applyEntitlement(data);
          cancellationRequired = data.plan === "lifetime" && data.subscriptionStatus === "cancellation_required";
          if (!unlocked && checkoutSucceeded && attempt < attempts - 1) {
            await new Promise((resolve) => window.setTimeout(resolve, 750));
          }
        }
        if (cancelled) return;
        if (!unlocked && checkoutSucceeded) throw new Error("Stripe received the checkout. Choose Restore web purchase in a moment while access finishes updating.");
        if (unlocked && checkoutSucceeded) {
          const queued = parseNames(sessionStorage.getItem(PENDING_NAMES_KEY) ?? "");
          if (queued.length) {
            const additions = queued.map((name) => ({ id: makeId(), drawNumber: 0, name, included: true }));
            setEntries((current) => renumberEntries([...current, ...additions]));
            setLastAddedIds(additions.map((entry) => entry.id));
            sessionStorage.removeItem(PENDING_NAMES_KEY);
          }
          if (!cancellationRequired) setShowUpgrade(false);
        }
        if (query.has("checkout")) window.history.replaceState({}, "", window.location.pathname);
      } catch (error) {
        if (query.has("checkout")) setCheckoutError(error instanceof Error ? error.message : "Could not check web purchase status.");
      } finally {
        if (checkoutSucceeded && !cancelled) setCheckoutBusy(null);
      }
    };
    void refresh();
    return () => { cancelled = true; };
  }, [accountEmail, applyEntitlement, authReady]);

  const drawWheel = useCallback(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const size = Math.max(320, Math.min(canvas.clientWidth || 620, canvas.clientHeight || 620));
    const ratio = window.devicePixelRatio || 1;
    canvas.width = size * ratio;
    canvas.height = size * ratio;
    const context = canvas.getContext("2d");
    if (!context) return;
    context.scale(ratio, ratio);
    context.clearRect(0, 0, size, size);
    const center = size / 2;
    const radius = size / 2 - 12;
    const visibleEntries = activeEntries;
    const segmentCount = Math.max(visibleEntries.length, 1);
    const segmentAngle = (Math.PI * 2) / segmentCount;

    for (let index = 0; index < segmentCount; index += 1) {
      const start = -Math.PI / 2 + index * segmentAngle;
      const end = start + segmentAngle;
      context.beginPath();
      context.moveTo(center, center);
      context.arc(center, center, radius, start, end);
      context.closePath();
      context.fillStyle = visibleEntries.length ? WHEEL_COLORS[index % WHEEL_COLORS.length] : WHEEL_CARD;
      context.fill();
      context.strokeStyle = "rgba(16, 18, 26, .72)";
      context.lineWidth = visibleEntries.length <= 40 ? 2 : 0.7;
      context.stroke();

      if (visibleEntries.length && visibleEntries.length <= 40) {
        context.save();
        context.beginPath();
        context.moveTo(center, center);
        context.arc(center, center, radius, start, end);
        context.closePath();
        context.clip();
        context.translate(center, center);
        const labelAngle = start + segmentAngle / 2;
        context.rotate(labelAngle);
        const normalizedAngle = (labelAngle + Math.PI * 2) % (Math.PI * 2);
        const shouldFlip = normalizedAngle > Math.PI / 2 && normalizedAngle < Math.PI * 1.5;
        if (shouldFlip) context.rotate(Math.PI);
        context.textBaseline = "middle";
        context.fillStyle = WHEEL_INK;
        const showFullLabel = visibleEntries.length <= 12;
        const fontSize = showFullLabel
          ? Math.max(11, Math.min(size < 400 ? 13 : 15, 210 / visibleEntries.length + 8))
          : Math.max(10, Math.min(13, 150 / visibleEntries.length + 7));
        context.font = `${showFullLabel ? 700 : 800} ${fontSize}px ${WHEEL_LABEL_FONT}`;

        const labelStart = radius * (showFullLabel ? 0.3 : 0.62);
        const anchorX = shouldFlip ? -labelStart : labelStart;
        context.textAlign = shouldFlip ? "right" : "left";
        const label = showFullLabel
          ? fitWheelLabel(context, visibleEntries[index], radius - labelStart - 18)
          : `${visibleEntries[index].drawNumber}.`;
        context.fillText(label, anchorX, 0);
        context.restore();
      }
    }

    context.beginPath();
    context.arc(center, center, radius * 0.2, 0, Math.PI * 2);
    context.fillStyle = WHEEL_INK;
    context.fill();
    context.beginPath();
    context.arc(center, center, radius * 0.13, 0, Math.PI * 2);
    context.fillStyle = WHEEL_CARD;
    context.fill();
  }, [activeEntries]);

  useEffect(() => {
    if (mode !== "wheel") return;
    const drawFrame = window.requestAnimationFrame(drawWheel);
    const resize = new ResizeObserver(drawWheel);
    if (canvasRef.current) resize.observe(canvasRef.current);
    void document.fonts?.ready.then(drawWheel);
    return () => {
      window.cancelAnimationFrame(drawFrame);
      resize.disconnect();
    };
  }, [drawWheel, mode]);

  const stopWinnerAudio = useCallback(() => {
    if (!winnerAudioRef.current) return;
    winnerAudioRef.current.pause();
    winnerAudioRef.current.currentTime = 0;
    winnerAudioRef.current = null;
  }, []);

  const playWinnerAudio = useCallback((track: string) => {
    if (!soundOn) return;
    stopWinnerAudio();
    const audio = new Audio(track);
    winnerAudioRef.current = audio;
    audio.volume = 0.76;
    // Every eligible file is verified music at 120+ BPM and at least five
    // seconds long. Looping keeps the soundtrack continuous for the full modal.
    audio.loop = true;
    void audio.play().catch(() => undefined);
    const timer = window.setTimeout(() => {
      if (winnerAudioRef.current === audio) stopWinnerAudio();
    }, 5800);
    timersRef.current.push(timer);
  }, [soundOn, stopWinnerAudio]);

  const presentWinner = useCallback((result: Winner, playSound = true) => {
    const nextCelebration = createCelebration();
    setWinner(result);
    setCelebration(nextCelebration);
    if (playSound) playWinnerAudio(nextCelebration.audio);
  }, [playWinnerAudio]);

  const dismissWinner = useCallback(() => {
    stopWinnerAudio();
    setWinner(null);
  }, [stopWinnerAudio]);

  const finishPick = useCallback((selected: Entry) => {
    const number = selected.drawNumber;
    const result = { id: makeId(), name: selected.name, number, pickedAt: new Date().toISOString() };
    setLiveName(`${number}. ${selected.name}`);
    presentWinner(result);
    setHistory((current) => [result, ...current].slice(0, 20));
    if (noRepeats) setExcludedIds((current) => [...new Set([...current, selected.id])]);
    setIsSpinning(false);
  }, [noRepeats, presentWinner]);

  const spin = useCallback(() => {
    if (isSpinning || !activeEntries.length) return;
    dismissWinner();
    setIsSpinning(true);
    const selected = activeEntries[randomIndex(activeEntries.length)];

    if (mode === "classic") {
      const started = performance.now();
      const tick = () => {
        const elapsed = performance.now() - started;
        if (elapsed >= 2200) { finishPick(selected); return; }
        const preview = activeEntries[randomIndex(activeEntries.length)];
        setLiveName(`${preview.drawNumber}. ${preview.name}`);
        const timer = window.setTimeout(tick, Math.min(220, 45 + elapsed / 14));
        timersRef.current.push(timer);
      };
      tick();
      return;
    }

    const wheelIndex = activeEntries.findIndex((entry) => entry.id === selected.id);
    const segmentAngle = 360 / Math.max(activeEntries.length, 1);
    const target = (360 - (wheelIndex + 0.5) * segmentAngle + 360) % 360;
    setRotation((current) => {
      const normalized = ((current % 360) + 360) % 360;
      const delta = (target - normalized + 360) % 360;
      return current + 5 * 360 + delta;
    });
    const timer = window.setTimeout(() => finishPick(selected), 3900);
    timersRef.current.push(timer);
  }, [activeEntries, dismissWinner, finishPick, isSpinning, mode]);

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (confirmation) {
        if (event.key === "Escape") setConfirmation(null);
        return;
      }
      if (pendingDuplicateNames.length) {
        if (event.key === "Escape") setPendingDuplicateNames([]);
        return;
      }
      if (event.code === "Space" && !(event.target instanceof HTMLTextAreaElement || event.target instanceof HTMLInputElement)) {
        event.preventDefault();
        spin();
      }
      if (event.key === "Escape") {
        dismissWinner();
        setShowPoolSheet(false);
        setShowRecentPicks(false);
      }
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [confirmation, dismissWinner, pendingDuplicateNames.length, spin]);

  const appendNamesToPool = (names: string[]) => {
    if (!names.length) return;
    if (!isPremium && entries.length + names.length > FREE_LIMIT) {
      setPendingNames(names);
      setShowUpgrade(true);
      return;
    }
    const additions = names.map((name) => ({ id: makeId(), drawNumber: 0, name, included: true }));
    setEntries((current) => renumberEntries([...current, ...additions]));
    setLastAddedIds(additions.map((entry) => entry.id));
  };

  const addNames = () => {
    const names = parseNames(input);
    if (!names.length) return;
    const uniqueNames = namesExcludingDuplicates(names, entries.map((entry) => entry.name));
    if (uniqueNames.length !== names.length) {
      setPendingDuplicateNames(names);
      return;
    }
    appendNamesToPool(names);
  };

  const sendPurchaseAccountLink = async () => {
    const email = authEmail.trim().toLocaleLowerCase();
    if (!/^\S+@\S+\.\S+$/.test(email)) {
      setCheckoutError("Enter a valid email address.");
      return;
    }
    setAuthBusy(true);
    setCheckoutError(null);
    setAuthNotice(null);
    try {
      await sendSignInLinkToEmail(namesnapAuth, email, {
        url: `${window.location.origin}/?purchaseAccount=complete`,
        handleCodeInApp: true,
        linkDomain: "getnamesnap.web.app",
      });
      localStorage.setItem(AUTH_EMAIL_KEY, email);
      setAuthNotice(`Secure sign-in link sent to ${email}. Open it to continue.`);
    } catch {
      setCheckoutError("Could not send the secure sign-in link. Check the address and try again.");
    } finally {
      setAuthBusy(false);
    }
  };

  const completePurchaseAccountLink = async () => {
    const email = authEmail.trim().toLocaleLowerCase();
    if (!/^\S+@\S+\.\S+$/.test(email)) {
      setCheckoutError("Enter the email address that received this link.");
      return;
    }
    setAuthBusy(true);
    setCheckoutError(null);
    try {
      await signInWithEmailLink(namesnapAuth, email, window.location.href);
      localStorage.removeItem(AUTH_EMAIL_KEY);
      setEmailLinkNeedsAddress(false);
      setAuthNotice("Purchase account verified. Your web purchase can now follow you to another browser.");
      window.history.replaceState({}, "", window.location.pathname);
    } catch {
      setCheckoutError("That email does not match this sign-in link, or the link has expired.");
    } finally {
      setAuthBusy(false);
    }
  };

  const startCheckout = async (plan: "monthly" | "lifetime") => {
    if (!namesnapAuth.currentUser?.emailVerified) {
      setAccountEmail(null);
      setCheckoutError("Verify your purchase email before opening checkout.");
      return;
    }
    setCheckoutBusy(plan);
    setCheckoutError(null);
    sessionStorage.setItem(PENDING_NAMES_KEY, pendingNames.join("\n"));
    try {
      const response = await apiFetch("/api/checkout", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ plan }),
      });
      const data = await apiJson(response);
      if (response.status === 409 && data.active) {
        applyEntitlement(data);
        setShowUpgrade(false);
        setCheckoutBusy(null);
        return;
      }
      if (!response.ok || !data.url) throw new Error(data.error ?? "Checkout could not be started.");
      window.location.assign(data.url);
    } catch (error) {
      setCheckoutError(error instanceof Error ? error.message : "Checkout could not be started.");
      setCheckoutBusy(null);
    }
  };

  const restorePurchase = async () => {
    if (!namesnapAuth.currentUser?.emailVerified) {
      setCheckoutError("Use the secure email link first, then restore your purchase.");
      return;
    }
    setCheckoutBusy("restore");
    setCheckoutError(null);
    try {
      const response = await apiFetch("/api/status");
      const data = await apiJson(response);
      if (!response.ok) throw new Error(data.error ?? "Purchase status could not be checked.");
      if (!applyEntitlement(data)) throw new Error("No active NameSnap web purchase was found in this browser.");
      setShowUpgrade(false);
    } catch (error) {
      setCheckoutError(error instanceof Error ? error.message : "Purchase status could not be checked.");
    } finally {
      setCheckoutBusy(null);
    }
  };

  const resetPool = useCallback(() => {
    setExcludedIds([]);
    setHistory([]);
    setLiveName("Ready when you are");
    dismissWinner();
  }, [dismissWinner]);

  const removeEntry = (entryId: string) => {
    setEntries((current) => renumberEntries(current.filter((entry) => entry.id !== entryId)));
    setExcludedIds((current) => current.filter((id) => id !== entryId));
    setLastAddedIds((current) => current.filter((id) => id !== entryId));
  };

  const undoLastAdd = () => {
    if (!lastAddedIds.length) return;
    const ids = new Set(lastAddedIds);
    setEntries((current) => renumberEntries(current.filter((entry) => !ids.has(entry.id))));
    setExcludedIds((current) => current.filter((id) => !ids.has(id)));
    setLastAddedIds([]);
  };

  const clearPool = () => {
    setEntries([]);
    setLastAddedIds([]);
    resetPool();
  };

  const requestClearInput = () => setConfirmation({
    kicker: "CLEAR DRAFT LIST",
    message: `Remove all ${parseNames(input).length} names from the list waiting to be added? Names already in the pool will stay.`,
    confirmLabel: "Clear list",
    onConfirm: () => setInput(""),
  });

  const requestNoRepeatChange = (nextValue: boolean) => {
    if (nextValue === noRepeats) return;
    setConfirmation({
      kicker: "CHANGE NO-REPEAT SETTING",
      message: `Turn no repeats ${nextValue ? "on" : "off"}? This resets inclusion and recent-pick history while keeping every contestant.`,
      confirmLabel: nextValue ? "Turn on" : "Turn off",
      onConfirm: () => {
        setNoRepeats(nextValue);
        resetPool();
      },
    });
  };

  const requestResetPool = (afterReset?: () => void) => setConfirmation({
    kicker: "RESET PICKS",
    message: "Return every picked contestant to the eligible pool and clear recent winners? Your contestant list will stay.",
    confirmLabel: "Reset picks",
    onConfirm: () => { resetPool(); afterReset?.(); },
  });

  const requestClearPool = (afterClear?: () => void) => setConfirmation({
    kicker: "CLEAR CONTESTANTS",
    message: `Remove all ${entries.length} contestants and clear recent winners? Your draft list will stay. This cannot be undone.`,
    confirmLabel: "Clear pool",
    onConfirm: () => { clearPool(); afterClear?.(); },
  });

  const requestRemoveEntry = (entry: Entry) => setConfirmation({
    kicker: "REMOVE CONTESTANT",
    message: `Remove “${entry.name}” from this contestant pool? Remaining contestants will be renumbered.`,
    confirmLabel: "Remove name",
    onConfirm: () => removeEntry(entry.id),
  });

  const confirmAction = () => {
    const action = confirmation;
    setConfirmation(null);
    action?.onConfirm();
  };

  const exitPresentation = async () => {
    setPresentation(false);
    fullscreenSessionRef.current = false;
    if (document.fullscreenElement) await document.exitFullscreen().catch(() => undefined);
  };

  const togglePresentation = async () => {
    if (presentation) {
      await exitPresentation();
      return;
    }

    setPresentation(true);
    const shouldUseBrowserFullscreen = window.matchMedia("(min-width: 821px) and (pointer: fine)").matches;
    if (shouldUseBrowserFullscreen && stageRef.current?.requestFullscreen) {
      fullscreenRequestStartedAtRef.current = performance.now();
      await stageRef.current.requestFullscreen().catch(() => undefined);
    }
  };

  const pendingDuplicateCount = pendingDuplicateNames.length
    - namesExcludingDuplicates(pendingDuplicateNames, entries.map((entry) => entry.name)).length;

  return (
    <main className={`web-app ${presentation ? "is-presenting" : ""}`}>
      <header className="app-bar">
        <a className="brand" href="/" aria-label="NameSnap Web home">
          <img src="/namesnap-app-icon-v2.png" alt="" width={46} height={46} />
          <span><b>NameSnap</b><small>WEB</small></span>
        </a>
        <div className="app-bar-center"><i /> FAIR PICKS · LIVE ON SCREEN</div>
        <nav aria-label="NameSnap controls">
          <button className="quiet-control sound-control" onClick={() => setSoundOn((current) => { if (current) stopWinnerAudio(); return !current; })} aria-pressed={soundOn}><img src="/brand/sound_emoji.png" alt="" />{soundOn ? "Sound on" : "Sound off"}</button>
          {isPremium && entitlementPlan === "monthly" ? <button className="quiet-control" onClick={() => { setCheckoutError(null); setShowUpgrade(true); }}>Go lifetime</button> : null}
          <a className="app-store-button" href={APP_STORE_URL} target="_blank" rel="noreferrer">iPhone + iPad <span aria-hidden="true">↗</span></a>
          <button className="present-button" onClick={togglePresentation} aria-pressed={presentation}>Present <span aria-hidden="true">↗</span></button>
        </nav>
      </header>

      <div className="broadcast-shell">
        <aside className="producer-panel" aria-label="Picker controls">
          <div className="panel-heading">
            <div><span>PICKER SETUP</span><h1>Contestant list</h1></div>
          </div>

          <label className="input-label" htmlFor="contestant-input">Contestants</label>
          <NumberedNameEditor
            value={input}
            onChange={setInput}
            onRequestRemove={(name, remove) => setConfirmation({
              kicker: "DELETE DRAFT NAME",
              message: `Delete “${name}” from the names waiting to be added? This cannot be undone.`,
              confirmLabel: "Delete name",
              onConfirm: remove,
            })}
          />
          <div className="input-meta"><span>{parseNames(input).length} ready to add</span><span>Names stay in this browser</span></div>
          <button className="add-button" onClick={addNames} disabled={!parseNames(input).length}>Add names <span aria-hidden="true">＋</span></button>
          <div className="draft-tools">
            <button type="button" onClick={undoLastAdd} disabled={!lastAddedIds.length}>Undo last add</button>
            <button type="button" onClick={requestClearInput} disabled={!parseNames(input).length}>Clear this list</button>
          </div>

          <div className="control-block">
            <span className="block-label">Reveal style</span>
            <div className="segmented" role="group" aria-label="Reveal style">
              <button className={mode === "classic" ? "active" : ""} onClick={() => setMode("classic")}>Quick pick</button>
              <button className={mode === "wheel" ? "active" : ""} onClick={() => setMode("wheel")}>Spin wheel</button>
            </div>
          </div>

          <label className="switch-row" htmlFor="no-repeats">
            <span><b><img src="/brand/repeat_emoji.png" alt="" />No repeats</b><small>Winners sit out until reset</small></span>
            <input id="no-repeats" type="checkbox" checked={noRepeats} onChange={(event) => requestNoRepeatChange(event.target.checked)} />
            <i aria-hidden="true" />
          </label>

          <div className="pool-tools">
            <button onClick={() => requestResetPool()} disabled={!history.length && !excludedIds.length}>Reset pool</button>
            <button onClick={requestClearPool} disabled={!entries.length}>Clear pool</button>
          </div>

          <div className={`pool-preview ${entries.length ? "is-clickable" : ""}`}>
            <button className="pool-preview-surface" type="button" aria-label="Open the full contestant list" onClick={() => setShowPoolSheet(true)} disabled={!entries.length} />
            <div className="pool-preview-header">
              <div><span>ACTIVE POOL</span><b>{activeEntries.length}</b></div>
              <span className={`pool-preview-cta ${entries.length ? "" : "is-disabled"}`}>
                View full list <span aria-hidden="true">↗</span>
              </span>
            </div>
            {entries.length ? (
              <ul>{entries.slice(0, POOL_PREVIEW_LIMIT).map((entry) => (
                <li key={entry.id} className={excludedIds.includes(entry.id) ? "picked" : ""}>
                  <i>{initials(entry.name)}</i><span>{entry.drawNumber}. {entry.name}</span>
                  <button type="button" className="pool-trash" aria-label={`Remove ${entry.name}`} onClick={() => requestRemoveEntry(entry)}><TrashGlyph /></button>
                </li>
              ))}</ul>
            ) : <p>Your draw is empty. Paste a list above to begin.</p>}
            {entries.length > POOL_PREVIEW_LIMIT
              ? <small>+ {entries.length - POOL_PREVIEW_LIMIT} more contestants · Open the full list</small>
              : entries.length ? <small>Open the pane to see the full list</small> : null}
          </div>
        </aside>

        <section className="stage" ref={stageRef} aria-label="Live picker stage">
          <div className="stage-topline">
            <span className="live-chip"><i /> NAMESNAP LIVE</span>
            <span>{activeEntries.length ? `${activeEntries.length} eligible` : "Waiting for contestants"}</span>
            <span className="space-hint"><kbd>SPACE</kbd> to spin</span>
            {presentation ? <button type="button" className="presentation-exit" onClick={exitPresentation} aria-label="Exit presentation mode">Exit view <span aria-hidden="true">×</span></button> : null}
          </div>

          <div
            className={`picker-display ${mode} ${isSpinning ? "spinning" : ""}`}
            role="button"
            tabIndex={0}
            aria-label={activeEntries.length ? "Pick a winner" : "Add contestants before picking a winner"}
            onClick={spin}
            onKeyDown={(event) => {
              if (event.key === "Enter") {
                event.preventDefault();
                spin();
              }
            }}
          >
            <div className="stage-burst burst-a" /><div className="stage-burst burst-b" />
            {mode === "wheel" ? (
              <div className="wheel-wrap">
                <div className="wheel-pointer" aria-hidden="true" />
                <canvas ref={canvasRef} className="wheel-canvas" style={{ transform: `rotate(${rotation}deg)`, transitionDuration: isSpinning ? "3.8s" : "0s" }} aria-label={`Wheel containing ${activeEntries.length} eligible contestants`} />
                {!activeEntries.length && <div className="wheel-empty"><b>0</b><span>Names in the draw<small>Add contestants above</small></span></div>}
              </div>
            ) : (
              <div className="classic-picker">
                <span className="classic-kicker">NEXT UP</span><strong>{liveName}</strong>
                <div className="classic-rings"><i /><i /><i /></div>
              </div>
            )}
          </div>

          <div className="stage-controls">
            <button className="spin-button" onClick={spin} disabled={!activeEntries.length || isSpinning}><span>{isSpinning ? "Picking…" : mode === "wheel" ? "Spin the wheel" : "Pick a winner"}</span><i aria-hidden="true">→</i></button>
            <button type="button" className="stage-status stage-status-toggle" aria-pressed={noRepeats} onClick={() => requestNoRepeatChange(!noRepeats)} disabled={isSpinning}><span>NO REPEATS</span><b>{noRepeats ? "ON" : "OFF"}</b></button>
            <button type="button" className="stage-status stage-status-recent" aria-haspopup="dialog" aria-label="Open previous winners" onClick={() => setShowRecentPicks(true)} disabled={!history.length}><span>RECENT PICKS</span><b>VIEW</b></button>
          </div>

          {history.length > 0 && <div className="history-rail" aria-label="Previous winners, newest to oldest"><div className="history-rail-label"><span>PREVIOUS {Math.min(5, history.length)} WINNER{history.length === 1 ? "" : "S"}</span><small>NEWEST <i aria-hidden="true">→</i> OLDEST</small></div><div className="history-pills">{history.slice(0, 5).map((item) => <button key={item.id} onClick={() => presentWinner(item)}><i>{item.number}</i>{item.name}</button>)}</div></div>}
        </section>
      </div>

      <section className="marketing-showcase" aria-labelledby="namesnap-story-title">
        <div className="marketing-intro">
          <div>
            <span className="marketing-kicker">MADE FOR THE WHOLE ROOM</span>
            <h2 id="namesnap-story-title">One list. One fair pick. <em>A ridiculous celebration.</em></h2>
          </div>
          <div className="marketing-intro-copy">
            <p>Share this tab, capture it in OBS, or tap Present for a clean full-screen draw. NameSnap turns an ordinary random pick into the moment everyone watches.</p>
            <a href={APP_STORE_URL} target="_blank" rel="noreferrer">Get the iPhone + iPad app <span aria-hidden="true">↗</span></a>
          </div>
        </div>

        <div className="marketing-feature-grid">
          <article className="marketing-feature marketing-feature-local">
            <span>01 · PRIVATE BY DESIGN</span>
            <h3>Names stay right here.</h3>
            <p>No account. No audience database. Contestant lists and recent picks stay in this browser.</p>
            <img src="/celebrations/robot.png" alt="A cheerful NameSnap robot protecting a winner card" />
          </article>
          <article className="marketing-feature marketing-feature-screen">
            <span>02 · BUILT TO PRESENT</span>
            <h3>Big-screen energy.</h3>
            <p>Use the web picker on a classroom display, a stream, a projector, or anywhere a group needs one clear result.</p>
            <img src="/celebrations/hype-mascot.png" alt="The NameSnap hype mascot celebrating" />
          </article>
          <article className="marketing-feature marketing-feature-winner">
            <span>03 · WINNER MOMENT</span>
            <h3>Never a quiet win.</h3>
            <p>Confetti, high-energy music, characters, and hundreds of celebration variations make every name feel like the main event.</p>
            <img src="/celebrations/guitarist.png" alt="A NameSnap guitarist playing a victory solo" />
          </article>
        </div>

        <div className="marketing-use-strip" aria-label="Ways to use NameSnap">
          <span>CLASSROOMS</span><i>★</i><span>GIVEAWAYS</span><i>★</i><span>LIVESTREAMS</span><i>★</i><span>TEAMS</span><i>★</i><span>FAMILY GAMES</span>
        </div>

        <div className="marketing-cta">
          <div className="marketing-cta-art" aria-hidden="true"><img src="/celebrations/dancer.png" alt="" /><img src="/namesnap-app-icon-v2.png" alt="" /></div>
          <div><span className="marketing-kicker">PICK ANYWHERE</span><h2>Web for the room.<br /><em>App for your pocket.</em></h2><p>Keep NameSnap close on iPhone and iPad—ready for substitute teachers, club meetings, family nights, and the next giveaway.</p></div>
          <a href={APP_STORE_URL} target="_blank" rel="noreferrer">Open in the App Store <span aria-hidden="true">↗</span></a>
        </div>
      </section>

      <footer className="web-footer"><span>© 2026 NameSnap · Fair picks, huge winner energy.</span><nav><a href="/privacy">Privacy</a><a href="/support">Support</a><a href="/terms">EULA</a><a href="/support#contact">Contact</a></nav></footer>

      {winner && celebration && (
        <div
          key={`${winner.id}-${celebration.variation}`}
          className={`modal-backdrop winner-celebration-backdrop celebration-palette-${celebration.palette} celebration-${celebration.direction}`}
          role="presentation"
          data-celebration-variation={celebration.variation + 1}
        >
          <div className="celebration-world" aria-hidden="true">
            <img className="celebration-confetti-gif celebration-confetti-gif-a" src="/celebrations/confetti-burst.gif" alt="" />
            <img className="celebration-confetti-gif celebration-confetti-gif-b" src="/celebrations/confetti-burst.gif" alt="" />
            <div className="celebration-particles">
              {celebrationPieces.map((piece) => <i key={piece.index} style={piece.style} />)}
            </div>
          </div>

          <img
            className={`celebration-hero celebration-hero-${celebration.hero}`}
            src={celebration.hero === "pixel-bomb" ? "/celebrations/pixel-bomb.gif" : `/celebrations/${celebration.hero}.png`}
            alt=""
            aria-hidden="true"
          />

          <section className="winner-modal winner-celebration" role="dialog" aria-modal="true" aria-live="assertive" aria-labelledby="winner-title" aria-describedby="winner-message">
            <button type="button" className="winner-close" aria-label="Close winner celebration" onClick={dismissWinner}>×</button>
            <span className="winner-kicker">{CELEBRATION_HEADLINES[celebration.palette]}</span>
            <span className="winner-variation">CELEBRATION {celebration.variation + 1} / {CELEBRATION_VARIATION_COUNT} · {HERO_LABELS[celebration.hero]}</span>
            <div className="winner-number" aria-hidden="true">{winner.number}</div>
            <h2 id="winner-title">{winner.name}</h2>
            <p id="winner-message">Winner #{winner.number} from the numbered pool. Make some noise!</p>
            <div className="winner-actions">
              <button ref={winnerDoneRef} className="winner-done" onClick={dismissWinner}>Keep going</button>
              <button className="winner-reset" onClick={() => { dismissWinner(); requestResetPool(); }}>Reset picks</button>
            </div>
          </section>
        </div>
      )}

      {showPoolSheet && (
        <div className="modal-backdrop pool-sheet-backdrop" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) setShowPoolSheet(false); }}>
          <section className="pool-sheet" role="dialog" aria-modal="true" aria-labelledby="pool-sheet-title">
            <div className="pool-sheet-handle" aria-hidden="true" />
            <header>
              <div>
                <span>CONTESTANT POOL</span>
                <h2 id="pool-sheet-title">All contestants</h2>
                <p>{activeEntries.length} eligible · {entries.length} total</p>
              </div>
              <button ref={poolSheetCloseRef} type="button" className="pool-sheet-close" aria-label="Close contestant list" onClick={() => setShowPoolSheet(false)}>×</button>
            </header>
            <ul className="pool-sheet-list">
              {entries.map((entry) => {
                const picked = excludedIds.includes(entry.id);
                return (
                  <li key={entry.id} className={picked ? "picked" : ""}>
                    <i>{initials(entry.name)}</i>
                    <span><b>{entry.drawNumber}. {entry.name}</b><small>{picked ? "Picked · sitting out" : "Eligible for the next draw"}</small></span>
                    <button type="button" className="pool-sheet-trash" aria-label={`Remove ${entry.name}`} onClick={() => requestRemoveEntry(entry)}><TrashGlyph /></button>
                  </li>
                );
              })}
            </ul>
            <footer>
              <button type="button" onClick={() => requestResetPool()} disabled={!history.length && !excludedIds.length}>Reset picks</button>
              <button type="button" className="pool-sheet-clear" onClick={() => requestClearPool(() => setShowPoolSheet(false))}>Clear pool</button>
              <button type="button" className="pool-sheet-done" onClick={() => setShowPoolSheet(false)}>Done</button>
            </footer>
          </section>
        </div>
      )}

      {showRecentPicks && (
        <div className="modal-backdrop pool-sheet-backdrop" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) setShowRecentPicks(false); }}>
          <section className="pool-sheet history-sheet" role="dialog" aria-modal="true" aria-labelledby="recent-picks-title">
            <div className="pool-sheet-handle" aria-hidden="true" />
            <header>
              <div>
                <span>DRAW HISTORY</span>
                <h2 id="recent-picks-title">Recent picks</h2>
                <p>{history.length} winner{history.length === 1 ? "" : "s"} from this pool</p>
              </div>
              <button ref={recentPicksCloseRef} type="button" className="pool-sheet-close" aria-label="Close recent picks" onClick={() => setShowRecentPicks(false)}>×</button>
            </header>
            <ol className="history-sheet-list">
              {history.map((item, index) => (
                <li key={item.id}>
                  <button type="button" onClick={() => { setShowRecentPicks(false); presentWinner(item); }}>
                    <i>{item.number}</i>
                    <span><b>{item.name}</b><small>Pick {history.length - index} · contestant #{item.number}</small></span>
                    <span aria-hidden="true">↗</span>
                  </button>
                </li>
              ))}
            </ol>
            <footer>
              <button type="button" onClick={() => requestResetPool(() => setShowRecentPicks(false))}>Reset picks</button>
              <button type="button" className="pool-sheet-done" onClick={() => setShowRecentPicks(false)}>Done</button>
            </footer>
          </section>
        </div>
      )}

      {confirmation && (
        <div className="modal-backdrop confirmation-backdrop" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) setConfirmation(null); }}>
          <section className="confirmation-modal" role="alertdialog" aria-modal="true" aria-labelledby="confirmation-title" aria-describedby="confirmation-message">
            <span className="confirmation-kicker">{confirmation.kicker}</span>
            <span className="confirmation-mark" aria-hidden="true">?</span>
            <h2 id="confirmation-title">Are you sure?</h2>
            <p id="confirmation-message">{confirmation.message}</p>
            <div className="confirmation-actions">
              <button ref={confirmationCancelRef} type="button" className="confirmation-cancel" onClick={() => setConfirmation(null)}>Cancel</button>
              <button type="button" className="confirmation-confirm" onClick={confirmAction}>{confirmation.confirmLabel}</button>
            </div>
          </section>
        </div>
      )}

      {pendingDuplicateNames.length > 0 && (
        <div className="modal-backdrop confirmation-backdrop" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) setPendingDuplicateNames([]); }}>
          <section className="confirmation-modal duplicate-modal" role="dialog" aria-modal="true" aria-labelledby="duplicate-title" aria-describedby="duplicate-message">
            <span className="confirmation-kicker">DUPLICATES FOUND</span>
            <span className="confirmation-mark" aria-hidden="true">?</span>
            <h2 id="duplicate-title">Add them again?</h2>
            <p id="duplicate-message">{pendingDuplicateCount} duplicate {pendingDuplicateCount === 1 ? "name was" : "names were"} found in this list or pool. What should NameSnap do?</p>
            <div className="duplicate-actions">
              <button ref={duplicateCancelRef} type="button" className="confirmation-cancel" onClick={() => setPendingDuplicateNames([])}>Cancel</button>
              <button type="button" className="confirmation-cancel" onClick={() => {
                const uniqueNames = namesExcludingDuplicates(pendingDuplicateNames, entries.map((entry) => entry.name));
                setPendingDuplicateNames([]);
                appendNamesToPool(uniqueNames);
              }}>Skip duplicates</button>
              <button type="button" className="confirmation-confirm" onClick={() => {
                const names = pendingDuplicateNames;
                setPendingDuplicateNames([]);
                appendNamesToPool(names);
              }}>Add all anyway</button>
            </div>
          </section>
        </div>
      )}

      {showUpgrade && (
        <div className="modal-backdrop" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) setShowUpgrade(false); }}>
          <section className="upgrade-modal" role="dialog" aria-modal="true" aria-labelledby="upgrade-title">
            <button className="modal-close" aria-label="Close upgrade" onClick={() => { setPendingNames([]); setShowUpgrade(false); }}>×</button>
            <span className="upgrade-spark" aria-hidden="true"><img src="/brand/sparkle_emoji.png" alt="" /></span><span className="upgrade-kicker">BIG DRAW ENERGY</span>
            <h2 id="upgrade-title">{entitlementPlan === "monthly" ? "Make it Lifetime?" : "Upgrade to Unlimited?"}</h2>
            <p>{entitlementPlan === "monthly" ? "Your Monthly plan is active. Switch to a one-time Lifetime unlock whenever you want." : `Free supports up to ${FREE_LIMIT} contestants.`}</p>
            <ul><li>Unlimited contestants</li><li>Use presentation mode on stream</li><li>Restore on another browser with your verified email</li></ul>
            <p className="renewal-copy">{entitlementPlan === "monthly" ? "When Lifetime payment completes, NameSnap automatically stops the existing Stripe monthly renewal. If Stripe cannot complete that step, NameSnap flags it here and gives you a direct billing-support action." : "Unlimited Monthly renews every month until canceled. Unlimited Lifetime is a one-time purchase."}</p>
            {!accountEmail ? (
              <div className="purchase-account">
                <span className="upgrade-kicker">PROTECT YOUR PURCHASE</span>
                <h3>Use a secure email link</h3>
                <p>No password and no account needed for free use. This verified email is only for buying once and restoring access later.</p>
                <label htmlFor="purchase-email">Purchase email</label>
                <input id="purchase-email" type="email" autoComplete="email" inputMode="email" value={authEmail} onChange={(event) => setAuthEmail(event.target.value)} placeholder="you@example.com" />
                <button type="button" className="purchase-account-button" onClick={emailLinkNeedsAddress ? completePurchaseAccountLink : sendPurchaseAccountLink} disabled={authBusy}>
                  {authBusy ? "Checking…" : emailLinkNeedsAddress ? "Verify this email" : "Send secure sign-in link"}
                </button>
                {authNotice ? <p className="auth-notice" role="status">{authNotice}</p> : null}
              </div>
            ) : (
              <div className="purchase-account signed-in">
                <span>Purchase protected for <b>{accountEmail}</b></span>
                <button type="button" onClick={() => { void signOut(namesnapAuth); setEntitlementPlan(null); setAuthNotice(null); }}>Use another email</button>
              </div>
            )}
            {accountEmail && entitlementPlan !== "lifetime" ? (
              <div className={`plan-grid ${entitlementPlan === "monthly" ? "lifetime-only" : ""}`}>
                <button className="lifetime-plan" onClick={() => startCheckout("lifetime")} disabled={checkoutBusy !== null}><span>BEST VALUE</span><b>{checkoutBusy === "lifetime" ? "Opening checkout…" : entitlementPlan === "monthly" ? "Upgrade to Lifetime" : "Unlock Lifetime"}</b><strong>$6.99</strong><small>one time on web</small></button>
                {entitlementPlan !== "monthly" ? <button className="monthly-plan" onClick={() => startCheckout("monthly")} disabled={checkoutBusy !== null}><span>FLEXIBLE</span><b>{checkoutBusy === "monthly" ? "Opening checkout…" : "Go Monthly"}</b><strong>$0.99</strong><small>per month on web</small></button> : null}
              </div>
            ) : null}
            {accountEmail && entitlementPlan === "lifetime" ? <p className="lifetime-owned">Lifetime is already owned by this purchase account. No checkout is needed.</p> : null}
            {subscriptionCancellationRequired ? <p className="billing-warning" role="alert">Lifetime is unlocked, but Stripe could not stop the previous Monthly renewal automatically. Email <a href="mailto:sidequestsoftware@proton.me?subject=NameSnap%20Web%20monthly%20cancellation">NameSnap billing support</a> now so it can be canceled before another charge.</p> : null}
            <p className="platform-note">Web purchases unlock NameSnap Web. App Store purchases unlock the iPhone and iPad app.</p>
            <button className="restore-button" onClick={restorePurchase} disabled={checkoutBusy !== null}>{checkoutBusy === "restore" ? "Checking…" : "Restore web purchase"}</button>
            {checkoutError ? <p className="checkout-error" role="alert">{checkoutError}</p> : null}
            <div className="legal-links"><a href="/privacy">Privacy Policy</a><a href="/terms">Terms of Use</a></div>
            <input type="hidden" value={pendingNames.join("|")} readOnly />
          </section>
        </div>
      )}
    </main>
  );
}
