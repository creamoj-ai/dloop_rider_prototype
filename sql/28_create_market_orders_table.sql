-- ============================================
-- 28. Market Orders — Customer orders for rider products
-- ============================================

CREATE TABLE IF NOT EXISTS public.market_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rider_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.market_products(id) ON DELETE SET NULL,
    product_name TEXT NOT NULL,
    customer_name TEXT NOT NULL,
    customer_phone TEXT,
    customer_address TEXT,
    quantity INT NOT NULL DEFAULT 1,
    unit_price NUMERIC(10,2) NOT NULL,
    total_price NUMERIC(10,2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'delivering', 'delivered', 'cancelled')),
    source TEXT NOT NULL DEFAULT 'app' CHECK (source IN ('bot', 'website', 'whatsapp', 'phone', 'app')),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    accepted_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ
);

-- RLS
ALTER TABLE public.market_orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Riders can view own market orders"
    ON public.market_orders FOR SELECT
    USING (rider_id = auth.uid());

CREATE POLICY "Riders can insert own market orders"
    ON public.market_orders FOR INSERT
    WITH CHECK (rider_id = auth.uid());

CREATE POLICY "Riders can update own market orders"
    ON public.market_orders FOR UPDATE
    USING (rider_id = auth.uid());

-- Indexes
CREATE INDEX IF NOT EXISTS idx_market_orders_rider_status
    ON public.market_orders (rider_id, status);

CREATE INDEX IF NOT EXISTS idx_market_orders_rider_created
    ON public.market_orders (rider_id, created_at DESC);

-- Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.market_orders;

-- Seed data for creamoj@gmail.com
DO $$
DECLARE
  v_rider_id UUID;
  v_product_energy UUID;
  v_product_snack UUID;
  v_product_protein UUID;
BEGIN
  SELECT id INTO v_rider_id FROM auth.users WHERE email = 'creamoj@gmail.com' LIMIT 1;
  IF v_rider_id IS NULL THEN RETURN; END IF;

  SELECT id INTO v_product_energy FROM public.market_products WHERE rider_id = v_rider_id AND name = 'Energy Drink Box' LIMIT 1;
  SELECT id INTO v_product_snack FROM public.market_products WHERE rider_id = v_rider_id AND name = 'Snack Box' LIMIT 1;
  SELECT id INTO v_product_protein FROM public.market_products WHERE rider_id = v_rider_id AND name = 'Protein Bar Pack' LIMIT 1;

  INSERT INTO public.market_orders (rider_id, product_id, product_name, customer_name, customer_phone, customer_address, quantity, unit_price, total_price, status, source, delivered_at) VALUES
    (v_rider_id, v_product_energy, 'Energy Drink Box', 'Anna Verdi', '+39 333 1234567', 'Via Chiaia 45, Napoli', 1, 15.00, 15.00, 'delivered', 'whatsapp', now() - interval '2 hours'),
    (v_rider_id, v_product_snack, 'Snack Box', 'Paolo Greco', '+39 340 9876543', 'Via Toledo 120, Napoli', 2, 12.00, 24.00, 'delivering', 'app', NULL),
    (v_rider_id, v_product_protein, 'Protein Bar Pack', 'Maria Longo', '+39 328 5551234', 'Corso Umberto 88, Napoli', 1, 18.00, 18.00, 'pending', 'bot', NULL);

  RAISE NOTICE 'Seeded 3 market orders for rider %', v_rider_id;
END $$;
