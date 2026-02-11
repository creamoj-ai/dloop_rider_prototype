-- ============================================
-- 29. Dealer Platforms — Bot/site integration config
-- ============================================
-- Predisposes AI bot integration with dealer websites and third-party platforms.
-- Each dealer (rider_contacts with type=dealer) can have multiple platform connections.
-- The api_key authenticates incoming webhooks from external platforms.
-- The scrape_url allows the AI bot to fetch and parse the dealer's menu.

CREATE TABLE IF NOT EXISTS public.dealer_platforms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rider_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    contact_id UUID REFERENCES public.rider_contacts(id) ON DELETE CASCADE,
    platform_type TEXT NOT NULL CHECK (platform_type IN ('website', 'justeat', 'deliveroo', 'glovo', 'ubereats', 'whatsapp', 'custom')),
    platform_name TEXT NOT NULL,
    webhook_url TEXT,
    api_key TEXT,
    scrape_url TEXT,
    config JSONB NOT NULL DEFAULT '{}',
    is_active BOOLEAN NOT NULL DEFAULT true,
    last_sync_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- RLS
ALTER TABLE public.dealer_platforms ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Riders can view own platforms"
    ON public.dealer_platforms FOR SELECT
    USING (rider_id = auth.uid());

CREATE POLICY "Riders can insert own platforms"
    ON public.dealer_platforms FOR INSERT
    WITH CHECK (rider_id = auth.uid());

CREATE POLICY "Riders can update own platforms"
    ON public.dealer_platforms FOR UPDATE
    USING (rider_id = auth.uid());

CREATE POLICY "Riders can delete own platforms"
    ON public.dealer_platforms FOR DELETE
    USING (rider_id = auth.uid());

-- Indexes
CREATE INDEX IF NOT EXISTS idx_dealer_platforms_rider_active
    ON public.dealer_platforms (rider_id, is_active)
    WHERE is_active = true;

-- Seed data for creamoj@gmail.com
DO $$
DECLARE
  v_rider_id UUID;
  v_dealer_id UUID;
BEGIN
  SELECT id INTO v_rider_id FROM auth.users WHERE email = 'creamoj@gmail.com' LIMIT 1;
  IF v_rider_id IS NULL THEN RETURN; END IF;

  -- Get first dealer contact
  SELECT id INTO v_dealer_id FROM public.rider_contacts
    WHERE rider_id = v_rider_id AND contact_type = 'dealer' LIMIT 1;

  IF v_dealer_id IS NOT NULL THEN
    INSERT INTO public.dealer_platforms (rider_id, contact_id, platform_type, platform_name, webhook_url, api_key, scrape_url) VALUES
      (v_rider_id, v_dealer_id, 'website', 'Trattoria Napoli Centro - Sito', 'https://trattorianapoli.it/api/orders', 'dk_' || encode(gen_random_bytes(16), 'hex'), 'https://trattorianapoli.it/menu'),
      (v_rider_id, v_dealer_id, 'whatsapp', 'Trattoria Napoli Centro - WhatsApp', NULL, 'dk_' || encode(gen_random_bytes(16), 'hex'), NULL);
    RAISE NOTICE 'Seeded 2 dealer platforms for rider %', v_rider_id;
  ELSE
    RAISE NOTICE 'No dealer contacts found for rider %, skipping platform seed', v_rider_id;
  END IF;
END $$;
