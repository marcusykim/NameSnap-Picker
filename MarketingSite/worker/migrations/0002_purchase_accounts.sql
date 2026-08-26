ALTER TABLE entitlements ADD COLUMN account_hash TEXT;
ALTER TABLE entitlements ADD COLUMN email_hash TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS entitlements_account_hash
  ON entitlements(account_hash)
  WHERE account_hash IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS entitlements_email_hash
  ON entitlements(email_hash)
  WHERE email_hash IS NOT NULL;

CREATE TABLE IF NOT EXISTS checkout_attempts (
  account_hash TEXT NOT NULL,
  plan TEXT NOT NULL CHECK (plan IN ('monthly', 'lifetime')),
  session_id TEXT NOT NULL,
  checkout_url TEXT NOT NULL,
  expires_at INTEGER NOT NULL,
  created_at INTEGER NOT NULL DEFAULT (unixepoch()),
  updated_at INTEGER NOT NULL DEFAULT (unixepoch()),
  PRIMARY KEY (account_hash, plan)
);

CREATE UNIQUE INDEX IF NOT EXISTS checkout_attempts_session
  ON checkout_attempts(session_id);
