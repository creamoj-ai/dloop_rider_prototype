-- ============================================
-- 20. Create hot_zones table
-- ============================================
-- Stores delivery hot zones with demand levels, coordinates, and earning estimates
-- Used by the zone map screen and hot zones widget

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

CREATE INDEX idx_hot_zones_demand ON public.hot_zones(demand);

-- RLS: everyone authenticated can read zones (they're public data for all riders)
ALTER TABLE public.hot_zones ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read zones"
  ON public.hot_zones FOR SELECT
  USING (auth.role() = 'authenticated');

-- Enable Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.hot_zones;

-- Seed 5 Milano zones
INSERT INTO public.hot_zones (name, demand, orders_per_hour, distance_km, earning_min, earning_max, latitude, longitude, radius_meters, active_riders, trending, trend_text) VALUES
  ('Milano Centro', 'alta', 12, 0.5, 16, 20, 45.4642, 9.1900, 800, 8, 'up', 'Domanda in crescita +25% rispetto a ieri'),
  ('Navigli', 'alta', 10, 1.2, 14, 18, 45.4500, 9.1750, 650, 6, 'up', 'Zona aperitivo — picco dalle 18:00 alle 22:00'),
  ('Porta Romana', 'media', 8, 2.0, 12, 15, 45.4500, 9.2050, 550, 4, 'flat', 'Domanda stabile — buona per consegne regolari'),
  ('Isola', 'media', 6, 3.1, 10, 13, 45.4850, 9.1880, 500, 3, 'down', 'Domanda in calo — pochi ristoranti aperti ora'),
  ('Città Studi', 'bassa', 4, 4.5, 8, 10, 45.4780, 9.2250, 450, 2, 'down', 'Zona universitaria — picco solo a pranzo');
