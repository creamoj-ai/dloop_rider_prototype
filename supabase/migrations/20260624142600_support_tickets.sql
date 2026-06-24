-- Support Tickets Table
-- Simple ticketing system for rider support

DO $$ BEGIN
  CREATE TYPE ticket_status AS ENUM ('open', 'in_progress', 'resolved', 'closed');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE ticket_category AS ENUM ('technical', 'payment', 'order', 'other');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE ticket_priority AS ENUM ('low', 'medium', 'high', 'urgent');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS support_tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rider_id UUID NOT NULL REFERENCES riders(id) ON DELETE CASCADE,

  -- Ticket details
  category ticket_category NOT NULL DEFAULT 'other',
  priority ticket_priority NOT NULL DEFAULT 'medium',
  status ticket_status NOT NULL DEFAULT 'open',

  subject TEXT NOT NULL,
  description TEXT NOT NULL,

  -- Internal notes (only visible to support team)
  internal_notes TEXT,
  assigned_to TEXT, -- Email or ID of support agent

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  resolved_at TIMESTAMP WITH TIME ZONE,
  closed_at TIMESTAMP WITH TIME ZONE
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_support_tickets_rider_id ON support_tickets(rider_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON support_tickets(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_support_tickets_category ON support_tickets(category);
CREATE INDEX IF NOT EXISTS idx_support_tickets_priority ON support_tickets(priority DESC, created_at ASC);

-- RLS Policies
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;

-- Policy: Riders can read their own tickets
DROP POLICY IF EXISTS "Riders can read own tickets" ON support_tickets;
CREATE POLICY "Riders can read own tickets"
  ON support_tickets
  FOR SELECT
  USING (auth.uid() = rider_id);

-- Policy: Riders can create tickets
DROP POLICY IF EXISTS "Riders can create tickets" ON support_tickets;
CREATE POLICY "Riders can create tickets"
  ON support_tickets
  FOR INSERT
  WITH CHECK (auth.uid() = rider_id);

-- Policy: Riders can update their own open tickets (subject/description only, within 30 minutes)
DROP POLICY IF EXISTS "Riders can update own open tickets" ON support_tickets;
CREATE POLICY "Riders can update own open tickets"
  ON support_tickets
  FOR UPDATE
  USING (
    auth.uid() = rider_id
    AND status = 'open'
    AND created_at > NOW() - INTERVAL '30 minutes'
  )
  WITH CHECK (
    -- Riders can only update subject and description, not status or internal fields
    auth.uid() = rider_id
  );

-- Trigger for updated_at
CREATE OR REPLACE FUNCTION update_support_tickets_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();

  -- Auto-set resolved_at when status changes to resolved
  IF NEW.status = 'resolved' AND OLD.status != 'resolved' THEN
    NEW.resolved_at = NOW();
  END IF;

  -- Auto-set closed_at when status changes to closed
  IF NEW.status = 'closed' AND OLD.status != 'closed' THEN
    NEW.closed_at = NOW();
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS support_tickets_updated_at ON support_tickets;
CREATE TRIGGER support_tickets_updated_at
  BEFORE UPDATE ON support_tickets
  FOR EACH ROW
  EXECUTE FUNCTION update_support_tickets_updated_at();

-- Support Ticket Messages (for conversation thread)
CREATE TABLE IF NOT EXISTS support_ticket_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,

  sender_type TEXT NOT NULL CHECK (sender_type IN ('rider', 'support')),
  sender_id UUID, -- rider_id if rider, support agent ID if support

  message TEXT NOT NULL,
  attachments JSONB, -- Array of attachment URLs

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_support_ticket_messages_ticket_id ON support_ticket_messages(ticket_id, created_at ASC);

-- RLS Policies for messages
ALTER TABLE support_ticket_messages ENABLE ROW LEVEL SECURITY;

-- Policy: Riders can read messages for their tickets
DROP POLICY IF EXISTS "Riders can read own ticket messages" ON support_ticket_messages;
CREATE POLICY "Riders can read own ticket messages"
  ON support_ticket_messages
  FOR SELECT
  USING (
    ticket_id IN (
      SELECT id FROM support_tickets WHERE rider_id = auth.uid()
    )
  );

-- Policy: Riders can send messages on their tickets
DROP POLICY IF EXISTS "Riders can send messages on own tickets" ON support_ticket_messages;
CREATE POLICY "Riders can send messages on own tickets"
  ON support_ticket_messages
  FOR INSERT
  WITH CHECK (
    sender_type = 'rider'
    AND sender_id = auth.uid()
    AND ticket_id IN (
      SELECT id FROM support_tickets WHERE rider_id = auth.uid()
    )
  );

-- Comments
COMMENT ON TABLE support_tickets IS 'Support ticketing system for rider issues';
COMMENT ON TABLE support_ticket_messages IS 'Conversation thread for support tickets';
