# 🎯 Prossimi Step - dloop Rider Prototype

## 📌 Priorità Alta

### 1. Test Ticketing System
- [ ] Testare apertura ticket dalla PWA
- [ ] Verificare salvataggio in Supabase
- [ ] Controllare RLS policies funzionanti
- [ ] Testare validazione form

### 2. Dashboard Supporto (Team Support)
- [ ] Creare UI lista ticket (filtri: status, categoria, priorità)
- [ ] Implementare assegnazione ticket a supporto agent
- [ ] Sistema risposte (support_ticket_messages)
- [ ] Notifiche rider quando ticket risolto
- [ ] Cambio status ticket (open → in_progress → resolved → closed)
- [ ] Internal notes per team supporto

## 📌 Priorità Media

### 3. Community Riders Launch
- [ ] Aspettare 10+ rider attivi
- [ ] De-commentare linea 173 in `lib/screens/today/widgets/quick_actions_grid.dart`
- [ ] Creare UI chat community
- [ ] Implementare real-time messages (Supabase Realtime)
- [ ] Filtro per zona geografica
- [ ] Moderazione messaggi (report, delete)

### 4. WhatsApp Market Bot
- [ ] Edge Function per gestione ordini marketplace
- [ ] Integrazione WhatsApp Business API
- [ ] Comandi bot (lista prodotti, crea ordine, status)
- [ ] Notifiche ordini ai rider
- [ ] Sistema pagamento ordini marketplace

## 📌 Completati ✅

- [x] Migrazione chatbot da OpenAI GPT-3.5 a Anthropic Claude Haiku 4.5
- [x] Rimozione feature luxury (Yamamay, Jolie, gioielli)
- [x] Rimozione Piano PRO (€29/mese con Qover)
- [x] Badge "Coming Soon" su WhatsApp Market Bot
- [x] Sistema ticketing supporto (tabelle + form UI)
- [x] Infrastruttura Community Riders (nascosta)
- [x] Deploy Edge Functions con Claude Haiku

---

## 🔧 Note Tecniche

**Support Tickets:**
- Tabelle: `support_tickets`, `support_ticket_messages`
- RLS attive per rider
- Trigger auto-update timestamp

**Community Messages:**
- Tabella: `community_messages`
- RLS: tutti leggono, solo owner modifica (5min window)
- Pronta per launch

**Claude Haiku:**
- Model: `claude-haiku-4-5`
- API: Anthropic Messages API
- Costo: -50% vs GPT-3.5-turbo
- Velocità: +2x

---

**Ultimo aggiornamento:** 2026-06-24
**Branch attivo:** `feat/dloop-2.0-insurance-platform`
