# Supabase Setup Guide

## Project Setup

### 1. Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Sign up / Log in
3. Create new project:
   - Name: `dloop-rider-prototype`
   - Database password: Save securely
   - Region: `eu-central-1` (or closest to users)
   - Plan: `Pro` (for production)
4. Wait 2-3 minutes for project to initialize

### 2. Get Connection Details

1. Go to **Project Settings** → **Database**
2. Copy:
   - **Host**: `db.aqpwfurradxbnqvycvkm.supabase.co`
   - **Database**: `postgres`
   - **Port**: `5432`
   - **Username**: `postgres`
   - **Password**: (what you set above)
3. Construct `DB_URL`:
   ```
   postgresql://postgres:PASSWORD@db.aqpwfurradxbnqvycvkm.supabase.co:5432/postgres
   ```

### 3. Get API Keys

1. Go to **Settings** → **API**
2. Under Project API Keys, copy:
   - **anon public**: `sb_publishable_NBWU-byCV0TIsj5-8Mixog_CEV7IkrB`
     - This is `DB_ANON_KEY`
   - **service_role secret**: `eyJhbGciOiJIUzI1NiIsInR...` (very long)
     - This is `DB_ROLE_KEY`
3. Save these securely

## Database Schema Setup

### 1. Create WhatsApp Tables

Go to **SQL Editor** and run this script:

```sql
-- ==================================================
-- WhatsApp Conversations Table
-- ==================================================
CREATE TABLE IF NOT EXISTS whatsapp_conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone TEXT NOT NULL UNIQUE,
  conversation_type TEXT NOT NULL CHECK (conversation_type IN ('customer', 'dealer')),
  context JSONB DEFAULT '{}',
  message_count INT DEFAULT 0,
  last_message_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_conversations_phone ON whatsapp_conversations(phone);
CREATE INDEX idx_conversations_type ON whatsapp_conversations(conversation_type);

-- ==================================================
-- WhatsApp Messages Table
-- ==================================================
CREATE TABLE IF NOT EXISTS whatsapp_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES whatsapp_conversations(id) ON DELETE CASCADE,
  phone TEXT NOT NULL,
  direction TEXT NOT NULL CHECK (direction IN ('inbound', 'outbound')),
  content TEXT NOT NULL,
  type TEXT DEFAULT 'text' CHECK (type IN ('text', 'image', 'audio', 'document')),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'delivered', 'read', 'failed')),
  meta_message_id TEXT,
  meta_response JSONB,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_messages_conversation ON whatsapp_messages(conversation_id);
CREATE INDEX idx_messages_phone ON whatsapp_messages(phone);
CREATE INDEX idx_messages_created ON whatsapp_messages(created_at DESC);

-- ==================================================
-- WhatsApp Order Relays Table
-- ==================================================
CREATE TABLE IF NOT EXISTS whatsapp_order_relays (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID REFERENCES whatsapp_conversations(id) ON DELETE SET NULL,
  phone TEXT NOT NULL,
  order_data JSONB NOT NULL,
  products JSONB[] DEFAULT ARRAY[]::JSONB[],
  total_price NUMERIC(10,2),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'created', 'failed')),
  market_order_id UUID,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_relays_conversation ON whatsapp_order_relays(conversation_id);
CREATE INDEX idx_relays_status ON whatsapp_order_relays(status);
```

### 2. Enable Row Level Security (RLS)

```sql
-- Enable RLS on all tables
ALTER TABLE whatsapp_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE whatsapp_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE whatsapp_order_relays ENABLE ROW LEVEL SECURITY;

-- Create policy: authenticated users can read
CREATE POLICY "Enable read for authenticated users" ON whatsapp_conversations
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Enable read for authenticated users" ON whatsapp_messages
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Enable read for authenticated users" ON whatsapp_order_relays
  FOR SELECT USING (auth.role() = 'authenticated');

-- Create policy: service role (functions) can do everything
CREATE POLICY "Enable all for service role" ON whatsapp_conversations
  FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Enable all for service role" ON whatsapp_messages
  FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Enable all for service role" ON whatsapp_order_relays
  FOR ALL USING (auth.role() = 'service_role');
```

### 3. Enable Realtime (Optional)

To see live messages in your dashboard:

```sql
ALTER PUBLICATION supabase_realtime ADD TABLE whatsapp_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE whatsapp_conversations;
```

## Deploy Edge Functions

### 1. Via Supabase Dashboard

1. Go to **Edge Functions**
2. For each function, copy code from `supabase/functions/[name]/index.ts`
3. Create new function or upload

### 2. Via CLI (Recommended)

```bash
# Install CLI
npm install -g supabase

# Login
supabase login

# Link project
supabase link --project-ref aqpwfurradxbnqvycvkm

# Deploy functions
supabase functions deploy whatsapp-webhook
supabase functions deploy whatsapp-simulate
supabase functions deploy whatsapp-webhook-v2
supabase functions deploy whatsapp-test-webhook

# Verify
supabase functions list
```

## Add Secrets

### Via CLI:
```bash
supabase secrets set DB_URL="postgresql://postgres:PASSWORD@db.xxx.supabase.co:5432/postgres"
supabase secrets set DB_ANON_KEY="sb_publishable_..."
supabase secrets set DB_ROLE_KEY="eyJ..."
supabase secrets set OPENAI_API_KEY="sk-proj-..."
supabase secrets set WHATSAPP_PHONE_NUMBER_ID="979991158533832"
supabase secrets set WHATSAPP_ACCESS_TOKEN="EAAXXXXX..."
```

### Via Dashboard:

1. **Settings** → scroll down to **Secrets**
2. Click **Add new secret**
3. For each:
   - Key: (from above)
   - Value: (from above)
4. Click **Add secret**

### Verify Secrets

```bash
supabase secrets list
```

Should show all secrets (values hidden).

## Enable Extensions (if needed)

```sql
-- UUID support
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- pgvector (for embeddings, optional)
CREATE EXTENSION IF NOT EXISTS "vector";

-- HTTP client (for external APIs)
CREATE EXTENSION IF NOT EXISTS "http";
```

## Configure Network

### 1. Allow Supabase Functions to Connect to Database

1. Go to **Settings** → **Network**
2. Under "Database", should see:
   - Direct connections: Allowed
   - Via functions: Allowed

### 2. Set Up Database Connection Pooling (Optional)

For high-volume deployments:

1. Go to **Database** → **Connection Pooling**
2. Set:
   - **Mode**: Transaction (recommended)
   - **Min pool size**: 5
   - **Max pool size**: 20

## Test Connection

```bash
# From CLI
psql postgresql://postgres:PASSWORD@db.aqpwfurradxbnqvycvkm.supabase.co:5432/postgres

# Should connect successfully
# Test query:
SELECT version();

# Exit with: \q
```

## Complete Supabase Setup Checklist

- [ ] Project created
- [ ] Database password saved securely
- [ ] DB_URL constructed
- [ ] DB_ANON_KEY copied
- [ ] DB_ROLE_KEY copied
- [ ] WhatsApp tables created
- [ ] RLS policies applied
- [ ] Edge functions deployed:
  - [ ] whatsapp-webhook
  - [ ] whatsapp-simulate
  - [ ] whatsapp-webhook-v2
  - [ ] whatsapp-test-webhook
- [ ] All secrets added:
  - [ ] DB_URL
  - [ ] DB_ANON_KEY
  - [ ] DB_ROLE_KEY
  - [ ] OPENAI_API_KEY
  - [ ] WHATSAPP_PHONE_NUMBER_ID
  - [ ] WHATSAPP_ACCESS_TOKEN
- [ ] Realtime enabled (optional)
- [ ] Network configured
- [ ] Database connection tested

## Monitoring & Maintenance

### View Function Logs

1. Go to **Edge Functions** → **whatsapp-webhook**
2. Click **Logs** tab
3. Filter by:
   - Date range
   - Execution status (success/error)
   - Search text

### Monitor Database

1. Go to **Database** → **Statistics**
2. Check:
   - Connection count
   - Query performance
   - Storage usage

### Manage Usage

1. Go to **Settings** → **Billing**
2. View:
   - Edge Function executions
   - Database operations
   - Storage usage
3. Set billing alerts if desired

## Scaling Considerations

### For 1000+ daily active users:

1. Upgrade to **Pro** or **Team** plan
2. Enable database connection pooling
3. Create indexes on frequently queried columns
4. Archive old messages to cold storage (optional)
5. Set up automated backups

### For 10000+ daily active users:

1. Upgrade to **Team** plan
2. Consider dedicated database
3. Implement message caching (Redis)
4. Batch OpenAI requests
5. Hire Supabase consulting

## Reference

- [Supabase Documentation](https://supabase.com/docs)
- [Edge Functions Guide](https://supabase.com/docs/guides/functions)
- [Database Guide](https://supabase.com/docs/guides/database)
- [Auth & RLS](https://supabase.com/docs/guides/auth/row-level-security)

---

**Last Updated**: 2026-02-26
**Project Ref**: `aqpwfurradxbnqvycvkm`
