/* Vitrine · a ação mora no próprio componente de cada seção */
(function () {
  var page = '';
  var MENU_PAGES = /^(dropdown|menu|action-menu|filter-menu|button-group|split-button)$/;
  var fm = null;
  function floatMenu() {
    if (!fm) { fm = document.createElement('div'); fm.className = 'lu-pop lv-fm'; document.body.appendChild(fm); }
    return fm;
  }
  function closeFloat() { if (fm) fm.classList.remove('open'); }
  function showFloat(anchor, html, w) {
    var m = floatMenu(); m.innerHTML = html; m.style.width = (w || 220) + 'px';
    var r = anchor.getBoundingClientRect(); var left = Math.min(r.left, innerWidth - (w || 220) - 12);
    var top = r.bottom + 6; if (top + 260 > innerHeight) top = Math.max(12, r.top - 6 - Math.min(260, 48 * 4));
    m.style.left = left + 'px'; m.style.top = top + 'px'; m.classList.add('open');
    if (window.LedgerUI) LedgerUI.hydrate(m);
  }
  var I = function (n) { return '<i data-i="' + n + '"></i>'; };
  var ACTIONS = '<button class="lu-menu-item" type="button" data-fm="Editar">' + I('edit') + 'Editar</button><button class="lu-menu-item" type="button" data-fm="Duplicar">' + I('copy') + 'Duplicar</button><button class="lu-menu-item" type="button" data-fm="Compartilhar">' + I('link') + 'Compartilhar</button><div class="lu-menu-sep"></div><button class="lu-menu-item danger" type="button" data-fm="Excluir">' + I('trash') + 'Excluir</button>';
  var OPTS = ['Matriz · Feira de Santana', 'Filial Serrinha', 'Filial Alagoinhas', 'Filial Santo Estêvão'];
  var NTF = ['<b>Novo pedido #2492</b> de Padaria Central', 'Pagamento recebido de <b>Bom Preço</b> · R$ 3.120,50', '<b>NF-e 48.211</b> autorizada'];
  var selTarget = null;
  function toast(o) { if (window.LedgerLive) LedgerLive.toast(o); }
  function open(id) { if (window.LedgerLive) LedgerLive.open(id); }
  function kindOf(el) { var m = (el.className.match(/\bc-(\w+)/) || [])[1] || 'neutral'; return {primary: 'info', secondary: 'info', mono: 'neutral', dark: 'neutral', light: 'neutral'}[m] || m; }
  function sibOn(b) { [].forEach.call(b.parentNode.children, function (x) { if (x.tagName === b.tagName) x.classList.toggle('on', x === b); }); }
  function lbl(el) { var l = el.querySelector('.lbl'); return l ? l.textContent.trim() : ''; }

  window.LedgerAct = {
    mount: function (root, id) {
      page = id; closeFloat();
      root.querySelectorAll('.d-exp').forEach(function (x) { x.classList.add('d-act'); });
      // acordeões: itens fechados ganham corpo para poder abrir
      root.querySelectorAll('.d-exp .lu-acc2 .it').forEach(function (it) {
        if (!it.querySelector('.bd')) { var b = document.createElement('div'); b.className = 'bd'; b.textContent = 'Sim. Abra o pedido, toque em Ações e escolha a opção; a nota segue para a SEFAZ.'; it.appendChild(b); }
        it.classList.remove('mo');
      });
      // grades que não cabem na largura da página viram uma coluna (ou menos)
      root.querySelectorAll('.d-exp .lu-grid').forEach(function (g) {
        var over = function () { return g.scrollWidth > g.clientWidth + 4 || [].some.call(g.querySelectorAll('table, .lu-tablewrap, .lu-tbl, .lu-panel, .lu-card, [style*=overflow]'), function (c) { return c.scrollWidth > c.clientWidth + 4 || (c.parentElement && c.offsetWidth > c.parentElement.clientWidth + 4); }) || [].some.call(g.children, function (c) { return c.scrollWidth > c.clientWidth + 4; }); };
        var n = parseInt(getComputedStyle(g).getPropertyValue('--cols')) || 0;
        while (n > 1 && over()) { n = n > 2 ? Math.ceil(n / 2) : 1; g.style.setProperty('--cols', n); }
      });
      // dicas visuais do que é clicável
      root.querySelectorAll('.d-exp .lu-mst').forEach(function (m) { m.setAttribute('data-hint', 'Clique para abrir'); });
    }
  };

  document.addEventListener('click', function (e) {
    if (fm && fm.contains(e.target)) {
      var it = e.target.closest('[data-fm],[data-pick],[data-ntf]'); if (!it) return;
      if (it.dataset.pick && selTarget) { var v = selTarget.querySelector('.val'); if (v) v.textContent = it.dataset.pick; }
      if (it.dataset.fm) toast(it.dataset.fm === 'Excluir' ? {kind: 'neutral', title: 'Pedido #2491 excluído', action: 'Desfazer'} : {kind: 'success', title: it.dataset.fm + ' · Pedido #2491'});
      closeFloat(); return;
    }
    var ex = e.target.closest('#main .d-exp');
    document.querySelectorAll('#main .lu-anc.open').forEach(function (a) { if (!a.contains(e.target)) a.classList.remove('open'); });
    if (!ex) { closeFloat(); return; }
    var t = e.target, el;

    if ((el = t.closest('.lu-anc')) && !/m-loop|m-click/.test(el.className)) { el.classList.toggle('open'); closeFloat(); return; }
    if ((el = t.closest('.lu-mst'))) {
      var d = el.querySelector('.lu-mdraw'), L = lbl(el);
      if (d) open('lv-dr-' + (d.classList.contains('left') ? 'left' : d.classList.contains('bottom') ? 'bottom' : d.classList.contains('flush') ? 'flush' : 'right'));
      else {
        var a = (el.className.match(/\ba-([\w-]+)/) || [])[1], lay = el.querySelector('.lay');
        var id = /chip/.test(L) ? 'lv-md-chip' : /alert/.test(L) ? 'lv-md-alert' : lay && lay.classList.contains('top') ? 'lv-md-top' : (lay && lay.classList.contains('bottom') && !a) ? 'lv-md-bottom' : /^full/.test(L) ? 'lv-md-full' : /^(xs|sm|md|lg|xl)\b/.test(L) ? 'lv-md-s-' + L.split(/\W/)[0] : a ? 'lv-md-' + a : 'lv-md-scale';
        open(id);
      }
      return;
    }
    if ((page === 'drawer' || page === 'modal') && (el = t.closest('.lu-row'))) {
      var s = el.querySelector('.mono'); var k = s && s.textContent.trim();
      if (k && /^(xs|sm|md|lg|wide|xl|full)$/.test(k)) { open(page === 'drawer' ? 'lv-dr-s-' + (k === 'xs' ? 'sm' : k === 'full' ? 'xl' : k) : (k === 'full' ? 'lv-md-full' : 'lv-md-s-' + (k === 'wide' ? 'xl' : k))); return; }
    }
    if ((el = t.closest('[data-toast]'))) return; // botões do Toaster já disparam sozinhos
    if ((el = t.closest('.lu-stoast'))) { if (!t.closest('.act')) { var m = el.querySelector('.msg'); toast({status: 'run', title: m ? m.innerHTML : 'Processando', action: (el.querySelector('.act') || {}).textContent}); } else toast({kind: 'neutral', title: t.textContent.trim()}); return; }
    if ((el = t.closest('.lu-tcard,.lu-toast'))) { var b = el.querySelector('b'), sp = el.querySelector('.t span, .t > span'); toast({kind: el.querySelector('.lu-sp') ? 'loading' : kindOf(el), title: b ? b.textContent : 'Notificação', desc: sp ? sp.textContent : ''}); return; }
    if ((el = t.closest('.lu-acc2 .hd'))) { el.parentNode.classList.toggle('on'); return; }
    if ((el = t.closest('.lu-tb > button, .lu-seg > button, [role=tablist] > button, .lu-pg2 > button, .lu-vs > button'))) { sibOn(el); return; }
    if ((el = t.closest('.lu-al .x, .lu-al [aria-label=Fechar]'))) { var al = el.closest('.lu-al'); al.classList.add('lv-gone'); setTimeout(function () { al.classList.remove('lv-gone'); }, 2600); return; }
    if ((el = t.closest('.lu-sw'))) { e.preventDefault(); el.classList.toggle('on'); return; }
    if ((el = t.closest('.lu-clipswap')) || (page === 'clipboard' && (el = t.closest('button')))) { if (el.classList.contains('lu-clipswap')) el.classList.add('lv-done'); toast({kind: 'success', title: 'Copiado', desc: 'Chave Pix na área de transferência'}); setTimeout(function () { el.classList.remove('lv-done'); }, 1800); return; }
    if ((el = t.closest('.lu-sel2 .lu-input, .lu-select, .lu-sel2'))) { selTarget = el; showFloat(el, OPTS.map(function (o) { return '<button class="lu-menu-item" type="button" data-pick="' + o + '">' + I('building') + o + '</button>'; }).join(''), Math.max(240, el.getBoundingClientRect().width)); return; }
    if ((el = t.closest('.lu-bell'))) { el.classList.remove('lv-ring'); void el.offsetWidth; el.classList.add('lv-ring'); showFloat(el, NTF.map(function (n, k) { return '<div class="lu-ntf ' + (k < 2 ? 'unread' : '') + '" data-ntf="1"><span class="lu-dot" style="margin-top:6px"></span><span class="tx">' + n + '</span><time>' + ['agora', '5 min', '1 h'][k] + '</time></div>'; }).join(''), 340); return; }
    if ((el = t.closest('.lu-cmd'))) { open('lv-cmd'); return; }
    if (MENU_PAGES.test(page) && (el = t.closest('button, .lu-kebab')) && !t.closest('.lu-pop')) { showFloat(el, ACTIONS); return; }
    if ((el = t.closest('.lu-pop .lu-menu-item'))) { sibOn(el); el.classList.add('hl'); toast({kind: 'neutral', title: el.textContent.trim()}); return; }
    closeFloat();
  });
  document.addEventListener('contextmenu', function (e) {
    if (page !== 'context-menu' && page !== 'table' && page !== 'data-table') return;
    var row = e.target.closest('#main .d-exp .lu-row, #main .d-exp tr'); if (!row) return;
    e.preventDefault(); var m = document.getElementById('lv-ctx'); if (!m) return;
    m.style.left = Math.min(e.clientX, innerWidth - 240) + 'px'; m.style.top = Math.min(e.clientY, innerHeight - 230) + 'px'; m.classList.add('open');
  });
  addEventListener('scroll', closeFloat, {passive: true});
  addEventListener('keydown', function (e) { if (e.key === 'Escape') { closeFloat(); document.querySelectorAll('#main .lu-anc.open').forEach(function (a) { a.classList.remove('open'); }); } });
})();
