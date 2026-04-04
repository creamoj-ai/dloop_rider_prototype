# 💼 DLOOP 2.0: Insurance Business Model - Detailed Specification

**Data:** Aprile 2026
**Status:** Product Specification Draft
**Owner:** Product Team

---

## 1. Insurance Product Architecture

### 1.1 Three Revenue Streams

```
┌─────────────────────────────────────────────────────────────┐
│                    DLOOP 2.0 Revenue Model                  │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  Stream 1: Courier SaaS Subscription                         │
│  ├─ €9-19/mese per courier freelancer                        │
│  ├─ Blended ARPU: €12.75/mese                                │
│  └─ Includes: Dashboard, ratings, support, insurance access  │
│                                                               │
│  Stream 2: Per-Order Fee (Dealer Revenue)                    │
│  ├─ €0.50-€1.50 per ordine (blended €0.75)                  │
│  ├─ Invisible insurance (psychology: "tool cost")            │
│  └─ Dealer benefits: routing, tracking, payment, insurance   │
│                                                               │
│  Stream 3: Insurance Margin (Reinsurance Model)              │
│  ├─ Cost: €0.40-€0.50 per ordine (to insurance partner)     │
│  ├─ Sell: €1.00-€2.00 per ordine (to dealer)                │
│  ├─ Margin: €0.30-€1.55 (122-233% gross margin)             │
│  └─ Bundled in per-order fee (non-transparent)              │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 Courier Subscription Tiers

| Feature | Basic | Pro | Premium |
|---------|-------|-----|---------|
| **Prezzo/mese** | €9 | €15 | €19 |
| **Ordini/mese** | Unlimited | Unlimited | Unlimited |
| **Insurance Coverage** | €100K | €250K | €500K |
| **Dashboard** | Basic | Advanced | Pro |
| **Priority Support** | ❌ | ✅ | ✅ |
| **Ratings Boost** | ❌ | ✅ (1.1x) | ✅ (1.2x) |
| **Target ARPU** | 30% courier | 45% courier | 25% courier |
| **Blended ARPU** | €12.75/mese |  |  |

**Revenue Courier per M6:**
- 1000 courier × €12.75 ARPU × 6 mesi = €76.500

### 1.3 Insurance Coverage Details

**What's Covered:**
- ✅ Merci danneggiate (danno, break, strappi)
- ✅ Merci smarrite (furto, smarrimento)
- ✅ Responsabilità civile (danno a terzi, proprietà)
- ✅ Cyber liability (data breach, order compromise)
- ✅ Professional indemnity (delivery error claims)

**Coverage Limits:**
- Basic: €100K per evento, €500K annual aggregate
- Pro: €250K per evento, €1M annual aggregate
- Premium: €500K per evento, €5M annual aggregate

**Deductible:**
- €0 deductible (DLOOP copre deductible da partnership cut)
- Claim processing: 24h turnaround
- Claim payout: 3-5 business days

**Insurance Partner:**
- Generali, AXA, o Allianz (negoziare Q2 2026)
- Partner provides: Policy underwriting, claims processing, regulatory compliance
- DLOOP provides: Courier acquisition, order data, claims routing

---

## 2. Financial Model Details

### 2.1 Unit Economics Per Ordine

```
Dealer Perspective:
├─ Order Value: €25 (average)
├─ Payment Processing: -€1.25 (5% Stripe fee)
├─ DLOOP All-in Fee: -€0.75 (includes insurance)
│  └─ Breakdown (invisible to dealer):
│     ├─ Routing/tracking: -€0.10
│     ├─ Insurance cost: -€0.40
│     ├─ DLOOP margin: -€0.25
│     └─ Partner fee: -€0.00
└─ Net to Dealer: €22.75 (91% gross margin)

Courier Perspective:
├─ Order Payout: €2.50-€3.50 (variable by distance)
├─ Insurance Included: €1.25 value
├─ Net Income: €2.50-€3.50
└─ Monthly (50 ordini): €125-€175 + €15 sub = €140-€190

DLOOP Perspective:
├─ Revenue: €0.75/ordine
├─ COGS: €0.40 (insurance) + €0.10 (routing) = €0.50
├─ Gross Profit: €0.25/ordine (33% margin)
└─ Blended with SaaS: €1.25/ordine effective margin
```

### 2.2 Customer Acquisition Cost (CAC)

**CAC Model - Courier:**
- Referral bonus: €500 (one-time)
- Average ordini to break-even: 200 ordini × €0.25 margin = €50 ROI
- Payback period: 4 months (50 ordini/mese)
- LTV: €12.75 × 36 mesi × 97% retention = €444
- LTV/CAC: 0.88 (not ideal, but covered by dealer CAC savings)

**CAC Model - Dealer:**
- Direct cost: €0 (organic, referral from courier)
- Time cost: 2h onboarding = €50
- Effective CAC: €50
- LTV: €18.75 × 36 mesi × 95% retention = €641
- LTV/CAC: 12.8 (excellent)

**Blended CAC:**
- Total CAC portfolio: €0 (organic B2B2C model)
- Courier acquisition: Viral through dealer referrals
- Dealer acquisition: Viral through courier network

### 2.3 Churn Analysis

**Courier Churn:**
- Monthly baseline: 2% (natural attrition: gig workers leave gig work)
- Caused by: Better opportunities, burnout, moving, seasonal work
- Reduction levers: Ratings boost, premium support, community features
- Target M3+: 95% retention (1% monthly churn)

**Dealer Churn:**
- Monthly baseline: 3-5% (marketplace model observed)
- Insurance bundling reduces churn: -50% (sticky coverage)
- Integration stickiness: WhatsApp + Stripe reduces churn: -30%
- Target M3+: 92% retention (1.3% monthly churn)

**LTV Projection:**

| Segment | M3 Retention | Monthly Churn | LTV (36mo) |
|---------|--------------|---------------|-----------|
| **Courier Basic** | 97% | 0.8% | €344 |
| **Courier Pro** | 97% | 0.8% | €519 |
| **Courier Premium** | 98% | 0.5% | €685 |
| **Dealer** | 92% | 1.3% | €619 |
| **Blended** | - | - | €541 |

---

## 3. Insurance Partner Negotiation

### 3.1 Generali Pitch (Standard Approach)

**Problem Statement for Insurer:**
- Gig workers underserved: 1M+ courier/riders in Europa
- Current insurance: Manual, expensive, not designed for gig
- Tech gap: No platform connecting courier to insurance
- Market opportunity: €500M+ TAM in Europa

**Solution We Offer:**
- 1000+ courier on DLOOP platform (M6)
- 100% digital claims (instant, via app)
- Reduced fraud: Full order documentation + GPS tracking
- Retention: Bundled insurance (stickier than standalone)
- Scale predictable: Recurring orders, predictable claim patterns

**Financial Proposal for Insurer:**
- Volume commitment: 10K ordini/mese starting M2
- Claim volume: €3750/mese expected losses (3% claim rate)
- Premium: €0.40-€0.50 per ordine (negotiable)
- Upside: 2.5x on claim losses = 150% gross margin

**Risk Mitigation:**
- Courier vetting: Background check + rating system
- Order validation: GPS, photos, timestamps, signatures
- Fraud detection: ML model trained on Glovo data
- Claims audit: Manual review for >€100 claims
- Dispute resolution: SLA 48h response

### 3.2 Expected Negotiation Timeline

| Week | Action | Expected Outcome |
|------|--------|-----------------|
| W1 | Email intro + deck | Insurer interest |
| W2 | Zoom call + Q&A | Contract discussion |
| W3 | Term sheet negotiation | Price, coverage, SLA |
| W4 | Legal review + pilot | LOI signed, small pilot (100 ordini) |
| W5-6 | Pilot results analysis | Full contract negotiated |
| W7 | Go-live | Insurance live on platform |

### 3.3 Fallback Options

If Generali/AXA decline:
1. **Standalone insurance partners**: AIG, Allianz Direct, Zurich
2. **Risk pooling + self-insurance**: Raise €100K capital, self-insure up to €50K claim threshold
3. **Buy insurance as buyer**: Purchase commercial general liability, pass cost to dealer (€2 fee, higher margin)

---

## 4. Product Implementation

### 4.1 Database Schema

```sql
-- Courier subscription management
CREATE TABLE courier_subscriptions (
  id UUID PRIMARY KEY,
  courier_id UUID NOT NULL,
  tier VARCHAR(50), -- 'basic', 'pro', 'premium'
  monthly_price DECIMAL(10,2),
  insurance_coverage_limit INTEGER, -- €100K, €250K, €500K
  started_at TIMESTAMP,
  cancelled_at TIMESTAMP,
  payment_status VARCHAR(50), -- 'active', 'past_due', 'cancelled'
  stripe_subscription_id VARCHAR(255)
);

-- Insurance policies
CREATE TABLE insurance_policies (
  id UUID PRIMARY KEY,
  order_id UUID NOT NULL,
  courier_id UUID NOT NULL,
  dealer_id UUID NOT NULL,
  coverage_amount DECIMAL(10,2),
  premium_paid DECIMAL(10,2),
  policy_status VARCHAR(50), -- 'active', 'claimed', 'expired'
  created_at TIMESTAMP,
  expires_at TIMESTAMP
);

-- Insurance claims
CREATE TABLE insurance_claims (
  id UUID PRIMARY KEY,
  policy_id UUID NOT NULL,
  claim_type VARCHAR(50), -- 'damage', 'loss', 'theft', 'liability'
  claim_amount DECIMAL(10,2),
  description TEXT,
  evidence_urls TEXT[], -- Photos, receipts, etc
  claim_status VARCHAR(50), -- 'submitted', 'approved', 'rejected', 'paid'
  submitted_at TIMESTAMP,
  processed_at TIMESTAMP
);

-- Dealer fees (per-order, includes insurance)
CREATE TABLE dealer_fees (
  id UUID PRIMARY KEY,
  dealer_id UUID NOT NULL,
  order_id UUID NOT NULL,
  fee_amount DECIMAL(10,2), -- €0.75 blended
  breakdown JSON, -- {routing: 0.1, insurance: 0.4, dloop_margin: 0.25}
  paid_at TIMESTAMP,
  status VARCHAR(50) -- 'pending', 'collected', 'refunded'
);
```

### 4.2 Dashboard Features

**For Courier:**
- Subscription management (upgrade/downgrade)
- Insurance coverage status
- Active claims tracker
- Earnings report with insurance breakdown
- Rating + reputation score
- Support chat with insurance questions

**For Dealer:**
- Per-order fee summary
- Insurance breakdown (transparency option)
- Claim history
- Courier reliability stats
- Compliance reporting

**For DLOOP Admin:**
- Insurance partner integration status
- Claims approval workflow
- Fraud detection dashboard
- Revenue reporting
- Churn prediction

---

## 5. Risk Management

### 5.1 Insurance Claim Risk

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| **Claim rate > 8%** | Low | Critical | Courier vetting, order validation, fraud detection |
| **Claim fraud** | Medium | High | Manual audit >€100, GPS validation, photo verification |
| **Insurance partner dispute** | Low | Critical | Weekly reconciliation, clear KPIs in contract |
| **Regulatory issue (IVASS)** | Low | Critical | Legal review, licensed intermediary, compliance audit |

### 5.2 Operational Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| **Courier supply drought** | Medium | Critical | Referral bonus €500, affiliate program, job board ads |
| **Delivery SLA failure** | Medium | High | GPS routing optimization, courier load balancing, surge pricing |
| **Payment processing failure** | Low | High | Dual processor (Stripe + Sella), manual reconciliation |
| **Competitor undercutting** | Medium | Medium | Insurance moat, network effects, brand loyalty |

---

## 6. Go-Live Checklist

### Week 1-2: Foundation
- [ ] Insurance partner LOI signed
- [ ] Database schema deployed (courier_subscriptions, insurance_policies, claims)
- [ ] Stripe integration for courier SaaS billing
- [ ] Email notifications + SMS (claims, billing, alerts)

### Week 3-4: Product MVP
- [ ] Courier SaaS dashboard (basic version)
- [ ] Claims submission form + evidence upload
- [ ] Insurance coverage display in courier app
- [ ] Dealer fee integration in WhatsApp bot

### Week 5-6: Testing + Load
- [ ] 50 courier beta test (free tier)
- [ ] 500 ordini test run
- [ ] Claims processing test (simulate 20 claims)
- [ ] Load testing: 1000 concurrent users

### Week 7-8: Soft Launch
- [ ] 5 dealer pilots (Toelettatura Pet, PAM, NaturaSì, Yamamay, 1 new)
- [ ] 50 courier production (paid tier)
- [ ] Real insurance coverage live
- [ ] 24h support team on-call

---

**Version:** 1.0
**Last Updated:** 2026-04-03
**Next Review:** When insurance partner is signed
