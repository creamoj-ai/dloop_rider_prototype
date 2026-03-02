-- Verifica ordini creati
SELECT 
  id,
  product_name,
  customer_name,
  customer_phone,
  quantity,
  unit_price,
  total_price,
  status,
  created_at
FROM orders
ORDER BY created_at DESC
LIMIT 10;
