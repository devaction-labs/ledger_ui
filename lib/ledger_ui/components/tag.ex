defmodule LedgerUI.Components.Tag do
  @moduledoc """
  Tags: clickable badges that represent an attribute, a filter or an action.

      <.tag href="#">Default</.tag>
      <.tag navigate={~p"/tags/elixir"} color="primary" shape="pill">Elixir</.tag>
      <.tag color="info" variant="bordered" shape="pill" phx-click="filter">Info</.tag>
      <.tag variant="soft" active={tag in @selected} phx-click="toggle" phx-value-tag={tag}>{tag}</.tag>

      <.tag_group>
        <.tag color="neutral">Primary</.tag>
        <.tag color="primary">55</.tag>
      </.tag_group>

  With `href`, `navigate` or `patch` a tag is a link; otherwise a button. `as="span"` (or
  `static`) renders a non-interactive `<span>`. `removable` draws the `x` of a removable tag
  (give `on_remove` to make it act). With `canvas` the tag is the canvas tag: an optional
  colour `swatch` and a remove button; `size="sm"` (24px, 12.5px, `px-2`), `label`/`value` (a
  muted label and an ink value, 500), `dashed` (dashed border) and `tone="acc"` (accent text and
  icon) cover the applied-filter tags of a report; it never wraps its line. Styled only with Tailwind utilities (the colour enters as
  `--c`/`--c-on`/`--c-soft`/`--c-ink`, see `LedgerUI.Color`).
  """
  use LedgerUI.Component

  alias LedgerUI.Color

  @base "inline-flex h-[26px] items-center gap-1.5 border border-solid px-[9px] text-[12.5px] font-medium"
  @shape %{"rounded" => "rounded-md", "pill" => "rounded-full", "square" => "rounded-[3px]"}

  @variants %{
    "solid" => LedgerUI.Variants.solid(),
    "soft" => LedgerUI.Variants.soft(),
    "bordered" =>
      "border-[color-mix(in_oklab,var(--c)_35%,transparent)] bg-(--c-soft) text-(--c-ink)",
    "outline" => "border-[color-mix(in_oklab,var(--c)_55%,transparent)] text-(--c-ink)",
    "flat" => "border-transparent bg-sunken text-(--c-ink)"
  }

  # The canvas tag, and the tag the person presses (`aria-pressed`).
  @canvas "inline-flex items-center gap-1.5 rounded-sm border border-line-strong bg-panel whitespace-nowrap aria-pressed:cursor-pointer aria-pressed:border-accent-500 aria-pressed:bg-accent-soft aria-pressed:text-accent-content"
  @canvas_sizes %{
    "md" => "h-[26px] pr-1.5 pl-[9px] text-[13px]",
    "sm" => "h-6 px-2 text-[12.5px]"
  }
  @canvas_tones %{"neutral" => "text-ink-2", "acc" => "text-accent-content"}
  @canvas_remove "grid size-[18px] cursor-pointer place-items-center rounded-[4px] border-0 bg-none p-0 text-muted hover:bg-hover hover:text-ink"
  @count "inline-grid h-[18px] min-w-[18px] place-items-center rounded-[5px] bg-neg px-[5px] text-[11px] font-semibold text-white tabular-nums"

  attr :color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary info success warning error light)

  attr :variant, :string, default: "solid", values: ~w(solid soft bordered outline flat)
  attr :tint, :string, default: nil, doc: "A CSS colour of its own; overrides `color`."
  attr :active, :boolean, default: false, doc: "Selected state of a filter chip."
  attr :count, :integer, default: nil, doc: "A small pill with this number after the label."
  attr :shape, :string, default: "rounded", values: ~w(rounded pill square)
  attr :as, :string, default: nil, values: [nil, "span"]
  attr :static, :boolean, default: false
  attr :type, :string, default: "button"
  attr :removable, :boolean, default: false, doc: "Draws the `x` of a removable tag."
  attr :on_remove, :any, default: nil, doc: "An event name or `JS` command for the `x`."
  attr :remove_label, :string, default: nil
  attr :canvas, :boolean, default: false, doc: "The canvas `lu-tag` (swatch + remove button)."
  attr :swatch, :string, default: nil, doc: "A CSS colour for the canvas tag's square."
  attr :size, :string, default: "md", values: ~w(sm md), doc: "Canvas tag: `sm` is 24px."

  attr :tone, :string,
    default: "neutral",
    values: ~w(neutral acc),
    doc: "Canvas tag: `acc` is accent text."

  attr :dashed, :boolean, default: false, doc: "Canvas tag: dashed border."
  attr :label, :string, default: nil, doc: "Canvas tag: a muted label before the value."
  attr :value, :string, default: nil, doc: "Canvas tag: the value (ink, 500) after the label."
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch method download name value disabled)
  slot :inner_block, doc: "The text (required unless a canvas tag has `label`/`value`)."

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def tag(%{canvas: true} = assigns) do
    changed0 = assigns.__changed__
    assigns = I18n.texts(assigns, remove_label: {:pt, "common.remove"})

    assigns =
      assigns
      |> assign(
        :classes,
        cx([
          @canvas,
          @canvas_sizes[assigns.size],
          @canvas_tones[assigns.tone],
          assigns.dashed && "border-dashed",
          assigns.class
        ])
      )
      |> assign(:remove_class, @canvas_remove)

    assigns =
      settle(assigns, changed0,
        classes: [:size, :tone, :dashed, :class],
        remove_class: []
      )

    ~H"""
    <span data-part="tag" class={@classes} {@rest}>
      <span
        :if={@swatch}
        data-part="tag-swatch"
        class="size-2 rounded-[2px]"
        style={"background:#{@swatch}"}
      ></span><span :if={@label} data-part="tag-label" class="text-muted">{@label}</span>
      <b :if={@value} data-part="tag-value" class="font-medium text-ink">{@value}</b>{render_slot(
        @inner_block
      )}
      <button
        :if={@removable || @on_remove}
        data-part="tag-remove"
        class={@remove_class}
        aria-label={@remove_label}
        data-lu-remove=""
        type="button"
        phx-click={@on_remove || JS.hide(to: {:closest, "[data-part=tag]"})}
      >
        <.icon name="x" size="sm" />
      </button>
    </span>
    """
  end

  def tag(assigns) do
    changed0 = assigns.__changed__
    assigns = I18n.texts(assigns, remove_label: {:pt, "common.remove"})
    # `value` is the canvas tag's value; on any other tag it is still the HTML attribute
    assigns =
      if assigns.value,
        do: assign(assigns, :rest, Map.put(assigns.rest, :value, assigns.value)),
        else: assigns

    assigns =
      assigns
      |> assign(
        :classes,
        cx([
          @base,
          !assigns.tint && Color.vars(assigns.color),
          !assigns.tint && @variants[assigns.variant],
          assigns.tint && "border-transparent",
          @shape[assigns.shape],
          assigns.class
        ])
      )
      |> assign(:attrs, tag_attrs(assigns))
      |> assign(:link?, link?(assigns.rest))
      |> assign(:span?, assigns.as == "span" or assigns.static)

    assigns =
      settle(assigns, changed0,
        rest: [:rest, :value],
        classes: [:tint, :color, :variant, :shape, :class],
        attrs: [:rest, :tint],
        link?: [:rest],
        span?: [:as, :static]
      )

    ~H"""
    <span :if={@span?} data-part="tag" class={@classes} {@attrs}>
      <.tag_body
        phx-no-format
        count={@count}
        removable={@removable}
        on_remove={@on_remove}
        remove_label={@remove_label}
      >{render_slot(@inner_block)}</.tag_body>
    </span>
    <.link
      :if={!@span? and @link?}
      data-part="tag"
      class={@classes}
      aria-pressed={@active && "true"}
      {@attrs}
    >
      <.tag_body
        phx-no-format
        count={@count}
        removable={@removable}
        on_remove={@on_remove}
        remove_label={@remove_label}
      >{render_slot(@inner_block)}</.tag_body>
    </.link>
    <button
      :if={!@span? and !@link?}
      data-part="tag"
      type={@type}
      class={@classes}
      aria-pressed={@active && "true"}
      {@attrs}
    >
      <.tag_body
        phx-no-format
        count={@count}
        removable={@removable}
        on_remove={@on_remove}
        remove_label={@remove_label}
      >{render_slot(@inner_block)}</.tag_body>
    </button>
    """
  end

  defp link?(rest), do: Enum.any?([:href, :navigate, :patch], &Map.has_key?(rest, &1))

  # `style` goes in a map: `style={nil}` would render `style=""`.
  defp tag_attrs(%{tint: tint, rest: rest}) when is_binary(tint),
    do:
      Map.put(
        rest,
        :style,
        "color:#{tint};background:color-mix(in oklab, #{tint} 14%, transparent)"
      )

  defp tag_attrs(%{rest: rest}), do: rest

  defp tag_body(assigns) do
    changed0 = assigns.__changed__
    assigns = assign(assigns, :count_class, @count)
    assigns = settle(assigns, changed0, count_class: [])

    ~H"""
    {render_slot(@inner_block)}<span :if={@count} data-part="tag-count" class={@count_class}>{@count}</span><span
      :if={@removable and !@on_remove}
      data-part="tag-remove"
      class="inline-grid opacity-60"
    ><.icon name="x" size="sm" /></span><span
      :if={@on_remove}
      data-part="tag-remove"
      class="inline-grid opacity-60"
      role="button"
      tabindex="0"
      aria-label={@remove_label}
      phx-click={@on_remove}
    ><.icon name="x" size="sm" /></span>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def tag_group(assigns) do
    changed0 = assigns.__changed__

    assigns =
      assign(assigns, :classes, cx(["inline-flex flex-wrap items-center gap-1.5", assigns.class]))

    assigns = settle(assigns, changed0, classes: [:class])

    ~H"""
    <span data-part="tag-group" class={@classes} {@rest}>{render_slot(@inner_block)}</span>
    """
  end
end
