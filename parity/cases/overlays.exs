defmodule Parity.Cases.Overlays do
  @moduledoc false
  # Lote Overlays: accordion, collapse, command palette, drawer/sheet, modal, notification center,
  # popover, tooltip. Os mesmos ids de `overlays.py` (lado original: a saída da lib antes da migração).
  # O conteúdo dos slots é HTML simples com estilo inline (os botões etc. são de outros lotes).
  use Phoenix.Component
  use LedgerUI
  import Parity.Common

  @btn "padding:0 14px;height:36px;display:inline-flex;align-items:center;border:1px solid #999;border-radius:8px;font-size:14px;font-weight:500"

  def cases do
    assigns = %{btn: @btn}

    modal =
      %{
        "modal-basic" => ~H"""
        <.modal id="m1" inline title="Exportar relatório" description="October 2026 · Orbit Cloud" icon="download" style="min-height:360px">
          <div style="height:60px;background:#8883;border-radius:8px"></div>
          <p style="margin:0">Choose a format.</p>
          <:footer><span style={@btn}>Cancelar</span><span style={@btn}>Exportar</span></:footer>
        </.modal>
        """,
        "modal-sizes" => ~H"""
        <.colm>
          <.modal :for={s <- ~w(xs sm md lg xl)} id={"ms-#{s}"} inline size={s} title={"size #{s}"} style="min-height:150px">
            <p style="margin:0">Corpo</p>
          </.modal>
        </.colm>
        """,
        "modal-destructive" => ~H"""
        <.modal id="m2" inline size="xs" title="Excluir visão?" description="“Pro churn watch” será removida para todos do workspace." icon="trash" icon_tone="error" close_button={false} style="min-height:300px">
          <:footer><span style={@btn}>Cancelar</span><span style={@btn}>Excluir</span></:footer>
        </.modal>
        """,
        "modal-tones" => ~H"""
        <.colm>
          <.modal :for={t <- ~w(neutral accent success error warning info lime)} id={"mt-#{t}"} inline size="xs" title={t} icon="info" icon_tone={t} style="min-height:130px"></.modal>
        </.colm>
        """,
        "modal-corner" => ~H"""
        <.colm>
          <.modal id="m3" inline size="xs" style="min-height:160px"><div style="padding:20px;font-weight:600">Sem cabeçalho</div></.modal>
          <.modal id="m4" inline size="xs" close_variant="chip" style="min-height:160px"><div style="height:90px;background:#8886"></div><div style="padding:10px;font-weight:600">Capa da loja</div></.modal>
        </.colm>
        """,
        "modal-align" => ~H"""
        <.colm>
          <.modal :for={p <- ~w(top center bottom)} id={"ma-#{p}"} inline size="xs" placement={p} title={p} style="min-height:200px"></.modal>
        </.colm>
        """,
        "modal-page" => ~H"""
        <div style="position:relative;height:420px;overflow:hidden;background:#8881">
          <.modal id="mp" layout="page" open title="Novo pedido" description="Os itens saem do estoque quando o pedido for pago." on_close="close">
            <div style="height:80px;background:#8883;border-radius:8px"></div>
            <div style="height:40px;background:#8883;border-radius:8px"></div>
            <:footer><span style={@btn}>Cancelar</span><span style={@btn}>Criar</span></:footer>
          </.modal>
        </div>
        """,
        "modal-page-header" => ~H"""
        <div style="position:relative;height:300px;overflow:hidden;background:#8881">
          <.modal id="mp2" layout="page" open on_close="close" close_button={false}>
            <:header><div><h3>Cabeçalho próprio</h3><p>Legenda</p></div></:header>
            <p style="margin:0">Corpo</p>
          </.modal>
        </div>
        """
      }

    drawer =
      %{
        "drawer-float" => ~H"""
        <.drawer id="d1" inline title="Orbit Cloud" description="Pro · desde jan 2026" style="height:420px;padding:0;justify-content:flex-start">
          <div style="height:70px;background:#8883;border-radius:8px"></div>
          <p style="margin:0">Detalhes da conta.</p>
          <:footer><span style={@btn}>Abrir conta</span><span style={@btn}>Propor upgrade</span></:footer>
        </.drawer>
        """,
        "drawer-flush" => ~H"""
        <.drawer id="d2" inline variant="flush" title="Pedido #2491" style="height:300px;padding:0;justify-content:flex-start">
          <p style="margin:0">Itens do pedido.</p>
        </.drawer>
        """,
        "drawer-left" => ~H"""
        <div style="display:grid;gap:12px">
          <.drawer id="d3" inline placement="left" size="sm" title="Float" style="height:260px;padding:0">
            <p style="margin:0">Esquerda</p>
          </.drawer>
          <.drawer id="d4" inline placement="left" variant="flush" size="sm" title="Flush" style="height:260px;padding:0">
            <p style="margin:0">Esquerda</p>
          </.drawer>
        </div>
        """,
        "drawer-sizes" => ~H"""
        <div style="display:grid;gap:12px">
          <.drawer :for={s <- ~w(sm md lg wide xl)} id={"ds-#{s}"} inline size={s} title={s} style="height:150px;padding:0"></.drawer>
        </div>
        """,
        "drawer-bare" => ~H"""
        <.drawer id="d5" inline style="height:200px;padding:0"><div style="padding:16px">Menu</div></.drawer>
        """,
        "sheet-bottom" => ~H"""
        <.sheet id="s1" inline placement="bottom" title="Filtros" style="height:380px;padding:0">
          <p style="margin:0">Plano e status.</p>
          <:footer><span style={@btn}>Mostrar 23 contas</span></:footer>
        </.sheet>
        """,
        "sheet-bare" => ~H"""
        <.sheet id="s2" inline placement="bottom" style="height:240px;padding:0"><div style="padding:16px">Conteúdo</div></.sheet>
        """,
        "drawer-page" => ~H"""
        <div style="position:relative;height:420px;overflow:hidden;background:#8881">
          <.drawer id="dp" layout="page" open title="Pedido #2491" description="Criado hoje por Ana" on_close="close">
            <div style="height:80px;background:#8883;border-radius:8px"></div>
            <div style="height:40px;background:#8883;border-radius:8px"></div>
            <:footer><span style={@btn}>Imprimir</span></:footer>
          </.drawer>
        </div>
        """
      }

    floats =
      %{
        "tooltip-colors" => ~H"""
        <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:4px">
          <div :for={c <- ~w(neutral light dark primary secondary info success warning error)} style="height:110px;display:flex;align-items:center;justify-content:center">
            <.tooltip id={"tc-#{c}"} color={c} text={c} open><span style={@btn}>x</span></.tooltip>
          </div>
        </div>
        """,
        "tooltip-placements" => ~H"""
        <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:4px">
          <div :for={p <- ~w(top top-start top-end right right-start right-end bottom bottom-start bottom-end left left-start left-end)} style="height:120px;display:flex;align-items:center;justify-content:center">
            <.tooltip id={"tp-#{p}"} placement={p} text={p} open><span style={@btn}>b</span></.tooltip>
          </div>
        </div>
        """,
        "tooltip-closed" => ~H"""
        <.tooltip id="tcl" text="Fechado"><span style={@btn}>hover</span></.tooltip>
        """,
        "tooltip-content" => ~H"""
        <div style="height:150px;display:flex;align-items:center;justify-content:center">
          <.tooltip id="tct" open>
            <span style={@btn}>Content</span>
            <:content><div style="padding:12px">Conteúdo <b>rico</b></div></:content>
          </.tooltip>
        </div>
        """,
        "popover-placements" => ~H"""
        <div style="display:grid;grid-template-columns:repeat(2,1fr);gap:8px">
          <div :for={p <- ~w(right-start bottom top-end left)} style="height:210px;display:flex;align-items:center;justify-content:center">
            <.popover id={"pp-#{p}"} placement={p} width="180px" open>
              <:trigger :let={a}><span style={@btn} {a}>{p}</span></:trigger>
              <:title>Group Lesson</:title>
              <p style="margin:8px 0 0">Lorem ipsum dolor sit amet.</p>
            </.popover>
          </div>
        </div>
        """,
        "popover-default" => ~H"""
        <div style="height:150px;padding:20px">
          <.popover id="pd" open>
            <:trigger :let={a}><span style={@btn} {a}>Lessons</span></:trigger>
            <b>Net revenue retention</b>
            <p style="margin:8px 0 0">Receita de clientes existentes nos últimos 12 meses.</p>
          </.popover>
        </div>
        """,
        "popover-closed" => ~H"""
        <.popover id="pc" width={nil}>
          <:trigger :let={a}><span style={@btn} {a}>Fechado</span></:trigger>
          <p>x</p>
        </.popover>
        """
      }

    palette =
      %{
        "palette-canvas" => palette_case("pc1", "canvas", true, 460),
        "palette-classic" => palette_case("pc2", "classic", true, 460),
        "palette-scopes" => ~H"""
        <.command_palette id="pc3" inline style="min-height:420px" placeholder="Buscar" query="ped" scopes={[{"Tudo", "all"}, {"Páginas", "pages"}, "Ações"]} items={[
          %{group: "Ir para", scope: "pages", label: "Pedidos", sub: "lista", icon: "cart", keys: ["G", "O"]},
          %{group: "Ações", scope: "Ações", label: "Novo pedido", icon: "plus", count: 3},
          %{label: "Sem grupo", avatar: %{initials: "CD", tint: "#d97a1e"}},
          %{label: "Outro avatar", avatar: %{initials: "AB"}}
        ]} assistant={%{label: "Perguntar: “%{query}”", sub: "IA"}} />
        """,
        "palette-bare" => ~H"""
        <.command_palette id="pc4" bare style="width:100%" hints={false} items={[%{label: "Item único", icon: "file"}]}>
          <:footer>rodapé próprio</:footer>
        </.command_palette>
        """,
        "palette-typed" => ~H"""
        <.command_palette id="pc5" bare highlight="typed" hint_new_tab={nil} style="width:100%" items={[%{label: "A", icon: "file"}, %{label: "B", icon: "plus"}]} />
        """
      }

    notif =
      %{
        "notif-canvas" => notif_case("canvas"),
        "notif-classic" => ~H"""
        <.notification_center id="n2" inline variant="classic" on_read_all="r" all_href="/n" preferences_href="/p"
          items={[
            %{id: "1", title: "3 new revenue insights", at: "há 5 min", type: "primary", icon: "sparkles", tone: "lime", category: "orders"},
            %{id: "2", title: "Fernando mencionou você", body: "Board pack Q3", at: "há 1 h", avatar: %{initials: "FP", tint: "t2"}},
            %{id: "3", title: "Pagamento falhou", at: "ontem", type: "error", read: true}
          ]}
          tabs={[%{id: "all", label: "Todas"}, %{id: "unread", label: "Não lidas"}, %{id: "orders", label: "Pedidos"}]} />
        """,
        "notif-empty" => ~H"""
        <div style="display:flex;gap:10px;flex-wrap:wrap">
          <.notification_center :for={t <- ~w(neutral primary info success warning error)} id={"ne-#{t}"} inline empty_tone={t} items={[]} />
        </div>
        """,
        "notif-bell" => ~H"""
        <div style="height:280px;padding:10px">
          <.notification_center id="n3" open arrow
            items={[%{id: "1", title: "Novo pedido", body: "#2492", at: "agora", type: "success"}, %{id: "2", title: "Lido", at: "ontem", read: true}]} />
        </div>
        """,
        "notif-bell-closed" => ~H"""
        <div style="display:flex;gap:30px;padding:10px">
          <.notification_center id="n4" items={[]} />
          <.notification_center id="n5" items={[%{title: "x"}]} unread={120} />
        </div>
        """
      }

    acc =
      %{
        "accordion-variants" => ~H"""
        <div style="display:grid;grid-template-columns:repeat(2,1fr);gap:16px">
          <div :for={v <- ~w(advanced basic border-bottom bordered canvas divided primary)}>
            <.accordion id={"acc-#{v}"} variant={v}>
              <.accordion_item id={"acc-#{v}-1"} title="Como emitir uma NF-e?" open>Abra o pedido e toque em Emitir NF-e.</.accordion_item>
              <.accordion_item id={"acc-#{v}-2"} title="Posso cancelar uma nota?">Sim.</.accordion_item>
              <.accordion_item id={"acc-#{v}-3"} title="E se a SEFAZ estiver fora?">Contingência.</.accordion_item>
            </.accordion>
          </div>
        </div>
        """,
        "accordion-colors" => ~H"""
        <.colm>
          <.accordion :for={c <- ~w(primary secondary info success warning error)} id={"acc-c-#{c}"} variant="primary" color={c}>
            <:item title={"color #{c}"} open>Corpo</:item>
            <:item title="Fechado">x</:item>
          </.accordion>
        </.colm>
        """,
        "accordion-header" => ~H"""
        <.accordion id="acc-h" variant="advanced">
          <.accordion_item id="acc-h-1" open toggle_label="Alternar"><:header><b>Header</b> próprio</:header>Corpo</.accordion_item>
          <.accordion_item id="acc-h-2"><:header><b>Outro</b></:header>Corpo</.accordion_item>
        </.accordion>
        """,
        "collapse-variants" => ~H"""
        <div style="display:grid;grid-template-columns:repeat(2,1fr);gap:14px">
          <.collapse :for={v <- ["canvas", "framed", "flat", "section", "classic"]} id={"col-#{v}"} variant={v} open>
            <:trigger>Trigger {v}</:trigger>
            <p style="margin:0">Corpo do collapse.</p>
          </.collapse>
        </div>
        """,
        "collapse-closed" => ~H"""
        <div style="display:grid;grid-template-columns:repeat(2,1fr);gap:14px">
          <.collapse :for={v <- ["canvas", "framed", "flat", "section"]} id={"colc-#{v}"} variant={v}>
            <:trigger>Fechado {v}</:trigger>
            <p>Corpo</p>
          </.collapse>
        </div>
        """,
        "collapse-chevron" => ~H"""
        <.colm>
          <.collapse id="cch1" chevron="down"><:trigger>Chevron down</:trigger>Corpo</.collapse>
          <.collapse id="cch2" chevron="right" open><:trigger>Chevron right</:trigger>Corpo</.collapse>
          <.collapse id="cch3" chevron="down" variant="flat" open><:trigger>Flat com chevron</:trigger>Corpo</.collapse>
          <.collapse id="cch4" chevron="right" variant="section"><:trigger>Section</:trigger>Corpo</.collapse>
        </.colm>
        """,
        "collapse-text" => ~H"""
        <div style="width:260px">
          <.collapse_text id="ct1" lines={2}>
            Os cartões recusados concentram-se em emissores europeus. Ativar retentativa inteligente e e-mail no dia 1 recuperaria cerca de $3,400 de MRR neste trimestre, segundo a análise.
          </.collapse_text>
        </div>
        """
      }

    modal |> Map.merge(drawer) |> Map.merge(floats) |> Map.merge(palette) |> Map.merge(notif) |> Map.merge(acc)
  end

  defp palette_case(id, variant, _inline, _w) do
    assigns = %{id: id, variant: variant}

    ~H"""
    <.command_palette id={@id} inline variant={@variant} style="min-height:420px" placeholder="Search or run…" query="churn" hint_new_tab={nil}
      items={[
        %{group: "Ir para", label: "Churn", icon: "user-minus", count: 23},
        %{group: "Ir para", label: "Pro churn watch", icon: "folder"},
        %{group: "Ações", label: "Perguntar à IA: por que o churn subiu?", icon: "sparkles", keys: ["↵"]},
        %{group: "Ações", label: "Exportar relatório de churn", icon: "download"},
        %{group: "Contas", label: "Nordic Pay · churned", icon: "building"}
      ]} />
    """
  end

  defp notif_case(variant) do
    assigns = %{variant: variant}

    ~H"""
    <.notification_center id="n1" inline variant={@variant}
      items={[
        %{id: "1", title: "Novo pedido #2492", body: "de Padaria Central", at: "agora", type: "success", group: "Hoje"},
        %{id: "2", title: "Pagamento recebido", body: "R$ 3.120,50", at: "agora", type: "info", group: "Hoje"},
        %{id: "3", title: "Estoque baixo", at: "ontem", type: "warning", read: true, group: "Ontem"},
        %{id: "4", title: "Sem tipo", at: "2d", read: true}
      ]} />
    """
  end
end
