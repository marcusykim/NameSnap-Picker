CREATE TABLE IF NOT EXISTS entitlements (
  identity_hash TEXT PRIMARY KEY,
  plan TEXT NOT NULL CHECK (plan IN ('monthly', 'lifetime')),
  active INTEGER NOT NULL DEFAULT 0 CHECK (active IN (0, 1)),
  stripe_customer_id TEXT,
  subscription_id TEXT,
  checkout_session_id TEXT,
  subscription_status TEXT,
  created_at INTEGER NOT NULL DEFAULT (unixepoch()),
  updated_at INTEGER NOT NULL DEFAULT (unixepoch())
);

CREATE UNIQUE INDEX IF NOT EXISTS entitlements_subscription_id
  ON entitlements(subscription_id)
  WHERE subscription_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS entitlements_customer_id
  ON entitlements(stripe_customer_id)
  WHERE stripe_customer_id IS NOT NULL;
