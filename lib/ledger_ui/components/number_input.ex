defmodule LedgerUI.Components.NumberInput do
  @moduledoc """
  A numeric field for money and quantities that shows the number the way the person's locale
  writes it (`1.234,56` in pt-BR, `1,234.56` in en) and submits the plain machine value
  (`1234.56`).

      <.number_input field={@form[:price]} label="Price" prefix="R$" decimals={2} min={0} />
      <.number_input field={@form[:quantity]} label="Quantity" steppers min={1} step={1} suffix="un" />
      <.number_input name="qty" value={3} steppers stepper_style="round" min={0} />

  The control is the design's `lu-num`: the number is a `span.v` that the `LedgerUI.NumberInput`
  hook (`priv/static/ledger_ui/hooks/number_input.js`) makes editable (`contenteditable`,
  `role="spinbutton"`); a hidden input named like the field carries the machine value and fires a
  bubbling `input` event when it changes, so a surrounding `phx-change` runs. Typing keeps what
  the person writes; leaving the field clamps to `min`/`max`, rounds to `decimals`/`max_decimals`
  and writes it grouped. Arrow up/down (and the steppers) move by `step`, Page up/down by ten
  steps. The steppers are disabled at `min` and `max` by the hook.

  Deviations from the README: `align` defaults to `"center"` (the design's value), and the
  accessible names of the steppers default to the `locale`'s (`Diminuir`/`Aumentar` in pt-BR).
  """
  use LedgerUI.Component

  import LedgerUI.Components.DatePicker, only: [field_assigns: 1]

  @seps %{
    "pt-BR" => {".", ","},
    "pt_BR" => {".", ","},
    "en" => {",", "."}
  }

  @doc false
  # Machine text ("-1234.5") of a number, numeric string, float or Decimal; `nil` otherwise.
  def machine(nil), do: nil
  def machine(v) when is_integer(v), do: Integer.to_string(v)
  def machine(v) when is_float(v), do: :erlang.float_to_binary(v, [{:decimals, 10}, :compact])

  def machine(v) when is_binary(v) do
    v = String.trim(v)
    if Regex.match?(~r/^-?\d+(\.\d+)?$/, v), do: v, else: nil
  end

  def machine(%{__struct__: _} = v), do: v |> to_string() |> machine()
  def machine(_), do: nil

  @doc false
  # {int digits, fraction digits} rounded half up to `n` decimals.
  def round_to(machine, n) do
    {neg, int, frac} = split(machine)
    frac = String.pad_trailing(frac, n + 1, "0")
    keep = String.slice(frac, 0, n)
    up = if String.at(frac, n) >= "5", do: 1, else: 0
    total = String.to_integer(int <> keep) + up
    s = total |> Integer.to_string() |> String.pad_leading(n + 1, "0")
    len = String.length(s)
    {neg and total != 0, String.slice(s, 0, len - n), String.slice(s, len - n, n)}
  end

  defp split("-" <> rest), do: {true, elem(split(rest), 1), elem(split(rest), 2)}

  defp split(m) do
    case String.split(m, ".", parts: 2) do
      [i, f] -> {false, i, f}
      [i] -> {false, i, ""}
    end
  end

  @doc """
  Formats a number for display, as the field shows it.

      iex> LedgerUI.Components.NumberInput.format_number(1284.9, decimals: 2)
      "1.284,90"
      iex> LedgerUI.Components.NumberInput.format_number(12.5, locale: "en", max_decimals: 2)
      "12.5"
  """
  def format_number(value, opts \\ []) do
    {dec_sep, thou_sep} = separators(opts)
    decimals = opts[:decimals]
    max_decimals = opts[:max_decimals]

    case machine(value) do
      nil ->
        ""

      m ->
        {_, _int, frac} = split(m)
        places = decimals || max_decimals || String.length(frac)
        {neg, int, frac} = round_to(m, places)
        frac = if decimals, do: frac, else: String.trim_trailing(frac, "0")
        int = group(int, thou_sep)
        if(neg, do: "-", else: "") <> int <> if(frac == "", do: "", else: dec_sep <> frac)
    end
  end

  @doc false
  def separators(opts) do
    {d, t} = Map.get(@seps, opts[:locale] || "pt-BR", {".", ","}) |> then(fn {t, d} -> {d, t} end)
    {opts[:decimal_separator] || d, opts[:thousands_separator] || t}
  end

  defp group(int, ""), do: int

  defp group(int, sep) do
    int
    |> String.reverse()
    |> String.graphemes()
    |> Enum.chunk_every(3)
    |> Enum.map_join(sep, &Enum.join/1)
    |> String.reverse()
  end

  @styles %{
    "stepper_style" => %{"inset" => nil, "round" => "round", "joined" => "joined"},
    "size" => %{"sm" => "s-sm", "md" => nil, "lg" => "s-lg"}
  }

  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :any
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :label, :string, default: nil
  attr :label_class, :any, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :disabled, :boolean, default: false
  attr :locale, :string, default: "pt-BR", values: ~w(pt-BR pt_BR en)
  attr :decimal_separator, :string, default: nil
  attr :thousands_separator, :string, default: nil
  attr :decimals, :integer, default: nil
  attr :max_decimals, :integer, default: nil
  attr :min, :any, default: nil
  attr :max, :any, default: nil
  attr :step, :any, default: 1
  attr :steppers, :boolean, default: false
  attr :stepper_style, :string, default: "inset", values: ~w(inset round joined)
  attr :decrement_label, :string, default: nil
  attr :increment_label, :string, default: nil
  attr :prefix, :string, default: nil
  attr :suffix, :string, default: nil
  attr :variant, :string, default: "outlined", values: ~w(outlined filled)
  attr :size, :string, default: "md", values: ~w(sm md lg)
  attr :shape, :string, default: "rounded", values: ~w(rounded pill)
  attr :align, :string, default: "center", values: ~w(left right center)
  attr :wrapper_class, :any, default: nil

  attr :canvas, :boolean,
    default: false,
    doc:
      "The block of the canvas app templates: a `div.lu-num` whose minus button is `.minus` (otherwise a `span`)."

  attr :class, :any, default: nil
  attr :rest, :global

  @doc "Renders the number input."
  def number_input(assigns) do
    assigns = assigns |> Map.new() |> field_assigns()
    pt? = assigns.locale in ["pt-BR", "pt_BR"]

    opts =
      Map.take(assigns, [
        :locale,
        :decimals,
        :max_decimals,
        :decimal_separator,
        :thousands_separator
      ])
      |> Map.to_list()

    machine = machine(assigns.value)
    id = assigns.id || assigns.name || "number-input"

    config = %{
      min: machine(assigns.min),
      max: machine(assigns.max),
      step: machine(assigns.step) || "1",
      decimals: assigns.decimals,
      maxDecimals: assigns.max_decimals,
      dec: elem(separators(opts), 0),
      thou: elem(separators(opts), 1),
      disabled: assigns.disabled
    }

    assigns =
      assigns
      |> assign(:id, id)
      |> assign(:config, Jason.encode!(config))
      |> assign(:machine, machine || "")
      |> assign(:min_text, machine(assigns.min))
      |> assign(:max_text, machine(assigns.max))
      |> assign(:text, format_number(assigns.value, opts))
      |> assign(:minus, assigns.decrement_label || if(pt?, do: "Diminuir", else: "Decrease"))
      |> assign(:plus, assigns.increment_label || if(pt?, do: "Aumentar", else: "Increase"))
      |> assign(:icon_size, if(assigns.canvas, do: "sm"))
      |> assign(:num_class, num_class(assigns))
      |> assign(:v_class, if(assigns.align == "right", do: "v r", else: "v"))
      |> assign(
        :num_attrs,
        if(assigns.shape == "pill", do: %{style: "border-radius:999px"}, else: %{})
      )
      |> assign(
        :v_attrs,
        if(assigns.align == "left", do: %{style: "text-align:left;flex:1"}, else: %{})
      )
      |> assign(:wrapped, assigns.label != nil or assigns.help != nil or assigns.errors != [])

    ~H"""
    <div :if={@wrapped} class={cx(["lu-field", @wrapper_class])}>
      <span :if={@label} class={cx(["lu-label", @label_class])}>{@label}</span>
      <.control {assigns} />
      <span :for={e <- @errors} class="lu-help err">{e}</span>
      <span :if={@help} class="lu-help">{@help}</span>
    </div>
    <.control :if={!@wrapped} {assigns} />
    """
  end

  defp num_class(a) do
    cx([
      "lu-num",
      a.steppers and @styles["stepper_style"][a.stepper_style],
      a.variant == "filled" and "filled",
      a.disabled and "dis",
      @styles["size"][a.size],
      a.class
    ])
  end

  defp control(assigns) do
    ~H"""
    <.dynamic_tag
      tag_name={if @canvas, do: "div", else: "span"}
      id={@id}
      data-part="number-input"
      phx-hook="LedgerUI.NumberInput"
      data-lu-config={@config}
      class={@num_class}
      {@num_attrs}
      {@rest}
    >
      <input
        :if={@name}
        type="hidden"
        name={@name}
        value={@machine}
        disabled={@disabled}
        data-num-value
      />
      <span :if={@prefix} class="ad l">{@prefix}</span>
      <button :if={@steppers} aria-label={@minus} class={@canvas && "minus"} type="button">
        <.icon name="minus" size={@icon_size} />
      </button>
      <span
        class={@v_class}
        role="spinbutton"
        tabindex={if @disabled, do: "-1", else: "0"}
        aria-valuenow={@machine != "" && @machine}
        aria-valuemin={@min_text}
        aria-valuemax={@max_text}
        aria-disabled={@disabled && "true"}
        {@v_attrs}
      >{@text}</span>
      <span :if={@suffix} class="ad r">{@suffix}</span>
      <button :if={@steppers} aria-label={@plus} class="plus" type="button">
        <.icon name="plus" size={@icon_size} />
      </button>
    </.dynamic_tag>
    """
  end

  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :any
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :label, :string, default: nil
  attr :label_class, :any, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :disabled, :boolean, default: false
  attr :locale, :string, default: "pt-BR", values: ["pt-BR", "pt_BR", "en"]
  attr :decimal_separator, :string, default: nil
  attr :thousands_separator, :string, default: nil
  attr :decimals, :integer, default: nil
  attr :max_decimals, :integer, default: nil
  attr :min, :any, default: nil
  attr :max, :any, default: nil
  attr :step, :any, default: 1
  attr :steppers, :boolean, default: false
  attr :stepper_style, :string, default: "inset", values: ["inset", "round", "joined"]
  attr :decrement_label, :string, default: nil
  attr :increment_label, :string, default: nil
  attr :prefix, :string, default: nil
  attr :suffix, :string, default: nil
  attr :variant, :string, default: "outlined", values: ["outlined", "filled"]
  attr :size, :string, default: "md", values: ["sm", "md", "lg"]
  attr :shape, :string, default: "rounded", values: ["rounded", "pill"]
  attr :align, :string, default: "center", values: ["left", "right", "center"]
  attr :wrapper_class, :any, default: nil

  attr :canvas, :boolean,
    default: false,
    doc:
      "The block of the canvas app templates: a `div.lu-num` whose minus button is `.minus` (otherwise a `span`)."

  attr :class, :any, default: nil
  attr :rest, :global

  @doc "Same as `number_input/1` (same attributes and slots), under the name the design vitrine uses."
  def number_stepper(assigns), do: number_input(assigns)
end
