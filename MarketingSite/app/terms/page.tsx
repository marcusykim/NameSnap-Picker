import type { Metadata } from "next";
import { PublicHero, SiteFooter, SiteHeader } from "../site-chrome";

export const metadata: Metadata = { title: "EULA + Terms of Use", description: "NameSnap end-user license agreement and terms of use." };

export default function TermsPage() {
  return (
    <main className="public-page"><SiteHeader />
      <PublicHero
        eyebrow="EULA + TERMS OF USE"
        title="Fair picks."
        accent="Clear terms."
        description="The practical rules for using NameSnap on iPhone, iPad, and the web—written to be read, not hidden."
        art="/celebrations/knight.png"
        artAlt="A confident NameSnap knight holding a winner card"
        artLabel="THE FAIR-PICK CODE"
        facts={["PLAIN LANGUAGE", "APPLE EULA", "WEB TERMS"]}
      />
      <div className="public-summary shell">
        <span>LICENSE SNAPSHOT</span>
        <p>The Apple app is licensed under Apple’s Standard EULA. These product terms add the rules that apply specifically to NameSnap and its web version.</p>
        <time dateTime="2026-08-22">Effective August 22, 2026</time>
      </div>
      <article className="policy policy-grid shell">
        <section><h2>Agreement</h2><p>These terms govern NameSnap Web at getnamesnap.web.app and supplement the license terms that govern the NameSnap iPhone and iPad app. By using NameSnap, you agree to these terms.</p></section>
        <section><h2>Apple app license</h2><p>The NameSnap iPhone and iPad app is licensed, not sold. Apple’s <a href="https://www.apple.com/legal/internet-services/itunes/dev/stdeula/" target="_blank" rel="noreferrer">Standard End User License Agreement</a> applies to the app and is incorporated here by reference. It grants a nontransferable license to use NameSnap on Apple-branded products you own or control, subject to Apple’s Usage Rules.</p></section>
        <section><h2>Ownership and restrictions</h2><p>NameSnap, its interface, artwork, branding, and software remain the property of Marcus Kim and applicable licensors. Except where law expressly permits it, you may not copy, redistribute, sublicense, reverse engineer, disassemble, derive source code from, modify, or create derivative works from the app or web service.</p></section>
        <section><h2>What NameSnap does</h2><p>NameSnap randomly selects from the active names you provide. It is intended for ordinary classroom participation, games, giveaways, teams, and live-stream activities. Do not use NameSnap for medical, legal, financial, safety-critical, gambling, or other decisions where a random result could cause harm or determine a protected right.</p></section>
        <section><h2>Your responsibility</h2><p>You are responsible for the lists you enter, for obtaining any permission needed to display participant names, and for running promotions or giveaways in compliance with platform rules and applicable law. Do not enter sensitive personal information.</p></section>
        <section><h2>Age and purchases</h2><p>The free picker may be used under appropriate adult or school supervision. A web purchase must be completed by an adult or by someone authorized by the payment-method owner and organization. Children must not submit payment information.</p></section>
        <section><h2>Free and paid access</h2><p>NameSnap Web supports up to 16 contestants free. Unlimited Monthly is a recurring Stripe subscription until canceled. Unlimited Lifetime is a one-time web purchase. Web purchases unlock NameSnap Web only; purchases through Apple unlock the iPhone and iPad app only.</p></section>
        <section><h2>Billing and cancellation</h2><p>Stripe processes web payments. Monthly subscribers can contact NameSnap support using the email address entered at Stripe Checkout to request cancellation of future renewals or help updating payment details. Cancellation takes effect at the end of the paid billing period unless Stripe states otherwise. Prices and taxes, when applicable, are shown before payment.</p></section>
        <section><h2>Refunds</h2><p>For a web purchase question, contact NameSnap support with the email used at Stripe Checkout. App Store refund requests are handled by Apple under Apple’s policies. Nothing in these terms limits rights that cannot legally be waived.</p></section>
        <section><h2>Availability and warranty</h2><p>NameSnap is provided on an “as is” and “as available” basis. We work to keep it reliable, but do not guarantee uninterrupted availability or that a random selection will be suitable for every purpose.</p></section>
        <section><h2>Third-party services</h2><p>NameSnap may link to or rely on Apple, Stripe, Firebase, and Cloudflare services. Your use of those services is also subject to their applicable terms. NameSnap is responsible for its own customer support; Apple is not responsible for providing maintenance or support for NameSnap.</p></section>
        <section><h2>Termination</h2><p>Your permission to use NameSnap ends automatically if you materially violate these terms or Apple’s applicable license. Provisions concerning ownership, disclaimers, responsibility, and applicable law survive termination.</p></section>
        <section><h2>Legal and export compliance</h2><p>You may use NameSnap only where permitted by law and must comply with applicable U.S. export and sanctions rules. You represent that you are not located in a U.S.-embargoed country and are not on a U.S. Government prohibited or restricted party list.</p></section>
        <section><h2>Apple beneficiary</h2><p>For the iPhone and iPad app, Apple and its subsidiaries are third-party beneficiaries of the applicable app-license terms and may enforce those terms as provided by Apple’s Standard EULA.</p></section>
        <section><h2>Changes</h2><p>NameSnap may update these terms as the product changes. Material changes will be posted here with a revised effective date.</p></section>
        <section><h2>Contact</h2><p>Questions can be sent to <a href="mailto:sidequestsoftware@proton.me?subject=NameSnap%20Terms">sidequestsoftware@proton.me</a>.</p></section>
      </article>
      <SiteFooter />
    </main>
  );
}
