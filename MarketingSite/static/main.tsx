import { createRoot } from "react-dom/client";
import "../app/globals.css";
import { NameSnapWebApp } from "../app/namesnap-web-app";
import PrivacyPage from "../app/privacy/page";
import SupportPage from "../app/support/page";
import TermsPage from "../app/terms/page";

const routes = {
  "/privacy": {
    title: "Privacy Policy | NameSnap",
    description: "NameSnap privacy policy.",
    element: <PrivacyPage />,
  },
  "/support": {
    title: "Support | NameSnap",
    description: "Help, FAQs, and contact information for NameSnap.",
    element: <SupportPage />,
  },
  "/terms": {
    title: "EULA + Terms of Use | NameSnap",
    description: "NameSnap end-user license agreement and terms of use.",
    element: <TermsPage />,
  },
} as const;

const normalizedPath = window.location.pathname.replace(/\/+$/, "") || "/";
const route = routes[normalizedPath as keyof typeof routes];

if (route) {
  document.title = route.title;
  document.querySelector('meta[name="description"]')?.setAttribute("content", route.description);
}

createRoot(document.getElementById("root")!).render(route?.element ?? <NameSnapWebApp />);
