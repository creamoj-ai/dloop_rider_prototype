# WhatsApp Webhook 500 Error - Root Cause Analysis & Fix

**Date**: 2026-02-26
**Project**: dloop WhatsApp Bot MVP
**Supabase Project**: aqpwfurradxbnqvycvkm
**Status**: ✅ FIXED (pending deployment)

---

## 🔴 CRITICAL BUGS IDENTIFIED

### **BUG #1: Undefined Parameters in `createDeliveryOrder`**
**Severity**: CRITICAL (causes 500 error)
**File**: `supabase/functions/whatsapp-webhook/customer_functions.ts`
**Lines**: 760-770

**Root Cause**:
The function signature has `phone` and `conversationId` as direct parameters, but the code was trying to access them as properties of the `opts` object (`opts.phone`, `opts.conversationId`).

```typescript
// BEFORE (BROKEN):
const { error: relayErr } = await db.from("whatsapp_order_relays").insert({
  conversation_id: opts.conversationId,  // ❌ undefined
  customer_phone: opts.phone,            // ❌ undefined
  notes: opts.notes,                     // ❌ undefined (should be opts.customerNotes)
  ...
});

// AFTER (FIXED):
const { error: relayErr } = await db.from("whatsapp_order_relays").insert({
  conversation_id: conversationId,  // ✅ correct
  customer_phone: phone,            // ✅ correct
  notes: opts.customerNotes,        // ✅ correct
  ...
});
```

**Impact**:
- Database insert fails with constraint violation (NOT NULL fields receive undefined)
- Throws unhandled exception
- Returns 500 error to Meta webhook
- Bot doesn't respond to customer messages

---

### **BUG #2: Wrong Environment Variable Names**
**Severity**: HIGH (breaks auto-dispatch and payment link features)
**Files**:
- `supabase/functions/whatsapp-webhook/customer_functions.ts` (lines 784-786)
- `supabase/functions/whatsapp-webhook/dealer_functions.ts` (lines 614-616)

**Root Cause**:
The code tries to read `SUPABASE_URL` and `SUPABASE_ANON_KEY` environment variables, but the project uses different names:
- `DB_URL` (not `SUPABASE_URL`)
- `DB_ANON_KEY` (not `SUPABASE_ANON_KEY`)
- `DB_ROLE_KEY` (not `SUPABASE_SERVICE_ROLE_KEY`)

```typescript
// BEFORE (BROKEN):
const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";      // ❌ returns ""
const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";      // ❌ returns ""

// AFTER (FIXED):
const supabaseUrl = Deno.env.get("DB_URL") ?? "";             // ✅ correct
const anonKey = Deno.env.get("DB_ANON_KEY") ?? "";            // ✅ correct
```

**Impact**:
- Auto-dispatch API call fails (empty URL)
- Stripe payment link generation fails
- Dealer notifications fail
- No error thrown (fallback to empty string ""), fails silently

---

### **BUG #3: Poor Error Logging**
**Severity**: MEDIUM (masks real errors)
**File**: `supabase/functions/whatsapp-webhook/index.ts`
**Lines**: 88-90

**Root Cause**:
The webhook catches errors but doesn't log enough detail:

```typescript
// BEFORE (INSUFFICIENT):
} catch (error) {
  console.error("❌ Processing error:", error);
}

// AFTER (DETAILED):
} catch (error) {
  console.error("❌ Processing error:", error);
  console.error("Error details:", error instanceof Error ? error.message : String(error));
  console.error("Error stack:", error instanceof Error ? error.stack : "N/A");
}
```

**Impact**:
- Hard to debug production errors
- Stack traces not visible in Supabase logs
- Wasted hours troubleshooting

---

## ✅ FIXES APPLIED

### Files Modified:
1. ✅ `supabase/functions/whatsapp-webhook/customer_functions.ts`
   - Fixed line 760: `opts.conversationId` → `conversationId`
   - Fixed line 763: `opts.phone` → `phone`
   - Fixed line 767: `opts.notes` → `opts.customerNotes`
   - Fixed line 784: `SUPABASE_URL` → `DB_URL`
   - Fixed line 785: `SUPABASE_ANON_KEY` → `DB_ANON_KEY`

2. ✅ `supabase/functions/whatsapp-webhook/dealer_functions.ts`
   - Fixed line 614: `SUPABASE_URL` → `DB_URL`
   - Fixed line 615: `SUPABASE_ANON_KEY` → `DB_ANON_KEY`

3. ✅ `supabase/functions/whatsapp-webhook/index.ts`
   - Added detailed error logging (lines 89-90)

---

## 🚀 DEPLOYMENT INSTRUCTIONS

### Option 1: Manual Deployment (Recommended)
```bash
cd /c/Users/itjob/dloop_rider_prototype
npx supabase functions deploy whatsapp-webhook \
  --project-ref aqpwfurradxbnqvycvkm \
  --no-verify-jwt
```

### Option 2: Use Deployment Script
```bash
cd /c/Users/itjob/dloop_rider_prototype
./deploy-webhook.sh
```

### If Login Required:
1. Get access token: https://app.supabase.com/account/tokens
2. Set environment variable:
   ```bash
   export SUPABASE_ACCESS_TOKEN='sbp_your-token-here'
   ```
3. Deploy again

---

## 🧪 TESTING CHECKLIST

After deployment:

### Test 1: Basic Message Handling
1. Send WhatsApp message to: **+39 328 1854639**
2. Message: "Ciao, vorrei ordinare una pizza"
3. Expected: Bot replies with product search results or dealer menu
4. Check logs: https://supabase.com/dashboard/project/aqpwfurradxbnqvycvkm/functions/whatsapp-webhook/logs

### Test 2: Order Creation
1. Send: "Voglio 2 Margherita da Pizzeria Da Mario, indirizzo Via Roma 10"
2. Expected: Bot confirms order and provides payment link
3. Verify in DB:
   ```sql
   SELECT * FROM whatsapp_order_relays ORDER BY created_at DESC LIMIT 1;
   ```
4. Check fields are NOT NULL: `conversation_id`, `customer_phone`, `notes`

### Test 3: Dealer Confirmation
1. Send message from dealer phone (from `rider_contacts` table)
2. Message: "OK"
3. Expected: Bot confirms order acceptance
4. Verify notification sent to rider

### Test 4: Error Logging
1. Trigger any error (e.g., invalid order)
2. Check logs for detailed error message + stack trace
3. Should see: "Error details:" and "Error stack:" in logs

---

## 📊 ROOT CAUSE SUMMARY

| Issue | Cause | Symptom | Fix |
|-------|-------|---------|-----|
| 500 Error | Undefined parameters in DB insert | Webhook crashes | Fixed parameter references |
| Silent failures | Wrong env var names | Auto-dispatch/payment doesn't work | Fixed to DB_URL, DB_ANON_KEY |
| Hard to debug | Insufficient logging | Can't see stack traces | Added detailed error logs |

---

## 🔮 PREVENTION

To prevent similar bugs:

1. **Type Safety**: Add strict TypeScript checks
   ```typescript
   // Add to tsconfig.json (if exists):
   "strict": true,
   "noImplicitAny": true
   ```

2. **Validation**: Validate all DB inserts
   ```typescript
   if (!conversationId || !phone) {
     throw new Error("Missing required parameters");
   }
   ```

3. **Environment Variables**: Centralize in one config file
   ```typescript
   // supabase/functions/_shared/config.ts
   export const CONFIG = {
     DB_URL: Deno.env.get("DB_URL") || "",
     DB_ANON_KEY: Deno.env.get("DB_ANON_KEY") || "",
     // ... etc
   };
   ```

4. **Error Handling**: Always log full error details
   ```typescript
   console.error("Error:", error);
   console.error("Message:", error?.message);
   console.error("Stack:", error?.stack);
   ```

---

## 📝 NOTES

- **Why not caught earlier?** The webhook returns 200 OK even on errors (async fire-and-forget processing)
- **Why schema cache error was a red herring?** Tables existed, but INSERT was failing due to undefined values
- **Next improvement**: Add health check endpoint (`/health`) to test DB connection

---

**Analyst**: Claude Sonnet 4.5
**Session**: 2026-02-26 WhatsApp Bot Debugging
**Deployment Status**: ⏳ PENDING (awaiting manual deploy by user)
