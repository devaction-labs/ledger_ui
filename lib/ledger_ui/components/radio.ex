defmodule LedgerUI.Components.Radio.Choice do
  @moduledoc false
  # The cards, chips and tiles shared by `radio_group/1` and `checkbox_group/1`: a real
  # input (radio or checkbox) inside its label; the `on` look follows the input.
  use LedgerUI.Component

  alias LedgerUI.Components.Select.Options

  @vh "position:absolute;opacity:0;width:1px;height:1px;margin:0;pointer-events:none"
  @colors ~w(primary secondary info success warning error)

  attr :type, :string, values: ~w(radio checkbox)
  attr :variant, :string, values: ~w(card chip tile)
  attr :name, :string, default: nil
  attr :id, :string, default: nil
  attr :value, :string, default: nil
  attr :checked, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :label, :string, default: nil
  attr :description, :string, default: nil
  attr :count, :any, default: nil
  attr :icon, :string, default: nil
  attr :color, :string, default: "neutral"
  attr :control, :string, default: "start"
  attr :shape, :string, default: "circle"
  attr :aria_label, :string, default: nil
  attr :class, :any, default: nil
  attr :input_class, :any, default: nil
  attr :style, :string, default: nil
  attr :rest, :global
  slot :content

  def choice(%{variant: "card"} = assigns) do
    assigns = assign(assigns, :tone, color_class(assigns.color))

    ~H"""
    <label class={cx(["lu-choice", @control == "end" && "end", @tone, @disabled && "dis", @class])}>
      <input
        type={@type}
        class={cx(["lu-rd", @input_class])}
        {Options.style_attrs(@type == "checkbox" && "border-radius:5px")}
        id={@id}
        name={@name}
        value={@value}
        checked={@checked}
        disabled={@disabled}
        {@rest}
      />
      <.icon
        :if={@icon}
        name={@icon}
        boxed
        box_size={36}
        tone={if @checked, do: "accent"}
        box_class="lu-choice-ic"
      />
      <span class="lu-col" style="gap:2px">
        <b style="font-size:14px">
          <%= if @content != [] do %>
            {render_slot(@content)}
          <% else %>
            {@label}
          <% end %>
        </b>
        <span :if={@description} class="lu-xs lu-muted">{@description}</span>
      </span>
      <span :if={@count} class="price">{@count}</span>
    </label>
    """
  end

  def choice(%{variant: "chip"} = assigns) do
    assigns = assign(assigns, :tone, color_class(assigns.color))

    ~H"""
    <label
      class={
        cx([
          "lu-rchip",
          @shape == "pill" && "pill",
          @tone,
          @checked && "on",
          @class
        ])
      }
      {Options.style_attrs(@style)}
    >
      <input
        type={@type}
        style={vh()}
        id={@id}
        name={@name}
        value={@value}
        checked={@checked}
        disabled={@disabled}
        {@rest}
      />
      <span :if={@type == "checkbox"} data-lu-tick hidden={!@checked}>✓ </span>
      <.icon :if={@icon} name={@icon} size="sm" />
      <%= if @content != [] do %>
        {render_slot(@content)}
      <% else %>
        {@label}
      <% end %>
      <span :if={@count} class="n" style="color:var(--muted);font-variant-numeric:tabular-nums">
        {@count}
      </span>
    </label>
    """
  end

  def choice(%{variant: "tile"} = assigns) do
    assigns = assign(assigns, :tone, color_class(assigns.color))

    ~H"""
    <label
      class={cx(["lu-rtile", @tone, @checked && "on", @class])}
      {Options.style_attrs(tile_style(@style, @disabled))}
    >
      <input
        type={@type}
        style={vh()}
        id={@id}
        name={@name}
        value={@value}
        checked={@checked}
        disabled={@disabled}
        aria-label={@aria_label}
        {@rest}
      />
      <%= if @content != [] do %>
        {render_slot(@content)}
      <% else %>
        {@label}
      <% end %>
    </label>
    """
  end

  defp tile_style(style, disabled) do
    [style, disabled && "opacity:.35;cursor:not-allowed"]
    |> Enum.filter(& &1)
    |> Enum.join(";")
    |> case do
      "" -> nil
      s -> s
    end
  end

  @doc "The inline style that hides a native input but keeps it focusable."
  def vh, do: @vh

  @doc "`c-<color>` for a theme colour (nothing for `neutral`)."
  def color_class(color) when color in @colors, do: "c-" <> color
  def color_class(_), do: nil
end

defmodule LedgerUI.Components.Radio do
  @moduledoc """
  Single choice among visible options: `radio_group/1`, in six forms.

      <.radio_group field={@form[:plan]} options={[{"Free", "free"}, {"Pro", "pro"}]} color="primary" />

      <.radio_group name="basic" value="primary">
        <:radio value="default">Default</:radio>
        <:radio value="error" color="error" disabled>Error</:radio>
      </.radio_group>

      <.radio_group field={@form[:status]} variant="chip" options={[
        %{label: "Todos", value: "all", count: 128}, %{label: "Draft", value: "draft"}]} />

  `variant` is `basic`/`outline` (`lu-check` radios), `card` (`lu-choice`, with `control="end"`),
  `chip` (`lu-rchip`, `shape="pill"` for round ends), `segmented` (the look of
  `LedgerUI.Components.Segmented`, a button per option over a real radio) and `tile` (a 52px
  square with free content and an `aria_label`). Every variant keeps a real radio, so the form,
  `field` errors, the arrow keys and `phx-change` work; the `on` look follows the radio (hooks
  `LedgerUI.ChoiceGroup` and `LedgerUI.Segmented`).

  Options are `{label, value}` tuples, plain values, maps with `:label`, `:value`,
  `:description`, `:count`, `:icon`, `:color`, `:disabled`, or `:radio` slots.
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Radio.Choice
  alias LedgerUI.Components.Select.Options

  @styles %{
    "size" => %{"xs" => "s-xs", "sm" => "s-sm", "md" => "s-md", "lg" => "s-lg"},
    "shape" => %{"circle" => nil, "squircle" => "squircle", "pill" => "pill"},
    "seg_size" => %{"xs" => "sm", "sm" => "sm", "md" => nil, "lg" => "lg"}
  }
  @colors ~w(neutral primary secondary info success warning error)

  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :any, default: nil
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :options, :list, default: []
  attr :color, :string, default: "neutral", values: @colors
  attr :variant, :string, default: "basic", values: ~w(basic outline card chip segmented tile)
  attr :control, :string, default: "start", values: ~w(start end)
  attr :filled, :boolean, default: false
  attr :shape, :string, default: "circle", values: ~w(circle squircle pill)
  attr :size, :string, default: "md", values: ~w(xs sm md lg)
  attr :label, :string, default: nil
  attr :label_class, :any, default: nil
  attr :label_hint, :string, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :disabled, :boolean, default: false
  attr :wrapper_class, :any, default: nil
  attr :radio_class, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(form required)

  slot :radio do
    attr :value, :any
    attr :label, :string
    attr :color, :string
    attr :disabled, :boolean
    attr :aria_label, :string
    attr :description, :string
    attr :count, :any
    attr :icon, :string
    attr :class, :any
    attr :style, :string
    attr :checked, :boolean
    attr :shape, :string
    attr :filled, :boolean
  end

  def radio_group(assigns) do
    assigns = Options.resolve(assigns, "radio", radio_seed(assigns))
    selected = assigns.value |> Options.values() |> List.first()
    items = items(assigns)

    assigns =
      assigns
      |> assign(:items, items)
      |> assign(:selected, selected)
      |> assign(:container, container_class(assigns))
      |> assign(:hook, hook(assigns.variant))
      |> assign(:size_class, @styles["size"][assigns.size])

    ~H"""
    <Options.shell
      tag="div"
      label={@label}
      label_hint={@label_hint}
      help={@help}
      errors={@errors}
      for={@id}
      bare={true}
      class={@wrapper_class}
    >
      <div
        id={@id}
        role={@label && "radiogroup"}
        aria-labelledby={@label && @id <> "-label"}
        class={@container}
        phx-hook={@hook}
        {@rest}
      >
        {render_items(assigns)}
      </div>
    </Options.shell>
    """
  end

  # Deterministic id seed: groups that differ only by color/size/variant must not collide.
  defp radio_seed(a),
    do: {a.options, a.label, a.color, a.size, a.variant, a.control, a.filled, a.shape, a.value}

  defp render_items(%{variant: v} = assigns) when v in ["basic", "outline"] do
    ~H"""
    <label
      :for={i <- @items}
      class={
        cx([
          "lu-check",
          i.tone,
          @size_class,
          (i.shape || @shape) == "squircle" && "squircle",
          (i.filled || @filled) && "filled",
          i.disabled && "dis"
        ])
      }
      {Options.style_attrs(
        @variant == "outline" &&
          "padding:8px 12px;border:1px solid var(--line-strong);border-radius:10px"
      )}
    >
      <input
        type="radio"
        id={i.id}
        name={@name}
        value={@name && i.value}
        checked={i.checked}
        disabled={i.disabled}
        class={@radio_class}
        aria-label={i.aria_label}
      />
      <span :if={i.content != [] || i.label not in [nil, ""]} class="t">
        <%= if i.content != [] do %>
          {render_slot(i.content)}
        <% else %>
          {i.label}
        <% end %>
        <small :if={i.description}>{i.description}</small>
      </span>
    </label>
    """
  end

  defp render_items(%{variant: "segmented"} = assigns) do
    ~H"""
    <%= for i <- @items do %>
      <input
        type="radio"
        id={i.id}
        name={@name}
        value={i.value}
        checked={i.checked}
        disabled={i.disabled}
        style={Choice.vh()}
        tabindex="-1"
        aria-hidden="true"
      /><button
        type="button"
        class={i.checked && "on"}
        data-lu-value={i.value}
        aria-pressed={to_string(i.checked)}
        disabled={i.disabled}
      >{i.label}<span :if={i.count} class="n">{i.count}</span></button>
    <% end %>
    """
  end

  defp render_items(assigns) do
    ~H"""
    <Choice.choice
      :for={i <- @items}
      type="radio"
      variant={@variant}
      id={i.id}
      name={@name}
      value={i.value}
      checked={i.checked}
      disabled={i.disabled}
      label={i.label}
      description={i.description}
      count={i.count}
      icon={i.icon}
      color={i.color_name}
      control={@control}
      shape={i.shape || @shape}
      aria_label={i.aria_label}
      input_class={@radio_class}
      class={i.class}
      style={i.style}
    >
      <:content :if={i.content != []}>{render_slot(i.content)}</:content>
    </Choice.choice>
    """
  end

  defp items(assigns) do
    base = assigns.id || assigns.name || "radio"

    if assigns.radio != [] do
      assigns.radio
      |> Enum.with_index()
      |> Enum.map(fn {slot, idx} ->
        value = Options.str(slot[:value])
        color = slot[:color] || assigns.color

        item(assigns, base, idx, %{
          value: value,
          label: slot[:label],
          description: slot[:description],
          count: slot[:count],
          icon: slot[:icon],
          color: color,
          disabled: slot[:disabled] || false,
          aria_label: slot[:aria_label],
          class: slot[:class],
          style: slot[:style],
          checked: slot[:checked],
          shape: slot[:shape],
          filled: slot[:filled],
          content: slot[:inner_block] && [slot]
        })
      end)
    else
      assigns.options
      |> Options.normalize()
      |> Options.flatten()
      |> Enum.with_index()
      |> Enum.map(fn {o, idx} ->
        item(assigns, base, idx, %{
          value: o.value,
          label: o.label,
          description: o.description,
          count: o.count,
          icon: o.icon,
          color: o.color || assigns.color,
          disabled: o.disabled,
          aria_label: nil,
          class: nil,
          style: nil,
          checked: nil,
          shape: nil,
          filled: nil,
          content: []
        })
      end)
    end
  end

  defp item(assigns, base, idx, map) do
    color = to_string(map.color)

    selected = assigns.value |> Options.values() |> List.first()

    map
    |> Map.put(:checked, if(is_nil(map.checked), do: map.value == selected, else: map.checked))
    |> Map.put(:content, map.content || [])
    |> Map.put(:disabled, map.disabled || assigns.disabled)
    |> Map.put(:id, "#{base}-#{idx}")
    |> Map.put(:tone, "c-" <> color)
    |> Map.put(:color_name, color)
  end

  defp container_class(%{variant: "segmented"} = a),
    do: cx(["lu-seg", @styles["seg_size"][a.size], a.class])

  defp container_class(%{class: class}) when not is_nil(class), do: cx([class])
  defp container_class(%{variant: v}) when v in ["chip", "tile"], do: "lu-row"
  defp container_class(_), do: "lu-col"

  defp hook("segmented"), do: "LedgerUI.Segmented"
  defp hook(_), do: "LedgerUI.ChoiceGroup"

  component_alias(:radio_choice, :radio_group)

  LedgerUI.Component.__declare_like__(__MODULE__, :radio_group, __ENV__)

  attr :checked, :boolean,
    default: false,
    doc: "A lone radio (no `options`, no `<:radio>`): whether it is the chosen one."

  @doc """
  A radio, or a group of them: with `options` (or `<:radio>` slots) it is `radio_group/1`; without,
  one radio with its `label`, `color` and `size`.

      <.radio name="plan" value="pro" label="Pro" checked />
      <.radio field={@form[:plan]} options={[{"Monthly", "m"}, {"Yearly", "y"}]} />
  """
  def radio(%{options: [], radio: []} = assigns) do
    one = %{
      __slot__: :radio,
      value: assigns.value,
      label: assigns.label,
      checked: assigns.checked,
      disabled: assigns.disabled,
      inner_block: nil
    }

    radio_group(assign(assigns, radio: [one], label: nil))
  end

  def radio(assigns), do: radio_group(assigns)
end
