defmodule MyAppWeb.Page do
  use Phoenix.Component

  def page(assigns) do
    ~H"""
    <.badge :for={t <- @tags} :key={t.id} color="success">{t.name}</.badge>
    <.table id="items" rows={@items} row_id={&"item-#{&1.id}"}>
      <:col :let={r} label="A" wrap="auto">{r.a}</:col>
    </.table>
    <.command_palette id="palette" items={@pages} defer_items />
    <.select id="s" no_results="Nada aqui" options={@opts} locale="en" />
    """
  end
end
