# WhatsApp Webhook Flow Diagram

## Current Situation: Message Received, But No Response

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  User sends WhatsApp to +39 328 185 4639                       │
│                                                                 │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       v
┌─────────────────────────────────────────────────────────────────┐
│  Meta WhatsApp Cloud API                                        │
│  • Receives message                                              │
│  • Formats as JSON                                               │
│  • Sends to webhook URL                                          │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       v
┌─────────────────────────────────────────────────────────────────┐
│  WEBHOOK ENDPOINT ✅ WORKING                                    │
│  https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/         │
│  whatsapp-webhook                                               │
│                                                                 │
│  File: supabase/functions/whatsapp-webhook/index.ts             │
│                                                                 │
│  ✅ Receives POST request                                       │
│  ✅ Parses JSON payload                                         │
│  ✅ Extracts phone, text, name                                  │
│  ✅ Returns HTTP 200 "OK" immediately                           │
│                                                                 │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ├─────────────────────────────────────────┐
                       │                                         │
          (returns to Meta)                    (async in background)
                       │                                         │
                       v                                         v
              HTTP 200 OK                  ┌──────────────────────────┐
                       │                   │ ASYNC PROCESSING START   │
                       │                   └─────────┬────────────────┘
                       │                             │
                       │                             v
                       │                  ✅ Parse message
                       │                  ✅ Save to DB
                       │                  ✅ Fetch conversation
                       │                  ✅ Build system prompt
                       │                             │
                       │                             v
                       │                  ┌──────────────────────────┐
                       │                  │ CALL CHATGPT (OpenAI)    │
                       │                  │                          │
                       │                  │ File: _shared/openai.ts  │
                       │                  │ Function: chatCompletion │
                       │                  │                          │
                       │                  │ Uses secret:             │
                       │                  │ OPENAI_API_KEY           │
                       │                  │                          │
                       │                  │ ❌ KEY IS INVALID/       │
                       │                  │    EXPIRED               │
                       │                  └─────────┬────────────────┘
                       │                             │
                       │                             v
                       │                  ❌ FAILURE: 401 Unauthorized
                       │                             │
                       │                             v
                       │                  ❌ "Incorrect API key"
                       │                             │
                       │                             v
                       │                  ❌ Error caught & logged
                       │                  ❌ No response generated
                       │                             │
                       │                             v
                       │                  ❌ sendMetaMessage() NOT called
                       │                             │
                       │                             v
                       └─────────────────────► User gets NO RESPONSE
                                               ❌ Silent failure
                                               ❌ No feedback
                                               ❌ Looks broken
```

## Expected Flow After Fix (When API Key is Valid)

```
┌──────────────────────┐
│  User WhatsApp       │
│  "Ho bisogno di      │
│   una maglietta"     │
└──────────┬───────────┘
           │
           v
┌──────────────────────────────────┐
│  Meta WhatsApp → Webhook ✅      │
└──────────┬───────────────────────┘
           │
           v
┌──────────────────────────────────┐
│  Webhook returns 200 OK ✅       │
│  (tells Meta: received OK)       │
└──────────┬───────────────────────┘
           │
           ├─────────────────────────┐
           │ (ASYNC)                 │
           v                         v
        To Meta                Parse & Process
                               ✅ Save message to DB
                               ✅ Fetch conversation
                               ✅ Build system prompt
                                       │
                                       v
                               ✅ Call OpenAI ChatGPT
                               ✅ API key is VALID
                                       │
                                       v
                               ✅ ChatGPT generates response
                               ✅ "👔 YAMAMAY ha magliette!"
                                       │
                                       v
                               ✅ Send via Meta API
                               ✅ WHATSAPP_ACCESS_TOKEN valid
                                       │
                                       v
                               ✅ Save response to DB
                                       │
                                       v
                ┌──────────────────────┘
                │
                v
        ┌───────────────────────────┐
        │ User receives bot response │
        │ in WhatsApp (2-5 seconds) │
        └───────────────────────────┘
```

## Component Status Breakdown

### Phase 1: Message Reception (✅ All Working)
```
Meta API
  └─> POST to webhook
      └─> index.ts receives request ✅
          └─> Parses JSON ✅
              └─> Returns 200 OK ✅
```

### Phase 2: Database (✅ All Working)
```
Async Processing
  └─> Save to whatsapp_conversations ✅
      └─> Save to whatsapp_messages ✅
          └─> Query history ✅
```

### Phase 3: ChatGPT Processing (❌ BROKEN)
```
OpenAI Integration
  └─> Get OPENAI_API_KEY secret
      └─> INVALID/EXPIRED ❌
          └─> OpenAI returns 401 ❌
              └─> Error caught ❌
                  └─> No response ❌
```

### Phase 4: Message Response (❌ Blocked by Phase 3)
```
Send Response
  └─> Cannot execute (blocked by ChatGPT failure)
      └─> User sees nothing ❌
```

## Files in Flow

| Component | File | Status | Issue |
|-----------|------|--------|-------|
| Entry | `whatsapp-webhook/index.ts` | ✅ | None |
| Parse | `whatsapp-webhook/index.ts:42` | ✅ | None |
| Save DB | `whatsapp-webhook/processor.ts:103-111` | ✅ | None |
| System Prompt | `whatsapp-webhook/processor.ts:135-138` | ✅ | None |
| OpenAI Call | `_shared/openai.ts:50-77` | ❌ | Invalid key |
| OpenAI Secret | `_shared/openai.ts:4` | ❌ | **EXPIRED** |
| Response Send | `whatsapp-webhook/processor.ts:198` | ❌ | Blocked |
| Save Response | `whatsapp-webhook/processor.ts:201-210` | ❌ | Blocked |

## Testing Points

```
1. Webhook GET (verify)
   ✅ curl "...whatsapp-webhook?hub.challenge=test&hub.verify_token=dloop_wa_verify_2026"
   Returns: test

2. Webhook POST (receive)
   ✅ curl -X POST "...whatsapp-webhook" -d '{...meta json...}'
   Returns: 200 OK

3. Simulate Function (process)
   ❌ curl -X POST "...whatsapp-simulate" -d '{"phone":"+39...","text":"..."}'
   Returns: OpenAI API error 401 ❌
   Should return: ChatGPT response ✅

4. Database Check
   ✅ SELECT * FROM whatsapp_conversations
   May have entries IF API key was ever valid

5. Real WhatsApp
   ❌ Send message to +39 328 185 4639
   Result: No response ❌
   Expected: Bot response in 2-5 sec ✅
```

## Secrets Configuration

```
Supabase Project: aqpwfurradxbnqvycvkm

Required Secrets:
┌─────────────────────────────────────────┐
│ OPENAI_API_KEY                          │
│ Current: sk-proj-****... (INVALID) ❌   │
│ Needed: Valid key from OpenAI           │
│ Fix: supabase secrets set OPENAI_...    │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ WHATSAPP_ACCESS_TOKEN                   │
│ Current: EAAVfoVVjNTUBQ... (?)          │
│ Status: Need to verify after API fix    │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ WHATSAPP_PHONE_NUMBER_ID                │
│ Current: 979991158533832 ✅             │
│ Status: Correct                         │
└─────────────────────────────────────────┘
```

## The Fix

```
Step 1: Get new OpenAI API key
        https://platform.openai.com/account/api-keys
        Copy: sk-proj-...

Step 2: Update secret
        supabase secrets set OPENAI_API_KEY="sk-proj-..."

Step 3: Test
        curl -X POST ...whatsapp-simulate...
        Should return ChatGPT response ✅

Step 4: Verify
        Send real WhatsApp message
        Bot responds in 2-5 seconds ✅
```

## Success Indicators

- [ ] whatsapp-simulate returns ChatGPT response
- [ ] No 401 errors in Supabase logs
- [ ] whatsapp_messages table has new entries
- [ ] Real WhatsApp bot responds within 2-5 seconds
- [ ] Response is in Italian and relevant to message
- [ ] Dealer pilots can chat with bot
