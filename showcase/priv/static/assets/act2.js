/* Vitrine · formulários e entradas que respondem de verdade */
(function () {
  var LOOP = /(^|\s)(m-loop|m-type|m-grow|m-click|m-hover|mo-[\w-]+)(\s|$)/;
  function still(el) { for (var e = el; e && !e.classList.contains('d-exp'); e = e.parentElement) if (LOOP.test(e.className && e.className.baseVal !== undefined ? e.className.baseVal : e.className)) return false; return true; }
  function inEx(el) { return el && el.closest('#main .d-exp'); }
  function toast(o) { return window.LedgerLive ? LedgerLive.toast(o) : null; }
  function fmtSize(n) { return n > 1048576 ? (n / 1048576).toFixed(1).replace('.', ',') + ' MB' : Math.max(1, Math.round(n / 1024)) + ' KB'; }
  var picker = document.createElement('input'); picker.type = 'file'; picker.multiple = true; picker.style.display = 'none';
  document.addEventListener('DOMContentLoaded', function () { document.body.appendChild(picker); });
  var onPick = null;
  picker.addEventListener('change', function () { var f = [].slice.call(picker.files || []); picker.value = ''; if (f.length && onPick) onPick(f); });
  function pick(accept, multiple, cb) { picker.accept = accept || ''; picker.multiple = !!multiple; onPick = cb; picker.click(); }

  function fileRow(f) {
    var ext = (f.name.split('.').pop() || 'arq').slice(0, 4).toUpperCase();
    var r = document.createElement('div'); r.className = 'lu-file lv-new';
    r.innerHTML = '<span class="ft">' + ext + '</span><div class="meta"><b></b><span>Enviando… 0%</span><div class="pb"><i style="--sp:0%"></i></div></div><button aria-label="Remover" class="lu-btn icon ghost sm" type="button" data-lv-rm><i data-i="x"></i></button>';
    r.querySelector('b').textContent = f.name;
    if (window.LedgerUI) LedgerUI.hydrate(r);
    var p = 0, bar = r.querySelector('.pb i'), st = r.querySelector('.meta span');
    var iv = setInterval(function () { p = Math.min(100, p + 8 + Math.random() * 18); bar.style.setProperty('--sp', p + '%'); st.textContent = p < 100 ? 'Enviando… ' + Math.round(p) + '%' : fmtSize(f.size) + ' · enviado'; if (p >= 100) { clearInterval(iv); r.classList.add('done'); } }, 220);
    return r;
  }
  function listFor(zone) {
    var host = zone.closest('.lu-cell, .lu-col, .d-in2') || zone.parentNode;
    var l = host.querySelector(':scope > .lv-files'); if (!l) { l = document.createElement('div'); l.className = 'lv-files'; zone.insertAdjacentElement('afterend', l); }
    return l;
  }
  function upload(zone, files) {
    var l = listFor(zone); files.forEach(function (f) { l.appendChild(fileRow(f)); });
    var t = toast({kind: 'loading', title: 'Enviando ' + files.length + (files.length > 1 ? ' arquivos…' : ' arquivo…')});
    setTimeout(function () { if (t && t.update) t.update({kind: 'success', title: files.length > 1 ? files.length + ' arquivos enviados' : 'Arquivo enviado', desc: files[0].name}); }, 2600);
  }
  function setImg(box, f) {
    var url = URL.createObjectURL(f);
    box.classList.add('has', 'lv-img'); box.style.backgroundImage = 'url("' + url + '")';
    [].forEach.call(box.childNodes, function (n) { if (n.nodeType === 3) n.textContent = ''; });
    toast({kind: 'success', title: 'Imagem trocada', desc: f.name});
  }

  document.addEventListener('click', function (e) {
    var t = e.target, el, ex = inEx(t); if (!ex) return;
    var page = (location.hash || '').slice(1);

    if ((el = t.closest('[data-lv-rm]'))) { var row = el.closest('.lu-file'); row.style.opacity = 0; setTimeout(function () { row.remove(); }, 180); return; }
    if ((el = t.closest('.lu-file [aria-label=Remover]'))) { var r2 = el.closest('.lu-file'); r2.classList.add('lv-gone'); setTimeout(function () { r2.classList.remove('lv-gone'); }, 2400); return; }
    if ((el = t.closest('.lu-upz, .lu-drop, .lu-thumbs .add')) || (page === 'upload' && (el = t.closest('.lu-b')))) { var z = el; pick('', true, function (f) { upload(z, f); var s = z.parentNode.querySelector('.lu-xs.lu-muted'); if (s && /nenhum/.test(s.textContent)) s.textContent = f.length + (f.length > 1 ? ' arquivos escolhidos' : ' arquivo: ' + f[0].name); }); return; }
    if ((el = t.closest('.lu-imgin'))) { var b = el; pick('image/*', false, function (f) { setImg(b, f[0]); }); return; }

    if ((el = t.closest('.lu-stars svg')) && still(el)) { var ss = [].slice.call(el.parentNode.querySelectorAll('svg')), k = ss.indexOf(el); ss.forEach(function (s, i) { s.setAttribute('class', i <= k ? 'on' : 'off'); }); var lab = el.parentNode.parentNode.querySelector('.lu-xs:not(.lu-muted), b'); toast({kind: 'success', title: 'Nota ' + (k + 1) + ' de ' + ss.length}); return; }
    if ((el = t.closest('.lu-num > button')) && still(el)) { var v = el.parentNode.querySelector('.v'); if (!v) return; var txt = v.textContent, m = txt.match(/-?[\d.,]+/); var n = m ? parseFloat(m[0].replace(/\./g, '').replace(',', '.')) : 0; var dec = m && m[0].indexOf(',') >= 0 ? (m[0].split(',')[1] || '').length : 0; n += (el.classList.contains('plus') || /Aumentar/.test(el.getAttribute('aria-label'))) ? 1 : -1; if (n < 0) n = 0; var s = dec ? n.toFixed(dec).replace('.', ',') : String(n); v.textContent = m ? txt.replace(m[0], s) : s; v.classList.remove('lv-bump'); void v.offsetWidth; v.classList.add('lv-bump'); return; }
    if ((el = t.closest('.lu-otp2')) && still(el)) { otp(el); return; }
    if ((el = t.closest('.lu-input .eye, .lu-input [aria-label*=senha]'))) { pwToggle(el); return; }
    if ((el = t.closest('.lu-input .val, .lu-ta .tx')) && still(el)) { el.contentEditable = 'true'; el.spellcheck = false; el.focus(); var c = el.closest('.lu-input, .lu-ta'); c.classList.add('focus', 'lv-focus'); el.onblur = function () { c.classList.remove('lv-focus'); if (!c.classList.contains('m-err')) c.classList.remove('focus'); }; return; }
    if ((el = t.closest('.lu-input')) && still(el) && !t.closest('button')) { var vv = el.querySelector('.val'); if (vv) { vv.contentEditable = 'true'; vv.focus(); el.classList.add('focus', 'lv-focus'); vv.onblur = function () { el.classList.remove('focus', 'lv-focus'); }; } return; }
    if ((el = t.closest('.lu-pbox .lu-chip i, .lu-pbox .lu-chip [data-i=x]'))) { var ch = el.closest('.lu-chip'); ch.style.transition = 'opacity .15s, transform .15s'; ch.style.opacity = 0; ch.style.transform = 'scale(.8)'; setTimeout(function () { ch.remove(); }, 160); return; }
    if ((el = t.closest('.lu-pbox')) && !t.closest('.lu-chip')) { addChip(el); return; }
    if ((el = t.closest('.lu-chip')) && !el.closest('.lu-pbox, .lu-tag') && still(el)) { el.classList.toggle('on'); return; }
    if ((el = t.closest('.lu-cal .d, .lu-cal2 > .d')) && still(el) && !el.classList.contains('o')) { el.parentNode.querySelectorAll('.d.s, .d.r, .d.rs, .d.re').forEach(function (x) { x.classList.remove('s', 'r', 'rs', 're'); }); el.classList.add('s'); toast({kind: 'neutral', title: 'Dia ' + el.textContent.trim() + ' selecionado'}); return; }
    if ((el = t.closest('.lu-tlist span')) && still(el.parentNode)) { [].forEach.call(el.parentNode.children, function (x) { x.classList.toggle('on', x === el); }); return; }
    if ((el = t.closest('.lu-swatches > button, .lu-sw2'))) { [].forEach.call(el.parentNode.children, function (x) { x.classList.toggle('on', x === el); }); var pv = el.closest('.d-in2').querySelector('.lu-cpick .pv, .lu-input .val'); if (pv && el.getAttribute('aria-label')) pv.textContent = el.getAttribute('aria-label'); return; }
    if ((el = t.closest('.lu-ts > span')) && still(el.parentNode)) { [].forEach.call(el.parentNode.children, function (x) { x.classList.toggle('on', x === el); }); var want = el.querySelector('[data-i=moon]') ? 'dark' : el.querySelector('[data-i=sun]') ? 'light' : null; var cur = document.documentElement.getAttribute('data-theme'); if (want && want !== cur) document.getElementById('th').click(); return; }
    if ((el = t.closest('.lu-tree-i')) && !t.closest('input, label')) { tree(el); return; }
    if ((el = t.closest('.lu-kcol .h button'))) { var col = el.closest('.lu-kcol'), card = col.querySelector('.lu-kcard'); if (card) { var nc = card.cloneNode(true); nc.classList.add('lv-new'); var bb = nc.querySelector('b'); if (bb) bb.textContent = 'Novo pedido'; col.appendChild(nc); count(col); } return; }
    if ((el = t.closest('.lu-cdots i, .lu-carousel2 ~ .lu-row .lu-btn, .lu-carousel2 .lu-btn, .lu-carousel2'))) {
      var host = el.closest('.lu-col, .lu-cell, .d-in2'); var car = host && host.querySelector('.lu-carousel2'); if (!car) return; var tr = car.querySelector('.tr'); var n = tr.children.length - (tr.children.length > 3 ? 1 : 0);
      var k = +(car.dataset.k || 0);
      if (el.tagName === 'I' && el.parentNode.classList.contains('lu-cdots')) k = [].indexOf.call(el.parentNode.children, el);
      else if (el.querySelector && el.querySelector('[data-i=chevron-left], [data-i=arrow-left]')) k = (k - 1 + n) % n; else k = (k + 1) % n;
      car.dataset.k = k; tr.style.animation = 'none'; tr.style.transition = 'transform .45s cubic-bezier(.3,.7,.3,1)'; tr.style.transform = 'translateX(' + (-100 * k) + '%)'; [].forEach.call(tr.children, function (c) { c.style.animation = 'none'; c.style.opacity = 1; });
      var dots = host.querySelectorAll('.lu-cdots i'); [].forEach.call(dots, function (d, i) { d.style.animation = 'none'; d.classList.toggle('on', i === k); d.style.background = i === k ? 'var(--ink)' : ''; d.style.width = i === k ? '18px' : ''; });
      return;
    }
  });

  function pwToggle(btn) {
    var inp = btn.closest('.lu-input'), val = inp.querySelector('.val') || inp.querySelector('.lu-dots'); if (!val) return;
    inp.querySelectorAll('[class*="mo-"], .lu-swap2').forEach(function (x) { x.style.animation = 'none'; });
    var dots = val.querySelector('.lu-dots') || (val.classList.contains('lu-dots') ? val : null);
    if (!val.dataset.pw) { val.dataset.pw = dots ? 'Bompreco#2026' : val.textContent.trim(); }
    var showing = inp.classList.toggle('lv-show');
    var plain = val.dataset.pw, mask = '•'.repeat(Math.max(8, plain.length));
    if (dots) { dots.textContent = showing ? plain : mask; dots.style.letterSpacing = showing ? '0' : ''; }
    else val.textContent = showing ? plain : mask;
    if (!showing && !dots) val.style.letterSpacing = '.12em'; else val.style.letterSpacing = '';
    var ic = btn.querySelector('svg, i'); var ni = document.createElement('i'); ni.setAttribute('data-i', showing ? 'eye-off' : 'eye'); if (ic) ic.replaceWith(ni); else btn.appendChild(ni);
    btn.setAttribute('aria-label', showing ? 'Ocultar a senha' : 'Mostrar a senha'); btn.setAttribute('aria-pressed', showing ? 'true' : 'false');
    if (window.LedgerUI) LedgerUI.hydrate(btn);
  }
  function indent(r) { return parseFloat(r.style.paddingLeft) || 0; }
  function flatTree(tr) {
    if (tr._flat) return; tr._flat = 1;
    tr.querySelectorAll('.mo-expand').forEach(function (w) { while (w.firstChild) w.parentNode.insertBefore(w.firstChild, w); w.remove(); });
    tr.querySelectorAll('[class*="mo-"]').forEach(function (x) { x.className = x.className.replace(/\bmo-[\w-]+/g, ''); x.style.animation = 'none'; });
  }
  function rowsBelow(r) { var out = [], lv = indent(r), n = r.nextElementSibling; while (n && n.classList.contains('lu-tree-i') && indent(n) > lv) { out.push(n); n = n.nextElementSibling; } return out; }
  function setChevron(r, open) { var tw = r.querySelector('.tw'); if (!tw) return; var ni = document.createElement('i'); ni.className = 'tw'; ni.setAttribute('data-i', open ? 'chevron-down' : 'chevron-right'); tw.replaceWith(ni); if (window.LedgerUI) LedgerUI.hydrate(r); }
  function tree(r) {
    var tr = r.closest('.lu-tree'); flatTree(tr);
    var isFolder = !!r.querySelector('.tw');
    if (!isFolder) { tr.querySelectorAll('.lu-tree-i.on').forEach(function (x) { x.classList.remove('on'); }); r.classList.add('on'); return; }
    var kids = rowsBelow(r), open = r.dataset.open ? r.dataset.open === '1' : !!(r.querySelector('[data-i=chevron-down], [data-icon=chevron-down]') && kids.length);
    if (!open && !kids.length) {
      var lv = indent(r) + 18, chk = !!r.querySelector('.lu-check'), name = r.textContent.replace(/\d+$/, '').trim();
      var after = r;
      ['Contas a pagar', 'Contas a receber', 'Conciliação'].forEach(function (nm, k) {
        var d = document.createElement('div'); d.className = 'lu-tree-i lv-new'; d.style.paddingLeft = lv + 'px';
        d.innerHTML = '<span style="width:16px"></span>' + (chk ? '<label class="lu-check" style="margin-right:2px"><input type="checkbox"></label>' : '') + '<i class="md" data-i="file"></i>' + (name === 'Financeiro' ? nm : nm.replace('Contas a ', '') + ' · ' + name) + '<span class="r">' + (k * 7 + 3) + '</span>';
        after.insertAdjacentElement('afterend', d); after = d;
      });
      if (window.LedgerUI) LedgerUI.hydrate(tr);
      kids = rowsBelow(r);
    }
    open = !open; r.dataset.open = open ? '1' : '0';
    kids.forEach(function (k) { if (!open) { k.classList.add('lv-closed'); } else if (indent(k) === indent(kids[0])) { k.classList.remove('lv-closed'); if (k.querySelector('.tw') && k.dataset.open === '1') rowsBelow(k).forEach(function (g) { g.classList.remove('lv-closed'); }); } });
    setChevron(r, open);
  }
  document.addEventListener('change', function (e) {
    var cb = e.target; if (!cb.matches || !cb.matches('#main .d-exp .lu-tree .lu-check input')) return;
    var r = cb.closest('.lu-tree-i'), tr = r.closest('.lu-tree'); flatTree(tr);
    rowsBelow(r).forEach(function (k) { var c = k.querySelector('.lu-check input'); if (c) { c.checked = cb.checked; c.indeterminate = false; } });
    var rows = [].slice.call(tr.querySelectorAll('.lu-tree-i'));
    rows.slice().reverse().forEach(function (p) { if (!p.querySelector('.tw')) return; var c = p.querySelector('.lu-check input'); var ks = rowsBelow(p).map(function (k) { return k.querySelector('.lu-check input'); }).filter(Boolean); if (!c || !ks.length) return; var n = ks.filter(function (k) { return k.checked; }).length; c.checked = n === ks.length; c.indeterminate = n > 0 && n < ks.length; });
  });
  function count(col) { var n = col.querySelector('.h .n'); if (n) n.textContent = col.querySelectorAll('.lu-kcard').length; }
  function addChip(box) {
    var inp = box.querySelector('input'); if (!inp) { inp = document.createElement('input'); inp.className = 'lv-chipin'; inp.placeholder = 'Adicionar…'; box.appendChild(inp); }
    inp.focus();
    inp.onkeydown = function (e) { if ((e.key === 'Enter' || e.key === ',') && inp.value.trim()) { e.preventDefault(); var c = document.createElement('span'); c.className = 'lu-chip lv-new'; c.style.height = '24px'; c.innerHTML = '<span></span> <i class="sm" data-i="x"></i>'; c.firstChild.textContent = inp.value.trim(); inp.insertAdjacentElement('beforebegin', c); if (window.LedgerUI) LedgerUI.hydrate(c); inp.value = ''; } if (e.key === 'Backspace' && !inp.value) { var cs = box.querySelectorAll('.lu-chip'); if (cs.length) cs[cs.length - 1].remove(); } };
  }
  function otp(box) {
    var cells = [].slice.call(box.querySelectorAll(':scope > i'));
    var inp = box.querySelector('.lv-otpin'); if (!inp) { inp = document.createElement('input'); inp.className = 'lv-otpin'; inp.inputMode = 'numeric'; inp.autocomplete = 'one-time-code'; box.appendChild(inp); }
    function paint() { var v = inp.value.replace(/\D/g, '').slice(0, cells.length); inp.value = v; cells.forEach(function (c, i) { var b = c.querySelector('b'); if (!b) { b = document.createElement('b'); c.appendChild(b); } b.textContent = v[i] || ''; c.classList.toggle('on', i === Math.min(v.length, cells.length - 1) && document.activeElement === inp); }); if (v.length === cells.length) { inp.blur(); cells.forEach(function (c) { c.classList.remove('on'); }); toast({kind: 'success', title: 'Código ' + v + ' confirmado'}); } }
    inp.value = ''; inp.oninput = paint; inp.onfocus = paint; inp.onblur = function () { cells.forEach(function (c) { c.classList.remove('on'); }); };
    inp.focus(); paint();
  }

  // slider: arrastar
  var drag = null;
  document.addEventListener('pointerdown', function (e) {
    var sl = e.target.closest('#main .d-exp .lu-sl'); if (sl && still(sl)) { drag = sl; sl.setPointerCapture && sl.setPointerCapture(e.pointerId); move(e); e.preventDefault(); return; }
    var sg = e.target.closest('#main .d-exp .lu-sig'); if (sg && still(sg)) { sign(sg, e); }
  });
  function move(e) { if (!drag) return; var r = drag.getBoundingClientRect(); var p = Math.max(0, Math.min(100, (e.clientX - r.left) / r.width * 100)); var a = parseFloat(getComputedStyle(drag).getPropertyValue('--a')) || 0; drag.style.setProperty('--sp', Math.max(p, a) + '%'); var w = drag.closest('.lu-slw'); var vv = w && w.querySelector('.vv'); if (vv) vv.textContent = Math.round(p) + '%'; var bub = drag.querySelector('.th b, .val'); if (bub) bub.textContent = Math.round(p); }
  document.addEventListener('pointermove', move);
  document.addEventListener('pointerup', function () { drag = null; });
  // assinatura: desenha de verdade
  function sign(pad, e) {
    var svg = pad.querySelector('svg'); if (!svg) return; e.preventDefault();
    if (!pad.dataset.lvSigned) { svg.innerHTML = ''; pad.dataset.lvSigned = '1'; var ty = pad.querySelector('.typed'); if (ty) ty.remove(); }
    var r = svg.getBoundingClientRect(); if (!svg.viewBox.baseVal || !svg.viewBox.baseVal.width) svg.setAttribute('viewBox', '0 0 ' + Math.round(r.width) + ' ' + Math.round(r.height)); var vb = svg.viewBox.baseVal;
    function pt(ev) { return ((ev.clientX - r.left) / r.width * vb.width).toFixed(1) + ' ' + ((ev.clientY - r.top) / r.height * vb.height).toFixed(1); }
    var path = document.createElementNS('http://www.w3.org/2000/svg', 'path'); var d = 'M' + pt(e); path.setAttribute('d', d); path.setAttribute('style', 'animation:none;stroke-dasharray:none;stroke-dashoffset:0;fill:none;stroke:var(--ink);stroke-width:' + (2.4 * vb.width / r.width).toFixed(2) + ';stroke-linecap:round;stroke-linejoin:round'); svg.appendChild(path);
    function mv(ev) { d += ' L' + pt(ev); path.setAttribute('d', d); }
    function up() { removeEventListener('pointermove', mv); removeEventListener('pointerup', up); }
    addEventListener('pointermove', mv); addEventListener('pointerup', up);
  }
  // kanban: arrastar cards entre colunas
  var kc = null;
  document.addEventListener('dragstart', function (e) { var c = e.target.closest && e.target.closest('#main .d-exp .lu-kcard'); if (c) { kc = c; c.classList.add('lv-drag'); e.dataTransfer.effectAllowed = 'move'; } });
  document.addEventListener('dragend', function () { if (kc) kc.classList.remove('lv-drag'); kc = null; document.querySelectorAll('.lu-kcol.lv-over').forEach(function (c) { c.classList.remove('lv-over'); }); });
  document.addEventListener('dragover', function (e) {
    var col = e.target.closest && e.target.closest('#main .d-exp .lu-kcol'); var z = e.target.closest && e.target.closest('#main .d-exp .lu-upz, #main .d-exp .lu-drop');
    if (col && kc) { e.preventDefault(); document.querySelectorAll('.lu-kcol.lv-over').forEach(function (c) { if (c !== col) c.classList.remove('lv-over'); }); col.classList.add('lv-over'); }
    if (z) { e.preventDefault(); z.classList.add('lv-hover'); }
  });
  document.addEventListener('dragleave', function (e) { var z = e.target.closest && e.target.closest('.lu-upz, .lu-drop'); if (z) z.classList.remove('lv-hover'); });
  document.addEventListener('drop', function (e) {
    var col = e.target.closest && e.target.closest('#main .d-exp .lu-kcol'); var z = e.target.closest && e.target.closest('#main .d-exp .lu-upz, #main .d-exp .lu-drop');
    if (col && kc) { e.preventDefault(); var from = kc.closest('.lu-kcol'); col.appendChild(kc); col.classList.remove('lv-over'); count(col); count(from); toast({kind: 'info', title: 'Card movido', desc: 'para ' + ((col.querySelector('.h') || {}).firstChild || {}).textContent}); }
    else if (z && e.dataTransfer.files.length) { e.preventDefault(); z.classList.remove('lv-hover'); upload(z, [].slice.call(e.dataTransfer.files)); }
  });
  window.LedgerAct2 = { mount: function (root) { root.querySelectorAll('.d-exp .lu-kcard').forEach(function (c) { if (still(c)) c.draggable = true; }); } };
})();
