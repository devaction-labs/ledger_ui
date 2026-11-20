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
      |> assign(:cls, cx(["lu-acc2", assigns.variant, "c-" <> assigns.color, assigns.class]))
      |> assign(:multiple_s, Support.flag(assigns.multiple))

    ~H"""
    <div id={@id} class={@cls} data-lu-multiple={@multiple_s} {@rest}>
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
      |> assign(:cls, cx(["it", assigns.open && "on", assigns.class]))
      |> assign(:hd_class, cx(["hd", assigns.trigger_class]))
      |> assign(:blank?, Support.blank?(assigns.inner_block))
      |> assign(:bd_id, assigns.id <> "-bd")
      |> assign(:hd_id, assigns.id <> "-hd")
      |> assign(:expanded, Support.flag(assigns.open))
      |> assign(:ch_label, if(assigns.header != [], do: assigns.toggle_label))
      |> assign(:bd_style, if(!assigns.open, do: "display:none"))

    ~H"""
    <div id={@id} class={@cls} phx-hook="LedgerUI.Collapse" keep-class {@cfg} {@rest}>
      <div
        id={@hd_id}
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
        <span class="ch" aria-label={@ch_label}><.icon name="chevron-down" size="sm" /></span>
      </div>
      <div
        :if={!@blank?}
        id={@bd_id}
        class="bd"
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
