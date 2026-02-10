-- ============================================
-- 16. RLS policies for orders table
-- ============================================
-- Enables Row Level Security on orders so riders can only
-- see, insert, and update their own orders.

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Riders can view own orders"
  ON public.orders FOR SELECT
  USING (rider_id = auth.uid());

CREATE POLICY "Riders can insert own orders"
  ON public.orders FOR INSERT
  WITH CHECK (rider_id = auth.uid());

CREATE POLICY "Riders can update own orders"
  ON public.orders FOR UPDATE
  USING (rider_id = auth.uid());
