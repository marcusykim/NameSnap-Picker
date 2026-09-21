-- Freeze Checkout parameters before calling Stripe so an uncertain response can
-- be retried from another browser without generating another payable session.
ALTER TABLE purchase_checkouts ADD COLUMN customer_id TEXT;
ALTER TABLE purchase_checkouts ADD COLUMN identity_hash TEXT;
ALTER TABLE purchase_checkouts ADD COLUMN buyer_identity TEXT;
ALTER TABLE purchase_checkouts ADD COLUMN account_hash TEXT;
ALTER TABLE purchase_checkouts ADD COLUMN first_attempt_at INTEGER;
