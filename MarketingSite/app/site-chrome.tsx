import Image from "next/image";
import Link from "next/link";

export function SiteHeader() {
  return (
    <header className="site-header shell">
      <Link className="brand" href="/" aria-label="NameSnap home">
        <Image src="/namesnap-icon.png" alt="" width={48} height={48} />
        <span>NameSnap</span>
      </Link>
      <nav aria-label="Main navigation">
        <Link href="/#how-it-works">How it works</Link>
        <Link href="/privacy">Privacy</Link>
        <Link href="/support">Support</Link>
      </nav>
      <a className="nav-cta" href="https://apps.apple.com/app/id6759588637" target="_blank" rel="noreferrer">App Store <span aria-hidden="true">↗</span></a>
    </header>
  );
}

export function SiteFooter() {
  return (
    <footer className="site-footer shell">
      <div className="brand"><Image src="/namesnap-icon.png" alt="" width={44} height={44} /><span>NameSnap</span></div>
      <p>Fair random picks in seconds.</p>
      <nav aria-label="Footer navigation"><Link href="/privacy">Privacy</Link><Link href="/support">Support</Link><a href="mailto:sidequestsoftware@proton.me">Email</a></nav>
      <small>© 2026 Marcus Kim. Apple and App Store are trademarks of Apple Inc.</small>
    </footer>
  );
}
