defmodule Parity.Cases.Actions do
  use Phoenix.Component
  use LedgerUI
  import Parity.Common

  @colors ~w(neutral primary secondary info success warning error white mono)
  @sizes ~w(xs sm md lg xl)

  def cases do
    buttons =
      for v <- ~w(solid glow outline soft bordered flat glass ghost dim), into: %{} do
        assigns = %{v: v, colors: @colors}

        {"button-#{v}",
         ~H"""
         <.row><.button :for={c <- @colors} color={c} variant={@v} size="sm">Botão</.button></.row>
         """}
      end

    badges =
      for v <- ~w(solid glow soft outline flat bordered), into: %{} do
        assigns = %{v: v, colors: Enum.take(@colors, 7)}

        {"badge-#{v}",
         ~H"""
         <.row><.badge :for={c <- @colors} color={c} variant={@v}>{String.capitalize(c)}</.badge></.row>
         """}
      end

    matrix =
      for sz <- ~w(xs md lg xl), into: %{} do
        assigns = %{sz: sz, colors: @colors, variants: ~w(solid glow outline soft bordered flat glass ghost dim)}

        {"button-matrix-#{sz}",
         ~H"""
         <.colm>
           <.row :for={v <- @variants}><.button :for={c <- @colors} color={c} variant={v} size={@sz}>Btn</.button></.row>
         </.colm>
         """}
      end

    assigns = %{sizes: @sizes, colors: @colors, variants: ~w(solid glow outline soft bordered flat glass ghost dim),
                squares: [{"neutral", "solid"}, {"primary", "soft"}, {"error", "outline"}, {"success", "ghost"}, {"secondary", "glow"}, {"mono", "flat"}]}

    Map.merge(buttons, badges)
    |> Map.merge(matrix)
    |> Map.merge(%{
      "button-sizes" => ~H"""
      <.row><.button :for={s <- @sizes} size={s}>{String.upcase(s)}</.button></.row>
      """,
      "button-shapes" => ~H"""
      <.row>
        <.button>Rounded</.button>
        <.button shape="pill">Pill</.button>
        <.button icon="huge-plus" aria-label="Adicionar" />
        <.button color="primary" variant="soft" icon="huge-sparkles" aria-label="IA" />
      </.row>
      """,
      "button-states" => ~H"""
      <.row>
        <.button icon="huge-download">Export report</.button>
        <.button variant="outline" trailing_icon="huge-arrow-right">Com ícone à direita</.button>
        <.button disabled>Disabled</.button>
      </.row>
      """,
      "button-group" => ~H"""
      <.row>
        <.button_group>
          <.button variant="outline" size="sm">Day</.button>
          <.button variant="outline" size="sm">Week</.button>
          <.button variant="soft" size="sm">Month</.button>
        </.button_group>
        <.button_group shape="pill">
          <.button variant="outline" size="sm" icon="huge-chevron-left">Anterior</.button>
          <.button variant="outline" size="sm" trailing_icon="huge-chevron-right">Próximo</.button>
        </.button_group>
      </.row>
      """,
      "badge-sizes" => ~H"""
      <.row>
        <.badge :for={s <- @sizes} color="primary" size={s}>{String.upcase(s)}</.badge>
        <.badge color="success" shape="pill">Pill</.badge>
      </.row>
      """,
      "button-pill" => ~H"""
      <.colm>
        <.row :for={v <- @variants}><.button :for={c <- @colors} color={c} variant={v} size="sm" shape="pill">Pill</.button></.row>
      </.colm>
      """,
      "button-square" => ~H"""
      <.colm>
        <.row :for={{c, v} <- @squares}><.button :for={s <- @sizes} color={c} variant={v} size={s} shape="square" icon="huge-plus" aria-label="x" /></.row>
      </.colm>
      """,
      "button-loading-pip" => ~H"""
      <.row>
        <.button loading>Salvando</.button>
        <.button loading color="primary" variant="soft">Salvando</.button>
        <.button loading color="error">Salvando</.button>
        <.button variant="outline" icon="huge-bell" pip aria-label="Notificações" />
      </.row>
      """,
      "button-current" => ~H"""
      <div style="color:#b45309">
        <.row>
          <.button color="current">Current</.button>
          <.button color="current" variant="outline">Current</.button>
          <.button color="current" variant="ghost">Current</.button>
          <.button color="current" variant="soft">Current</.button>
        </.row>
      </div>
      """,
      "button-canvas" => ~H"""
      <.row>
        <.button canvas>Default</.button>
        <.button canvas size="sm">Small</.button>
        <.button canvas size="lg">Large</.button>
        <.button canvas disabled>Disabled</.button>
        <.button canvas icon="huge-filter">Filter</.button>
      </.row>
      """,
      "icon-button" => ~H"""
      <.colm>
        <.row>
          <.icon_button icon="plus" label="Adicionar" variant="primary" />
          <.icon_button icon="filter" label="Filtrar" />
          <.icon_button icon="more-h" label="Mais" variant="soft" />
          <.icon_button icon="x" label="Fechar" variant="ghost" />
          <.icon_button icon="trash" label="Excluir" variant="danger-soft" />
          <.icon_button icon="sparkles" label="IA" variant="accent" />
        </.row>
        <.row>
          <.icon_button icon="settings" label="Config" size="sm" />
          <.icon_button icon="settings" label="Config" />
          <.icon_button icon="settings" label="Config" size="lg" />
        </.row>
      </.colm>
      """,
      "icon-button-topbar" => ~H"""
      <.row>
        <.insight_button count={3}>New AI insights</.insight_button>
        <.icon_button icon="bell" label="Notificações" variant="topbar" dot />
        <.icon_button icon="moon" label="Tema escuro" variant="topbar" />
        <.icon_button icon="arrow-right" label="Abrir" variant="go" />
      </.row>
      """,
      "badge-shapes" => ~H"""
      <.colm>
        <.row :for={sh <- ~w(rounded pill square)}>
          <.badge :for={s <- @sizes} color="info" size={s} shape={sh}>{sh} {s}</.badge>
        </.row>
      </.colm>
      """,
      "badge-colors-all" => ~H"""
      <.colm>
        <.row :for={v <- ~w(solid soft outline)}>
          <.badge :for={c <- @colors} color={c} variant={v} size="lg">{String.capitalize(c)}</.badge>
        </.row>
      </.colm>
      """,
      "badge-icon" => ~H"""
      <.row>
        <.badge color="primary" variant="outline" icon="huge-sparkles">3 novos</.badge>
        <.badge color="success" size="lg" shape="pill" icon="huge-check">Pago</.badge>
      </.row>
      """,
      "badge-canvas" => ~H"""
      <.row>
        <.badge canvas color="primary" dot="live" class="tracking-[.06em] text-[11px] font-semibold uppercase">Live</.badge>
        <.badge canvas>Neutral</.badge>
        <.badge canvas color="primary">Primary</.badge>
        <.badge canvas color="success">Success</.badge>
        <.badge canvas color="error">Error</.badge>
        <.badge canvas color="warning">Warning</.badge>
        <.badge canvas color="info">Info</.badge>
        <.badge canvas color="lime">Lime</.badge>
        <.badge canvas variant="solid">Solid</.badge>
        <.badge canvas variant="outline">Outline</.badge>
        <.badge canvas variant="outline" color="success">Pos</.badge>
        <.badge canvas variant="outline" color="warning">Warn</.badge>
        <.badge canvas variant="outline" color="primary">Acc</.badge>
        <.badge canvas variant="outline" color="error">Neg</.badge>
        <.badge canvas color="primary" size="sm">Beta</.badge>
        <.badge canvas size="lg">Grande</.badge>
      </.row>
      """,
      "icon-sizes" => ~H"""
      <.colm>
        <.row><.icon :for={s <- ~w(sm md base lg xl)} name="huge-package" size={s} /></.row>
        <.row>
          <.icon boxed tone="accent" name="sparkles" />
          <.icon boxed tone="success" name="check" />
          <.icon boxed tone="error" name="x-circle" />
          <.icon boxed tone="warning" name="alert" />
          <.icon boxed tone="info" name="info" />
          <.icon boxed tone="lime" name="ai" />
          <.icon boxed name="file" />
        </.row>
        <.row><.icon boxed tone="accent" box_size="lg" name="sparkles" size="lg" /></.row>
      </.colm>
      """
    })
  end
end
