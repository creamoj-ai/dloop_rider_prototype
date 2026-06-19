-- Crea ordine di test per Admin Panel
INSERT INTO orders (
    id,
    restaurant_name,
    customer_name,
    customer_address,
    customer_phone,
    distance_km,
    base_earning,
    status,
    created_at
) VALUES (
    'TEST' || substr(md5(random()::text), 1, 8),
    'Yamamay Napoli Centro',
    'Mario Rossi',
    'Via Toledo 100, Napoli',
    '3331234567',
    3.11,
    4.67,
    'pending',
    NOW()
)
RETURNING id, restaurant_name, customer_address, status;
