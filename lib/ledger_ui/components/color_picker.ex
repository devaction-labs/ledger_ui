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

  `popover` draws the picker on a popover surface (300px), as in the reference of the
  design; otherwise the picker has no surface of its own.
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Form
  import LedgerUI.Components.Input, only: [input: 1]

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

  # swatch size -> {swatch button, 8-column grid}; `sm` / default is the 26px swatch of the design
  @swatch "cursor-pointer rounded-[7px] border-0 shadow-[inset_0_0_0_1px_rgba(0,0,0,.08)] disabled:cursor-not-allowed"
  # the hook toggles `aria-pressed`: the ring follows the attribute
  @swatch_on "aria-pressed:shadow-[0_0_0_2px_var(--lu-bg-panel),0_0_0_4px_var(--lu-ink)]"
  @swatch_sizes %{
    "md" => {"size-[30px]", "grid-cols-[repeat(8,30px)]"},
    "lg" => {"size-[34px]", "grid-cols-[repeat(8,34px)]"}
  }
  @swatch_default {"size-[26px]", "grid-cols-[repeat(8,26px)]"}
  @thumb "absolute size-3.5 rounded-full border-2 border-white shadow-[0_0_0_1px_rgba(0,0,0,.3)]"

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
    {swatch_size, grid_8} = @swatch_sizes[assigns.swatch_size] || @swatch_default
    sized? = Map.has_key?(@swatch_sizes, assigns.swatch_size)

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
      |> assign(:swatch_cls, [@swatch, swatch_size])
      |> assign(:swatch_on, @swatch_on)
      |> assign(:grid_cls, if(sized?, do: grid_8, else: "grid-cols-[repeat(5,1fr)]"))
      |> assign(:grid_8, grid_8)
      |> assign(:thumb, @thumb)
      |> assign(:target_attr, assigns.target && to_string(assigns.target))
      |> assign(
        :root_cls,
        [
          "flex flex-col gap-3",
          assigns.popover &&
            "w-[300px] min-w-[220px] rounded-lg border border-line bg-panel p-3.5 shadow-md"
        ]
      )

    ~H"""
    <Form.field
      :if={@label || @help || @errors != []}
      as="div"
      label={@label}
      label_class={@label_class}
      help={@help}
      errors={@errors}
      class={@wrapper_class}
    >
      <.picker_body {assigns} />
    </Form.field>
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
      class={[@root_cls, @class]}
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
        <div data-part="color-picker-controls" class="flex w-full flex-col gap-2.5">
          <div
            data-part="color-picker-area"
            class="relative h-[120px] cursor-crosshair touch-none rounded-[10px]"
            role="slider"
            tabindex="0"
            aria-label={@l.color_area}
            aria-valuetext={
              @l.color_area_text
              |> String.replace("%{s}", to_string(@s))
              |> String.replace("%{v}", to_string(@v))
            }
            style={"background:linear-gradient(to top,#000,transparent),linear-gradient(to right,#fff,hsl(#{@h} 100% 50%))"}
            data-area
          >
            <i class={@thumb} style={"left:#{@s}%;top:#{100 - @v}%"}></i>
          </div>
          <div
            data-part="color-picker-hue"
            class="relative h-2.5 cursor-pointer touch-none rounded-[5px] bg-[linear-gradient(90deg,red,#ff0,lime,cyan,blue,#f0f,red)]"
            role="slider"
            tabindex="0"
            aria-label={@l.color_hue}
            aria-valuemin="0"
            aria-valuemax="360"
            aria-valuenow={@h}
            data-hue
          >
            <i
              class={[@thumb, "-top-0.5 -ml-[7px]"]}
              style={"left:#{Float.round(@h / 360 * 100, 1)}%"}
            ></i>
          </div>
          <div
            :if={@alpha}
            data-part="color-picker-alpha"
            class="relative h-2.5 cursor-pointer touch-none rounded-[5px]"
            role="slider"
            tabindex="0"
            aria-label={@l.color_alpha}
            aria-valuemin="0"
            aria-valuemax="100"
            aria-valuenow={@a}
            style={"background:linear-gradient(90deg,transparent,#{String.slice(@color, 0, 7)}),repeating-conic-gradient(#ccc 0 25%,#fff 0 50%) 0 0/8px 8px"}
            data-alpha-track
          >
            <i class={[@thumb, "-top-0.5 -ml-[7px]"]} style={"left:#{@a}%"}></i>
          </div>
        </div>
        <.input
          id={@id <> "-hex"}
          size="sm"
          prefix="#"
          value={@hex_text <> if(@alpha and @a < 100, do: String.slice(@color, 7, 2), else: "")}
          aria-label={@l.color_hex}
          disabled={@disabled}
        />
        <div
          :if={@swatches != []}
          data-part="color-picker-swatches"
          class={["grid w-full gap-1.5", @grid_cls]}
          data-lu-single
          role="group"
          aria-label={@l.color_presets}
        >
          <.swatch :for={p <- @swatches} p={p} cls={@swatch_cls} on={@swatch_on} disabled={@disabled} />
        </div>
      <% else %>
        <div
          :if={@swatches != []}
          data-part="color-picker-swatches"
          class={["grid gap-1.5", @grid_8]}
          data-lu-single
        >
          <.swatch :for={p <- @swatches} p={p} cls={@swatch_cls} on={@swatch_on} disabled={@disabled} />
        </div>
        <%= if @hex_field do %>
          <Form.field :if={@hex_label} as="label" label={@hex_label}>
            <.input
              id={@id <> "-hex"}
              size="sm"
              prefix="#"
              value={@hex_text}
              disabled={@disabled}
            />
          </Form.field>
          <.input
            :if={!@hex_label}
            id={@id <> "-hex"}
            size="sm"
            prefix="#"
            value={@hex_text}
            disabled={@disabled}
          />
        <% end %>
      <% end %>
    </div>
    """
  end

  attr :p, :map, required: true
  attr :cls, :any, required: true
  attr :on, :string, required: true
  attr :disabled, :boolean, default: false

  defp swatch(assigns) do
    ~H"""
    <button
      data-part="color-picker-swatch"
      aria-label={@p.hex}
      aria-pressed={to_string(@p.on)}
      class={[@cls, @on]}
      style={"background:" <> @p.hex}
      type="button"
      disabled={@disabled}
    ></button>
    """
  end
end
