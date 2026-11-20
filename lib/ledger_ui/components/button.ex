defmodule LedgerUI.Components.Button do
  @moduledoc """
  Buttons: `button/1` (filled, outlined, soft, ghost, glass, in every theme colour),
  `button_group/1` (segmented joins), `icon_button/1` (square icon-only buttons, the top bar
  buttons and the round "go" button) and `insight_button/1` (the top bar AI insights pill).

      <.button>Export report</.button>
      <.button color="primary" variant="soft" size="sm">Save</.button>
      <.button color="error" variant="outline" shape="pill">Delete</.button>
      <.button icon color="primary" variant="soft" aria-label="IA"><.icon name="sparkles" /></.button>
      <.button navigate={~p"/orders"} variant="ghost">Orders</.button>
      <.button color="primary" loading={@saving}>Saving</.button>
      <.button icon variant="outline" pip aria-label="Notifications"><.icon name="bell" /></.button>

      <.button_group shape="pill">
        <.button variant="outline" size="sm">Day</.button>
        <.button variant="outline" size="sm">Week</.button>
      </.button_group>

      <.icon_button icon="plus" label="Adicionar" variant="primary" />
      <.icon_button icon="notification-03" label="Notificações" variant="topbar" dot />

  The default `color="neutral" variant="solid"` is the black button of the system. The classes
  are `lu-b c-<color> v-<variant> s-<size> sh-<shape>` (`color="current"` has no colour class: it
  takes the parent's text colour). With `href`, `navigate` or `patch` a link is rendered that
  looks the same.

  `loading` blocks the button (no double submit) with `disabled` (links: `aria-disabled`) plus
  `aria-busy`, hides the label keeping the width and shows a spinner on top. It is not `inert`, so
  the spinner's `role="status"` is announced. The design's loading button has no `disabled`
  attribute: that is a documented parity exception. `pip` puts the notification dot on the corner
  of the button.
  """
  use LedgerUI.Component

  @styles %{
    "color" => %{
      "neutral" => "c-neutral",
      "primary" => "c-primary",
      "secondary" => "c-secondary",
      "info" => "c-info",
      "success" => "c-success",
      "warning" => "c-warning",
      "error" => "c-error",
      "white" => "c-white",
      "current" => nil,
      "mono" => "c-mono"
    },
    "variant" => %{
      "solid" => "v-solid",
      "glow" => "v-glow",
      "outline" => "v-outline",
      "soft" => "v-soft",
      "bordered" => "v-bordered",
      "flat" => "v-flat",
      "glass" => "v-glass",
      "ghost" => "v-ghost",
      "dim" => "v-dim"
    },
    "size" => %{"xs" => "s-xs", "sm" => "s-sm", "md" => "s-md", "lg" => "s-lg", "xl" => "s-xl"},
    "shape" => %{"rounded" => "sh-rounded", "pill" => "sh-pill", "square" => "sh-square"}
  }

  @link_attrs ~w(href navigate patch)a
  @pip_style "position:absolute;top:6px;right:7px;width:7px;height:7px;border-radius:50%;background:var(--neg);box-shadow:0 0 0 2px var(--bg-panel)"

  # `style={nil}` would render `style=""`: the style goes in the attribute map instead.
  defp with_style(rest, nil), do: rest
  defp with_style(rest, style), do: Map.put(rest, :style, style)

  attr :color, :string, default: "neutral", values: Map.keys(@styles["color"])
  attr :variant, :string, default: "solid", values: Map.keys(@styles["variant"])
  attr :size, :string, default: "md", values: Map.keys(@styles["size"])
  attr :shape, :string, default: "rounded", values: Map.keys(@styles["shape"])

  attr :icon, :boolean,
    default: false,
    doc: "A square button holding only an icon. Pass `aria-label`."

  attr :control, :boolean,
    default: false,
    doc: "Kept for compatibility; buttons and fields of a size share one height."

  attr :type, :string, default: "button"
  attr :disabled, :boolean, default: false

  attr :loading, :boolean,
    default: false,
    doc:
      "Disables the button (no clicks), marks it `aria-busy`, shows a spinner (announced: not `inert`)."

  attr :pip, :boolean, default: false, doc: "The notification dot on the corner."
  attr :loading_label, :string, default: "Loading", doc: "Read by screen readers for the spinner."
  attr :class, :any, default: nil
  attr :style, :string, default: nil

  attr :rest, :global,
    include: ~w(href navigate patch method download target rel replace form name value)

  slot :inner_block, required: true

  def button(assigns) do
    {disabled?, style, spinner_color} = state(assigns)

    assigns =
      assigns
      |> assign(:classes, classes(assigns))
      |> assign(:rest, with_style(assigns.rest, style))
      |> assign(:disabled_s, disabled?)
      |> assign(:spinner_style, "position:absolute;color:" <> spinner_color)
      |> assign(:pip_style, @pip_style)
      |> assign(:link?, Enum.any?(@link_attrs, &Map.has_key?(assigns.rest, &1)))

    ~H"""
    <.link
      :if={@link?}
      data-part="button"
      class={@classes}
      aria-disabled={(@disabled_s || @loading) && "true"}
      aria-busy={@loading && "true"}
      {@rest}
    >
      {render_slot(@inner_block)}
      <span
        :if={@loading}
        class="lu-sp v-border s-sm"
        style={@spinner_style}
        role="status"
        aria-label={@loading_label}
      ></span><span :if={@pip} style={@pip_style}></span>
    </.link>
    <button
      :if={!@link?}
      data-part="button"
      type={@type}
      class={@classes}
      disabled={@disabled_s || @loading}
      aria-busy={@loading && "true"}
      {@rest}
    >
      {render_slot(@inner_block)}
      <span
        :if={@loading}
        class="lu-sp v-border s-sm"
        style={@spinner_style}
        role="status"
        aria-label={@loading_label}
      ></span><span :if={@pip} style={@pip_style}></span>
    </button>
    """
  end

  defp classes(a) do
    cx([
      "lu-b",
      @styles["color"][a.color],
      @styles["variant"][a.variant],
      @styles["size"][a.size],
      if(a.icon, do: "sh-square", else: @styles["shape"][a.shape]),
      a.class
    ])
  end

  # {disabled?, style, spinner colour}
  defp state(a) do
    decls =
      [
        a.loading && "color:transparent",
        (a.loading or a.pip) && "position:relative",
        a.style
      ]
      |> Enum.filter(& &1)
      |> Enum.join(";")

    style = if decls == "", do: nil, else: decls
    {a.disabled, style, spinner_color(a)}
  end

  defp spinner_color(%{variant: v, color: c}) when v in ~w(solid glow dim) do
    if c in ~w(neutral mono), do: "var(--on-inverse)", else: "var(--c-on)"
  end

  defp spinner_color(_), do: "var(--c-ink)"

  attr :shape, :string, default: "rounded", values: ~w(rounded pill)
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "Joins buttons side by side into one segmented control."
  def button_group(assigns) do
    assigns =
      assign(
        assigns,
        :classes,
        cx(["lu-bgroup", assigns.shape == "pill" && "sh-pill", assigns.class])
      )

    ~H"""
    <div data-part="button-group" class={@classes} role="group" {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @icon_variants %{
    "default" => nil,
    "primary" => "primary",
    "soft" => "soft",
    "ghost" => "ghost",
    "danger-soft" => "danger-soft",
    "accent" => "accent"
  }

  attr :icon, :string, required: true, doc: "Icon name."
  attr :label, :string, required: true, doc: "The `aria-label` (and the only text of the button)."

  attr :variant, :string,
    default: "default",
    values: Map.keys(@icon_variants) ++ ["topbar", "go"],
    doc: "`topbar` is the 40x40 top bar button (`lu-tbtn`), `go` the round teal arrow button."

  attr :size, :string, default: "md", values: ~w(sm md lg), doc: "Square buttons only."
  attr :dot, :boolean, default: false, doc: "A red dot for something new (`topbar` only)."
  attr :type, :string, default: "button"
  attr :class, :any, default: nil
  attr :rest, :global

  @doc """
  A button that holds only an icon. Always labelled with `aria-label`.

      <.icon_button icon="download" label="Baixar" />
      <.icon_button icon="trash" label="Excluir" variant="danger-soft" size="sm" />
      <.icon_button icon="bell" label="Notificações" variant="topbar" dot />
  """
  def icon_button(%{variant: "topbar"} = assigns) do
    assigns = assign(assigns, :classes, cx(["lu-tbtn", assigns.dot && "dot", assigns.class]))

    ~H"""
    <button data-part="icon-button" type={@type} class={@classes} aria-label={@label} {@rest}><.icon name={
      @icon
    } /></button>
    """
  end

  def icon_button(%{variant: "go"} = assigns) do
    assigns = assign(assigns, :classes, cx(["lu-round-go", assigns.class]))

    ~H"""
    <button data-part="icon-button" type={@type} class={@classes} aria-label={@label} {@rest}><.icon
      name={@icon}
      size="md"
    /></button>
    """
  end

  def icon_button(assigns) do
    assigns =
      assign(
        assigns,
        :classes,
        cx([
          "lu-btn icon",
          @icon_variants[assigns.variant],
          assigns.size != "md" && assigns.size,
          assigns.class
        ])
      )

    ~H"""
    <button data-part="icon-button" type={@type} class={@classes} aria-label={@label} {@rest}><.icon name={
      @icon
    } /></button>
    """
  end

  attr :count, :any, default: nil, doc: "The number in the square badge."
  attr :type, :string, default: "button"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "The top bar pill with a count badge (`New AI insights`)."
  def insight_button(assigns) do
    assigns = assign(assigns, :classes, cx(["lu-insight-btn", assigns.class]))

    ~H"""
    <button data-part="insight-button" type={@type} class={@classes} {@rest}><span
      :if={@count}
      class="n"
    >{@count}</span>{render_slot(@inner_block)}</button>
    """
  end
end
