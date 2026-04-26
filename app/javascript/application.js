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

// Pull-to-refresh pour la PWA iPhone (mode standalone uniquement)
(function () {
  if (!window.navigator.standalone) return;
  if (typeof gtag === 'function') gtag('event', 'pwa_session', { event_category: 'PWA' });

  const THRESHOLD = 75; // px à tirer avant de déclencher le reload
  let startY = 0;
  let pulling = false;

  // Indicateur visuel
  const ptr = document.createElement('div');
  ptr.id = 'ptr-indicator';
  ptr.innerHTML = '<div class="ptr-spinner"></div>';
  ptr.style.cssText = [
    'position:fixed', 'top:0', 'left:0', 'right:0',
    'display:flex', 'justify-content:center', 'align-items:center',
    'height:56px', 'background:#f8fafc',
    'transform:translateY(-56px)',
    'transition:transform 0.2s ease',
    'z-index:9999', 'pointer-events:none'
  ].join(';');

  const style = document.createElement('style');
  style.textContent = `
    #ptr-indicator .ptr-spinner {
      width: 24px; height: 24px;
      border: 3px solid #e2e8f0;
      border-top-color: #3b82f6;
      border-radius: 50%;
      animation: ptr-spin 0.7s linear infinite;
      opacity: 0;
      transition: opacity 0.2s;
    }
    #ptr-indicator.ptr-ready .ptr-spinner { opacity: 1; }
    @keyframes ptr-spin { to { transform: rotate(360deg); } }
  `;
  document.head.appendChild(style);
  // DOMContentLoaded déjà passé avec importmap — on insère directement ou on attend turbo:load
  if (document.body) {
    document.body.prepend(ptr);
  } else {
    document.addEventListener('turbo:load', () => document.body.prepend(ptr), { once: true });
  }

  document.addEventListener('touchstart', (e) => {
    if (window.scrollY === 0) {
      startY = e.touches[0].clientY;
      pulling = true;
    }
  }, { passive: true });

  document.addEventListener('touchmove', (e) => {
    if (!pulling) return;
    const diff = e.touches[0].clientY - startY;
    if (diff > 0) {
      const pull = Math.min(diff * 0.5, THRESHOLD);
      ptr.style.transform = `translateY(${pull - 56}px)`;
      ptr.classList.toggle('ptr-ready', diff > THRESHOLD);
    }
  }, { passive: true });

  document.addEventListener('touchend', (e) => {
    if (!pulling) return;
    pulling = false;
    const diff = e.changedTouches[0].clientY - startY;
    if (diff > THRESHOLD) {
      ptr.style.transform = 'translateY(0)';
      setTimeout(() => window.location.reload(), 200);
    } else {
      ptr.style.transform = 'translateY(-56px)';
      ptr.classList.remove('ptr-ready');
    }
  }, { passive: true });
})();

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
