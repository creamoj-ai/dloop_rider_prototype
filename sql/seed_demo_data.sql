-- ============================================================================
-- DLoop Rider Prototype - Seed Demo Data for MVP
-- Rider: Marco Rossi (creamoj@gmail.com)
-- ============================================================================
-- IMPORTANT: The rider's UUID must match the Supabase Auth user UUID.
-- Run this AFTER the user has signed up via the app.
--
-- To find the auth user UUID:
--   SELECT id FROM auth.users WHERE email = 'creamoj@gmail.com';
--
-- Then replace the placeholder below OR run the dynamic version.
-- ============================================================================

-- ============================================================================
-- STEP 0: Get the auth user ID dynamically
-- ============================================================================
DO $$
DECLARE
    v_rider_id UUID;
    v_zone_centro UUID;
    v_zone_vomero UUID;
    v_zone_chiaia UUID;
    v_zone_stazione UUID;
BEGIN
    -- Get the auth user UUID for creamoj@gmail.com
    SELECT id INTO v_rider_id FROM auth.users WHERE email = 'creamoj@gmail.com';

    IF v_rider_id IS NULL THEN
        RAISE EXCEPTION 'User creamoj@gmail.com not found in auth.users. Please sign up first.';
    END IF;

    RAISE NOTICE 'Found user UUID: %', v_rider_id;

    -- ========================================================================
    -- STEP 1: RIDER PROFILE
    -- ========================================================================
    INSERT INTO riders (
        id, email, phone, full_name, avatar_url,
        current_mode, vehicle_type, vehicle_plate, status,
        rating, total_deliveries, total_earnings,
        stats, is_online,
        current_location_lat, current_location_lng
    ) VALUES (
        v_rider_id,
        'creamoj@gmail.com',
        '+393331234567',
        'Marco Rossi',
        'https://i.pravatar.cc/150?img=12',
        'earn',
        'ebike',
        'NA-1234',
        'active',
        4.87,
        1247,
        18450.00,
        '{"completed_orders": 1247, "active_dealers": 4, "active_clients": 5, "active_boxes": 2, "total_market_sales": 180}'::jsonb,
        true,
        40.8518,
        14.2681
    )
    ON CONFLICT (id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        avatar_url = EXCLUDED.avatar_url,
        current_mode = EXCLUDED.current_mode,
        vehicle_type = EXCLUDED.vehicle_type,
        rating = EXCLUDED.rating,
        total_deliveries = EXCLUDED.total_deliveries,
        total_earnings = EXCLUDED.total_earnings,
        stats = EXCLUDED.stats,
        is_online = EXCLUDED.is_online,
        current_location_lat = EXCLUDED.current_location_lat,
        current_location_lng = EXCLUDED.current_location_lng,
        updated_at = NOW();

    -- ========================================================================
    -- STEP 2: RIDER STATS (Gamification)
    -- ========================================================================
    INSERT INTO rider_stats (
        rider_id,
        lifetime_orders, lifetime_earnings, lifetime_distance_km, lifetime_hours_online,
        current_daily_streak, longest_daily_streak,
        avg_rating, total_ratings_count,
        five_star_count, four_star_count, three_star_count, two_star_count, one_star_count,
        avg_delivery_time_minutes, on_time_delivery_rate,
        earn_mode_hours, grow_mode_hours, market_mode_hours,
        best_day_earnings, best_day_date, best_week_earnings, best_week_date,
        achievements_unlocked, total_achievement_points,
        current_level, current_xp, xp_to_next_level
    ) VALUES (
        v_rider_id,
        1247, 18450.00, 8420.3, 1850.5,
        12, 28,
        4.87, 1180,
        890, 220, 50, 15, 5,
        18.5, 94.20,
        1200.0, 420.0, 230.5,
        285.00, '2025-12-20', 1420.00, '2025-12-16',
        8, 1650,
        12, 2450, 3000
    )
    ON CONFLICT (rider_id) DO UPDATE SET
        lifetime_orders = EXCLUDED.lifetime_orders,
        lifetime_earnings = EXCLUDED.lifetime_earnings,
        lifetime_distance_km = EXCLUDED.lifetime_distance_km,
        current_daily_streak = EXCLUDED.current_daily_streak,
        avg_rating = EXCLUDED.avg_rating,
        achievements_unlocked = EXCLUDED.achievements_unlocked,
        current_level = EXCLUDED.current_level,
        current_xp = EXCLUDED.current_xp,
        xp_to_next_level = EXCLUDED.xp_to_next_level,
        updated_at = NOW();

    -- ========================================================================
    -- STEP 3: ZONES (Napoli) - get or create
    -- ========================================================================
    -- Centro Storico
    INSERT INTO zones (name, city, center_lat, center_lng, demand_score, is_active)
    VALUES ('Centro Storico', 'Napoli', 40.8518, 14.2681, 92.00, true)
    ON CONFLICT DO NOTHING;
    SELECT id INTO v_zone_centro FROM zones WHERE name = 'Centro Storico' AND city = 'Napoli' LIMIT 1;

    -- Vomero
    INSERT INTO zones (name, city, center_lat, center_lng, demand_score, is_active)
    VALUES ('Vomero', 'Napoli', 40.8325, 14.2250, 88.00, true)
    ON CONFLICT DO NOTHING;
    SELECT id INTO v_zone_vomero FROM zones WHERE name = 'Vomero' AND city = 'Napoli' LIMIT 1;

    -- Chiaia
    INSERT INTO zones (name, city, center_lat, center_lng, demand_score, is_active)
    VALUES ('Chiaia', 'Napoli', 40.8375, 14.2450, 85.00, true)
    ON CONFLICT DO NOTHING;
    SELECT id INTO v_zone_chiaia FROM zones WHERE name = 'Chiaia' AND city = 'Napoli' LIMIT 1;

    -- Stazione Centrale
    INSERT INTO zones (name, city, center_lat, center_lng, demand_score, is_active)
    VALUES ('Stazione Centrale', 'Napoli', 40.8575, 14.2750, 78.00, true)
    ON CONFLICT DO NOTHING;
    SELECT id INTO v_zone_stazione FROM zones WHERE name = 'Stazione Centrale' AND city = 'Napoli' LIMIT 1;

    -- Update rider's zone
    UPDATE riders SET current_zone_id = v_zone_centro WHERE id = v_rider_id;

    -- ========================================================================
    -- STEP 4: ORDERS (8 today, mix of statuses)
    -- ========================================================================
    -- Order 1: Completed, morning
    INSERT INTO orders (rider_id, zone_id, order_number, platform, status,
        pickup_lat, pickup_lng, pickup_address,
        delivery_lat, delivery_lng, delivery_address,
        distance_km, base_earnings, bonus_earnings, tip_amount, total_earnings,
        estimated_duration_minutes, customer_name,
        accepted_at, picked_up_at, delivered_at, rush_hour)
    VALUES (
        v_rider_id, v_zone_centro, 'JE-2026-4816', 'justeat', 'completed',
        40.8505, 14.2625, 'Pizzeria Da Michele, Via Cesare Sersale 1',
        40.8530, 14.2650, 'Via Tribunali 32',
        1.8, 12.60, 2.00, 1.50, 16.10,
        15, 'Luigi Esposito',
        NOW() - INTERVAL '7 hours', NOW() - INTERVAL '6 hours 45 min', NOW() - INTERVAL '6 hours 30 min', false
    ) ON CONFLICT DO NOTHING;

    -- Order 2: Completed, lunch rush
    INSERT INTO orders (rider_id, zone_id, order_number, platform, status,
        pickup_lat, pickup_lng, pickup_address,
        delivery_lat, delivery_lng, delivery_address,
        distance_km, base_earnings, bonus_earnings, tip_amount, total_earnings,
        estimated_duration_minutes, customer_name,
        accepted_at, picked_up_at, delivered_at, rush_hour)
    VALUES (
        v_rider_id, v_zone_centro, 'DL-2026-4817', 'deliveroo', 'completed',
        40.8540, 14.2550, 'Trattoria Nennella, Via Foria 31',
        40.8560, 14.2580, 'Corso Umberto I, 78',
        2.3, 16.10, 3.50, 2.00, 21.60,
        18, 'Anna Ferraro',
        NOW() - INTERVAL '5 hours', NOW() - INTERVAL '4 hours 50 min', NOW() - INTERVAL '4 hours 35 min', true
    ) ON CONFLICT DO NOTHING;

    -- Order 3: Completed, afternoon
    INSERT INTO orders (rider_id, zone_id, order_number, platform, status,
        pickup_lat, pickup_lng, pickup_address,
        delivery_lat, delivery_lng, delivery_address,
        distance_km, base_earnings, bonus_earnings, tip_amount, total_earnings,
        estimated_duration_minutes, customer_name,
        accepted_at, picked_up_at, delivered_at, rush_hour)
    VALUES (
        v_rider_id, v_zone_vomero, 'UE-2026-4818', 'uber_eats', 'completed',
        40.8320, 14.2240, 'Friggitoria Vomero, Via Scarlatti 8',
        40.8340, 14.2260, 'Via Cilea 44',
        1.5, 10.50, 0.00, 0.50, 11.00,
        12, 'Paolo Russo',
        NOW() - INTERVAL '4 hours', NOW() - INTERVAL '3 hours 50 min', NOW() - INTERVAL '3 hours 40 min', false
    ) ON CONFLICT DO NOTHING;

    -- Order 4: Completed
    INSERT INTO orders (rider_id, zone_id, order_number, platform, status,
        pickup_lat, pickup_lng, pickup_address,
        delivery_lat, delivery_lng, delivery_address,
        distance_km, base_earnings, bonus_earnings, tip_amount, total_earnings,
        estimated_duration_minutes, customer_name,
        accepted_at, picked_up_at, delivered_at, rush_hour)
    VALUES (
        v_rider_id, v_zone_chiaia, 'GL-2026-4819', 'glovo', 'completed',
        40.8375, 14.2450, 'Pasticceria Scaturchio, P.za San Domenico',
        40.8390, 14.2470, 'Via Chiaia 65',
        3.1, 21.70, 4.00, 3.00, 28.70,
        22, 'Giulia Romano',
        NOW() - INTERVAL '3 hours', NOW() - INTERVAL '2 hours 50 min', NOW() - INTERVAL '2 hours 35 min', false
    ) ON CONFLICT DO NOTHING;

    -- Order 5: Completed
    INSERT INTO orders (rider_id, zone_id, order_number, platform, status,
        pickup_lat, pickup_lng, pickup_address,
        delivery_lat, delivery_lng, delivery_address,
        distance_km, base_earnings, bonus_earnings, tip_amount, total_earnings,
        estimated_duration_minutes, customer_name,
        accepted_at, picked_up_at, delivered_at, rush_hour)
    VALUES (
        v_rider_id, v_zone_centro, 'JE-2026-4820', 'justeat', 'completed',
        40.8510, 14.2670, 'Sushi Zen, Via Toledo 120',
        40.8530, 14.2690, 'Via Santa Chiara 12',
        2.0, 14.00, 1.50, 1.00, 16.50,
        14, 'Stefano Colombo',
        NOW() - INTERVAL '2 hours', NOW() - INTERVAL '1 hour 50 min', NOW() - INTERVAL '1 hour 40 min', false
    ) ON CONFLICT DO NOTHING;

    -- Order 6: Completed
    INSERT INTO orders (rider_id, zone_id, order_number, platform, status,
        pickup_lat, pickup_lng, pickup_address,
        delivery_lat, delivery_lng, delivery_address,
        distance_km, base_earnings, bonus_earnings, tip_amount, total_earnings,
        estimated_duration_minutes, customer_name,
        accepted_at, picked_up_at, delivered_at, rush_hour)
    VALUES (
        v_rider_id, v_zone_stazione, 'DL-2026-4821', 'deliveroo', 'completed',
        40.8575, 14.2750, 'KFC Stazione, P.za Garibaldi',
        40.8590, 14.2770, 'Corso Novara 18',
        1.2, 8.40, 0.00, 0.00, 8.40,
        10, 'Francesco Greco',
        NOW() - INTERVAL '1 hour 20 min', NOW() - INTERVAL '1 hour 10 min', NOW() - INTERVAL '1 hour', false
    ) ON CONFLICT DO NOTHING;

    -- Order 7: Completed (most recent)
    INSERT INTO orders (rider_id, zone_id, order_number, platform, status,
        pickup_lat, pickup_lng, pickup_address,
        delivery_lat, delivery_lng, delivery_address,
        distance_km, base_earnings, bonus_earnings, tip_amount, total_earnings,
        estimated_duration_minutes, customer_name,
        accepted_at, picked_up_at, delivered_at, rush_hour)
    VALUES (
        v_rider_id, v_zone_centro, 'UE-2026-4822', 'uber_eats', 'completed',
        40.8518, 14.2681, 'Rossopomodoro, Via Partenope 1',
        40.8530, 14.2700, 'Lungomare Caracciolo 22',
        2.5, 17.50, 2.50, 2.00, 22.00,
        16, 'Maria Bianchi',
        NOW() - INTERVAL '45 min', NOW() - INTERVAL '35 min', NOW() - INTERVAL '22 min', false
    ) ON CONFLICT DO NOTHING;

    -- Order 8: In progress (picked up)
    INSERT INTO orders (rider_id, zone_id, order_number, platform, status,
        pickup_lat, pickup_lng, pickup_address,
        delivery_lat, delivery_lng, delivery_address,
        distance_km, base_earnings, bonus_earnings, tip_amount, total_earnings,
        estimated_duration_minutes, customer_name, customer_notes,
        accepted_at, picked_up_at, rush_hour)
    VALUES (
        v_rider_id, v_zone_centro, 'GL-2026-4823', 'glovo', 'picked_up',
        40.8505, 14.2625, 'Pizzeria Da Mario, Via Spaccanapoli 15',
        40.8540, 14.2660, 'Via Duomo 88',
        1.8, 12.60, 1.00, 0.00, 13.60,
        12, 'Roberto Napoli', 'Citofono rotto, chiamare al 333-1234567',
        NOW() - INTERVAL '10 min', NOW() - INTERVAL '5 min', false
    ) ON CONFLICT DO NOTHING;

    -- ========================================================================
    -- STEP 5: DEALERS (4 dealers)
    -- ========================================================================
    INSERT INTO dealers (rider_id, business_name, category, contact_name, phone, address, lat, lng, zone_id, relationship_status, priority_level, total_orders, total_revenue, commission_rate)
    VALUES
        (v_rider_id, 'Pizzeria Da Michele', 'restaurant', 'Antonio Condurro', '+393331111111', 'Via Cesare Sersale 1, Napoli', 40.8505, 14.2625, v_zone_centro, 'active', 1, 342, 4200.00, 8.5),
        (v_rider_id, 'Trattoria Nennella', 'restaurant', 'Giovanni Nennella', '+393332222222', 'Via Foria 31, Napoli', 40.8540, 14.2550, v_zone_centro, 'active', 2, 187, 2800.00, 7.0),
        (v_rider_id, 'Farmacia Centrale', 'pharmacy', 'Dr. Lucia Verde', '+393333333333', 'Via Toledo 88, Napoli', 40.8400, 14.2500, v_zone_chiaia, 'active', 3, 95, 1400.00, 5.0),
        (v_rider_id, 'Pasticceria Scaturchio', 'bakery', 'Maria Scaturchio', '+393334444444', 'P.za San Domenico Maggiore 19, Napoli', 40.8480, 14.2530, v_zone_centro, 'pending', 4, 0, 0.00, 6.0)
    ON CONFLICT DO NOTHING;

    -- ========================================================================
    -- STEP 6: CLIENTS (5 clients)
    -- ========================================================================
    INSERT INTO clients (rider_id, full_name, phone, address, lat, lng, zone_id, loyalty_tier, loyalty_points, total_orders, total_spent, status)
    VALUES
        (v_rider_id, 'Luigi Esposito', '+393335555555', 'Via Tribunali 32, Napoli', 40.8530, 14.2650, v_zone_centro, 'gold', 1250, 48, 720.00, 'active'),
        (v_rider_id, 'Anna Ferraro', '+393336666666', 'Corso Umberto I 78, Napoli', 40.8560, 14.2580, v_zone_centro, 'silver', 640, 32, 480.00, 'active'),
        (v_rider_id, 'Paolo Russo', '+393337777777', 'Via Cilea 44, Napoli', 40.8340, 14.2260, v_zone_vomero, 'bronze', 315, 21, 315.00, 'active'),
        (v_rider_id, 'Giulia Romano', '+393338888888', 'Via Chiaia 65, Napoli', 40.8390, 14.2470, v_zone_chiaia, 'bronze', 45, 3, 45.00, 'active'),
        (v_rider_id, 'Stefano Colombo', '+393339999999', 'Via Santa Chiara 12, Napoli', 40.8530, 14.2690, v_zone_centro, 'silver', 225, 15, 225.00, 'active')
    ON CONFLICT DO NOTHING;

    -- ========================================================================
    -- STEP 7: BOXES (2 active subscriptions)
    -- ========================================================================
    INSERT INTO boxes (rider_id, client_id, box_name, description, contents, price, frequency, status, total_deliveries, total_revenue)
    VALUES
        (v_rider_id,
         (SELECT id FROM clients WHERE full_name = 'Luigi Esposito' AND rider_id = v_rider_id LIMIT 1),
         'Box Pranzo Premium', 'Box pranzo settimanale con prodotti locali',
         '[{"name": "Pizza Margherita", "qty": 2}, {"name": "Insalata Caprese", "qty": 1}, {"name": "Tiramisu", "qty": 1}]'::jsonb,
         25.00, 'weekly', 'active', 18, 450.00),
        (v_rider_id,
         (SELECT id FROM clients WHERE full_name = 'Anna Ferraro' AND rider_id = v_rider_id LIMIT 1),
         'Box Colazione', 'Cornetti e caffe ogni mattina',
         '[{"name": "Cornetto", "qty": 3}, {"name": "Caffe macinato 250g", "qty": 1}]'::jsonb,
         12.00, 'daily', 'active', 45, 540.00)
    ON CONFLICT DO NOTHING;

    -- ========================================================================
    -- STEP 8: MARKET PRODUCTS (6 products)
    -- ========================================================================
    INSERT INTO market_products (rider_id, name, description, category, price, cost_price, stock_quantity, is_active, views_count, orders_count, total_revenue)
    VALUES
        (v_rider_id, 'Power Bank 10000mAh', 'Caricatore portatile universale', 'Tech', 24.99, 12.00, 15, true, 342, 28, 699.72),
        (v_rider_id, 'Cavo USB-C 2m', 'Cavo ricarica rapida tipo C', 'Tech', 9.99, 3.50, 50, true, 518, 67, 669.33),
        (v_rider_id, 'Supporto Telefono Bici', 'Supporto universale per manubrio', 'Accessori', 14.99, 6.00, 8, true, 210, 15, 224.85),
        (v_rider_id, 'Guanti Touch Screen', 'Guanti invernali con touch capacitivo', 'Abbigliamento', 12.99, 4.50, 20, true, 189, 22, 285.78),
        (v_rider_id, 'Luce LED Bici Set', 'Set luci anteriore + posteriore ricaricabile', 'Accessori', 19.99, 8.00, 12, true, 276, 31, 619.69),
        (v_rider_id, 'Borraccia Termica 750ml', 'Borraccia in acciaio inox, mantiene temp 12h', 'Accessori', 16.99, 7.00, 25, true, 154, 12, 203.88)
    ON CONFLICT DO NOTHING;

    -- ========================================================================
    -- STEP 9: TRANSACTIONS (recent activity)
    -- ========================================================================
    INSERT INTO transactions (rider_id, type, amount, status, description, processed_at)
    VALUES
        (v_rider_id, 'order_earning', 22.00, 'completed', 'Consegna #4822 - Rossopomodoro', NOW() - INTERVAL '22 min'),
        (v_rider_id, 'order_earning', 8.40, 'completed', 'Consegna #4821 - KFC Stazione', NOW() - INTERVAL '1 hour'),
        (v_rider_id, 'commission', 3.40, 'completed', 'Commissione rete - Luigi Esposito', NOW() - INTERVAL '2 hours'),
        (v_rider_id, 'order_earning', 16.50, 'completed', 'Consegna #4820 - Sushi Zen', NOW() - INTERVAL '1 hour 40 min'),
        (v_rider_id, 'market_sale', 8.00, 'completed', 'Vendita - Power Bank 10000mAh', NOW() - INTERVAL '3 hours'),
        (v_rider_id, 'order_earning', 28.70, 'completed', 'Consegna #4819 - Pasticceria Scaturchio', NOW() - INTERVAL '2 hours 35 min'),
        (v_rider_id, 'order_earning', 11.00, 'completed', 'Consegna #4818 - Friggitoria Vomero', NOW() - INTERVAL '3 hours 40 min'),
        (v_rider_id, 'bonus', 25.00, 'pending', 'Bonus referral - Anna Ferraro', NOW() - INTERVAL '4 hours'),
        (v_rider_id, 'order_earning', 21.60, 'completed', 'Consegna #4817 - Trattoria Nennella', NOW() - INTERVAL '4 hours 35 min'),
        (v_rider_id, 'market_sale', 4.20, 'completed', 'Vendita - Cavo USB-C', NOW() - INTERVAL '5 hours'),
        (v_rider_id, 'order_earning', 16.10, 'completed', 'Consegna #4816 - Pizzeria Da Michele', NOW() - INTERVAL '6 hours 30 min'),
        (v_rider_id, 'tip', 2.00, 'completed', 'Mancia - Maria Bianchi', NOW() - INTERVAL '22 min')
    ON CONFLICT DO NOTHING;

    -- ========================================================================
    -- STEP 10: EARNINGS DAILY (today)
    -- ========================================================================
    INSERT INTO earnings_daily (
        rider_id, date,
        earn_orders_count, earn_base_amount, earn_bonus_amount, earn_tips_amount, earn_total,
        grow_boxes_delivered, grow_revenue, grow_commission, grow_total,
        market_orders_count, market_revenue, market_costs, market_profit,
        total_earnings, total_expenses, net_earnings,
        hours_online, hourly_rate, distance_km
    ) VALUES (
        v_rider_id, CURRENT_DATE,
        8, 113.30, 14.50, 10.00, 137.80,
        2, 37.00, 2.80, 2.80,
        2, 12.20, 5.50, 6.70,
        147.30, 5.50, 141.80,
        6.5, 21.82, 16.2
    )
    ON CONFLICT (rider_id, date) DO UPDATE SET
        earn_orders_count = EXCLUDED.earn_orders_count,
        earn_base_amount = EXCLUDED.earn_base_amount,
        earn_bonus_amount = EXCLUDED.earn_bonus_amount,
        earn_tips_amount = EXCLUDED.earn_tips_amount,
        earn_total = EXCLUDED.earn_total,
        grow_total = EXCLUDED.grow_total,
        market_orders_count = EXCLUDED.market_orders_count,
        market_profit = EXCLUDED.market_profit,
        total_earnings = EXCLUDED.total_earnings,
        net_earnings = EXCLUDED.net_earnings,
        hours_online = EXCLUDED.hours_online,
        hourly_rate = EXCLUDED.hourly_rate,
        distance_km = EXCLUDED.distance_km,
        updated_at = NOW();

    -- ========================================================================
    -- STEP 11: EARNINGS MONTHLY (current month)
    -- ========================================================================
    INSERT INTO earnings_monthly (
        rider_id, year, month,
        total_orders, total_earnings, total_expenses, net_earnings,
        earn_total, grow_total, market_total,
        hours_online, avg_hourly_rate, total_distance_km
    ) VALUES (
        v_rider_id, EXTRACT(YEAR FROM CURRENT_DATE)::int, EXTRACT(MONTH FROM CURRENT_DATE)::int,
        186, 2920.00, 120.00, 2800.00,
        2400.00, 340.00, 180.00,
        168.0, 16.67, 620.5
    )
    ON CONFLICT (rider_id, year, month) DO UPDATE SET
        total_orders = EXCLUDED.total_orders,
        total_earnings = EXCLUDED.total_earnings,
        net_earnings = EXCLUDED.net_earnings,
        earn_total = EXCLUDED.earn_total,
        grow_total = EXCLUDED.grow_total,
        market_total = EXCLUDED.market_total,
        hours_online = EXCLUDED.hours_online,
        avg_hourly_rate = EXCLUDED.avg_hourly_rate,
        updated_at = NOW();

    -- ========================================================================
    -- STEP 12: ACTIVE SESSION
    -- ========================================================================
    -- Delete old active sessions first
    UPDATE sessions SET is_active = false, end_time = NOW()
    WHERE rider_id = v_rider_id AND is_active = true;

    INSERT INTO sessions (
        rider_id, start_time, is_active, start_zone_id, mode,
        starting_balance, session_earnings, orders_completed, distance_km, active_minutes
    ) VALUES (
        v_rider_id,
        NOW() - INTERVAL '6 hours 30 minutes',
        true,
        v_zone_centro,
        'earn',
        1705.70,
        141.80,
        8,
        16.2,
        390
    );

    -- ========================================================================
    -- STEP 13: ZONE METRICS LIVE
    -- ========================================================================
    INSERT INTO zone_metrics_live (zone_id, recorded_at, heatmap_score, demand_level, pending_orders_count, active_riders_count, avg_hourly_rate, peak_multiplier, is_rush_hour, next_peak_hour, weather_conditions)
    VALUES
        (v_zone_centro, NOW(), 95.00, 'very_high', 15, 12, 19.50, 1.3, true, 13, 'sunny'),
        (v_zone_vomero, NOW() + INTERVAL '1 second', 88.00, 'high', 10, 8, 17.80, 1.2, true, 20, 'sunny'),
        (v_zone_chiaia, NOW() + INTERVAL '2 seconds', 82.00, 'high', 8, 6, 16.20, 1.1, false, 20, 'sunny'),
        (v_zone_stazione, NOW() + INTERVAL '3 seconds', 70.00, 'medium', 6, 5, 14.50, 1.0, false, 19, 'sunny')
    ON CONFLICT (zone_id, recorded_at) DO NOTHING;

    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'SEED DATA INSERTED SUCCESSFULLY!';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Rider: Marco Rossi (%)' , v_rider_id;
    RAISE NOTICE 'Orders: 8 (7 completed + 1 in progress)';
    RAISE NOTICE 'Dealers: 4';
    RAISE NOTICE 'Clients: 5';
    RAISE NOTICE 'Boxes: 2';
    RAISE NOTICE 'Market Products: 6';
    RAISE NOTICE 'Transactions: 12';
    RAISE NOTICE 'Earnings Daily: today';
    RAISE NOTICE 'Earnings Monthly: current month';
    RAISE NOTICE 'Active Session: Centro Storico Napoli';
    RAISE NOTICE 'Zone Metrics: 4 Napoli zones';
    RAISE NOTICE '============================================';

END $$;
