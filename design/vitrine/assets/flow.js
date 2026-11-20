/* Vitrine · Flow: nós arrastáveis, conectores que acompanham, seleção e novo nó */
(function () {
  function nodes(c) { return [].slice.call(c.querySelectorAll(':scope > .lu-flow-node')); }
  function box(n) { return {x: n.offsetLeft, y: n.offsetTop, w: n.offsetWidth, h: n.offsetHeight}; }
  function dist(b, p) { var dx = Math.max(b.x - p[0], 0, p[0] - (b.x + b.w)), dy = Math.max(b.y - p[1], 0, p[1] - (b.y + b.h)); return Math.hypot(dx, dy); }
  function pts(d) {
    var tk = d.match(/[MLHVQCSTZmlhvqcstz]|-?\d*\.?\d+/g) || [], i = 0, cmd = '', x = 0, y = 0, start = null;
    var arity = {M: 2, L: 2, H: 1, V: 1, Q: 4, C: 6, S: 4, T: 2};
    while (i < tk.length) {
      if (/[A-Za-z]/.test(tk[i])) { cmd = tk[i++].toUpperCase(); if (cmd === 'Z') continue; }
      var n = arity[cmd] || 2, a = tk.slice(i, i + n).map(Number); i += n;
      if (cmd === 'H') x = a[0]; else if (cmd === 'V') y = a[0]; else { x = a[n - 2]; y = a[n - 1]; }
      if (!start) start = [x, y];
      if (cmd === 'M') cmd = 'L';
    }
    return [start || [0, 0], [x, y]];
  }
  function route(a, b) {
    var sx = a.x + a.w / 2, sy = a.y + a.h, tx = b.x + b.w / 2, ty = b.y;
    if (ty - sy > 16) {
      if (Math.abs(tx - sx) < 3) return 'M' + sx + ' ' + sy + ' V' + ty;
      var mid = (sy + ty) / 2, r = Math.min(14, Math.abs(tx - sx) / 2, (ty - sy) / 2), s = tx > sx ? 1 : -1;
      return 'M' + sx + ' ' + sy + ' V' + (mid - r) + ' Q' + sx + ' ' + mid + ' ' + (sx + s * r) + ' ' + mid + ' H' + (tx - s * r) + ' Q' + tx + ' ' + mid + ' ' + tx + ' ' + (mid + r) + ' V' + ty;
    }
    // alvo ao lado ou acima: sai pela lateral, entra pela outra lateral
    var right = b.x > a.x + a.w / 2, x1 = right ? a.x + a.w : a.x, y1 = a.y + a.h / 2, x2 = right ? b.x : b.x + b.w, y2 = b.y + b.h / 2, k = Math.max(40, Math.abs(x2 - x1) / 2) * (right ? 1 : -1);
    return 'M' + x1 + ' ' + y1 + ' C' + (x1 + k) + ' ' + y1 + ' ' + (x2 - k) + ' ' + y2 + ' ' + x2 + ' ' + y2;
  }
  function draw(c) { (c._edges || []).forEach(function (e) { e.p.setAttribute('d', route(box(e.a), box(e.b))); }); }
  function setup(c) {
    if (c._flow) return; c._flow = 1;
    var svg = c.querySelector(':scope > svg'); if (!svg) return;
    var ns = nodes(c), bs = ns.map(box);
    c._edges = [].slice.call(svg.querySelectorAll('path')).map(function (p) {
      var e = pts(p.getAttribute('d') || ''); if (!e[0][0] && !e[0][1]) return null;
      var ia = bs.map(function (b) { return dist(b, e[0]); }), a = ia.indexOf(Math.min.apply(null, ia));
      var ib = bs.map(function (b, i) { return i === a ? 1e9 : dist(b, e[1]); }), b = ib.indexOf(Math.min.apply(null, ib));
      return a >= 0 && b >= 0 && a !== b ? {p: p, a: ns[a], b: ns[b]} : null;
    }).filter(Boolean);
    svg.classList.remove('mo-draw'); svg.querySelectorAll('path').forEach(function (p) { p.style.animation = 'none'; if (!p.getAttribute('stroke-dasharray')) { p.style.strokeDasharray = 'none'; p.style.strokeDashoffset = 0; } });
    ns.forEach(function (n) { n.classList.remove('mo-glow'); n.style.animation = 'none'; });
    draw(c);
    if (!c.querySelector('.lv-flowbar')) {
      var bar = document.createElement('div'); bar.className = 'lv-flowbar';
      bar.innerHTML = '<button type="button" data-flow-add><i data-i="plus"></i>Novo passo</button><span>Arraste os nós · clique para selecionar</span>';
      c.appendChild(bar); if (window.LedgerUI) LedgerUI.hydrate(bar);
    }
  }
  var drag = null;
  document.addEventListener('pointerdown', function (e) {
    var n = e.target.closest('#main .d-exp .lu-flow-node'); if (!n) return;
    var c = n.parentElement; setup(c);
    c.querySelectorAll('.lu-flow-node.on').forEach(function (x) { x.classList.remove('on'); }); n.classList.add('on');
    drag = {n: n, c: c, x: e.clientX, y: e.clientY, l: n.offsetLeft, t: n.offsetTop, moved: false};
    n.setPointerCapture && n.setPointerCapture(e.pointerId); n.classList.add('lv-grab'); e.preventDefault();
  });
  document.addEventListener('pointermove', function (e) {
    if (!drag) return; var dx = e.clientX - drag.x, dy = e.clientY - drag.y; if (Math.abs(dx) + Math.abs(dy) > 2) drag.moved = true;
    var c = drag.c, n = drag.n;
    var l = Math.max(6, Math.min(c.clientWidth - n.offsetWidth - 6, drag.l + dx)), t = Math.max(6, Math.min(c.clientHeight - n.offsetHeight - 6, drag.t + dy));
    l = Math.round(l / 6) * 6; t = Math.round(t / 6) * 6;
    n.style.left = l + 'px'; n.style.top = t + 'px'; draw(c);
  });
  document.addEventListener('pointerup', function () { if (drag) { drag.n.classList.remove('lv-grab'); drag = null; } });
  document.addEventListener('click', function (e) {
    var add = e.target.closest('#main [data-flow-add]'); if (!add) return;
    var c = add.closest('.lv-flowbar').parentElement; setup(c);
    var sel = c.querySelector('.lu-flow-node.on') || nodes(c).pop(); var sb = box(sel);
    var n = document.createElement('div'); n.className = 'lu-flow-node lv-new'; n.style.position = 'absolute';
    var k = nodes(c).length;
    n.innerHTML = '<span class="lu-ic acc"><i class="md" data-i="' + ['bell', 'clock', 'check', 'zap'][k % 4] + '"></i></span><span class="t"><b class="lu-small">' + ['Notificar no WhatsApp', 'Esperar 1 dia', 'Marcar como resolvido', 'Novo gatilho'][k % 4] + '</b><small>Passo ' + (k + 1) + '</small></span>';
    c.insertBefore(n, c.querySelector('.lv-flowbar')); if (window.LedgerUI) LedgerUI.hydrate(n);
    var l = Math.min(c.clientWidth - n.offsetWidth - 6, sb.x + sb.w + 40), t = Math.min(c.clientHeight - n.offsetHeight - 50, sb.y + 40);
    if (l < sb.x + sb.w) { l = sb.x; t = Math.min(c.clientHeight - n.offsetHeight - 50, sb.y + sb.h + 40); }
    n.style.left = l + 'px'; n.style.top = t + 'px';
    var svg = c.querySelector(':scope > svg'), p = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    p.setAttribute('fill', 'none'); p.setAttribute('stroke', 'var(--line-strong)'); p.setAttribute('stroke-width', '1.5'); svg.appendChild(p);
    c._edges.push({p: p, a: sel, b: n}); draw(c);
    c.querySelectorAll('.lu-flow-node.on').forEach(function (x) { x.classList.remove('on'); }); n.classList.add('on');
  });
  window.LedgerFlow = { mount: function (root) { root.querySelectorAll('.d-exp .lu-flow-node').forEach(function (n) { var c = n.parentElement; if (c.querySelector(':scope > svg')) setup(c); }); } };
})();
