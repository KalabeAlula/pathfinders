// FCM worker for the browser build. The Flutter page registers it by this path
// from push_token_registration, so it has to stay at the web root.
//
// Chat pushes are data-only, exactly like on Android, so this worker draws the
// notification itself instead of letting Chrome render `payload.notification`.
importScripts("https://www.gstatic.com/firebasejs/12.12.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/12.12.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyAPtj1N8--gVdZac2jtjgtTOxQU0FkLh1Y",
  authDomain: "pathfinders-dce0b.firebaseapp.com",
  projectId: "pathfinders-dce0b",
  storageBucket: "pathfinders-dce0b.firebasestorage.app",
  messagingSenderId: "163106016796",
  appId: "1:163106016796:web:5841354936e81fcacfd9d9",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const data = payload.data || {};
  const options = {
    body: data.body || "New message",
    icon: "/icons/Icon-192.png",
    badge: "/icons/Icon-192.png",
    data,
  };
  // One card per circle, mirroring the phone's grouped tray.
  if (data.circle_id) {
    options.tag = `chat-${data.circle_id}`;
    options.renotify = true;
  }
  return self.registration.showNotification(data.title || "Pathfinders", options);
});

self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  event.waitUntil(
    clients
      .matchAll({ type: "window", includeUncontrolled: true })
      .then((windows) => {
        const open = windows.find((client) =>
          client.url.startsWith(self.location.origin),
        );
        return open ? open.focus() : clients.openWindow("/");
      }),
  );
});
