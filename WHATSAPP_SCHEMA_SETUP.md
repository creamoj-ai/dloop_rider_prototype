# ⚠️ CRITICAL: WhatsApp Bot Schema Setup

## Problem Found
**The WhatsApp database tables were never created!**

The diagnostic revealed:
- ❌ `whatsapp_conversations` table missing
- ❌ `whatsapp_messages` table missing
- ❌ `whatsapp_order_relays` table missing
- ❌ `rider_contacts` needs WhatsApp contact_value column

This is why the bot receives messages but can't process them - the webhook tries to save data to non-existent tables and crashes.

---

## ✅ Quick Fix (2 minutes)

### 1. Open Supabase SQL Editor
Navigate to: https://supabase.com/dashboard/project/imhjdsjtaommutdmkouf/sql/new

### 2. Copy SQL Script
Open: `sql/42_create_whatsapp_bot_schema.sql`
Copy ALL content

### 3. Paste & Run
- Paste into SQL Editor
- Click **RUN** button
- Wait for success message

### 4. Verify
Run this query to confirm tables exist:
```sql
SELECT tablename FROM pg_catalog.pg_tables
WHERE schemaname = 'public'
AND tablename LIKE 'whatsapp%'
ORDER BY tablename;
```

Should return:
- ✅ whatsapp_conversations
- ✅ whatsapp_messages
- ✅ whatsapp_order_relays

---

## 🎯 What Gets Created

### `whatsapp_conversations`
Tracks each customer/dealer conversation:
- `phone`: Customer phone number (unique)
- `conversation_type`: 'customer' or 'dealer'
- `state`: idle/ordering/confirming/tracking/support
- `context`: JSON state machine data
- `message_count`: Total messages in conversation

### `whatsapp_messages`
Individual messages with full tracking:
- `direction`: 'inbound' or 'outbound'
- `status`: sent/delivered/read/failed
- `tokens_used`: ChatGPT API tokens
- `wa_message_id`: Meta message ID for status updates
- `meta_response`: Error details if failed

### `whatsapp_order_relays`
Dealer → Customer order pipeline:
- `status`: pending/confirmed/declined/preparing/ready/picked_up
- `products`: JSON array of ordered items
- `total_price`: Order total

---

## 🔄 After Schema Creation

### 1. Test Schema
```bash
node diagnose-bot.js
```
Should now show:
- ✅ Database connectivity
- ✅ No inbound messages (not received yet)
- ✅ No outbound messages (not sent yet)
- ✅ Webhook endpoint working

### 2. Send Test Messages
Send test messages to bot: **+39 328 1854639**
```
"Ciao, mi servono prodotti"
"OK" (if you're a dealer)
```

### 3. Check Messages in DB
Run: `node check-messages.js`
Should show recent inbound/outbound messages

### 4. If Still Not Working
Check Supabase function logs:
https://supabase.com/dashboard/project/imhjdsjtaommutdmkouf/functions

---

## ⚡ Troubleshooting

| Error | Solution |
|-------|----------|
| `relation "whatsapp_messages" does not exist` | Run SQL script again, click RUN button |
| Messages still not in DB | Check Supabase function logs for errors |
| Bot doesn't respond to messages | Verify webhook URL in Meta Business Account |
| `FOREIGN KEY constraint failed` | Ensure `riders` table has test data |

---

## 📝 Notes

- Tables have RLS enabled (only service_role can access)
- Webhook uses `service_role` client for full access
- All messages indexed for fast queries
- Realtime enabled for live conversation updates
- Triggers auto-update conversation message_count

