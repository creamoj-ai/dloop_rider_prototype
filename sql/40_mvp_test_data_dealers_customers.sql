-- MVP Test Data: 20 Dealers (Grocery + Pet) + 10 Customers
-- Created: 2026-02-23

-- TEST DEALERS (20 items)
INSERT INTO rider_contacts (id, name, phone, city, delivery_area, platform_type, created_at) VALUES
-- GROCERY DEALERS (10)
('11111111-1111-1111-1111-111111111101'::UUID, 'Carrefour Express Napoli', '+39 081 2345678', 'Napoli', '80100,80128', 'grocery', NOW()),
('11111111-1111-1111-1111-111111111102'::UUID, 'Esselunga Vomero', '+39 081 5555111', 'Napoli', '80129,80130', 'grocery', NOW()),
('11111111-1111-1111-1111-111111111103'::UUID, 'CooperMarkt Centro', '+39 081 6666222', 'Napoli', '80132,80134', 'grocery', NOW()),
('11111111-1111-1111-1111-111111111104'::UUID, 'Auchan Fuorigrotta', '+39 081 7777333', 'Napoli', '80125,80126', 'grocery', NOW()),
('11111111-1111-1111-1111-111111111105'::UUID, 'Amazon Fresh Napoli', '+39 081 8888444', 'Napoli', '80100,80128,80129', 'grocery', NOW()),
('11111111-1111-1111-1111-111111111106'::UUID, 'Marianna Supermercati', '+39 081 9999555', 'Napoli', '80131,80133', 'grocery', NOW()),
('11111111-1111-1111-1111-111111111107'::UUID, 'Spesa Online Napoli', '+39 081 1010111', 'Napoli', '80100,80102', 'grocery', NOW()),
('11111111-1111-1111-1111-111111111108'::UUID, 'Alimentari Vomero', '+39 081 1111222', 'Napoli', '80129,80130,80131', 'grocery', NOW()),
('11111111-1111-1111-1111-111111111109'::UUID, 'Bio Market Napoli', '+39 081 1212333', 'Napoli', '80125,80127', 'grocery', NOW()),
('11111111-1111-1111-1111-111111111110'::UUID, 'Express Alimentari', '+39 081 1313444', 'Napoli', '80100,80128,80129', 'grocery', NOW()),

-- PET DEALERS (10)
('22222222-2222-2222-2222-222222222101'::UUID, 'PetStore Napoli', '+39 081 2000111', 'Napoli', '80100,80128,80129', 'pet', NOW()),
('22222222-2222-2222-2222-222222222102'::UUID, 'Zooplus Campania', '+39 081 2001222', 'Napoli', '80125,80126,80127', 'pet', NOW()),
('22222222-2222-2222-2222-222222222103'::UUID, 'Veterinari Napoli', '+39 081 2002333', 'Napoli', '80100,80102,80129', 'pet', NOW()),
('22222222-2222-2222-2222-222222222104'::UUID, 'Grooming Center Vomero', '+39 081 2003444', 'Napoli', '80129,80130,80131', 'pet', NOW()),
('22222222-2222-2222-2222-222222222105'::UUID, 'Pet Supplies Napoli', '+39 081 2004555', 'Napoli', '80100,80128', 'pet', NOW()),
('22222222-2222-2222-2222-222222222106'::UUID, 'Negozio Animali Centro', '+39 081 2005666', 'Napoli', '80132,80133,80134', 'pet', NOW()),
('22222222-2222-2222-2222-222222222107'::UUID, 'Veterinaria San Domenico', '+39 081 2006777', 'Napoli', '80131,80132,80133', 'pet', NOW()),
('22222222-2222-2222-2222-222222222108'::UUID, 'Toelettatura Cani Gatti', '+39 081 2007888', 'Napoli', '80125,80126', 'pet', NOW()),
('22222222-2222-2222-2222-222222222109'::UUID, 'Pet Shop Premium', '+39 081 2008999', 'Napoli', '80100,80128,80129,80130', 'pet', NOW()),
('22222222-2222-2222-2222-222222222110'::UUID, 'Mangimi e Accessori', '+39 081 2009100', 'Napoli', '80125,80126,80127', 'pet', NOW());

-- TEST CUSTOMERS (10)
INSERT INTO clients (id, name, phone, city, neighborhood, created_at) VALUES
('33333333-3333-3333-3333-333333333301'::UUID, 'Marco Rossi', '+39 333 1234567', 'Napoli', 'Vomero', NOW()),
('33333333-3333-3333-3333-333333333302'::UUID, 'Anna Bianchi', '+39 333 2234567', 'Napoli', 'Centro Storico', NOW()),
('33333333-3333-3333-3333-333333333303'::UUID, 'Giuseppe Verdi', '+39 333 3234567', 'Napoli', 'Fuorigrotta', NOW()),
('33333333-3333-3333-3333-333333333304'::UUID, 'Lucia Ferrari', '+39 333 4234567', 'Napoli', 'Chiaia', NOW()),
('33333333-3333-3333-3333-333333333305'::UUID, 'Paolo Rizzo', '+39 333 5234567', 'Napoli', 'Posillipo', NOW()),
('33333333-3333-3333-3333-333333333306'::UUID, 'Elena Rossi', '+39 333 6234567', 'Napoli', 'Montesanto', NOW()),
('33333333-3333-3333-3333-333333333307'::UUID, 'Francesco Russo', '+39 333 7234567', 'Napoli', 'Cavalleggeri', NOW()),
('33333333-3333-3333-3333-333333333308'::UUID, 'Gabriella Gallo', '+39 333 8234567', 'Napoli', 'San Carlo Arena', NOW()),
('33333333-3333-3333-3333-333333333309'::UUID, 'Salvatore Marino', '+39 333 9234567', 'Napoli', 'Arenella', NOW()),
('33333333-3333-3333-3333-333333333310'::UUID, 'Vittoria Lombardi', '+39 333 0234567', 'Napoli', 'Soccavo', NOW());
