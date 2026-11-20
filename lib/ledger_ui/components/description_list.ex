defmodule LedgerUI.Components.DescriptionList do
  @moduledoc """
  Label and value pairs in a grid, as the canvas `lu-dl2`: the label small and faint, the value
  in the ink colour. For the short data of a detail (an order, a client).

      <.description_list cols={2}>
        <:item label="Razão social">Mercadinho Bom Preço Ltda</:item>
        <:item label="CNPJ" mono>12.345.678/0001-90</:item>
      </.description_list>

  `cols` is 1 to 4. `layout="inline"` puts the label at the left and the value at the right. An
  item with no content shows `empty` ("—"). An item takes `id`, `class` and `style` for its
  `<dd>`, and `wrapper_id`, `wrapper_class` and `wrapper_style` for the `<div>` around the pair.
  """
  use LedgerUI.Component

  attr :cols, :integer, default: 2, values: [1, 2, 3, 4]
  attr :layout, :string, default: "stacked", values: ~w(stacked inline)
  attr :empty, :string, default: "—"
  attr :class, :any, default: nil
  attr :style, :string, default: nil
  attr :rest, :global

  slot :item, required: true, doc: "A pair: `label`, and the value as content." do
    attr :label, :string
    attr :mono, :boolean
    attr :id, :string
    attr :class, :any
    attr :style, :string
    attr :wrapper_id, :string
    attr :wrapper_class, :any
    attr :wrapper_style, :string
  end

  def description_list(assigns) do
    assigns =
      assigns
      |> assign(:classes, cx(["lu-dl2", assigns.layout == "inline" && "inline", assigns.class]))
      |> assign(
        :root_style,
        Enum.join(Enum.filter(["--cols:#{assigns.cols}", assigns.style], & &1), ";")
      )

    ~H"""
    <dl data-part="description-list" class={@classes} style={@root_style} {@rest}>
      <div :for={item <- @item} {wrapper_attrs(item)}>
        <dt>{item[:label]}</dt>
        <dd {dd_attrs(item)}>{if item.inner_block == [], do: @empty, else: render_slot(item)}</dd>
      </div>
    </dl>
    """
  end

  # Attributes go in maps so empty ones are not rendered (`style={nil}` would give `style=""`).
  defp wrapper_attrs(item) do
    for {key, name} <- [wrapper_id: :id, wrapper_class: :class, wrapper_style: :style],
        v = item[key],
        into: %{},
        do: {name, v}
  end

  defp dd_attrs(item) do
    cls = cx([item[:mono] && "mono", item[:class]])
    attrs = for {key, v} <- [id: item[:id], style: item[:style]], v, into: %{}, do: {key, v}
    if cls == "", do: attrs, else: Map.put(attrs, :class, cls)
  end
end
