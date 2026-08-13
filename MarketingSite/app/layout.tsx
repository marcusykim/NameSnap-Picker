import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL(
    process.env.NEXT_PUBLIC_SITE_URL ?? "https://getnamesnap.web.app",
  ),
  title: {
    default: "NameSnap — Fair random picks in seconds",
    template: "%s | NameSnap",
  },
  description: "A fast, playful random name picker for classrooms, giveaways, games, teams, and live streams.",
  icons: { icon: "/namesnap-icon.png", apple: "/namesnap-icon.png" },
  openGraph: {
    title: "NameSnap — Fair random picks in seconds",
    description: "Paste names, tap spin, and get a fair winner in seconds.",
    images: ["/og.png"],
    type: "website",
  },
  twitter: { card: "summary_large_image", images: ["/og.png"] },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>{children}</body></html>;
}
