defmodule LedgerUI.Components.Accordion do
  @moduledoc """
  A list of sections that open under their titles (`<.accordion>` with `<.accordion_item>`).

      <.accordion id="faq" variant="bordered">
        <.accordion_item id="faq-1" title="Accordion Item 1" open>
          <p>Lorem ipsum dolor sit amet.</p>
        </.accordion_item>
        <.accordion_item id="faq-2" title="Accordion Item 2">...</.accordion_item>
      </.accordion>

      <.accordion id="help" variant="primary" color="warning">...</.accordion>

  Variants: `canvas` (default), `basic`, `border-bottom`, `bordered`, `divided`, `primary` and
  `advanced` (a `:header` of your own per item, with the chevron at its end). `color` tints the
  `primary` style. One section is open at a time; `multiple` lets them open independently.

  The browser owns which sections are open (the `LedgerUI.Collapse` hook,
  `priv/static/ledger_ui/hooks/collapse.js`); the server's `open` wins when it changes,
  `LedgerUI.open/close/toggle("faq-1")` work and `on_open` / `on_close` push `%{"id" => item_id}`
  when they are event names. The ARIA is rendered by the server: the header is a `role="button"`
  with `tabindex="0"`, `aria-expanded` and `aria-controls`, the body a `role="region"` labelled by
  the header; the hook only updates `aria-expanded`.
  """
  use LedgerUI.Component
  alias LedgerUI.Components.Modal.Support

  # What each variant does to the items (direct children). `data-state` is the item's, kept by the hook.
  @open_card "*:data-[state=open]:rounded-[12px] *:data-[state=open]:border-0 *:data-[state=open]:bg-panel *:data-[state=open]:px-3 " <>
               "*:data-[state=open]:shadow-[0_0_0_1px_var(--lu-line),var(--lu-shadow-sm)]"
  @variants %{
    "basic" => "*:border-0",
    "divided" => "*:border-b *:border-line",
    "border-bottom" => "*:border-b *:border-line",
    "bordered" => "gap-2 *:rounded-[12px] *:border *:border-line *:px-2.5",
    "canvas" => "*:mb-1.5 *:rounded-[12px] *:border-0 *:bg-sunken *:px-3",
    "advanced" => "*:border-b *:border-line " <> @open_card,
    "primary" =>
      "*:border-b *:border-line *:data-[state=open]:[&>[data-part=accordion-header]]:text-(--c-ink)"
  }
  @header "flex items-center gap-2.5 px-1 py-3 text-sm font-medium"
  @chevron "ml-auto inline-grid text-muted"
  @body "px-1 pb-3 text-[13.5px] text-muted"

  attr :id, :string, required: true

  attr :variant, :string,
    default: "canvas",
    values: ~w(advanced basic border-bottom bordered canvas divided primary)

  attr :color, :string,
    default: "primary",
    values: ~w(primary secondary info success warning error)

  attr :multiple, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global

  slot :item,
    doc: "A section, its content the body: one `accordion_item/1`, with the id `<id>-<position>`." do
    attr :title, :string
    attr :open, :boolean
    attr :id, :string
    attr :class, :any
  end

  slot :inner_block, doc: "`accordion_item/1`s, after the `<:item>`s."

  def accordion(assigns) do
    assigns =
      assigns
      |> assign(
        :cls,
        cx([
          "flex flex-col",
          @variants[assigns.variant],
          assigns.variant == "primary" && LedgerUI.Color.vars(assigns.color),
          assigns.class
        ])
      )
      |> assign(:multiple_s, Support.flag(assigns.multiple))

    ~H"""
    <div id={@id} data-part="accordion" class={@cls} data-lu-multiple={@multiple_s} {@rest}>
      <.accordion_item
        :for={{item, i} <- Enum.with_index(@item)}
        id={item[:id] || "#{@id}-#{i}"}
        title={item[:title]}
        open={item[:open] == true}
        class={item[:class]}
      >
        {render_slot(item)}
      </.accordion_item>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :id, :string, required: true
  attr :title, :string, default: nil
  attr :open, :boolean, default: false
  attr :on_open, :any, default: nil
  attr :on_close, :any, default: nil
  attr :target, :any, default: nil
  attr :toggle_label, :string, default: "Toggle"
  attr :class, :any, default: nil
  attr :trigger_class, :any, default: nil
  attr :rest, :global

  slot :header
  slot :inner_block

  def accordion_item(assigns) do
    cfg =
      Support.cfg("item",
        open: Support.flag(assigns.open),
        "on-open": Support.handler(assigns.on_open),
        "on-close": Support.handler(assigns.on_close),
        target: assigns.target
      )

    assigns =
      assigns
      |> assign(:cfg, cfg)
      |> assign(:cls, cx([assigns.open && "on", assigns.class]))
      |> assign(:hd_class, cx([@header, assigns.trigger_class]))
      |> assign(:chevron_class, @chevron)
      |> assign(:body_class, @body)
      |> assign(:state, if(assigns.open, do: "open", else: "closed"))
      |> assign(:blank?, Support.blank?(assigns.inner_block))
      |> assign(:bd_id, assigns.id <> "-bd")
      |> assign(:hd_id, assigns.id <> "-hd")
      |> assign(:expanded, Support.flag(assigns.open))
      |> assign(:ch_label, if(assigns.header != [], do: assigns.toggle_label))
      |> assign(:bd_style, if(!assigns.open, do: "display:none"))

    ~H"""
    <div
      id={@id}
      data-part="accordion-item"
      data-state={@state}
      class={@cls}
      phx-hook="LedgerUI.Collapse"
      keep-class
      keep-data-state
      {@cfg}
      {@rest}
    >
      <div
        id={@hd_id}
        data-part="accordion-header"
        class={@hd_class}
        role="button"
        tabindex="0"
        aria-expanded={@expanded}
        aria-controls={!@blank? && @bd_id}
      >
        <%= if @header == [] do %>
          {@title}
        <% else %>
          {render_slot(@header)}
        <% end %>
        <span data-part="accordion-chevron" class={@chevron_class} aria-label={@ch_label}><.icon
          name="chevron-down"
          size="sm"
        /></span>
      </div>
      <div
        :if={!@blank?}
        id={@bd_id}
        data-part="accordion-body"
        class={@body_class}
        role="region"
        aria-labelledby={@hd_id}
        {Support.st(@bd_style)}
        keep-style
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end
end
