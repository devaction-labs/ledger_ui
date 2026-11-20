/* Vitrine · componentes interativos de verdade (abrem na janela, não na prévia) */
(function () {
  var I = function (n, s) { return '<i data-i="' + n + '"' + (s ? ' data-s="' + s + '"' : '') + '></i>'; };
  var B = function (t, c, v, extra, icon) { return '<button type="button" class="lu-b c-' + (c || 'neutral') + ' v-' + (v || 'outline') + ' s-sm" ' + (extra || '') + '>' + (icon ? I(icon) : '') + t + '</button>'; };
  var FIELD = function (l, v, ph) { return '<div class="lu-field"><span class="lu-label">' + l + '</span><span class="lu-input"><input value="' + (v || '') + '" placeholder="' + (ph || '') + '"></span></div>'; };
  var FORM = FIELD('Razão social', '', 'Mercadinho Bom Preço Ltda') + FIELD('CNPJ', '', '00.000.000/0000-00') + FIELD('E-mail', '', 'contato@empresa.com.br') + '<label class="lu-sw on c-primary"><i></i><span class="t">Enviar boas-vindas por WhatsApp</span></label>';
  var X = function (chip) { return '<button class="lv-x ' + (chip ? 'chip' : '') + '" data-lv-close aria-label="Fechar">' + I('x') + '</button>'; };
  function ov(id, panelCls, style, title, desc, body, foot, chip) {
    return '<div class="lv-ov" id="' + id + '" role="dialog" aria-modal="true" aria-label="' + title + '"><div class="lv-bd" data-lv-close></div><div class="lv-p ' + panelCls + '" style="' + (style || '') + '">' +
      '<div class="lv-ph"><div><h3>' + title + '</h3>' + (desc ? '<p>' + desc + '</p>' : '') + '</div>' + X(chip) + '</div><div class="lv-pb">' + body + '</div>' +
      (foot !== false ? '<div class="lv-pf">' + (foot || B('Cancelar', 'neutral', 'outline', 'data-lv-close') + B('Salvar', 'mono', 'solid', 'data-lv-close data-lv-after=\'{"kind":"success","title":"Cliente salvo","desc":"Mercadinho Bom Preço"}\'')) + '</div>' : '') + '</div></div>';
  }
  var L = {};
  function play(title, html) { return '<div class="lv-play"><div class="lv-h"><i></i>' + (title || 'Experimente · interativo') + '</div>' + html + '</div>'; }
  function row(label, html) { return '<div class="lv-row"><span class="lv-lbl">' + label + '</span>' + html + '</div>'; }

  /* ---------- Toasts ---------- */
  var T = [['Neutral', { kind: 'neutral', title: 'Alterações salvas' }], ['Info', { kind: 'info', title: 'Nova versão disponível', desc: 'Atualize para a 2.4' }], ['Success', { kind: 'success', title: 'NF-e 48.211 autorizada', desc: 'Protocolo 129 2611' }], ['Warning', { kind: 'warning', title: 'Certificado vence em 3 dias' }], ['Error', { kind: 'error', title: 'SEFAZ recusou a nota', desc: 'Rejeição 539' }], ['Com ação', { kind: 'info', title: 'Pedido #2488 excluído', action: 'Desfazer' }], ['Invertido', { kind: 'success', title: 'Pagamento recebido', desc: 'Pix · R$ 3.120,50', invert: true }]];
  var S = [['Rodando', { status: 'run', title: 'Deploy <b>f798c00</b> compilando em <b>main</b>', action: 'Cancelar' }], ['Na fila', { status: 'queue', title: 'Lote <b>#118</b> na fila, <b>2 à frente</b>', action: 'Cancelar' }], ['Concluído', { status: 'ok', title: '<b>Backup</b> concluído, <b>1,2 GB</b>', action: 'Baixar' }], ['Falhou', { status: 'err', title: 'Deploy <b>c03b7e1</b> falhou na etapa <b>build</b>', action: 'Ver logs' }]];
  var POS = ['left-top', 'center-top', 'right-top', 'left-bottom', 'center-bottom', 'right-bottom'];
  var toastPlay = play('Experimente · dispara toasts de verdade nesta janela',
    row('Tipo', T.map(function (t) { return B(t[0], 'neutral', 'outline', "data-lv-toast='" + JSON.stringify(t[1]) + "'"); }).join('')) +
    row('Status', S.map(function (t) { return B(t[0], 'neutral', 'outline', "data-lv-toast='" + JSON.stringify(t[1]) + "'"); }).join('')) +
    row('Fluxos', B('Carregando → sucesso', 'primary', 'soft', 'data-lv-flow="load"', 'sparkles') + B('Progresso até 100%', 'primary', 'soft', 'data-lv-flow="prog"') + B('Status run → ok', 'neutral', 'soft', 'data-lv-flow="status"') + B('Pilha de 3', 'neutral', 'soft', 'data-lv-flow="stack"')) +
    row('Posição', '<div class="lu-seg sm" id="lv-pos">' + POS.map(function (p) { return '<button type="button" data-pos="' + p + '" class="' + (p === 'center-bottom' ? 'on' : '') + '">' + p + '</button>'; }).join('') + '</div>'));
  L['toaster'] = L['toast-card'] = L['status-toast'] = toastPlay;

  /* ---------- Drawer / Sheet ---------- */
  var dr = '';
  [['right', 'right · float', ''], ['left', 'left · float', 'left'], ['flush', 'right · flush', 'flush'], ['bottom', 'bottom', 'bottom']].forEach(function (d) {
    dr += ov('lv-dr-' + d[0], 'lv-dr ' + d[2], '', 'Novo cliente', 'Quem compra de você.', FORM);
  });
  [['sm', 400], ['md', 520], ['lg', 640], ['wide', 800], ['xl', 1080]].forEach(function (s) { dr += ov('lv-dr-s-' + s[0], 'lv-dr', '--w:' + s[1] + 'px', 'Pedido #2491', 'size=' + s[0] + ' · ' + s[1] + 'px', '<div class="lu-dl2" style="--cols:2"><div><dt>Cliente</dt><dd>Bom Preço</dd></div><div><dt>Total</dt><dd>R$ 1.284,90</dd></div><div><dt>Status</dt><dd>Pago</dd></div><div><dt>Entrega</dt><dd>Hoje, 14h</dd></div></div>'); });
  L['drawer'] = play('Experimente · abre a gaveta de verdade',
    row('placement', B('Direita', 'neutral', 'outline', 'data-lv-open="lv-dr-right"') + B('Esquerda', 'neutral', 'outline', 'data-lv-open="lv-dr-left"') + B('Colada (flush)', 'neutral', 'outline', 'data-lv-open="lv-dr-flush"') + B('Por baixo', 'neutral', 'outline', 'data-lv-open="lv-dr-bottom"')) +
    row('size', ['sm', 'md', 'lg', 'wide', 'xl'].map(function (s) { return B(s, 'neutral', 'soft', 'data-lv-open="lv-dr-s-' + s + '"'); }).join(''))) + dr;
  L['sheet'] = play('Experimente', row('Sheet', B('Abrir filtros', 'neutral', 'outline', 'data-lv-open="lv-sh"', 'filter'))) + ov('lv-sh', 'lv-dr bottom', '', 'Filtros', 'Refine a lista de pedidos.', '<label class="lu-check c-primary"><input type="checkbox" checked><span class="t">Pagos</span></label><label class="lu-check c-primary"><input type="checkbox"><span class="t">Atrasados</span></label><label class="lu-check c-primary"><input type="checkbox" checked><span class="t">Entrega hoje</span></label>');

  /* ---------- Modal ---------- */
  var md = '', A = ['fade', 'scale', 'sheet', 'shift-down', 'shift-up'];
  A.forEach(function (a) { md += ov('lv-md-' + a, 'lv-md a-' + a, '', 'Exportar relatório', 'animation="' + a + '"', '<span class="lu-small lu-muted">Escolha o formato do arquivo.</span><div class="lu-seg"><button class="on" type="button">PDF</button><button type="button">Excel</button><button type="button">CSV</button></div>'); });
  [['xs', 320], ['sm', 440], ['md', 560], ['lg', 720], ['xl', 960]].forEach(function (s) { md += ov('lv-md-s-' + s[0], 'lv-md a-scale', '--w:' + s[1] + 'px', 'size=' + s[0], s[1] + 'px de largura máxima', '<span class="lu-small lu-muted">Conteúdo do modal.</span>'); });
  md += ov('lv-md-full', 'lv-md full a-scale', '', 'size=full', 'Tela inteira', '<span class="lu-small lu-muted">Conteúdo ocupando toda a janela.</span>');
  md += ov('lv-md-top', 'lv-md top a-shift-down', '', 'placement=top', '', '<span class="lu-small lu-muted">Abre perto do topo.</span>');
  md += ov('lv-md-bottom', 'lv-md bottom a-shift-up', '', 'placement=bottom', '', '<span class="lu-small lu-muted">Abre perto da base.</span>');
  md += ov('lv-md-alert', 'lv-md a-scale', '--w:440px', 'Excluir pedido #2488?', 'Esta ação não pode ser desfeita.', '', B('Cancelar', 'neutral', 'outline', 'data-lv-close') + B('Excluir', 'error', 'solid', 'data-lv-close data-lv-after=\'{"kind":"neutral","title":"Pedido #2488 excluído","action":"Desfazer"}\''));
  md += ov('lv-md-chip', 'lv-md a-scale', '--w:480px', 'Capa da loja', 'close_variant="chip"', '<div style="height:150px;border-radius:12px;background:linear-gradient(135deg,var(--teal-300),var(--teal-700))"></div>', false, true);
  L['modal'] = play('Experimente · abre o modal de verdade',
    row('animation', A.map(function (a) { return B(a, 'neutral', 'outline', 'data-lv-open="lv-md-' + a + '"'); }).join('')) +
    row('size', ['xs', 'sm', 'md', 'lg', 'xl'].map(function (s) { return B(s, 'neutral', 'soft', 'data-lv-open="lv-md-s-' + s + '"'); }).join('') + B('full', 'neutral', 'soft', 'data-lv-open="lv-md-full"')) +
    row('outros', B('placement=top', 'neutral', 'outline', 'data-lv-open="lv-md-top"') + B('placement=bottom', 'neutral', 'outline', 'data-lv-open="lv-md-bottom"') + B('Confirmar exclusão', 'error', 'soft', 'data-lv-open="lv-md-alert"') + B('close_variant=chip', 'neutral', 'outline', 'data-lv-open="lv-md-chip"'))) + md;

  /* ---------- Dropdown / ActionMenu / Menu / Popover / Tooltip ---------- */
  var MENU = function (end) { return '<div class="lv-fl lu-pop ' + (end ? 'end' : '') + '" style="width:220px">' + [['Editar', 'edit'], ['Duplicar', 'copy'], ['Compartilhar', 'link']].map(function (m) { return '<button class="lu-menu-item" type="button" data-lv-closepop>' + I(m[1]) + m[0] + '</button>'; }).join('') + '<div class="lu-menu-sep"></div><button class="lu-menu-item danger" type="button" data-lv-closepop data-lv-after=\'{"kind":"neutral","title":"Pedido excluído","action":"Desfazer"}\'>' + I('trash') + 'Excluir</button></div>'; };
  var dd = function (trigger, end) { return '<span class="lv-anc">' + trigger + MENU(end) + '</span>'; };
  L['dropdown'] = L['menu'] = play('Experimente · clique para abrir',
    row('gatilhos', dd(B('Ações', 'neutral', 'outline', 'data-lv-pop') ) + dd(B('Ações', 'mono', 'solid', 'data-lv-pop')) + dd(B('Período', 'primary', 'soft', 'data-lv-pop')) + dd('<button class="lu-kebab" type="button" data-lv-pop aria-label="Mais">' + I('more-h') + '</button>', true)));
  L['action-menu'] = play('Experimente', row('linha', '<span class="lu-small" style="flex:1">Pedido #2491 · Mercadinho Bom Preço</span>' + dd('<button class="lu-kebab" type="button" data-lv-pop aria-label="Ações">' + I('more-h') + '</button>', true)));
  var POP = '<div class="lv-fl lu-pop pad right" style="width:260px;white-space:normal"><b style="font-size:13.5px">Ticket médio</b><p class="lu-small lu-muted" style="margin:4px 0 0">Faturamento dividido pelo número de pedidos pagos no período.</p></div>';
  L['popover'] = play('Experimente', row('clique', '<span class="lv-anc">' + B('O que é ticket médio?', 'neutral', 'outline', 'data-lv-pop', 'info') + POP + '</span>'));
  var TIPC = ['neutral', 'light', 'dark', 'primary', 'secondary', 'info', 'success', 'warning', 'error'];
  L['tooltip'] = play('Experimente · passe o ponteiro', row('color', TIPC.map(function (c) { return '<span class="lv-tip" tabindex="0">' + B(c, 'neutral', 'outline') + '<span class="lu-tip2 c-' + c + '">Exportar <kbd>⌘E</kbd></span></span>'; }).join('')) + row('posição', '<span class="lv-tip">' + B('Em cima', 'neutral', 'soft') + '<span class="lu-tip2 c-dark">top</span></span><span class="lv-tip b">' + B('Embaixo', 'neutral', 'soft') + '<span class="lu-tip2 c-dark">bottom</span></span>'));
  L['context-menu'] = play('Experimente', '<div class="lv-area" data-lv-ctx>Clique com o botão direito aqui</div>') + '<div class="lv-ctx lu-pop" id="lv-ctx" style="width:220px">' + [['Abrir', 'external'], ['Renomear', 'edit'], ['Copiar link', 'link']].map(function (m) { return '<button class="lu-menu-item" type="button" data-lv-closectx>' + I(m[1]) + m[0] + '</button>'; }).join('') + '<div class="lu-menu-sep"></div><button class="lu-menu-item danger" type="button" data-lv-closectx>' + I('trash') + 'Excluir</button></div>';

  /* ---------- Command palette / Notificações ---------- */
  var CMD = ['Pedidos', 'Clientes', 'Notas fiscais', 'Emitir NF-e', 'Novo pedido', 'Financeiro', 'Estoque', 'Ajustes'];
  L['command-palette-dialog'] = play('Experimente', row('abrir', B('Abrir paleta de comandos', 'neutral', 'outline', 'data-lv-open="lv-cmd"', 'search'))) +
    '<div class="lv-ov" id="lv-cmd"><div class="lv-bd" data-lv-close></div><div class="lv-p lv-md a-shift-down top" style="--w:560px;padding:0"><div class="lu-cmd" style="border:0;box-shadow:none"><div class="q">' + I('search') + '<input id="lv-cq" placeholder="Buscar ou executar…" style="flex:1;border:0;background:none;font:inherit;font-size:16px;color:var(--ink);outline:none"><kbd class="lu-kbd">Esc</kbd></div><div class="list" id="lv-cl"></div></div></div></div>';
  L['notification-center'] = play('Experimente', row('sino', '<span class="lv-anc"><button class="lu-bell" type="button" data-lv-pop aria-label="Notificações" style="cursor:pointer">' + I('bell') + '<b>3</b></button><div class="lv-fl lu-pop" style="width:340px;padding:6px">' + ['Pagamento recebido de <b>Bom Preço</b> · R$ 3.120,50', '<b>NF-e 48.211</b> autorizada', '<b>Carlos</b> comentou no pedido #2491'].map(function (t, k) { return '<div class="lu-ntf ' + (k < 2 ? 'unread' : '') + '"><span class="lu-dot" style="margin-top:6px"></span><span class="tx">' + t + '</span><time>' + ['agora', '5 min', '1 h'][k] + '</time></div>'; }).join('') + '</div></span>'));

  /* ---------- Accordion / Collapse / Tabs / Alert / Clipboard / Select ---------- */
  var QA = [['Como emitir uma NF-e?', 'Abra o pedido e toque em Emitir NF-e.'], ['Posso cancelar uma nota?', 'Sim, em até 24 horas.'], ['E se a SEFAZ estiver fora?', 'A nota entra em contingência e é transmitida depois.']];
  L['accordion'] = L['collapse'] = play('Experimente · clique nas perguntas', '<div class="lv-acc">' + QA.map(function (q, k) { return '<div class="it ' + (k === 0 ? 'on' : '') + '"><button class="hd" type="button" data-lv-acc>' + q[0] + '<span class="ch">' + I('chevron-down', 'sm') + '</span></button><div class="bd"><div>' + q[1] + '</div></div></div>'; }).join('') + '</div>');
  L['tabs'] = play('Experimente', '<div class="lu-tb line" data-lv-tabs>' + ['Visão geral', 'Faturas', 'Uso'].map(function (t, k) { return '<button type="button" class="' + (k ? '' : 'on') + '">' + t + '</button>'; }).join('') + '</div><div class="lv-panes"><div class="on">Resumo do mês: 1.096 pedidos, R$ 184 mil.</div><div>12 faturas em aberto, 3 vencidas.</div><div>78% da cota de notas usada.</div></div>');
  L['alert'] = play('Experimente', '<div class="lv-dismiss" style="display:flex;gap:10px;align-items:center;padding:12px 14px;border-radius:12px;background:var(--warn-soft);color:var(--warn)">' + I('alert') + '<span style="flex:1"><b>Certificado vence em 3 dias.</b> Renove para continuar emitindo.</span><button class="lv-x" type="button" data-lv-dismiss aria-label="Fechar">' + I('x') + '</button></div>' + row('', B('Mostrar de novo', 'neutral', 'soft', 'data-lv-undismiss')));
  L['clipboard'] = play('Experimente', row('Pix', '<span class="lu-tmini">00020126580014BR.GOV.BCB.PIX</span>' + B('Copiar', 'neutral', 'outline', 'data-lv-copy="00020126580014BR.GOV.BCB.PIX"', 'copy')));
  L['select'] = L['autocomplete'] = play('Experimente', row('Filial', '<span class="lv-anc"><button type="button" class="lu-input" data-lv-pop style="width:280px;cursor:pointer;background:var(--bg-panel)">' + I('building') + '<span class="val" id="lv-selv">Matriz · Feira de Santana</span>' + I('chevron-down', 'sm') + '</button><div class="lv-fl lu-pop" style="width:280px">' + ['Matriz · Feira de Santana', 'Filial Serrinha', 'Filial Alagoinhas'].map(function (o) { return '<button class="lu-menu-item" type="button" data-lv-pick="' + o + '">' + o + '</button>'; }).join('') + '</div></span>'));

  /* ---------- runtime ---------- */
  var toaster;
  function T0(o) { return LedgerUI.toast(toaster, o); }
  function closeAllPops(except) { document.querySelectorAll('.lv-anc.open').forEach(function (a) { if (a !== except) a.classList.remove('open'); }); }
  function openOv(el) { el.classList.add('open'); var f = el.querySelector('input'); if (f) setTimeout(function () { f.focus(); }, 60); if (el.id === 'lv-cmd') paintCmd(''); }
  function closeOv(el) { el.classList.remove('open'); }
  function paintCmd(q) { var l = document.getElementById('lv-cl'); if (!l) return; var hits = CMD.filter(function (c) { return c.toLowerCase().indexOf(q.toLowerCase()) >= 0; }); l.innerHTML = hits.map(function (h, k) { return '<button class="lu-menu-item ' + (k === 0 ? 'hl' : '') + '" type="button" data-lv-close data-lv-after=\'{"kind":"info","title":"Abrindo ' + h + '"}\'>' + h + '</button>'; }).join('') || '<p class="lu-small lu-muted" style="padding:12px">Nada encontrado.</p>'; }
  function flow(kind) {
    if (kind === 'load') { var t = T0({ kind: 'loading', title: 'Emitindo NF-e…', desc: 'Transmitindo à SEFAZ-BA' }); setTimeout(function () { t.update({ kind: 'success', title: 'NF-e autorizada', desc: 'Nº 4.312 · protocolo 129 2611' }); }, 1800); }
    if (kind === 'prog') { var p = 0, t2 = T0({ kind: 'loading', title: 'Importando extrato…', desc: '0%' }); var iv = setInterval(function () { p += 20; if (p >= 100) { clearInterval(iv); t2.update({ kind: 'success', title: 'Extrato importado', desc: '980 linhas' }); } else { t2.el.querySelector('.t span').textContent = p + '%'; } }, 450); }
    if (kind === 'status') { var s = T0({ status: 'run', title: 'Deploy <b>f798c00</b> compilando', action: 'Cancelar' }); setTimeout(function () { s.update({ status: 'ok', title: 'Deploy <b>f798c00</b> publicado em <b>38s</b>', action: 'Abrir' }); }, 2400); }
    if (kind === 'stack') { T0({ kind: 'success', title: 'NF-e 48.211 autorizada' }); setTimeout(function () { T0({ kind: 'info', title: 'Novo pedido #2492' }); }, 300); setTimeout(function () { T0({ kind: 'warning', title: 'Estoque baixo: café' }); }, 600); }
  }
  window.LedgerLive = {
    toast: function (o) { return T0(o); }, open: function (id) { var e = document.getElementById(id); if (e) openOv(e); },
    has: function () { return false; },
    html: function (id) { return L[id] || ''; },
    mount: function (root) { if (window.LedgerUI) LedgerUI.hydrate(root); }
  };
  document.addEventListener('DOMContentLoaded', function () {
    var seen = {}; Object.keys(L).forEach(function (k) { var w = document.createElement('div'); w.innerHTML = L[k]; w.querySelectorAll('.lv-ov, #lv-ctx').forEach(function (o) { if (!seen[o.id]) { seen[o.id] = 1; document.body.appendChild(o); } }); });
    toaster = document.createElement('div'); toaster.className = 'lu-toaster lv-toaster'; toaster.dataset.pos = 'center-bottom'; toaster.innerHTML = '<div class="stack"></div>'; document.body.appendChild(toaster);
  });
  document.addEventListener('click', function (e) {
    var t = e.target.closest('[data-lv-toast],[data-lv-flow],[data-lv-open],[data-lv-close],[data-lv-pop],[data-lv-closepop],[data-lv-acc],[data-lv-dismiss],[data-lv-undismiss],[data-lv-copy],[data-lv-pick],[data-pos],[data-lv-tabs] > button,[data-lv-closectx]');
    if (!e.target.closest('.lv-anc')) closeAllPops();
    if (!e.target.closest('#lv-ctx')) { var c = document.getElementById('lv-ctx'); if (c) c.classList.remove('open'); }
    if (!t) return;
    if (t.dataset.lvToast) T0(JSON.parse(t.dataset.lvToast));
    if (t.dataset.lvFlow) flow(t.dataset.lvFlow);
    if (t.dataset.lvOpen) openOv(document.getElementById(t.dataset.lvOpen));
    if (t.hasAttribute('data-lv-close')) { var o = t.closest('.lv-ov'); if (o) closeOv(o); }
    if (t.hasAttribute('data-lv-pop')) { var a = t.closest('.lv-anc'); closeAllPops(a); a.classList.toggle('open'); }
    if (t.hasAttribute('data-lv-closepop')) closeAllPops();
    if (t.hasAttribute('data-lv-closectx')) document.getElementById('lv-ctx').classList.remove('open');
    if (t.dataset.lvAfter) setTimeout(function () { T0(JSON.parse(t.dataset.lvAfter)); }, 180);
    if (t.hasAttribute('data-lv-acc')) t.closest('.it').classList.toggle('on');
    if (t.hasAttribute('data-lv-dismiss')) t.closest('.lv-dismiss').classList.add('gone');
    if (t.hasAttribute('data-lv-undismiss')) document.querySelectorAll('.lv-dismiss.gone').forEach(function (d) { d.classList.remove('gone'); });
    if (t.dataset.lvCopy) { if (navigator.clipboard) navigator.clipboard.writeText(t.dataset.lvCopy).then(function () {}, function () {}); T0({ kind: 'success', title: 'Copiado', desc: 'Chave Pix na área de transferência' }); }
    if (t.dataset.lvPick) { document.getElementById('lv-selv').textContent = t.dataset.lvPick; closeAllPops(); }
    if (t.dataset.pos && t.closest('#lv-pos')) { toaster.dataset.pos = t.dataset.pos; t.parentNode.querySelectorAll('button').forEach(function (b) { b.classList.toggle('on', b === t); }); T0({ kind: 'info', title: 'Posição: ' + t.dataset.pos }); }
    if (t.parentNode && t.parentNode.hasAttribute && t.parentNode.hasAttribute('data-lv-tabs')) { var bs = [].slice.call(t.parentNode.children), k = bs.indexOf(t); bs.forEach(function (b) { b.classList.toggle('on', b === t); }); var panes = t.parentNode.nextElementSibling.children; for (var i = 0; i < panes.length; i++) panes[i].classList.toggle('on', i === k); }
  });
  document.addEventListener('contextmenu', function (e) { var a = e.target.closest('[data-lv-ctx]'); if (!a) return; e.preventDefault(); var m = document.getElementById('lv-ctx'); m.style.left = Math.min(e.clientX, innerWidth - 240) + 'px'; m.style.top = Math.min(e.clientY, innerHeight - 230) + 'px'; m.classList.add('open'); });
  document.addEventListener('input', function (e) { if (e.target.id === 'lv-cq') paintCmd(e.target.value); });
  document.addEventListener('keydown', function (e) { if (e.key === 'Escape') { document.querySelectorAll('.lv-ov.open').forEach(closeOv); closeAllPops(); var c = document.getElementById('lv-ctx'); if (c) c.classList.remove('open'); } });
})();
