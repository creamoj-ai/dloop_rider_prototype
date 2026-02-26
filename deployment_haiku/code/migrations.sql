-- ============================================================
-- WhatsApp Bot Schema Migrations
-- Run these in order in Supabase SQL Editor
-- ============================================================

-- ============================================================
-- 1. Create WhatsApp Conversations Table
-- ============================================================
CREATE TABLE IF NOT EXISTS public.whatsapp_conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Contact info
  phone TEXT NOT NULL UNIQUE,
  conversation_type TEXT NOT NULL CHECK (conversation_type IN ('customer', 'dealer')),

  -- Context
  context JSONB DEFAULT '{}',

  -- Metadata
  message_count INT DEFAULT 0,
  last_message_at TIMESTAMPTZ DEFAULT now(),

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_conversations_phone ON public.whatsapp_conversations(phone);
CREATE INDEX IF NOT EXISTS idx_conversations_type ON public.whatsapp_conversations(conversation_type);
CREATE INDEX IF NOT EXISTS idx_conversations_updated ON public.whatsapp_conversations(updated_at DESC);

-- Enable RLS
ALTER TABLE public.whatsapp_conversations ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Enable read for authenticated" ON public.whatsapp_conversations;
CREATE POLICY "Enable read for authenticated"
  ON public.whatsapp_conversations FOR SELECT
  USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Enable all for service role" ON public.whatsapp_conversations;
CREATE POLICY "Enable all for service role"
  ON public.whatsapp_conversations FOR ALL
  USING (auth.role() = 'service_role');

-- ============================================================
-- 2. Create WhatsApp Messages Table
-- ============================================================
CREATE TABLE IF NOT EXISTS public.whatsapp_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Foreign keys
  conversation_id UUID NOT NULL REFERENCES public.whatsapp_conversations(id) ON DELETE CASCADE,
  phone TEXT NOT NULL,

  -- Content
  content TEXT NOT NULL,
  type TEXT DEFAULT 'text' CHECK (type IN ('text', 'image', 'audio', 'document')),

  -- Direction and status
  direction TEXT NOT NULL CHECK (direction IN ('inbound', 'outbound')),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'delivered', 'read', 'failed')),

  -- Meta integration
  meta_message_id TEXT,
  meta_response JSONB,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON public.whatsapp_messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_phone ON public.whatsapp_messages(phone);
CREATE INDEX IF NOT EXISTS idx_messages_created ON public.whatsapp_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_status ON public.whatsapp_messages(status);
CREATE INDEX IF NOT EXISTS idx_messages_direction ON public.whatsapp_messages(direction);

-- Enable RLS
ALTER TABLE public.whatsapp_messages ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Enable read for authenticated" ON public.whatsapp_messages;
CREATE POLICY "Enable read for authenticated"
  ON public.whatsapp_messages FOR SELECT
  USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Enable all for service role" ON public.whatsapp_messages;
CREATE POLICY "Enable all for service role"
  ON public.whatsapp_messages FOR ALL
  USING (auth.role() = 'service_role');

-- ============================================================
-- 3. Create WhatsApp Order Relays Table
-- ============================================================
CREATE TABLE IF NOT EXISTS public.whatsapp_order_relays (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Foreign keys
  conversation_id UUID REFERENCES public.whatsapp_conversations(id) ON DELETE SET NULL,
  phone TEXT NOT NULL,

  -- Order data
  order_data JSONB NOT NULL,
  products JSONB[] DEFAULT ARRAY[]::JSONB[],
  total_price NUMERIC(10,2),

  -- Status
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'created', 'failed')),

  -- Integration
  market_order_id UUID,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_relays_conversation ON public.whatsapp_order_relays(conversation_id);
CREATE INDEX IF NOT EXISTS idx_relays_status ON public.whatsapp_order_relays(status);
CREATE INDEX IF NOT EXISTS idx_relays_phone ON public.whatsapp_order_relays(phone);
CREATE INDEX IF NOT EXISTS idx_relays_created ON public.whatsapp_order_relays(created_at DESC);

-- Enable RLS
ALTER TABLE public.whatsapp_order_relays ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Enable read for authenticated" ON public.whatsapp_order_relays;
CREATE POLICY "Enable read for authenticated"
  ON public.whatsapp_order_relays FOR SELECT
  USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Enable all for service role" ON public.whatsapp_order_relays;
CREATE POLICY "Enable all for service role"
  ON public.whatsapp_order_relays FOR ALL
  USING (auth.role() = 'service_role');

-- ============================================================
-- 4. Enable Realtime (optional)
-- ============================================================
ALTER PUBLICATION supabase_realtime ADD TABLE public.whatsapp_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.whatsapp_conversations;

-- ============================================================
-- 5. Create Useful Views
-- ============================================================

-- Active conversations (last 24 hours)
DROP VIEW IF EXISTS public.active_conversations;
CREATE VIEW public.active_conversations AS
SELECT
  c.id,
  c.phone,
  c.conversation_type,
  c.message_count,
  c.last_message_at,
  AGE(NOW(), c.last_message_at) AS time_since_last_message
FROM public.whatsapp_conversations c
WHERE c.last_message_at > NOW() - INTERVAL '24 hours'
ORDER BY c.last_message_at DESC;

-- Recent messages by conversation
DROP VIEW IF EXISTS public.recent_messages_by_conversation;
CREATE VIEW public.recent_messages_by_conversation AS
SELECT
  c.id as conversation_id,
  c.phone,
  c.conversation_type,
  c.message_count,
  COUNT(m.id) FILTER (WHERE m.direction = 'inbound') as inbound_count,
  COUNT(m.id) FILTER (WHERE m.direction = 'outbound') as outbound_count,
  COUNT(m.id) FILTER (WHERE m.status = 'failed') as failed_count,
  c.last_message_at
FROM public.whatsapp_conversations c
LEFT JOIN public.whatsapp_messages m ON c.id = m.conversation_id
WHERE c.last_message_at > NOW() - INTERVAL '7 days'
GROUP BY c.id, c.phone, c.conversation_type, c.message_count, c.last_message_at
ORDER BY c.last_message_at DESC;

-- Message statistics
DROP VIEW IF EXISTS public.message_statistics;
CREATE VIEW public.message_statistics AS
SELECT
  DATE(created_at) as date,
  direction,
  status,
  COUNT(*) as count,
  ROUND(AVG(EXTRACT(EPOCH FROM (updated_at - created_at))), 2) as avg_processing_time_sec
FROM public.whatsapp_messages
WHERE created_at > NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at), direction, status
ORDER BY date DESC, direction, status;

-- ============================================================
-- 6. Create Triggers (optional)
-- ============================================================

-- Auto-update conversation last_message_at when new message arrives
CREATE OR REPLACE FUNCTION public.update_conversation_on_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.whatsapp_conversations
  SET
    last_message_at = NEW.created_at,
    message_count = message_count + 1,
    updated_at = NOW()
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_conversation_on_message ON public.whatsapp_messages;
CREATE TRIGGER trigger_update_conversation_on_message
  AFTER INSERT ON public.whatsapp_messages
  FOR EACH ROW
  EXECUTE FUNCTION public.update_conversation_on_message();

-- ============================================================
-- 7. Grant Permissions
-- ============================================================

-- Allow public (anon) to read via simulate endpoint
GRANT SELECT ON public.whatsapp_conversations TO anon;
GRANT SELECT ON public.whatsapp_messages TO anon;
GRANT SELECT ON public.whatsapp_order_relays TO anon;
GRANT INSERT ON public.whatsapp_messages TO anon;

-- Allow service_role full access (Edge Functions)
GRANT ALL ON public.whatsapp_conversations TO service_role;
GRANT ALL ON public.whatsapp_messages TO service_role;
GRANT ALL ON public.whatsapp_order_relays TO service_role;

-- ============================================================
-- 8. Verification
-- ============================================================
-- Check tables exist
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public' AND table_name LIKE 'whatsapp%';

-- Check RLS is enabled
SELECT tablename, rowsecurity FROM pg_tables
WHERE schemaname = 'public' AND tablename LIKE 'whatsapp%';

-- ============================================================
-- DONE!
-- ============================================================
-- All tables created successfully
-- Ready for bot deployment
