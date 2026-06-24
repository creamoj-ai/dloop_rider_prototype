// Firebase Cloud Messaging Service Worker
// Gestisce notifiche push in background per Dloop Rider PWA
//
// TODO: Replace appId below with real value from Firebase Console:
//   Firebase Console > Project Settings > Your Apps > Web app > App ID
//   The appId should look like: 1:793691819503:web:a1b2c3d4e5f6g7h8
// TODO: Generate VAPID key in Firebase Console > Project Settings > Cloud Messaging > Web Push certificates

importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// Inizializza Firebase con la config del progetto
firebase.initializeApp({
  apiKey: 'AIzaSyDSp5lXMuyE9zfeNEEyCumQEvA77UFFVGA',
  authDomain: 'loop-rider-prototype.firebaseapp.com',
  projectId: 'loop-rider-prototype',
  storageBucket: 'loop-rider-prototype.firebasestorage.app',
  messagingSenderId: '793691819503',
  appId: '1:793691819503:web:dloop-web-config',
});

const messaging = firebase.messaging();

// Handler per messaggi in background (quando PWA non è in foreground)
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Background message received:', payload);

  const notificationTitle = payload.notification?.title || 'Dloop Rider';
  const notificationOptions = {
    body: payload.notification?.body || 'Hai una nuova notifica',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: payload.data?.type || 'default',
    data: payload.data,
    requireInteraction: payload.data?.type === 'new_order', // Nuovo ordine richiede azione
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handler per click su notifica
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification clicked:', event.notification.tag);

  event.notification.close();

  // Naviga all'app
  const urlToOpen = new URL('/', self.location.origin).href;

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true })
      .then((windowClients) => {
        // Se c'è già una finestra aperta, portala in focus
        for (let i = 0; i < windowClients.length; i++) {
          const client = windowClients[i];
          if (client.url === urlToOpen && 'focus' in client) {
            return client.focus();
          }
        }
        // Altrimenti apri una nuova finestra
        if (clients.openWindow) {
          return clients.openWindow(urlToOpen);
        }
      })
  );
});
