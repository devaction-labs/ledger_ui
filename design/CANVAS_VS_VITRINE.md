# Canvas × vitrine

Regra: o **canvas** (design/canvas/*.dc.html) é a fonte da verdade. Onde a vitrine (design/vitrine/sec) difere, vale o canvas.

Gerado por `cd design && python3 ../scripts/canvas_vs_vitrine.py`.

```
components 134 demos 488 identical 451
auth-split DIFF 'Referência visual' 3 16 ['+<svg.[]', '+<defs.[]', '+<lineargradient.[]', '+<stop.[]']
calendar DIFF 'Dia selecionado andando · em loop' 1 2 ['-<div.lu-cal2.mo-pick[]', '+<div.lu-cal.mo-pick[]']
calendar DIFF 'view month/week · variant full/mini · marks dot/tint' 2 6 ['-<div.lu-cal2[]', '+<div.lu-cal[]', '-<div.lu-cal2.sm[]', '+<div.lu-cal.sm[]']
date-picker DIFF 'Escolhendo um intervalo · em loop' 1 2 ['-<div.lu-cal2.mo-range[]', '+<div.lu-cal.mo-range[]']
date-picker DIFF 'mode single · multiple · range × size sm/md/lg' 2 6 ['-<div.lu-cal2.sm[]', '+<div.lu-cal.sm[]', '-<div.lu-cal2[]', '+<div.lu-cal[]']
date-picker DIFF 'Referência visual' 3 2 ['-T:Out 2026', '+T:Oct 2026']
date-time-picker DIFF 'Data e hora · em loop' 1 2 ['-<div.lu-cal2.mo-pick.sm[]', '+<div.lu-cal.mo-pick.sm[]']
dropdown DIFF 'placement (12)' 5 48 ['-T:top-start', '+T:Gatilho', '-T:Pedido #2491 · Pago', '+T:top-start']
dropdown DIFF 'Referência visual' 6 4 ['-T:Out 2026', '+T:Oct 2026', '-T:Out 2026', '+T:Oct 2026']
hero-card DIFF 'Referência visual' 3 2 ['-T:Out 2026', '+T:Oct 2026']
kpi-card DIFF 'Referência visual' 3 16 ['+<svg.[]', '+<defs.[]', '+<lineargradient.[]', '+<stop.[]']
palette DIFF 'Superfícies' 3 12 ['-<div.lu-swc[]', '+<div.lu-sw[]', '-<div.lu-swc[]', '+<div.lu-sw[]']
palette DIFF 'Texto e linhas' 4 12 ['-<div.lu-swc[]', '+<div.lu-sw[]', '-<div.lu-swc[]', '+<div.lu-sw[]']
palette DIFF 'Ação e sinais' 5 16 ['-<div.lu-swc[]', '+<div.lu-sw[]', '-<div.lu-swc[]', '+<div.lu-sw[]']
palette DIFF 'Séries de gráfico' 6 12 ['-<div.lu-swc[]', '+<div.lu-sw[]', '-<div.lu-swc[]', '+<div.lu-sw[]']
pixel-card DIFF 'Movimento — os pixels acendem e piscam (loop)' 1 4488 ['+<span.grid[]', '+<i.[--o1:0.67;--o2:0;--o3:0]', '+>', '+<i.[--o1:0;--o2:0.31;--o3:0.69]']
pixel-card DIFF 'color — passe o mouse em qualquer card' 2 8976 ['+<span.grid[]', '+<i.[--o1:0.27;--o2:0.57;--o3:0.85]', '+>', '+<i.[--o1:0.78;--o2:0;--o3:0.72]']
pixel-card DIFF 'estado aceso (hover/foco) · arrow={false}' 3 3366 ['+<span.grid[]', '+<i.[--o1:0.97;--o2:0;--o3:0.29]', '+>', '+<i.[--o1:0;--o2:0.53;--o3:0.70]']
popover DIFF 'placement (12) · trigger_on click/hover' 2 48 ['-T:top-start', '+T:Gatilho', '-T:Ticket médio · R$ 168,40', '+T:top-start']
shell DIFF 'Referência visual' 3 236 ['-T:Out 2026', '+T:Oct 2026', '+<svg.[]', '+<defs.[]']
textarea DIFF 'tokens · header/footer · resizable' 4 10 ['-T:{{cliente}}', '+T:{ {cliente} }', '-T:{{numero}}', '+T:{ {numero} }']
toast-card NO-MATCH '' None  
toast-card NO-MATCH '' None  
toast-card NO-MATCH '' None  
toast-card NO-MATCH '' None  
toast-card NO-MATCH '' None  
toast-card NO-MATCH '' None  
toast-card NO-MATCH '' None  
toast-card NO-MATCH '' None  
toast-card NO-MATCH '' None  
toast-card NO-MATCH '' None  
toast-card NO-MATCH '' None  
toast-card NO-MATCH '' None  
toaster DIFF 'Ao vivo — clique para disparar' 1 45 ['+<div.c-success.lu-tcard[]', '+<span.tile[]', '+ICON:check-circle:md', '+>']
tooltip DIFF 'Aparece ao passar o ponteiro · em loop' 1 6 ['-<div.[align-items:center;display:flex;flex-direction:column;gap:8px;height:110px;justify-content:center]', '+<div.[display:grid;height:96px;place-items:center]', '-<div.[align-items:center;display:flex;flex-direction:column;gap:8px;height:110px;justify-content:center]', '+<div.[display:grid;height:96px;place-items:center]']
tooltip DIFF 'color (9)' 2 45 ['-<div.[align-items:center;display:flex;flex-direction:column;gap:8px;height:110px;justify-content:center]', '+<div.[display:grid;height:96px;place-items:center]', '-<span.lu-muted.lu-xs.mono[]', '-T:neutral']
tooltip DIFF 'placement (12) · trigger hover/click/focus/manual · follow_cursor' 3 86 ['-<div.[align-items:center;display:flex;flex-direction:column;gap:8px;height:110px;justify-content:center]', '+<div.[display:grid;height:96px;place-items:center]', '-T:Exportar', '+T:top-start']
```
