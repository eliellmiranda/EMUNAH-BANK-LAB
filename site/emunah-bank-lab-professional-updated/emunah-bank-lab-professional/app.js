(() => {
      const STORAGE_KEY = 'emunah-bank-lab-review-state-v4';
      const sidebar = document.getElementById('sidebar');
      const overlay = document.getElementById('overlay');
      const menuToggle = document.getElementById('menuToggle');

      function openSidebar() {
        sidebar.classList.add('open');
        overlay.classList.add('open');
      }

      function closeSidebar() {
        sidebar.classList.remove('open');
        overlay.classList.remove('open');
      }

      if (menuToggle) {
        menuToggle.addEventListener('click', () => {
          if (sidebar.classList.contains('open')) closeSidebar();
          else openSidebar();
        });
      }
      overlay.addEventListener('click', closeSidebar);

      const viewButtons = [...document.querySelectorAll('[data-view-btn]')];
      const views = [...document.querySelectorAll('.view')];
      const navPanes = [...document.querySelectorAll('[data-nav-pane]')];
      const navButtons = [...document.querySelectorAll('.nav-btn')];

      function setView(name) {
        viewButtons.forEach(btn => {
          const active = btn.dataset.viewBtn === name;
          btn.classList.toggle('active', active);
          btn.setAttribute('aria-selected', String(active));
        });

        views.forEach(view => {
          view.classList.toggle('active', view.dataset.view === name);
        });

        navPanes.forEach(pane => {
          pane.style.display = pane.dataset.navPane === name ? 'block' : 'none';
        });

        const first = document.querySelector(`.nav-btn[data-page="${name}"]`);
        if (first) setSection(name, first.dataset.target);
        window.scrollTo({top:0, behavior:'smooth'});
        closeSidebar();
      }

      function setSection(pageName, targetId) {
        const view = document.querySelector(`.view[data-view="${pageName}"]`);
        if (!view) return;

        view.querySelectorAll('.section').forEach(section => {
          section.classList.toggle('active', section.id === targetId);
        });

        navButtons.forEach(btn => {
          const active = btn.dataset.page === pageName && btn.dataset.target === targetId;
          btn.classList.toggle('active', active);
        });

        closeSidebar();
      }

      viewButtons.forEach(btn => {
        btn.addEventListener('click', () => setView(btn.dataset.viewBtn));
      });

      navButtons.forEach(btn => {
        btn.addEventListener('click', () => setSection(btn.dataset.page, btn.dataset.target));
      });

      document.querySelectorAll('.accordion').forEach((accordion, index) => {
        const button = accordion.querySelector('.acc-btn');
        const panel = accordion.querySelector('.acc-panel');
        if (!button || !panel) return;

        const panelId = `acc-panel-${index + 1}`;
        const buttonId = `acc-btn-${index + 1}`;
        button.id = buttonId;
        panel.id = panelId;
        button.setAttribute('aria-controls', panelId);
        panel.setAttribute('aria-labelledby', buttonId);

        button.addEventListener('click', () => {
          const isOpen = accordion.classList.toggle('open');
          button.setAttribute('aria-expanded', String(isOpen));
        });
      });

      document.querySelectorAll('[data-copy]').forEach(btn => {
        btn.addEventListener('click', async () => {
          const code = btn.closest('.code');
          const pre = code ? code.querySelector('pre') : null;
          if (!pre) return;

          const old = btn.textContent;
          try {
            await navigator.clipboard.writeText(pre.textContent);
            btn.textContent = 'copiado!';
          } catch {
            btn.textContent = 'falhou';
          }
          setTimeout(() => btn.textContent = old, 1800);
        });
      });


      function setAccordionState(accordion, open) {
        const button = accordion.querySelector('.acc-btn');
        const chevron = accordion.querySelector('.acc-chevron');
        accordion.classList.toggle('open', open);
        if (button) button.setAttribute('aria-expanded', String(open));
        if (chevron) chevron.style.transform = open ? 'rotate(180deg)' : 'rotate(0deg)';
      }

      const guideControls = document.querySelector('[data-guide-controls]');
      if (guideControls) {
        const consultasSection = document.getElementById('consultas');
        const guideAccordions = [...consultasSection.querySelectorAll('.guide-accordion-list .accordion')];
        guideControls.querySelector('[data-guide-expand]')?.addEventListener('click', () => {
          guideAccordions.forEach(acc => setAccordionState(acc, true));
        });
        guideControls.querySelector('[data-guide-collapse]')?.addEventListener('click', () => {
          guideAccordions.forEach(acc => setAccordionState(acc, false));
        });

        consultasSection.querySelectorAll('.guide-toc-link').forEach(link => {
          link.addEventListener('click', (event) => {
            const targetId = link.getAttribute('href')?.replace('#', '');
            const target = targetId ? document.getElementById(targetId) : null;
            if (!target) return;
            event.preventDefault();
            setSection('blueprint', 'consultas');
            setAccordionState(target, true);
            setTimeout(() => target.scrollIntoView({ behavior: 'smooth', block: 'start' }), 100);
          });
        });
      }

      const siteSearch = document.getElementById('siteSearch');
      const searchClear = document.getElementById('searchClear');
      const searchResults = document.getElementById('searchResults');

      function buildSearchIndex() {
        const items = [];
        document.querySelectorAll('.section').forEach(section => {
          const page = section.closest('.view')?.dataset.view || 'blueprint';
          const title = section.querySelector('.section-title')?.textContent?.trim() || section.id;
          items.push({ label: title, type: 'Seção', page, target: section.id, anchor: null, text: `${title} ${section.textContent}`.toLowerCase() });
          section.querySelectorAll('.accordion').forEach(acc => {
            const accTitle = acc.querySelector('.acc-title')?.textContent?.trim();
            if (!accTitle) return;
            items.push({ label: accTitle, type: 'Tópico', page, target: section.id, anchor: acc.id || null, text: `${accTitle} ${acc.textContent}`.toLowerCase() });
          });
        });
        document.querySelectorAll('.review-card').forEach(card => {
          const label = card.querySelector('.review-title')?.textContent?.trim();
          const section = card.closest('.section');
          if (!label || !section) return;
          items.push({ label, type: 'Revisão', page: 'review', target: section.id, anchor: null, text: `${label} ${card.textContent}`.toLowerCase() });
        });
        return items;
      }

      const searchIndex = buildSearchIndex();

      function openSearchResult(item) {
        setView(item.page);
        setSection(item.page, item.target);
        if (item.anchor) {
          const anchorEl = document.getElementById(item.anchor);
          if (anchorEl) {
            if (anchorEl.classList.contains('accordion')) setAccordionState(anchorEl, true);
            setTimeout(() => anchorEl.scrollIntoView({ behavior: 'smooth', block: 'start' }), 120);
          }
        }
      }

      function renderSearchResults(query) {
        const q = query.trim().toLowerCase();
        if (!q) {
          searchResults.hidden = true;
          searchResults.innerHTML = '';
          searchClear.hidden = true;
          return;
        }
        searchClear.hidden = false;
        const results = searchIndex.filter(item => item.text.includes(q)).slice(0, 12);
        if (!results.length) {
          searchResults.hidden = false;
          searchResults.innerHTML = '<div class="search-empty">Nenhum resultado encontrado.</div>';
          return;
        }
        searchResults.hidden = false;
        searchResults.innerHTML = results.map((item, i) => `<button type="button" class="search-result-item" data-search-idx="${i}"><span class="search-result-type">${item.type}</span><span class="search-result-label">${item.label}</span></button>`).join('');
        [...searchResults.querySelectorAll('[data-search-idx]')].forEach((btn, idx) => {
          btn.addEventListener('click', () => openSearchResult(results[idx]));
        });
      }

      siteSearch?.addEventListener('input', () => renderSearchResults(siteSearch.value));
      searchClear?.addEventListener('click', () => {
        siteSearch.value = '';
        renderSearchResults('');
        siteSearch.focus();
      });

      const reviewCards = [...document.querySelectorAll('.review-card')];
      const reviewState = new Set();

      function loadReviewState() {
        try {
          const saved = JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]');
          saved.forEach(id => reviewState.add(id));
        } catch {}
      }

      function saveReviewState() {
        localStorage.setItem(STORAGE_KEY, JSON.stringify([...reviewState]));
      }

      function updateReviewStats() {
        reviewCards.forEach(card => {
          const id = card.dataset.reviewId;
          const resolved = reviewState.has(id);
          const button = card.querySelector('[data-resolve]');
          card.classList.toggle('resolved', resolved);
          if (button) {
            button.classList.toggle('on', resolved);
            button.textContent = resolved ? '↺ reabrir' : '✓ resolver';
          }
        });

        const total = reviewCards.length;
        const done = reviewState.size;
        const pending = total - done;
        const pct = total ? Math.round(done * 100 / total) : 0;

        const setText = (id, value) => {
          const el = document.getElementById(id);
          if (el) el.textContent = value;
        };
        setText('statTotal', total);
        setText('statPending', pending);
        setText('statDone', done);
        setText('statPct', pct + '%');
        setText('progressLabel', `${done} / ${total} resolvidos`);
        const fill = document.getElementById('progressFill');
        if (fill) fill.style.width = pct + '%';

        document.querySelectorAll('[data-review-group]').forEach(section => {
          const id = section.id;
          const cards = [...section.querySelectorAll('.review-card')];
          const p = cards.filter(card => !reviewState.has(card.dataset.reviewId)).length;
          const badge = document.querySelector(`[data-badge="${id}"]`);
          if (!badge) return;
          if (p === 0) {
            badge.textContent = 'ok';
            badge.classList.remove('danger', 'warn');
            badge.classList.add('ok');
          } else {
            badge.textContent = p;
            badge.classList.remove('ok');
          }
        });
      }

      reviewCards.forEach(card => {
        const head = card.querySelector('.review-head');
        const resolve = card.querySelector('[data-resolve]');
        const chevron = card.querySelector('.acc-chevron');

        if (head) {
          head.addEventListener('click', (event) => {
            if (event.target.closest('[data-resolve]')) return;
            card.classList.toggle('open');
            if (chevron) {
              chevron.style.transform = card.classList.contains('open') ? 'rotate(180deg)' : 'rotate(0deg)';
            }
          });
        }

        if (resolve) {
          resolve.addEventListener('click', (event) => {
            event.stopPropagation();
            const id = card.dataset.reviewId;
            if (reviewState.has(id)) reviewState.delete(id);
            else reviewState.add(id);
            saveReviewState();
            updateReviewStats();
          });
        }

        if (card.classList.contains('open') && chevron) {
          chevron.style.transform = 'rotate(180deg)';
        }
      });

      loadReviewState();
      updateReviewStats();
    })();
