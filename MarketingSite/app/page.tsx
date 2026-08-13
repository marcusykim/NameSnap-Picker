import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { SiteFooter, SiteHeader } from "./site-chrome";

export const metadata: Metadata = {
  title: "NameSnap — Fair random picks in seconds",
  description:
    "A fast, playful random name picker for classrooms, giveaways, games, teams, and live streams.",
};

const APP_STORE_URL = "https://apps.apple.com/app/id6759588637";

const uses = [
  ["01", "Classrooms", "Call on students fairly without slowing down the lesson."],
  ["02", "Giveaways", "Turn a list of entries into one transparent, exciting winner."],
  ["03", "Games & teams", "Split the indecision and keep the moment moving."],
  ["04", "Live streams", "Make audience picks feel quick, visible, and fun."],
];

export default function Home() {
  return (
    <main>
      <SiteHeader />

      <section className="hero shell" aria-labelledby="hero-title">
        <div className="hero-copy">
          <p className="eyebrow"><span /> FAIR PICKS. ZERO FUSS.</p>
          <h1 id="hero-title">Stop debating.<br /><em>Start picking.</em></h1>
          <p className="hero-lede">
            Paste names, tap spin, and get a fair winner in seconds. Made for classrooms,
            giveaways, games, teams, and live streams.
          </p>
          <div className="hero-actions">
            <a className="button button-primary" href={APP_STORE_URL} target="_blank" rel="noreferrer">
              View on the App Store <span aria-hidden="true">↗</span>
            </a>
            <a className="text-link" href="#how-it-works">See how it works <span aria-hidden="true">↓</span></a>
          </div>
          <div className="trust-row" aria-label="NameSnap benefits">
            <span>No account</span><span>No tracking</span><span>16 names free</span>
          </div>
        </div>

        <div className="hero-visual" aria-label="NameSnap app preview">
          <div className="burst burst-one" />
          <div className="burst burst-two" />
          <div className="screen-label">ACTUAL IPHONE SCREEN</div>
          <div className="phone phone-hero">
            <Image src="/screens/name-picker-ready.png" alt="NameSnap ready to pick a winner" width={1206} height={2622} priority />
          </div>
          <div className="scribble-note note-one">NO REPEATS<br /><b>when you want them</b></div>
          <div className="scribble-note note-two"><b>16</b><br />names free</div>
        </div>
      </section>

      <section className="ticker" aria-label="Common NameSnap uses">
        <div>CLASS PICKS <i>✦</i> RAFFLES <i>✦</i> TEAM DRAWS <i>✦</i> PARTY GAMES <i>✦</i> GIVEAWAYS <i>✦</i> LIVE STREAMS</div>
      </section>

      <section className="shell section" id="how-it-works" aria-labelledby="how-title">
        <div className="section-heading split-heading">
          <div>
            <p className="eyebrow"><span /> THREE TAPS TO DONE</p>
            <h2 id="how-title">From list to winner,<br />without the ceremony.</h2>
          </div>
          <p>Every screen is built around one job: making a quick decision feel fair and satisfying.</p>
        </div>

        <div className="steps">
          <article className="step step-yellow">
            <div className="step-copy"><span>1</span><h3>Paste your list</h3><p>Use commas or new lines. NameSnap cleans it up and gets everyone into the draw.</p></div>
            <div className="phone phone-step"><Image src="/screens/name-picker-input.png" alt="Sixteen names entered into NameSnap" width={1206} height={2622} /></div>
          </article>
          <article className="step step-blue">
            <div className="step-copy"><span>2</span><h3>Pick your style</h3><p>Use the quick picker or switch to the wheel when the reveal deserves a little drama.</p></div>
            <div className="phone phone-step"><Image src="/screens/name-picker-wheel.png" alt="NameSnap wheel picker mode" width={1206} height={2622} /></div>
          </article>
          <article className="step step-mint">
            <div className="step-copy"><span>3</span><h3>Meet the winner</h3><p>Keep recent winners handy, skip names on the fly, and turn on no-repeat mode.</p></div>
            <div className="phone phone-step"><Image src="/screens/name-picker-winner.png" alt="NameSnap showing a winner and recent picks" width={1206} height={2622} /></div>
          </article>
        </div>
      </section>

      <section className="uses section">
        <div className="shell">
          <div className="section-heading uses-heading">
            <p className="eyebrow eyebrow-light"><span /> BUILT FOR REAL MOMENTS</p>
            <h2>When “who goes next?”<br />needs an answer now.</h2>
          </div>
          <div className="use-grid">
            {uses.map(([number, title, description]) => (
              <article key={number}>
                <span>{number}</span><h3>{title}</h3><p>{description}</p>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section className="shell section pricing" aria-labelledby="pricing-title">
        <div className="pricing-card">
          <div className="pricing-copy">
            <p className="eyebrow"><span /> START SMALL. GO UNLIMITED.</p>
            <h2 id="pricing-title">Sixteen names.<br />Free forever.</h2>
            <p>No timer. No sign-in. No ads. Upgrade only when your lists get bigger.</p>
            <ul>
              <li><b>Free:</b> up to 16 contestants per session</li>
              <li><b>Unlimited Monthly:</b> $0.99/month in the U.S.</li>
              <li><b>Unlimited Lifetime:</b> $6.99 once in the U.S.</li>
            </ul>
            <small>Purchases are handled by Apple. Local storefront pricing may vary.</small>
          </div>
          <div className="price-sticker" aria-label="No account required"><strong>0</strong><span>accounts<br />required</span></div>
        </div>
      </section>

      <section className="privacy-band" aria-labelledby="privacy-title">
        <div className="shell privacy-grid">
          <div>
            <p className="eyebrow"><span /> PRIVACY IS A FEATURE</p>
            <h2 id="privacy-title">Your list stays<br />your business.</h2>
          </div>
          <div>
            <p>NameSnap does not require an account, run third-party ads, or track how you use the app. Names, history, and preferences stay on your device.</p>
            <Link className="button button-dark" href="/privacy">Read the privacy policy <span aria-hidden="true">→</span></Link>
          </div>
          <div className="proof-grid">
            <article><span>FAIRNESS</span><h3>Every active name gets an equal shot.</h3><p>Each pick is selected at random from the active pool. No-repeat mode simply removes previous winners until you reset.</p></article>
            <article><span>PRIVACY</span><h3>Your list never becomes our database.</h3><p>NameSnap has no account system or analytics backend. Contestants and winner history stay on your device.</p></article>
          </div>
        </div>
      </section>

      <section className="shell final-cta">
        <div className="final-card">
          <Image className="final-icon" src="/namesnap-icon.png" alt="" width={1024} height={1024} />
          <p className="eyebrow eyebrow-light"><span /> READY WHEN YOU ARE</p>
          <h2>Make the pick.<br /><em>Keep it moving.</em></h2>
          <a className="button button-light" href={APP_STORE_URL} target="_blank" rel="noreferrer">View on the App Store <span aria-hidden="true">↗</span></a>
        </div>
      </section>

      <SiteFooter />
    </main>
  );
}
