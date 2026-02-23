-- ============================================
-- 41. Create clients table
-- ============================================
-- Stores customer information for delivery platform
-- Each client belongs to a rider, tracks loyalty tier and spending

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

CREATE POLICY "Riders can view own clients"
    ON public.clients FOR SELECT
    USING (rider_id = auth.uid());

CREATE POLICY "Riders can insert own clients"
    ON public.clients FOR INSERT
    WITH CHECK (rider_id = auth.uid());

CREATE POLICY "Riders can update own clients"
    ON public.clients FOR UPDATE
    USING (rider_id = auth.uid());

CREATE POLICY "Riders can delete own clients"
    ON public.clients FOR DELETE
    USING (rider_id = auth.uid());

-- Enable Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.clients;

-- Updated_at trigger
CREATE OR REPLACE FUNCTION public.update_clients_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_clients_updated_at
    BEFORE UPDATE ON public.clients
    FOR EACH ROW
    EXECUTE FUNCTION public.update_clients_updated_at();
