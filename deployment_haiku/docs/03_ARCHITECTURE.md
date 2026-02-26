# WhatsApp Bot Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     WHATSAPP BOT MVP ARCHITECTURE              │
└─────────────────────────────────────────────────────────────────┘

  WhatsApp User              Meta Cloud              Dloop Backend
       │                        │                           │
       ├─ Send Message ────────>│                           │
       │                        │                           │
       │                    [Webhook]                       │
       │                        │                           │
       │                        ├─ POST ─────────────────>  Webhook Function
       │                        │                           │
       │                        │                      [Processing]
       │                        │                           │
       │                        │                      [NLU Routing]
       │                        │                           │
       │                        │                      [ChatGPT Call]
       │                        │                           │
       │                        │                      [DB Storage]
       │                        │                           │
       │                        │                      [WhatsApp API]
       │                        │                           │
       │                    [API Call]                       │
       │<────────────────────────────────────────────────────┤
       │                  Receive Response
       │
```

## Components

### 1. Message Ingestion
- **whatsapp-webhook** (Primary): POST endpoint receiving Meta webhooks
- **whatsapp-simulate**: Test endpoint for development
- **whatsapp-webhook-v2**: Fallback processor
- **whatsapp-test-webhook**: Internal test runner

**Flow**:
```
Meta Webhook POST
    ↓
Verify signature (if configured)
    ↓
Parse message payload
    ↓
Route to processor (dealer or customer)
    ↓
Process asynchronously
```

### 2. Message Processing Pipeline

#### Customer Pipeline
```
Inbound Message
    ↓
Extract text/media
    ↓
Normalize phone
    ↓
Find or create conversation
    ↓
[NLU Classification]
    ├─ order_request
    ├─ product_inquiry
    ├─ support_request
    └─ general_chat
    ↓
[Intent-Specific Processing]
    ├─ order_request → Parse cart → Match products → OpenAI confirm
    ├─ product_inquiry → Semantic search → OpenAI suggest
    ├─ support_request → Escalate to humans
    └─ general_chat → OpenAI respond
    ↓
Store in database
    ↓
Send via WhatsApp API
```

#### Dealer Pipeline
```
Inbound Message (from dealer contact)
    ↓
Identify dealer (via rider_contacts)
    ↓
Check order status / inventory
    ↓
Generate response
    ↓
Store in database
    ↓
Send via WhatsApp API
```

### 3. AI Integration (OpenAI/ChatGPT)

**Model**: `gpt-3.5-turbo`

**System Prompt**: Italian-friendly customer service assistant
```
Tu sei un assistente di servizio clienti amichevole per Dloop.
- Rispondi in italiano
- Sii cordiale e utile
- Classifica richieste (ordine, prodotto, supporto)
- Estrai prodotti dalle richieste
- Conferma ordini in modo naturale
```

**Input Format**:
```json
{
  "messages": [
    { "role": "system", "content": "..." },
    { "role": "user", "content": "Vorrei ordinare un profumo" }
  ],
  "temperature": 0.7,
  "max_tokens": 150
}
```

### 4. Database Schema

```sql
-- Conversations (one per phone)
whatsapp_conversations {
  id: UUID
  phone: TEXT (normalized)
  conversation_type: TEXT (customer | dealer)
  context: JSONB (conversation history)
  message_count: INT
  last_message_at: TIMESTAMPTZ
  updated_at: TIMESTAMPTZ
}

-- Messages (all inbound/outbound)
whatsapp_messages {
  id: UUID
  conversation_id: UUID (FK)
  phone: TEXT
  direction: TEXT (inbound | outbound)
  content: TEXT
  type: TEXT (text | image | audio | document)
  status: TEXT (pending | sent | delivered | read | failed)
  meta_message_id: TEXT
  meta_response: JSONB
  created_at: TIMESTAMPTZ
}

-- Order Pipeline
whatsapp_order_relays {
  id: UUID
  conversation_id: UUID
  phone: TEXT
  order_data: JSONB
  products: JSONB[]
  total_price: NUMERIC
  status: TEXT (pending | confirmed | created | failed)
  market_order_id: UUID (when created)
  created_at: TIMESTAMPTZ
}
```

### 5. Routing Logic

**Phone-based Routing**:
```
Incoming message from phone +39XXX
    ↓
Is phone in rider_contacts with contact_type='dealer'?
    ├─ YES → Route to dealer_processor
    └─ NO → Route to customer_processor
```

**Dealer Identification** (via `rider_contacts` table):
```json
{
  "id": "uuid",
  "rider_id": "uuid",
  "contact_type": "dealer",
  "contact_value": "+39328185464",
  "name": "Toelettatura Pet",
  "category": "pets"
}
```

### 6. Error Handling

**Retry Logic**:
```
ChatGPT Error
    ↓
Retry with exponential backoff (3 attempts)
    ↓
Log error to database
    ↓
Queue for manual review
```

**Fallback Responses**:
```
If ChatGPT fails:
  → "Mi scusi, non ho potuto elaborare. Riprova tra poco."

If DB fails:
  → "Errore di connessione. Il supporto verrà contattato."

If WhatsApp API fails:
  → Message stored as "failed", escalated to support
```

### 7. Real-time Features

**Supabase Realtime** (optional):
- Subscribe to `whatsapp_messages` for live updates
- Support dashboard sees responses in real-time
- Dealer app receives notifications

**FCM Notifications** (via `whatsapp-notify`):
- Alert rider when order received via WhatsApp
- Notify support of failed messages
- Send delivery confirmations

## Data Flow Diagram

```
Customer Message
    ↓
[whatsapp-webhook]
    ├─ Parse Meta payload
    ├─ Normalize phone
    └─ Pass to processor
    ↓
[processInboundMessage]
    ├─ Find/create conversation
    ├─ Store inbound message
    └─ Call OpenAI
    ↓
[OpenAI API]
    ├─ Generate response
    └─ Return text
    ↓
[whatsapp_messages insert]
    ├─ Store outbound message
    └─ Set status="sent"
    ↓
[WhatsApp Cloud API]
    ├─ Send message
    └─ Receive delivery status
    ↓
[whatsapp_messages update]
    └─ Update status (delivered/failed)
    ↓
Customer Receives Response
```

## Performance Targets

| Metric | Target | Current |
|--------|--------|---------|
| Webhook latency | <2s | ~1.5s |
| ChatGPT response time | <5s | ~4s |
| Total E2E latency | <8s | ~6s |
| Database queries/sec | 100+ | ~10 |
| Error rate | <1% | TBD |
| Uptime | 99%+ | TBD |

## Security Considerations

1. **Secrets Management**: All credentials in Supabase secrets
2. **JWT Verification**: Webhook validates Meta signatures
3. **Rate Limiting**: Per-phone rate limits (10 msgs/min)
4. **Data Privacy**: No personally identifiable info logged
5. **Database Access**: RLS policies restrict data access

## Scalability

**Current capacity**: 100 concurrent conversations
**Bottleneck**: ChatGPT API rate limits (3,500 RPM)
**Optimization**: Message batching, caching common responses

---

**Last Updated**: 2026-02-26
**Status**: Production-ready
