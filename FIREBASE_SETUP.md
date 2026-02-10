# Firebase Setup per dloop_rider_prototype

## Passi per configurare Firebase

### 1. Crea progetto Firebase
- Vai su https://console.firebase.google.com
- Crea un nuovo progetto "dloop-rider"
- Disabilita Google Analytics (non serve per il prototipo)

### 2. Registra app Android
- Package name: `com.dloop.rider.prototype`
- App nickname: "DLoop Rider"
- Scarica `google-services.json`
- Mettilo in: `android/app/google-services.json`

### 3. (Opzionale) Registra app iOS
- Bundle ID: `com.dloop.rider.prototype`
- Scarica `GoogleService-Info.plist`
- Mettilo in: `ios/Runner/GoogleService-Info.plist`

### 4. Abilita Cloud Messaging
- Nel progetto Firebase vai su "Cloud Messaging"
- Genera la Server Key (per inviare push dal backend)
- Salva la Server Key nelle env variables di Supabase Edge Functions

### 5. Esegui SQL su Supabase
- `sql/19_create_fcm_tokens_table.sql` — tabella per i token FCM dei device

### 6. Testa
```bash
flutter run
```
L'app chiederà il permesso per le notifiche al primo avvio.

## Canali di notifica Android

| Canale | ID | Priorità | Uso |
|--------|---|----------|-----|
| Ordini | `dloop_orders` | Alta | Nuovi ordini, stati ordine |
| Supporto | `dloop_support` | Default | Messaggi dal supporto |
| Guadagni | `dloop_earnings` | Bassa | Guadagni, traguardi |
