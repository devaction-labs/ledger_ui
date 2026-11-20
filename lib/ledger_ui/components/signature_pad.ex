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

  import LedgerUI.Components.DatePicker, only: [field_assigns: 1]

  @labels %{
    "en" => %{
      signature_draw: "Draw",
      signature_type: "Type",
      signature_clear: "Clear",
      signature_area: "Signature area",
      signature_hint: "Sign here",
      signature_name: "Type your name",
      signature_ready: "Signed",
      signature_empty: "No signature"
    },
    "pt_BR" => %{
      signature_draw: "Desenhar",
      signature_type: "Digitar",
      signature_clear: "Limpar",
      signature_area: "Área da assinatura",
      signature_hint: "Assine aqui",
      signature_name: "Digite seu nome",
      signature_ready: "Assinado",
      signature_empty: "Sem assinatura"
    }
  }

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
  attr :ink, :string, default: "#0F172A"
  attr :height, :integer, default: 170
  attr :locale, :string, default: "en", values: ~w(en pt_BR)
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
    assigns = assigns |> Map.new() |> field_assigns()
    lang = if assigns.locale == "pt_BR", do: "pt_BR", else: "en"
    l = Map.merge(@labels[lang], assigns.labels)
    {box, paths} = parse_svg(assigns.value)
    id = assigns.id || assigns.name || "signature-pad"
    mode = if assigns.mode in assigns.modes, do: assigns.mode, else: List.first(assigns.modes)

    assigns =
      assigns
      |> assign(:id, id)
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
          labels: Map.new(l, fn {k, v} -> {to_string(k), v} end)
        })
      )
      |> assign(:box, box)
      |> assign(:paths, paths)
      |> assign(:cur_mode, mode)
      |> assign(:signed, paths != [] or (mode == "type" and assigns.text != ""))
      |> assign(:target_attr, assigns.target && to_string(assigns.target))
      |> assign(:sig_style, if(assigns.height != 170, do: "height:#{assigns.height}px"))
      |> assign(
        :sig_attrs,
        if(assigns.height != 170, do: %{style: "height:#{assigns.height}px"}, else: %{})
      )

    ~H"""
    <div
      id={@id}
      data-part="signature-pad"
      phx-hook="LedgerUI.SignaturePad"
      class={cx(["lu-col", @wrapper_class])}
      style="gap:10px"
      data-lu-config={@config}
      {@rest}
    >
      <span :if={@label} class={cx(["lu-label", @label_class])}>{@label}</span>
      <input
        :if={@name}
        type="hidden"
        name={@name}
        value={assigns[:value] || ""}
        disabled={@disabled}
        data-sig-value
      />
      <div :if={length(@modes) > 1} class="lu-seg sm" role="tablist" data-sig-modes>
        <button
          :for={m <- @modes}
          type="button"
          role="tab"
          aria-selected={to_string(m == @cur_mode)}
          class={if m == @cur_mode, do: "on", else: ""}
          data-mode={m}
          disabled={@disabled}
        >
          {if m == "draw", do: @l.signature_draw, else: @l.signature_type}
        </button>
      </div>
      <span :if={"type" in @modes} class="lu-input sm" hidden={@cur_mode != "type"} data-sig-name>
        <input
          type="text"
          value={@text}
          placeholder={@l.signature_name}
          aria-label={@l.signature_name}
          disabled={@disabled}
        />
      </span>
      <div class={cx(["lu-sig", @class])} phx-update="ignore" id={@id <> "-pad"} {@sig_attrs}>
        <%= if @cur_mode == "type" do %>
          <span class="typed">{@text}</span>
        <% else %>
          <div :if={@variant == "canvas"} class="base"></div>
          <svg aria-hidden="true" viewBox={@box}>
            <path
              :for={d <- @paths}
              d={d}
              fill="none"
              stroke="var(--ink)"
              stroke-linecap="round"
              stroke-width="2.4"
            >
            </path>
          </svg>
        <% end %>
        <span
          :if={@variant == "canvas" and @l.signature_hint != ""}
          class="lu-xs lu-muted"
          style="position:absolute;left:24px;bottom:12px"
        >
          {@l.signature_hint}
        </span>
      </div>
      <div :if={@footer} class="lu-row">
        <button class="lu-btn ghost sm" type="button" disabled={@disabled}>
          <.icon name="refresh" />{@l.signature_clear}
        </button>
        <span class="lu-grow" role="status" aria-live="polite"></span>
        <button
          :if={@confirm}
          class="lu-btn primary sm"
          type="button"
          disabled={@disabled}
        >
          <.icon name="check" />{@confirm}
        </button>
      </div>
    </div>
    """
  end
end
