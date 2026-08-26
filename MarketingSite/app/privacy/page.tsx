import type { Metadata } from "next";
import { PublicHero, SiteFooter, SiteHeader } from "../site-chrome";

export const metadata: Metadata = { title: "Privacy Policy", description: "NameSnap privacy policy." };

export default function PrivacyPage() {
  return (
    <main className="public-page"><SiteHeader />
      <PublicHero
        eyebrow="PRIVACY POLICY"
        title="Pick names at random."
        accent="Party while you do it."
        description="Paste or type your list, tap once, and let NameSnap turn a fair random pick into the loudest moment in the room."
        art="/celebrations/robot.png"
        artAlt="A cheerful NameSnap robot holding a winner card"
        artLabel="LOCAL BY DEFAULT"
        facts={["NO ACCOUNT", "NO ADS", "NAMES STAY LOCAL"]}
        actions
      />
      <div className="public-summary shell">
        <span>THE SHORT VERSION</span>
        <p>Your contestants and recent picks stay on the device in front of you. Payment providers only receive what they need to process an optional purchase.</p>
        <time dateTime="2026-08-22">Effective August 22, 2026</time>
      </div>
      <article className="policy policy-grid shell">
        <section><h2>Overview</h2><p>NameSnap is designed to make random picks without requiring an account or sign-in. This policy covers the NameSnap iPhone and iPad app and NameSnap Web at getnamesnap.web.app.</p></section>
        <section><h2>Contestant data stays local</h2><p>Contestant names, recent winner history, and picker preferences are stored locally on your device or browser. NameSnap Web does not send contestant names or winner history to Firebase, Stripe, Marcus Kim, or another NameSnap server.</p></section>
        <section><h2>Analytics, tracking, and advertising</h2><p>NameSnap does not use third-party analytics, advertising SDKs, cross-app tracking, or third-party ads.</p></section>
        <section><h2>Web session and purchase data</h2><p>NameSnap Web stores one strictly necessary, randomly generated browser identifier in local browser storage so that web purchase access can be restored in that browser. Cloudflare stores only a one-way hash of that identifier together with the selected plan, entitlement status, and Stripe customer or subscription identifiers. It does not store your contestant list. Stripe processes web payments and may collect an email address, billing details, and payment information under Stripe’s privacy policy. NameSnap does not receive your full payment-card number.</p></section>
        <section><h2>App Store purchases</h2><p>Optional purchases in the iPhone and iPad app are processed by Apple through the App Store and StoreKit. Apple may provide purchase and entitlement status so the app can unlock features. App Store purchases and web purchases are separate because Apple and Stripe operate separate payment systems.</p></section>
        <section><h2>Service providers and data sharing</h2><p>Firebase provides website hosting. Cloudflare provides the payment service endpoint and stores the minimal web entitlement record described above. Stripe processes web purchases. Apple processes in-app purchases. NameSnap does not sell or rent personal data and does not share it with advertisers or data brokers.</p></section>
        <section><h2>Children</h2><p>NameSnap does not knowingly collect personal information from children. Contestant names stay local. Web checkout is intended for an adult, school employee, or other person authorized to make the purchase; children should not submit payment information.</p></section>
        <section><h2>Data deletion</h2><p>You can clear contestant names and winner history inside NameSnap. Clearing site data in your browser removes locally stored picker data and the random browser identifier, but may also disconnect that browser from a web purchase. For deletion of the corresponding web entitlement record or purchase-related support, email NameSnap support. Deleting the iOS app removes local app data subject to device backups managed by you or Apple.</p></section>
        <section><h2>Changes to this policy</h2><p>If NameSnap’s data practices change, this page will be updated before the change takes effect and the effective date above will be revised.</p></section>
        <section><h2>Contact</h2><p>Questions about this policy can be sent to <a href="mailto:sidequestsoftware@proton.me?subject=NameSnap%20Privacy">sidequestsoftware@proton.me</a>.</p></section>
      </article>
      <SiteFooter />
    </main>
  );
}
