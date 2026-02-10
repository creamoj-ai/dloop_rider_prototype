-- ============================================
-- 17. Create notifications table
-- ============================================
-- Stores in-app notifications for riders: orders, earnings, milestones

CREATE TABLE IF NOT EXISTS public.notifications (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rider_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type        TEXT NOT NULL CHECK (type IN (
    'new_order', 'order_accepted', 'order_picked_up', 'order_delivered', 'order_cancelled',
    'new_earning', 'daily_target_reached', 'achievement',
    'system'
  )),
  title       TEXT NOT NULL,
  body        TEXT NOT NULL DEFAULT '',
  data        JSONB DEFAULT '{}',
  is_read     BOOLEAN NOT NULL DEFAULT false,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX idx_notifications_rider_id ON public.notifications(rider_id);
CREATE INDEX idx_notifications_rider_unread ON public.notifications(rider_id, is_read) WHERE is_read = false;
CREATE INDEX idx_notifications_created_at ON public.notifications(created_at);

-- RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Riders can view own notifications"
  ON public.notifications FOR SELECT
  USING (rider_id = auth.uid());

CREATE POLICY "Riders can update own notifications"
  ON public.notifications FOR UPDATE
  USING (rider_id = auth.uid())
  WITH CHECK (rider_id = auth.uid());

CREATE POLICY "Riders can insert own notifications"
  ON public.notifications FOR INSERT
  WITH CHECK (rider_id = auth.uid());

-- Enable real-time
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;

-- Seed demo data for creamoj@gmail.com
DO $$
DECLARE
  v_rider_id UUID;
BEGIN
  SELECT id INTO v_rider_id FROM auth.users WHERE email = 'creamoj@gmail.com';
  IF v_rider_id IS NULL THEN
    RAISE NOTICE 'creamoj@gmail.com not found, skipping seed';
    RETURN;
  END IF;

  INSERT INTO public.notifications (rider_id, type, title, body, data, is_read, created_at) VALUES
    -- Today
    (v_rider_id, 'new_order',            'Nuovo ordine disponibile',     'Pizzeria Da Mario → Via Roma 15 (1.2 km)',     '{"order_id": "demo-1", "distance_km": 1.2}', false, now() - interval '30 minutes'),
    (v_rider_id, 'order_delivered',       'Consegna completata',          'Hai consegnato a Via Roma 15 — €4.50',         '{"order_id": "demo-1", "amount": 4.50}',      true,  now() - interval '20 minutes'),
    (v_rider_id, 'new_earning',           'Nuovo guadagno',               'Mancia di €2.00 dal cliente di Via Roma 15',   '{"amount": 2.00}',                             false, now() - interval '19 minutes'),
    (v_rider_id, 'new_order',            'Nuovo ordine disponibile',     'Sushi Zen → Corso Italia 88 (2.5 km)',         '{"order_id": "demo-2", "distance_km": 2.5}', false, now() - interval '10 minutes'),
    -- Yesterday
    (v_rider_id, 'daily_target_reached', 'Obiettivo raggiunto!',         'Hai raggiunto il tuo obiettivo giornaliero di €50!', '{"target": 50}',                        true,  now() - interval '1 day'),
    (v_rider_id, 'achievement',          'Traguardo sbloccato',          'Hai completato 10 consegne — Livello 2!',       '{"level": 2, "orders": 10}',                  true,  now() - interval '1 day'),
    -- Last week
    (v_rider_id, 'system',              'Benvenuto su dloop!',          'Inizia a consegnare e guadagnare. Buon lavoro!', '{}',                                          true,  now() - interval '7 days');
END $$;
