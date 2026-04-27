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

  const THRESHOLD = 70;
  let startY = 0;
  let currentY = 0;
  let pulling = false;
  let refreshing = false;

  // Spinner style iOS natif (rayons qui s'estompent)
  const style = document.createElement('style');
  style.textContent = `
    #ptr-wrap {
      position: fixed; top: 0; left: 0; right: 0;
      display: flex; justify-content: center; align-items: flex-end;
      height: 60px; z-index: 9999; pointer-events: none;
      transform: translateY(-60px);
      transition: transform 0.22s ease;
    }
    #ptr-wrap.ptr-visible { transform: translateY(0); }
    #ptr-spinner {
      width: 28px; height: 28px;
      position: relative; margin-bottom: 14px;
    }
    #ptr-spinner span {
      position: absolute; left: 50%; top: 50%;
      width: 2.5px; height: 7px;
      background: #8e8e93;
      border-radius: 2px;
      transform-origin: center -4px;
      opacity: 0;
    }
    #ptr-spinner.ptr-spin span { animation: ptr-fade 1s linear infinite; }
    @keyframes ptr-fade { 0%,100%{opacity:.15} 0%{opacity:1} }
  `;
  document.head.appendChild(style);

  // Créer le spinner avec 12 rayons (style iOS)
  const wrap = document.createElement('div');
  wrap.id = 'ptr-wrap';
  const spinner = document.createElement('div');
  spinner.id = 'ptr-spinner';
  for (let i = 0; i < 12; i++) {
    const s = document.createElement('span');
    s.style.transform = `rotate(${i * 30}deg) translateY(-50%)`;
    s.style.animationDelay = `${-(12 - i) / 12}s`;
    spinner.appendChild(s);
  }
  wrap.appendChild(spinner);
  document.body.prepend(wrap);

  function getScrollTop() {
    return window.scrollY || document.documentElement.scrollTop || 0;
  }

  document.addEventListener('touchstart', (e) => {
    if (refreshing) return;
    if (getScrollTop() === 0) {
      startY = e.touches[0].clientY;
      pulling = true;
    }
  }, { passive: true });

  document.addEventListener('touchmove', (e) => {
    if (!pulling || refreshing) return;
    currentY = e.touches[0].clientY;
    const diff = currentY - startY;
    if (diff > 10) {
      wrap.classList.add('ptr-visible');
      if (diff > THRESHOLD) spinner.classList.add('ptr-spin');
      else spinner.classList.remove('ptr-spin');
    }
  }, { passive: true });

  document.addEventListener('touchend', () => {
    if (!pulling || refreshing) return;
    pulling = false;
    const diff = currentY - startY;
    if (diff > THRESHOLD) {
      refreshing = true;
      spinner.classList.add('ptr-spin');
      setTimeout(() => window.location.reload(), 300);
    } else {
      wrap.classList.remove('ptr-visible');
      spinner.classList.remove('ptr-spin');
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
