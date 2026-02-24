-- ============================================================
-- 42: WhatsApp Bot Complete Schema
-- ============================================================
-- This script creates ALL tables needed for WhatsApp bot MVP
-- RUN THIS IN SUPABASE SQL EDITOR BEFORE DEPLOYING BOT
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

-- Indexes for fast lookup
CREATE INDEX IF NOT EXISTS idx_wa_conversations_phone ON public.whatsapp_conversations(phone);
CREATE INDEX IF NOT EXISTS idx_wa_conversations_type ON public.whatsapp_conversations(conversation_type);
CREATE INDEX IF NOT EXISTS idx_wa_conversations_rider ON public.whatsapp_conversations(assigned_rider_id);
CREATE INDEX IF NOT EXISTS idx_wa_conversations_updated ON public.whatsapp_conversations(updated_at DESC);

-- RLS
ALTER TABLE public.whatsapp_conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role full access on conversations"
  ON public.whatsapp_conversations FOR ALL
  USING (auth.role() = 'service_role');

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.whatsapp_conversations;

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

-- Indexes
CREATE INDEX IF NOT EXISTS idx_wa_messages_conversation ON public.whatsapp_messages(conversation_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_wa_messages_phone ON public.whatsapp_messages(phone, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_wa_messages_wa_id ON public.whatsapp_messages(wa_message_id);
CREATE INDEX IF NOT EXISTS idx_wa_messages_direction ON public.whatsapp_messages(direction, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_wa_messages_status ON public.whatsapp_messages(status);

-- RLS
ALTER TABLE public.whatsapp_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role full access on messages"
  ON public.whatsapp_messages FOR ALL
  USING (auth.role() = 'service_role');

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.whatsapp_messages;

-- ============================================================
-- 3. WhatsApp Order Relays Table (dealer → customer orders)
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

-- Indexes
CREATE INDEX IF NOT EXISTS idx_wa_relays_conversation ON public.whatsapp_order_relays(conversation_id);
CREATE INDEX IF NOT EXISTS idx_wa_relays_dealer ON public.whatsapp_order_relays(dealer_id, status);
CREATE INDEX IF NOT EXISTS idx_wa_relays_status ON public.whatsapp_order_relays(status);

-- RLS
ALTER TABLE public.whatsapp_order_relays ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role full access on relays"
  ON public.whatsapp_order_relays FOR ALL
  USING (auth.role() = 'service_role');

-- ============================================================
-- 4. Update rider_contacts table to support WhatsApp routing
-- ============================================================
-- Check if contact_value column exists, if not add it
ALTER TABLE IF EXISTS public.rider_contacts
  ADD COLUMN IF NOT EXISTS contact_value TEXT;

-- Create indexes for WhatsApp lookup
CREATE INDEX IF NOT EXISTS idx_rider_contacts_contact_value
  ON public.rider_contacts(contact_value)
  WHERE contact_value IS NOT NULL;

-- ============================================================
-- 5. Trigger to update whatsapp_conversations.updated_at
-- ============================================================
CREATE OR REPLACE FUNCTION public.update_whatsapp_conversations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.whatsapp_conversations
    SET updated_at = NOW(), message_count = message_count + 1
    WHERE id = NEW.conversation_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop trigger if exists and recreate
DROP TRIGGER IF EXISTS trigger_update_wa_conversations_on_message ON public.whatsapp_messages;

CREATE TRIGGER trigger_update_wa_conversations_on_message
    AFTER INSERT ON public.whatsapp_messages
    FOR EACH ROW
    EXECUTE FUNCTION public.update_whatsapp_conversations_updated_at();

-- ============================================================
-- 6. Trigger to update whatsapp_order_relays.updated_at
-- ============================================================
CREATE OR REPLACE FUNCTION public.update_whatsapp_order_relays_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_wa_relays_updated_at ON public.whatsapp_order_relays;

CREATE TRIGGER trigger_update_wa_relays_updated_at
    BEFORE UPDATE ON public.whatsapp_order_relays
    FOR EACH ROW
    EXECUTE FUNCTION public.update_whatsapp_order_relays_updated_at();

-- ============================================================
-- 7. Verify Schema Created Successfully
-- ============================================================
-- Run this to check all tables exist
SELECT
  'whatsapp_conversations' as table_name,
  EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'whatsapp_conversations') as exists
UNION ALL
SELECT
  'whatsapp_messages',
  EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'whatsapp_messages')
UNION ALL
SELECT
  'whatsapp_order_relays',
  EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'whatsapp_order_relays');
