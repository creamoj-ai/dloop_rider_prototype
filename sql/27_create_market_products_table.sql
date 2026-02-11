-- ============================================
-- 27. Market Products — Rider product catalog
-- ============================================

CREATE TABLE IF NOT EXISTS public.market_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rider_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC(10,2) NOT NULL,
    cost_price NUMERIC(10,2) NOT NULL DEFAULT 0,
    category TEXT NOT NULL CHECK (category IN ('bevande', 'food', 'integratori', 'altro')),
    image_url TEXT,
    stock INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    sold_count INT NOT NULL DEFAULT 0,
    views_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- RLS
ALTER TABLE public.market_products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Riders can view own products"
    ON public.market_products FOR SELECT
    USING (rider_id = auth.uid());

CREATE POLICY "Riders can insert own products"
    ON public.market_products FOR INSERT
    WITH CHECK (rider_id = auth.uid());

CREATE POLICY "Riders can update own products"
    ON public.market_products FOR UPDATE
    USING (rider_id = auth.uid());

CREATE POLICY "Riders can delete own products"
    ON public.market_products FOR DELETE
    USING (rider_id = auth.uid());

-- Indexes
CREATE INDEX IF NOT EXISTS idx_market_products_rider_active
    ON public.market_products (rider_id, is_active)
    WHERE is_active = true;

-- Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.market_products;

-- Updated_at trigger
CREATE OR REPLACE FUNCTION public.update_market_products_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_market_products_updated_at
    BEFORE UPDATE ON public.market_products
    FOR EACH ROW
    EXECUTE FUNCTION public.update_market_products_updated_at();

-- Seed data for creamoj@gmail.com
DO $$
DECLARE
  v_rider_id UUID;
BEGIN
  SELECT id INTO v_rider_id FROM auth.users WHERE email = 'creamoj@gmail.com' LIMIT 1;
  IF v_rider_id IS NOT NULL THEN
    INSERT INTO public.market_products (rider_id, name, description, price, cost_price, category, stock, sold_count) VALUES
      (v_rider_id, 'Energy Drink Box', 'Box 6x energy drink premium', 15.00, 8.50, 'bevande', 24, 12),
      (v_rider_id, 'Snack Box', 'Assortimento snack salutari', 12.00, 6.00, 'food', 18, 8),
      (v_rider_id, 'Premium Water Pack', 'Pack 12x acqua minerale premium', 8.50, 4.00, 'bevande', 30, 15),
      (v_rider_id, 'Protein Bar Pack', 'Pack 10x barrette proteiche', 18.00, 10.00, 'food', 12, 6),
      (v_rider_id, 'Electrolyte Mix', 'Integratore elettroliti 30 bustine', 9.90, 5.50, 'integratori', 20, 10),
      (v_rider_id, 'Coffee Kit', 'Kit caffè specialty 250g + filtri', 22.00, 12.00, 'bevande', 8, 3);
    RAISE NOTICE 'Seeded 6 market products for rider %', v_rider_id;
  END IF;
END $$;
