-- MVP Test Data: 20 Dealers + 10 Customers
-- Created: 2026-02-23

DO $$
DECLARE
  v_rider_id UUID;
BEGIN
  -- Get test rider
  SELECT id INTO v_rider_id FROM auth.users WHERE email = 'creamoj@gmail.com' LIMIT 1;
  IF v_rider_id IS NULL THEN
    RAISE NOTICE 'No rider found for creamoj@gmail.com';
    RETURN;
  END IF;

  -- TEST DEALERS (20 items) - grocery + pet
  INSERT INTO rider_contacts (rider_id, name, contact_type, status, phone, total_orders, monthly_earnings, category) VALUES
  -- GROCERY DEALERS (10)
  (v_rider_id, 'Carrefour Express Napoli', 'dealer', 'active', '+39 081 2345678', 142, 120.00, 'grocery'),
  (v_rider_id, 'Esselunga Vomero', 'dealer', 'active', '+39 081 5555111', 98, 95.00, 'grocery'),
  (v_rider_id, 'CooperMarkt Centro', 'dealer', 'active', '+39 081 6666222', 76, 80.00, 'grocery'),
  (v_rider_id, 'Auchan Fuorigrotta', 'dealer', 'potential', '+39 081 7777333', 12, 45.00, 'grocery'),
  (v_rider_id, 'Amazon Fresh Napoli', 'dealer', 'active', '+39 081 8888444', 156, 145.00, 'grocery'),
  (v_rider_id, 'Marianna Supermercati', 'dealer', 'active', '+39 081 9999555', 89, 85.00, 'grocery'),
  (v_rider_id, 'Spesa Online Napoli', 'dealer', 'active', '+39 081 1010111', 124, 110.00, 'grocery'),
  (v_rider_id, 'Alimentari Vomero', 'dealer', 'active', '+39 081 1111222', 67, 75.00, 'grocery'),
  (v_rider_id, 'Bio Market Napoli', 'dealer', 'potential', '+39 081 1212333', 34, 60.00, 'grocery'),
  (v_rider_id, 'Express Alimentari', 'dealer', 'active', '+39 081 1313444', 145, 135.00, 'grocery'),

  -- PET DEALERS (10)
  (v_rider_id, 'PetStore Napoli', 'dealer', 'active', '+39 081 2000111', 78, 85.00, 'pet'),
  (v_rider_id, 'Zooplus Campania', 'dealer', 'active', '+39 081 2001222', 56, 65.00, 'pet'),
  (v_rider_id, 'Veterinari Napoli', 'dealer', 'active', '+39 081 2002333', 92, 100.00, 'pet'),
  (v_rider_id, 'Grooming Center Vomero', 'dealer', 'potential', '+39 081 2003444', 23, 50.00, 'pet'),
  (v_rider_id, 'Pet Supplies Napoli', 'dealer', 'active', '+39 081 2004555', 64, 72.00, 'pet'),
  (v_rider_id, 'Negozio Animali Centro', 'dealer', 'active', '+39 081 2005666', 45, 55.00, 'pet'),
  (v_rider_id, 'Veterinaria San Domenico', 'dealer', 'active', '+39 081 2006777', 87, 95.00, 'pet'),
  (v_rider_id, 'Toelettatura Cani Gatti', 'dealer', 'potential', '+39 081 2007888', 28, 45.00, 'pet'),
  (v_rider_id, 'Pet Shop Premium', 'dealer', 'active', '+39 081 2008999', 102, 115.00, 'pet'),
  (v_rider_id, 'Mangimi e Accessori', 'dealer', 'active', '+39 081 2009100', 71, 78.00, 'pet');

  RAISE NOTICE 'Seeded 20 dealers for rider %', v_rider_id;

  -- TEST CUSTOMERS (10)
  INSERT INTO clients (rider_id, full_name, phone, address, lat, lng, loyalty_tier, loyalty_points, total_orders, total_spent, status) VALUES
  (v_rider_id, 'Marco Rossi', '+39 333 1234567', 'Via Vomero 42, Napoli', 40.8450, 14.2580, 'gold', 1200, 45, 650.00, 'active'),
  (v_rider_id, 'Anna Bianchi', '+39 333 2234567', 'Piazza del Plebiscito 1, Napoli', 40.8530, 14.2650, 'silver', 580, 28, 420.00, 'active'),
  (v_rider_id, 'Giuseppe Verdi', '+39 333 3234567', 'Via Fuorigrotta 88, Napoli', 40.8200, 14.1950, 'bronze', 280, 15, 200.00, 'active'),
  (v_rider_id, 'Lucia Ferrari', '+39 333 4234567', 'Via Chiaia 65, Napoli', 40.8390, 14.2470, 'bronze', 125, 8, 120.00, 'active'),
  (v_rider_id, 'Paolo Rizzo', '+39 333 5234567', 'Via Posillipo 12, Napoli', 40.8100, 14.2100, 'silver', 450, 22, 380.00, 'vip'),
  (v_rider_id, 'Elena Rossi', '+39 333 6234567', 'Piazza Montesanto 5, Napoli', 40.8560, 14.2650, 'bronze', 95, 5, 85.00, 'active'),
  (v_rider_id, 'Francesco Russo', '+39 333 7234567', 'Via Cavalleggeri d''Aosta 6, Napoli', 40.8450, 14.1850, 'gold', 980, 38, 580.00, 'vip'),
  (v_rider_id, 'Gabriella Gallo', '+39 333 8234567', 'Via San Carlo Arena 25, Napoli', 40.8650, 14.2450, 'bronze', 165, 9, 145.00, 'active'),
  (v_rider_id, 'Salvatore Marino', '+39 333 9234567', 'Via Arenella 14, Napoli', 40.8150, 14.2450, 'silver', 320, 16, 265.00, 'active'),
  (v_rider_id, 'Vittoria Lombardi', '+39 333 0234567', 'Via Soccavo 33, Napoli', 40.7950, 14.1650, 'bronze', 210, 12, 175.00, 'active');

  RAISE NOTICE 'Seeded 10 customers for rider %', v_rider_id;
  RAISE NOTICE 'Total: 20 dealers + 10 customers seeded successfully';

END $$;
