-- ============================================
-- 43. Add delivery_slot to orders table
-- ============================================
-- Stores the customer-selected delivery time window.
-- Values: '09-11' | '11-13' | '13-15' | '15-17' | '17-19' | '19-21'

ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS delivery_slot TEXT
  CHECK (delivery_slot IN ('09-11', '11-13', '13-15', '15-17', '17-19', '19-21'));

COMMENT ON COLUMN public.orders.delivery_slot IS 'Customer-selected delivery time slot (HH-HH format)';
