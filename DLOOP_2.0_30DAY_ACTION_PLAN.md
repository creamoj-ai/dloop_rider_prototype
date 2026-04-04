# 🚀 DLOOP 2.0: 30-Day Action Plan (Execution Framework)

**Data:** Aprile 2026
**Duration:** 30 days (Day 1 - Day 30)
**Owner:** Product + Operations Team
**Status:** Ready to Execute

---

## Executive Summary

**Goal:** Launch DLOOP 2.0 (Insurance-First SaaS Platform) with:
- ✅ Insurance partner contract signed
- ✅ 50 courier MVP on-boarded
- ✅ Delivery SLA validated (95% on-time)
- ✅ 5 dealer pilots activated
- ✅ Real insurance claims processing tested

**Success Metrics (Day 30):**
- Insurance partner: LOI signed ✅
- Courier active: 50+ ✅
- Ordini processed: 500+ ✅
- Claim rate: <5% ✅
- Delivery SLA: >95% ✅
- Dealer pilots: 5 active ✅

---

## WEEK 1: Insurance Partner Negotiation (Days 1-7)

### Day 1-2: Preparation

**Task 1.1: Create Insurance Pitch Deck**
```
File: DLOOP_Insurance_Partner_Pitch_v1.pptx
Slides:
1. Title + Team (2 slides)
2. Problem: Couriers underserved (2 slides)
3. Solution: DLOOP platform (2 slides)
4. Market size: €300M Europe, 20K Italy (1 slide)
5. Unit economics: €0.40 cost, €1.25 sell, 3.5% claim rate (2 slides)
6. Partnership model: Volume, pricing, SLA (2 slides)
7. 12-month forecast: 72K ordini/mese, €30K claims (1 slide)
8. Risk mitigation: Courier vetting, fraud detection (1 slide)
9. Next steps: LOI, pilot, full contract (1 slide)

Deadline: Day 2, 17:00
Owner: Product team
```

**Task 1.2: Prepare Insurance Partner Email List**
```
Primary targets (Tier 1):
- Generali (largest Italy)
  Contact: B2B partnerships (biz-partnerships@generali.it)
  - AXA (DHL partnership precedent)
  Contact: SMB courier program (sme@axa-it.it)
  - Allianz (innovation focus)
  Contact: Digital partnerships (digital.innovation@allianz.it)

Secondary targets (Tier 2):
- Zurich (online-first)
- HDI (broker-friendly)
- Groupama (growth mode)

Deadline: Day 2, 17:00
Owner: Business development
```

### Day 3-4: Initial Outreach

**Task 1.3: Send Pitch Emails**
```
Email template:
Subject: Opportunity: Insurance Partnership for 1000+ Courier Platform

Body:
Hi [Insurer],

We're building DLOOP, the operating system for freelance couriers in Italy.

Current state:
- 20,000 freelance courier in Italy
- 90% go uninsured (liability risk)
- Insurance is expensive & complicated

DLOOP solution:
- Platform connects courier to network + insurance
- Bundled SaaS + insurance (stickier than standalone)
- Full digital claims (GPS, photos, automated processing)

Partnership opportunity:
- Volume: 1000+ courier by M6, 72K ordini/mese
- Premium: €0.40-0.50/ordine (€340K+ annual)
- Claims: 3.5% rate, fully documented, automated processing
- Risk: Reduced (vetted courier, digital evidence)

Call details in attached deck.

Let's talk this week?

[Your name]
[Your title]
[Phone]
[Email]

Deadline: Day 3, 10:00
Owner: Founder/CEO
Tracking: Spreadsheet (email sent, open rate, response date)
```

**Task 1.4: Schedule Zoom Calls**
```
Target: 3 calls per day (Day 3-4)
Goal: Get to contract discussion in Week 2
Duration: 30 min per call
Talking points:
1. Problem validation (courier underserved)
2. Platform overview (MVP live, 50 courier beta)
3. Unit economics (3.5% claim rate, <€1 expected loss)
4. Partnership model (volume, price, SLA)
5. Next steps (LOI, pilot, contract)

Deadline: Day 4, 17:00
Owner: Founder/CEO
Expected: 2-3 "interested" responses
```

### Day 5-7: Negotiation Kickoff

**Task 1.5: Conduct Insurer Meetings**
```
Meeting format:
- Pre-call: Confirm attendees (insurance underwriter, partnerships, CEO)
- Pitch: 10 min (focus on market opportunity + risk mitigation)
- Q&A: 15 min (underwriter concerns, fraud detection, claim SLA)
- Next steps: 5 min (LOI timeline, pilot terms)

Success criteria:
- Insurer interested (80%+ probability)
- Contract discussion scheduled (Week 2)
- Pilot terms discussed (€0.40-0.50, 100 ordini min)

Deadline: Day 7, 17:00
Owner: Founder/CEO
Expected outcome: 1-2 "advanced discussions"
```

**Task 1.6: Financial Model Sharing**
```
Shared with interested insurers:
- Expected loss calculation (3.5% × €25 = €0.875/ordine)
- Claim volume forecast (M1-M6: 126, 294, 609, 1102, 1733, 2520 claims)
- Premium/margin table (cost €0.40, sell €1.25, margin 212%)
- Fraud mitigation (background check, rating system, GPS, photo evidence)

Deadline: Day 5
Owner: Finance/Product
Security: NDA signed before sharing
```

---

## WEEK 2: Product Development (Days 8-14)

### Database & Backend

**Task 2.1: Deploy Supabase Schema**
```sql
Tables to create:
1. courier_subscriptions (tier, price, insurance_limit, status)
2. insurance_policies (coverage, premium, status)
3. insurance_claims (type, amount, status, evidence)
4. dealer_fees (order_id, fee, breakdown)
5. claim_events (courier_id, order_id, event_type, description)

Migration script: DLOOP_2.0_database_schema.sql
Deadline: Day 8
Owner: Backend engineer
Testing: Full schema test (CRUD ops)
Rollback plan: Backup + restore script
```

**Task 2.2: Build Insurance Quote Engine**
```typescript
// /functions/insurance-quote
// POST /insurance-quote
// Body: { courier_id, order_value, risk_level }
// Response: { premium: €1.25, coverage: €250K, expires_in: "30d" }

Logic:
- Base premium: €0.75 + €0.50 (if risk_level = "high")
- Coverage limit: Based on courier tier (Basic €100K, Pro €250K, Premium €500K)
- Deductible: €0 (DLOOP absorbs)
- Validity: 30 days from quote
- Track: Quote acceptance rate, conversion rate

Deadline: Day 10
Owner: Backend engineer
Testing: Unit tests (50 cases), integration test
```

**Task 2.3: Stripe Integration for Courier SaaS Billing**
```typescript
// /functions/create-courier-subscription
// Generates Stripe subscription for courier
// Tiers: Basic €9, Pro €15, Premium €19

Integration points:
- Create Stripe customer (courier_id)
- Create subscription (monthly, auto-renew)
- Webhook: subscription.updated, subscription.deleted
- Email: Confirmation + invoice

Deadline: Day 12
Owner: Backend engineer
Testing: Test all 3 tiers, cancellation flow
```

### Frontend & Dashboard

**Task 2.4: Build Courier SaaS Dashboard (MVP)**
```
Pages:
1. /courier/dashboard
   - Subscription status (current tier, renewal date)
   - Insurance coverage (limit, active claims)
   - Earnings this month
   - Claims this month
   - Support chat

2. /courier/subscription
   - Tier selector (Basic, Pro, Premium)
   - Price comparison
   - Upgrade/downgrade flow
   - Cancellation option (with exit survey)

3. /courier/claims
   - Submit new claim (form: type, description, evidence upload)
   - View claim status (submitted, approved, rejected, paid)
   - Claim history

4. /courier/support
   - Chat with DLOOP support
   - FAQ (claims, billing, insurance coverage)
   - Contact form

Deadline: Day 14
Owner: Frontend engineer
Testing: User testing with 5 courier
```

**Task 2.5: WhatsApp Bot Integration (Dealer Fee)**
```
Update /functions/whatsapp-webhook to:
1. Calculate order-level fee (€0.75)
2. Breakdown JSON: {routing: €0.10, insurance: €0.40, dloop: €0.25}
3. Send fee summary to dealer WhatsApp
4. Store fee record in dealer_fees table
5. Track fee collection in dashboard

Example message to dealer:
"✅ Ordine #12345 - €89.99
📊 Protezione Professionale: €0.75
📍 Tracking: [link]
💳 Payment due: [link]"

Deadline: Day 14
Owner: Backend engineer
Testing: End-to-end with real WhatsApp
```

---

## WEEK 3: Courier MVP & Testing (Days 15-21)

### Courier Recruitment

**Task 3.1: Build Courier Landing Page**
```
Page: dloop-landing.it/courier
Content:
1. Hero: "Earn €3-5/ordine + Professional Insurance"
2. Benefits: 5 key points (insurance, ratings, earnings, support, tools)
3. Requirements: Age 18+, valid ID, clean background
4. Sign-up form: Name, phone, area, experience
5. Bonus: "€500 joining bonus (free tier)"
6. FAQ: Insurance coverage, payment, how it works

Deadline: Day 15
Owner: Marketing/Frontend
Testing: A/B test headline + CTA
Tracking: Form submissions, email confirmations
```

**Task 3.2: WhatsApp Recruitment Campaign**
```
Strategy: Reach out to existing courier networks
- Message: "Earn €3-5/ordine + Insurance. Join 50 pilot riders. €500 bonus. Limited slots."
- Channel: WhatsApp + Telegram groups (courier communities)
- Target: 50 courier sign-ups
- Bonus allocation: €500 per courier (total €25K cost)
- Timeline: Days 15-19 (5 days)

Recruitment targets:
- 25 from Glovo alumni (known quality)
- 15 from local courier groups (Naples, Milan, Rome)
- 10 from referrals (existing network)

Deadline: Day 19
Owner: Growth/Operations
Tracking: Spreadsheet (name, phone, area, status, onboarding date)
Success: 50+ sign-ups
```

**Task 3.3: Courier Onboarding**
```
Process (per courier):
1. Background check (5 min, automated via external service)
2. Document upload (ID, insurance documents)
3. App installation + account setup
4. Subscription tier selection (free tier for pilot)
5. First order assignment
6. Payment setup (bank details)

Timeline: 15 min per courier
Total: 50 courier × 15 min = 750 min = 12.5 hours (1 person, 3 days)

Deadline: Day 21 (all 50 onboarded)
Owner: Operations
Testing: Verify each courier can accept first order
```

### Load Testing & Validation

**Task 3.4: Run 500-Order Test Load**
```
Objective: Validate system stability + claim rate accuracy
- Order volume: 500 ordini over 7 days (Day 15-21)
- Avg order value: €25
- Expected claims: 500 × 3.5% = 17.5 claims (expect 15-20)
- Test scenarios:
  1. Normal orders (85%)
  2. Damaged items (8%)
  3. Lost items (5%)
  4. Delivery issues (2%)

Metrics to track:
- System uptime: Target 99%+
- Claim processing time: Target <1 hour
- Payment processing: 0 failures
- Delivery SLA: Target >95% on-time

Deadline: Day 21
Owner: QA/Operations
Success: <5% claim rate, >95% on-time delivery
```

**Task 3.5: Claims Testing**
```
Simulate 15-20 claims from test orders:
1. Create claim (courier submits: type, description, photo)
2. Evidence upload (receipt, damage photo, GPS tracking)
3. Claims assessment (manual review: approve, reject, counter-offer)
4. Payout (process payment to courier bank account)
5. Track: Time to resolution (target <24h)

Success criteria:
- 90%+ claims processed <24h
- Zero claim disputes
- Evidence upload working (photos, PDF, GPS)
- Payout successful 100%

Deadline: Day 21
Owner: Operations/Finance
Expected claims: 15-20 (from 500 orders)
```

---

## WEEK 4: Dealer Pilot Launch (Days 22-30)

### Dealer Integration

**Task 4.1: Prepare 5 Dealer Pilots**
```
Selected dealers:
1. Toelettatura Pet 🐾 (high ticket, low volume)
2. Piccolo Supermarket PAM 🛒 (high volume, standard)
3. NaturaSì Vomero 🥬 (organic, eco-conscious)
4. Yamamay/Carpisa Cimino Group 👔 (fashion, B2B)
5. New pilot TBD (third vertical)

For each dealer:
- Confirm participation (signed pilot agreement)
- Setup WhatsApp integration (bot + fee notifications)
- Training: How to use DLOOP dashboard
- Support: Assigned account manager (24h response)

Deadline: Day 24
Owner: Sales/Operations
Success: All 5 dealers confirmed + onboarded
```

**Task 4.2: Deploy Dealer Dashboard**
```
Pages:
1. /dealer/dashboard
   - Overview: Orders today, earnings, active courier
   - Orders: List with status (pending, in-pickup, in-delivery, delivered)
   - Earnings: Daily/weekly/monthly breakdown
   - Couriers: Available in your area + ratings

2. /dealer/fees
   - Fee summary: €0.75/order breakdown
   - Insurance details: Coverage limit, deductible
   - Monthly invoice

3. /dealer/support
   - Chat with DLOOP support
   - FAQ
   - Problem report (missing item, delivery issue)

Deadline: Day 24
Owner: Frontend
Testing: Internal test + dealer feedback (Day 24-25)
```

**Task 4.3: End-to-End Testing (Dealer → Courier → Delivery)**
```
Test flow (per dealer):
1. Dealer creates order in PWA checkout
2. Order routed to DLOOP (saved to orders table)
3. Fee calculated & notified to dealer (€0.75)
4. Order offered to courier (first 50 active)
5. Courier accepts → pickup → delivery → complete
6. Insurance policy created (€250K coverage)
7. Claim (if applicable): Create → Process → Payout
8. Dealer payment: Invoice generated, payment collected

Deadline: Day 25
Owner: QA
Test cases: 20 (normal, damaged, lost, liability)
Success: 100% orders complete, all payments processed
```

### Monitoring & Go-Live

**Task 4.4: Setup Production Monitoring**
```
Dashboards:
1. Operations: Real-time orders, courier status, claims
2. Finance: Revenue, COGS, margin, payment status
3. Customer: Support tickets, NPS, satisfaction
4. Insurance: Claim rate, fraud detection, payout status

Alerts:
- System down: Slack alert (immediate)
- High claim rate (>5%): Email alert (daily)
- Failed payment: Dashboard notification (realtime)
- Missing delivery: Support ticket (realtime)

Deadline: Day 26
Owner: DevOps/Operations
Tools: Supabase logs, Stripe API, custom dashboards
```

**Task 4.5: Soft Launch & Support**
```
Timeline:
- Day 26: Turn on for 5 dealer pilots (limited)
- Day 27-28: Monitor 24h, fix any bugs (real-time support)
- Day 29: Expand to 10 dealer if stable
- Day 30: Assess go/no-go decision

Success criteria for full launch:
- Uptime: 99%+
- Claim rate: <5%
- Delivery SLA: >95%
- Payment success: 99.5%
- Customer NPS: >50

Go/No-Go Decision (Day 30):
- GREEN: All metrics hit → Proceed to Scale phase
- YELLOW: 1-2 metrics miss → Extend 1 week
- RED: 3+ metrics miss → Pivot/debug 2 weeks
```

---

## Risk Management & Escalation

### Critical Blockers

| Risk | Probability | Impact | Mitigation | Owner |
|------|------------|--------|-----------|-------|
| **Insurance partner declines** | 20% | Critical | Fallback to self-insure up to €50K | CEO |
| **Courier recruitment fails** | 15% | Critical | Launch with 25 courier, extend recruitment | Growth |
| **Delivery SLA < 90%** | 25% | High | GPS optimization, load balancing | Ops |
| **Claim fraud detected** | 10% | High | Manual audit, tighter vetting | Finance |
| **Payment processing fails** | 5% | High | Dual processor (Stripe + Sella) | Backend |

### Escalation Protocol

**If SLA < 90% (Day 25):**
1. Root cause analysis (courier availability? logistics? product bug?)
2. If courier availability: Recruit 20 more (24h campaign)
3. If logistics: GPS routing optimization (48h)
4. If product bug: Hot fix (4h), rollback plan ready
5. Escalate to CEO for Day 30 go/no-go decision

**If Claim Rate > 5% (Day 21):**
1. Analyze claim patterns (damage vs loss vs liability)
2. If damage: Improve courier training (video, incentives)
3. If loss: Stricter delivery confirmation (photo + signature)
4. If fraud: Tighter vetting criteria
5. Escalate to insurance partner for claim review

---

## Financial Runway (30 Days)

| Item | Cost | Notes |
|------|------|-------|
| **Insurance negotiation** | €5K | Legal review, travel (1 trip to Rome) |
| **Product development** | €25K | 2 engineers × 3 weeks |
| **Courier bonuses** | €25K | 50 courier × €500 joining bonus |
| **Operations** | €10K | 2 people × 2 weeks onboarding |
| **Marketing** | €5K | Landing page, WhatsApp campaign |
| **Contingency** | €10K | Buffer for issues |
| **TOTAL** | **€80K** | 30-day sprint |

**Funding source:** Existing capital (raised earlier in 2026)

---

## Success Metrics (Day 30 Target)

| Metric | Target | Status |
|--------|--------|--------|
| **Insurance partner** | LOI signed | ? |
| **Courier active** | 50+ | ? |
| **Orders processed** | 500+ | ? |
| **Claim rate** | <5% | ? |
| **Delivery SLA** | >95% | ? |
| **Dealer pilots** | 5 active | ? |
| **System uptime** | 99%+ | ? |
| **Payment success** | 99.5%+ | ? |
| **NPS** | 50+ | ? |
| **Churn** | <2% | ? |

---

## Day-by-Day Checklist

### Week 1
- [ ] Day 1: Pitch deck ready
- [ ] Day 2: Email list prepared
- [ ] Day 3: 3 pitch emails sent
- [ ] Day 4: 3 Zoom calls scheduled
- [ ] Day 5-7: Insurer meetings completed

### Week 2
- [ ] Day 8: Database schema deployed
- [ ] Day 10: Insurance quote engine live
- [ ] Day 12: Stripe integration live
- [ ] Day 14: Courier dashboard deployed

### Week 3
- [ ] Day 15: Courier landing page live
- [ ] Day 19: 50 courier sign-ups
- [ ] Day 21: All 50 onboarded + 500 orders tested

### Week 4
- [ ] Day 24: 5 dealer pilots confirmed
- [ ] Day 25: End-to-end tests passing
- [ ] Day 26: Monitoring setup
- [ ] Day 30: Go/no-go decision + shipping decision

---

**Created:** 2026-04-03
**Duration:** 30 days
**Status:** READY TO EXECUTE
**Next Phase:** 90-day scale plan (if successful)
