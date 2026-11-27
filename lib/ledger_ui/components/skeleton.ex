defmodule LedgerUI.Components.Skeleton do
  @moduledoc """
  Loading placeholder that mirrors the final layout. Styled only with Tailwind utilities; the
  size comes from `class` (a block is 12px high until a `h-*` class says otherwise).

      <.skeleton class="h-3 w-40" animation="wave" />
      <.skeleton shape="circle" class="size-10" />

      <.skeleton_group label="Loading orders">
        <.skeleton class="w-3/5" />
      </.skeleton_group>

  `skeleton_group` with `loop` and a `:loaded` slot plays the canvas loop: the placeholder, then the
  content that arrives, in turn (CSS only).

  ## Table placeholder

  `variant="table"` draws `rows` x `cols` blocks as a table-like grid (a `skeleton_group`, announced
  to screen readers). Use it while a list has no first result, e.g. with `assign_async`:

      <.async_result :let={orders} assign={@orders}>
        <:loading><.skeleton variant="table" rows={5} cols={4} /></:loading>
        <:failed :let={_reason}>Could not load</:failed>
        <.table ...>...</.table>
      </.async_result>

  `animation={nil}` (or `"none"`) draws a still block; `tag="span"` draws a span (inside a flex
  column). `shape` is the corner: the base block has the small radius, so `"rounded"` (or `nil`)
  keeps it.
  """
  use LedgerUI.Component

  @animations %{
    "wave" =>
      "after:absolute after:inset-0 after:content-[''] after:[transform:translateX(-100%)] " <>
        "after:bg-[linear-gradient(90deg,transparent,color-mix(in_oklab,var(--lu-bg-panel)_70%,transparent),transparent)] " <>
        "after:animate-[lu-wave_1.4s_ease-in-out_infinite]",
    "pulse" => "animate-[lu-pulse_1.4s_ease-in-out_infinite]",
    "none" => nil
  }

  @shapes %{
    "pill" => "rounded-full",
    "circle" => "rounded-[50%]",
    "square" => "rounded-none",
    "lg" => "rounded-lg"
  }

  attr :animation, :string, default: "wave", values: [nil | ~w(wave pulse none)]

  attr :variant, :string,
    default: "canvas",
    values: ~w(canvas lineone table),
    doc: "`table` draws a `rows` x `cols` grid of blocks (see the moduledoc)."

  attr :rows, :integer, default: 5, doc: "`variant=\"table\"`: number of rows."
  attr :cols, :integer, default: 4, doc: "`variant=\"table\"`: number of columns."
  attr :shape, :string, default: nil, values: [nil | ~w(rounded pill circle square lg)]
  attr :tag, :string, default: "div", values: ~w(div span), doc: "The element drawn."
  attr :class, :any, default: nil
  attr :rest, :global

  def skeleton(%{variant: "table"} = assigns) do
    ~H"""
    <.skeleton_group class={["flex flex-col gap-3", @class]} {@rest}>
      <div
        :for={_ <- 1..max(@rows, 1)//1}
        data-part="skeleton-row"
        class="grid items-center gap-4"
        style={"grid-template-columns:repeat(#{max(@cols, 1)},minmax(0,1fr))"}
      >
        <.skeleton :for={c <- 1..max(@cols, 1)//1} animation={@animation} class={col_width(c)} />
      </div>
    </.skeleton_group>
    """
  end

  def skeleton(assigns) do
    changed0 = assigns.__changed__

    assigns =
      assign(
        assigns,
        :classes,
        cx([
          "relative overflow-hidden bg-sunken",
          # the corner: the old slate block (`lineone`) has 3px; the shape decides otherwise
          cond do
            assigns.variant == "lineone" -> "rounded-[3px]"
            assigns.shape in ~w(pill circle square lg) -> @shapes[assigns.shape]
            true -> "rounded-sm"
          end,
          # a `h-*` in `class` is the caller's height
          !height?(assigns.class) && "h-3",
          assigns.animation && @animations[assigns.animation]
        ])
      )

    assigns = settle(assigns, changed0, classes: [:variant, :shape, :class, :animation])

    ~H"""
    <.dynamic_tag tag_name={@tag} data-part="skeleton" class={[@classes, @class]} {@rest}>
    </.dynamic_tag>
    """
  end

  defp col_width(c), do: Enum.at(~w(w-full w-4/5 w-3/5 w-2/3), rem(c - 1, 4))

  defp height?(class) do
    class |> cx() |> String.split() |> Enum.any?(&Regex.match?(~r/^(h|size|min-h)-/, &1))
  end

  # the loop of the canvas (`clipswap`): the placeholder, then the content that arrives, in turn
  @swap_a "animate-[lu-sw-a_4s_ease-in-out_infinite] motion-reduce:animate-none"
  @swap_b "animate-[lu-sw-b_4s_ease-in-out_infinite] opacity-0 motion-reduce:animate-none"

  attr :label, :string, default: nil, doc: "Read by screen readers; not drawn."

  attr :loop, :boolean,
    default: false,
    doc:
      "The canvas loop (`lu-sw-a`/`lu-sw-b`): the placeholder, then the `:loaded` content, forever (demos)."

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  slot :loaded, doc: "With `loop`: the content that replaces the placeholder."

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def skeleton_group(%{loop: true, loaded: [_ | _]} = assigns) do
    changed0 = assigns.__changed__
    assigns = I18n.texts(assigns, label: "skeleton.loading")
    assigns = assign(assigns, swap_a: @swap_a, swap_b: @swap_b)
    assigns = settle(assigns, changed0, swap_a: [], swap_b: [])

    ~H"""
    <div
      data-part="skeleton-group"
      role="status"
      aria-busy="true"
      class={["grid *:col-start-1 *:row-start-1", @class]}
      {@rest}
    >
      <span data-part="skeleton-label" class="sr-only">{@label}</span>
      <div data-part="skeleton-loading" class={["flex flex-col", @swap_a]}>
        {render_slot(@inner_block)}
      </div>
      <div data-part="skeleton-loaded" class={@swap_b}>{render_slot(@loaded)}</div>
    </div>
    """
  end

  def skeleton_group(assigns) do
    assigns = I18n.texts(assigns, label: "skeleton.loading")

    ~H"""
    <div data-part="skeleton-group" role="status" aria-busy="true" class={@class} {@rest}>
      <span data-part="skeleton-label" class="sr-only">{@label}</span>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
