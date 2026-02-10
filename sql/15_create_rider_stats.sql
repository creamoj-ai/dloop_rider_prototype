-- ============================================
-- 15. Create rider_stats table
-- ============================================
-- Stores lifetime stats and gamification data per rider.
-- Run in Supabase SQL Editor.

CREATE TABLE IF NOT EXISTS public.rider_stats (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rider_id                UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  lifetime_orders         INT NOT NULL DEFAULT 0,
  lifetime_earnings       NUMERIC(10,2) NOT NULL DEFAULT 0,
  lifetime_distance_km    NUMERIC(10,2) NOT NULL DEFAULT 0,
  lifetime_hours_online   NUMERIC(10,2) NOT NULL DEFAULT 0,
  current_daily_streak    INT NOT NULL DEFAULT 0,
  longest_daily_streak    INT NOT NULL DEFAULT 0,
  avg_rating              NUMERIC(3,2) NOT NULL DEFAULT 0,
  total_ratings_count     INT NOT NULL DEFAULT 0,
  best_day_earnings       NUMERIC(10,2) NOT NULL DEFAULT 0,
  best_day_date           DATE,
  achievements_unlocked   INT NOT NULL DEFAULT 0,
  total_achievement_points INT NOT NULL DEFAULT 0,
  current_level           INT NOT NULL DEFAULT 1,
  current_xp              INT NOT NULL DEFAULT 0,
  xp_to_next_level        INT NOT NULL DEFAULT 100,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_rider_stats_rider_id ON public.rider_stats(rider_id);

-- RLS
ALTER TABLE public.rider_stats ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Riders can view own stats" ON public.rider_stats;
CREATE POLICY "Riders can view own stats"
  ON public.rider_stats FOR SELECT
  USING (rider_id = auth.uid());

DROP POLICY IF EXISTS "Riders can update own stats" ON public.rider_stats;
CREATE POLICY "Riders can update own stats"
  ON public.rider_stats FOR UPDATE
  USING (rider_id = auth.uid());

-- Realtime
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.rider_stats;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- Seed data for creamoj@gmail.com
DO $$
DECLARE
  v_rider_id UUID;
BEGIN
  SELECT id INTO v_rider_id FROM auth.users WHERE email = 'creamoj@gmail.com';
  IF v_rider_id IS NULL THEN
    RAISE NOTICE 'creamoj@gmail.com not found, skipping seed';
    RETURN;
  END IF;

  INSERT INTO public.rider_stats (
    rider_id,
    lifetime_orders, lifetime_earnings, lifetime_distance_km, lifetime_hours_online,
    current_daily_streak, longest_daily_streak,
    avg_rating, total_ratings_count,
    best_day_earnings, best_day_date,
    achievements_unlocked, total_achievement_points,
    current_level, current_xp, xp_to_next_level
  ) VALUES (
    v_rider_id,
    247, 3842.50, 1856.3, 312.5,
    5, 14,
    4.78, 203,
    187.50, '2026-01-15',
    8, 1250,
    12, 73, 100
  )
  ON CONFLICT (rider_id) DO NOTHING;

  RAISE NOTICE 'Seeded rider_stats for %', v_rider_id;
END $$;
