defmodule MyAppWeb.ItemsLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~H"""
    <.date_picker id="d" locale="pt_BR" />
    <.select id="s" no_results="Nenhum resultado encontrado" options={@opts} />
    <.chip id="c" remove_label="Remover" />
    <.command_palette id="palette" items={@pages} placeholder="Outra coisa" empty="Nada encontrado" />
    <.table id="items" rows={@items}>
      <:col :let={r} label="A">{r.a}</:col>
      <:cell class="px-2 whitespace-normal!">x</:cell>
    </.table>
    <.card_table id="ct" rows={@items} class="[&_th]:py-1">
      <:col label="A">a</:col>
    </.card_table>
    <.chip :for={n <- @notes} id={"n-#{n.id}"} />
    <.badge :for={t <- @tags} :key={t.id}>{t.name}</.badge>
    <.pagination id="p" page={1} pages={3} />
    """
  end
end
