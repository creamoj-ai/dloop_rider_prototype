-- ===========================================
-- 23. Add settings columns to rider_preferences
-- ===========================================

-- Push notifications toggle (controls FCM token registration)
ALTER TABLE public.rider_preferences
    ADD COLUMN IF NOT EXISTS push_notifications BOOLEAN NOT NULL DEFAULT true;

-- Order sounds toggle
ALTER TABLE public.rider_preferences
    ADD COLUMN IF NOT EXISTS order_sounds BOOLEAN NOT NULL DEFAULT true;

-- Biometric lock toggle (controls biometric gate on app launch)
ALTER TABLE public.rider_preferences
    ADD COLUMN IF NOT EXISTS biometric_lock BOOLEAN NOT NULL DEFAULT true;

-- Distance unit preference
ALTER TABLE public.rider_preferences
    ADD COLUMN IF NOT EXISTS distance_unit TEXT NOT NULL DEFAULT 'km';

-- Add check constraint separately
ALTER TABLE public.rider_preferences
    DROP CONSTRAINT IF EXISTS rider_preferences_distance_unit_check;
ALTER TABLE public.rider_preferences
    ADD CONSTRAINT rider_preferences_distance_unit_check CHECK (distance_unit IN ('km', 'mi'));
