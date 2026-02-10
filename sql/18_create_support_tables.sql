-- ============================================
-- 18. Create support chat tables
-- ============================================
-- Conversations and messages for rider ↔ support chat

-- ========================================
-- Conversations
-- ========================================
CREATE TABLE IF NOT EXISTS public.support_conversations (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rider_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  subject     TEXT NOT NULL DEFAULT 'Supporto',
  status      TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'closed')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_support_conversations_rider ON public.support_conversations(rider_id);

-- RLS
ALTER TABLE public.support_conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Riders can view own conversations"
  ON public.support_conversations FOR SELECT
  USING (rider_id = auth.uid());

CREATE POLICY "Riders can create conversations"
  ON public.support_conversations FOR INSERT
  WITH CHECK (rider_id = auth.uid());

CREATE POLICY "Riders can update own conversations"
  ON public.support_conversations FOR UPDATE
  USING (rider_id = auth.uid())
  WITH CHECK (rider_id = auth.uid());

-- Enable real-time
ALTER PUBLICATION supabase_realtime ADD TABLE public.support_conversations;

-- ========================================
-- Messages
-- ========================================
CREATE TABLE IF NOT EXISTS public.support_messages (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES public.support_conversations(id) ON DELETE CASCADE,
  sender_type     TEXT NOT NULL CHECK (sender_type IN ('rider', 'support', 'system')),
  sender_id       UUID,
  body            TEXT NOT NULL,
  is_read         BOOLEAN NOT NULL DEFAULT false,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_support_messages_conversation ON public.support_messages(conversation_id);
CREATE INDEX idx_support_messages_created_at ON public.support_messages(conversation_id, created_at);
CREATE INDEX idx_support_messages_unread ON public.support_messages(conversation_id, is_read) WHERE is_read = false;

-- RLS
ALTER TABLE public.support_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Riders can view own conversation messages"
  ON public.support_messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.support_conversations sc
      WHERE sc.id = conversation_id AND sc.rider_id = auth.uid()
    )
  );

CREATE POLICY "Riders can send messages"
  ON public.support_messages FOR INSERT
  WITH CHECK (
    sender_type = 'rider'
    AND sender_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.support_conversations sc
      WHERE sc.id = conversation_id AND sc.rider_id = auth.uid()
    )
  );

CREATE POLICY "Riders can mark messages as read"
  ON public.support_messages FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.support_conversations sc
      WHERE sc.id = conversation_id AND sc.rider_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.support_conversations sc
      WHERE sc.id = conversation_id AND sc.rider_id = auth.uid()
    )
  );

-- Enable real-time
ALTER PUBLICATION supabase_realtime ADD TABLE public.support_messages;

-- ========================================
-- Auto-welcome trigger
-- ========================================
CREATE OR REPLACE FUNCTION public.handle_new_support_conversation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.support_messages (conversation_id, sender_type, sender_id, body)
  VALUES (
    NEW.id,
    'system',
    NULL,
    'Benvenuto nel supporto dloop! Un operatore ti risponderà a breve. Come possiamo aiutarti?'
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_support_conversation_created ON public.support_conversations;

CREATE TRIGGER on_support_conversation_created
  AFTER INSERT ON public.support_conversations
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_support_conversation();
