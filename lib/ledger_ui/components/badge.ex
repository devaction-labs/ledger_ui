defmodule LedgerUI.Components.Badge do
  @moduledoc """
  Badges: `color` x `variant` x `size` x `shape`, with a dot, an icon or a remove button. Styled only
  with Tailwind utilities (the colour enters as `--c`/`--c-on`/`--c-soft`/`--c-ink`, see
  `LedgerUI.Color`).

      <.badge>Default</.badge>
      <.badge color="success" shape="pill">Paid</.badge>
      <.badge color="primary" variant="outline" icon="huge-sparkles">3 new</.badge>
      <.badge color="primary" variant="soft" dot>Online</.badge>
      <.badge on_remove={JS.hide()}>Filter</.badge>

  With `canvas` the badge is the compact canvas badge (tinted by `color`: `primary`, `success`,
  `error`, `warning`, `info`, `lime`; `variant` `solid`/`outline`; `size` `sm`/`lg`), which is what tables
  and KPI rows use.
  """
  use LedgerUI.Component

  @variants %{
    "solid" => "border-transparent bg-(--c) text-(--c-on)",
    "glow" =>
      "border-transparent bg-(--c) text-(--c-on) shadow-[0_0_0_3px_color-mix(in_oklab,var(--c)_18%,transparent),0_4px_12px_-3px_color-mix(in_oklab,var(--c)_55%,transparent)]",
    "soft" => "border-transparent bg-(--c-soft) text-(--c-ink)",
    "outline" =>
      "border-solid text-(--c-ink) border-[color-mix(in_oklab,var(--c)_50%,transparent)]",
    "flat" =>
      "border-transparent bg-[color-mix(in_oklab,var(--c)_9%,transparent)] text-(--c-ink)",
    "bordered" =>
      "bg-(--c-soft) text-(--c-ink) border-[color-mix(in_oklab,var(--c)_35%,transparent)]"
  }

  @sizes %{
    "xs" => "h-4 px-[5px] text-[10.5px]",
    "sm" => "h-[19px] px-1.5 text-[11px]",
    "md" => "h-[22px] px-2 text-xs",
    "lg" => "h-[26px] px-2.5 text-[13px]",
    "xl" => "h-[30px] px-3 text-sm"
  }

  @shapes %{"rounded" => "rounded-sm", "pill" => "rounded-full", "square" => "rounded-[2px]"}

  # The icon is 13px. The original `lu-bd` has no icon rule (only the canvas `lu-badge` does): the
  # 13px of the design is kept for both, and the parity case `badge-icon` adds that rule to the original.
  @base "inline-flex items-center gap-[5px] font-medium leading-none whitespace-nowrap [&_svg]:size-[13px]"

  # --- the compact canvas badge: tone (a `color`) x look (`soft`, `solid`, `outline`)
  @canvas_tones %{
    "neutral" => "bg-sunken text-ink-2",
    "primary" => "bg-accent-soft text-accent-content",
    "success" => "bg-pos-soft text-pos",
    "error" => "bg-neg-soft text-neg",
    "warning" => "bg-warn-soft text-warn",
    "info" => "bg-info-soft text-info",
    "lime" => "bg-lime-soft text-lime"
  }

  @canvas_outline_text %{
    "neutral" => "text-ink-2",
    "primary" => "text-accent-content",
    "success" => "text-pos",
    "error" => "text-neg",
    "warning" => "text-warn",
    "info" => "text-info",
    "lime" => "text-lime"
  }

  @canvas_outline %{
    "warning" =>
      "shadow-[inset_0_0_0_1px_color-mix(in_oklab,var(--lu-warn)_55%,transparent)] bg-[color-mix(in_oklab,var(--lu-warn)_10%,transparent)]",
    "success" =>
      "shadow-[inset_0_0_0_1px_color-mix(in_oklab,var(--lu-pos)_50%,transparent)] bg-[color-mix(in_oklab,var(--lu-pos)_9%,transparent)]",
    "primary" =>
      "shadow-[inset_0_0_0_1px_color-mix(in_oklab,var(--lu-accent-500)_55%,transparent)] bg-[color-mix(in_oklab,var(--lu-accent-500)_10%,transparent)]",
    "error" =>
      "shadow-[inset_0_0_0_1px_color-mix(in_oklab,var(--lu-neg)_55%,transparent)] bg-[color-mix(in_oklab,var(--lu-neg)_10%,transparent)]"
  }

  @canvas_sizes %{
    "sm" => "h-[18px] px-1.5 text-[11px]",
    "lg" => "h-[26px] px-2.5 text-[13px]"
  }

  attr :color, :string, default: "neutral", values: LedgerUI.Color.names()
  attr :variant, :string, default: "soft", values: Map.keys(@variants)
  attr :size, :string, default: "md", values: Map.keys(@sizes)
  attr :shape, :string, default: "rounded", values: Map.keys(@shapes)
  attr :icon, :string, default: nil, doc: "An icon name before the content."
  attr :dot, :any, default: false, doc: ~s(A dot before the content; `"live"` pulses.)
  attr :canvas, :boolean, default: false, doc: "The compact canvas badge."

  attr :on_remove, :any,
    default: nil,
    doc: "An event name or a `JS` command: adds a remove button after the content."

  attr :id, :string, default: nil
  attr :target, :any, default: nil, doc: "The `phx-target` of `on_remove` when it is an event."
  attr :remove_label, :string, default: "Remove"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def badge(assigns) do
    assigns = assign(assigns, :cls, classes(assigns))

    ~H"""
    <span id={@id} data-part="badge" class={[@cls, @class]} {@rest}><.dot
      :if={@dot}
      live={@dot == "live"}
    /><.icon :if={@icon} name={@icon} />{render_slot(@inner_block)}<.remove_button
      :if={@on_remove}
      on_remove={@on_remove}
      target={@target}
      id={@id}
      label={@remove_label}
    /></span>
    """
  end

  defp classes(%{canvas: true} = a) do
    [
      @base,
      "rounded-sm tabular-nums",
      @canvas_sizes[a.size] || @canvas_sizes["md"] || "h-[22px] px-2 text-xs",
      canvas_look(a.variant, a.color)
    ]
  end

  defp classes(a) do
    [
      @base,
      "border",
      LedgerUI.Color.vars(a.color),
      @variants[a.variant],
      @sizes[a.size],
      @shapes[a.shape]
    ]
  end

  defp canvas_look("solid", _), do: "bg-inverse text-on-inverse"

  defp canvas_look("outline", color) do
    [
      @canvas_outline_text[color] || "text-ink-2",
      @canvas_outline[color] || "bg-transparent shadow-[inset_0_0_0_1px_var(--lu-line-strong)]"
    ]
  end

  defp canvas_look(_, color), do: @canvas_tones[color] || @canvas_tones["neutral"]

  attr :live, :boolean, default: false

  defp dot(assigns) do
    ~H"""
    <span
      data-part="badge-dot"
      class={[
        "inline-block size-[7px] flex-none rounded-full",
        !@live && "bg-current",
        @live &&
          "bg-accent-500 shadow-[0_0_0_3px_color-mix(in_oklab,var(--lu-accent-500)_22%,transparent)] animate-[lu-pulse_2s_ease-in-out_infinite]"
      ]}
    ></span>
    """
  end

  attr :on_remove, :any, required: true
  attr :target, :any, default: nil
  attr :id, :string, default: nil
  attr :label, :string, required: true

  defp remove_button(assigns) do
    ~H"""
    <button
      type="button"
      data-part="badge-remove"
      class="-mr-0.5 inline-grid size-3.5 cursor-pointer place-items-center rounded-full border-0 bg-transparent p-0 text-current opacity-70 hover:opacity-100"
      aria-label={@label}
      phx-click={@on_remove}
      phx-target={@target}
      phx-value-id={@id}
    >
      <.icon name="x" size="sm" />
    </button>
    """
  end
end
