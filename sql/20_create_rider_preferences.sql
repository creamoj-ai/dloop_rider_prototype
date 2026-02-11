-- ===========================================
-- 20. Rider Preferences table
-- ===========================================

CREATE TABLE IF NOT EXISTS public.rider_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rider_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,

    -- Vehicle settings
    vehicle_type TEXT NOT NULL DEFAULT 'scooter' CHECK (vehicle_type IN ('bicicletta', 'scooter', 'auto')),
    max_distance_km NUMERIC(4,1) NOT NULL DEFAULT 5.0,

    -- Pre-shift checklist (JSONB array of checked item keys)
    checklist JSONB NOT NULL DEFAULT '[]'::jsonb,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- RLS
ALTER TABLE public.rider_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own preferences"
    ON public.rider_preferences FOR SELECT
    USING (rider_id = auth.uid());

CREATE POLICY "Users can insert own preferences"
    ON public.rider_preferences FOR INSERT
    WITH CHECK (rider_id = auth.uid());

CREATE POLICY "Users can update own preferences"
    ON public.rider_preferences FOR UPDATE
    USING (rider_id = auth.uid());

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.rider_preferences;

-- Updated_at trigger
CREATE OR REPLACE FUNCTION public.update_rider_preferences_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_rider_preferences_updated_at
    BEFORE UPDATE ON public.rider_preferences
    FOR EACH ROW
    EXECUTE FUNCTION public.update_rider_preferences_updated_at();

-- Seed default preferences for existing user
DO $$
DECLARE
    v_rider_id UUID;
BEGIN
    SELECT id INTO v_rider_id FROM auth.users WHERE email = 'creamoj@gmail.com' LIMIT 1;
    IF v_rider_id IS NOT NULL THEN
        INSERT INTO public.rider_preferences (rider_id, vehicle_type, max_distance_km, checklist)
        VALUES (v_rider_id, 'scooter', 5.0, '[]'::jsonb)
        ON CONFLICT (rider_id) DO NOTHING;
    END IF;
END $$;
