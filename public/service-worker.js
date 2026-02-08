self.addEventListener('install', (event) => {
  console.log('SW: Installé');
});

self.addEventListener('fetch', (event) => {
  // Indispensable pour que le navigateur valide la PWA
});
