# 🔄 DLOOP MVP Pivot Analysis – Daily Delivery Model

**Data**: 23 Febbraio 2026  
**Decisione Critica**: Pivot da Fast Delivery (30-60min) a Daily Delivery (ricorrente)

---

## 📊 PITCH ORIGINALE vs MVP ATTUALE

### Original Pitch (Qover Outreach Email)
- **Categoria**: Fast delivery (Deliveroo/Glovo competitor)
- **Target dealer**: Ristoranti, pizzerie, esercenti di quartiere
- **Tipo ordine**: One-off urgenti (30-60 min max)
- **Modello revenue**: Rider Pro subscriptions + B2B merchant fees
- **Logistica**: P2P simple relay
- **Timing**: Consegne veloci, urgenti

### NEW MVP Direction (User Directive – 23 Feb)
- **Categoria**: Daily recurring delivery
- **Target dealer**: **Grocery + Pet ONLY** (non fast food)
- **Tipo ordine**: Pre-ordini ricorrenti (daily/weekly/monthly)
- **Modello revenue**: Dealer subscriptions + Customer subscription plans + recurring Stripe payments
- **Logistica**: Multi-stop cluster optimization
- **Timing**: Same-day o domani (pre-ordinato), NO urgenza

---

## ⚠️ DISALLINEAMENTO CRITICO

| Aspetto | Pitch Originale | MVP Daily Delivery | DB Status | Gap |
|---------|-----------------|-------------------|-----------|-----|
| **Target dealer** | Ristoranti, pizzerie | Supermercati, pet shop | ❌ Non categorizzato | Need `dealer_category` field |
| **Tipo ordini** | One-off, urgenti | Ricorrenti (daily/weekly) | ❌ Manca `order_subscriptions` table | Critical |
| **Timing** | 30-60 min (fast) | Same-day o domani (pre-ordine) | ⚠️ `order_relays` per fast P2P | Designed for fast, not pre-scheduled |
| **Logistics** | P2P relay semplice | Multi-stop cluster ottimizzate | ❌ Non esiste `delivery_clusters` | Missing route optimization |
| **Customer plans** | Rider Pro solo | Rider Pro + Customer daily plans | ❌ No `customer_subscriptions` | Blocked recurring customer payments |
| **Payment recurrence** | Occasionale | Settimanale/mensile ricorrente | ⚠️ Stripe Connect non è ricorrente | Need recurring payment intents |

---

## ✅ COSA GIÀ FUNZIONA (NON TOCCARE)

Questi componenti sono **pronti per il test**:

1. **WhatsApp Bot Infrastructure** ✓
   - `whatsapp_webhook` table + Edge Functions
   - `dealer_processor.ts` con keyword commands (PRONTO, OK, NO, ORDINI)
   - State machine enforcement

2. **Dealer Subscriptions Model** ✓
   - `dealer_subscriptions` table con tiers (starter, pro, business, enterprise)
   - Fee audit table per transaction logging
   - Already supports dealer tier pricing

3. **Stripe Connect Splits** ✓
   - Rider payment 100% of delivery fee
   - Dealer account management
   - Payout infrastructure ready

4. **Order Relay Lifecycle** ✓
   - `order_relays` table stores delivery state
   - Status flow: pending → assigned → in_transit → completed
   - Rider contact & location tracking

5. **Rider Contacts + Clients** ✓
   - `rider_contacts` (dealers) already exist
   - `clients` (customers) already exist
   - WhatsApp message history stored

---

## ❌ COSA MANCA PER DAILY DELIVERY MVP

### Critical Blockers (MVP cannot launch without these)

1. **order_subscriptions table**
   - Store: dealer_id, customer_id, frequency (daily/weekly/monthly), day_of_week, target_products
   - Links one-off orders to recurring subscription plans
   - **Workaround for MVP**: Treat daily orders as individual one-off orders; batch them manually

2. **dealer_category field**
   - Add to `rider_contacts` table: category IN ('grocery', 'pet', 'pharmacy', 'fashion', 'beauty', 'wellness', 'home_garden', 'electronics')
   - Required to filter dealers by MVP focus (Grocery + Pet only)
   - **Workaround for MVP**: Create 2 test dealers manually with name convention (e.g., "Carrefour_grocery", "PetStore_pet")

3. **customer_subscriptions table**
   - Store: customer_id, dealer_id, subscription_tier, billing_frequency, renewal_date
   - Track which customers have recurring plans
   - **Workaround for MVP**: Use one-off orders; skip customer subscription tier for now

4. **Recurring payment intents (Stripe)**
   - Setup SCA-compliant recurring charges
   - **Workaround for MVP**: Generate payment links manually; skip automated recurring billing

---

## 🎯 RECOMMENDED MVP TEST PATH (Minimal changes)

### Phase 1: Setup Test Data (No DB changes needed)
```
1. Create 2 test dealers (grocery + pet) manually
   - INSERT INTO rider_contacts (name, phone, city, delivery_area, platform_type)
   - Name convention: "Carrefour Express_GROCERY", "PetStore Napoli_PET"
   
2. Create 3 test customers manually
   - INSERT INTO clients (name, phone, city)
   - Use real WhatsApp numbers for bot testing

3. Create 6 test products (grocery + pet)
   - INSERT INTO market_products (name, category, price, description)
   - Categories: grocery items (pasta, latte, pane) + pet items (cibo cani, giocattoli)
```

### Phase 2: Test WhatsApp Bot Order Flow (USE EXISTING CODE)
```
1. Customer sends WhatsApp: "Ciao, voglio ordinare da Carrefour"
2. Bot responds with product list (grocery items)
3. Customer: "Voglio 1 latte, 1 pane, consegna domani"
4. Bot generates order_relays entry + sends Stripe link to dealer
5. Dealer clicks PRONTO (WhatsApp keyword) → order assigned to rider
6. Test complete
```

### Phase 3: Test Dealer Subscription Tier Logic (USE EXISTING CODE)
```
1. Verify dealer_subscriptions tier applies correct fees
2. Check Stripe split: dealer gets margin, platform keeps fee, rider gets 100% delivery
3. Verify fee audit logs transactions
```

### Phase 4: Add Category Field (MINIMAL DB CHANGE)
```
ALTER TABLE rider_contacts ADD COLUMN category TEXT DEFAULT 'grocery';
- Update test dealers with category='grocery' or 'pet'
- Modify WhatsApp bot filter to show only dealers in customer's preferred categories
```

---

## 📋 MVP TEST CHECKLIST (What to test NOW)

- [ ] WhatsApp bot receives customer message
- [ ] Bot retrieves test products (grocery + pet)
- [ ] Customer confirms order via WhatsApp
- [ ] Order created in `order_relays` with status='pending'
- [ ] Stripe payment link generated
- [ ] Dealer receives WhatsApp notification with payment link
- [ ] Dealer confirms PRONTO → order status changes to 'assigned'
- [ ] Rider assigned via dispatch logic
- [ ] End-to-end order flow completes
- [ ] Dealer subscription fee applied correctly

---

## ⏭️ FUTURE WORK (Post-MVP, don't do now)

- **order_subscriptions table** → Enable daily/weekly recurring orders
- **customer_subscriptions table** → Enable customer subscription tiers
- **delivery_clusters** → Optimize multi-stop routes for daily delivery
- **recurring_payment_intents** → Automate weekly/monthly Stripe charges
- **Order frequency tracking** → Analytics on subscription patterns

---

## 🚀 RECOMMENDATION: START HERE

**Don't rewrite the DB.** Test what you have:

1. **Create 500 test products** (Grocery + Pet categories) → Market products table
2. **Create 20 test dealers** (10 grocery, 10 pet stores) → Rider contacts with names
3. **Create 10 test customers** → Clients table with real/test WhatsApp numbers
4. **Test the WhatsApp bot** end-to-end with these data
5. **After MVP validation**, then add `order_subscriptions` table for recurring orders

**This way**: You validate the current architecture without breaking it. Once MVP works, you know exactly what new tables to add.

---

**Status**: ✅ Analysis saved. Ready for MVP testing.
