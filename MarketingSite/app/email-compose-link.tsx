"use client";

const supportEmailUrl = "mailto:sidequestsoftware@proton.me?subject=NameSnap%20Support";

export function EmailComposeLink() {
  return (
    <a
      aria-label="Send NameSnap support an email"
      className="button button-primary"
      href={supportEmailUrl}
      onClick={(event) => {
        event.preventDefault();
        window.location.assign(supportEmailUrl);
      }}
    >
      Send us an email
    </a>
  );
}
