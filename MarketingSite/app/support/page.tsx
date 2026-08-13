import type { Metadata } from "next";
import { SiteFooter, SiteHeader } from "../site-chrome";

export const metadata: Metadata = { title: "Support", description: "Help, FAQs, and contact information for NameSnap." };

const faqs = [
  ["How many contestants can I add for free?", "The free version supports up to 16 contestants per session. Unlimited Monthly and Unlimited Lifetime remove that limit."],
  ["How do I avoid picking the same person twice?", "Turn on No Repeat before you pick. NameSnap removes each winner from the active pool until you reset the session."],
  ["How do I restore a purchase?", "Open the upgrade screen and tap Restore Purchases. Make sure the device is signed in to the Apple Account that originally completed the purchase."],
  ["Where is my data stored?", "Contestant names, recent winners, and preferences stay on your device. NameSnap does not require an account and does not run third-party analytics or ads."],
  ["Can I paste a list?", "Yes. Paste names separated by commas or new lines, then add them to your pool."],
];

export default function SupportPage() {
  return (
    <main><SiteHeader />
      <section className="legal-hero shell"><p className="eyebrow"><span /> NAME SNAP SUPPORT</p><h1>Help is<br /><em>right here.</em></h1><p>Quick answers for common questions, plus a direct line if something is not working.</p></section>
      <section className="legal-layout shell">
        <aside><h2>Contact</h2><p>For customer service, complaints or feedback, bug reports, purchase questions, and feature requests:</p><a className="button button-primary" href="mailto:sidequestsoftware@proton.me?subject=NameSnap%20Support">Email NameSnap support</a><small>Please include your device model, iOS version, and what you were trying to do.</small></aside>
        <div className="faq-list"><h2>Frequently asked questions</h2>{faqs.map(([question, answer]) => <article key={question}><h3>{question}</h3><p>{answer}</p></article>)}</div>
      </section>
      <SiteFooter />
    </main>
  );
}
