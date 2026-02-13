-- ============================================================
-- SQL 34: Smart Dispatch — PostGIS, rider_locations, dispatch_log, RPCs
-- ============================================================
-- Milestone: M4 Smart Dispatch
-- Enables intelligent order-to-rider matching using:
--   1. PostGIS for geographic proximity
--   2. Multi-factor scoring (proximity, rating, acceptance, specialization)
--   3. Priority dispatch with timeout escalation
-- ============================================================

-- ── 1. Enable PostGIS extension ──────────────────────────────
CREATE EXTENSION IF NOT EXISTS postgis;

-- ── 2. Create hot_zones table (if not exists) ────────────────
-- The Flutter app references this table but it was never created via SQL.
CREATE TABLE IF NOT EXISTS public.hot_zones (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            TEXT NOT NULL,
    demand          TEXT NOT NULL DEFAULT 'media'
                    CHECK (demand IN ('alta', 'media', 'bassa')),
    orders_per_hour INT NOT NULL DEFAULT 0,
    distance_km     NUMERIC(8,2) NOT NULL DEFAULT 0,
    earning_min     NUMERIC(8,2) NOT NULL DEFAULT 0,
    earning_max     NUMERIC(8,2) NOT NULL DEFAULT 0,
    latitude        DOUBLE PRECISION NOT NULL DEFAULT 0,
    longitude       DOUBLE PRECISION NOT NULL DEFAULT 0,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.hot_zones ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view hot zones"
    ON public.hot_zones FOR SELECT
    USING (true);

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.hot_zones;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- Seed Napoli-area zones for WoZ phase
INSERT INTO public.hot_zones (name, demand, orders_per_hour, distance_km, earning_min, earning_max, latitude, longitude)
SELECT * FROM (VALUES
    ('Afragola Centro',   'alta',  8,  0.5,  14, 18, 40.9219, 14.3094),
    ('Casoria',           'media', 5,  2.0,  10, 14, 40.9067, 14.2900),
    ('Cardito-Crispano',  'media', 4,  3.0,  10, 13, 40.9500, 14.3200),
    ('Acerra',            'bassa', 3,  5.0,   8, 12, 40.9450, 14.3700)
) AS v(name, demand, orders_per_hour, distance_km, earning_min, earning_max, latitude, longitude)
WHERE NOT EXISTS (SELECT 1 FROM public.hot_zones LIMIT 1);

-- ── 3. rider_locations — real-time GPS tracking ──────────────
-- One row per rider (upsert pattern). Keeps table tiny.
CREATE TABLE IF NOT EXISTS public.rider_locations (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rider_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    location    GEOGRAPHY(Point, 4326) NOT NULL,
    heading     DOUBLE PRECISION,
    speed       DOUBLE PRECISION DEFAULT 0,
    accuracy    DOUBLE PRECISION,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.rider_locations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Riders can upsert own location"
    ON public.rider_locations FOR ALL TO authenticated
    USING (rider_id = auth.uid())
    WITH CHECK (rider_id = auth.uid());

CREATE INDEX IF NOT EXISTS idx_rider_locations_geo
    ON public.rider_locations USING GIST (location);

CREATE INDEX IF NOT EXISTS idx_rider_locations_updated
    ON public.rider_locations (updated_at DESC);

-- ── 4. dispatch_log — audit trail for dispatch decisions ─────
CREATE TABLE IF NOT EXISTS public.dispatch_log (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id        UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    rider_id        UUID REFERENCES auth.users(id),
    action          TEXT NOT NULL
                    CHECK (action IN (
                        'scored', 'assigned', 'accepted', 'rejected',
                        'timeout', 'broadcast', 'escalated', 'no_riders'
                    )),
    score           DOUBLE PRECISION,
    factors_json    JSONB,
    distance_km     DOUBLE PRECISION,
    attempt_number  INT DEFAULT 1,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.dispatch_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Riders can view own dispatch logs"
    ON public.dispatch_log FOR SELECT TO authenticated
    USING (rider_id = auth.uid());

CREATE POLICY "Service role full access on dispatch_log"
    ON public.dispatch_log FOR ALL
    USING (auth.role() = 'service_role');

CREATE INDEX IF NOT EXISTS idx_dispatch_log_order
    ON public.dispatch_log (order_id, created_at);

CREATE INDEX IF NOT EXISTS idx_dispatch_log_rider
    ON public.dispatch_log (rider_id, created_at DESC);

-- ── 5. Add dispatch columns to orders ────────────────────────
ALTER TABLE public.orders
    ADD COLUMN IF NOT EXISTS dispatch_status TEXT
        DEFAULT 'pending'
        CHECK (dispatch_status IN ('pending', 'dispatching', 'assigned', 'broadcast', 'escalated'));

ALTER TABLE public.orders
    ADD COLUMN IF NOT EXISTS dispatch_attempts INT DEFAULT 0;

-- ── 6. Add acceptance metrics to rider_stats ─────────────────
ALTER TABLE public.rider_stats
    ADD COLUMN IF NOT EXISTS acceptance_rate DOUBLE PRECISION DEFAULT 1.0;

ALTER TABLE public.rider_stats
    ADD COLUMN IF NOT EXISTS total_dispatches INT DEFAULT 0;

ALTER TABLE public.rider_stats
    ADD COLUMN IF NOT EXISTS total_accepted INT DEFAULT 0;

-- ── 7. RPC: get_nearby_riders ────────────────────────────────
-- Returns online riders within radius, ordered by distance.
-- Used by dispatch-order Edge Function.
CREATE OR REPLACE FUNCTION public.get_nearby_riders(
    p_lat DOUBLE PRECISION,
    p_lng DOUBLE PRECISION,
    p_radius_km DOUBLE PRECISION DEFAULT 5.0,
    p_exclude_rider_id UUID DEFAULT NULL
)
RETURNS TABLE (
    rider_id UUID,
    distance_km DOUBLE PRECISION,
    heading DOUBLE PRECISION,
    speed DOUBLE PRECISION,
    location_updated_at TIMESTAMPTZ,
    avg_rating DOUBLE PRECISION,
    acceptance_rate DOUBLE PRECISION,
    lifetime_orders INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        rl.rider_id,
        ST_Distance(
            rl.location,
            ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography
        ) / 1000.0 AS distance_km,
        rl.heading,
        rl.speed,
        rl.updated_at AS location_updated_at,
        COALESCE(rs.avg_rating::double precision, 5.0) AS avg_rating,
        COALESCE(rs.acceptance_rate, 1.0) AS acceptance_rate,
        COALESCE(rs.lifetime_orders, 0) AS lifetime_orders
    FROM public.rider_locations rl
    INNER JOIN public.sessions s
        ON s.rider_id = rl.rider_id
        AND s.is_active = true
    LEFT JOIN public.rider_stats rs
        ON rs.rider_id = rl.rider_id
    WHERE
        ST_DWithin(
            rl.location,
            ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography,
            p_radius_km * 1000
        )
        AND rl.updated_at > NOW() - INTERVAL '10 minutes'
        AND (p_exclude_rider_id IS NULL OR rl.rider_id != p_exclude_rider_id)
    ORDER BY distance_km ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── 8. RPC: upsert_rider_location ───────────────────────────
-- Called by Flutter app to update rider GPS position.
-- Uses auth.uid() so riders can only update their own location.
CREATE OR REPLACE FUNCTION public.upsert_rider_location(
    p_lat DOUBLE PRECISION,
    p_lng DOUBLE PRECISION,
    p_heading DOUBLE PRECISION DEFAULT NULL,
    p_speed DOUBLE PRECISION DEFAULT 0,
    p_accuracy DOUBLE PRECISION DEFAULT NULL
)
RETURNS void AS $$
BEGIN
    INSERT INTO public.rider_locations (rider_id, location, heading, speed, accuracy, updated_at)
    VALUES (
        auth.uid(),
        ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography,
        p_heading,
        p_speed,
        p_accuracy,
        now()
    )
    ON CONFLICT (rider_id) DO UPDATE SET
        location = EXCLUDED.location,
        heading = EXCLUDED.heading,
        speed = EXCLUDED.speed,
        accuracy = EXCLUDED.accuracy,
        updated_at = now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── 9. Update RLS on orders for assigned dispatch ────────────
-- Riders should also see orders assigned to them (priority window)
DO $$
BEGIN
  DROP POLICY IF EXISTS "Riders can view own and broadcast orders" ON public.orders;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

CREATE POLICY "Riders can view own and broadcast orders"
    ON public.orders FOR SELECT
    USING (
      rider_id = auth.uid()
      OR assigned_rider_id = auth.uid()
      OR (
        status = 'pending'
        AND assigned_rider_id IS NULL
        AND (
          dispatch_status = 'broadcast'
          OR (priority_expires_at IS NOT NULL AND priority_expires_at < now())
        )
      )
    );
