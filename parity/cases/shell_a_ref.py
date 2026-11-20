"""Shell/app, parte A (lado original, gerador da referência c6.py/c14.py): o markup `lu-*` que a referência desenha
para AiInsights, AiPromo, AiMessage, AiComposer, ConversationList, AiProposal, AiToolTrace, Trace, CodeBlock e GlowText.
O lado HEEx está em `shell_a_ref.exs`."""
from _common import *
from base import btn, ibtn, badge, col  # noqa: E402

LOGO_NOP = None
C = {}

C["ref-ai-insights"] = (520, f'<div style="max-width:440px">{c6.AIC}</div>')

C["ref-ai-promo"] = (300, '<div style="width:260px">' + f'<div class="lu-promo"><div class="lu-row" style="flex-wrap:nowrap"><span class="ic">{ic("sparkles","md")}</span><span class="lu-col" style="gap:0"><b>Ledgerly AI</b><span class="lu-xs lu-muted">3 new revenue insights</span></span></div><span class="lu-small lu-ink2">Ask why revenue moved and get the accounts behind it.</span><button class="lu-btn primary block" type="button" style="justify-content:space-between"><span class="lu-row" style="gap:8px"><span class="lead" style="margin-left:-8px">{ic("sparkles","sm")}</span>Run AI insights</span>{ic("arrow-right","sm")}</button></div>' + "</div>")

AI_TXT = (f'<div class="lu-msg"><span class="ai">{ic("sparkles","md")}</span><div class="body"><div>O churn subiu <b>0,4 pts</b> por causa de <b>23 contas</b>. Dessas, <b>7 de 11</b> cancelamentos Pro vieram logo após uma falha de pagamento.</div>'
          f'<div class="acts">{ibtn("copy","Copiar","ghost sm")}{ibtn("thumb-up","Útil","ghost sm")}{ibtn("thumb-down","Não útil","ghost sm")}{ibtn("refresh","Gerar de novo","ghost sm")}</div></div></div>')
C["ref-ai-message"] = (420, col(c6.USER_MSG, AI_TXT,
    f'<div class="lu-msg"><span class="ai">{ic("sparkles","md")}</span><div class="body"><span class="lu-dots" style="margin-top:10px"><i></i><i></i><i></i></span></div></div>', gap=16))

C["ref-ai-composer"] = (680, f'<div style="max-width:640px">{c6.COMPOSER}</div>')

C["ref-conversation-list"] = (340, '<div class="lu-panel" style="width:300px;padding:8px"><div style="padding:4px 4px 8px">' + btn("Nova conversa", "block", "plus") + "</div>" + '<div class="lu-nav-h">Hoje</div>' + "".join(f'<a href="#" class="lu-nav-item {"on" if i==0 else ""}" style="height:34px;font-size:13.5px;font-weight:400">{ic("message","md")}<span style="overflow:hidden;text-overflow:ellipsis;white-space:nowrap">{t}</span></a>' for i, t in enumerate(["Por que o churn subiu em outubro?", "Contas Scale perto do limite"])) + '<div class="lu-nav-h">Últimos 7 dias</div>' + "".join(f'<a href="#" class="lu-nav-item" style="height:34px;font-size:13.5px;font-weight:400">{ic("message","md")}<span style="overflow:hidden;text-overflow:ellipsis;white-space:nowrap">{t}</span></a>' for t in ["Comparar coorte de setembro", "Resumo para o board", "Previsão de MRR Q4"]) + "</div>")

C["ref-ai-proposal"] = (420, card('Proposta ' + badge("Aguardando aprovação", "warn"), f'<div class="lu-col" style="gap:12px"><div class="lu-row"><span class="lu-ic lime">{ic("sparkles","md")}</span><b>Ativar retentativa inteligente para o plano Pro</b></div><div class="lu-tablewrap"><table class="lu-table dense"><thead><tr><th>Regra</th><th>Atual</th><th>Proposto</th></tr></thead><tbody><tr><td>Retentativas</td><td><s class="lu-muted">2</s></td><td class="strong">4</td></tr><tr><td>Intervalo</td><td><s class="lu-muted">3 dias</s></td><td class="strong">1, 3, 5, 7 dias</td></tr><tr><td>E-mail ao cliente</td><td><s class="lu-muted">Não</s></td><td class="strong">Dia 1</td></tr></tbody></table></div><div class="lu-row">{badge("+$3,400 MRR recuperável","lime")}<span class="lu-small lu-muted">baseado em 7 contas</span></div></div>',
      foot='<span class="lu-grow"></span>' + btn("Rejeitar", "ghost sm") + btn("Editar", "sm", "edit") + btn("Aprovar", "primary sm", "check")))

C["ref-ai-tool-trace"] = (340, '<details open class="lu-trace"><summary class="lu-row" style="list-style:none;padding:9px 12px;cursor:pointer;border-bottom:1px solid var(--line)">' + ic("tool", "md lu-muted") + '<span class="lu-small">Usou 3 ferramentas</span><span class="lu-grow"></span><span class="lu-xs lu-muted mono">1.8s</span></summary>' + "".join(f'<div class="lu-trace-i">{ic(i,"md")}<span class="nm">{n}</span><span class="lu-xs lu-muted">{d}</span><span class="ms">{t}</span></div>' for i, n, d, t in [("check-circle", "stripe.list_cancellations", "oct 2026 · 23 rows", "640ms"), ("check-circle", "cohorts.compare", "sep vs avg", "410ms"), ("refresh", "accounts.seat_usage", "executando…", "—")]) + "</details>")

C["ref-trace"] = (380, '<div class="lu-trace">' + "".join(f'<div class="lu-trace-i" style="padding-left:{12+l*18}px">{ic("chevron-down" if l==0 else "circle","sm lu-muted")}<span class="nm" style="width:180px">{n}</span><div style="flex:1;position:relative;height:8px;background:var(--bg-sunken);border-radius:4px"><i style="position:absolute;left:{s}%;width:{w}%;top:0;bottom:0;border-radius:4px;background:var(--{c})"></i></div><span class="ms" style="width:56px;text-align:right">{t}</span></div>' for l, n, s, w, c, t in [(0, "ai.answer", 0, 100, "teal-500", "1.84s"), (1, "plan", 0, 12, "teal-300", "220ms"), (1, "stripe.list", 12, 35, "teal-500", "640ms"), (1, "cohorts.compare", 47, 22, "teal-500", "410ms"), (1, "seat_usage", 69, 8, "neg", "timeout"), (1, "compose", 77, 23, "teal-400", "420ms")]) + "</div>")

C["ref-code-block"] = (400, '<div class="lu-code"><div class="hd">' + ic("code", "sm") + 'lib/ledgerly/churn.ex<button type="button" data-lu-copy="..."><span class="lu-copy-label">Copiar</span></button></div><pre>' +
    '<span class="ln">1</span><span class="k">defmodule</span> <span class="f">Ledgerly.Churn</span> <span class="k">do</span>\n'
    '<span class="ln">2</span>  <span class="c"># MRR perdido no período, por plano</span>\n'
    '<span class="ln">3</span>  <span class="k">def</span> <span class="f">by_plan</span>(period) <span class="k">do</span>\n'
    '<span class="lu-diff-del"><span class="ln">4</span>    Repo.all(<span class="f">cancellations</span>(period))</span>'
    '<span class="lu-diff-add"><span class="ln">4</span>    period |&gt; <span class="f">cancellations</span>() |&gt; <span class="f">reject_recovered</span>() |&gt; Repo.all()</span>'
    '<span class="ln">5</span>    |&gt; Enum.group_by(&amp; &amp;1.plan, &amp; &amp;1.mrr_cents)\n'
    '<span class="ln">6</span>  <span class="k">end</span>\n<span class="ln">7</span><span class="k">end</span></pre></div>')

C["ref-glow-text"] = (420, col('<div class="lu-glowtx" style="font-size:44px">Assistente Signetum</div>', '<div class="lu-glowtx" style="font-size:32px">tone=default · h1</div>', '<div class="lu-glowtx warm" style="font-size:24px">tone=warm · h2</div>', '<span class="lu-glowtx" style="font-size:15px">as=span dentro do texto</span>', gap=10))
