defmodule Parity.Cases.DadosA do
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

  @img "data:image/svg+xml;utf8,%3Csvg xmlns='http://www.w3.org/2000/svg' width='40' height='40'%3E%3Crect width='40' height='40' fill='%23e8b04a'/%3E%3Ccircle cx='20' cy='16' r='7' fill='%23fff'/%3E%3Crect x='8' y='26' width='24' height='14' rx='7' fill='%23fff'/%3E%3C/svg%3E"

  def cases do
    assigns = %{
      img: @img,
      colors: @colors,
      variants: ~w(solid soft bordered skeleton),
      sizes: [16, 20, 24, 26, 30, 32, 36, 44, 56, 72],
      shapes: ~w(circle square rounded squircle reuleaux-triangle diamond hexagon hexagon-2 octagon star star-2 heart),
      slides: [{"linear-gradient(135deg,#1f9282,#0c4b44)", "Promoção de novembro"}, {"linear-gradient(135deg,#6a4fd8,#2b3577)", "Novo: NFC-e"}, {"linear-gradient(135deg,#e8b04a,#b07a2c)", "Black Friday"}],
      ct_rows: [%{n: "PED-2491", c: "Mercadinho Bom Preço"}],
      tones: ~w(online away busy offline),
      positions: [nil, "top-left", "top-right", "bottom-left"],
      ring_colors: ~w(primary secondary info success warning error neutral),
      gradients: ~w(sky-blue amber-orange pink-rose purple-orange green-fuchsia purple-indigo fuchsia-pink),
      kinds: [{"neutral", "building"}, {"primary", "user"}, {"warning", "truck"}, {"secondary", "sparkles"}, {"info", "plus"}],
      overlaps: ~w(2 3 7 auto),
      group_people: [{"IS", "t2"}, {"FP", "t3"}, {"CA", "t4"}, {"AN", "t5"}],
      small_people: [{"IS", "info"}, {"FP", "success"}, {"CA", "warning"}],
      spread_people: [{"AN", "primary"}, {"CA", "info"}, {"FP", "warning"}],
      more_people: [{"AN", "primary"}, {"CA", "info"}],
      timer_colors: ~w(neutral primary secondary info success warning error),
      tcolors: ~w(neutral primary secondary info success warning error light),
      dl: [{"Razão social", "Mercadinho Bom Preço Ltda"}, {"CNPJ", "12.345.678/0001-90"}, {"Regime", "Simples Nacional"}, {"Cidade", "Feira de Santana · BA"}, {"Desde", "jan 2024"}, {"Limite", "R$ 15.000,00"}],
      minis: [{"invoice", "accent", "Board packs", "4 relatórios"}, {"user-minus", "error", "Pro churn watch", "23 contas"}, {"globe", "info", "EMEA expansion", "12 contas"}, {"wallet", "success", "Receber", "Pix e boleto"}, {"zap", "warning", "Atenção", "3 pendências"}],
      pxs: [{"red", "cart", "Loja", "PDV, estoque, NFC-e"}, {"rose", "smile", "Clínica", "Agenda e prontuário"}, {"green", "wallet", "Financeiro", "Contas e conciliação"}, {"teal", "trend-up", "Receita", "MRR e coortes"}, {"blue", "users", "CRM", "Contas e pipeline"}, {"violet", "sparkles", "Assistente", "IA nos seus dados"}, {"amber", "calendar", "Agenda", "Horários e lembretes"}, {"ink", "code", "API", "Chaves e webhooks"}],
      masks: ~w(squircle reuleaux-triangle diamond hexagon hexagon-2 octagon star star-2 heart),
      img2: "data:image/svg+xml;utf8,%3Csvg xmlns='http://www.w3.org/2000/svg' width='200' height='80'%3E%3Crect width='200' height='80' fill='%23c4a000'/%3E%3Ccircle cx='60' cy='40' r='30' fill='%23fff' opacity='.4'/%3E%3C/svg%3E",
      tvariants: ~w(solid soft bordered outline flat),
      chart_tags: [{"Pro", "chart-1"}, {"Scale", "chart-2"}, {"Contract", "chart-3"}, {"Churn", "chart-4"}, {"Starter", "chart-5"}]
    }

    %{
      "avatar-colors" => ~H"""
      <.gr cols={4} gap="12px 28px">
        <%= for c <- @colors, v <- @variants do %>
          <.avatar initials="BP" color={c} variant={v} size="40" />
        <% end %>
      </.gr>
      """,
      "avatar-sizes" => ~H"""
      <.row>
        <.avatar :for={px <- @sizes} initials="AN" color="primary" variant="soft" size={to_string(px)} />
      </.row>
      """,
      "avatar-shapes" => ~H"""
      <.row>
        <.avatar :for={s <- @shapes} initials="AN" color="primary" shape={s} size="44" />
      </.row>
      """,
      "avatar-status" => ~H"""
      <.colm>
        <.row>
          <%= for t <- @tones, p <- @positions do %>
            <.avatar initials="AN" color="primary" variant="soft" size="40" status={t} status_position={p} />
          <% end %>
        </.row>
        <.row>
          <.avatar :for={t <- @tones} initials="AN" color="primary" variant="soft" size="40" status={t} ping />
          <.avatar :for={c <- ~w(primary secondary info)} initials="AN" color="primary" variant="soft" size="40" status={c} status_position="top-right" />
        </.row>
        <.row>
          <.avatar :for={px <- [16, 24, 32, 56, 72]} initials="AN" color="primary" variant="soft" size={to_string(px)} status="online" />
        </.row>
      </.colm>
      """,
      "avatar-rings" => ~H"""
      <.colm>
        <.row>
          <.avatar initials="AN" color="primary" variant="soft" size="40" ring />
          <.avatar initials="AN" color="primary" variant="soft" size="40" ring={1} />
          <.avatar initials="AN" color="primary" variant="soft" size="40" ring={2} />
          <.avatar initials="AN" color="primary" variant="soft" size="40" ring={4} />
          <.avatar initials="AN" color="primary" variant="soft" size="40" ring ring_color="panel" />
          <span style="background:var(--lu-inverse);padding:6px;border-radius:12px;display:inline-flex"><.avatar initials="AN" color="primary" variant="soft" size="40" ring ring_color="white" /></span>
        </.row>
        <.row>
          <.avatar :for={c <- @ring_colors} initials="AN" color="primary" variant="soft" size="40" ring ring_color={c} />
        </.row>
        <.row>
          <.avatar :for={g <- @gradients} initials="AN" size="40" gradient={g} />
        </.row>
      </.colm>
      """,
      "avatar-kinds" => ~H"""
      <.row>
        <%= for {c, i} <- @kinds do %>
          <.avatar color={c} variant="soft" size="40" icon={i} />
        <% end %>
        <.avatar color="primary" variant="soft" size="40" icon="user" />
        <.avatar color="none" size="40" icon="user" />
      </.row>
      """,
      "avatar-custom" => ~H"""
      <.row>
        <.avatar initials="AN" size="40" tint="#1a7f4b" />
        <.avatar initials="CA" size="56" shape="rounded" background="linear-gradient(135deg,#f97316,#ec4899)" />
        <.avatar initials="FP" size="56" shape="hexagon" tint="#4f46e5" />
        <.avatar initials="IS" size="32" variant="mono" />
        <.avatar initials="SM" size="32" variant="mono" shape="square" />
        <.avatar initials="OC" size="40" color="none" shape="square" />
      </.row>
      """,
      "avatar-image" => ~H"""
      <.row>
        <.avatar src={@img} alt="Ana" size="32" />
        <.avatar src={@img} alt="Ana" size="44" shape="squircle" />
        <.avatar src={@img} alt="Ana" size="56" shape="hexagon" status="online" />
        <.avatar src={@img} alt="Ana" size="56" shape="heart" />
      </.row>
      """,
      "avatar-legacy" => ~H"""
      <.row>
        <.avatar :for={t <- ~w(t2 t3 t4 t5 none)} initials="IS" color={t} size="36" />
        <.avatar initials="IS" color="t3" shape="square" size="36" />
        <.avatar initials="PB" color="none" variant="mono" size="32" />
        <.avatar initials="SM" color="none" variant="mono" size="32" status="online" />
      </.row>
      """,
      "avatar-legacy-t1" => ~H"""
      <.row>
        <.avatar :for={px <- [24, 36, 48]} initials="IS" color="t1" size={to_string(px)} />
      </.row>
      """,
      "avatar-group" => ~H"""
      <.colm>
        <.avatar_group :for={o <- @overlaps} overlap={o} more={8} size="sm-plus">
          <.avatar :for={{i, t} <- @group_people} initials={i} color={t} size="sm-plus" />
        </.avatar_group>
        <.avatar_group more={2} size="xs" ring_color="panel">
          <.avatar :for={{i, c} <- @small_people} initials={i} color={c} variant="soft" size="xs" />
        </.avatar_group>
        <.avatar_group>
          <.avatar initials="A" color="primary" variant="soft" size="md" ring={2} />
          <.avatar initials="B" color="primary" variant="bordered" size="md" />
          <.avatar initials="C" color="primary" variant="solid" size="md" />
        </.avatar_group>
        <.avatar_group spread>
          <.avatar :for={{i, c} <- @spread_people} initials={i} color={c} variant="soft" size="md" />
        </.avatar_group>
      </.colm>
      """,
      "avatar-group-more" => ~H"""
      <.avatar_group id="grp-more" hidden={[%{name: "Ana Souza"}, %{name: "Beto Lima"}, %{name: "Caio Reis"}]} size="sm">
        <.avatar :for={{i, c} <- @more_people} initials={i} color={c} variant="soft" size="sm" />
      </.avatar_group>
      """,
      "tag-matrix" => ~H"""
      <.gr cols={5} gap="10px 12px">
        <%= for c <- @tcolors, v <- @tvariants do %>
          <.tag as="span" color={c} variant={v}>{String.capitalize(c)}</.tag>
        <% end %>
      </.gr>
      """,
      "tag-shapes" => ~H"""
      <.colm>
        <.row>
          <.tag as="span" color="primary" variant="soft">rounded</.tag>
          <.tag as="span" color="primary" variant="soft" shape="pill">pill</.tag>
          <.tag as="span" color="primary" variant="soft" shape="square">square</.tag>
          <.tag as="span" color="neutral" variant="solid" removable>Removível</.tag>
          <.tag as="span" color="info" variant="bordered" shape="pill" count={3}>Com contagem</.tag>
        </.row>
        <.row>
          <.tag as="span" tint="#0d8f91">VIP</.tag>
          <.tag as="span" color="error" variant="soft" shape="pill" removable>Inadimplente</.tag>
          <.tag as="span" color="primary" variant="outline" shape="square" removable>Contorno</.tag>
        </.row>
        <.tag_group>
          <.tag as="span" color="neutral">Primary</.tag>
          <.tag as="span" color="primary">55</.tag>
          <.tag as="span" color="success" variant="soft" shape="pill">Ok</.tag>
        </.tag_group>
      </.colm>
      """,
      "tag-pressable" => ~H"""
      <.row>
        <.tag color="primary" variant="soft">Botão</.tag>
        <.tag href="#" color="info" variant="bordered" shape="pill" style="text-decoration:none">Link</.tag>
        <.tag color="primary" variant="soft" active>Ativa</.tag>
        <.tag color="neutral" variant="flat" count={2} removable>Filtro</.tag>
      </.row>
      """,
      "tag-canvas" => ~H"""
      <.row>
        <.tag :for={{t, c} <- @chart_tags} canvas swatch={"var(--lu-#{c})"} removable>{t}</.tag>
        <.tag canvas>Sem amostra</.tag>
        <.tag canvas aria-pressed="true">Pressionada</.tag>
        <.tag canvas aria-pressed="true">Ativa</.tag>
      </.row>
      """,
      "description-list-cols" => ~H"""
      <.colm>
        <.description_list :for={c <- [1, 2, 3, 4]} cols={c}>
          <:item :for={{l, v} <- @dl} label={l}>{v}</:item>
        </.description_list>
        <.description_list cols={3}>
          <:item :for={{l, v} <- @dl} label={l} mono={l == "CNPJ"}>{v}</:item>
          <:item label="Observação" />
        </.description_list>
      </.colm>
      """,
      "description-list-inline" => ~H"""
      <.colm>
        <.description_list cols={2} layout="inline">
          <:item :for={{l, v} <- @dl} label={l}>{v}</:item>
        </.description_list>
        <.description_list cols={1} variant="inline">
          <:item :for={{l, v} <- @dl} label={l} mono={l == "CNPJ"}>{v}</:item>
        </.description_list>
      </.colm>
      """,
      "mini-card-panel" => ~H"""
      <.gr cols={3} gap="12px" just="stretch">
        <.mini_card :for={{i, t, n, m} <- @minis} href="#" icon={i} tone={t} label={n}><span class="text-xs/4 text-muted">{m}</span></.mini_card>
        <.mini_card icon="file" label="Sem tom"><span class="text-xs/4 text-muted">Neutro</span></.mini_card>
      </.gr>
      """,
      "mini-card-value" => ~H"""
      <.gr cols={2} gap="12px" just="stretch">
        <.mini_card label="A receber" value="R$ 41,2 mil" />
        <.mini_card label="Vencidas" value="R$ 3,4 mil" />
      </.gr>
      """,
      "mini-card-surface" => ~H"""
      <.gr cols={3} gap="10px" just="stretch">
        <.mini_card :for={t <- ~w(accent success warning error info neutral)} surface="card" icon="file" tone={t} label={t}><span>Atalho</span></.mini_card>
      </.gr>
      """,
      "pixel-card-colors" => ~H"""
      <.gr cols={4} gap="10px" just="stretch">
        <.pixel_card :for={{c, i, t, d} <- @pxs} id={"pxc-" <> c} href="#" color={c} icon={i} title={t} description={d} />
      </.gr>
      """,
      "pixel-card-states" => ~H"""
      <.gr cols={3} gap="10px" just="stretch">
        <.pixel_card id="pxs-1" href="#" icon="trend-up" title="Padrão" description="Sem cor, usa o accent" />
        <.pixel_card id="pxs-2" href="#" color="ink" icon="code" title="Sem seta" description="Sem seta" arrow={false} />
        <.pixel_card id="pxs-3" color="violet" icon="sparkles" title="Botão" description="Sem link" />
      </.gr>
      """,
      "cover-bands" => ~H"""
      <.colm>
        <.cover height={140} />
        <.cover tone="neutral" height={100} />
        <.cover height={120} title="Distribuidora Sertão" />
        <.cover tone="neutral" height={90} title="Título no neutro" />
      </.colm>
      """,
      "cover-avatar" => ~H"""
      <.colm>
        <.cover height={110} title="Distribuidora Sertão" subtitle="Cliente desde 2021">
          <:avatar><.avatar initials="DS" tint="#1a7f4b" size="64" shape="rounded" /></:avatar>
        </.cover>
        <.cover tone="neutral" height={90} title="Sem subtítulo">
          <:avatar><.avatar initials="SS" color="primary" variant="solid" size="64" shape="rounded" /></:avatar>
        </.cover>
      </.colm>
      """,
      "cover-image" => ~H"""
      <.cover height={110} src={@img2} />
      """,
      "mask-shapes" => ~H"""
      <.row>
        <.mask :for={s <- @masks} shape={s} size="64" style="background:linear-gradient(135deg,var(--lu-accent-300),var(--lu-accent-700))">BP</.mask>
      </.row>
      """,
      "mask-sizes" => ~H"""
      <.row>
        <.mask :for={px <- [24, 32, 44, 56, 72]} shape="hexagon" size={to_string(px)}>BP</.mask>
        <.mask shape="star" size="56" label="Favorito">MK</.mask>
      </.row>
      """,
      "mask-image" => ~H"""
      <.row>
        <.mask :for={s <- ~w(heart hexagon squircle)} shape={s} src={@img} alt="Ana" size="64" />
      </.row>
      """,
      "timer-ring" => ~H"""
      <.colm>
        <.row>
          <.timer :for={s <- ~w(sm md lg)} id={"tr-s-" <> s} size={s} format="hh:mm" elapsed={15600} total={24000} />
        </.row>
        <.row>
          <.timer :for={{c, k} <- Enum.with_index(@timer_colors)} id={"tr-c-" <> c} size="sm" color={c} format="hh:mm" elapsed={300 * (40 + k * 8)} total={30000} />
        </.row>
        <.row>
          <.timer id="tr-z" size="sm" format="hh:mm" elapsed={0} total={600} />
          <.timer id="tr-f" size="sm" color="success" format="hh:mm" elapsed={28800} total={28800} />
          <.timer id="tr-t" size="sm" color="warning" format="hh:mm" elapsed={9600} total={28800} />
        </.row>
      </.colm>
      """,
      "timer-extras" => ~H"""
      <.row>
        <.timer id="te-1" elapsed={15600} total={24000} kicker="Register open" kicker_paused="Paused" label="Register 01">
          <:actions>
            <.button canvas size="sm">Pause</.button>
            <.button canvas size="sm">+15 min</.button>
          </:actions>
        </.timer>
        <.timer id="te-2" running={false} elapsed={7200} total={24000} kicker="Register open" kicker_paused="Paused" label="Register 02" />
        <.timer id="te-3" size="sm" color="primary" direction="down" elapsed={900} total={3600} kicker="Break" label="Countdown" />
      </.row>
      """,
      "timer-mini" => ~H"""
      <.row>
        <.timer id="tm-1" variant="mini" elapsed={5076} />
        <.timer id="tm-2" variant="mini" running={false} elapsed={5076} format="hms" />
        <.timer id="tm-3" variant="mini" elapsed={1476} format="auto" />
      </.row>
      """,
      "cash-timer-states" => ~H"""
      <.colm>
        <.cash_timer id="ct-1" state="open" title="Caixa 1 · aberto às 08:00" elapsed={8048} running={false} amount="R$ 3.412,90" />
        <.cash_timer id="ct-2" state="closed" title="Caixa 2 fechado · ontem às 18:04" elapsed={28800} amount="R$ 6.412,30">
          <:action><.button canvas size="sm">Abrir caixa</.button></:action>
        </.cash_timer>
        <.cash_timer id="ct-3" state="alert" title="Conferência do caixa 2" difference="− R$ 12,50">
          <:stat label="Esperado">R$ 6.412,30</:stat>
          <:stat label="Contado">R$ 6.399,80</:stat>
        </.cash_timer>
        <.cash_timer id="ct-4" title="Revisão do board pack · Orbit Cloud" elapsed={5076} running={false} amount="$169.20" />
      </.colm>
      """,
      "bulk-bar-pill" => ~H"""
      <.colm>
        <.bulk_bar :for={v <- ~w(inverse soft solid)} id={"bb-" <> v} variant={v} count={3} label="selecionado" label_plural="selecionados" floating={false} on_clear="clear" clear_label="Limpar">
          <:action icon="file">Emitir NF-e</:action>
          <:action icon="download">Exportar</:action>
          <:action variant="danger" icon="trash">Excluir</:action>
        </.bulk_bar>
        <.bulk_bar id="bb-one" count={1} label="selecionado" label_plural="selecionados" floating={false}>
          <:action icon="file">Emitir NF-e</:action>
          <:action icon="download">Exportar</:action>
        </.bulk_bar>
        <.bulk_bar id="bb-esc" count={2} total={50} label="selecionado" label_plural="selecionados" floating={false} on_clear="clear" on_select_all="all" show_esc clear_label="Limpar" select_all_label="Selecionar todos %{total}">
          <:action icon="file">Emitir NF-e</:action>
          <:action icon="download">Exportar</:action>
          <:action variant="danger" icon="trash">Excluir</:action>
        </.bulk_bar>
      </.colm>
      """,
      "bulk-bar-progress" => ~H"""
      <.bulk_bar id="bb-prog" count={4} label="selecionados" floating={false} progress={4} progress_max={10} />
      """,
      "bulk-bar-inline" => ~H"""
      <.colm>
        <.bulk_bar id="bi-1" variant="inline" count={25} total={1096} label="selecionadas" label_plural="selecionadas" on_select_all="all" select_all_label="Selecionar todas as %{total}">
          <:action icon="folder">Mover</:action>
          <:action icon="download" variant="primary">Exportar</:action>
          <:action icon="trash" variant="danger">Excluir</:action>
        </.bulk_bar>
        <.bulk_bar id="bi-2" variant="inline" count={1096} total={1096} label="selecionadas" label_plural="selecionadas">
          <:action icon="folder">Mover</:action>
          <:action icon="download" variant="primary">Exportar</:action>
          <:action icon="trash" variant="danger">Excluir</:action>
        </.bulk_bar>
        <.bulk_bar id="bi-3" variant="inline" count={3} label="selecionado" label_plural="selecionados" />
      </.colm>
      """,
      "bulk-bar-float" => ~H"""
      <div style="position:relative;height:130px;background:var(--lu-bg-tray);border-radius:14px">
        <.bulk_bar id="bf-1" variant="float" count={3} label="selecionado" label_plural="selecionados" on_clear="clear" clear_label="Limpar">
          <:action icon="file">Emitir NF-e</:action>
          <:action icon="download">Exportar</:action>
          <:action variant="danger" icon="trash">Excluir</:action>
        </.bulk_bar>
      </div>
      """,
      "carousel-slide" => ~H"""
      <.colm>
        <.carousel id="c1" navigation pagination="bullets" slides={3} style="max-width:560px">
          <.carousel_slide :for={{bg, t} <- @slides} style={"background:" <> bg}>{t}</.carousel_slide>
        </.carousel>
        <.carousel id="c2" pagination="fraction" slides={3} style="max-width:300px">
          <.carousel_slide :for={{bg, t} <- @slides} style={"background:" <> bg}>{t}</.carousel_slide>
        </.carousel>
        <.carousel id="c3" pagination="progress" slides={3} style="max-width:300px">
          <.carousel_slide :for={{bg, t} <- @slides} style={"background:" <> bg}>{t}</.carousel_slide>
        </.carousel>
        <.carousel id="c4" style="max-width:360px">
          <.carousel_slide :for={{bg, t} <- @slides} style={"background:" <> bg}>{t}</.carousel_slide>
          <:thumb :for={{bg, _} <- @slides}><span style={"display:block;width:100%;height:100%;background:" <> bg}></span></:thumb>
        </.carousel>
      </.colm>
      """,
      "card-table-tray" => ~H"""
      <.colm>
        <.card_table id="t1" rows={@ct_rows} title="Pedidos" meta="128" description="Os últimos pedidos do mês">
          <:col :let={r} label="Pedido">{r.n}</:col>
          <:col :let={r} label="Cliente">{r.c}</:col>
          <:actions><.button canvas size="sm" icon="download">Exportar</.button></:actions>
          <:foot><span>Mostrando 1 de 128</span><span>Atualizado agora</span></:foot>
        </.card_table>
        <.card_table id="t2" rows={@ct_rows}>
          <:col :let={r} label="Pedido">{r.n}</:col>
          <:col :let={r} label="Cliente">{r.c}</:col>
        </.card_table>
        <.card_table id="t3" rows={@ct_rows} title="Sem borda" bordered={false}>
          <:col :let={r} label="Pedido">{r.n}</:col>
          <:col :let={r} label="Cliente">{r.c}</:col>
        </.card_table>
        <.card_table id="t4" rows={@ct_rows} title="Plano" meta="3" variant="flat">
          <:col :let={r} label="Pedido">{r.n}</:col>
          <:col :let={r} label="Cliente">{r.c}</:col>
          <:foot><span>Rodapé</span></:foot>
        </.card_table>
      </.colm>
      """
    }
  end
end
