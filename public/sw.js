/* Service Worker for Web Push Notifications */

// Take over immediately on update — safe because this SW does not cache assets.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', event => event.waitUntil(clients.claim()));

// Pass-through fetch handler — no caching. Required for Chrome PWA installability.
self.addEventListener('fetch', () => {});

self.addEventListener('push', event => {
  const data = event.data?.json() ?? { title: 'Notification', body: '', url: '/' };
  const { title, body, url } = data;
  event.waitUntil(
    self.registration.showNotification(title, {
      body: body ?? '',
      icon: '/vite.svg',
      data: { url: url ?? '/' },
    })
  );
});

self.addEventListener('notificationclick', event => {
  event.notification.close();
  const url = event.notification.data?.url ?? '/';
  event.waitUntil(
    clients
      .matchAll({ type: 'window', includeUncontrolled: true })
      .then(windowClients => {
        const existing = windowClients.find(c => c.url === url && 'focus' in c);
        if (existing) return existing.focus();
        return clients.openWindow(url);
      })
  );
});

/**
 * Re-subscribe when the browser rotates the push subscription.
 * Since the SW cannot use the Relay environment, it calls the GraphQL
 * endpoint directly with credentials (session cookie) included.
 */
self.addEventListener('pushsubscriptionchange', event => {
  const applicationServerKey =
    event.oldSubscription?.options?.applicationServerKey ?? null;

  event.waitUntil(
    self.registration.pushManager
      .subscribe({ userVisibleOnly: true, applicationServerKey })
      .then(newSubscription => {
        const { endpoint, expirationTime } = newSubscription;
        const keys = newSubscription.toJSON().keys ?? {};
        return fetch('/graphql', {
          method: 'POST',
          credentials: 'include',
          headers: { 'content-type': 'application/json' },
          body: JSON.stringify({
            query: `
              mutation RegisterPushSubscription($input: RegisterPushSubscriptionInput!) {
                registerPushSubscription(input: $input) {
                  success
                  errors { message }
                }
              }
            `,
            variables: {
              input: {
                endpoint,
                p256dh: keys.p256dh ?? '',
                auth: keys.auth ?? '',
                expirationTime: expirationTime ?? null,
              },
            },
          }),
        });
      })
      .catch(err => console.error('[SW] pushsubscriptionchange failed:', err))
  );
});
