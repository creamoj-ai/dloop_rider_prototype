-- ============================================
-- 24. Create AI chatbot messages table
-- ============================================

CREATE TABLE IF NOT EXISTS public.bot_messages (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rider_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role        TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content     TEXT NOT NULL,
    tokens_used INT NOT NULL DEFAULT 0,
    model       TEXT NOT NULL DEFAULT 'gpt-4o-mini',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX idx_bot_messages_rider ON public.bot_messages(rider_id);
CREATE INDEX idx_bot_messages_rider_created ON public.bot_messages(rider_id, created_at);

-- RLS
ALTER TABLE public.bot_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Riders can view own bot messages"
    ON public.bot_messages FOR SELECT
    USING (rider_id = auth.uid());

CREATE POLICY "Riders can insert own bot messages"
    ON public.bot_messages FOR INSERT
    WITH CHECK (rider_id = auth.uid());

CREATE POLICY "Riders can delete own bot messages"
    ON public.bot_messages FOR DELETE
    USING (rider_id = auth.uid());

-- Enable real-time
ALTER PUBLICATION supabase_realtime ADD TABLE public.bot_messages;
