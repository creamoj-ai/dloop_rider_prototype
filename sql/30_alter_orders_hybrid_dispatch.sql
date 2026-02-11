-- ============================================
-- 30. Hybrid Dispatch — Add columns to orders table
-- ============================================
-- Enables the hybrid dispatch model:
-- 1. Order arrives → assigned to specific rider (assigned_rider_id)
-- 2. If rider doesn't accept within priority window → broadcast to zone
-- 3. Any rider in the zone can accept broadcast orders
--
-- source tracks where the order came from (bot, website, manual, etc.)
-- dealer_contact_id links to the dealer in rider_contacts
-- dealer_platform_id links to the platform integration that generated the order

-- New columns
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS assigned_rider_id UUID REFERENCES auth.users(id);
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS zone_id UUID;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS source TEXT DEFAULT 'manual';
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS priority_expires_at TIMESTAMPTZ;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS dealer_contact_id UUID;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS dealer_platform_id UUID;

-- Update existing RLS to allow riders to see broadcast orders in their zone
-- Drop and recreate SELECT policy to include broadcast orders
DO $$
BEGIN
  -- Try to drop existing select policy (may have different name)
  BEGIN
    DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
  EXCEPTION WHEN OTHERS THEN NULL;
  END;
  BEGIN
    DROP POLICY IF EXISTS "Riders can view own orders" ON public.orders;
  EXCEPTION WHEN OTHERS THEN NULL;
  END;
END $$;

-- New SELECT policy: rider sees own orders + broadcast orders (no assigned rider, in any zone)
CREATE POLICY "Riders can view own and broadcast orders"
    ON public.orders FOR SELECT
    USING (
      rider_id = auth.uid()
      OR (
        status = 'pending'
        AND assigned_rider_id IS NULL
        AND priority_expires_at IS NOT NULL
        AND priority_expires_at < now()
      )
    );

-- Index for broadcast order lookup
CREATE INDEX IF NOT EXISTS idx_orders_broadcast
    ON public.orders (status, assigned_rider_id, priority_expires_at)
    WHERE status = 'pending' AND assigned_rider_id IS NULL;

-- Backfill existing orders: set source to 'manual' where NULL
UPDATE public.orders SET source = 'manual' WHERE source IS NULL;
