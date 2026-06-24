-- Community Messages Table
-- For community chat between riders in the same zone
-- Hidden from UI until 10+ active riders

CREATE TABLE IF NOT EXISTS community_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rider_id UUID NOT NULL REFERENCES riders(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  zone_id TEXT, -- Optional: filter by zone (e.g. "napoli_centro")
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_community_messages_created_at ON community_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_community_messages_zone_id ON community_messages(zone_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_community_messages_rider_id ON community_messages(rider_id);

-- RLS Policies
ALTER TABLE community_messages ENABLE ROW LEVEL SECURITY;

-- Policy: Riders can read all messages in their zone
DROP POLICY IF EXISTS "Riders can read community messages" ON community_messages;
CREATE POLICY "Riders can read community messages"
  ON community_messages
  FOR SELECT
  USING (true); -- All authenticated riders can read all messages

-- Policy: Riders can insert their own messages
DROP POLICY IF EXISTS "Riders can insert own messages" ON community_messages;
CREATE POLICY "Riders can insert own messages"
  ON community_messages
  FOR INSERT
  WITH CHECK (auth.uid() = rider_id);

-- Policy: Riders can update/delete their own messages (within 5 minutes)
DROP POLICY IF EXISTS "Riders can update own messages" ON community_messages;
CREATE POLICY "Riders can update own messages"
  ON community_messages
  FOR UPDATE
  USING (
    auth.uid() = rider_id
    AND created_at > NOW() - INTERVAL '5 minutes'
  );

DROP POLICY IF EXISTS "Riders can delete own messages" ON community_messages;
CREATE POLICY "Riders can delete own messages"
  ON community_messages
  FOR DELETE
  USING (
    auth.uid() = rider_id
    AND created_at > NOW() - INTERVAL '5 minutes'
  );

-- Trigger for updated_at
CREATE OR REPLACE FUNCTION update_community_messages_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS community_messages_updated_at ON community_messages;
CREATE TRIGGER community_messages_updated_at
  BEFORE UPDATE ON community_messages
  FOR EACH ROW
  EXECUTE FUNCTION update_community_messages_updated_at();

-- Comment
COMMENT ON TABLE community_messages IS 'Community chat messages between riders. Hidden from UI until 10+ active riders.';
