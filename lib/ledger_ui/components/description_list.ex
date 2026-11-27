defmodule LedgerUI.Components.DescriptionList do
  @moduledoc """
  Label and value pairs in a grid, as the canvas description list: the label small and faint, the
  value in the ink colour. For the short data of a detail (an order, a client). Styled only with
  Tailwind utilities.

      <.description_list cols={2}>
        <:item label="Razão social">Mercadinho Bom Preço Ltda</:item>
        <:item label="CNPJ" mono>12.345.678/0001-90</:item>
      </.description_list>

  `cols` is 1 to 4. `layout="inline"` puts the label at the left and the value at the right. An
  item with no content shows `empty` ("—"). An item takes `id`, `class` and `style` for its
  `<dd>`, and `wrapper_id`, `wrapper_class` and `wrapper_style` for the `<div>` around the pair.

  `divider` (inline layout) is `"all"` (the default: a line under every item), `"between"` (no
  line under the last item of each column) or `"none"`. With `"between"` or `"none"` the spacing is
  symmetric: `py-2.5` per item (`pt-2.5`/`pb-2.5`), the first row with no top padding, the last row with no bottom
  padding, and no row gap. Which items are last is worked out on the server from the item count
  and `cols` (items fill the grid by row), so it does not depend on the inner markup.

      <.description_list layout="inline" cols={1} divider="between">
        <:item label="Emitente">Fabmed</:item>
        <:item label="Empenho" mono>2026NE000123</:item>
      </.description_list>
  """
  use LedgerUI.Component

  @cols %{
    1 => "grid-cols-[repeat(1,minmax(0,1fr))]",
    2 => "grid-cols-[repeat(2,minmax(0,1fr))]",
    3 => "grid-cols-[repeat(3,minmax(0,1fr))]",
    4 => "grid-cols-[repeat(4,minmax(0,1fr))]"
  }

  @pair %{
    "stacked" => "flex flex-col gap-[3px]",
    "inline" => "flex flex-row justify-between gap-3 border-b border-line pb-2.5"
  }

  @pair_symmetric "flex flex-row justify-between gap-3"

  attr :cols, :integer, default: 2, values: [1, 2, 3, 4]
  attr :layout, :string, default: "stacked", values: ~w(stacked inline)

  attr :divider, :string,
    default: "all",
    values: ~w(all between none),
    doc:
      "Inline layout lines: under every item (`all`), under all but the last of each column (`between`) or none. Anything but `all` also makes the spacing symmetric."

  attr :variant, :string,
    default: nil,
    values: [nil, "stacked", "inline"],
    doc: "The same as `layout`; it wins when given."

  attr :empty, :string, default: "—"
  attr :class, :any, default: nil
  attr :style, :string, default: nil
  attr :rest, :global

  slot :item, required: true, doc: "A pair: `label`, and the value as content." do
    attr :label, :string

    attr :title, :string,
      doc: "The same as `label` (the name Phoenix's generated `list` gives it)."

    attr :mono, :boolean
    attr :id, :string
    attr :class, :any
    attr :style, :string
    attr :wrapper_id, :string
    attr :wrapper_class, :any
    attr :wrapper_style, :string
  end

  def description_list(assigns) do
    assigns = assign(assigns, :layout, assigns.variant || assigns.layout)

    symmetric? = assigns.layout == "inline" and assigns.divider in ["between", "none"]

    assigns =
      assigns
      |> assign(
        :classes,
        cx([
          "grid gap-x-6",
          if(symmetric?, do: "gap-y-0", else: "gap-y-[14px]"),
          @cols[assigns.cols] || @cols[2],
          assigns.class
        ])
      )
      |> assign(:pair, @pair[assigns.layout] || @pair["stacked"])
      |> assign(:symmetric?, symmetric?)
      |> assign(:total, length(assigns.item))
      |> assign(:root_attrs, if(assigns.style, do: %{style: assigns.style}, else: %{}))

    ~H"""
    <dl data-part="description-list" class={@classes} {@root_attrs} {@rest}>
      <div
        :for={{item, index} <- Enum.with_index(@item)}
        data-part="description-list-item"
        {wrapper_attrs(item, pair_class(assigns, index))}
      >
        <dt data-part="description-list-term" class="text-[12px] leading-5 text-muted">
          {item[:label] || item[:title]}
        </dt>
        <dd data-part="description-list-detail" {dd_attrs(item)}>
          {if blank_slot?(item[:inner_block]), do: @empty, else: render_slot(item)}
        </dd>
      </div>
    </dl>
    """
  end

  # Items fill the grid by row, so the item at `index` is in column `rem(index, cols)`; it is the
  # last of its column when no item fits a row below it.
  defp pair_class(%{symmetric?: false, pair: pair}, _index), do: pair

  defp pair_class(assigns, index) do
    cols = assigns.cols
    last? = index + cols >= assigns.total

    cx([
      @pair_symmetric,
      assigns.divider == "between" and not last? and "border-b border-line",
      if(index < cols, do: "pt-0", else: "pt-2.5"),
      if(last?, do: "pb-0", else: "pb-2.5")
    ])
  end

  # A call with a body but only named slots still carries an empty `inner_block`.
  defp blank_slot?(slot) when slot in [nil, []], do: true
  defp blank_slot?([%{inner_block: %Phoenix.LiveView.Rendered{static: [""]}}]), do: true
  defp blank_slot?(_), do: false

  # Attributes go in maps so empty ones are not rendered (`style={nil}` would give `style=""`).
  defp wrapper_attrs(item, pair) do
    attrs =
      for {key, name} <- [wrapper_id: :id, wrapper_style: :style],
          v = item[key],
          into: %{},
          do: {name, v}

    Map.put(attrs, :class, cx([pair, item[:wrapper_class]]))
  end

  defp dd_attrs(item) do
    cls = cx(["m-0 text-[14px] leading-5 font-medium", item[:mono] && "font-mono", item[:class]])
    attrs = for {key, v} <- [id: item[:id], style: item[:style]], v, into: %{}, do: {key, v}
    Map.put(attrs, :class, cls)
  end
end
