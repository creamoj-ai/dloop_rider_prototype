# ⚡ PWA SPRINT PLAN - 2 SETTIMANE (Tempo Dimezzato)

## 🎯 TARGET
**Catalogo PWA installabile + Cart + Checkout** in **14 giorni** (invece di 28)

---

## 🔥 STRATEGIE PER DIMEZZARE TEMPO

### **1. Usare Boilerplate (Non partire da zero)**
```bash
create-next-app@latest dloop-pwa --typescript --tailwind --app-router
```
✅ Skip custom webpack config
✅ Next.js 15 PWA built-in support

### **2. UI Kit Pre-built (shadcn/ui)**
```bash
npx shadcn-ui@latest init
npx shadcn-ui@latest add card button input dialog
```
✅ Zero CSS da scrivere
✅ Componenti responsive pronti

### **3. Supabase Real-Time Direct**
```typescript
// Niente API custom - query Supabase direttamente da client
const { data } = await supabase
  .from('products')
  .select('*')
  .eq('dealer_id', dealerId)
```
✅ Zero backend da scrivere
✅ Auth built-in

### **4. Generare Codice con AI**
- Prompt ChatGPT: "Generate Next.js component for product card with shadcn/ui"
- Database schema: Usare SQL direttamente (già fatto)
- CRUD hooks: Generare con AI

### **5. Design Minimalista (Non perfetto, funzionante)**
```
❌ Design pixel-perfect Figma
✅ Grid layout + Tailwind (fatto in 30 min)
```

### **6. Parallelizzare (Se hai team)**
- Dev 1: Setup boilerplate + Database
- Dev 2: Componenti UI (card, button, dialog)
- Dev 3: Catalogo page + product grid

---

## 📅 SPRINT GIORNALIERO (14 giorni)

### **SETTIMANA 1: Setup + MVP Core**

#### **Day 1-2: Setup Base** (4-6 ore)
```bash
✅ create-next-app (TypeScript, Tailwind, App Router)
✅ npx shadcn-ui init + add card button input
✅ .env.local: NEXT_PUBLIC_SUPABASE_URL + KEY
✅ Supabase client config
✅ Deploy preview su Vercel
```
**Commit**: "init: next.js pwa boilerplate"

#### **Day 3: Database + Auth**
```sql
✅ Verify products table (già fatto)
✅ Aggiungi colonne mancanti:
   - image_url (se non c'è)
   - dealer_id (se non c'è)
   - description (se non c'è)
```
```typescript
✅ Setup Supabase Auth (Magic Link via email)
✅ useAuth hook (custom)
```
**Commit**: "feat: supabase auth + user session"

#### **Day 4-5: Componenti UI** (4-6 ore)
```typescript
✅ ProductCard (shadcn/card + image + price)
✅ ProductGrid (responsive grid)
✅ DealerSelector (dropdown per scegliere dealer)
✅ Cart badge (numero items)
```
**Use AI**: "Generate shadcn/ui ProductCard component for ecommerce"

**Commit**: "feat: ui components"

#### **Day 6: Catalogo Page** (3-4 ore)
```typescript
✅ /catalog/[dealerId] page
✅ Fetch products da Supabase
✅ Display grid con ProductCard
✅ Add to cart (Zustand state management)
```
**Commit**: "feat: product catalog page"

#### **Day 7: Cart + Checkout Minimal** (3-4 ore)
```typescript
✅ /cart page (lista items + remove button)
✅ /checkout page (form: nome + indirizzo + telefono)
✅ Order creation (POST to Supabase)
✅ Success page
```
**Commit**: "feat: cart + checkout flow"

---

### **SETTIMANA 2: PWA + Polish + Deploy**

#### **Day 8: PWA Setup** (2-3 ore)
```typescript
✅ next-pwa npm package
✅ public/manifest.json (PWA metadata)
✅ Service worker (caching strategy)
✅ Icons 192x192 + 512x512
```
**next.config.js**:
```javascript
const withPWA = require('next-pwa')({
  dest: 'public',
  disable: process.env.NODE_ENV === 'development',
});

module.exports = withPWA({
  reactStrictMode: true,
});
```

**Commit**: "feat: pwa manifest + service worker"

#### **Day 9: Offline Support** (2-3 ore)
```typescript
✅ Zustand persist (cart saved offline)
✅ Supabase offline queries (cached data)
✅ Sync quando online (background sync)
```
**Commit**: "feat: offline support"

#### **Day 10: Images + Optimization** (2-3 ore)
```typescript
✅ next/image optimization
✅ Cloudinary integration (URL-based, no upload)
✅ Lazy loading images
```
**Commit**: "feat: image optimization"

#### **Day 11-12: Responsive Design** (3-4 ore)
```typescript
✅ Mobile-first Tailwind breakpoints
✅ Touch-friendly buttons (min 48px)
✅ Mobile viewport config
✅ Test su iPhone/Android
```
**Commit**: "feat: mobile responsive"

#### **Day 13: Testing + Polish** (2-3 ore)
```
✅ Test catalogo (load products)
✅ Test cart (add/remove items)
✅ Test checkout (create order)
✅ Test offline (disable network → still works)
✅ Test PWA install (Add to Home Screen works)
```
**Commit**: "test: e2e manual testing"

#### **Day 14: Deploy + Monitor** (1-2 ore)
```bash
✅ Deploy Vercel (auto)
✅ Setup analytics (Vercel Analytics)
✅ Monitor performance (Lighthouse)
✅ Activate dealer pilots (test link)
```
**Commit**: "deploy: production pwa"

---

## 📊 TIMELINE COMPRESSO

| Fase | Giorni | Ore |
|------|--------|-----|
| Setup Base | 2 | 4-6 |
| Database + Auth | 1 | 3-4 |
| UI Components | 2 | 4-6 |
| Catalogo | 1 | 3-4 |
| Cart + Checkout | 1 | 3-4 |
| **SUBTOTAL WEEK 1** | **7** | **20-24** |
| PWA Setup | 1 | 2-3 |
| Offline Support | 1 | 2-3 |
| Images | 1 | 2-3 |
| Responsive | 2 | 3-4 |
| Testing | 1 | 2-3 |
| Deploy | 1 | 1-2 |
| **SUBTOTAL WEEK 2** | **7** | **12-18** |
| **TOTALE** | **14** | **32-42 ore** |

**Equivalente**: 4-5 giorni di lavoro full-time di 1 persona (o 2 persone × 1.5 settimane)

---

## 🛠️ TECH STACK (Velocity Massima)

```
Frontend:        Next.js 15 + TypeScript + Tailwind
UI Components:   shadcn/ui (pre-built)
State:           Zustand (semplice, performante)
Database:        Supabase (real-time, auth built-in)
Auth:            Supabase Magic Link
Images:          next/image + Cloudinary
PWA:             next-pwa
Deploy:          Vercel (auto-deploy su git push)
```

✅ **Zero custom APIs** (Supabase client-side)
✅ **Zero database migrations** (schema già pronto)
✅ **Zero auth boilerplate** (Supabase handles)

---

## 🚀 COME ACCELERARE ANCORA

### **Se timeline troppo tight:**

**Option 1: MVP Minimal (10 giorni)**
```
❌ Offline support (Day 9)
❌ Image optimization (Day 10)
❌ Responsive polish (Day 11-12)
→ Deploy con MVP funzionante in 10 giorni
```

**Option 2: Generare codice 80% con AI**
```bash
# Prompt ChatGPT:
"Generate a complete Next.js ecommerce app with:
- Catalog page fetching from Supabase
- Shopping cart with Zustand
- Checkout form
- PWA manifest
Use shadcn/ui for components, Tailwind for styling"
```

**Option 3: Delegare UI a freelancer**
```
- Tu: Database + Auth + Cart logic (7 giorni)
- Freelancer: Design + Tailwind styling (3 giorni)
→ Parallelo = 7 giorni totali
```

---

## ✅ DEPENDENCIES INSTALL (5 min)

```bash
npm install next-pwa zustand @supabase/supabase-js
npx shadcn-ui@latest init
npx shadcn-ui@latest add card button input dialog
```

---

## 🎯 DECISION: VUOI PROCEDERE COSÌ?

1. **START DAY 1 ORA** (boilerplate setup)?
2. **Adattare timeline** (10 giorni invece di 14)?
3. **Usare AI per generare 80% codice**?
4. **Parallelizzare con team** (tu + freelancer)?

Scegli e partimao! 🚀
