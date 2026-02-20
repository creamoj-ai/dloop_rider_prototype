# Informativa sulla Privacy

**Ultimo aggiornamento: 20 febbraio 2026**

## Titolare del Trattamento

**CAV S.R.L.** (di seguito "DLOOP", "noi", "nostro")
Piazza Giuseppe Garibaldi 101, 80142 Napoli (NA), Italia
P.IVA / C.F.: 09532291219
PEC: legal@pec.mydely.it
Email: privacy@dloop.it
Sito web: https://dloop.it

## 1. Introduzione

La presente Informativa sulla Privacy descrive come CAV S.R.L., titolare della piattaforma DLOOP, raccoglie, utilizza, conserva e protegge i dati personali degli utenti dell'applicazione mobile DLOOP ("App") e del sito web dloop.it ("Sito"), in conformita' al Regolamento (UE) 2016/679 (GDPR), al D.Lgs. 196/2003 (Codice Privacy) come modificato dal D.Lgs. 101/2018, e alle linee guida del Garante per la Protezione dei Dati Personali.

## 2. Categorie di Dati Personali Raccolti

### 2.1 Dati forniti direttamente dall'utente
- **Dati identificativi**: nome, cognome, indirizzo email, numero di telefono
- **Credenziali di accesso**: email e password (hash crittografico), autenticazione tramite Google Sign-In
- **Dati di profilo**: foto profilo (opzionale), preferenze di consegna, unita' di misura
- **Dati di pagamento**: i dati della carta di credito/debito sono gestiti esclusivamente da Stripe Inc. e non vengono mai memorizzati sui nostri server
- **Comunicazioni**: messaggi inviati tramite la chat in-app, conversazioni WhatsApp, richieste di supporto

### 2.2 Dati raccolti automaticamente
- **Dati di geolocalizzazione**: posizione GPS in tempo reale durante le sessioni di lavoro attive (rider), con soglia minima di 50 metri e intervallo di 30 secondi
- **Dati del dispositivo**: modello del dispositivo, sistema operativo, versione dell'app, identificativo Firebase (FCM token) per le notifiche push
- **Dati di utilizzo**: schermate visitate, azioni effettuate nell'app, timestamp delle sessioni, log di attivita'
- **Dati di consegna**: ordini effettuati, stato delle consegne, tempi di completamento, valutazioni e feedback

### 2.3 Dati generati dal sistema
- **Punteggio di dispatch**: calcolato automaticamente sulla base di prossimita', valutazione, tasso di accettazione, specializzazione e disponibilita' (algoritmo di Smart Dispatch)
- **Statistiche rider**: guadagni, ordini completati, tasso di accettazione, valutazione media
- **Audit dei compensi**: registro immutabile delle transazioni con dettaglio importi, commissioni e ripartizioni

## 3. Finalita' e Base Giuridica del Trattamento

| Finalita' | Base giuridica (Art. 6 GDPR) | Dati trattati |
|-----------|------------------------------|---------------|
| Registrazione e gestione account | Esecuzione contratto (b) | Dati identificativi, credenziali |
| Erogazione del servizio di consegna | Esecuzione contratto (b) | Geolocalizzazione, ordini, consegne |
| Elaborazione pagamenti e fatturazione | Esecuzione contratto (b) + Obbligo legale (c) | Dati di pagamento (via Stripe) |
| Assegnazione intelligente ordini (Smart Dispatch) | Legittimo interesse (f) | Geolocalizzazione, statistiche rider |
| Comunicazioni operative (WhatsApp/chat) | Esecuzione contratto (b) | Messaggi, numero di telefono |
| Assistenza clienti tramite chatbot AI | Legittimo interesse (f) | Messaggi, contesto conversazione |
| Notifiche push | Consenso (a) | FCM token, preferenze |
| Sicurezza e prevenzione frodi | Legittimo interesse (f) | Log di accesso, dati dispositivo |
| Adempimenti fiscali e contabili | Obbligo legale (c) | Dati identificativi, transazioni |
| Miglioramento del servizio | Legittimo interesse (f) | Dati di utilizzo anonimizzati |

## 4. Profilazione e Processo Decisionale Automatizzato

### 4.1 Smart Dispatch
L'algoritmo di Smart Dispatch assegna automaticamente gli ordini ai rider sulla base di un punteggio calcolato come segue:
- Prossimita' geografica (40%)
- Valutazione media (30%)
- Tasso di accettazione (15%)
- Specializzazione per esercizio (10%)
- Disponibilita' residua nel turno (5%)

Questo processo costituisce una decisione automatizzata ai sensi dell'Art. 22 GDPR. L'utente ha diritto di:
- Ottenere l'intervento umano da parte del titolare
- Esprimere la propria opinione
- Contestare la decisione

### 4.2 Chatbot AI
Le conversazioni con il chatbot sono elaborate da modelli di intelligenza artificiale (OpenAI GPT-4o Mini) per fornire risposte contestualizzate. I messaggi vengono utilizzati esclusivamente per generare la risposta e non vengono usati per addestrare modelli AI.

## 5. Responsabili del Trattamento (Sub-processori)

Ci avvaliamo dei seguenti fornitori terzi che trattano dati personali per nostro conto:

| Fornitore | Sede | Dati trattati | Finalita' | Garanzie trasferimento extra-UE |
|-----------|------|---------------|-----------|--------------------------------|
| **Supabase Inc.** | USA (infrastruttura: AWS EU West, Irlanda) | Account, ordini, sessioni, geolocalizzazione, messaggi | Database, autenticazione, funzioni serverless | Standard Contractual Clauses (SCC) |
| **Google LLC (Firebase)** | USA | FCM token, eventi app, crash report | Notifiche push, analytics, stabilita' app | SCC + Data Processing Terms Google |
| **Stripe Inc.** | USA / Irlanda | Dati pagamento, transazioni, dati dealer | Elaborazione pagamenti, Connect (split) | SCC + Stripe DPA |
| **OpenAI** | USA (OpenAI Ireland Ltd per EEA) | Messaggi chatbot e WhatsApp | Chatbot AI, elaborazione linguaggio naturale | SCC + OpenAI DPA |
| **Meta Platforms Inc.** | USA (Meta Platforms Ireland Ltd per EEA) | Numero telefono, messaggi WhatsApp | Comunicazioni con clienti e dealer | SCC + Meta Data Processing Terms |
| **Google LLC (Maps)** | USA | Indirizzi, coordinate GPS | Geocodifica, calcolo percorsi, mappe | SCC + Data Processing Terms Google |

## 6. Trasferimento di Dati Extra-UE

Alcuni dei nostri sub-processori hanno sede negli Stati Uniti d'America. Il trasferimento dei dati e' garantito da:
- **Standard Contractual Clauses (SCC)** approvate dalla Commissione Europea (Decisione 2021/914)
- **Data Processing Agreements (DPA)** stipulati con ciascun fornitore
- **Misure tecniche supplementari**: crittografia in transito (TLS 1.3) e a riposo (AES-256)

L'infrastruttura database principale (Supabase) e' ospitata nella regione **AWS EU West (Irlanda)**, all'interno dello Spazio Economico Europeo.

## 7. Periodo di Conservazione dei Dati

| Tipo di dato | Periodo di conservazione |
|--------------|------------------------|
| Account utente | Per tutta la durata dell'account + 30 giorni dopo la cancellazione |
| Dati di geolocalizzazione | **30 giorni** dalla raccolta, poi cancellati automaticamente |
| Ordini e transazioni | **10 anni** (obbligo fiscale Art. 2220 c.c.) |
| Messaggi chat e WhatsApp | **12 mesi** dalla conversazione |
| Log di accesso e sicurezza | **6 mesi** (Art. 132 D.Lgs. 196/2003) |
| Audit dei compensi (fee_audit) | **10 anni** (obbligo fiscale) |
| Statistiche rider | Per tutta la durata dell'account |
| FCM token | Fino a revoca del consenso o disinstallazione app |
| Log di dispatch | **12 mesi** |

## 8. Diritti dell'Interessato

Ai sensi degli Artt. 15-22 del GDPR, l'utente ha diritto di:

1. **Accesso** (Art. 15): ottenere conferma del trattamento e copia dei dati
2. **Rettifica** (Art. 16): correggere dati inesatti o incompleti
3. **Cancellazione** (Art. 17): richiedere la cancellazione dei dati ("diritto all'oblio")
4. **Limitazione** (Art. 18): limitare il trattamento in determinati casi
5. **Portabilita'** (Art. 20): ricevere i dati in formato strutturato e leggibile da dispositivo automatico
6. **Opposizione** (Art. 21): opporsi al trattamento basato su legittimo interesse
7. **Revoca del consenso** (Art. 7): revocare il consenso in qualsiasi momento senza pregiudizio per la liceita' del trattamento precedente
8. **Non essere sottoposto a decisioni automatizzate** (Art. 22): contestare le decisioni dello Smart Dispatch

Per esercitare i propri diritti, l'utente puo' contattarci all'indirizzo **privacy@dloop.it** o scrivere a CAV S.R.L., Piazza Giuseppe Garibaldi 101, 80142 Napoli.

Rispondiamo entro **30 giorni** dalla richiesta. In caso di richieste complesse, il termine puo' essere prorogato di ulteriori 60 giorni, previa comunicazione.

## 9. Sicurezza dei Dati

Adottiamo le seguenti misure tecniche e organizzative per proteggere i dati personali:

- **Crittografia in transito**: TLS 1.3 per tutte le comunicazioni
- **Crittografia a riposo**: AES-256 per i dati memorizzati
- **Autenticazione sicura**: hash delle password con bcrypt, autenticazione biometrica opzionale
- **Row Level Security (RLS)**: ogni utente puo' accedere esclusivamente ai propri dati nel database
- **Separazione degli ambienti**: chiavi API distinte per test e produzione
- **Backup giornalieri**: ripristino garantito entro 24 ore
- **Monitoraggio**: logging degli accessi e delle anomalie

## 10. Geolocalizzazione

### 10.1 Come funziona
L'App raccoglie la posizione GPS del rider **esclusivamente durante le sessioni di lavoro attive**. La raccolta si interrompe automaticamente al termine della sessione.

### 10.2 Parametri tecnici
- Distanza minima tra aggiornamenti: 50 metri
- Intervallo minimo: 30 secondi
- Dati considerati obsoleti dopo: 120 secondi

### 10.3 Opt-out
Il rider puo' disattivare la geolocalizzazione in qualsiasi momento terminando la sessione di lavoro. La geolocalizzazione e' necessaria per l'erogazione del servizio di consegna; senza di essa non e' possibile ricevere ordini tramite Smart Dispatch.

### 10.4 Cancellazione
I dati di geolocalizzazione vengono cancellati automaticamente dopo 30 giorni dalla raccolta.

## 11. Cookie (solo Sito Web)

Il sito web dloop.it utilizza cookie tecnici necessari al funzionamento e, previo consenso, cookie di terze parti per analytics. Per maggiori informazioni, consultare la nostra [Cookie Policy](https://dloop.it/cookie-policy).

## 12. Minori

Il servizio DLOOP e' riservato a persone che abbiano compiuto 18 anni di eta'. Non raccogliamo consapevolmente dati personali di minori. Se veniamo a conoscenza di aver raccolto dati di un minore, provvederemo alla cancellazione immediata.

## 13. Modifiche alla presente Informativa

Ci riserviamo il diritto di aggiornare la presente Informativa. In caso di modifiche sostanziali, informeremo gli utenti tramite notifica in-app o email almeno 30 giorni prima dell'entrata in vigore delle modifiche.

La versione aggiornata sara' sempre disponibile nell'App (Impostazioni > Privacy Policy) e sul sito dloop.it.

## 14. Reclamo all'Autorita' di Controllo

Se l'utente ritiene che il trattamento dei propri dati violi il GDPR, ha diritto di proporre reclamo al:

**Garante per la Protezione dei Dati Personali**
Piazza Venezia 11, 00187 Roma
Tel. +39 06 696771
Email: protocollo@gpdp.it
PEC: protocollo@pec.gpdp.it
Sito: https://www.garanteprivacy.it

## 15. Contatti

Per qualsiasi domanda relativa alla presente Informativa:

**CAV S.R.L.**
Piazza Giuseppe Garibaldi 101, 80142 Napoli (NA)
Email: privacy@dloop.it
PEC: legal@pec.mydely.it
