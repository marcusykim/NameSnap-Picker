/* eslint-disable @next/next/no-html-link-for-pages, @next/next/no-img-element */

export function SiteHeader() {
  return (
    <header className="site-header shell">
      <a className="brand" href="/" aria-label="NameSnap home">
        <img src="/namesnap-icon.png" alt="" width={48} height={48} />
        <span>NameSnap</span>
      </a>
      <nav aria-label="Main navigation">
        <a href="/">Open picker</a>
        <a href="/privacy">Privacy</a>
        <a href="/support">Support</a>
        <a href="/terms">Terms</a>
      </nav>
      <a className="nav-cta" href="https://apps.apple.com/app/id6759588637" target="_blank" rel="noreferrer">App Store <span aria-hidden="true">↗</span></a>
    </header>
  );
}

export function SiteFooter() {
  return (
    <footer className="site-footer shell">
      <div className="brand"><img src="/namesnap-icon.png" alt="" width={44} height={44} /><span>NameSnap</span></div>
      <p>Fair random picks in seconds.</p>
      <nav aria-label="Footer navigation"><a href="/privacy">Privacy</a><a href="/support">Support</a><a href="/terms">Terms</a><a href="mailto:sidequestsoftware@proton.me">Email</a></nav>
      <small>© 2026 Marcus Kim. Apple and App Store are trademarks of Apple Inc.</small>
    </footer>
  );
}
