import type { Metadata } from "next";
import { SiteFooter, SiteHeader } from "../site-chrome";

export const metadata: Metadata = { title: "Support", description: "Help, FAQs, and contact information for NameSnap." };

const faqs = [
  ["How many contestants can I add for free?", "The free version supports up to 16 contestants per session. Unlimited Monthly and Unlimited Lifetime remove that limit."],
  ["How do I avoid picking the same person twice?", "Turn on No Repeat before you pick. NameSnap removes each winner from the active pool until you reset the session."],
  ["How do I restore an App Store purchase?", "In the iPhone or iPad app, open the upgrade screen and tap Restore Purchases. Make sure the device is signed in to the Apple Account that originally completed the purchase."],
  ["How do I restore a web purchase?", "In NameSnap Web, open the upgrade screen in the same browser and choose Restore web purchase. If browser data was cleared or you changed devices, contact support with the email used at Stripe Checkout."],
  ["How do I cancel Unlimited Monthly?", "Email NameSnap support from the address used at Stripe Checkout and ask us to cancel future renewals. Your access remains available through the end of the paid billing period unless Stripe states otherwise."],
  ["Does a web purchase unlock the App Store app?", "No. Stripe web purchases unlock NameSnap Web, while Apple purchases unlock the iPhone and iPad app. The two stores do not share entitlements."],
  ["Where is my data stored?", "Contestant names, recent winners, and preferences stay on your device or browser. They are not sent to NameSnap. A minimal browser entitlement record is stored only when NameSnap Web checks or completes a web purchase."],
  ["Can I paste a list?", "Yes. Paste names separated by commas or new lines, then add them to your pool."],
  ["Can I use NameSnap in OBS or on a classroom display?", "Yes. Capture getnamesnap.web.app as a browser source, share the browser window, or use Present mode for a clean full-screen draw."],
];

export default function SupportPage() {
  return (
    <main><SiteHeader />
      <section className="legal-hero shell"><p className="eyebrow"><span /> NAME SNAP SUPPORT</p><h1>Help is<br /><em>right here.</em></h1><p>Quick answers for common questions, plus a direct line if something is not working.</p></section>
      <section className="legal-layout shell">
        <aside><h2>Contact</h2><p>For customer service, complaints or feedback, bug reports, purchase questions, and feature requests:</p><a className="button button-primary" href="mailto:sidequestsoftware@proton.me?subject=NameSnap%20Support">Email NameSnap support</a><small>Please include whether you used web, iPhone, or iPad and what you were trying to do. Never email payment-card details.</small></aside>
        <div className="faq-list"><h2>Frequently asked questions</h2>{faqs.map(([question, answer]) => <article key={question}><h3>{question}</h3><p>{answer}</p></article>)}</div>
      </section>
      <SiteFooter />
    </main>
  );
}
