-- ============================================
-- 14. Seed fresh active orders for testing
-- ============================================
-- Clears stale orders and inserts fresh pending/accepted/picked_up
-- orders for creamoj@gmail.com so the real-time stream has data.
--
-- Run in Supabase SQL Editor after 13_create_transactions_table.sql

DO $$
DECLARE
  v_rider_id UUID;
  v_zone_id  UUID;
BEGIN
  SELECT id INTO v_rider_id FROM auth.users WHERE email = 'creamoj@gmail.com';
  IF v_rider_id IS NULL THEN
    RAISE EXCEPTION 'creamoj@gmail.com not found in auth.users. Sign up first.';
  END IF;

  -- Get first zone (if zones table exists)
  BEGIN
    SELECT id INTO v_zone_id FROM public.zones LIMIT 1;
  EXCEPTION WHEN OTHERS THEN
    v_zone_id := NULL;
  END;

  -- Clear old non-completed orders for this rider (keep completed history)
  DELETE FROM public.orders
  WHERE rider_id = v_rider_id
    AND status IN ('pending', 'accepted', 'picked_up');

  -- === 2 PENDING orders (rider can accept) ===

  INSERT INTO public.orders (
    rider_id, zone_id, order_number, platform, status,
    pickup_address, delivery_address,
    distance_km, base_earnings, bonus_earnings, tip_amount, total_earnings,
    estimated_duration_minutes, customer_name, customer_notes,
    rush_hour, created_at
  ) VALUES (
    v_rider_id, v_zone_id, 'DL-2026-5001', 'deliveroo', 'pending',
    'Pizzeria Da Mario, Via Spaccanapoli 15',
    'Via Roma 15, Milano',
    1.8, 4.50, 0.00, 0.00, 4.50,
    12, 'Luigi Esposito', NULL,
    false, now() - interval '2 minutes'
  );

  INSERT INTO public.orders (
    rider_id, zone_id, order_number, platform, status,
    pickup_address, delivery_address,
    distance_km, base_earnings, bonus_earnings, tip_amount, total_earnings,
    estimated_duration_minutes, customer_name, customer_notes,
    rush_hour, created_at
  ) VALUES (
    v_rider_id, v_zone_id, 'JE-2026-5002', 'justeat', 'pending',
    'Sushi Zen, Via Toledo 120',
    'Corso Buenos Aires 88, Milano',
    2.5, 6.25, 0.00, 0.00, 6.25,
    16, 'Anna Ferraro', 'Citofono rotto, chiamare',
    false, now() - interval '1 minute'
  );

  -- === 1 ACCEPTED order (rider en route to pickup) ===

  INSERT INTO public.orders (
    rider_id, zone_id, order_number, platform, status,
    pickup_address, delivery_address,
    distance_km, base_earnings, bonus_earnings, tip_amount, total_earnings,
    estimated_duration_minutes, customer_name, customer_notes,
    rush_hour, created_at, accepted_at
  ) VALUES (
    v_rider_id, v_zone_id, 'GL-2026-5003', 'glovo', 'accepted',
    'Burger King, Piazza Duomo 3',
    'Via Dante 23, Milano',
    2.0, 5.00, 1.00, 0.00, 6.00,
    14, 'Paolo Russo', NULL,
    true, now() - interval '8 minutes', now() - interval '5 minutes'
  );

  -- === 1 PICKED_UP order (rider delivering) ===

  INSERT INTO public.orders (
    rider_id, zone_id, order_number, platform, status,
    pickup_address, delivery_address,
    distance_km, base_earnings, bonus_earnings, tip_amount, total_earnings,
    estimated_duration_minutes, customer_name, customer_notes,
    rush_hour, created_at, accepted_at, picked_up_at
  ) VALUES (
    v_rider_id, v_zone_id, 'UE-2026-5004', 'uber_eats', 'picked_up',
    'Poke House, Corso Buenos Aires 88',
    'Via Montenapoleone 8, Milano',
    1.5, 3.75, 0.50, 0.00, 4.25,
    10, 'Giulia Romano', 'Piano 3, scala B',
    false, now() - interval '15 minutes', now() - interval '12 minutes', now() - interval '5 minutes'
  );

  -- === 2 COMPLETED orders (today's history) ===

  INSERT INTO public.orders (
    rider_id, zone_id, order_number, platform, status,
    pickup_address, delivery_address,
    distance_km, base_earnings, bonus_earnings, tip_amount, total_earnings,
    estimated_duration_minutes, customer_name,
    rush_hour, created_at, accepted_at, picked_up_at, delivered_at
  ) VALUES (
    v_rider_id, v_zone_id, 'DL-2026-5005', 'deliveroo', 'completed',
    'La Piadineria, Via Paolo Sarpi 44',
    'Via Brera 22, Milano',
    1.2, 3.00, 0.00, 0.50, 3.50,
    8, 'Stefano Colombo',
    false, now() - interval '3 hours', now() - interval '2 hours 55 min', now() - interval '2 hours 45 min', now() - interval '2 hours 30 min'
  );

  INSERT INTO public.orders (
    rider_id, zone_id, order_number, platform, status,
    pickup_address, delivery_address,
    distance_km, base_earnings, bonus_earnings, tip_amount, total_earnings,
    estimated_duration_minutes, customer_name,
    rush_hour, created_at, accepted_at, picked_up_at, delivered_at
  ) VALUES (
    v_rider_id, v_zone_id, 'GL-2026-5006', 'glovo', 'completed',
    'Rossopomodoro, Piazza Duomo 1',
    'Corso Italia 42, Milano',
    3.1, 7.75, 2.00, 1.00, 10.75,
    20, 'Maria Bianchi',
    true, now() - interval '1 hour 30 min', now() - interval '1 hour 25 min', now() - interval '1 hour 15 min', now() - interval '1 hour'
  );

  RAISE NOTICE 'Seeded 6 fresh orders for rider %', v_rider_id;
END $$;
