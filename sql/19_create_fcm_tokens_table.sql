-- ============================================
-- 19. Create FCM tokens table
-- ============================================
-- Stores Firebase Cloud Messaging device tokens for push notifications

CREATE TABLE IF NOT EXISTS public.fcm_tokens (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rider_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token       TEXT NOT NULL,
  device_info TEXT DEFAULT '',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(rider_id, token)
);

CREATE INDEX idx_fcm_tokens_rider ON public.fcm_tokens(rider_id);

-- RLS
ALTER TABLE public.fcm_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Riders can view own tokens"
  ON public.fcm_tokens FOR SELECT
  USING (rider_id = auth.uid());

CREATE POLICY "Riders can insert own tokens"
  ON public.fcm_tokens FOR INSERT
  WITH CHECK (rider_id = auth.uid());

CREATE POLICY "Riders can update own tokens"
  ON public.fcm_tokens FOR UPDATE
  USING (rider_id = auth.uid())
  WITH CHECK (rider_id = auth.uid());

CREATE POLICY "Riders can delete own tokens"
  ON public.fcm_tokens FOR DELETE
  USING (rider_id = auth.uid());
