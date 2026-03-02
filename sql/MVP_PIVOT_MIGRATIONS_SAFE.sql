-- ============================================
-- MVP PIVOT MIGRATIONS - SAFE VERSION
-- ============================================
-- This version is idempotent and won't fail on existing tables

-- ============================================
-- 1. Create hot_zones table (skip if exists)
-- ============================================
DO $$
BEGIN
  -- Table creation with IF NOT EXISTS
  CREATE TABLE IF NOT EXISTS public.hot_zones (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            TEXT NOT NULL,
    demand          TEXT NOT NULL DEFAULT 'bassa' CHECK (demand IN ('alta', 'media', 'bassa')),
    orders_per_hour INT NOT NULL DEFAULT 0,
    distance_km     DOUBLE PRECISION NOT NULL DEFAULT 0,
    earning_min     DOUBLE PRECISION NOT NULL DEFAULT 0,
    earning_max     DOUBLE PRECISION NOT NULL DEFAULT 0,
    latitude        DOUBLE PRECISION NOT NULL,
    longitude       DOUBLE PRECISION NOT NULL,
    radius_meters   DOUBLE PRECISION NOT NULL DEFAULT 500,
    active_riders   INT NOT NULL DEFAULT 0,
    trending        TEXT NOT NULL DEFAULT 'flat' CHECK (trending IN ('up', 'flat', 'down')),
    trend_text      TEXT DEFAULT '',
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
  );

  -- Index (skip if exists)
  CREATE INDEX IF NOT EXISTS idx_hot_zones_demand ON public.hot_zones(demand);

  -- RLS
  ALTER TABLE public.hot_zones ENABLE ROW LEVEL SECURITY;

  -- Policy (drop if exists, then recreate)
  DROP POLICY IF EXISTS "Authenticated users can read zones" ON public.hot_zones;
  CREATE POLICY "Authenticated users can read zones"
    ON public.hot_zones FOR SELECT
    USING (auth.role() = 'authenticated');

  -- Realtime (add only if not already added)
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
    AND schemaname = 'public'
    AND tablename = 'hot_zones'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.hot_zones;
  END IF;

  -- Seed data (insert only if table is empty)
  IF NOT EXISTS (SELECT 1 FROM public.hot_zones LIMIT 1) THEN
    INSERT INTO public.hot_zones (name, demand, orders_per_hour, distance_km, earning_min, earning_max, latitude, longitude, radius_meters, active_riders, trending, trend_text) VALUES
      ('Milano Centro', 'alta', 12, 0.5, 16, 20, 45.4642, 9.1900, 800, 8, 'up', 'Domanda in crescita +25% rispetto a ieri'),
      ('Navigli', 'alta', 10, 1.2, 14, 18, 45.4500, 9.1750, 650, 6, 'up', 'Zona aperitivo — picco dalle 18:00 alle 22:00'),
      ('Porta Romana', 'media', 8, 2.0, 12, 15, 45.4500, 9.2050, 550, 4, 'flat', 'Domanda stabile — buona per consegne regolari'),
      ('Isola', 'media', 6, 3.1, 10, 13, 45.4850, 9.1880, 500, 3, 'down', 'Domanda in calo — pochi ristoranti aperti ora'),
      ('Città Studi', 'bassa', 4, 4.5, 8, 10, 45.4780, 9.2250, 450, 2, 'down', 'Zona universitaria — picco solo a pranzo');
  END IF;

  RAISE NOTICE 'hot_zones table ready';
END $$;


-- ============================================
-- 2. Create clients table
-- ============================================

-- Create trigger function first (before table creation)
CREATE OR REPLACE FUNCTION public.update_clients_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
  CREATE TABLE IF NOT EXISTS public.clients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rider_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    phone TEXT,
    address TEXT,
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    zone_id UUID REFERENCES public.hot_zones(id) ON DELETE SET NULL,
    loyalty_tier TEXT NOT NULL DEFAULT 'bronze' CHECK (loyalty_tier IN ('bronze', 'silver', 'gold', 'platinum')),
    loyalty_points INT NOT NULL DEFAULT 0,
    total_orders INT NOT NULL DEFAULT 0,
    total_spent NUMERIC(10,2) NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'vip')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
  );

  -- Indexes
  CREATE INDEX IF NOT EXISTS idx_clients_rider_id ON public.clients(rider_id);
  CREATE INDEX IF NOT EXISTS idx_clients_status ON public.clients(status);
  CREATE INDEX IF NOT EXISTS idx_clients_zone_id ON public.clients(zone_id);

  -- RLS
  ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;

  DROP POLICY IF EXISTS "Riders can view own clients" ON public.clients;
  CREATE POLICY "Riders can view own clients"
    ON public.clients FOR SELECT
    USING (rider_id = auth.uid());

  DROP POLICY IF EXISTS "Riders can insert own clients" ON public.clients;
  CREATE POLICY "Riders can insert own clients"
    ON public.clients FOR INSERT
    WITH CHECK (rider_id = auth.uid());

  DROP POLICY IF EXISTS "Riders can update own clients" ON public.clients;
  CREATE POLICY "Riders can update own clients"
    ON public.clients FOR UPDATE
    USING (rider_id = auth.uid());

  DROP POLICY IF EXISTS "Riders can delete own clients" ON public.clients;
  CREATE POLICY "Riders can delete own clients"
    ON public.clients FOR DELETE
    USING (rider_id = auth.uid());

  -- Realtime
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
    AND schemaname = 'public'
    AND tablename = 'clients'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.clients;
  END IF;

  -- Updated_at trigger
  DROP TRIGGER IF EXISTS set_clients_updated_at ON public.clients;
  CREATE TRIGGER set_clients_updated_at
    BEFORE UPDATE ON public.clients
    FOR EACH ROW
    EXECUTE FUNCTION public.update_clients_updated_at();

  RAISE NOTICE 'clients table ready';
END $$;


-- ============================================
-- 3. Add category field to rider_contacts
-- ============================================
DO $$
BEGIN
  -- Add column if not exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'rider_contacts'
    AND column_name = 'category'
  ) THEN
    ALTER TABLE public.rider_contacts
    ADD COLUMN category TEXT DEFAULT 'grocery'
    CHECK (category IN ('grocery', 'pet', 'pharmacy', 'fashion', 'beauty', 'wellness', 'home_garden', 'electronics'));

    CREATE INDEX idx_rider_contacts_category ON public.rider_contacts(category);

    RAISE NOTICE 'Added category field to rider_contacts';
  ELSE
    RAISE NOTICE 'category field already exists in rider_contacts';
  END IF;

  -- Update existing dealers to have a category (if null)
  UPDATE public.rider_contacts
  SET category = 'grocery'
  WHERE category IS NULL;
END $$;


-- ============================================
-- 3.5. Fix market_products category constraint
-- ============================================
DO $$
BEGIN
  -- Drop old category check constraint if exists
  ALTER TABLE public.market_products DROP CONSTRAINT IF EXISTS market_products_category_check;

  -- Add new category check constraint with grocery + pet
  ALTER TABLE public.market_products DROP CONSTRAINT IF EXISTS market_products_category_check_new;
  ALTER TABLE public.market_products
  ADD CONSTRAINT market_products_category_check_new
  CHECK (category IN ('grocery', 'pet', 'bevande', 'integratori', 'snack'));

  RAISE NOTICE 'Fixed market_products category constraint';
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Could not update constraint (table may not exist yet)';
END $$;


-- ============================================
-- 4. Insert test dealers + customers
-- ============================================
DO $$
DECLARE
  v_rider_id UUID;
BEGIN
  -- Get test rider
  SELECT id INTO v_rider_id FROM auth.users WHERE email = 'creamoj@gmail.com' LIMIT 1;
  IF v_rider_id IS NULL THEN
    RAISE NOTICE 'No rider found for creamoj@gmail.com - skipping test data';
    RETURN;
  END IF;

  -- Check if dealers already exist
  IF EXISTS (SELECT 1 FROM rider_contacts WHERE rider_id = v_rider_id AND name LIKE '%Carrefour%') THEN
    RAISE NOTICE 'Test dealers already exist - skipping insert';
  ELSE
    -- TEST DEALERS (20 items) - grocery + pet
    INSERT INTO rider_contacts (rider_id, name, contact_type, status, phone, total_orders, monthly_earnings, category) VALUES
    -- GROCERY DEALERS (10)
    (v_rider_id, 'Carrefour Express Napoli', 'dealer', 'active', '+39 081 2345678', 142, 120.00, 'grocery'),
    (v_rider_id, 'Esselunga Vomero', 'dealer', 'active', '+39 081 5555111', 98, 95.00, 'grocery'),
    (v_rider_id, 'CooperMarkt Centro', 'dealer', 'active', '+39 081 6666222', 76, 80.00, 'grocery'),
    (v_rider_id, 'Auchan Fuorigrotta', 'dealer', 'potential', '+39 081 7777333', 12, 45.00, 'grocery'),
    (v_rider_id, 'Amazon Fresh Napoli', 'dealer', 'active', '+39 081 8888444', 156, 145.00, 'grocery'),
    (v_rider_id, 'Marianna Supermercati', 'dealer', 'active', '+39 081 9999555', 89, 85.00, 'grocery'),
    (v_rider_id, 'Spesa Online Napoli', 'dealer', 'active', '+39 081 1010111', 124, 110.00, 'grocery'),
    (v_rider_id, 'Alimentari Vomero', 'dealer', 'active', '+39 081 1111222', 67, 75.00, 'grocery'),
    (v_rider_id, 'Bio Market Napoli', 'dealer', 'potential', '+39 081 1212333', 34, 60.00, 'grocery'),
    (v_rider_id, 'Express Alimentari', 'dealer', 'active', '+39 081 1313444', 145, 135.00, 'grocery'),
    -- PET DEALERS (10)
    (v_rider_id, 'PetStore Napoli', 'dealer', 'active', '+39 081 2000111', 78, 85.00, 'pet'),
    (v_rider_id, 'Zooplus Campania', 'dealer', 'active', '+39 081 2001222', 56, 65.00, 'pet'),
    (v_rider_id, 'Veterinari Napoli', 'dealer', 'active', '+39 081 2002333', 92, 100.00, 'pet'),
    (v_rider_id, 'Grooming Center Vomero', 'dealer', 'potential', '+39 081 2003444', 23, 50.00, 'pet'),
    (v_rider_id, 'Pet Supplies Napoli', 'dealer', 'active', '+39 081 2004555', 64, 72.00, 'pet'),
    (v_rider_id, 'Negozio Animali Centro', 'dealer', 'active', '+39 081 2005666', 45, 55.00, 'pet'),
    (v_rider_id, 'Veterinaria San Domenico', 'dealer', 'active', '+39 081 2006777', 87, 95.00, 'pet'),
    (v_rider_id, 'Toelettatura Cani Gatti', 'dealer', 'potential', '+39 081 2007888', 28, 45.00, 'pet'),
    (v_rider_id, 'Pet Shop Premium', 'dealer', 'active', '+39 081 2008999', 102, 115.00, 'pet'),
    (v_rider_id, 'Mangimi e Accessori', 'dealer', 'active', '+39 081 2009100', 71, 78.00, 'pet');

    RAISE NOTICE 'Seeded 20 dealers for rider %', v_rider_id;
  END IF;

  -- Check if customers already exist
  IF EXISTS (SELECT 1 FROM clients WHERE rider_id = v_rider_id AND full_name = 'Marco Rossi') THEN
    RAISE NOTICE 'Test customers already exist - skipping insert';
  ELSE
    -- TEST CUSTOMERS (10)
    INSERT INTO clients (rider_id, full_name, phone, address, lat, lng, loyalty_tier, loyalty_points, total_orders, total_spent, status) VALUES
    (v_rider_id, 'Marco Rossi', '+39 333 1234567', 'Via Vomero 42, Napoli', 40.8450, 14.2580, 'gold', 1200, 45, 650.00, 'active'),
    (v_rider_id, 'Anna Bianchi', '+39 333 2234567', 'Piazza del Plebiscito 1, Napoli', 40.8530, 14.2650, 'silver', 580, 28, 420.00, 'active'),
    (v_rider_id, 'Giuseppe Verdi', '+39 333 3234567', 'Via Fuorigrotta 88, Napoli', 40.8200, 14.1950, 'bronze', 280, 15, 200.00, 'active'),
    (v_rider_id, 'Lucia Ferrari', '+39 333 4234567', 'Via Chiaia 65, Napoli', 40.8390, 14.2470, 'bronze', 125, 8, 120.00, 'active'),
    (v_rider_id, 'Paolo Rizzo', '+39 333 5234567', 'Via Posillipo 12, Napoli', 40.8100, 14.2100, 'silver', 450, 22, 380.00, 'vip'),
    (v_rider_id, 'Elena Rossi', '+39 333 6234567', 'Piazza Montesanto 5, Napoli', 40.8560, 14.2650, 'bronze', 95, 5, 85.00, 'active'),
    (v_rider_id, 'Francesco Russo', '+39 333 7234567', 'Via Cavalleggeri d''Aosta 6, Napoli', 40.8450, 14.1850, 'gold', 980, 38, 580.00, 'vip'),
    (v_rider_id, 'Gabriella Gallo', '+39 333 8234567', 'Via San Carlo Arena 25, Napoli', 40.8650, 14.2450, 'bronze', 165, 9, 145.00, 'active'),
    (v_rider_id, 'Salvatore Marino', '+39 333 9234567', 'Via Arenella 14, Napoli', 40.8150, 14.2450, 'silver', 320, 16, 265.00, 'active'),
    (v_rider_id, 'Vittoria Lombardi', '+39 333 0234567', 'Via Soccavo 33, Napoli', 40.7950, 14.1650, 'bronze', 210, 12, 175.00, 'active');

    RAISE NOTICE 'Seeded 10 customers for rider %', v_rider_id;
  END IF;

  RAISE NOTICE 'Dealers and customers migration complete';
END $$;


-- ============================================
-- 5. Insert 500 test products (grocery + pet)
-- ============================================
-- Note: This is a large insert, run separately if needed
-- File: sql/39_mvp_test_data_products.sql
-- Execute manually after this script completes
