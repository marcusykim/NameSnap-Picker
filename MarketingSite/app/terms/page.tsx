import type { Metadata } from "next";
import { SiteFooter, SiteHeader } from "../site-chrome";

export const metadata: Metadata = { title: "Terms of Use", description: "NameSnap Web terms of use." };

export default function TermsPage() {
  return (
    <main><SiteHeader />
      <section className="legal-hero shell"><p className="eyebrow"><span /> TERMS OF USE</p><h1>Fair picks.<br /><em>Clear terms.</em></h1><p>Effective August 22, 2026</p></section>
      <article className="policy shell">
        <section><h2>Agreement</h2><p>These terms govern use of NameSnap Web at getnamesnap.web.app. By using NameSnap Web, you agree to these terms. The iPhone and iPad app is also subject to Apple’s applicable App Store terms and standard end-user license agreement.</p></section>
        <section><h2>What NameSnap does</h2><p>NameSnap randomly selects from the active names you provide. It is intended for ordinary classroom participation, games, giveaways, teams, and live-stream activities. Do not use NameSnap for medical, legal, financial, safety-critical, gambling, or other decisions where a random result could cause harm or determine a protected right.</p></section>
        <section><h2>Your responsibility</h2><p>You are responsible for the lists you enter, for obtaining any permission needed to display participant names, and for running promotions or giveaways in compliance with platform rules and applicable law. Do not enter sensitive personal information.</p></section>
        <section><h2>Age and purchases</h2><p>The free picker may be used under appropriate adult or school supervision. A web purchase must be completed by an adult or by someone authorized by the payment-method owner and organization. Children must not submit payment information.</p></section>
        <section><h2>Free and paid access</h2><p>NameSnap Web supports up to 16 contestants free. Unlimited Monthly is a recurring Stripe subscription until canceled. Unlimited Lifetime is a one-time web purchase. Web purchases unlock NameSnap Web only; purchases through Apple unlock the iPhone and iPad app only.</p></section>
        <section><h2>Billing and cancellation</h2><p>Stripe processes web payments. Monthly subscribers can contact NameSnap support using the email address entered at Stripe Checkout to request cancellation of future renewals or help updating payment details. Cancellation takes effect at the end of the paid billing period unless Stripe states otherwise. Prices and taxes, when applicable, are shown before payment.</p></section>
        <section><h2>Refunds</h2><p>For a web purchase question, contact NameSnap support with the email used at Stripe Checkout. App Store refund requests are handled by Apple under Apple’s policies. Nothing in these terms limits rights that cannot legally be waived.</p></section>
        <section><h2>Availability and warranty</h2><p>NameSnap is provided on an “as is” and “as available” basis. We work to keep it reliable, but do not guarantee uninterrupted availability or that a random selection will be suitable for every purpose.</p></section>
        <section><h2>Changes</h2><p>NameSnap may update these terms as the product changes. Material changes will be posted here with a revised effective date.</p></section>
        <section><h2>Contact</h2><p>Questions can be sent to <a href="mailto:sidequestsoftware@proton.me?subject=NameSnap%20Terms">sidequestsoftware@proton.me</a>.</p></section>
      </article>
      <SiteFooter />
    </main>
  );
}
