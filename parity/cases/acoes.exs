defmodule Parity.Cases.Acoes do
  @moduledoc "Lote Ações: palette, clipboard, divider, fab, fab-dial, illustration, kbd, typography."
  use Phoenix.Component
  use LedgerUI
  import Parity.Common

  # `lu-fabdemo`: the box the floating buttons live in
  attr :h, :integer, default: 150
  slot :inner_block, required: true

  defp stage(assigns) do
    ~H"""
    <div
      class="relative overflow-hidden rounded-[16px] border border-line bg-tray"
      style={"height:#{@h}px"}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :cols, :integer, default: 2
  attr :gap, :integer, default: 16
  slot :inner_block, required: true

  defp grid(assigns) do
    ~H"""
    <div
      class="grid grid-cols-[repeat(var(--cols),minmax(0,1fr))]"
      style={"--cols:#{@cols};gap:#{@gap}px"}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @swatches [
    [
      {"--bg-page", "Página", "#ffffff", "#0e100f"},
      {"--bg-shell", "Shell / sidebar", "#f6f6f4", "#121413"},
      {"--bg-tray", "Bandeja do card", "#f4f4f2", "#161918"},
      {"--bg-panel", "Painel", "#ffffff", "#1b1e1d"},
      {"--bg-sunken", "Afundado", "#f1f1ef", "#202422"},
      {"--bg-selected", "Selecionado", "#e9e9e6", "#2a2e2c"}
    ],
    [
      {"--ink", "Ink", "#141514", "#f2f3f2"},
      {"--ink-2", "Ink 2", "#3b3d3b", "#c9cdcb"},
      {"--muted", "Muted", "#6b6d69", "#9ba19e"},
      {"--subtle", "Subtle (ícone)", "#8f918c", "#6f7572"},
      {"--line", "Linha", "#e8e8e5", "#2a2e2c"},
      {"--line-strong", "Linha forte", "#d7d7d3", "#3a3f3c"}
    ],
    [
      {"--inverse", "Inverso (botão)", "#141514", "#f2f3f2"},
      {"--accent", "Accent", "#1f9282", "#2fa792"},
      {"--pos", "Positivo", "#11773e", "#4cc985"},
      {"--neg", "Negativo", "#b72f48", "#f0788b"},
      {"--warn", "Aviso", "#8f5606", "#f0b453"},
      {"--info", "Info", "#2e64c9", "#7aa7f2"},
      {"--lime", "Oportunidade", "#3f6b0e", "#b9e27a"},
      {"--lime-soft", "Oportunidade suave", "#e2f6c6", "#1f2c10"}
    ]
  ]

  defp swatches(rows) do
    for r <- rows,
        do:
          {length(r),
           for({token, name, light, dark} <- r, do: %{token: token, name: name, light: light, dark: dark})}
  end

  def cases do
    assigns = %{swatches: swatches(@swatches)}

    palette = %{
      "palette-ramp" => ~H|<.palette variant="ramp" />|,
      "palette-chips" => ~H|<.palette variant="chips" />|,
      "palette-swatches" => ~H"""
      <.colm>
        <.palette :for={{cols, colors} <- @swatches} cols={cols} colors={colors} />
      </.colm>
      """,
      "palette-swatches-chart" => ~H"""
      <.palette
        cols={5}
        colors={[
          %{token: "--chart-1", name: "Série 1 · Pro", light: "#1f9282", dark: "#2fa792"},
          %{token: "--chart-3", name: "Série 3 · Contract", light: "#e8b04a", dark: "#e8b04a"},
          %{token: "--chart-4", name: "Série 4 · Churn", light: "#e57487", dark: "#e57487"},
          %{token: "--chart-5", name: "Série 5 · Starter", light: "#9fdacc", dark: "#2e5f56"},
          %{token: "--chart-ghost", name: "Comparação", light: "#b9bbb6", dark: "#565c59"}
        ]}
      />
      """,
      "palette-chart-2" => ~H"""
      <.palette
        cols={1}
        colors={[%{token: "--chart-2", name: "Série 2 · Scale", light: "#0c4b44", dark: "#a5e3d6"}]}
      />
      """
    }

    divider = %{
      "divider-horizontal" => ~H"""
      <.colm>
        <.divider />
        <.divider>ou continue com</.divider>
        <.divider align="left">Entrega</.divider>
        <.divider />
      </.colm>
      """,
      "divider-vertical" => ~H"""
      <.colm>
        <.row><span>Day</span><.divider orientation="vertical" /><span>Month</span><.divider orientation="vertical" /><span>Year</span></.row>
        <.row><span>Esquerda</span><.divider orientation="vertical" style="height:40px" /><span>Direita</span></.row>
      </.colm>
      """
    }

    kbd = %{
      "kbd-variants" => ~H"""
      <.colm>
        <.row>
          <.kbd>⌘</.kbd><.kbd>K</.kbd><.kbd>Ctrl</.kbd><.kbd>Shift</.kbd><.kbd>P</.kbd><.kbd>Esc</.kbd><.kbd>↑</.kbd><.kbd>↓</.kbd><.kbd>Enter</.kbd><.kbd>/</.kbd>
        </.row>
        <.row>
          <.kbd variant="flat">⌘</.kbd><.kbd variant="flat">K</.kbd><.kbd variant="flat">Esc</.kbd><.kbd variant="flat">/</.kbd>
        </.row>
        <.row>
          <span class="inline-block rounded-[8px] bg-inverse px-2.5 py-1.5 text-on-inverse">Buscar <.kbd variant="dark">⌘K</.kbd></span>
        </.row>
      </.colm>
      """
    }

    typography = %{
      "typography-sizes" => ~H"""
      <.colm>
        <.row>
          <.text as="span" size="xs">Signetum</.text><.text as="span" size="xs-plus">Signetum</.text><.text as="span" size="sm">Signetum</.text><.text as="span" size="base">Signetum</.text><.text as="span" size="lead">Signetum</.text><.text as="span" size="lg">Signetum</.text><.text as="span" size="xl">Signetum</.text><.text as="span" size="meta">Signetum</.text>
        </.row>
        <.row>
          <.text as="span" color="ink">Texto</.text><.text as="span" color="neutral">Texto</.text><.text as="span" color="muted">Texto</.text><.text as="span" color="subtle">Texto</.text><.text as="span" color="primary">Texto</.text><.text as="span" color="secondary">Texto</.text><.text as="span" color="success">Texto</.text><.text as="span" color="warning">Texto</.text><.text as="span" color="error">Texto</.text><.text as="span" color="info">Texto</.text>
        </.row>
        <.row>
          <.text as="span" weight="light">light</.text><.text as="span" weight="normal">normal</.text><.text as="span" weight="medium">medium</.text><.text as="span" weight="semibold">semibold</.text><.text as="span" weight="bold">bold</.text>
        </.row>
        <.row>
          <.text as="span" mono>mono 14</.text><.text as="span" size="lg" weight="semibold" color="ink">lg semibold ink</.text>
        </.row>
      </.colm>
      """,
      "typography-gradients" => ~H"""
      <.colm>
        <.row>
          <.text :for={g <- ~w(sky-blue green-fuchsia fuchsia-pink amber-orange purple-indigo)} as="span" gradient={g} size="lg" class="text-[22px]!">Signetum</.text>
        </.row>
        <.row><.text as="span" gradient="sky-blue" weight="medium" size="lg">weight medium</.text></.row>
      </.colm>
      """,
      "typography-decoration" => ~H"""
      <.row>
        <.text as="span" decoration="underline">underline</.text><.text as="span" decoration="line-through">line-through</.text><.text as="span" decoration="overline">overline</.text>
      </.row>
      """,
      "typography-links" => ~H"""
      <.row>
        <.text_link href="#">current</.text_link>
        <.text_link href="#" decoration_color="info" decoration_style="wavy">info wavy</.text_link>
        <.text_link href="#" decoration_color="primary" decoration_style="dotted">primary dotted</.text_link>
        <.text_link href="#" decoration_color="error" decoration_style="dashed">error dashed</.text_link>
        <.text_link href="#" decoration_color="secondary" decoration_style="double">secondary double</.text_link>
        <.text_link href="#" decoration_color="success">success</.text_link>
        <.text_link href="#" decoration_color="warning">warning</.text_link>
      </.row>
      """,
      "typography-inline-code" => ~H"""
      <.row>
        <span>Rode <.inline_code>mix test</.inline_code> e depois</span><.inline_code>mix format</.inline_code>
      </.row>
      """,
      "typography-headings" => ~H"""
      <.colm>
        <.heading level={1}>Título h1</.heading>
        <.heading level={2}>Título h2</.heading>
        <.heading level={3}>Título h3</.heading>
        <.heading level={4}>Título h4</.heading>
        <.heading level={5}>Título h5</.heading>
        <.heading level={6}>Título h6</.heading>
        <.heading level={2} size="title">Título h2</.heading>
        <.heading display={1}>Título h1</.heading>
        <.heading display={5}>Título h1</.heading>
        <.heading level={3} size="lg" color="info">Título h3</.heading>
        <.heading level={3} size="2xl" weight="light" color="muted">Título h3</.heading>
        <.heading level={3} size="sm" weight="bold">Título h3</.heading>
      </.colm>
      """
    }

    illustration = %{
      "illustration-states" => ~H"""
      <.row>
        <.illustration name="empty" /><.illustration name="success" /><.illustration name="error" /><.illustration name="search" /><.illustration name="offline" />
      </.row>
      """,
      "illustration-tones" => ~H"""
      <.row>
        <.illustration tone="primary" icon="inbox" /><.illustration tone="primary" icon="star" /><.illustration tone="warning" icon="bell" /><.illustration tone="error" icon="lock" /><.illustration tone="info" icon="sparkles" />
      </.row>
      """
    }

    clipboard = %{
      "clipboard-variants" => ~H"""
      <.colm>
        <.row>
          <.clipboard :for={v <- ~w(solid glow outline soft bordered flat ghost)} id={"cv-#{v}"} value="LDG-2026-1043" toast={nil} color="neutral" variant={v} size="sm" icon>Copiar</.clipboard>
        </.row>
        <.row>
          <.clipboard :for={c <- ~w(neutral primary secondary info success warning error)} id={"cc-#{c}"} value="LDG-2026-1043" toast={nil} color={c} variant="soft" size="sm" icon>Copiar</.clipboard>
        </.row>
        <.row>
          <.clipboard id="cp-1" value="x" toast={nil} color="primary" variant="solid" icon>Copiar</.clipboard>
          <.clipboard id="cp-2" value="x" toast={nil} color="error" variant="solid" icon>Copiar</.clipboard>
          <.clipboard id="cp-3" value="x" toast={nil} color="primary" variant="solid" icon_only aria-label="Copiar" />
        </.row>
      </.colm>
      """,
      "clipboard-sizes" => ~H"""
      <.row>
        <.clipboard :for={s <- ~w(xs sm md lg xl)} id={"cs-#{s}"} value="x" toast={nil} color="neutral" variant="outline" size={s} icon>Copiar</.clipboard>
        <.clipboard id="cs-icon" value="x" toast={nil} color="neutral" variant="ghost" size="sm" icon_only aria-label="Copiar" />
        <.clipboard id="cs-copied" size="sm" copied icon copied_label="Copiado" toast={nil} />
      </.row>
      """,
      "clipboard-input" => ~H"""
      <div style="max-width:460px">
        <.clipboard_input id="api-key" value="sk_live_51Hx…a9f2" field_label="Chave de API" leading_icon="key" label="Copiar" toast={nil} readonly />
      </div>
      """
    }

    fab = %{
      "fab-canvas" => ~H"""
      <.stage><.fab id="fc" label="Novo pedido" fixed={false}><:icon><.icon name="plus" size="md" /></:icon></.fab></.stage>
      """,
      "fab-pill-hover" => ~H"""
      <.stage><.fab id="fh" label="Pergunte ao assistente" variant="pill" fixed={false} /></.stage>
      """,
      "fab-pill-expanded" => ~H"""
      <.colm>
        <.stage><.fab id="fe1" label="Precisa de ajuda?" variant="pill" fixed={false} retract="auto"><:icon><.icon name="help" size="md" /></:icon></.fab></.stage>
        <.stage><.fab id="fe2" label="Nova fatura" variant="pill" fixed={false} color="primary" retract="never"><:icon><.icon name="plus" size="md" /></:icon></.fab></.stage>
        <.stage><.fab id="fe3" label="Chat com a equipe" variant="pill" fixed={false} color="light" retract="always" position="bottom-left" badge={3}><:icon><.icon name="chat" size="md" /></:icon></.fab></.stage>
        <.stage>
          <.fab id="fe4" label="Médio" variant="pill" fixed={false} color="dark" retract="never" position="bottom-left"><:icon><.icon name="plus" size="md" /></:icon></.fab>
          <.fab id="fe5" label="Grande" variant="pill" fixed={false} size="lg" expanded />
        </.stage>
      </.colm>
      """,
      "fab-pill-colors" => ~H"""
      <.row>
        <.fab :for={{c, l} <- [{"assistant", "Assistente"}, {"primary", "Primary"}, {"dark", "Dark"}, {"light", "Light"}]} id={"fk-#{c}"} label={l} variant="pill" fixed={false} color={c} retract="never" class="relative! right-auto! bottom-auto!" />
      </.row>
      """,
      "fab-pill-collapsed" => ~H"""
      <.row>
        <.fab id="fa-1" label="Assistente" variant="pill" fixed={false} color="assistant" retract="always" class="relative! right-auto! bottom-auto!" />
        <.fab id="fa-2" label="Primary" variant="pill" fixed={false} color="primary" retract="always" badge={7} class="relative! right-auto! bottom-auto!" />
        <.fab id="fa-3" label="Dark" variant="pill" fixed={false} color="dark" retract="always" class="relative! right-auto! bottom-auto!" />
        <.fab id="fa-4" label="Light" variant="pill" fixed={false} color="light" retract="always" badge={2} class="relative! right-auto! bottom-auto!" />
      </.row>
      """,
      "fab-positions" => ~H"""
      <.grid gap={12}>
        <.stage :for={p <- ~w(bottom-right bottom-left top-right top-left)} h={120}>
          <.fab id={"fp-#{p}"} label="Novo" variant="pill" fixed={false} color="dark" retract="always" position={p}><:icon><.icon name="plus" size="md" /></:icon></.fab>
        </.stage>
      </.grid>
      """,
      "fab-dial-open" => ~H"""
      <.grid>
        <.stage h={300}>
          <.fab_dial id="d1" label="Ações rápidas" fixed={false} open>
            <:action label="Novo contato"><.icon name="user-plus" /></:action>
            <:action label="Enviar arquivo"><.icon name="upload" /></:action>
            <:action label="Nova proposta"><.icon name="file" /></:action>
          </.fab_dial>
        </.stage>
        <.stage h={300}>
          <.fab_dial id="d2" label="Ações rápidas" fixed={false} variant="pill" open>
            <:action label="Novo contato"><.icon name="user-plus" /></:action>
            <:action label="Enviar arquivo"><.icon name="upload" /></:action>
            <:action label="Nova proposta"><.icon name="file" /></:action>
          </.fab_dial>
        </.stage>
      </.grid>
      """,
      "fab-dial-closed" => ~H"""
      <.grid>
        <.stage h={300}>
          <.fab_dial id="d3" label="Ações rápidas" fixed={false}>
            <:action label="Novo contato"><.icon name="user-plus" /></:action>
            <:action label="Enviar arquivo"><.icon name="upload" /></:action>
            <:action label="Nova proposta"><.icon name="file" /></:action>
          </.fab_dial>
        </.stage>
        <.stage h={300}>
          <.fab_dial id="d4" label="Ações rápidas" fixed={false} variant="pill">
            <:action label="Novo contato"><.icon name="user-plus" /></:action>
            <:action label="Enviar arquivo"><.icon name="upload" /></:action>
            <:action label="Nova proposta"><.icon name="file" /></:action>
          </.fab_dial>
        </.stage>
      </.grid>
      """
    }

    [palette, divider, kbd, typography, illustration, clipboard, fab]
    |> Enum.reduce(%{}, &Map.merge/2)
  end
end
