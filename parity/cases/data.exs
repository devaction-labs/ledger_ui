defmodule Parity.Cases.Data do
  use Phoenix.Component
  use LedgerUI

  import Parity.Common

  def cases do
    assigns = %{surfaces: ~w(default bordered outline muted soft filled solid glow gradient gradient_outline),
                colors: ~w(primary secondary info success warning error),
                tinted: for(v <- ~w(solid soft), c <- ~w(primary secondary info success warning error), do: {v, c}),
                gradients: ~w(purple-indigo fuchsia-pink amber-orange sky-blue green-fuchsia)}

    %{
      "card-tray" => ~H"""
      <.card title="Revenue by plan">
        <:actions><.button variant="outline" size="sm" trailing_icon="huge-arrow-up-right">Plans</.button></:actions>
        <p class="m-0 text-muted">Conteúdo do painel.</p>
        <:footer>trailing 12 mo</:footer>
      </.card>
      """,
      "card-surfaces" => ~H"""
      <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:12px">
        <.card :for={v <- @surfaces} variant={v}><:title>{v}</:title><span>Faturamento do mês</span></.card>
      </div>
      """,
      "card-surface-colors" => ~H"""
      <div style="display:grid;grid-template-columns:repeat(6,1fr);gap:8px">
        <.card :for={{v, c} <- @tinted} variant={v} color={c}><:title>{v}</:title><span>Faturamento do mês</span></.card>
        <.card :for={g <- @gradients} variant="gradient" gradient={g}><:title>gradient</:title><span>Faturamento do mês</span></.card>
      </div>
      """,
      "card-sizes" => ~H"""
      <.row>
        <.card :for={{s, p} <- [{"xs", 8}, {"sm", 11}, {"md", 14}, {"lg", 20}]} variant="default" size={s}><:title>{s}</:title></.card>
      </.row>
      """,
      "card-parts" => ~H"""
      <.card canvas>
        <.card_header>
          <.card_heading level={3}>Profile</.card_heading>
          <.card_actions><.button variant="outline" size="sm">Edit</.button></.card_actions>
        </.card_header>
        <.card_body>Corpo do cartão<.card_subheading class="mt-2">Subtítulo</.card_subheading></.card_body>
        <.card_footer>All changes saved</.card_footer>
      </.card>
      """,
      "card-sizes-heading" => ~H"""
      <.card canvas>
        <.card_header size="lg"><.card_heading level={3} size="lg">Heading lg</.card_heading></.card_header>
        <.card_body>x</.card_body>
      </.card>
      """,
      "card-flat" => ~H"""
      <.card variant="flat"><b>Card plano</b><p class="mt-1.5 mb-0 text-muted">Sem bandeja.</p></.card>
      """
    }
  end
end
