-- ============================================================
-- 31: WhatsApp Bot tables
-- Run on: Supabase SQL Editor
-- ============================================================

-- whatsapp_conversations: tracks each customer conversation
CREATE TABLE IF NOT EXISTS whatsapp_conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone TEXT NOT NULL UNIQUE,
  customer_name TEXT,
  state TEXT NOT NULL DEFAULT 'idle'
    CHECK (state IN ('idle', 'ordering', 'confirming', 'tracking', 'support')),
  context JSONB DEFAULT '{}'::jsonb,
  assigned_rider_id UUID REFERENCES users(id) ON DELETE SET NULL,
  last_message_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Index for fast lookup by phone
CREATE INDEX IF NOT EXISTS idx_wa_conversations_phone ON whatsapp_conversations(phone);
-- Index for rider assignment queries
CREATE INDEX IF NOT EXISTS idx_wa_conversations_rider ON whatsapp_conversations(assigned_rider_id);

-- RLS: rider sees only their assigned conversations
ALTER TABLE whatsapp_conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Riders see own assigned conversations"
  ON whatsapp_conversations FOR SELECT
  USING (assigned_rider_id = auth.uid());

CREATE POLICY "Service role full access on conversations"
  ON whatsapp_conversations FOR ALL
  USING (auth.role() = 'service_role');

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE whatsapp_conversations;

-- whatsapp_messages: individual messages in each conversation
CREATE TABLE IF NOT EXISTS whatsapp_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES whatsapp_conversations(id) ON DELETE CASCADE,
  direction TEXT NOT NULL CHECK (direction IN ('inbound', 'outbound')),
  content TEXT,
  message_type TEXT NOT NULL DEFAULT 'text'
    CHECK (message_type IN ('text', 'voice', 'image', 'template', 'interactive', 'location')),
  wa_message_id TEXT,
  template_name TEXT,
  status TEXT DEFAULT 'sent'
    CHECK (status IN ('sent', 'delivered', 'read', 'failed')),
  metadata JSONB DEFAULT '{}'::jsonb,
  tokens_used INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Index for conversation message history
CREATE INDEX IF NOT EXISTS idx_wa_messages_conversation ON whatsapp_messages(conversation_id, created_at);
-- Index for WhatsApp message ID lookups (status updates)
CREATE INDEX IF NOT EXISTS idx_wa_messages_wa_id ON whatsapp_messages(wa_message_id);

-- RLS: rider sees messages of their assigned conversations
ALTER TABLE whatsapp_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Riders see messages of own conversations"
  ON whatsapp_messages FOR SELECT
  USING (
    conversation_id IN (
      SELECT id FROM whatsapp_conversations
      WHERE assigned_rider_id = auth.uid()
    )
  );

CREATE POLICY "Service role full access on messages"
  ON whatsapp_messages FOR ALL
  USING (auth.role() = 'service_role');

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE whatsapp_messages;
