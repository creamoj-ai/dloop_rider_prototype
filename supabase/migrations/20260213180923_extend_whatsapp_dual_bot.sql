-- ============================================================
-- SQL 33: Extend WhatsApp tables for Dual-Bot (Customer + Dealer)
-- ============================================================
-- Idempotent: safe to re-run.
-- ============================================================

-- ── 1. Add role column to whatsapp_conversations ──────────────
ALTER TABLE whatsapp_conversations
  ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'customer'
    CHECK (role IN ('customer', 'dealer'));

ALTER TABLE whatsapp_conversations
  ADD COLUMN IF NOT EXISTS dealer_contact_id UUID REFERENCES rider_contacts(id);

ALTER TABLE whatsapp_conversations
  DROP CONSTRAINT IF EXISTS whatsapp_conversations_phone_key;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'uq_wa_conv_phone_role'
  ) THEN
    ALTER TABLE whatsapp_conversations
      ADD CONSTRAINT uq_wa_conv_phone_role UNIQUE (phone, role);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_wa_conversations_role
  ON whatsapp_conversations(role);

CREATE INDEX IF NOT EXISTS idx_wa_conversations_dealer
  ON whatsapp_conversations(dealer_contact_id);

-- ── 2. Dealer availability on rider_contacts ──────────────────
ALTER TABLE rider_contacts
  ADD COLUMN IF NOT EXISTS is_available BOOLEAN DEFAULT true;

ALTER TABLE rider_contacts
  ADD COLUMN IF NOT EXISTS unavailable_until TIMESTAMPTZ;

-- ── 3. Customer phone on orders (for future proactive msgs) ───
ALTER TABLE orders
  ADD COLUMN IF NOT EXISTS customer_phone TEXT;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'orders' AND column_name = 'wa_conversation_id'
  ) THEN
    ALTER TABLE orders
      ADD COLUMN wa_conversation_id UUID REFERENCES whatsapp_conversations(id);
  END IF;
END $$;

-- ── 4. Customer feedback table ────────────────────────────────
CREATE TABLE IF NOT EXISTS customer_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  customer_phone TEXT NOT NULL,
  rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_feedback_order
  ON customer_feedback(order_id);

CREATE INDEX IF NOT EXISTS idx_feedback_phone
  ON customer_feedback(customer_phone);

ALTER TABLE customer_feedback ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'Service role full access on feedback'
  ) THEN
    CREATE POLICY "Service role full access on feedback"
      ON customer_feedback FOR ALL
      USING (auth.role() = 'service_role');
  END IF;
END $$;

DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE customer_feedback;
EXCEPTION WHEN duplicate_object THEN
  NULL;
END $$;
