defmodule LedgerUI.Components.Collapse do
  @moduledoc """
  A section that opens and closes under its trigger (`<.collapse>`) and a text clamped to a few
  lines with a "show more" link (`<.collapse_text>`).

      <.collapse id="details">
        <:trigger>Shipping details</:trigger>
        <p>Ships in two days.</p>
      </.collapse>

      <.collapse id="files" open chevron="down" variant="section">
        <:trigger>My files</:trigger>
        ...
      </.collapse>

      <.collapse_text id="desc" lines={2} more="Show more" less="Show less">
        Long text...
      </.collapse_text>

  `collapse` is a native `<details>`: the trigger works with the mouse and the keyboard and the
  browser owns `open`; when the server changes `open`, the server wins. `LedgerUI.open/close/toggle("id")`
  open and close it too. `on_open` / `on_close` run on every toggle (an event name pushes
  `%{"id" => id}` to the LiveView or `target`; a `%JS{}` is run as is). The `LedgerUI.Collapse` hook
  (`priv/static/ledger_ui/hooks/collapse.js`) provides the events and the chevron's turn.

  `variant` is the design canvas section by default; `classic` (or `nil`) leaves the trigger to its
  `class`; `framed`, `flat` and `section` are the other ready-made looks.
  """
  use LedgerUI.Component
  alias LedgerUI.Components.Modal.Support

  @details_style %{
    "canvas" =>
      "border-radius:14px;box-shadow:inset 0 0 0 1px var(--line);background:var(--bg-panel)",
    "framed" => "border-radius:12px;box-shadow:inset 0 0 0 1px var(--line)",
    "flat" => "border-bottom:1px solid var(--line)"
  }
  @summary_style %{
    "canvas" =>
      "padding:14px 16px;font-size:14px;line-height:21px;font-weight:500;color:var(--ink)",
    "framed" => "padding:14px 16px;font-weight:500",
    "flat" => "padding:12px 0;font-weight:500",
    "section" =>
      "padding:8px 0;font-size:11.5px;letter-spacing:.06em;text-transform:uppercase;color:var(--muted);font-weight:500"
  }
  @panel_style %{
    "canvas" => "padding:0 16px 14px;font-size:13.5px;line-height:21px;color:var(--muted)",
    "framed" => "padding:0 16px 14px",
    "flat" => "padding:0 0 12px",
    "section" => "padding:0 0 8px"
  }
  @summary_base "list-style:none;cursor:pointer"
  @flex "display:flex;align-items:center;justify-content:space-between;gap:10px"

  attr :id, :string, required: true
  attr :open, :boolean, default: false
  attr :on_open, :any, default: nil
  attr :on_close, :any, default: nil
  attr :target, :any, default: nil
  attr :chevron, :string, default: nil, values: [nil, "", "down", "right"]

  attr :variant, :string,
    default: "canvas",
    values: [nil, "", "classic", "framed", "flat", "section", "canvas"]

  attr :panel_class, :any, default: nil
  attr :chevron_class, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  slot :trigger, required: true do
    attr :class, :any
    attr :style, :string
  end

  def collapse(assigns) do
    v = if assigns.variant in [nil, "", "classic"], do: nil, else: assigns.variant
    [trigger | _] = assigns.trigger
    chevron = assigns.chevron not in [nil, ""] && assigns.chevron

    cfg =
      Support.cfg("collapse",
        open: Support.flag(assigns.open),
        chevron: chevron || nil,
        "on-open": Support.handler(assigns.on_open),
        "on-close": Support.handler(assigns.on_close),
        target: assigns.target
      )

    assigns =
      assigns
      |> assign(:cfg, cfg)
      |> assign(:cls, Support.class(cx([assigns.class])))
      |> assign(:style_d, Support.style([v && @details_style[v], assigns.rest[:style]]))
      |> assign(:rest, Map.delete(assigns.rest, :style))
      |> assign(:summary_class, Support.class(cx([trigger[:class]])))
      |> assign(
        :summary_style,
        Support.style([
          v && @summary_base,
          v && @summary_style[v],
          chevron && @flex,
          trigger[:style]
        ])
      )
      |> assign(:chevron_name, if(chevron == "right", do: "chevron-right", else: "chevron-down"))
      |> assign(:chevron?, chevron)
      |> assign(:wrap?, v != nil or assigns.panel_class != nil)
      |> assign(:panel_class_s, cx(["ac-panel", assigns.panel_class]))
      |> assign(:panel_style, v && @panel_style[v])
      |> assign(:trigger_slot, trigger)

    ~H"""
    <details
      id={@id}
      class={@cls}
      {Support.st(@style_d)}
      open={@open}
      phx-hook="LedgerUI.Collapse"
      {@cfg}
      {@rest}
    >
      <summary class={@summary_class} {Support.st(@summary_style)}>
        {render_slot(@trigger_slot)}
        <.icon
          :if={@chevron?}
          name={@chevron_name}
          size="sm"
          class={@chevron_class}
          data-lu-chevron=""
        />
      </summary>
      <%= if @wrap? do %>
        <div class={@panel_class_s} {Support.st(@panel_style)}>{render_slot(@inner_block)}</div>
      <% else %>
        {render_slot(@inner_block)}
      <% end %>
    </details>
    """
  end

  attr :id, :string, required: true
  attr :lines, :integer, default: 2
  attr :open, :boolean, default: false
  attr :more, :string, default: "Show more"
  attr :less, :string, default: "Show less"
  attr :class, :any, default: nil
  attr :text_class, :any, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  @doc """
  A text clamped to `lines` lines, with a link under it that shows the rest and hides it again.
  Works in the browser (no event to the server); the link has `aria-expanded` and `aria-controls`.
  """
  def collapse_text(assigns) do
    clamp =
      "display:-webkit-box;-webkit-box-orient:vertical;-webkit-line-clamp:#{assigns.lines};overflow:hidden"

    cfg =
      Support.cfg("collapse-text",
        open: Support.flag(assigns.open),
        lines: assigns.lines,
        more: assigns.more,
        less: assigns.less
      )

    assigns =
      assigns
      |> assign(:cfg, cfg)
      |> assign(:text_style, if(!assigns.open, do: clamp))
      |> assign(:label, if(assigns.open, do: assigns.less, else: assigns.more))
      |> assign(:text_id, assigns.id <> "-text")

    ~H"""
    <div id={@id} class={@class} phx-hook="LedgerUI.Collapse" {@cfg} {@rest}>
      <div id={@text_id} class={@text_class} {Support.st(@text_style)} keep-style>
        {render_slot(@inner_block)}
      </div>
      <button
        type="button"
        class="lu-btn link sm"
        aria-expanded={Support.flag(@open)}
        aria-controls={@text_id}
        data-lu-more=""
      >
        {@label}
      </button>
    </div>
    """
  end
end
