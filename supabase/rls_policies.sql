-- Enable RLS on all tables
ALTER TABLE rider_pricing ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE earnings ENABLE ROW LEVEL SECURITY;

-- rider_pricing: SELECT/INSERT/UPDATE where rider_id = auth.uid()
CREATE POLICY "Users can view own pricing"
  ON rider_pricing FOR SELECT
  USING (rider_id = auth.uid());

CREATE POLICY "Users can insert own pricing"
  ON rider_pricing FOR INSERT
  WITH CHECK (rider_id = auth.uid());

CREATE POLICY "Users can update own pricing"
  ON rider_pricing FOR UPDATE
  USING (rider_id = auth.uid())
  WITH CHECK (rider_id = auth.uid());

-- orders: SELECT/INSERT/UPDATE where rider_id = auth.uid()
CREATE POLICY "Users can view own orders"
  ON orders FOR SELECT
  USING (rider_id = auth.uid());

CREATE POLICY "Users can insert own orders"
  ON orders FOR INSERT
  WITH CHECK (rider_id = auth.uid());

CREATE POLICY "Users can update own orders"
  ON orders FOR UPDATE
  USING (rider_id = auth.uid())
  WITH CHECK (rider_id = auth.uid());

-- earnings: SELECT/INSERT where rider_id = auth.uid()
CREATE POLICY "Users can view own earnings"
  ON earnings FOR SELECT
  USING (rider_id = auth.uid());

CREATE POLICY "Users can insert own earnings"
  ON earnings FOR INSERT
  WITH CHECK (rider_id = auth.uid());
