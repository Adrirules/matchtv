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

// Capture l'événement d'installation natif Chrome/Android dès qu'il est disponible
window.addEventListener('beforeinstallprompt', (e) => {
  e.preventDefault();
  window.deferredPrompt = e;

  // Affiche le bouton Android uniquement quand Chrome confirme qu'on peut installer
  const androidBtn = document.getElementById('pwa-android');
  if (androidBtn) androidBtn.style.display = 'inline-flex';
});

// Masque le bouton Android si l'app est déjà installée
window.addEventListener('appinstalled', () => {
  window.deferredPrompt = null;
  const androidBtn = document.getElementById('pwa-android');
  if (androidBtn) {
    androidBtn.textContent = '✅ Installée !';
    androidBtn.disabled = true;
  }
});

document.addEventListener('turbo:load', () => {
  const appleBtn = document.getElementById('pwa-apple');
  const androidBtn = document.getElementById('pwa-android');

  // Bouton Android caché par défaut — visible seulement si beforeinstallprompt a déjà fired
  if (androidBtn && !window.deferredPrompt) {
    androidBtn.style.display = 'none';
  }

  if (appleBtn) {
    appleBtn.addEventListener('click', (e) => {
      e.preventDefault();
      alert("📲 Sur iPhone :\n\n1. Appuyez sur l'icône Partager (carré avec flèche).\n2. Faites défiler → 'Sur l'écran d'accueil'.\n3. Appuyez sur 'Ajouter'.");
    });
  }

  if (androidBtn) {
    androidBtn.addEventListener('click', async (e) => {
      e.preventDefault();
      if (window.deferredPrompt) {
        window.deferredPrompt.prompt();
        const { outcome } = await window.deferredPrompt.userChoice;
        window.deferredPrompt = null;
        if (outcome === 'accepted') {
          androidBtn.textContent = '✅ Installée !';
          androidBtn.disabled = true;
        }
      }
    });
  }
});
