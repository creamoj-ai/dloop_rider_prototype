# Complete Database Schema

## Overview

The WhatsApp bot uses 3 main tables:

```
whatsapp_conversations ← whatsapp_messages
                       ↓
                whatsapp_order_relays
```

## Table 1: whatsapp_conversations

Stores one conversation per phone number.

```sql
CREATE TABLE whatsapp_conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Contact info
  phone TEXT NOT NULL UNIQUE,                    -- Normalized phone number
  conversation_type TEXT NOT NULL,               -- 'customer' or 'dealer'

  -- Context & history
  context JSONB DEFAULT '{}',                    -- Conversation context

  -- Metadata
  message_count INT DEFAULT 0,                   -- Total messages in conversation
  last_message_at TIMESTAMPTZ DEFAULT now(),    -- Last message timestamp

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),         -- Conversation start
  updated_at TIMESTAMPTZ DEFAULT now()          -- Last update
);

-- Indexes
CREATE INDEX idx_conversations_phone ON whatsapp_conversations(phone);
CREATE INDEX idx_conversations_type ON whatsapp_conversations(conversation_type);
```

### Example Row

```json
{
  "id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "phone": "393331234567",
  "conversation_type": "customer",
  "context": {
    "last_intent": "order",
    "product_interest": "profumi",
    "preferred_language": "it"
  },
  "message_count": 15,
  "last_message_at": "2026-02-26T10:30:00Z",
  "created_at": "2026-02-20T14:22:00Z",
  "updated_at": "2026-02-26T10:30:00Z"
}
```

## Table 2: whatsapp_messages

Stores all inbound and outbound messages.

```sql
CREATE TABLE whatsapp_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Foreign keys
  conversation_id UUID NOT NULL REFERENCES whatsapp_conversations(id) ON DELETE CASCADE,
  phone TEXT NOT NULL,                           -- Denormalized for queries

  -- Message content
  content TEXT NOT NULL,                         -- Message body
  type TEXT DEFAULT 'text',                      -- 'text', 'image', 'audio', 'document'

  -- Direction & status
  direction TEXT NOT NULL,                       -- 'inbound' or 'outbound'
  status TEXT DEFAULT 'pending',                 -- 'pending', 'sent', 'delivered', 'read', 'failed'

  -- Meta integration
  meta_message_id TEXT,                          -- Message ID from Meta API
  meta_response JSONB,                           -- Response from Meta API (errors, etc)

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes
CREATE INDEX idx_messages_conversation ON whatsapp_messages(conversation_id);
CREATE INDEX idx_messages_phone ON whatsapp_messages(phone);
CREATE INDEX idx_messages_created ON whatsapp_messages(created_at DESC);
```

### Example Inbound Message

```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "conversation_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "phone": "393331234567",
  "content": "Vorrei ordinare un profumo Chanel",
  "type": "text",
  "direction": "inbound",
  "status": "pending",
  "meta_message_id": "wamid.HBEUFxxxxxxxxxx",
  "meta_response": null,
  "created_at": "2026-02-26T10:30:00Z",
  "updated_at": "2026-02-26T10:30:00Z"
}
```

### Example Outbound Message (from Bot)

```json
{
  "id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
  "conversation_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "phone": "393331234567",
  "content": "Perfetto! Ho il Chanel No.5 disponibile. Prezzo: €85,00. Confermo l'ordine?",
  "type": "text",
  "direction": "outbound",
  "status": "sent",
  "meta_message_id": "wamid.HBEUFxxxxxxxxxx",
  "meta_response": {
    "messaging_product": "whatsapp",
    "contacts": [{ "wa_id": "393331234567" }],
    "messages": [{ "id": "wamid.HBEUFxxxxxxxxxx" }]
  },
  "created_at": "2026-02-26T10:30:02Z",
  "updated_at": "2026-02-26T10:30:02Z"
}
```

## Table 3: whatsapp_order_relays

Tracks orders initiated via WhatsApp.

```sql
CREATE TABLE whatsapp_order_relays (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Foreign keys
  conversation_id UUID REFERENCES whatsapp_conversations(id) ON DELETE SET NULL,
  phone TEXT NOT NULL,                           -- Customer phone

  -- Order data
  order_data JSONB NOT NULL,                     -- Full order details
  products JSONB[] DEFAULT ARRAY[]::JSONB[],    -- Array of product items
  total_price NUMERIC(10,2),                     -- Total order price

  -- Status
  status TEXT DEFAULT 'pending',                 -- 'pending', 'confirmed', 'created', 'failed'

  -- Integration
  market_order_id UUID,                          -- Order ID in market_orders table (when created)

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes
CREATE INDEX idx_relays_conversation ON whatsapp_order_relays(conversation_id);
CREATE INDEX idx_relays_status ON whatsapp_order_relays(status);
```

### Example Row

```json
{
  "id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
  "conversation_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "phone": "393331234567",
  "order_data": {
    "customer_name": "Mario Rossi",
    "customer_phone": "393331234567",
    "delivery_address": "Via Roma 123, Milano",
    "notes": "Consegnare entro le 18:00",
    "preferred_time": "16:00-18:00"
  },
  "products": [
    {
      "id": "prod-123",
      "name": "Chanel No.5",
      "quantity": 2,
      "price_per_unit": 85.00,
      "total": 170.00
    },
    {
      "id": "prod-456",
      "name": "Dior J'adore",
      "quantity": 1,
      "price_per_unit": 95.00,
      "total": 95.00
    }
  ],
  "total_price": 265.00,
  "status": "confirmed",
  "market_order_id": "order-uuid-12345",
  "created_at": "2026-02-26T10:31:00Z",
  "updated_at": "2026-02-26T10:32:00Z"
}
```

## Row Level Security (RLS)

All tables have RLS enabled to control access:

```sql
-- Allow authenticated users to read
CREATE POLICY "Enable read for authenticated users" ON whatsapp_messages
  FOR SELECT USING (auth.role() = 'authenticated');

-- Allow service role (Edge Functions) to do everything
CREATE POLICY "Enable all for service role" ON whatsapp_messages
  FOR ALL USING (auth.role() = 'service_role');
```

**Access Levels**:
- `anon` (anonymous API calls): Read only via `whatsapp-simulate`
- `authenticated` (logged-in users): Can read messages, create orders
- `service_role` (Edge Functions): Full access (read/write/delete)

## Realtime Subscriptions

Enable Realtime for live updates:

```sql
ALTER PUBLICATION supabase_realtime ADD TABLE whatsapp_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE whatsapp_conversations;
```

This allows:
- Support dashboard to see messages in real-time
- Rider app to get notifications
- Admin panel to monitor conversations

## Query Examples

### Get Recent Messages for Phone

```sql
SELECT * FROM whatsapp_messages
WHERE phone = '393331234567'
ORDER BY created_at DESC
LIMIT 20;
```

### Get Conversation with Latest Messages

```sql
SELECT
  c.id,
  c.phone,
  c.conversation_type,
  c.message_count,
  c.last_message_at,
  (SELECT JSON_AGG(row_to_json(m))
   FROM (SELECT * FROM whatsapp_messages
         WHERE conversation_id = c.id
         ORDER BY created_at DESC
         LIMIT 5) m
  ) AS recent_messages
FROM whatsapp_conversations c
WHERE c.phone = '393331234567';
```

### Get Pending Orders

```sql
SELECT * FROM whatsapp_order_relays
WHERE status IN ('pending', 'confirmed')
AND created_at > NOW() - INTERVAL '1 day'
ORDER BY created_at DESC;
```

### Get Message Statistics

```sql
SELECT
  DATE(created_at) as date,
  direction,
  status,
  COUNT(*) as count,
  AVG(EXTRACT(EPOCH FROM (updated_at - created_at))) as avg_processing_time_sec
FROM whatsapp_messages
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY DATE(created_at), direction, status
ORDER BY date DESC, direction, status;
```

### Get Conversations by Type

```sql
SELECT
  conversation_type,
  COUNT(*) as total,
  AVG(message_count) as avg_messages,
  MAX(last_message_at) as last_activity
FROM whatsapp_conversations
WHERE created_at > NOW() - INTERVAL '30 days'
GROUP BY conversation_type;
```

## Data Types Reference

| Type | Example | Use |
|------|---------|-----|
| `UUID` | `f47ac10b-58cc-4372-a567-0e02b2c3d479` | Unique IDs |
| `TEXT` | `"393331234567"` | Text fields |
| `JSONB` | `{"key": "value"}` | Nested data |
| `JSONB[]` | `[{...}, {...}]` | Arrays of objects |
| `INT` | `15` | Counts |
| `NUMERIC(10,2)` | `85.50` | Prices |
| `TIMESTAMPTZ` | `2026-02-26T10:30:00Z` | Timestamps |

## Migrations / Schema Changes

### Add New Column

```sql
ALTER TABLE whatsapp_messages ADD COLUMN sentiment TEXT;
CREATE INDEX idx_messages_sentiment ON whatsapp_messages(sentiment);
```

### Add Constraint

```sql
ALTER TABLE whatsapp_conversations
ADD CONSTRAINT valid_type CHECK (conversation_type IN ('customer', 'dealer'));
```

### Create View

```sql
CREATE VIEW active_conversations AS
SELECT * FROM whatsapp_conversations
WHERE last_message_at > NOW() - INTERVAL '24 hours'
ORDER BY last_message_at DESC;
```

## Performance Tips

1. **Indexes**: Keep indexes on frequently queried columns
2. **Partitioning**: For millions of messages, partition by date
3. **Archiving**: Move old messages to cold storage after 90 days
4. **Connection Pooling**: Enable in Supabase for high load
5. **Batch Operations**: Insert multiple messages at once when possible

---

**Last Updated**: 2026-02-26
**Status**: Production schema
**Tables**: 3 (conversations, messages, order_relays)
