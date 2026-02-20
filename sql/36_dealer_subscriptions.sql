-- ============================================================
-- SQL 36: Dealer Subscriptions + Fee Audit + get_dealer_tier RPC
-- Date: 2026-02-20
-- Milestone: M6 Scale Ready
-- ============================================================

-- 1. Dealer subscription tiers
CREATE TABLE IF NOT EXISTS public.dealer_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  dealer_contact_id UUID NOT NULL REFERENCES public.rider_contacts(id),
  tier TEXT NOT NULL CHECK (tier IN ('starter', 'pro', 'business', 'enterprise')) DEFAULT 'starter',
  stripe_subscription_id TEXT,
  stripe_customer_id TEXT,
  monthly_price_cents INTEGER NOT NULL DEFAULT 0,
  per_order_fee_cents INTEGER DEFAULT 50, -- €0.50 for starter
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  ends_at TIMESTAMPTZ,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index for quick tier lookup
CREATE INDEX IF NOT EXISTS idx_dealer_subscriptions_active
  ON public.dealer_subscriptions (dealer_contact_id, is_active)
  WHERE is_active = true;

-- 2. Fee audit table (immutable append-only log)
CREATE TABLE IF NOT EXISTS public.fee_audit (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES public.orders(id),
  relay_id UUID,
  dealer_contact_id UUID,
  rider_id UUID,
  total_amount_cents INTEGER NOT NULL,
  dealer_amount_cents INTEGER NOT NULL,
  platform_fee_cents INTEGER NOT NULL DEFAULT 0,
  stripe_fee_cents INTEGER NOT NULL DEFAULT 0,
  dealer_tier TEXT,
  per_order_fee_applied BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- No UPDATE or DELETE policy — append-only by design
CREATE INDEX IF NOT EXISTS idx_fee_audit_order
  ON public.fee_audit (order_id);

CREATE INDEX IF NOT EXISTS idx_fee_audit_dealer
  ON public.fee_audit (dealer_contact_id)
  WHERE dealer_contact_id IS NOT NULL;

-- 3. RPC: get_dealer_tier — used by stripe-webhook to look up dealer tier
CREATE OR REPLACE FUNCTION public.get_dealer_tier(p_dealer_contact_id UUID)
RETURNS TEXT
LANGUAGE sql
STABLE
AS $$
  SELECT tier
  FROM public.dealer_subscriptions
  WHERE dealer_contact_id = p_dealer_contact_id
    AND is_active = true
  ORDER BY created_at DESC
  LIMIT 1;
$$;

-- 4. Seed: default starter subscription for existing dealers
INSERT INTO public.dealer_subscriptions (dealer_contact_id, tier, per_order_fee_cents)
SELECT rc.id, 'starter', 50
FROM public.rider_contacts rc
WHERE rc.contact_type = 'dealer'
  AND NOT EXISTS (
    SELECT 1 FROM public.dealer_subscriptions ds
    WHERE ds.dealer_contact_id = rc.id AND ds.is_active = true
  );

-- 5. RLS: service role bypasses, authenticated can read own
ALTER TABLE public.dealer_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fee_audit ENABLE ROW LEVEL SECURITY;

-- Service role has full access (no policy needed, bypasses RLS)
-- Authenticated users can read fee_audit for their own orders
CREATE POLICY IF NOT EXISTS "riders_read_own_fee_audit" ON public.fee_audit
  FOR SELECT TO authenticated
  USING (rider_id = auth.uid());

-- Grant access
GRANT SELECT ON public.dealer_subscriptions TO authenticated;
GRANT SELECT ON public.fee_audit TO authenticated;
