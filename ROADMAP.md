# DLOOP — ROADMAP ARCHITETTURA

> Documento di riferimento architetturale. Aggiornato: 2026-07-10

---

## Stato attuale (Luglio 2026)

| Componente | Stato |
|---|---|
| Rider app (Flutter) | ✅ Prototype live |
| Dispatch engine (PostGIS + reputation) | ✅ Completato M4 |
| WhatsApp dual-bot merchant + customer | ✅ M3 completato |
| Telegram bot (control plane interno) | ✅ Deployato, notifiche merchant attive |
| WhatsApp intake (ordini merchant → Dloop) | 🟡 Stub pronto, non attivo |
| Customer WhatsApp notifications | 🟡 Stub pronto, non attivo |
| Billing SaaS settimanale (token → Stripe invoice) | ✅ Live |

---

## PROSSIMO MILESTONE — WhatsApp Intake Ibrida

### Problema da risolvere

Il modello attuale richiede che ogni merchant abbia il proprio numero WABA dedicato,
con una Edge Function separata per ognuno. Non scala oltre 5-10 merchant.

### Architettura proposta: Numero Unico + Routing AI

```
Merchant A ──┐
Merchant B ──┤──► WABA NUMERO UNICO (Dloop) ──► whatsapp-intake
Merchant C ──┘         (Meta Cloud API)               │
                                                       ▼
                                              AI Router (Claude Haiku)
                                                       │
                                          ┌────────────┴────────────┐
                                          ▼                         ▼
                                   Identifica merchant        Identifica intent
                                   da numero mittente         (nuovo ordine /
                                   o keyword                   status / altro)
                                                       │
                                                       ▼
                                           createDeliveryOrder()
                                                       │
                                          ┌────────────┴────────────┐
                                          ▼                         ▼
                               assignRider() dispatch       notifyMerchant()
                               (Telegram bot)               "🟢 Ordine ricevuto"
```

**Vantaggi numero unico:**
- Un solo account WABA da mantenere (costo fisso Meta)
- Ogni merchant scrive al numero Dloop, non ha bisogno di integrazioni proprie
- Onboarding merchant in minuti (basta dargli il numero)
- Routing trasparente via AI senza configurazione per merchant

**Routing AI (Claude Haiku):**
- Input: numero mittente + testo libero
- Output: `{ merchant_id, intent, order_draft? }`
- Intent `nuovo_ordine` → parse campi obbligatori → `createDeliveryOrder()`
- Intent `status_ordine` → lookup + risposta WhatsApp
- Intent `altro` → escalation a Shoshy via Telegram

---

## Payments — Modello A (SaaS Token)

Regola fondamentale: **Dloop NON tocca i soldi dell'ordine cliente→merchant.**

```
Merchant ──► Dloop (SaaS fee)          ← QUESTO gestisce Dloop
Cliente  ──► Merchant (prodotto/merce) ← Dloop non lo vede
```

### Modello A — Token prepagati

| Elemento | Valore |
|---|---|
| Unità | 1 token = 1 consegna |
| Prezzo token | €1,00 + 3,5% Stripe fee = €1,035 |
| Fatturazione | Settimanale automatica (weekly-billing cron) |
| Onboarding | 50 token gratuiti al merchant |
| Soglia rinnovo | Merchant può ricaricare manualmente o auto-ricarica |

**Flusso:**
1. Merchant crea ordine → `deduct_token()` (RPC Supabase)
2. Se saldo < 1 → errore bloccante, ordine non creato
3. Ordine cancellato pre-pickup → `refund_token()` automatico
4. Ogni lunedì → `weekly-billing` aggrega token consumati → Stripe Invoice

---

## Layer Notifiche (separazione completa)

```
                    ┌─────────────────────────┐
                    │   notification-service   │
                    │  (unico punto di invio)  │
                    └────────┬────────┬────────┘
                             │        │
              ┌──────────────┘        └──────────────┐
              ▼                                       ▼
   MERCHANT ── Telegram                    CLIENTE ── WhatsApp
   (MERCHANT_NOTIFY_ENABLED)               (CUSTOMER_WA_ENABLED)
   default: true                           default: false (stub)
```

**4 eventi automatici al merchant:**

| Evento | Messaggio |
|---|---|
| Ordine creato | `🟢 Nuovo ordine #XXXXXXXX — {indirizzo}` |
| Rider assegnato | `🛵 Rider {nome} assegnato — ordine #XXXXXXXX` |
| Ritirato / in consegna | `📦 Ordine #XXXXXXXX ritirato, in consegna` |
| Consegnato | `✅ Ordine #XXXXXXXX consegnato` |

**4 eventi automatici al cliente (quando CUSTOMER_WA_ENABLED=true):**
- Stessi 4 eventi
- Su "consegnato": invio PIN a 4 cifre → il rider lo inserisce nell'app per chiudere l'ordine

---

## Sequenza di attivazione

```
[FATTO]     ✅ Notification service merchant Telegram
[FATTO]     ✅ Webhook Telegram bot live (@dloop_saas_bot)
[FATTO]     ✅ whatsapp-intake stub (WHATSAPP_INTAKE_ENABLED=false)
[FATTO]     ✅ Customer WA stub (CUSTOMER_WA_ENABLED=false)

[PROSSIMO]  ⬜ Attivare Cloud API WhatsApp (Meta) per numero unico
[PROSSIMO]  ⬜ Implementare AI router in whatsapp-intake
[PROSSIMO]  ⬜ Attivare WHATSAPP_INTAKE_ENABLED=true
[PROSSIMO]  ⬜ Implementare notifyCustomer() + PIN logic
[PROSSIMO]  ⬜ Attivare CUSTOMER_WA_ENABLED=true
[FUTURO]    ⬜ Auto-ricarica token merchant
[FUTURO]    ⬜ Dashboard merchant (ordini live, saldo token)
```

---

## Vincoli non negoziabili

- Dloop **non gestisce pagamenti** cliente→merchant
- Il bot Telegram è **solo control plane e notifiche**, non UI per clienti
- Stripe è usato **esclusivamente** per fatturare i merchant (SaaS fee)
- WhatsApp merchant e WhatsApp cliente sono **due invii distinti**, non collegati
