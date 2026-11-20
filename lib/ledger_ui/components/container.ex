defmodule LedgerUI.Components.Container do
  @moduledoc """
  Page containers: `container_fixed/1` centers its content up to the `xl` breakpoint (1280px),
  `container_fluid/1` fills the width. Both keep a 24px gutter.

      <.container_fixed>
        <h1>Title</h1>
      </.container_fixed>

  The sizing is in the stylesheet (`lu-container-fixed`, `lu-container-fluid`), so a `style` or a
  `class` of the caller only adds to it.

  ## Preview

  `preview` draws the canvas diagram of a container instead of a real one: a hatched bar (`lu-cont`) with
  the accent span that shows the width of a `size` (`sm` 640px, `md` 768px, `lg` 1024px, `xl` 1280px,
  `2xl` 1536px, `prose` 68ch, `full` 100%). `label` and `width` override the text and the span width;
  the slot is ignored. For the documentation and the showcase only.

      <.container_fixed preview size="lg" style="flex:1" />
  """
  use LedgerUI.Component

  @sizes %{
    "sm" => {"38%", "640px"},
    "md" => {"48%", "768px"},
    "lg" => {"64%", "1024px"},
    "xl" => {"80%", "1280px"},
    "2xl" => {"96%", "1536px"},
    "prose" => {"44%", "68ch"},
    "full" => {"100%", "100%"}
  }

  @doc false
  def preview_sizes, do: Map.keys(@sizes)

  attr :size, :string, default: nil, values: [nil | Map.keys(@sizes)]
  attr :label, :string, default: nil
  attr :width, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  defp container_preview(assigns) do
    {w, l} = Map.get(@sizes, assigns.size, {"100%", "container"})
    assigns = assign(assigns, width: assigns.width || w, label: assigns.label || l)

    ~H"""
    <div data-part="container" class={cx(["lu-cont", @class])} {@rest}>
      <span style={"width:#{@width}"}>{@label}</span>
    </div>
    """
  end

  attr :preview, :boolean, default: false, doc: "The canvas diagram of a container."

  attr :size, :string,
    default: nil,
    values: [nil | Map.keys(@sizes)],
    doc: "With `preview`: the size drawn."

  attr :label, :string, default: nil, doc: "With `preview`: the text of the bar."
  attr :width, :string, default: nil, doc: "With `preview`: the width of the bar."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block

  @doc "A centered container, as wide as the `xl` breakpoint at most."
  def container_fixed(%{preview: true} = assigns), do: container_preview(assigns)

  def container_fixed(assigns) do
    ~H"""
    <div data-part="container" class={cx(["lu-container-fixed", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :preview, :boolean, default: false, doc: "The canvas diagram of a container."

  attr :size, :string,
    default: nil,
    values: [nil | Map.keys(@sizes)],
    doc: "With `preview`: the size drawn."

  attr :label, :string, default: nil, doc: "With `preview`: the text of the bar."
  attr :width, :string, default: nil, doc: "With `preview`: the width of the bar."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block

  @doc "A container as wide as its parent."
  def container_fluid(%{preview: true} = assigns), do: container_preview(assigns)

  def container_fluid(assigns) do
    ~H"""
    <div data-part="container" class={cx(["lu-container-fluid", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @widths %{
    "sm" => "640px",
    "md" => "768px",
    "lg" => "1024px",
    "xl" => "1280px",
    "2xl" => "1536px",
    "prose" => "68ch"
  }

  attr :size, :string,
    default: nil,
    values: [nil, "full" | Map.keys(@widths)],
    doc:
      "The widest the content gets: `sm` 640px, `md` 768px, `lg` 1024px, `xl` 1280px, `2xl` 1536px, `prose` 68ch, `full` the parent's width. Without it, as `container_fixed/1`."

  attr :class, :any, default: nil
  attr :style, :string, default: nil
  attr :rest, :global
  slot :inner_block

  @doc """
  A centered container with a gutter, sized by `size`.

      <.container size="lg">...</.container>
      <.container size="prose" class="py-10">...</.container>
  """
  def container(assigns) do
    max = @widths[assigns.size]

    assigns =
      assign(assigns,
        classes:
          cx([
            if(assigns.size == "full", do: "lu-container-fluid", else: "lu-container-fixed"),
            assigns.class
          ]),
        style: if(max, do: cx_style("max-width:#{max}", assigns.style), else: assigns.style)
      )

    ~H"""
    <div data-part="container" class={@classes} style={@style} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp cx_style(a, nil), do: a
  defp cx_style(a, b), do: a <> ";" <> b
end
