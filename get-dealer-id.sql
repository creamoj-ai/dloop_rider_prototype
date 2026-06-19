-- Query per recuperare dealer_id di Yamamay
SELECT
    id,
    business_name,
    email,
    ST_AsText(location) as coordinates,
    status
FROM dealers
WHERE business_name LIKE '%Yamamay%'
AND status = 'active'
LIMIT 1;
