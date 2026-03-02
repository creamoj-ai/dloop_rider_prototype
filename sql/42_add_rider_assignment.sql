-- ============================================================================
-- SQL MIGRATION: Add Rider Assignment Logic
-- ============================================================================
-- Adds support for hybrid rider assignment (client choice + dealer auto)
-- ============================================================================

-- 1. UPDATE orders TABLE
ALTER TABLE orders ADD COLUMN IF NOT EXISTS (
  preferred_rider_id UUID REFERENCES riders(id) ON DELETE SET NULL,
  assigned_rider_id UUID REFERENCES riders(id) ON DELETE SET NULL,
  dealer_assigned_at TIMESTAMP,
  rider_accepted_at TIMESTAMP,
  rider_rejected_at TIMESTAMP,
  rider_rejection_reason TEXT
);

-- 2. UPDATE riders TABLE
ALTER TABLE riders ADD COLUMN IF NOT EXISTS (
  current_order_count INT DEFAULT 0,
  status TEXT DEFAULT 'OFFLINE' CHECK (status IN ('ONLINE', 'OFFLINE', 'ON_DELIVERY', 'BREAK')),
  location POINT, -- GPS coordinates (latitude, longitude)
  acceptance_rate DECIMAL(3,2) DEFAULT 1.0
);

-- 3. CREATE ORDER_ASSIGNMENT_LOG TABLE (for audit trail)
CREATE TABLE IF NOT EXISTS order_assignment_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  rider_id UUID NOT NULL REFERENCES riders(id) ON DELETE CASCADE,
  assignment_type TEXT NOT NULL CHECK (assignment_type IN ('CLIENT_CHOICE', 'DEALER_MANUAL', 'AUTO')),
  status TEXT NOT NULL CHECK (status IN ('ASSIGNED', 'ACCEPTED', 'REJECTED')),
  rejection_reason TEXT,
  assigned_at TIMESTAMP NOT NULL DEFAULT NOW(),
  accepted_at TIMESTAMP,
  rejected_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 4. CREATE RIDER_AVAILABILITY VIEW
CREATE OR REPLACE VIEW available_riders AS
SELECT
  id,
  name,
  rating,
  current_order_count,
  status,
  acceptance_rate,
  location,
  (6 - current_order_count) AS available_slots
FROM riders
WHERE status = 'ONLINE'
  AND rating >= 4.5
  AND current_order_count < 5
ORDER BY rating DESC, current_order_count ASC;

-- 5. ADD INDEXES FOR PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_orders_assigned_rider_id ON orders(assigned_rider_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_dealer_assigned_at ON orders(dealer_assigned_at);
CREATE INDEX IF NOT EXISTS idx_riders_status ON riders(status);
CREATE INDEX IF NOT EXISTS idx_riders_rating ON riders(rating DESC);
CREATE INDEX IF NOT EXISTS idx_riders_current_order_count ON riders(current_order_count);

-- 6. ADD TRIGGER: Auto-increment rider order count
CREATE OR REPLACE FUNCTION increment_rider_order_count()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'ASSIGNED' AND OLD.status != 'ASSIGNED' THEN
    UPDATE riders SET current_order_count = current_order_count + 1
    WHERE id = NEW.assigned_rider_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_increment_rider_order_count ON orders;
CREATE TRIGGER trg_increment_rider_order_count
AFTER UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION increment_rider_order_count();

-- 7. ADD TRIGGER: Update rider status when order delivered
CREATE OR REPLACE FUNCTION update_rider_status_on_delivery()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'DELIVERED' AND OLD.status != 'DELIVERED' THEN
    UPDATE riders
    SET current_order_count = current_order_count - 1,
        status = CASE
          WHEN current_order_count - 1 <= 0 THEN 'ONLINE'
          ELSE 'ON_DELIVERY'
        END
    WHERE id = NEW.assigned_rider_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_rider_status_on_delivery ON orders;
CREATE TRIGGER trg_update_rider_status_on_delivery
AFTER UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION update_rider_status_on_delivery();

-- 8. SAMPLE DATA: Add test riders
INSERT INTO riders (id, name, email, phone, status, rating, acceptance_rate, current_order_count)
VALUES
  ('550e8400-e29b-41d4-a716-446655440001', 'Marco Rossi', 'marco@dloop.it', '+393201234567', 'ONLINE', 4.9, 1.0, 2),
  ('550e8400-e29b-41d4-a716-446655440002', 'Luca Bianchi', 'luca@dloop.it', '+393312345678', 'ONLINE', 4.8, 0.98, 1),
  ('550e8400-e29b-41d4-a716-446655440003', 'Giovanni Ferrari', 'giovanni@dloop.it', '+393423456789', 'ON_DELIVERY', 4.7, 0.95, 4),
  ('550e8400-e29b-41d4-a716-446655440004', 'Pietro Verdi', 'pietro@dloop.it', '+393534567890', 'OFFLINE', 4.6, 0.92, 0)
ON CONFLICT DO NOTHING;

-- 9. UPDATE ORDERS TABLE WITH NEW STATUSES
ALTER TABLE orders
DROP CONSTRAINT IF EXISTS orders_status_check;

ALTER TABLE orders
ADD CONSTRAINT orders_status_check CHECK (status IN (
  'BROWSING',
  'WAITING_ADDRESS',
  'AWAITING_SHOP_CONFIRM',
  'CONFIRMED',
  'PENDING_RIDER_ACCEPTANCE',
  'ASSIGNED',
  'IN_PICKUP',
  'IN_DELIVERY',
  'DELIVERED',
  'REJECTED'
));

-- 10. LOGGING
SELECT 'Migration: Rider Assignment Logic - COMPLETED ✅' AS status;
SELECT NOW() AS completed_at;
