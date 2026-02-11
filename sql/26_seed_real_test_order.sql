-- ============================================
-- 26. Seed one real pending order for E2E test
-- ============================================
-- Clears stale non-delivered orders, inserts 1 fresh pending order.
-- Run in Supabase SQL Editor before testing on device.

DO $$
DECLARE
  v_rider_id UUID;
BEGIN
  SELECT id INTO v_rider_id FROM auth.users WHERE email = 'creamoj@gmail.com';
  IF v_rider_id IS NULL THEN
    RAISE EXCEPTION 'creamoj@gmail.com not found in auth.users.';
  END IF;

  -- Clear stale non-delivered orders
  DELETE FROM public.orders
  WHERE rider_id = v_rider_id
    AND status IN ('pending', 'accepted', 'pickedUp');

  -- 1 PENDING order — ready for accept → pickup → deliver test
  INSERT INTO public.orders (
    rider_id, restaurant_name, restaurant_address, customer_name, customer_address,
    distance_km, distance_tier, base_earning, bonus_earning, tip_amount,
    rush_multiplier, hold_cost, hold_minutes, min_guarantee, total_earning,
    status, created_at
  ) VALUES (
    v_rider_id,
    'Trattoria Napoli Centro', 'Via Tribunali 32',
    'Marco Esposito', 'Via Chiaia 120',
    2.1, 'media', 5.25, 0.50, 0.00,
    1.0, 0.00, 0, 3.00, 5.75,
    'pending', now() - interval '1 minute'
  );

  RAISE NOTICE 'Seeded 1 pending order for rider %', v_rider_id;
END $$;
