/* eslint-disable @next/next/no-html-link-for-pages, @next/next/no-img-element */

type PublicHeroProps = {
  eyebrow: string;
  title: string;
  accent: string;
  description: string;
  art: string;
  artAlt: string;
  artLabel: string;
  facts: string[];
  actions?: boolean;
};

export function SiteHeader() {
  return (
    <header className="site-header shell">
      <a className="brand" href="/" aria-label="NameSnap home">
        <img src="/namesnap-app-icon-v2.png" alt="" width={48} height={48} />
        <span>NameSnap</span><small>WEB</small>
      </a>
      <nav aria-label="Main navigation">
        <a href="/">Open picker</a>
        <a href="/privacy">Privacy</a>
        <a href="/support">Support</a>
        <a href="/terms">EULA</a>
      </nav>
      <a className="nav-cta" href="https://apps.apple.com/app/id6759588637" target="_blank" rel="noreferrer">App Store <span aria-hidden="true">↗</span></a>
    </header>
  );
}

export function PublicHero({ eyebrow, title, accent, description, art, artAlt, artLabel, facts, actions = false }: PublicHeroProps) {
  return (
    <section className="public-hero shell">
      <div className="public-hero-copy">
        <p className="public-eyebrow"><i /> {eyebrow}</p>
        <h1>{title}<br /><em>{accent}</em></h1>
        <p className="public-hero-lede">{description}</p>
        {actions ? (
          <div className="public-hero-actions">
            <a href="/">Start picking now <span aria-hidden="true">→</span></a>
            <a href="https://apps.apple.com/app/id6759588637" target="_blank" rel="noreferrer">Get the app <span aria-hidden="true">↗</span></a>
          </div>
        ) : null}
        <div className="public-facts" aria-label="Quick facts">
          {facts.map((fact) => <span key={fact}>{fact}</span>)}
        </div>
      </div>
      <div className="public-hero-art" aria-label={artAlt}>
        <span className="public-art-chip">{artLabel}</span>
        <div className="public-art-rings" aria-hidden="true"><i /><i /><i /></div>
        <img src={art} alt={artAlt} />
      </div>
    </section>
  );
}

export function SiteFooter() {
  return (
    <footer className="site-footer shell">
      <div className="brand"><img src="/namesnap-app-icon-v2.png" alt="" width={44} height={44} /><span>NameSnap</span></div>
      <p>Fair picks. Huge winner energy.</p>
      <nav aria-label="Footer navigation"><a href="/">Open picker</a><a href="/privacy">Privacy</a><a href="/support">Support</a><a href="/terms">EULA</a><a href="mailto:sidequestsoftware@proton.me">Email</a></nav>
      <small>© 2026 Marcus Kim. Apple and App Store are trademarks of Apple Inc.</small>
    </footer>
  );
}
