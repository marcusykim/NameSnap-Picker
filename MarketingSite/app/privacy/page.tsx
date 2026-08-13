import type { Metadata } from "next";
import { SiteFooter, SiteHeader } from "../site-chrome";

export const metadata: Metadata = { title: "Privacy Policy", description: "NameSnap privacy policy." };

export default function PrivacyPage() {
  return (
    <main><SiteHeader />
      <section className="legal-hero shell"><p className="eyebrow"><span /> PRIVACY POLICY</p><h1>Simple app.<br /><em>Simple policy.</em></h1><p>Effective August 11, 2026</p></section>
      <article className="policy shell">
        <section><h2>Overview</h2><p>NameSnap is designed to make random picks without collecting personal information. You do not need to create an account or sign in to use the app.</p></section>
        <section><h2>Data stored on your device</h2><p>Contestant names, recent winner history, and app preferences are stored locally on your device. NameSnap does not transmit this information to Marcus Kim or to a NameSnap server.</p></section>
        <section><h2>Analytics, tracking, and advertising</h2><p>NameSnap does not use third-party analytics, advertising SDKs, cross-app tracking, or third-party ads.</p></section>
        <section><h2>Purchases</h2><p>Optional in-app purchases are processed by Apple through the App Store and StoreKit. Apple may provide NameSnap with purchase and entitlement status so the app can unlock features. NameSnap does not receive your payment-card details.</p></section>
        <section><h2>Data sharing</h2><p>NameSnap does not sell, rent, or share personal data with advertisers or data brokers.</p></section>
        <section><h2>Children</h2><p>NameSnap does not knowingly collect personal information from children. Because contestant names are stored only on the device, adults supervising classroom or family use remain in control of that content.</p></section>
        <section><h2>Data deletion</h2><p>You can remove contestant names and winner history inside the app. Deleting NameSnap from your device removes its locally stored app data, subject to normal device backups managed by you or Apple.</p></section>
        <section><h2>Changes to this policy</h2><p>If NameSnap’s data practices change, this page will be updated before the change takes effect and the effective date above will be revised.</p></section>
        <section><h2>Contact</h2><p>Questions about this policy can be sent to <a href="mailto:sidequestsoftware@proton.me?subject=NameSnap%20Privacy">sidequestsoftware@proton.me</a>.</p></section>
      </article>
      <SiteFooter />
    </main>
  );
}
