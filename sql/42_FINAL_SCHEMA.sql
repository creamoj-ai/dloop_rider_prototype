-- ============================================================
-- WhatsApp Bot Schema - FINAL VERSION
-- ============================================================

-- ============================================================
-- 1. WhatsApp Conversations Table
-- ============================================================
CREATE TABLE IF NOT EXISTS public.whatsapp_conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone TEXT NOT NULL,
  customer_name TEXT,
  conversation_type TEXT NOT NULL DEFAULT 'customer' CHECK (conversation_type IN ('customer', 'dealer')),
  state TEXT NOT NULL DEFAULT 'idle'
    CHECK (state IN ('idle', 'ordering', 'confirming', 'tracking', 'support', 'order_placed', 'completed')),
  context JSONB DEFAULT '{}'::jsonb,
  assigned_rider_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  message_count INT DEFAULT 0,
  last_message_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),

  UNIQUE(phone)
);

CREATE INDEX IF NOT EXISTS idx_wa_conversations_phone ON public.whatsapp_conversations(phone);
CREATE INDEX IF NOT EXISTS idx_wa_conversations_type ON public.whatsapp_conversations(conversation_type);
CREATE INDEX IF NOT EXISTS idx_wa_conversations_rider ON public.whatsapp_conversations(assigned_rider_id);
CREATE INDEX IF NOT EXISTS idx_wa_conversations_updated ON public.whatsapp_conversations(updated_at DESC);

ALTER TABLE public.whatsapp_conversations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Service role full access on conversations" ON public.whatsapp_conversations;
CREATE POLICY "Service role full access on conversations"
  ON public.whatsapp_conversations FOR ALL
  USING (auth.role() = 'service_role');

-- ============================================================
-- 2. WhatsApp Messages Table
-- ============================================================
CREATE TABLE IF NOT EXISTS public.whatsapp_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES public.whatsapp_conversations(id) ON DELETE CASCADE,
  phone TEXT NOT NULL,
  direction TEXT NOT NULL CHECK (direction IN ('inbound', 'outbound')),
  content TEXT NOT NULL,
  message_type TEXT NOT NULL DEFAULT 'text'
    CHECK (message_type IN ('text', 'voice', 'image', 'template', 'interactive', 'location', 'document')),
  wa_message_id TEXT UNIQUE,
  template_name TEXT,
  status TEXT DEFAULT 'sent'
    CHECK (status IN ('sent', 'delivered', 'read', 'failed', 'pending')),
  meta_response TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  tokens_used INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),

  CONSTRAINT message_from_conversation CHECK (
    (direction = 'inbound' AND wa_message_id IS NOT NULL) OR
    direction = 'outbound'
  )
);

CREATE INDEX IF NOT EXISTS idx_wa_messages_conversation ON public.whatsapp_messages(conversation_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_wa_messages_phone ON public.whatsapp_messages(phone, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_wa_messages_wa_id ON public.whatsapp_messages(wa_message_id);
CREATE INDEX IF NOT EXISTS idx_wa_messages_direction ON public.whatsapp_messages(direction, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_wa_messages_status ON public.whatsapp_messages(status);

ALTER TABLE public.whatsapp_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Service role full access on messages" ON public.whatsapp_messages;
CREATE POLICY "Service role full access on messages"
  ON public.whatsapp_messages FOR ALL
  USING (auth.role() = 'service_role');

-- ============================================================
-- 3. WhatsApp Order Relays Table
-- ============================================================
CREATE TABLE IF NOT EXISTS public.whatsapp_order_relays (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES public.whatsapp_conversations(id) ON DELETE CASCADE,
  order_id UUID REFERENCES public.market_orders(id) ON DELETE SET NULL,
  dealer_id UUID NOT NULL REFERENCES public.riders(id) ON DELETE CASCADE,
  customer_phone TEXT NOT NULL,
  customer_name TEXT,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'confirmed', 'declined', 'preparing', 'ready', 'picked_up', 'completed', 'cancelled')),
  products JSONB NOT NULL DEFAULT '[]'::jsonb,
  total_price NUMERIC(10,2),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_wa_relays_conversation ON public.whatsapp_order_relays(conversation_id);
CREATE INDEX IF NOT EXISTS idx_wa_relays_dealer ON public.whatsapp_order_relays(dealer_id, status);
CREATE INDEX IF NOT EXISTS idx_wa_relays_status ON public.whatsapp_order_relays(status);

ALTER TABLE public.whatsapp_order_relays ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Service role full access on relays" ON public.whatsapp_order_relays;
CREATE POLICY "Service role full access on relays"
  ON public.whatsapp_order_relays FOR ALL
  USING (auth.role() = 'service_role');

-- ============================================================
-- 4. rider_contacts support
-- ============================================================
ALTER TABLE IF EXISTS public.rider_contacts
  ADD COLUMN IF NOT EXISTS contact_value TEXT;

CREATE INDEX IF NOT EXISTS idx_rider_contacts_contact_value
  ON public.rider_contacts(contact_value)
  WHERE contact_value IS NOT NULL;

-- ============================================================
-- Verification
-- ============================================================
SELECT
  COUNT(*) as tables_created
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('whatsapp_conversations', 'whatsapp_messages', 'whatsapp_order_relays');
