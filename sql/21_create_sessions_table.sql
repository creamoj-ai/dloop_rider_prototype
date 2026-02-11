-- ===========================================
-- 21. Sessions table (prototype version)
-- ===========================================

CREATE TABLE IF NOT EXISTS public.sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rider_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Timing
    start_time TIMESTAMPTZ NOT NULL DEFAULT now(),
    end_time TIMESTAMPTZ,
    duration_minutes INT,
    is_active BOOLEAN NOT NULL DEFAULT true,

    -- Mode
    mode TEXT DEFAULT 'earn' CHECK (mode IN ('earn', 'grow', 'rest', 'market')),

    -- Performance
    session_earnings NUMERIC(10,2) NOT NULL DEFAULT 0,
    orders_completed INT NOT NULL DEFAULT 0,
    distance_km NUMERIC(8,2) NOT NULL DEFAULT 0,
    active_minutes INT NOT NULL DEFAULT 0,
    break_minutes INT NOT NULL DEFAULT 0,

    -- Metadata
    notes TEXT,

    -- Audit
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- RLS
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own sessions"
    ON public.sessions FOR SELECT
    USING (rider_id = auth.uid());

CREATE POLICY "Users can insert own sessions"
    ON public.sessions FOR INSERT
    WITH CHECK (rider_id = auth.uid());

CREATE POLICY "Users can update own sessions"
    ON public.sessions FOR UPDATE
    USING (rider_id = auth.uid());

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.sessions;

-- Updated_at trigger
CREATE OR REPLACE FUNCTION public.update_sessions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_sessions_updated_at
    BEFORE UPDATE ON public.sessions
    FOR EACH ROW
    EXECUTE FUNCTION public.update_sessions_updated_at();

-- Index for active session lookup
CREATE INDEX IF NOT EXISTS idx_sessions_rider_active
    ON public.sessions (rider_id, is_active)
    WHERE is_active = true;
