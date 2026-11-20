defmodule LedgerUI.Components.Badge do
  @moduledoc """
  Badges: filled, glowing, soft, outlined or bare text, with a dot, an icon or a remove button.

      <.badge>Default</.badge>
      <.badge color="success" shape="pill">Paid</.badge>
      <.badge color="primary" variant="soft" dot>Online</.badge>
      <.badge color="error" variant="outline" shape="pill">Error</.badge>
      <.badge on_remove={JS.hide()}>Filter</.badge>

  With `canvas` the badge is the compact canvas `lu-badge` (tinted by `color`:
  `primary`, `success`, `error`, `warning`, `info`, `lime`; `variant` `solid`/`outline`;
  `size` `sm`/`lg`), which is what tables and KPI rows use.

  `shape` defaults to `nil`, the rounded look of the theme; `"rounded"` adds the explicit class.
  The root `style` is rendered (empty) unless `style={false}`.
  """
  use LedgerUI.Component

  @colors ~w(neutral primary secondary info success warning error dark light white lime)
  @canvas_tone %{
    "primary" => "acc",
    "success" => "pos",
    "error" => "neg",
    "warning" => "warn",
    "info" => "info",
    "lime" => "lime"
  }
  @shape_style %{"pill" => "border-radius:999px", "square" => "border-radius:3px"}

  attr :color, :string, default: "neutral", values: @colors
  attr :variant, :string, default: "soft", values: ~w(solid glow soft outline flat)
  attr :size, :string, default: nil, values: [nil, "xs", "sm", "md", "lg", "xl"]
  attr :shape, :string, default: nil, values: [nil, "rounded", "pill", "square"]
  attr :dot, :any, default: false, doc: ~s(A dot before the content; `"live"` pulses.)
  attr :canvas, :boolean, default: false, doc: "The compact canvas `lu-badge`."

  attr :on_remove, :any,
    default: nil,
    doc: "An event name or a `JS` command: adds a remove button after the content."

  attr :id, :string, default: nil
  attr :target, :any, default: nil, doc: "The `phx-target` of `on_remove` when it is an event."
  attr :remove_label, :string, default: "Remove"
  attr :style, :any, default: nil, doc: "Inline style (`false` omits the attribute)."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def badge(%{canvas: true} = assigns) do
    assigns =
      assigns
      |> assign(
        :classes,
        cx([
          "lu-badge",
          @canvas_tone[assigns.color],
          assigns.variant in ["solid", "outline"] && assigns.variant,
          assigns.size in ["sm", "lg"] && assigns.size,
          assigns.class
        ])
      )
      |> assign(:dot_class, dot_class(assigns.dot))

    ~H"""
    <span id={@id} data-part="badge" class={@classes} {@rest}>
      <span :if={@dot} class={@dot_class}></span>{render_slot(@inner_block)}<.remove_button
        :if={@on_remove}
        on_remove={@on_remove}
        target={@target}
        id={@id}
        label={@remove_label}
      />
    </span>
    """
  end

  def badge(assigns) do
    assigns =
      assigns
      |> assign(
        :classes,
        cx([
          "lu-bd",
          "c-#{assigns.color}",
          "v-#{assigns.variant}",
          assigns.size && "s-#{assigns.size}",
          assigns.shape && "sh-#{assigns.shape}",
          assigns.class
        ])
      )
      |> assign(:dot_class, dot_class(assigns.dot))
      |> assign(:attrs, root_attrs(assigns))

    ~H"""
    <span id={@id} data-part="badge" class={@classes} {@attrs}>
      <span :if={@dot} class={@dot_class}></span>{render_slot(@inner_block)}<.remove_button
        :if={@on_remove}
        on_remove={@on_remove}
        target={@target}
        id={@id}
        label={@remove_label}
      />
    </span>
    """
  end

  # `style=""` unless the caller asks for no attribute at all (`style={false}`).
  defp root_attrs(%{style: false} = a), do: a.rest

  defp root_attrs(a),
    do: Map.put(a.rest, :style, a.style || @shape_style[a.shape] || "")

  defp dot_class("live"), do: "lu-dot live"
  defp dot_class(_), do: "lu-dot"

  attr :on_remove, :any, required: true
  attr :target, :any, default: nil
  attr :id, :string, default: nil
  attr :label, :string, required: true

  defp remove_button(assigns) do
    ~H"""
    <button
      type="button"
      class="x"
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
