-- ============================================
-- 14. Seed fresh active orders for testing
-- ============================================
-- Clears stale orders and inserts fresh pending/accepted/pickedUp/delivered
-- orders for creamoj@gmail.com so the real-time stream has data.
--
-- Run in Supabase SQL Editor after 13_create_transactions_table.sql
--
-- Orders table columns:
--   id, rider_id, restaurant_name, restaurant_address, customer_name,
--   customer_address, distance_km, distance_tier, base_earning, bonus_earning,
--   tip_amount, rush_multiplier, hold_cost, hold_minutes, min_guarantee,
--   total_earning, status, created_at, accepted_at, picked_up_at, delivered_at

DO $$
DECLARE
  v_rider_id UUID;
BEGIN
  SELECT id INTO v_rider_id FROM auth.users WHERE email = 'creamoj@gmail.com';
  IF v_rider_id IS NULL THEN
    RAISE EXCEPTION 'creamoj@gmail.com not found in auth.users. Sign up first.';
  END IF;

  -- Clear old non-completed orders for this rider (keep delivered history)
  DELETE FROM public.orders
  WHERE rider_id = v_rider_id
    AND status IN ('pending', 'accepted', 'pickedUp');

  -- === 2 PENDING orders (rider can accept) ===

  INSERT INTO public.orders (
    rider_id, restaurant_name, restaurant_address, customer_name, customer_address,
    distance_km, distance_tier, base_earning, bonus_earning, tip_amount,
    rush_multiplier, hold_cost, hold_minutes, min_guarantee, total_earning,
    status, created_at
  ) VALUES (
    v_rider_id, 'Pizzeria Da Mario', 'Via Spaccanapoli 15', 'Luigi Esposito', 'Via Roma 15',
    1.8, 'corta', 4.50, 0.00, 0.00,
    1.0, 0.00, 0, 3.00, 4.50,
    'pending', now() - interval '2 minutes'
  );

  INSERT INTO public.orders (
    rider_id, restaurant_name, restaurant_address, customer_name, customer_address,
    distance_km, distance_tier, base_earning, bonus_earning, tip_amount,
    rush_multiplier, hold_cost, hold_minutes, min_guarantee, total_earning,
    status, created_at
  ) VALUES (
    v_rider_id, 'Sushi Zen', 'Via Toledo 120', 'Anna Ferraro', 'Corso Buenos Aires 88',
    2.5, 'media', 6.25, 0.00, 0.00,
    1.0, 0.00, 0, 3.00, 6.25,
    'pending', now() - interval '1 minute'
  );

  -- === 1 ACCEPTED order (rider en route to pickup) ===

  INSERT INTO public.orders (
    rider_id, restaurant_name, restaurant_address, customer_name, customer_address,
    distance_km, distance_tier, base_earning, bonus_earning, tip_amount,
    rush_multiplier, hold_cost, hold_minutes, min_guarantee, total_earning,
    status, created_at, accepted_at
  ) VALUES (
    v_rider_id, 'Burger King', 'Piazza Duomo 3', 'Paolo Russo', 'Via Dante 23',
    2.0, 'corta', 5.00, 1.00, 0.00,
    2.0, 0.00, 0, 3.00, 11.00,
    'accepted', now() - interval '8 minutes', now() - interval '5 minutes'
  );

  -- === 1 PICKED_UP order (rider delivering) ===

  INSERT INTO public.orders (
    rider_id, restaurant_name, restaurant_address, customer_name, customer_address,
    distance_km, distance_tier, base_earning, bonus_earning, tip_amount,
    rush_multiplier, hold_cost, hold_minutes, min_guarantee, total_earning,
    status, created_at, accepted_at, picked_up_at
  ) VALUES (
    v_rider_id, 'Poke House', 'Corso Buenos Aires 88', 'Giulia Romano', 'Via Montenapoleone 8',
    1.5, 'corta', 3.75, 0.50, 0.00,
    1.0, 0.00, 0, 3.00, 4.25,
    'pickedUp', now() - interval '15 minutes', now() - interval '12 minutes', now() - interval '5 minutes'
  );

  -- === 2 DELIVERED orders (today's history) ===

  INSERT INTO public.orders (
    rider_id, restaurant_name, restaurant_address, customer_name, customer_address,
    distance_km, distance_tier, base_earning, bonus_earning, tip_amount,
    rush_multiplier, hold_cost, hold_minutes, min_guarantee, total_earning,
    status, created_at, accepted_at, picked_up_at, delivered_at
  ) VALUES (
    v_rider_id, 'La Piadineria', 'Via Paolo Sarpi 44', 'Stefano Colombo', 'Via Brera 22',
    1.2, 'corta', 3.00, 0.00, 0.50,
    1.0, 0.00, 0, 3.00, 3.50,
    'delivered', now() - interval '3 hours', now() - interval '2 hours 55 min', now() - interval '2 hours 45 min', now() - interval '2 hours 30 min'
  );

  INSERT INTO public.orders (
    rider_id, restaurant_name, restaurant_address, customer_name, customer_address,
    distance_km, distance_tier, base_earning, bonus_earning, tip_amount,
    rush_multiplier, hold_cost, hold_minutes, min_guarantee, total_earning,
    status, created_at, accepted_at, picked_up_at, delivered_at
  ) VALUES (
    v_rider_id, 'Rossopomodoro', 'Piazza Duomo 1', 'Maria Bianchi', 'Corso Italia 42',
    3.1, 'media', 7.75, 2.00, 1.00,
    2.0, 0.00, 0, 3.00, 18.50,
    'delivered', now() - interval '1 hour 30 min', now() - interval '1 hour 25 min', now() - interval '1 hour 15 min', now() - interval '1 hour'
  );

  RAISE NOTICE 'Seeded 6 orders for rider %', v_rider_id;
END $$;
