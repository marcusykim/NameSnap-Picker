import type { Metadata } from "next";
import { NameSnapWebApp } from "./namesnap-web-app";

export const metadata: Metadata = {
  title: "NameSnap Web — Pick a winner live",
  description:
    "Paste a list, spin live, and make a fair pick on stream, in class, or on any shared screen.",
};

export default function Home() {
  return <NameSnapWebApp />;
}
