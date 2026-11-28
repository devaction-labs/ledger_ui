defmodule LedgerUI.Components.SignaturePad do
  @moduledoc """
  A signature field: sign with a finger, a pen or the mouse (pointer events), or type a name
  that is set in a handwriting font. The signature leaves as SVG text.

      <.signature_pad field={@form[:signature]} label="Signature" />
      <.signature_pad name="receipt" mode="type" text="Marcos Oliveira" locale="pt_BR" />
      <.signature_pad name="sign" modes={["draw"]} height={220} />

  The form gets the SVG (`<svg xmlns=... viewBox="0 0 W H"><path .../></svg>`, `""` while the pad
  is empty) through a hidden input named like the field, and every stroke, typed letter or Clear
  fires a bubbling `input` event from it. The drawing surface is client-owned
  (`phx-update="ignore"
        role="img"
        aria-label={@l.signature_area}`); the hook `LedgerUI.SignaturePad`
  (`priv/static/ledger_ui/hooks/signature_pad.js`) redraws it when the server sends another
  `value`. Show a saved signature elsewhere as an image, never as raw markup:

      <img src={"data:image/svg+xml;base64," <> Base.encode64(@signature)} alt="Signature" />

  `confirm` (a label) and `on_confirm` add a "confirm" button to the footer, as in the design.
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Form
  import LedgerUI.Components.DatePicker, only: [field_assigns: 1]
  import LedgerUI.Components.Input, only: [input: 1]
  import LedgerUI.Components.Button, only: [button: 1]

  # the surface, its dashed base line (`::after`) and what the hook draws on it (sent in the config)
  @surface "relative rounded-[12px] border border-dashed border-line-strong bg-panel " <>
             "after:absolute after:inset-x-[18px] after:bottom-[34px] after:h-px after:bg-line-strong after:content-['']"
  @classes %{
    path: "fill-none stroke-ink stroke-[2.2] [stroke-linecap:round] [stroke-linejoin:round]",
    base: "absolute inset-x-6 bottom-9 border-t border-dashed border-line-strong",
    typed:
      "absolute bottom-10 left-[22px] text-[30px] [font-family:'Brush_Script_MT','Segoe_Script',cursive]",
    status: "min-w-0 flex-1 text-xs text-muted"
  }

  # the mode tabs (a segmented control); the hook flips `aria-selected`
  @tabs "inline-flex gap-0.5 self-start rounded-md bg-sunken p-[3px]"
  @tab "inline-flex h-6 cursor-pointer items-center gap-1.5 rounded-[6px] border-0 bg-transparent px-[9px] text-[12.5px] font-medium text-muted transition-[color,background] duration-150 " <>
         "hover:text-ink aria-selected:bg-panel aria-selected:text-ink aria-selected:shadow-[var(--lu-shadow-xs),0_0_0_1px_var(--lu-line)] " <>
         "focus-visible:shadow-[0_0_0_3px_var(--lu-focus)] focus-visible:outline-none disabled:cursor-not-allowed"

  # `{viewBox, [path d]}` read out of a stored signature; never rendered as raw markup.
  defp parse_svg(value) when is_binary(value) and value != "" do
    box =
      case Regex.run(~r/viewBox="([\d.\s-]+)"/i, value) do
        [_, b] -> b
        _ -> "0 0 300 170"
      end

    paths = for [_, d] <- Regex.scan(~r/<path[^>]*?\sd="([^"]*)"/, value), do: d
    {box, paths}
  end

  defp parse_svg(_), do: {"0 0 300 170", []}

  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :string
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :label, :string, default: nil
  attr :label_class, :any, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :mode, :string, default: "draw", values: ~w(draw type)
  attr :modes, :list, default: ["draw", "type"]
  attr :text, :string, default: ""

  attr :name_input, :boolean,
    default: true,
    doc:
      "Show the field to type the name in `type` mode. `false` draws the typed `text` alone in the surface (a read-only display, as in the design's canvas)."

  attr :ink, :string, default: "#0F172A"
  attr :height, :integer, default: 170

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  attr :labels, :map, default: %{}
  attr :disabled, :boolean, default: false
  attr :variant, :string, default: "canvas", values: ~w(canvas classic)
  attr :footer, :boolean, default: true
  attr :confirm, :string, default: nil, doc: "Label of a confirm button in the footer."
  attr :on_confirm, :string, default: nil
  attr :on_change, :string, default: nil
  attr :target, :any, default: nil
  attr :wrapper_class, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  @doc "Renders the signature pad."
  def signature_pad(assigns) do
    changed0 = assigns.__changed__
    assigns = assigns |> Map.new() |> field_assigns()
    lang = I18n.locale(assigns.locale)
    l = Map.merge(I18n.labels("signature", lang), assigns.labels)
    {box, paths} = parse_svg(assigns.value)
    id = field_id(assigns, "signature-pad")
    mode = if assigns.mode in assigns.modes, do: assigns.mode, else: List.first(assigns.modes)

    assigns =
      assigns
      |> assign(:id, id)
      |> assign(:label_id, assigns.label && id <> "-label")
      |> assign(:l, l)
      |> assign(
        :config,
        Jason.encode!(%{
          mode: mode,
          modes: assigns.modes,
          ink: assigns.ink,
          variant: assigns.variant,
          onChange: assigns.on_change,
          onConfirm: assigns.on_confirm,
          target: assigns.target && to_string(assigns.target),
          disabled: assigns.disabled,
          text: assigns.text,
          classes: @classes,
          labels: Map.new(l, fn {k, v} -> {to_string(k), v} end)
        })
      )
      |> assign(:box, box)
      |> assign(:paths, paths)
      |> assign(:cur_mode, mode)
      |> assign(:signed, paths != [] or (mode == "type" and assigns.text != ""))
      |> assign(:target_attr, assigns.target && to_string(assigns.target))
      |> assign(
        :sig_attrs,
        if(assigns.height != 170, do: %{style: "height:#{assigns.height}px"}, else: %{})
      )
      |> assign(:surface, [@surface, assigns.height == 170 && "h-[140px]", assigns.class])
      |> assign(:classes, @classes)
      |> assign(:tabs_cls, @tabs)
      |> assign(:tab_cls, @tab)

    # `l` also reads the process locale when `locale` is nil: like `I18n.texts/3`, it follows the
    # `locale` attr.
    fields = [:value, :field]

    assigns =
      settle(assigns, changed0,
        l: [:locale, :labels],
        id: [:id, :name, :field],
        label_id: [:label, :id, :name, :field],
        box: fields,
        paths: fields,
        cur_mode: [:mode, :modes],
        config: [
          :cur_mode,
          :modes,
          :ink,
          :variant,
          :on_change,
          :on_confirm,
          :target,
          :disabled,
          :text,
          :l
        ],
        signed: [:text, :mode, :modes | fields],
        target_attr: [:target],
        sig_attrs: [:height],
        surface: [:height, :class],
        classes: [],
        tabs_cls: [],
        tab_cls: []
      )

    ~H"""
    <div
      id={@id}
      data-part="signature-pad"
      phx-hook="LedgerUI.SignaturePad"
      class={["flex flex-col gap-2.5", @wrapper_class]}
      data-lu-config={@config}
      role={@label_id && "group"}
      aria-labelledby={@label_id}
      {@rest}
    >
      <Form.label :if={@label} id={@label_id} class={@label_class}>{@label}</Form.label>
      <input
        :if={@name}
        type="hidden"
        name={@name}
        value={assigns[:value] || ""}
        disabled={@disabled}
        data-sig-value
      />
      <div :if={length(@modes) > 1} class={@tabs_cls} role="tablist" data-sig-modes>
        <button
          :for={m <- @modes}
          type="button"
          data-part="signature-mode"
          role="tab"
          aria-selected={to_string(m == @cur_mode)}
          class={@tab_cls}
          data-mode={m}
          disabled={@disabled}
        >
          {if m == "draw", do: @l.signature_draw, else: @l.signature_type}
        </button>
      </div>
      <div :if={"type" in @modes and @name_input} hidden={@cur_mode != "type"} data-sig-name>
        <.input
          size="sm"
          value={@text}
          placeholder={@l.signature_name}
          aria-label={@l.signature_name}
          disabled={@disabled}
        />
      </div>
      <div
        data-part="signature-surface"
        class={@surface}
        phx-update="ignore"
        id={@id <> "-pad"}
        {@sig_attrs}
      >
        <%= if @cur_mode == "type" do %>
          <span data-part="signature-typed" class={@classes.typed}>{@text}</span>
        <% else %>
          <div :if={@variant == "canvas"} data-part="signature-base" class={@classes.base}></div>
          <svg aria-hidden="true" viewBox={@box} class="absolute inset-0 size-full">
            <path :for={d <- @paths} d={d} class={@classes.path}></path>
          </svg>
        <% end %>
        <span
          :if={@variant == "canvas" and @l.signature_hint != ""}
          class="absolute bottom-3 left-6 text-xs text-muted"
        >
          {@l.signature_hint}
        </span>
      </div>
      <Form.error :for={e <- @errors}>{e}</Form.error>
      <Form.help_text :if={@help}>{@help}</Form.help_text>
      <div :if={@footer} class="flex flex-wrap items-center gap-2.5">
        <.button
          canvas
          size="sm"
          appearance="ghost"
          icon="refresh"
          data-part="signature-clear"
          disabled={@disabled}
        >{@l.signature_clear}</.button>
        <span data-part="signature-status" class={@classes.status} role="status" aria-live="polite"></span>
        <.button
          :if={@confirm}
          canvas
          size="sm"
          appearance="primary"
          icon="check"
          data-part="signature-confirm"
          disabled={@disabled}
        >{@confirm}</.button>
      </div>
    </div>
    """
  end
end
