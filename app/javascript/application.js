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

// Pull-to-refresh PWA (standalone uniquement)
(function () {
  const isStandalone = window.navigator.standalone ||
                       window.matchMedia('(display-mode: standalone)').matches;
  if (!isStandalone) return;
  if (typeof gtag === 'function') gtag('event', 'pwa_session', { event_category: 'PWA' });

  const THRESHOLD = 80;
  let startY = 0;
  let currentY = 0;
  let pulling = false;
  let refreshing = false;
  let hapticDone = false;

  // Suivi fiable du scroll — window.scrollY est peu fiable en iOS standalone
  let scrollTop = 0;
  let isScrolling = false;
  let scrollTimer = null;
  document.addEventListener('scroll', () => {
    scrollTop = window.scrollY || document.documentElement.scrollTop || document.body.scrollTop || 0;
    isScrolling = true;
    clearTimeout(scrollTimer);
    scrollTimer = setTimeout(() => { isScrolling = false; }, 200);
  }, { passive: true });

  // Styles
  if (!document.getElementById('ptr-style')) {
    const style = document.createElement('style');
    style.id = 'ptr-style';
    style.textContent = `
      #ptr-wrap {
        position: fixed; top: 0; left: 0; right: 0;
        display: flex; justify-content: center; align-items: flex-end;
        height: 64px; z-index: 9999; pointer-events: none;
        transform: translateY(-64px);
        transition: transform 0.22s ease;
      }
      #ptr-wrap.ptr-visible { transform: translateY(0); }
      #ptr-spinner {
        width: 28px; height: 28px;
        position: relative; margin-bottom: 16px;
      }
      #ptr-spinner span {
        position: absolute; left: 12.25px; top: 0;
        width: 3px; height: 8px;
        background: #8e8e93; border-radius: 2px;
        transform-origin: 1.5px 14px;
        opacity: 0.15;
      }
      #ptr-spinner.ptr-spin span { animation: ptr-fade 1s linear infinite; }
      @keyframes ptr-fade { from { opacity: 1; } to { opacity: 0.15; } }
    `;
    document.head.appendChild(style);
  }

  function buildWrap() {
    const wrap = document.createElement('div');
    wrap.id = 'ptr-wrap';
    const spinner = document.createElement('div');
    spinner.id = 'ptr-spinner';
    for (let i = 0; i < 12; i++) {
      const s = document.createElement('span');
      s.style.transform = `rotate(${i * 30}deg)`;
      s.style.animationDelay = `${-((12 - i) / 12).toFixed(2)}s`;
      spinner.appendChild(s);
    }
    wrap.appendChild(spinner);
    return wrap;
  }

  function ensureWrap() {
    if (!document.getElementById('ptr-wrap')) document.body.prepend(buildWrap());
    return document.getElementById('ptr-wrap');
  }

  document.addEventListener('turbo:load', ensureWrap);
  ensureWrap();

  document.addEventListener('touchstart', (e) => {
    if (refreshing || isScrolling) return;
    if (scrollTop === 0) {
      startY = e.touches[0].clientY;
      currentY = startY;
      pulling = true;
      hapticDone = false;
    } else {
      pulling = false;
    }
  }, { passive: true });

  document.addEventListener('touchmove', (e) => {
    if (!pulling || refreshing) return;
    currentY = e.touches[0].clientY;
    const diff = currentY - startY;
    const wrap = document.getElementById('ptr-wrap');
    const spinner = document.getElementById('ptr-spinner');
    if (!wrap || !spinner) return;
    if (diff > 10) {
      wrap.classList.add('ptr-visible');
      if (diff > THRESHOLD) {
        spinner.classList.add('ptr-spin');
        if (!hapticDone) {
          hapticDone = true;
          if (navigator.vibrate) navigator.vibrate(10);
        }
      } else {
        spinner.classList.remove('ptr-spin');
        hapticDone = false;
      }
    } else {
      wrap.classList.remove('ptr-visible');
      spinner.classList.remove('ptr-spin');
    }
  }, { passive: true });

  document.addEventListener('touchcancel', () => {
    pulling = false;
    hapticDone = false;
    const wrap = document.getElementById('ptr-wrap');
    const spinner = document.getElementById('ptr-spinner');
    if (wrap) wrap.classList.remove('ptr-visible');
    if (spinner) spinner.classList.remove('ptr-spin');
  });

  document.addEventListener('touchend', () => {
    if (!pulling || refreshing) return;
    pulling = false;
    const diff = currentY - startY;
    const wrap = document.getElementById('ptr-wrap');
    const spinner = document.getElementById('ptr-spinner');
    if (diff > THRESHOLD) {
      refreshing = true;
      if (spinner) spinner.classList.add('ptr-spin');
      setTimeout(() => window.location.reload(), 300);
    } else {
      if (wrap) wrap.classList.remove('ptr-visible');
      if (spinner) spinner.classList.remove('ptr-spin');
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
