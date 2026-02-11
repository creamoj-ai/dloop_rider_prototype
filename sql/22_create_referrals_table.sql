-- 22. Referrals table for invite system
-- Tracks who invited whom and bonus status

CREATE TABLE IF NOT EXISTS referrals (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  referrer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  referred_name TEXT NOT NULL,
  referred_email TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'expired')),
  bonus_amount NUMERIC(10,2) NOT NULL DEFAULT 10.00,
  created_at TIMESTAMPTZ DEFAULT now(),
  activated_at TIMESTAMPTZ
);

-- RLS
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Riders can view own referrals"
  ON referrals FOR SELECT
  USING (referrer_id = auth.uid());

CREATE POLICY "Riders can insert own referrals"
  ON referrals FOR INSERT
  WITH CHECK (referrer_id = auth.uid());

-- Indexes
CREATE INDEX idx_referrals_referrer ON referrals(referrer_id);

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE referrals;

-- Seed demo data for creamoj@gmail.com
DO $$
DECLARE
  rider_uuid UUID;
BEGIN
  SELECT id INTO rider_uuid FROM auth.users WHERE email = 'creamoj@gmail.com' LIMIT 1;
  IF rider_uuid IS NOT NULL THEN
    INSERT INTO referrals (referrer_id, referred_name, referred_email, status, bonus_amount, activated_at) VALUES
      (rider_uuid, 'Luca Rossi', 'luca.r@email.com', 'active', 10.00, now() - interval '12 days'),
      (rider_uuid, 'Anna Marchetti', 'anna.m@email.com', 'active', 10.00, now() - interval '5 days'),
      (rider_uuid, 'Paolo Greco', 'paolo.g@email.com', 'pending', 10.00, NULL);
  END IF;
END $$;
