
const STORAGE_KEY = 'emunah-bank-lab-review-state-v1';

const appState = {
  view: 'bp',
  activeSections: {
    bp: 'visao-geral',
    rv: 'bugs'
  },
  resolved: new Set()
};

const sectionTitles = {};

document.addEventListener('DOMContentLoaded', () => {
  cacheSectionTitles();
  hydrateResolvedState();
  setupViewSwitches();
  setupNavigation();
  setupAccordions();
  setupCopyButtons();
  setupReviewChecklist();
  setupMobileMenu();
  restoreFromHash();
  refreshAllReviewMeta();
  syncUI();
});

function cacheSectionTitles() {
  document.querySelectorAll('.page-section').forEach(section => {
    sectionTitles[section.id] = section.dataset.sectionTitle || section.id;
  });
}

function setupViewSwitches() {
  document.querySelectorAll('[data-switch-view]').forEach(button => {
    button.addEventListener('click', () => {
      switchView(button.dataset.switchView, true);
    });
  });
}

function setupNavigation() {
  document.querySelectorAll('.nav-link').forEach(button => {
    button.addEventListener('click', () => {
      const view = button.dataset.view;
      const target = button.dataset.target;
      switchView(view, false);
      showSection(target, true);
      closeSidebar();
    });
  });
}

function setupAccordions() {
  document.querySelectorAll('.accordion__trigger').forEach(button => {
    const panel = button.closest('.accordion').querySelector('.accordion__panel');
    button.addEventListener('click', () => {
      const isOpen = button.getAttribute('aria-expanded') === 'true';
      button.setAttribute('aria-expanded', String(!isOpen));
      panel.classList.toggle('is-open', !isOpen);
    });
  });
}

function setupCopyButtons() {
  document.querySelectorAll('[data-copy-target]').forEach(button => {
    button.addEventListener('click', async () => {
      const block = button.closest('.code-block');
      const code = block?.querySelector('code');
      if (!code) return;

      try {
        await navigator.clipboard.writeText(code.textContent);
        const oldText = button.textContent;
        button.textContent = 'Copiado!';
        button.classList.add('is-copied');
        setTimeout(() => {
          button.textContent = oldText;
          button.classList.remove('is-copied');
        }, 1800);
      } catch (error) {
        const oldText = button.textContent;
        button.textContent = 'Falhou';
        setTimeout(() => {
          button.textContent = oldText;
        }, 1800);
      }
    });
  });
}

function setupReviewChecklist() {
  document.querySelectorAll('.review-item').forEach((item, index) => {
    if (!item.dataset.reviewId) {
      item.dataset.reviewId = `review-${index + 1}`;
    }

    const btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'resolve-btn';
    btn.textContent = 'Marcar resolvido';
    btn.addEventListener('click', () => {
      toggleResolved(item.dataset.reviewId);
    });

    item.querySelector('.review-item__header')?.appendChild(btn);
  });
}

function setupMobileMenu() {
  const toggle = document.getElementById('menuToggle');
  if (!toggle) return;

  toggle.addEventListener('click', () => {
    const sidebar = document.getElementById('sidebar');
    const isOpen = sidebar.classList.toggle('is-open');
    toggle.setAttribute('aria-expanded', String(isOpen));
  });

  document.addEventListener('click', event => {
    const sidebar = document.getElementById('sidebar');
    const toggleButton = document.getElementById('menuToggle');
    if (!sidebar || !toggleButton) return;

    const clickedInside = sidebar.contains(event.target) || toggleButton.contains(event.target);
    if (!clickedInside && sidebar.classList.contains('is-open')) {
      closeSidebar();
    }
  });
}

function closeSidebar() {
  const sidebar = document.getElementById('sidebar');
  const toggle = document.getElementById('menuToggle');
  if (!sidebar || !toggle) return;
  sidebar.classList.remove('is-open');
  toggle.setAttribute('aria-expanded', 'false');
}

function switchView(view, updateHash = true) {
  appState.view = view;

  document.querySelectorAll('[data-switch-view]').forEach(button => {
    const active = button.dataset.switchView === view;
    button.classList.toggle('is-active', active);
    button.setAttribute('aria-pressed', String(active));
  });

  document.querySelectorAll('[data-nav-view]').forEach(group => {
    group.classList.toggle('is-active', group.dataset.navView === view);
  });

  document.querySelectorAll('[data-hero-view]').forEach(hero => {
    const active = hero.dataset.heroView === view;
    hero.classList.toggle('is-active', active);
    hero.hidden = !active;
  });

  showSection(appState.activeSections[view], updateHash);
}

function showSection(sectionId, updateHash = true) {
  const view = appState.view;
  appState.activeSections[view] = sectionId;

  document.querySelectorAll('.page-section').forEach(section => {
    const active = section.id === sectionId && section.dataset.view === view;
    section.classList.toggle('is-active', active);
  });

  document.querySelectorAll('.nav-link').forEach(button => {
    const active = button.dataset.view === view && button.dataset.target === sectionId;
    button.classList.toggle('is-active', active);
  });

  const breadcrumbView = document.getElementById('breadcrumb-view');
  const breadcrumbSection = document.getElementById('breadcrumb-section');
  if (breadcrumbView) {
    breadcrumbView.textContent = view === 'bp' ? 'Blueprint' : 'Revisão Técnica';
  }
  if (breadcrumbSection) {
    breadcrumbSection.textContent = sectionTitles[sectionId] || sectionId;
  }

  if (updateHash) {
    history.replaceState(null, '', `#${view}/${sectionId}`);
  }

  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function toggleResolved(reviewId) {
  if (appState.resolved.has(reviewId)) {
    appState.resolved.delete(reviewId);
  } else {
    appState.resolved.add(reviewId);
  }
  persistResolvedState();
  refreshAllReviewMeta();
  syncResolvedStyles();
}

function syncResolvedStyles() {
  document.querySelectorAll('.review-item').forEach(item => {
    const isDone = appState.resolved.has(item.dataset.reviewId);
    item.classList.toggle('is-done', isDone);
    const button = item.querySelector('.resolve-btn');
    if (button) {
      button.classList.toggle('is-done', isDone);
      button.textContent = isDone ? 'Reabrir item' : 'Marcar resolvido';
    }
  });
}

function refreshAllReviewMeta() {
  syncResolvedStyles();

  const groups = ['bugs', 'inconsistencias', 'melhorias'];
  let pendingTotal = 0;

  groups.forEach(group => {
    const items = [...document.querySelectorAll(`.review-item[data-group="${group}"]`)];
    const done = items.filter(item => appState.resolved.has(item.dataset.reviewId)).length;
    const pending = items.length - done;
    pendingTotal += pending;

    const badge = document.querySelector(`[data-badge-for="${group}"]`);
    if (badge) {
      badge.textContent = pending;
    }

    const progressCard = document.querySelector(`[data-progress-group="${group}"]`);
    if (progressCard) {
      const label = progressCard.querySelector('[data-progress-label]');
      const fill = progressCard.querySelector('[data-progress-fill]');
      const percent = items.length ? Math.round((done / items.length) * 100) : 0;
      if (label) label.textContent = `${done} / ${items.length} resolvidos`;
      if (fill) fill.style.width = `${percent}%`;
    }
  });

  const pendingBadge = document.getElementById('pending-count');
  if (pendingBadge) {
    pendingBadge.textContent = pendingTotal;
  }
}

function persistResolvedState() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify([...appState.resolved]));
}

function hydrateResolvedState() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return;
    const parsed = JSON.parse(raw);
    appState.resolved = new Set(parsed);
  } catch (error) {
    appState.resolved = new Set();
  }
}

function restoreFromHash() {
  const hash = window.location.hash.replace('#', '');
  if (!hash.includes('/')) {
    switchView('bp', false);
    showSection(appState.activeSections.bp, false);
    return;
  }

  const [view, section] = hash.split('/');
  if ((view === 'bp' || view === 'rv') && document.getElementById(section)) {
    appState.activeSections[view] = section;
    switchView(view, false);
    showSection(section, false);
  } else {
    switchView('bp', false);
    showSection(appState.activeSections.bp, false);
  }
}

function syncUI() {
  syncResolvedStyles();
  switchView(appState.view, false);
}
