-- ============================================================
-- SQL 34: Stripe Connect — Express Accounts for Dealers
-- Date: 2026-02-13
-- Milestone: M2.8 Stripe Connect (Destination Charges)
-- ============================================================

-- 1. Add Stripe fields to dealer_platforms
ALTER TABLE public.dealer_platforms
  ADD COLUMN IF NOT EXISTS stripe_account_id TEXT,
  ADD COLUMN IF NOT EXISTS stripe_onboarding_status TEXT
    CHECK (stripe_onboarding_status IN ('pending', 'incomplete', 'complete'))
    DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS stripe_charges_enabled BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS stripe_payouts_enabled BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS stripe_onboarded_at TIMESTAMPTZ;

-- 2. Add Stripe payment tracking to orders
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS stripe_payment_intent_id TEXT,
  ADD COLUMN IF NOT EXISTS stripe_transfer_id TEXT,
  ADD COLUMN IF NOT EXISTS stripe_amount_cents INTEGER,
  ADD COLUMN IF NOT EXISTS stripe_application_fee_cents INTEGER,
  ADD COLUMN IF NOT EXISTS stripe_payment_status TEXT
    CHECK (stripe_payment_status IN ('pending', 'processing', 'succeeded', 'failed', 'refunded'))
    DEFAULT NULL;

-- 3. Add Stripe session ID to order_relays (link Destination Charge to relay)
ALTER TABLE public.order_relays
  ADD COLUMN IF NOT EXISTS stripe_payment_intent_id TEXT;

-- 4. Indexes for Stripe lookups
CREATE INDEX IF NOT EXISTS idx_dealer_platforms_stripe
  ON public.dealer_platforms (stripe_account_id)
  WHERE stripe_account_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_orders_stripe_pi
  ON public.orders (stripe_payment_intent_id)
  WHERE stripe_payment_intent_id IS NOT NULL;

-- 5. Service role policy for stripe-webhook (needs to update orders by payment_intent_id)
-- The webhook Edge Function uses the service role client, so no extra RLS needed.
-- But we add a policy for the operator (WoZ) to read stripe status.

-- Allow service role to read dealer stripe_account_id (for payment routing)
-- This is already covered by service role bypassing RLS.

-- 6. View: dealer_stripe_status (useful for operator form)
CREATE OR REPLACE VIEW public.dealer_stripe_status AS
SELECT
  rc.id AS dealer_contact_id,
  rc.name AS dealer_name,
  rc.phone AS dealer_phone,
  dp.stripe_account_id,
  dp.stripe_onboarding_status,
  dp.stripe_charges_enabled,
  dp.stripe_payouts_enabled,
  dp.stripe_onboarded_at
FROM public.rider_contacts rc
LEFT JOIN public.dealer_platforms dp
  ON dp.contact_id = rc.id
  AND dp.is_active = true
WHERE rc.contact_type = 'dealer';

-- Grant access to the view for authenticated users
GRANT SELECT ON public.dealer_stripe_status TO authenticated;
