const CACHE_NAME = 'beercount-pwa-v1';
const PRECACHE_MANIFEST = 'precache_manifest.json';

// Instalar y almacenar los recursos de Beercount.
self.addEventListener('install', (event) => {
  event.waitUntil(
    (async () => {
      const response = await fetch(PRECACHE_MANIFEST, {
        cache: 'no-store',
      });

      if (!response.ok) {
        throw new Error('No se pudo cargar precache_manifest.json');
      }

      const manifest = await response.json();
      const cache = await caches.open(CACHE_NAME);

      const resources = manifest.entries.map(
        (entry) => new URL(entry.url, self.registration.scope).href
      );

      // También almacenamos el manifiesto y la página principal.
      resources.push(
        new URL(PRECACHE_MANIFEST, self.registration.scope).href
      );

      await cache.addAll(resources);

      await self.skipWaiting();
    })()
  );
});

// Activar la nueva versión y eliminar cachés antiguas.
self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const cacheNames = await caches.keys();

      await Promise.all(
        cacheNames
          .filter(
            (name) =>
              name.startsWith('beercount-pwa-') &&
              name !== CACHE_NAME
          )
          .map((name) => caches.delete(name))
      );

      await self.clients.claim();
    })()
  );
});

// Servir Beercount sin conexión.
self.addEventListener('fetch', (event) => {
  const request = event.request;

  if (request.method !== 'GET') {
    return;
  }

  const url = new URL(request.url);

  // No interceptar solicitudes de otros dominios.
  if (url.origin !== self.location.origin) {
    return;
  }

  // Para la navegación, intentar red y recurrir a la caché.
  if (request.mode === 'navigate') {
    event.respondWith(
      (async () => {
        try {
          const response = await fetch(request);

          if (response.ok) {
            const cache = await caches.open(CACHE_NAME);
            await cache.put(
              new URL('index.html', self.registration.scope).href,
              response.clone()
            );
          }

          return response;
        } catch (_) {
          const cache = await caches.open(CACHE_NAME);

          const cachedPage = await cache.match(
            new URL('index.html', self.registration.scope).href
          );

          if (cachedPage) {
            return cachedPage;
          }

          return new Response('Beercount no está disponible sin conexión.', {
            status: 503,
            headers: { 'Content-Type': 'text/plain; charset=utf-8' },
          });
        }
      })()
    );

    return;
  }

  // Para los recursos, utilizar primero la caché.
  event.respondWith(
    (async () => {
      const cache = await caches.open(CACHE_NAME);
      const cachedResponse = await cache.match(request);

      if (cachedResponse) {
        return cachedResponse;
      }

      try {
        const response = await fetch(request);

        if (response.ok) {
          await cache.put(request, response.clone());
        }

        return response;
      } catch (_) {
        return new Response('', { status: 503 });
      }
    })()
  );
});
