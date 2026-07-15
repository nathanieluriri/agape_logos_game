// Firebase Cloud Messaging background handler. Must sit at the web ROOT so its
// service-worker scope covers the whole app. Uses the compat SDK because it runs
// in a plain service-worker context (no bundler). firebase_messaging_web
// registers this file automatically; index.html needs no changes.
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyDe2dy2O9EaQDOdtzMuaj5U0T9bI8V1eJI',
  appId: '1:415010449011:web:54eb32e83b1af179a8ac06',
  messagingSenderId: '415010449011',
  projectId: 'agape-logos',
  authDomain: 'agape-logos.firebaseapp.com',
  storageBucket: 'agape-logos.firebasestorage.app',
});

const messaging = firebase.messaging();
messaging.onBackgroundMessage((payload) => {
  const n = payload.notification || {};
  self.registration.showNotification(n.title || 'Agape Logos', {
    body: n.body || '',
    icon: '/icons/Icon-192.png',
  });
});
