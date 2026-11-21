/* Showcase · comportamento da vitrine (index.html) sobre o DOM do LiveView.
   Globais (tema, paleta, tela cheia, menu) por delegação; por página, o hook ShowcasePage. */
(function () {
  var root = document.documentElement;
  var theme = root.getAttribute('data-theme') || 'light';
  var esc = function (s) { return String(s).replace(/[&<>"]/g, function (c) { return {'&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;'}[c]; }); };
  var $ = function (id) { return document.getElementById(id); };

  var palette = root.getAttribute('data-palette') || 'ledger';
  var pals = null;
  function palettes() { if (!pals) { try { pals = JSON.parse($('d-palettes').textContent); } catch (e) { pals = []; } } return pals; }
  function palDots(id) {
    var P = palettes().filter(function (x) { return x.id === id; })[0] || palettes()[0]; if (!P) return '';
    var sw = P.sw[theme === 'dark' ? 'dark' : 'light'];
    return [0, 1, 7, 6].map(function (i) { return '<i style="background:' + sw[i][2] + '"></i>'; }).join('');
  }
  function palMenu() {
    var dots = function (sw) { return [0, 1, 7, 6, 8, 9, 10].map(function (i) { return '<i style="background:' + sw[i][2] + '"></i>'; }).join(''); };
    return palettes().map(function (P) {
      return '<button type="button" class="d-palopt ' + (P.id === palette ? 'on' : '') + '" data-pal="' + P.id + '" role="menuitemradio" aria-checked="' + (P.id === palette) + '"><span class="sw">' + dots(P.sw.light) + '</span><span class="sw">' + dots(P.sw.dark) + '</span><b>' + esc(P.name) + '</b><small>' + esc(P.description) + '</small></button>';
    }).join('');
  }
  // keeps what shows the palette in step: the top button, the menu, the "Usar esta" buttons of Temas
  function syncPalette() {
    document.querySelectorAll('[data-pal]').forEach(function (b) {
      var on = b.dataset.pal === palette;
      if (b.classList.contains('d-papply')) {
        on = on && b.dataset.th === theme;
        b.classList.toggle('on', on); b.textContent = on ? 'Em uso' : 'Usar esta';
      } else b.classList.toggle('on', on);
    });
    var pb = $('plb'); if (pb) pb.innerHTML = palDots(palette);
  }
  function setPalette(p) {
    palette = p; root.setAttribute('data-palette', p);
    try { localStorage.setItem('lu-palette', p); } catch (e) {}
    document.querySelectorAll('iframe').forEach(function (f) { try { f.contentWindow.postMessage({palette: p}, '*'); } catch (e) {} });
    syncPalette();
  }
  function setTheme(t) {
    theme = t; root.setAttribute('data-theme', t);
    if (document.body) document.body.setAttribute('data-theme', t);
    try { localStorage.setItem('lu-theme', t); } catch (e) {}
    document.querySelectorAll('iframe').forEach(function (f) { try { f.contentWindow.postMessage({theme: t}, '*'); } catch (e) {} });
    syncPalette();
  }
  document.addEventListener('DOMContentLoaded', function () { setTheme(theme); setPalette(palette); });
  addEventListener('message', function (e) {
    if (!e.data) return;
    if (e.data.theme && e.data.theme !== theme) { theme = e.data.theme; root.setAttribute('data-theme', theme); if (document.body) document.body.setAttribute('data-theme', theme); }
    if (e.data.palette && e.data.palette !== palette) { palette = e.data.palette; root.setAttribute('data-palette', palette); }
  });

  // legado: #id -> rota
  addEventListener('hashchange', function () {
    var h = location.hash.slice(1);
    if (!h || /^x-/.test(h)) return;
    var map = {inicio: '/', instalacao: '/instalacao', cores: '/cores', temas: '/temas', novidades: '/novidades'};
    if (location.pathname === '/') location.replace(map[h] || '/c/' + encodeURIComponent(h));
  });

  // paleta de busca
  var items = null, sel = 0, hits = [];
  function data() { if (!items) { try { items = JSON.parse($('d-search').textContent); } catch (e) { items = []; } } return items; }
  function paint() {
    var pq = $('pq'), pr = $('pr'), q = pq.value.toLowerCase().trim();
    hits = data().filter(function (i) { return i[1].toLowerCase().indexOf(q) >= 0; }).slice(0, 40);
    sel = Math.min(sel, Math.max(hits.length - 1, 0));
    pr.innerHTML = hits.map(function (i, k) { return '<a href="/c/' + esc(i[0]) + '" data-phx-link="patch" data-phx-link-state="push" class="' + (k === sel ? 'd-hl' : '') + '">' + esc(i[1]) + '<span>' + esc(i[2]) + '</span></a>'; }).join('') || '<p style="padding:12px;color:var(--lu-muted)">Nenhum componente com esse nome.</p>';
  }
  function openPal() { var pal = $('pal'); if (!pal) return; pal.classList.add('on'); $('pq').value = ''; sel = 0; paint(); $('pq').focus(); }
  function closeFs() { var fs = $('fs'); if (fs) { fs.classList.remove('on'); $('fsf').src = 'about:blank'; } }

  document.addEventListener('click', function (e) {
    var t = e.target;
    if (t.closest('#th')) { setTheme(theme === 'dark' ? 'light' : 'dark'); return; }
    if (t.closest('#plb')) { var m = $('plm'); m.innerHTML = palMenu(); m.classList.toggle('on'); return; }
    var pb = t.closest('[data-pal]');
    if (pb) {
      setPalette(pb.dataset.pal); if (pb.dataset.th) setTheme(pb.dataset.th);
      var pm = $('plm'); if (pm) pm.classList.remove('on');
      return;
    }
    if (!t.closest('#plm') && $('plm')) $('plm').classList.remove('on');
    if (t.closest('#mb')) return $('side').classList.toggle('open');
    if (t.closest('#sb')) return openPal();
    if (t.closest('#fsx')) return closeFs();
    var pal = $('pal');
    if (pal && (t === pal || (t.closest('#pr a') && pal.contains(t)))) pal.classList.remove('on');
    var full = t.closest('#full');
    if (full) {
      $('fst').textContent = full.dataset.name || '';
      $('fsf').src = '/full/' + encodeURIComponent(full.dataset.id) + '?theme=' + theme + '&palette=' + palette;
      $('fs').classList.add('on');
    }
    var cpl = t.closest('#cpl');
    if (cpl && navigator.clipboard) navigator.clipboard.writeText(location.href.split('#')[0]).then(function () { cpl.title = 'Copiado'; }, function () {});
    var cp = t.closest('[data-copy]');
    if (cp && navigator.clipboard) navigator.clipboard.writeText(cp.dataset.copy).then(function () { cp.textContent = 'Copiado'; setTimeout(function () { cp.textContent = 'Copiar'; }, 1400); }, function () {});
    var fold = t.closest('[data-fold]');
    if (fold) { var c = fold.closest('.d-exc'); c.classList.toggle('fold'); fold.textContent = c.classList.contains('fold') ? 'Expandir' : 'Recolher'; }
    var go = t.closest('#toc [data-go]');
    if (go) { var el = $(go.dataset.go); if (el) el.scrollIntoView({behavior: 'smooth', block: 'start'}); }
  });
  document.addEventListener('input', function (e) { if (e.target.id === 'pq') { sel = 0; paint(); } });
  document.addEventListener('keydown', function (e) {
    if (e.target && e.target.id === 'pq') {
      if (e.key === 'ArrowDown') { sel = Math.min(sel + 1, hits.length - 1); paint(); e.preventDefault(); }
      if (e.key === 'ArrowUp') { sel = Math.max(sel - 1, 0); paint(); e.preventDefault(); }
      if (e.key === 'Enter' && hits[sel]) { var a = $('pr').querySelector('a.d-hl'); if (a) a.click(); $('pal').classList.remove('on'); }
    }
    if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') { e.preventDefault(); openPal(); }
    if (e.key === 'Escape') { closeFs(); if ($('pal')) $('pal').classList.remove('on'); if ($('plm')) $('plm').classList.remove('on'); }
  });

  // hook por página
  var spy = null;
  function wire(main, id, first) {
    var side = $('side');
    if (side) { side.classList.remove('open'); var on = side.querySelector('a.on'); if (on) on.scrollIntoView({block: 'nearest'}); }
    if (!first) scrollTo(0, 0);
    syncPalette();
    // prévias estáticas (fallback do h da vitrine) precisam de ícones <i data-i>
    main.querySelectorAll('[data-static]:not([data-hyd])').forEach(function (s) { s.dataset.hyd = '1'; if (window.LedgerUI) LedgerUI.hydrate(s); });
    main.querySelectorAll('.d-exp:not(.wide) > .d-in2').forEach(function (w) { if ([].some.call(w.children, function (c) { return c.getBoundingClientRect().width < 60; })) w.parentNode.classList.add('wide'); });
    var toc = $('toc');
    if (spy) { spy.disconnect(); spy = null; }
    if (toc) {
      var mark = function (k) { toc.querySelectorAll('a').forEach(function (a) { a.classList.toggle('on', a.dataset.go === k); }); };
      spy = new IntersectionObserver(function (es) { var v = es.filter(function (e) { return e.isIntersecting; }).sort(function (a, b) { return a.boundingClientRect.top - b.boundingClientRect.top; })[0]; if (v) mark(v.target.id); }, {rootMargin: '-70px 0px -65% 0px'});
      main.querySelectorAll('[id^="x-"]').forEach(function (s) { spy.observe(s); });
      var f = toc.querySelector('a'); if (f) f.classList.add('on');
    }
  }

  window.ShowcaseHooks = {
    // gerador de tema (/temas): guarda a escolha em localStorage["lu-tg"] e a restaura ao montar
    ThemeGen: {
      mounted: function () {
        var saved = {};
        try { saved = JSON.parse(localStorage.getItem('lu-tg') || '{}') || {}; } catch (e) {}
        var mode = saved.mode || document.documentElement.getAttribute('data-theme') || 'light';
        this.pushEvent('tg_restore', {acc: saved.acc || 'base', gray: saved.gray || 'ledger', mode: mode});
      },
      updated: function () {
        var d = this.el.dataset;
        try { localStorage.setItem('lu-tg', JSON.stringify({acc: d.acc, gray: d.gray, mode: d.mode})); } catch (e) {}
      }
    },
    ShowcasePage: {
      mounted: function () { this.page = null; this.sync(); },
      updated: function () { this.sync(); },
      destroyed: function () { if (spy) { spy.disconnect(); spy = null; } },
      sync: function () {
        var id = this.el.dataset.page;
        if (id === this.page) return;
        var first = this.page === null; this.page = id;
        wire(this.el, id, first);
      }
    }
  };
})();
