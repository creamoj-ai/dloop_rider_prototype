-- ============================================================
-- SQL 36: Dealer Revenue — Subscriptions + Fee Audit
-- Date: 2026-02-13
-- Milestone: M5 Dealer Revenue
-- ============================================================

-- 1. dealer_subscriptions — tracks dealer tier + billing
CREATE TABLE IF NOT EXISTS public.dealer_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  dealer_contact_id UUID NOT NULL REFERENCES public.rider_contacts(id) ON DELETE CASCADE,
  rider_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tier TEXT NOT NULL DEFAULT 'starter'
    CHECK (tier IN ('starter', 'pro', 'business', 'enterprise')),
  monthly_fee_cents INTEGER NOT NULL DEFAULT 0,
  commission_rate NUMERIC(5,4) NOT NULL DEFAULT 0.0000,
  per_order_fee_cents INTEGER NOT NULL DEFAULT 50,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ,
  is_active BOOLEAN NOT NULL DEFAULT true,
  stripe_subscription_id TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. fee_audit — immutable audit trail per transaction
CREATE TABLE IF NOT EXISTS public.fee_audit (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  relay_id UUID REFERENCES public.order_relays(id) ON DELETE SET NULL,
  dealer_contact_id UUID REFERENCES public.rider_contacts(id) ON DELETE SET NULL,
  rider_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  total_amount_cents INTEGER NOT NULL,
  dealer_amount_cents INTEGER NOT NULL DEFAULT 0,
  rider_delivery_fee_cents INTEGER NOT NULL DEFAULT 0,
  platform_fee_cents INTEGER NOT NULL DEFAULT 0,
  stripe_fee_cents INTEGER NOT NULL DEFAULT 0,
  dealer_tier TEXT,
  per_order_fee_applied BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. Indexes
CREATE INDEX IF NOT EXISTS idx_dealer_subscriptions_contact
  ON public.dealer_subscriptions (dealer_contact_id)
  WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_dealer_subscriptions_rider
  ON public.dealer_subscriptions (rider_id)
  WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_fee_audit_order
  ON public.fee_audit (order_id);

CREATE INDEX IF NOT EXISTS idx_fee_audit_rider
  ON public.fee_audit (rider_id);

CREATE INDEX IF NOT EXISTS idx_fee_audit_dealer
  ON public.fee_audit (dealer_contact_id);

-- 4. RLS — dealer_subscriptions
ALTER TABLE public.dealer_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Riders see own dealer subscriptions"
  ON public.dealer_subscriptions FOR SELECT
  USING (rider_id = auth.uid());

CREATE POLICY "Service role manages dealer subscriptions"
  ON public.dealer_subscriptions FOR ALL
  USING (true)
  WITH CHECK (true);

-- 5. RLS — fee_audit
ALTER TABLE public.fee_audit ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Riders see own fee audit"
  ON public.fee_audit FOR SELECT
  USING (rider_id = auth.uid());

CREATE POLICY "Service role manages fee audit"
  ON public.fee_audit FOR ALL
  USING (true)
  WITH CHECK (true);

-- 6. Helper function: get active dealer tier
CREATE OR REPLACE FUNCTION public.get_dealer_tier(p_dealer_contact_id UUID)
RETURNS TEXT
LANGUAGE sql
STABLE
AS $$
  SELECT tier
  FROM public.dealer_subscriptions
  WHERE dealer_contact_id = p_dealer_contact_id
    AND is_active = true
    AND (expires_at IS NULL OR expires_at > now())
  ORDER BY created_at DESC
  LIMIT 1;
$$;

-- 7. Seed starter subscriptions for existing dealers (if any)
INSERT INTO public.dealer_subscriptions (dealer_contact_id, rider_id, tier, monthly_fee_cents, per_order_fee_cents)
SELECT
  rc.id AS dealer_contact_id,
  rc.rider_id,
  'starter' AS tier,
  0 AS monthly_fee_cents,
  50 AS per_order_fee_cents
FROM public.rider_contacts rc
WHERE rc.contact_type = 'dealer'
  AND NOT EXISTS (
    SELECT 1 FROM public.dealer_subscriptions ds
    WHERE ds.dealer_contact_id = rc.id AND ds.is_active = true
  );

-- 8. Updated_at trigger
CREATE OR REPLACE FUNCTION public.update_dealer_subscription_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_dealer_subscription_updated_at
  BEFORE UPDATE ON public.dealer_subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION public.update_dealer_subscription_timestamp();
