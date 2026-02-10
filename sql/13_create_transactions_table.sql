-- ============================================
-- 13. Create transactions table
-- ============================================
-- Stores rider earnings: order_earning, commission, market_sale, bonus, tip

CREATE TABLE IF NOT EXISTS public.transactions (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rider_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  order_id    UUID,
  type        TEXT NOT NULL CHECK (type IN ('order_earning', 'commission', 'market_sale', 'bonus', 'tip')),
  description TEXT NOT NULL DEFAULT '',
  amount      NUMERIC(10,2) NOT NULL DEFAULT 0,
  status      TEXT NOT NULL DEFAULT 'completed' CHECK (status IN ('completed', 'pending', 'cancelled')),
  processed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX idx_transactions_rider_id ON public.transactions(rider_id);
CREATE INDEX idx_transactions_processed_at ON public.transactions(processed_at);
CREATE INDEX idx_transactions_rider_status ON public.transactions(rider_id, status);

-- RLS
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Riders can view own transactions"
  ON public.transactions FOR SELECT
  USING (rider_id = auth.uid());

CREATE POLICY "Riders can insert own transactions"
  ON public.transactions FOR INSERT
  WITH CHECK (rider_id = auth.uid());

-- Enable real-time
ALTER PUBLICATION supabase_realtime ADD TABLE public.transactions;

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

  INSERT INTO public.transactions (rider_id, type, description, amount, status, processed_at) VALUES
    -- Today's earnings
    (v_rider_id, 'order_earning', 'Consegna Pizzeria Da Mario → Via Roma 15',      4.50, 'completed', now() - interval '3 hours'),
    (v_rider_id, 'order_earning', 'Consegna Sushi Zen → Corso Italia 88',           6.20, 'completed', now() - interval '2 hours'),
    (v_rider_id, 'order_earning', 'Consegna Burger King → Via Dante 23',             3.80, 'completed', now() - interval '1 hour'),
    (v_rider_id, 'tip',           'Mancia cliente Via Roma 15',                      2.00, 'completed', now() - interval '3 hours'),
    (v_rider_id, 'bonus',         'Bonus rush hour 12:00-14:00',                     1.50, 'completed', now() - interval '2 hours'),
    -- Yesterday
    (v_rider_id, 'order_earning', 'Consegna McDonald''s → Piazza Duomo 1',          5.10, 'completed', now() - interval '1 day'),
    (v_rider_id, 'order_earning', 'Consegna Poke House → Via Brera 30',             4.80, 'completed', now() - interval '1 day'),
    (v_rider_id, 'commission',    'Commissione rete livello 1',                      3.00, 'completed', now() - interval '1 day'),
    -- Last week
    (v_rider_id, 'order_earning', 'Consegna La Piadineria → Corso Sempione 76',     3.60, 'completed', now() - interval '5 days'),
    (v_rider_id, 'market_sale',   'Vendita prodotto marketplace',                    8.50, 'completed', now() - interval '6 days'),
    (v_rider_id, 'order_earning', 'Consegna Farmacia Centrale → Via Montenapoleone', 7.20, 'completed', now() - interval '7 days');
END $$;
