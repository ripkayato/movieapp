// firebase-messaging-sw.js
// Важно: используй актуальную версию Firebase JS SDK (проверь на https://firebase.google.com/docs/web/setup#available-libraries)
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// Твои Firebase-конфиги (скопируй из Firebase Console > Project Settings > Web App)
firebase.initializeApp({
  apiKey: "AIzaSyCFBaNbtesL3UUyHe25AhQusSRXjUvtfa4",
  authDomain: "YOUR_AUTH_DOMAIN",
  projectId: "YOUR_PROJECT_ID",
  storageBucket: "YOUR_STORAGE_BUCKET",
  messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
  appId: "YOUR_APP_ID"
});

const messaging = firebase.messaging();

// Опционально: обработка фоновых сообщений (для кастомных нотификаций)
// messaging.onBackgroundMessage((payload) => {
//   console.log('[firebase-messaging-sw.js] Received background message ', payload);
//   // Customize notification here
//   const notificationTitle = payload.notification.title;
//   const notificationOptions = {
//     body: payload.notification.body,
//     icon: '/icon.png' // путь к иконке
//   };
//   self.registration.showNotification(notificationTitle, notificationOptions);
// });