defmodule LedgerUI.Components.NumberInput do
  @moduledoc """
  A numeric field for money and quantities that shows the number the way the person's locale
  writes it (`1.234,56` in pt-BR, `1,234.56` in en) and submits the plain machine value
  (`1234.56`).

      <.number_input field={@form[:price]} label="Price" prefix="R$" decimals={2} min={0} />
      <.number_input field={@form[:quantity]} label="Quantity" steppers min={1} step={1} suffix="un" />
      <.number_input name="qty" value={3} steppers stepper_style="round" min={0} />

  The control is the design's number box: the number is a `span[data-part=number-value]` that the `LedgerUI.NumberInput`
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

  alias LedgerUI.Components.Form

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
    if number_text?(v), do: v, else: nil
  end

  def machine(%{__struct__: _} = v), do: v |> to_string() |> machine()
  def machine(_), do: nil

  # `-?\d+(\.\d+)?` over the whole text, without the regex (it ran on every render).
  defp number_text?("-" <> rest), do: unsigned_text?(rest)
  defp number_text?(text), do: unsigned_text?(text)

  defp unsigned_text?(text) do
    case :binary.split(text, ".") do
      [int] -> digits?(int)
      [int, frac] -> digits?(int) and digits?(frac)
    end
  end

  defp digits?(""), do: false
  defp digits?(bin), do: digits_only?(bin)
  defp digits_only?(<<c, rest::binary>>) when c in ?0..?9, do: digits_only?(rest)
  defp digits_only?(""), do: true
  defp digits_only?(_), do: false

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

  @heights %{"sm" => "h-8", "md" => "h-9", "lg" => "h-10"}
  @radii %{"sm" => "rounded-md", "md" => "rounded-md", "lg" => "rounded-lg"}

  @button "grid shrink-0 cursor-pointer place-items-center text-ink-2 hover:bg-hover disabled:cursor-not-allowed disabled:opacity-40"

  defp num_class(a) do
    style = a.stepper_style
    round? = a.steppers and style == "round"

    [
      "inline-flex items-center",
      @heights[a.size],
      if(a.shape == "pill", do: "rounded-full", else: @radii[a.size]),
      if(round?, do: "gap-1.5 border-0", else: "overflow-hidden border"),
      if(a.variant == "filled", do: "border-transparent", else: "border-line-strong"),
      cond do
        a.variant == "filled" or a.disabled -> "bg-sunken"
        round? -> "bg-transparent"
        true -> "bg-panel"
      end,
      a.disabled && "text-muted",
      a.loop && "animate-[lu-numloop_6s_steps(1)_infinite]",
      a.class
    ]
  end

  defp button_class(a, which) do
    # the 28px (sm) button draws its glyph 1px right of the centre in the design
    width = if a.size == "sm", do: "w-7 pl-0.5", else: "w-[34px]"

    [
      @button,
      cond do
        a.stepper_style == "round" ->
          [
            "h-8 rounded-full border border-line-strong bg-panel",
            if(a.size == "sm", do: "w-7 pl-1", else: "w-8")
          ]

        a.stepper_style == "joined" ->
          [
            "h-full bg-sunken",
            width,
            if(which == :minus, do: "border-r border-line", else: "border-l border-line")
          ]

        true ->
          ["h-full bg-transparent", width]
      end,
      a.loop && which == :plus && "animate-[lu-press_6s_infinite]"
    ]
  end

  defp value_class(a) do
    [
      "px-2.5 text-center font-medium tabular-nums",
      cond do
        a.size == "sm" -> "min-w-14"
        a.stepper_style == "round" and a.steppers -> "min-w-11"
        true -> "min-w-[72px]"
      end,
      case a.size do
        "sm" -> "text-[13px]"
        "lg" -> "text-base"
        _ -> "text-sm"
      end,
      a.align == "right" && "flex-1 text-right",
      a.align == "left" && "flex-1 text-left",
      a.loop && "after:[counter-reset:n_var(--lu-n)] after:content-[counter(n)]"
    ]
  end

  defp addon_class(a, side) do
    [
      "flex h-full items-center bg-sunken px-2.5 text-[13.5px] text-muted",
      if(side == :left, do: "border-r border-line", else: "border-l border-line"),
      (a.steppers and a.stepper_style == "round") && "rounded-md"
    ]
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

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`: the separators and the labels. Default: the process locale, the app config, `\"pt_BR\"`."

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
    doc: "The block of the canvas app templates: a `div` with 14px icons (otherwise a `span`)."

  attr :loop, :boolean,
    default: false,
    doc:
      "Demo animation (CSS only): the number counts 1 to 5 and back while the + button is pressed. The text is drawn by a counter, so `value` is not shown."

  attr :class, :any, default: nil
  attr :rest, :global

  @doc "Renders the number input."
  def number_input(assigns) do
    changed0 = assigns.__changed__
    assigns = assigns |> Map.new() |> field_assigns()

    # With no `locale` attr the separators and labels follow the process locale (`put_locale/1`) and
    # the app config, which the assigns do not show: those values are not settled then.
    explicit_locale? = assigns.locale != nil
    assigns = Map.put(assigns, :locale, I18n.locale(assigns.locale, "pt_BR"))

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
    id = field_id(assigns, "number-input")

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
      |> assign(:label_id, assigns.label && id <> "-label")
      |> assign(:config, config_json(config))
      |> assign(:machine, machine || "")
      |> assign(:min_text, machine(assigns.min))
      |> assign(:max_text, machine(assigns.max))
      |> assign(:text, format_number(assigns.value, opts))
      |> assign(
        :minus,
        assigns.decrement_label || I18n.t("number_input.decrease", assigns.locale)
      )
      |> assign(:plus, assigns.increment_label || I18n.t("number_input.increase", assigns.locale))
      |> assign(:icon_size, if(assigns.canvas, do: "sm"))
      |> assign(:num_class, num_class(assigns))
      |> assign(:v_class, value_class(assigns))
      |> assign(:minus_class, button_class(assigns, :minus))
      |> assign(:plus_class, button_class(assigns, :plus))
      |> assign(:left_class, addon_class(assigns, :left))
      |> assign(:right_class, addon_class(assigns, :right))
      |> assign(:wrapped, assigns.label != nil or assigns.help != nil or assigns.errors != [])

    by_locale =
      if explicit_locale? do
        sep = [:decimal_separator, :thousands_separator, :locale]

        [
          config: [:min, :max, :step, :decimals, :max_decimals, :disabled] ++ sep,
          text: [:value, :field, :decimals, :max_decimals] ++ sep,
          minus: [:decrement_label, :locale],
          plus: [:increment_label, :locale]
        ]
      else
        []
      end

    assigns =
      settle(
        assigns,
        changed0,
        [
          id: [:name, :field],
          # `:label` is not a source: a new label text must not send the field again. The id only
          # matters when the label appears or goes (then `wrapped` redraws the field as well).
          label_id: [:id, :name, :field],
          machine: [:value, :field],
          min_text: [:min],
          max_text: [:max],
          icon_size: [:canvas],
          num_class: [
            :stepper_style,
            :steppers,
            :size,
            :shape,
            :variant,
            :disabled,
            :loop,
            :class
          ],
          v_class: [:size, :stepper_style, :steppers, :align, :loop],
          minus_class: [:size, :stepper_style, :loop],
          plus_class: [:size, :stepper_style, :loop],
          left_class: [:steppers, :stepper_style],
          right_class: [:steppers, :stepper_style],
          wrapped: [:label, :help, :errors, :field]
        ] ++ by_locale
      )

    ~H"""
    <Form.field
      :if={@wrapped}
      as="div"
      label={@label}
      label_class={@label_class}
      label_id={@label_id}
      help={@help}
      errors={@errors}
      class={@wrapper_class}
    >
      <.control
        canvas={@canvas}
        config={@config}
        disabled={@disabled}
        icon_size={@icon_size}
        id={@id}
        label_id={@label_id}
        left_class={@left_class}
        loop={@loop}
        machine={@machine}
        max_text={@max_text}
        min_text={@min_text}
        minus={@minus}
        minus_class={@minus_class}
        name={@name}
        num_class={@num_class}
        plus={@plus}
        plus_class={@plus_class}
        prefix={@prefix}
        rest={@rest}
        right_class={@right_class}
        steppers={@steppers}
        suffix={@suffix}
        text={@text}
        v_class={@v_class}
      />
    </Form.field>
    <.control
      :if={!@wrapped}
      canvas={@canvas}
      config={@config}
      disabled={@disabled}
      icon_size={@icon_size}
      id={@id}
      label_id={@label_id}
      left_class={@left_class}
      loop={@loop}
      machine={@machine}
      max_text={@max_text}
      min_text={@min_text}
      minus={@minus}
      minus_class={@minus_class}
      name={@name}
      num_class={@num_class}
      plus={@plus}
      plus_class={@plus_class}
      prefix={@prefix}
      rest={@rest}
      right_class={@right_class}
      steppers={@steppers}
      suffix={@suffix}
      text={@text}
      v_class={@v_class}
    />
    """
  end

  # The two roots are written out (not `<.dynamic_tag>`): the tag of a `dynamic_tag` is drawn again, in
  # full, whenever its content changes, so a new value sent the whole root each time.
  defp control(assigns) do
    ~H"""
    <div
      :if={@canvas}
      id={@id}
      data-part="number-input"
      phx-hook="LedgerUI.NumberInput"
      data-lu-config={@config}
      class={@num_class}
      {@rest}
    >
      {number_body(assigns)}
    </div>
    <span
      :if={!@canvas}
      id={@id}
      data-part="number-input"
      phx-hook="LedgerUI.NumberInput"
      data-lu-config={@config}
      class={@num_class}
      {@rest}
    >
      {number_body(assigns)}
    </span>
    """
  end

  defp number_body(assigns) do
    ~H"""
    <input
      :if={@name}
      type="hidden"
      name={@name}
      value={@machine}
      disabled={@disabled}
      data-num-value
    />
    <span :if={@prefix} data-part="number-prefix" class={@left_class}>{@prefix}</span>
    <button
      :if={@steppers}
      aria-label={@minus}
      data-part="number-minus"
      class={@minus_class}
      type="button"
    >
      <.icon name="minus" size={@icon_size} />
    </button>
    <span
      data-part="number-value"
      class={@v_class}
      role="spinbutton"
      aria-labelledby={@label_id}
      tabindex={if @disabled, do: "-1", else: "0"}
      aria-valuenow={@machine != "" && @machine}
      aria-valuemin={@min_text}
      aria-valuemax={@max_text}
      aria-disabled={@disabled && "true"}
    >{if @loop, do: "", else: @text}</span>
    <span :if={@suffix} data-part="number-suffix" class={@right_class}>{@suffix}</span>
    <button
      :if={@steppers}
      aria-label={@plus}
      data-part="number-plus"
      class={@plus_class}
      type="button"
    >
      <.icon name="plus" size={@icon_size} />
    </button>
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

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`: the separators and the labels. Default: the process locale, the app config, `\"pt_BR\"`."

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
    doc: "The block of the canvas app templates: a `div` with 14px icons (otherwise a `span`)."

  attr :loop, :boolean,
    default: false,
    doc:
      "Demo animation (CSS only): the number counts 1 to 5 and back while the + button is pressed. The text is drawn by a counter, so `value` is not shown."

  attr :class, :any, default: nil
  attr :rest, :global

  @doc "Same as `number_input/1` (same attributes and slots), under the name the design vitrine uses."
  def number_stepper(assigns), do: number_input(assigns)
end
