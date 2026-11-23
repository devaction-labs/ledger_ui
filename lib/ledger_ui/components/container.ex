defmodule LedgerUI.Components.Container do
  @moduledoc """
  Page containers: `container_fixed/1` centers its content up to the `xl` breakpoint (1280px),
  `container_fluid/1` fills the width. Both keep a 24px gutter.

      <.container_fixed>
        <h1>Title</h1>
      </.container_fixed>

  The sizing is plain utilities (width 100%, a 24px gutter, `max-w-*` and `mx-auto` for the fixed
  one), so a `class` or a `style` of the caller only adds layout to it.

  ## Preview

  `preview` draws the canvas diagram of a container instead of a real one: a hatched bar with
  the accent span that shows the width of a `size` (`sm` 640px, `md` 768px, `lg` 1024px, `xl` 1280px,
  `2xl` 1536px, `prose` 68ch, `full` 100%). `label` and `width` override the text and the span width;
  the slot is ignored. For the documentation and the showcase only.

      <.container_fixed preview size="lg" class="flex-1" />
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
  attr :loop, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global

  defp container_preview(assigns) do
    {w, l} = Map.get(@sizes, assigns.size, {"100%", "container"})
    assigns = assign(assigns, width: assigns.width || w, label: assigns.label || l)

    ~H"""
    <div
      data-part="container"
      class={
        cx([
          "grid h-10 place-items-center rounded-md shadow-[inset_0_0_0_1px_var(--lu-line)]",
          "bg-[repeating-linear-gradient(45deg,var(--lu-bg-sunken)_0_6px,transparent_6px_12px)]",
          @class
        ])
      }
      {@rest}
    >
      <span
        data-part="container-preview-label"
        class={[
          "grid h-full place-items-center bg-accent-soft font-mono text-[11.5px] text-accent-content",
          "shadow-[inset_0_0_0_1px_color-mix(in_oklab,var(--lu-accent)_40%,transparent)]",
          @loop && "animate-[mo-contw_6s_ease-in-out_infinite]"
        ]}
        style={"width:#{@width}"}
      >{@label}</span>
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

  attr :loop, :boolean,
    default: false,
    doc: "With `preview`: the span breathes between narrow and wide (`--w` is the wide end)."

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block

  @doc "A centered container, as wide as the `xl` breakpoint at most."
  def container_fixed(%{preview: true} = assigns), do: container_preview(assigns)

  def container_fixed(assigns) do
    ~H"""
    <div
      data-part="container"
      class={cx(["mx-auto w-full max-w-[1280px] px-6", @class])}
      {@rest}
    >
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

  attr :loop, :boolean,
    default: false,
    doc: "With `preview`: the span breathes between narrow and wide (`--w` is the wide end)."

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block

  @doc "A container as wide as its parent."
  def container_fluid(%{preview: true} = assigns), do: container_preview(assigns)

  def container_fluid(assigns) do
    ~H"""
    <div data-part="container" class={cx(["w-full px-6", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @widths %{
    "sm" => "max-w-[640px]",
    "md" => "max-w-[768px]",
    "lg" => "max-w-[1024px]",
    "xl" => "max-w-[1280px]",
    "2xl" => "max-w-[1536px]",
    "prose" => "max-w-[68ch]"
  }

  attr :size, :string,
    default: nil,
    values: [nil, "full" | Map.keys(@widths)],
    doc:
      "The widest the content gets: `sm` 640px, `md` 768px, `lg` 1024px, `xl` 1280px, `2xl` 1536px, `prose` 68ch, `full` the parent's width. Without it, as `container_fixed/1`."

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block

  @doc """
  A centered container with a gutter, sized by `size`.

      <.container size="lg">...</.container>
      <.container size="prose" class="py-10">...</.container>
  """
  def container(assigns) do
    assigns =
      assign(
        assigns,
        :classes,
        cx([
          "w-full px-6",
          assigns.size != "full" && "mx-auto",
          assigns.size != "full" && (@widths[assigns.size] || "max-w-[1280px]"),
          assigns.class
        ])
      )

    ~H"""
    <div data-part="container" class={@classes} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
