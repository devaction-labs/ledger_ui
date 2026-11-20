/* Vitrine · Flow: cada card ramifica pelo + (embaixo e nas laterais), condição abre Sim/Não, nós arrastáveis */
(function () {
  var SVGNS = 'http://www.w3.org/2000/svg';
  var TYPES = [
    {k: 'acao', ic: 'zap', c: 'acc', t: 'Atualizar pedido', s: 'Ação · ERP'},
    {k: 'cond', ic: 'filter', c: 'warn', t: 'Valor acima de R$ 1.000?', s: 'Condição'},
    {k: 'wait', ic: 'clock', c: 'info', t: 'Esperar 1 dia', s: 'Espera'},
    {k: 'zap', ic: 'bell', c: 'lime', t: 'Avisar no WhatsApp', s: 'Notificação'},
    {k: 'mail', ic: 'mail', c: 'info', t: 'Enviar e-mail', s: 'Ação · modelo'},
    {k: 'ai', ic: 'ai', c: 'lime', t: 'Resumir com IA', s: 'IA'}
  ];
  var LABEL = {acao: 'Ação', cond: 'Condição', wait: 'Esperar', zap: 'Notificar', mail: 'E-mail', ai: 'IA'};
  function nodes(c) { return [].slice.call(c.querySelectorAll(':scope > .lu-flow-node')); }
  function box(n) { return {x: n.offsetLeft, y: n.offsetTop, w: n.offsetWidth, h: n.offsetHeight}; }
  function dist(b, p) { var dx = Math.max(b.x - p[0], 0, p[0] - (b.x + b.w)), dy = Math.max(b.y - p[1], 0, p[1] - (b.y + b.h)); return Math.hypot(dx, dy); }
  function pts(d) {
    var tk = d.match(/[MLHVQCSTZmlhvqcstz]|-?\d*\.?\d+/g) || [], i = 0, cmd = '', x = 0, y = 0, start = null;
    var ar = {M: 2, L: 2, H: 1, V: 1, Q: 4, C: 6, S: 4, T: 2};
    while (i < tk.length) {
      if (/[A-Za-z]/.test(tk[i])) { cmd = tk[i++].toUpperCase(); if (cmd === 'Z') continue; }
      var n = ar[cmd] || 2, a = tk.slice(i, i + n).map(Number); i += n;
      if (cmd === 'H') x = a[0]; else if (cmd === 'V') y = a[0]; else { x = a[n - 2]; y = a[n - 1]; }
      if (!start) start = [x, y]; if (cmd === 'M') cmd = 'L';
    }
    return [start || [0, 0], [x, y]];
  }
  function route(a, b, side) {
    if (side === 'r' || side === 'l') {
      var R = side === 'r', x1 = R ? a.x + a.w : a.x, y1 = a.y + a.h / 2, x2 = R ? b.x : b.x + b.w, y2 = b.y + b.h / 2;
      if (R ? x2 < x1 + 12 : x2 > x1 - 12) { x2 = b.x + b.w / 2; y2 = b.y; var kx = (x2 - x1); return 'M' + x1 + ' ' + y1 + ' C' + (x1 + (R ? 40 : -40)) + ' ' + y1 + ' ' + x2 + ' ' + (y2 - 40) + ' ' + x2 + ' ' + y2; }
      var k = Math.max(30, Math.abs(x2 - x1) / 2) * (R ? 1 : -1);
      return 'M' + x1 + ' ' + y1 + ' C' + (x1 + k) + ' ' + y1 + ' ' + (x2 - k) + ' ' + y2 + ' ' + x2 + ' ' + y2;
    }
    var sx = a.x + a.w / 2, sy = a.y + a.h, tx = b.x + b.w / 2, ty = b.y;
    if (ty - sy > 16) {
      if (Math.abs(tx - sx) < 3) return 'M' + sx + ' ' + sy + ' V' + ty;
      var mid = sy + Math.min(28, (ty - sy) / 2), r = Math.min(12, Math.abs(tx - sx) / 2, (ty - sy) / 2), s = tx > sx ? 1 : -1;
      return 'M' + sx + ' ' + sy + ' V' + (mid - r) + ' Q' + sx + ' ' + mid + ' ' + (sx + s * r) + ' ' + mid + ' H' + (tx - s * r) + ' Q' + tx + ' ' + mid + ' ' + tx + ' ' + (mid + r) + ' V' + ty;
    }
    var right = b.x > a.x + a.w / 2, x1b = right ? a.x + a.w : a.x, y1b = a.y + a.h / 2, x2b = right ? b.x : b.x + b.w, y2b = b.y + b.h / 2, kb = Math.max(40, Math.abs(x2b - x1b) / 2) * (right ? 1 : -1);
    return 'M' + x1b + ' ' + y1b + ' C' + (x1b + kb) + ' ' + y1b + ' ' + (x2b - kb) + ' ' + y2b + ' ' + x2b + ' ' + y2b;
  }
  function draw(c) {
    (c._edges || []).forEach(function (e) {
      if (!e.a.isConnected || !e.b.isConnected) { e.p.remove(); if (e.t) e.t.remove(); e.dead = 1; return; }
      e.p.setAttribute('d', route(box(e.a), box(e.b), e.side));
      if (e.t) { var L = e.p.getTotalLength(), m = e.p.getPointAtLength(L * 0.55); e.t.setAttribute('x', m.x); e.t.setAttribute('y', m.y); e.tb.setAttribute('x', m.x - 18); e.tb.setAttribute('y', m.y - 10); }
    });
    c._edges = (c._edges || []).filter(function (e) { return !e.dead; });
  }
  function grow(c) {
    var need = 0; nodes(c).forEach(function (n) { need = Math.max(need, n.offsetTop + n.offsetHeight + 24); });
    if (need > c.clientHeight) c.style.height = need + 'px';
  }
  function handles(n) {
    if (n.querySelector('.lv-fh')) return;
    ['b', 'r', 'l'].forEach(function (s) { var h = document.createElement('button'); h.type = 'button'; h.className = 'lv-fh ' + s; h.dataset.flowH = s; h.setAttribute('aria-label', 'Ramificar ' + {b: 'para baixo', r: 'para a direita', l: 'para a esquerda'}[s]); h.innerHTML = '<svg viewBox="0 0 24 24"><path d="M12 6v12M6 12h12"/></svg>'; n.appendChild(h); });
  }
  function setup(c) {
    if (c._flow) return; c._flow = 1;
    var svg = c.querySelector(':scope > svg'); if (!svg) return;
    var ns = nodes(c), bs = ns.map(box);
    c._edges = [].slice.call(svg.querySelectorAll('path')).map(function (p) {
      var e = pts(p.getAttribute('d') || '');
      var ia = bs.map(function (b) { return dist(b, e[0]); }), a = ia.indexOf(Math.min.apply(null, ia));
      var ib = bs.map(function (b, i) { return i === a ? 1e9 : dist(b, e[1]); }), b = ib.indexOf(Math.min.apply(null, ib));
      return a >= 0 && b >= 0 && a !== b ? {p: p, a: ns[a], b: ns[b], side: 'b'} : null;
    }).filter(Boolean);
    svg.classList.remove('mo-draw'); svg.style.overflow = 'visible';
    svg.querySelectorAll('path').forEach(function (p) { p.style.animation = 'none'; if (!p.getAttribute('stroke-dasharray')) { p.style.strokeDasharray = 'none'; p.style.strokeDashoffset = 0; } });
    ns.forEach(function (n) { n.classList.remove('mo-glow'); n.style.animation = 'none'; handles(n); });
    if (!c.querySelector('.lv-flowtip')) { var tip = document.createElement('div'); tip.className = 'lv-flowtip'; tip.textContent = 'Clique num card e use o + para ramificar · arraste para mover · Delete apaga'; c.appendChild(tip); }
    draw(c);
  }
  function mkNode(c, t, ghost) {
    var n = document.createElement('div'); n.className = 'lu-flow-node lv-new' + (ghost ? ' lv-ghost' : ''); n.style.position = 'absolute';
    n.innerHTML = ghost ? '<span class="lu-ic"><i class="md" data-i="plus"></i></span><span class="t"><b class="lu-small">Escolher passo</b><small>' + ghost + '</small></span>'
      : '<span class="lu-ic ' + t.c + '"><i class="md" data-i="' + t.ic + '"></i></span><span class="t"><b class="lu-small">' + t.t + '</b><small>' + t.s + '</small></span>';
    n.dataset.kind = ghost ? 'ghost' : t.k;
    c.insertBefore(n, c.querySelector('.lv-flowtip')); if (window.LedgerUI) LedgerUI.hydrate(n); handles(n);
    return n;
  }
  function edge(c, a, b, side, label) {
    var svg = c.querySelector(':scope > svg'), p = document.createElementNS(SVGNS, 'path');
    p.setAttribute('fill', 'none'); p.setAttribute('stroke', 'var(--line-strong)'); p.setAttribute('stroke-width', '1.5'); p.classList.add('lv-edge-new'); p.setAttribute('pathLength', '1'); svg.appendChild(p);
    var e = {p: p, a: a, b: b, side: side};
    if (label) {
      e.tb = document.createElementNS(SVGNS, 'rect'); e.tb.setAttribute('width', 36); e.tb.setAttribute('height', 20); e.tb.setAttribute('rx', 6); e.tb.setAttribute('class', 'lv-elb ' + (label === 'Sim' ? 'y' : 'n'));
      e.t = document.createElementNS(SVGNS, 'text'); e.t.textContent = label; e.t.setAttribute('class', 'lv-elt ' + (label === 'Sim' ? 'y' : 'n'));
      svg.appendChild(e.tb); svg.appendChild(e.t);
    }
    c._edges.push(e); return e;
  }
  function free(c, x, y, w, h, skip) {
    return !nodes(c).some(function (o) { if (o === skip) return false; var b = box(o); return x < b.x + b.w + 16 && x + w + 16 > b.x && y < b.y + b.h + 16 && y + h + 16 > b.y; });
  }
  function place(c, from, n, side, idx, of) {
    var a = box(from), w = n.offsetWidth, h = n.offsetHeight, x, y, gap = 64;
    var kids = c._edges.filter(function (e) { return e.a === from && e.side === side && e.b !== n; }).length + (idx || 0);
    if (side === 'b') { y = a.y + a.h + gap; x = a.x + (of ? (idx === 0 ? -(w / 2 + 14) : (w / 2 + 14)) : kids * (w + 24)); }
    else if (side === 'r') { x = a.x + a.w + gap; y = a.y + kids * (h + 28); }
    else { x = a.x - w - gap; y = a.y + kids * (h + 28); }
    x = Math.max(8, Math.min(c.clientWidth - w - 8, x)); y = Math.max(8, y);
    var tries = 0; while (!free(c, x, y, w, h, n) && tries++ < 12) { if (side === 'b') { x += w + 24; if (x > c.clientWidth - w - 8) { x = 8; y += h + 40; } } else y += h + 28; }
    n.style.left = Math.round(x) + 'px'; n.style.top = Math.round(y) + 'px';
  }
  function select(c, n) { c.querySelectorAll('.lu-flow-node.on').forEach(function (x) { x.classList.remove('on'); }); if (n) n.classList.add('on'); }
  // menu de tipos
  var menu = null, menuCtx = null;
  function openMenu(btn, ctx) {
    if (!menu) { menu = document.createElement('div'); menu.className = 'lu-pop lv-fm lv-fmenu'; document.body.appendChild(menu); }
    menuCtx = ctx;
    menu.innerHTML = '<div class="lu-menu-label">Adicionar passo</div>' + TYPES.map(function (t, i) { return '<button class="lu-menu-item" type="button" data-flow-t="' + i + '"><i data-i="' + t.ic + '"></i>' + LABEL[t.k] + '<span class="lv-sub">' + t.s + '</span></button>'; }).join('');
    if (window.LedgerUI) LedgerUI.hydrate(menu);
    var r = btn.getBoundingClientRect(); menu.style.width = '240px';
    menu.style.left = Math.min(innerWidth - 252, Math.max(8, r.left + r.width / 2 - 120)) + 'px';
    var top = r.bottom + 8; if (top + 300 > innerHeight) top = Math.max(8, r.top - 8 - 300);
    menu.style.top = top + 'px'; menu.classList.add('open');
  }
  function closeMenu() { if (menu) menu.classList.remove('open'); menuCtx = null; }
  function choose(i) {
    var ctx = menuCtx; closeMenu(); if (!ctx) return; var t = TYPES[i], c = ctx.c, n;
    if (ctx.ghost) {
      n = ctx.ghost; n.classList.remove('lv-ghost'); n.dataset.kind = t.k;
      n.querySelector('.lu-ic').className = 'lu-ic ' + t.c; n.querySelector('.lu-ic').innerHTML = '<i class="md" data-i="' + t.ic + '"></i>';
      n.querySelector('b').textContent = t.t; n.querySelector('small').textContent = t.s; if (window.LedgerUI) LedgerUI.hydrate(n);
    } else {
      n = mkNode(c, t); place(c, ctx.from, n, ctx.side); edge(c, ctx.from, n, ctx.side);
    }
    if (t.k === 'cond') {
      ['Sim', 'Não'].forEach(function (lab, k) { var g = mkNode(c, null, 'Caminho ' + lab); place(c, n, g, 'b', k, true); edge(c, n, g, 'b', lab); });
    }
    grow(c); draw(c); select(c, n);
    if (window.LedgerLive) LedgerLive.toast({kind: 'success', title: LABEL[t.k] + ' adicionada ao fluxo'});
  }
  // interação
  var drag = null;
  document.addEventListener('pointerdown', function (e) {
    if (e.target.closest('.lv-fh')) return;
    var n = e.target.closest('#main .d-exp .lu-flow-node'); if (!n) return;
    var c = n.parentElement; setup(c); select(c, n);
    if (n.classList.contains('lv-ghost')) return;
    drag = {n: n, c: c, x: e.clientX, y: e.clientY, l: n.offsetLeft, t: n.offsetTop};
    n.setPointerCapture && n.setPointerCapture(e.pointerId); n.classList.add('lv-grab'); e.preventDefault();
  });
  document.addEventListener('pointermove', function (e) {
    if (!drag) return; var c = drag.c, n = drag.n;
    var l = Math.max(6, Math.min(c.clientWidth - n.offsetWidth - 6, drag.l + e.clientX - drag.x)), t = Math.max(6, drag.t + e.clientY - drag.y);
    n.style.left = Math.round(l / 6) * 6 + 'px'; n.style.top = Math.round(t / 6) * 6 + 'px'; grow(c); draw(c);
  });
  document.addEventListener('pointerup', function () { if (drag) { drag.n.classList.remove('lv-grab'); drag = null; } });
  document.addEventListener('click', function (e) {
    var it = e.target.closest('[data-flow-t]'); if (it) { choose(+it.dataset.flowT); return; }
    if (menu && !menu.contains(e.target)) { var keep = e.target.closest('.lv-fh, .lv-ghost'); if (!keep) closeMenu(); }
    var h = e.target.closest('#main .lv-fh');
    if (h) { var n = h.closest('.lu-flow-node'), c = n.parentElement; setup(c); select(c, n); openMenu(h, {c: c, from: n, side: h.dataset.flowH}); return; }
    var g = e.target.closest('#main .lu-flow-node.lv-ghost');
    if (g) { openMenu(g, {c: g.parentElement, ghost: g}); return; }
    var ex = e.target.closest('#main .d-exp');
    if (ex && !e.target.closest('.lu-flow-node')) ex.querySelectorAll('.lu-flow-node.on').forEach(function (x) { x.classList.remove('on'); });
  });
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') closeMenu();
    if ((e.key === 'Delete' || e.key === 'Backspace') && !e.target.closest('input, textarea, [contenteditable=true]')) {
      var n = document.querySelector('#main .d-exp .lu-flow-node.on'); if (!n) return; var c = n.parentElement; if (nodes(c).length <= 1) return;
      e.preventDefault(); n.remove(); draw(c);
    }
  });
  addEventListener('scroll', closeMenu, {passive: true});
  window.LedgerFlow = { mount: function (root) { closeMenu(); root.querySelectorAll('.d-exp .lu-flow-node').forEach(function (n) { var c = n.parentElement; if (c.querySelector(':scope > svg')) setup(c); }); } };
})();
