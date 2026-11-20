defmodule LedgerUI.Components.ColorPicker do
  @moduledoc """
  A color picker that outputs hex text: a saturation/brightness area to drag, a hue slider, an
  optional opacity slider, a hex field and a row of preset swatches.

      <.color_picker field={@form[:color]} label="Stage color" />
      <.color_picker name="tag" value="#4C3FE0" presets={~w(#EB3B2F #F5A214 #18996E)} />
      <.color_picker field={@form[:overlay]} alpha locale="pt_BR" />
      <.color_picker name="brand" variant="swatches" hex_field presets={~w(#0D8F91 #2F5FD0 #8A5CD6)} />

  The form gets `#6366F1` (upper case, `#RRGGBB`; with `alpha` a translucent color is
  `#RRGGBBAA`) through a hidden input named like the field; every change fires a bubbling
  `input` event from it, so `phx-change` runs. The behaviour lives in the `LedgerUI.ColorPicker`
  hook (`priv/static/ledger_ui/hooks/color_picker.js`), so the picker needs a stable `id`.

  `popover` draws the picker on a `lu-pop pad` surface (300px), as in the reference of the
  design; otherwise the picker has no surface of its own.
  """
  use LedgerUI.Component

  import LedgerUI.Components.DatePicker, only: [field_assigns: 1]

  @presets ~w(#4C3FE0 #2763E6 #1693CC #18996E #31A35B #F5A214 #F06B0C #EB3B2F #DB428F #606A78)

  @labels %{
    "en" => %{
      color_area: "Color area",
      color_area_text: "Saturation %{s}%, brightness %{v}%",
      color_hue: "Hue",
      color_alpha: "Opacity",
      color_hex: "Hex",
      color_presets: "Preset colors"
    },
    "pt_BR" => %{
      color_area: "Área de cor",
      color_area_text: "Saturação %{s}%, brilho %{v}%",
      color_hue: "Matiz",
      color_alpha: "Opacidade",
      color_hex: "Hex",
      color_presets: "Cores predefinidas"
    }
  }

  @sizes %{"md" => 30, "lg" => 34}

  @doc false
  # "#4c3fe0" / "4C3FE0" / "#fff" -> "#4C3FE0" (or `nil`).
  def normalize(value) when is_binary(value) do
    hex = value |> String.trim() |> String.trim_leading("#") |> String.upcase()

    cond do
      Regex.match?(~r/^[0-9A-F]{3}$/, hex) ->
        "#" <> (hex |> String.graphemes() |> Enum.map_join(&(&1 <> &1)))

      Regex.match?(~r/^([0-9A-F]{6}|[0-9A-F]{8})$/, hex) ->
        "#" <> hex

      true ->
        nil
    end
  end

  def normalize(_), do: nil

  @doc false
  # {h (0..360), s (0..100), v (0..100), a (0..100)}
  def hsv("#" <> hex) do
    <<r::binary-size(2), g::binary-size(2), b::binary-size(2), rest::binary>> = hex
    [r, g, b] = Enum.map([r, g, b], &(String.to_integer(&1, 16) / 255))
    max = Enum.max([r, g, b])
    min = Enum.min([r, g, b])
    d = max - min

    h =
      cond do
        d == 0 -> 0.0
        max == r -> 60 * (:math.fmod((g - b) / d, 6) |> fix())
        max == g -> 60 * ((b - r) / d + 2)
        true -> 60 * ((r - g) / d + 4)
      end

    s = if max == 0, do: 0.0, else: d / max
    a = if rest == "", do: 100, else: round(String.to_integer(rest, 16) / 255 * 100)
    {round(h), round(s * 100), round(max * 100), a}
  end

  defp fix(x) when x < 0, do: x + 6
  defp fix(x), do: x

  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :string
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :default, :string, default: "#4C3FE0"
  attr :label, :string, default: nil
  attr :label_class, :any, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :alpha, :boolean, default: false
  attr :presets, :list, default: @presets
  attr :swatches, :list, default: nil, doc: "The same as `presets`; it wins when given."
  attr :locale, :string, default: "en", values: ~w(en pt_BR)
  attr :labels, :map, default: %{}
  attr :variant, :string, default: "full", values: ~w(full swatches)
  attr :hex_field, :boolean, default: false
  attr :hex_label, :any, default: "Hex"
  attr :swatch_size, :string, default: nil, values: [nil, "", "sm", "md", "lg"]
  attr :popover, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :on_change, :string, default: nil
  attr :target, :any, default: nil
  attr :wrapper_class, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  @doc "Renders the color picker."
  def color_picker(assigns) do
    assigns = assigns |> Map.new() |> field_assigns()
    lang = if assigns.locale == "pt_BR", do: "pt_BR", else: "en"
    l = Map.merge(@labels[lang], assigns.labels)
    color = normalize(assigns.value) || normalize(assigns.default) || "#4C3FE0"
    {h, s, v, a} = hsv(color)
    id = assigns.id || assigns.name || "color-picker"
    size = @sizes[assigns.swatch_size]

    swatches =
      for p <- assigns.swatches || assigns.presets,
          do: %{hex: p, on: normalize(p) == String.slice(color, 0, 7)}

    assigns =
      assigns
      |> assign(:id, id)
      |> assign(:l, l)
      |> assign(:color, color)
      |> assign(:hex_text, color |> String.trim_leading("#") |> String.slice(0, 6))
      |> assign(:hsv, {h, s, v, a})
      |> assign(:swatches, swatches)
      |> assign(:grid_style, size && "grid-template-columns:repeat(8,#{size}px)")
      |> assign(
        :grid_attrs,
        if(size, do: %{style: "grid-template-columns:repeat(8,#{size}px)"}, else: %{})
      )
      |> assign(:btn_style, size && "width:#{size}px;height:#{size}px")
      |> assign(:target_attr, assigns.target && to_string(assigns.target))
      |> assign(
        :surface,
        if(assigns.popover,
          do: "lu-pop pad",
          else: nil
        )
      )
      |> assign(
        :root_style,
        if(assigns.popover,
          do: "width:300px;display:flex;flex-direction:column;gap:12px",
          else: "display:flex;flex-direction:column;gap:12px"
        )
      )

    ~H"""
    <div :if={@label || @help || @errors != []} class={cx(["lu-field", @wrapper_class])}>
      <span :if={@label} class={cx(["lu-label", @label_class])}>{@label}</span>
      <.picker_body {assigns} />
      <span :for={e <- @errors} class="lu-help err">{e}</span>
      <span :if={@help} class="lu-help">{@help}</span>
    </div>
    <.picker_body :if={!(@label || @help || @errors != [])} {assigns} />
    """
  end

  defp picker_body(assigns) do
    {h, s, v, a} = assigns.hsv

    assigns =
      assigns
      |> assign(:h, h)
      |> assign(:s, s)
      |> assign(:v, v)
      |> assign(:a, a)
      |> assign(:ph, assigns.on_change)

    ~H"""
    <div
      id={@id}
      data-part="color-picker"
      phx-hook="LedgerUI.ColorPicker"
      class={cx([@surface, @class])}
      style={@root_style}
      data-lu-on-change={@on_change}
      data-lu-target={@target_attr}
      data-lu-alpha={@alpha && @variant == "full" && ""}
      {@rest}
    >
      <input
        :if={@name}
        type="hidden"
        name={@name}
        value={@color}
        disabled={@disabled}
        data-color-value
      />
      <%= if @variant == "full" do %>
        <div class="lu-cpick" style="width:100%">
          <div
            class="sv"
            role="slider"
            tabindex="0"
            aria-label={@l.color_area}
            aria-valuetext={
              @l.color_area_text
              |> String.replace("%{s}", to_string(@s))
              |> String.replace("%{v}", to_string(@v))
            }
            style={"background:linear-gradient(to top,#000,transparent),linear-gradient(to right,#fff,hsl(#{@h} 100% 50%));touch-action:none;cursor:crosshair"}
            data-area
          >
            <i style={"animation:none;left:#{@s}%;top:#{100 - @v}%"}></i>
          </div>
          <div
            class="hue"
            role="slider"
            tabindex="0"
            aria-label={@l.color_hue}
            aria-valuemin="0"
            aria-valuemax="360"
            aria-valuenow={@h}
            style="position:relative;touch-action:none;cursor:pointer"
            data-hue
          >
            <i style={"position:absolute;top:-2px;width:14px;height:14px;margin-left:-7px;border-radius:50%;border:2px solid #fff;box-shadow:0 0 0 1px rgba(0,0,0,.3);left:#{Float.round(@h / 360 * 100, 1)}%"}></i>
          </div>
          <div
            :if={@alpha}
            class="hue"
            role="slider"
            tabindex="0"
            aria-label={@l.color_alpha}
            aria-valuemin="0"
            aria-valuemax="100"
            aria-valuenow={@a}
            style={"position:relative;touch-action:none;cursor:pointer;background:linear-gradient(90deg,transparent,#{String.slice(@color, 0, 7)}),repeating-conic-gradient(#ccc 0 25%,#fff 0 50%) 0 0/8px 8px"}
            data-alpha-track
          >
            <i style={"position:absolute;top:-2px;width:14px;height:14px;margin-left:-7px;border-radius:50%;border:2px solid #fff;box-shadow:0 0 0 1px rgba(0,0,0,.3);left:#{@a}%"}></i>
          </div>
        </div>
        <span class="lu-input sm">
          <span class="addon sep">#</span>
          <input
            id={@id <> "-hex"}
            class="mono"
            value={@hex_text <> if(@alpha and @a < 100, do: String.slice(@color, 7, 2), else: "")}
            aria-label={@l.color_hex}
            disabled={@disabled}
          />
        </span>
        <div
          :if={@swatches != []}
          class="lu-swatches"
          data-lu-single
          role="group"
          aria-label={@l.color_presets}
          style={"grid-template-columns:repeat(5,1fr);width:100%;" <> (@grid_style || "")}
        >
          <button
            :for={p <- @swatches}
            aria-label={p.hex}
            class={if p.on, do: "on", else: ""}
            style={"background:" <> p.hex <> if(@btn_style, do: ";" <> @btn_style, else: "")}
            type="button"
            disabled={@disabled}
          ></button>
        </div>
      <% else %>
        <div :if={@swatches != []} class="lu-swatches" data-lu-single {@grid_attrs}>
          <button
            :for={p <- @swatches}
            aria-label={p.hex}
            class={if p.on, do: "on", else: ""}
            style={"background:" <> p.hex <> if(@btn_style, do: ";" <> @btn_style, else: "")}
            type="button"
            disabled={@disabled}
          ></button>
        </div>
        <%= if @hex_field do %>
          <label :if={@hex_label} class="lu-field">
            <span class="lu-label">{@hex_label}</span>
            <.hex_input id={@id} text={@hex_text} disabled={@disabled} l={@l} />
          </label>
          <.hex_input :if={!@hex_label} id={@id} text={@hex_text} disabled={@disabled} l={@l} />
        <% end %>
      <% end %>
    </div>
    """
  end

  defp hex_input(assigns) do
    ~H"""
    <span class="lu-input sm">
      <span class="addon sep">#</span>
      <input id={@id <> "-hex"} class="mono" value={@text} disabled={@disabled} />
    </span>
    """
  end
end
