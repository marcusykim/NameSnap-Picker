-- Reserve one pending checkout per email; the owner is a verified account or
-- a random browser identity. An email address alone never grants access.
CREATE TABLE purchase_checkouts (
  email_hash TEXT PRIMARY KEY,
  owner_hash TEXT NOT NULL UNIQUE,
  plan TEXT NOT NULL CHECK (plan IN ('monthly', 'lifetime')),
  generation TEXT NOT NULL UNIQUE,
  session_id TEXT UNIQUE,
  expires_at INTEGER NOT NULL
);
