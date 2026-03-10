# 🚀 DLOOP MVP - Complete Deployment Guide

## 📋 Project Overview

**DLOOP** is a hyperlocal delivery platform with:
- ✅ WhatsApp Bot (ChatGPT-powered)
- ✅ PWA Catalog (Next.js)
- ✅ Rider App (Flutter)
- ✅ Real-time Order Tracking
- ✅ Stripe Payment Integration
- ✅ FCM Push Notifications

---

## 🔧 Infrastructure Setup

### 1. Supabase Project
- **Project ID**: `aqpwfurradxbnqvycvkm`
- **Region**: eu-central-1
- **Database**: PostgreSQL

### Required Secrets (Supabase → Settings → Secrets)
```
WHATSAPP_ACCESS_TOKEN         → Meta OAuth token (expires, needs refresh)
WHATSAPP_PHONE_NUMBER_ID      → 979991158533832
WHATSAPP_VERIFY_TOKEN         → dloop_wa_verify_2026
OPENAI_API_KEY                → sk-proj-...
WOZ_ADMIN_KEY                 → Admin key for Stripe functions
STRIPE_SECRET_KEY             → Stripe API secret key
TWILIO_ACCOUNT_SID            → (Backup only, currently unused)
TWILIO_AUTH_TOKEN             → (Backup only, currently unused)
TWILIO_PHONE_NUMBER           → (Backup only, currently unused)
```

### 2. Meta WhatsApp Business
- **Business Account ID**: 936475792061077
- **WABA Phone**: +39 328 185 4639
- **Webhook URL**: https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/whatsapp-webhook
- **Verify Token**: dloop_wa_verify_2026
- **Status**: ⚠️ AWAITING NUMBER VERIFICATION (as of 2026-03-01)

### 3. Stripe Integration
- **Mode**: Live (production)
- **Endpoint**: https://api.stripe.com/v1/...
- **Webhook function**: `stripe-link` (generates Checkout links)
- **Flow**: Order created → Payment link generated → Sent to customer

---

## 📱 Component Deployment

### A. WhatsApp Webhook (Supabase Edge Functions)
**Path**: `supabase/functions/whatsapp-webhook/`

**Files**:
- `index.ts` - HTTP request handler (Meta JSON parsing)
- `processor.ts` - NLU pipeline (ChatGPT + function calling)
- `customer_functions.ts` - Tool definitions for ChatGPT
- `twilio_api.ts` - Media download + Twilio API (backup)
- `dealer_functions.ts` - Dealer routing logic
- `dealer_processor.ts` - Dealer message handling

**Deploy**:
```bash
cd dloop_rider_prototype
npx supabase functions deploy whatsapp-webhook --project-ref aqpwfurradxbnqvycvkm --no-verify-jwt
```

**Flow**:
```
Meta WhatsApp → Webhook (index.ts)
  ↓ Parse Meta JSON
  ↓ Extract phone + message
  ↓ Route to processor.ts
  ↓ processInboundMessage()
    - Get/create conversation
    - Call ChatGPT with system prompt
    - Execute ChatGPT function calls (assign_rider, browse_products, etc.)
    - Send reply via Meta API
```

### B. PWA (Next.js)
**Repo**: https://github.com/creamoj-ai/dloop-pwa
**URL**: https://dloop-pwa.vercel.app (production)

**Features**:
- `/` - Home dashboard (4 dealers × 3 products = 12 items)
- `/catalog` - Product listing with filters
- `/cart` - Shopping cart (Zustand state)
- `/checkout` - Order form (name, phone, address)
- `/order/:id` - Real-time tracking (Supabase Realtime)

**Deploy**:
```bash
cd dloop-pwa
git push origin main  # Auto-deploys to Vercel
```

### C. Rider App (Flutter)
**Path**: `lib/` in dloop_rider_prototype
**Stack**: Flutter + Riverpod + Supabase + GoRouter + Firebase

**Screens**:
- Dashboard (today's orders)
- Order Details
- In-delivery tracking
- Earnings tracker

**FCM Notifications**:
- Listens to `notifications` table via Realtime
- Triggers push when new order assigned
- Shows: Client name, address, items, total, ETA

**Deploy**:
```bash
flutter pub get
flutter build apk  # Android
flutter build ios  # iOS (requires Mac)
```

---

## 🔐 Security Checklist

- [ ] All secrets configured in Supabase (never in code)
- [ ] Meta webhook verify token matches (dloop_wa_verify_2026)
- [ ] Stripe API keys are production keys
- [ ] HTTPS everywhere (Supabase, Vercel, Stripe)
- [ ] JWT tokens validated (--no-verify-jwt only for development)
- [ ] Rate limiting enabled on functions
- [ ] Database Row-Level Security (RLS) policies configured
- [ ] Sensitive logs redacted (phone numbers, tokens)

---

## 📊 Database Schema

Key tables:
- `orders` - Customer orders (status, rider_id, created_at, delivered_at)
- `riders` - Rider profiles (name, rating, status, current_order_count)
- `whatsapp_conversations` - Chat state (phone, conversation_type, state)
- `whatsapp_messages` - Message logs (direction, content, status)
- `notifications` - Rider notifications (notification_type, title, body, is_read)
- `market_products` - Product catalog (name, price, stock, category)
- `rider_contacts` - Dealer contact info (name, phone, platform)

---

## 🧪 Testing Checklist (Once Meta Verifies Number)

### 1. WhatsApp Bot
- [ ] Send text message to +39 328 185 4639
- [ ] Verify ChatGPT response (should suggest dealer)
- [ ] Verify PWA link included in response
- [ ] Check Supabase logs for no errors
- [ ] Test with different product queries

### 2. PWA Ordering
- [ ] Click PWA link from WhatsApp
- [ ] Browse catalog (4 dealers visible)
- [ ] Add product to cart
- [ ] Go to checkout
- [ ] Fill form (name, phone, address)
- [ ] Submit order
- [ ] Verify order in Supabase `orders` table

### 3. Rider Assignment
- [ ] Check that order status is `PENDING`
- [ ] ChatGPT should call `assign_rider` (AUTO)
- [ ] Verify order.status becomes `ASSIGNED`
- [ ] Verify rider name populated
- [ ] Check Supabase logs: "Auto-assigned: [RiderName]"

### 4. FCM Notifications
- [ ] Rider app receives push notification
- [ ] Notification shows: Client name, address, items, total
- [ ] Rider can tap to view full order details

### 5. Stripe Payment
- [ ] Payment link generated after order creation
- [ ] Link sent to customer via WhatsApp
- [ ] Customer clicks link → Stripe Checkout
- [ ] Test with Stripe test card: 4242 4242 4242 4242
- [ ] Verify payment status updates in DB

### 6. Order Tracking
- [ ] Customer gets /order/:id link
- [ ] Tracking page shows status timeline
- [ ] Status updates in real-time as rider moves order forward
- [ ] Rider info card shows rider name + rating + phone

---

## 🚨 Known Issues & Blockers

### 1. Meta API Token Error (Code 190)
**Status**: ❌ BLOCKER (as of 2026-03-01)
**Cause**: Token invalid or Meta number not verified
**ChatGPT Response**: ✅ Working (proof in logs)
**Message Delivery**: ❌ Fails when sendMetaMessage() tries to send
**Solution**: Generate new token after Meta verifies number +39 328 1854639

### 2. Token Expiration
**Token Type**: Expires every 1-3 hours (unless "scade: mai" selected)
**Solution**: Generate non-expiring token from Meta
**Backup**: Implement token refresh logic (Phase 2)

---

## 📞 Support & Monitoring

### Logs
- Supabase Logs: https://supabase.com/dashboard/project/aqpwfurradxbnqvycvkm/functions
- Vercel Logs: https://vercel.com/dashboard (PWA)

### Metrics to Monitor
- Message inbound rate (WhatsApp)
- ChatGPT response time (avg <2s)
- Order creation rate
- Payment success rate (Stripe)
- Push notification delivery (FCM)

### Health Checks
- Webhook responds with 200 OK
- Supabase Realtime connected
- Meta API accessible (when configured)
- Stripe API accessible

---

## 🎯 Next Steps (Phase 2)

1. **Meta Number Verification** - Await Meta's approval
2. **Live Map Tracking** - Rider GPS + map display
3. **Rating System** - Post-delivery feedback
4. **Analytics Dashboard** - Orders, revenue, rider performance
5. **Multi-language** - Support EN, ES, FR
6. **SMS Fallback** - If WhatsApp fails
7. **Admin Dashboard** - Dealer management + payouts

---

## 📞 Emergency Contacts

- **Meta Support**: business.facebook.com/support
- **Stripe Support**: support@stripe.com
- **Supabase Support**: https://supabase.com/docs
- **Firebase Support**: firebase.google.com/support

---

**Last Updated**: 2026-03-01
**Status**: ✅ MVP COMPLETE (awaiting Meta verification)
**Team**: Claude Haiku 4.5

