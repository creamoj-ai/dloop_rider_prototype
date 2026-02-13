-- ============================================================
-- SQL 33: Extend WhatsApp tables for Dual-Bot (Customer + Dealer)
-- ============================================================
-- Adds role-based routing to whatsapp_conversations,
-- dealer availability to rider_contacts,
-- customer_phone to orders, and customer_feedback table.
-- ============================================================

-- ── 1. Add role column to whatsapp_conversations ──────────────
ALTER TABLE whatsapp_conversations
  ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'customer'
    CHECK (role IN ('customer', 'dealer'));

ALTER TABLE whatsapp_conversations
  ADD COLUMN IF NOT EXISTS dealer_contact_id UUID REFERENCES rider_contacts(id);

-- Change UNIQUE constraint from phone to (phone, role)
-- so the same phone can have both a customer and dealer conversation
ALTER TABLE whatsapp_conversations
  DROP CONSTRAINT IF EXISTS whatsapp_conversations_phone_key;

ALTER TABLE whatsapp_conversations
  ADD CONSTRAINT uq_wa_conv_phone_role UNIQUE (phone, role);

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

ALTER TABLE orders
  ADD COLUMN IF NOT EXISTS wa_conversation_id UUID
    REFERENCES whatsapp_conversations(id);

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

-- RLS: only service role can access (bot writes feedback)
ALTER TABLE customer_feedback ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role full access on feedback"
  ON customer_feedback FOR ALL
  USING (auth.role() = 'service_role');

-- Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE customer_feedback;
