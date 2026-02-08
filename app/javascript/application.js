// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "@popperjs/core"
import "bootstrap"


// Enregistrement du Service Worker PWA
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/service-worker.js')
      .then(reg => console.log('PWA: Service Worker enregistré !'))
      .catch(err => console.log('PWA: Erreur Service Worker:', err));
  });
}
// --- Logique d'installation PWA ---
document.addEventListener('turbo:load', () => {
  const appleBtn = document.getElementById('pwa-apple');
  const androidBtn = document.getElementById('pwa-android');

  if (appleBtn) {
    appleBtn.addEventListener('click', (e) => {
      e.preventDefault();
      alert("📲 Installation sur iPhone :\n\n1. Appuyez sur l'icône 'Partager' (le carré avec une flèche en bas de l'écran).\n2. Faites défiler et appuyez sur 'Sur l'écran d'accueil'.\n3. Cliquez sur 'Ajouter'.");
    });
  }

  if (androidBtn) {
    androidBtn.addEventListener('click', (e) => {
      e.preventDefault();
      // Si Chrome Android propose l'installation native
      if (window.deferredPrompt) {
        window.deferredPrompt.prompt();
      } else {
        alert("📲 Installation sur Android :\n\n1. Appuyez sur les 3 points en haut à droite.\n2. Choisissez 'Installer l'application' ou 'Ajouter à l'écran d'accueil'.");
      }
    });
  }
});

// Capture l'événement d'installation natif pour Android
window.addEventListener('beforeinstallprompt', (e) => {
  e.preventDefault();
  window.deferredPrompt = e;
});
