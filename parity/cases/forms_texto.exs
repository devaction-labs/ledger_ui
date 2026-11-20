defmodule Parity.Cases.FormsTexto do
  use Phoenix.Component
  use LedgerUI
  import Parity.Common

  @colors ~w(neutral primary secondary info success warning error)

  attr :cols, :integer, required: true
  attr :gap, :string, default: "10px 14px"
  attr :just, :string, default: "start"
  slot :inner_block, required: true

  defp gr(assigns) do
    assigns = assign(assigns, :unit, if(assigns.just == "stretch", do: "minmax(0,1fr)", else: "max-content"))

    ~H"""
    <div style={"display:grid;grid-template-columns:repeat(#{@cols},#{@unit});gap:#{@gap};align-items:center;justify-items:#{@just}"}>{render_slot(@inner_block)}</div>
    """
  end

  def cases do
    assigns = %{
      colors: @colors,
      cb_states: ~w(off on partial filled dis),
      sw_states: ["off", "on", "outline on", "outline filled", "dis"],
      sizes: ~w(xs sm md lg),
      sw_sizes: ~w(sm md lg),
      insets: [2, 3, 4, 5, 6],
      shapes: ~w(square circle),
      sw_shapes: ~w(squircle pill)
    }

    %{
      "checkbox-colors" => ~H"""
      <.gr cols={5} gap="12px 28px">
        <%= for c <- @colors, st <- @cb_states do %>
          <.checkbox color={c} checked={st in ["on", "dis"]} indeterminate={st == "partial"} filled={st == "filled"} disabled={st == "dis"} />
        <% end %>
      </.gr>
      """,
      "checkbox-sizes" => ~H"""
      <.gr cols={4} gap="12px 24px">
        <%= for sh <- @shapes, s <- @sizes do %>
          <.checkbox label="Rótulo" checked size={s} shape={sh} color="primary" />
        <% end %>
      </.gr>
      """,
      "checkbox-desc" => ~H"""
      <.colm>
        <.checkbox color="primary" label="Enviar DANFE por e-mail" description="O cliente recebe o PDF e o XML assim que a nota é autorizada." checked />
        <.checkbox color="primary" label="Reter ISS" description="Só para serviços com retenção na fonte." />
        <.checkbox color="primary" label="Selecionar todos" description="3 de 8 pedidos marcados" indeterminate />
        <.checkbox color="primary" label="Desabilitado" disabled />
      </.colm>
      """,
      "checkbox-outline" => ~H"""
      <.colm>
        <.checkbox color="primary" variant="outline" label="Variante outline" checked />
      </.colm>
      """,
      "switch-colors" => ~H"""
      <.gr cols={5} gap="12px 28px">
        <%= for c <- @colors, st <- @sw_states do %>
          <.switch color={c} checked={st != "off"} variant={if String.contains?(st, "outline"), do: "outline", else: "basic"} filled={String.contains?(st, "filled")} disabled={st == "dis"} />
        <% end %>
      </.gr>
      """,
      "switch-sizes" => ~H"""
      <.gr cols={6} gap="14px 24px">
        <%= for sh <- @sw_shapes, s <- @sw_sizes, on <- [false, true] do %>
          <.switch color="primary" checked={on} size={s} shape={sh} />
        <% end %>
      </.gr>
      """,
      "switch-inset" => ~H"""
      <.row>
        <.switch :for={i <- @insets} color="primary" checked size="lg" thumb_inset={i} />
      </.row>
      """,
      "switch-labels" => ~H"""
      <.gr cols={2} gap="16px 40px">
        <.switch color="primary" label="Notificar no WhatsApp" checked description="Mensagem quando a nota for autorizada" />
        <.switch color="primary" label="Cobrança automática" label_position="left" description="Rótulo à esquerda" />
        <.switch color="primary" label="Atualização ao vivo" checked />
        <.switch color="primary" label="Pequeno" checked size="sm" />
      </.gr>
      """,
      "radio-basic" => ~H"""
      <.gr cols={8} gap="12px 16px">
        <%= for c <- @colors, s <- @sizes, on <- [true, false] do %>
          <.radio color={c} size={s} checked={on} />
        <% end %>
      </.gr>
      """,
      "radio-shapes" => ~H"""
      <.row>
        <.radio color="primary" label="circle" checked />
        <.radio color="primary" label="squircle" shape="squircle" checked />
        <.radio color="primary" label="filled" filled />
        <.radio color="primary" label="desabilitado" checked disabled />
      </.row>
      """,
      "radio-card" => ~H"""
      <.gr cols={2} gap="10px 16px" just="stretch">
        <.radio_group name="c1" value="e" variant="card" options={[%{label: "Essencial", value: "e", description: "Até 500 notas/mês", count: "R$ 89"}, %{label: "Profissional", value: "p", description: "Notas ilimitadas", count: "R$ 189"}, %{label: "Sem preço", value: "s", description: "Só descrição"}]} />
        <.radio_group name="c2" value="e" variant="card" control="end" options={[%{label: "Básico", value: "e", description: "Até 500 notas/mês", count: "R$ 89"}, %{label: "Premium", value: "p", description: "Notas ilimitadas", count: "R$ 189"}]} />
      </.gr>
      """,
      "radio-chip" => ~H"""
      <.colm>
        <.radio_group name="chip1" value="Boleto" variant="chip" options={["Pix", "Boleto", "Cartão", "Dinheiro"]} />
        <.radio_group name="chip2" value="Aberto" variant="chip" shape="pill" color="success" options={["Aberto", "Pago", "Vencido"]} />
      </.colm>
      """,
      "radio-tile" => ~H"""
      <.row>
        <.radio_group name="t1" value="M" variant="tile" options={~w(PP P M G GG)} />
        <.radio_group name="t2" value="2" variant="tile" color="secondary" options={~w(1 2 3)} />
      </.row>
      """,
      "segmented-basic" => ~H"""
      <.colm>
        <.row>
          <.segmented id="sg1" value="month" options={[{"Day", "day"}, {"Month", "month"}, {"Year", "year"}]} />
          <.segmented id="sg2" value="todos" options={[%{label: "Todos", value: "todos", count: 15}, %{label: "Erros", value: "erros", count: 3}, %{label: "Sucesso", value: "sucesso", count: 8}, %{label: "Avisos", value: "avisos", count: 4}]} />
        </.row>
        <.row><.segmented id="sg3" size="sm" value="30d" options={~w(7d 30d 90d 12m)} /></.row>
        <div style="max-width:420px"><.segmented id="sg4" full value="m" options={[{"Mensal", "m"}, {"Anual", "a"}]} /></div>
      </.colm>
      """,
      "chip-basic" => ~H"""
      <.colm>
        <.row>
          <.chip selected={true}>Todos</.chip>
          <.chip selected={false}>Em risco</.chip>
          <.chip selected={false}>Expansão</.chip>
          <.chip selected={false}>Novos</.chip>
          <.chip dashed icon="plus">Filtro</.chip>
        </.row>
        <.row>
          <.chip tone="acc" selected={true} icon="check" count={412}>Pro</.chip>
          <.chip tone="acc" selected={false} count={298}>Scale</.chip>
          <.chip tone="acc" selected={true} icon="check" count={386}>Starter</.chip>
        </.row>
      </.colm>
      """,
      "textarea-variants" => ~H"""
      <.gr cols={3} gap="12px 14px" just="stretch">
        <%= for v <- ~w(outlined filled plain), s <- ~w(sm md lg) do %>
          <.textarea name={"ta-#{v}-#{s}"} placeholder="Escreva uma observação…" variant={v} size={s} />
        <% end %>
      </.gr>
      """,
      "textarea-counter" => ~H"""
      <.gr cols={4} gap="12px 14px" just="stretch">
        <.textarea name="tc1" label="normal" value="Cliente pediu nota com CPF." counter maxlength={200} />
        <.textarea name="tc2" label="aviso (≥ 90%)" value="Texto longo quase no limite…" counter maxlength={30} />
        <.textarea name="tc3" label="excedido" value="Texto que passou do limite…" counter maxlength={20} state="error" />
        <.textarea name="tc4" label="mínimo" value="Curto" counter min_length={20} help="Explique o motivo" />
      </.gr>
      """,
      "textarea-state" => ~H"""
      <.gr cols={2} gap="12px 14px" just="stretch">
        <.textarea name="ts1" label="Motivo" value="Cancelado a pedido do cliente." state="success" help="Motivo registrado" />
        <.textarea name="ts2" label="Motivo" placeholder="Obrigatório" state="error" help="Informe o motivo do cancelamento" />
      </.gr>
      """,
      "textarea-bars" => ~H"""
      <.gr cols={2} gap="12px 14px" just="stretch">
        <.textarea name="tb1" label="Modelo de mensagem" value="Olá, {{cliente}}! Sua nota {{numero}} foi autorizada. O boleto vence em {{vencimento}}." tokens>
          <:header><span class="text-xs text-muted">Variáveis</span></:header>
          <:footer><.icon name="bold" size="sm" /><.icon name="italic" size="sm" /><span class="ml-auto text-xs leading-5 text-muted tabular-nums">96 / 300</span></:footer>
        </.textarea>
      </.gr>
      """,
      "otp-sizes" => ~H"""
      <.colm>
        <.row :for={s <- ~w(sm md lg)}><.otp_input name={"o-#{s}"} value="4829" size={s} autofocus /></.row>
      </.colm>
      """,
      "otp-variants" => ~H"""
      <.gr cols={3} gap="14px 24px">
        <.otp_input name="ov1" label="length=4" value="1234" length={4} />
        <.otp_input name="ov2" label="separator=3" value="482915" separator={3} />
        <.otp_input name="ov3" label="alphanumeric" value="A7K2Q9" mode="alphanumeric" />
      </.gr>
      """,
      "otp-states" => ~H"""
      <.gr cols={3} gap="14px 24px">
        <.otp_input name="os1" label="success" value="482915" state="success" help="Código confirmado" />
        <.otp_input name="os2" label="error" value="482910" state="error" help="Código inválido. Restam 2 tentativas." />
        <.otp_input name="os3" label="disabled" disabled />
      </.gr>
      """,
      "number-styles" => ~H"""
      <.gr cols={3} gap="14px 18px">
        <%= for st <- ~w(inset round joined), s <- ~w(sm md lg) do %>
          <.number_input name={"n-#{st}-#{s}"} value={12} steppers stepper_style={st} size={s} />
        <% end %>
      </.gr>
      """,
      "number-addons" => ~H"""
      <.gr cols={4} gap="14px 18px">
        <.number_input name="na1" label="Preço" value={1284.9} decimals={2} prefix="R$" align="right" />
        <.number_input name="na2" label="Desconto" value={12.5} max_decimals={1} suffix="%" align="right" />
        <.number_input name="na3" label="Peso" value={0.75} decimals={3} suffix="kg" align="right" />
        <.number_input name="na4" label="Quantidade" value={3} steppers prefix="un" />
      </.gr>
      """,
      "number-states" => ~H"""
      <.row>
        <.number_input name="ns1" value={8} variant="filled" steppers />
        <.number_input name="ns2" value={0} disabled steppers />
        <.number_input name="ns3" label="max=10" value={10} steppers />
      </.row>
      """,
      "password-strength" => ~H"""
      <.gr cols={4} gap="14px 18px" just="stretch">
        <.password_input name="p1" label="Fraca" value="abc123" strength="weak" help="Muito curta" />
        <.password_input name="p2" label="Média" value="abc123" strength="fair" help="Adicione símbolos" />
        <.password_input name="p3" label="Boa" value="abc123" strength="good" help="Quase lá" />
        <.password_input name="p4" label="Forte" value="abc123" strength="strong" help="Senha forte" />
      </.gr>
      """,
      "input-group-basic" => ~H"""
      <.colm>
        <.input_group><.input_group_addon>R$</.input_group_addon><.input name="g1" value="1.250" variant="plain" /><.input_group_addon>,00</.input_group_addon></.input_group>
        <.input_group size="sm"><.input_group_addon size="sm">$</.input_group_addon><.input name="g2" value="49" variant="plain" size="sm" /></.input_group>
        <.input_group size="lg"><.input_group_addon size="lg">https://</.input_group_addon><.input name="g3" value="ledgerly.app" variant="plain" size="lg" /></.input_group>
        <.input_group shape="pill"><.input_group_addon>@</.input_group_addon><.input name="g4" value="usuario" variant="plain" shape="pill" /></.input_group>
        <.input_group variant="filled"><.input_group_addon>USD</.input_group_addon><.input name="g5" value="14.860" variant="plain" /></.input_group>
        <.input_group state="error"><.input_group_addon>$</.input_group_addon><.input name="g6" value="-3" variant="plain" state="error" /></.input_group>
      </.colm>
      """,
      "form-section-basic" => ~H"""
      <.colm>
        <.form_section title="Contato" description="Como falamos com você" divider={false}>
          <.input label="E-mail" value="voce@empresa.com" />
          <.input label="Telefone" value="(11) 99999-0000" />
        </.form_section>
        <.form_section title="Endereço" description="Usado na NF-e" layout="aside" columns={3}>
          <.input label="CEP" value="40000-000" />
          <.input label="Cidade" value="Salvador" />
          <.input label="UF" value="BA" />
        </.form_section>
      </.colm>
      """,
      "select-basic" => ~H"""
      <.colm>
        <div style="width:260px"><.select label="Plano" value="Pro" options={~w(Pro Scale Starter)} /></div>
        <div style="width:260px"><.select label="Região" placeholder="Escolha uma região" options={~w(Norte Sul)} /></div>
        <div style="width:260px"><.select label="Desabilitado" disabled value="EMEA" options={~w(EMEA)} /></div>
      </.colm>
      """,
      "select-open" => ~H"""
      <div style="width:260px"><.select id="so1" open value="Pro" options={["Pro", "Scale", "Starter", %{label: "Enterprise", value: "Enterprise", disabled: true, hint: "Em breve"}]} /></div>
      """,
      "pillbox-basic" => ~H"""
      <.colm>
        <div style="width:260px"><.pillbox id="pb1" value={["Pro", "Scale"]} removable options={~w(Pro Scale Starter)} /></div>
        <div style="width:260px"><.pillbox id="pb2" placeholder="Escolha segmentos" options={~w(Pro Scale Starter)} /></div>
      </.colm>
      """,
      "autocomplete-open" => ~H"""
      <div style="width:260px"><.autocomplete id="ac1" open display_value="Orbit Cloud" options={[%{label: "Orbit Cloud", value: "oc", initials: "OC", tone: "t1", hint: "Pro · $4.2k"}, %{label: "Orbital Labs", value: "ol", initials: "OL", tone: "t2", hint: "Scale · $1.9k"}, %{label: "Orbis Systems", value: "os", initials: "OS", tone: "t3", hint: "Starter · $340"}]} /></div>
      """,
      "autocomplete-closed" => ~H"""
      <.colm>
        <div style="width:260px"><.autocomplete id="ac2" label="Conta" placeholder="Buscar conta" options={~w(Pro)} /></div>
        <div style="width:260px"><.autocomplete id="ac3" label="Plano" size="sm" display_value="Pro" options={~w(Pro)} /></div>
      </.colm>
      """,
      "tags-basic" => ~H"""
      <.colm>
        <.tags_input id="tg1" label="Tags da conta" value={["enterprise", "q4-renewal", "champion"]} removable placeholder="Digite e pressione Enter" />
        <.tags_input id="tg2" label="Sem tags" placeholder="Adicionar tag" />
      </.colm>
      """,
      "phone-basic" => ~H"""
      <.gr cols={2} gap="14px 18px" just="stretch">
        <.phone_input name="ph1" label="Telefone" value="+5575998123344" placeholder="(555) 000-0000" />
        <.phone_input name="ph2" label="WhatsApp" country="US" placeholder="(555) 000-0000" />
      </.gr>
      """,
      "filter-menu-open" => ~H"""
      <.filter_menu id="fm1" open locale="pt_BR" label="Filtros" groups={[%{name: "plano", caption: "Plano", display: :section, value: ["Pro", "Scale"], options: [%{label: "Pro", value: "Pro", count: 412}, %{label: "Scale", value: "Scale", count: 298}, %{label: "Starter", value: "Starter", count: 386}]}]} />
      <div style="height:260px"></div>
      """,
      "filter-menu-closed" => ~H"""
      <.row>
        <.filter_menu id="fm2" label="Filtros" />
        <.filter_menu id="fm3" label="Status" color="primary" variant="soft" size="sm" dashed />
      </.row>
      """,
      "pill-select-basic" => ~H"""
      <.colm>
        <.pill_select id="ps1" value="30 dias" options={["7 dias", "30 dias", "90 dias", "12 meses"]} />
        <.pill_select id="ps2" multiple value={["Pro", "Starter"]} options={[{"Pro", "Pro", 412}, {"Scale", "Scale", 298}, {"Starter", "Starter", 386}]} />
      </.colm>
      """
    }
  end
end
