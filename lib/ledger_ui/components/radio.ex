defmodule LedgerUI.Components.Radio.Choice do
  @moduledoc false
  # The cards, chips and tiles shared by `radio_group/1` and `checkbox_group/1`: a real
  # input (radio or checkbox) inside its label; the chosen look follows the input through
  # `has-checked:` utilities, so no script has to mirror it.
  use LedgerUI.Component

  alias LedgerUI.Color
  alias LedgerUI.Components.Checkbox
  alias LedgerUI.Components.Select.Options

  # the input stays focusable but invisible
  @vh "pointer-events-none absolute m-0 size-px opacity-0"
  @colors ~w(primary secondary info success warning error)

  @card "group relative flex cursor-pointer items-start gap-3 rounded-lg border border-line-strong bg-panel p-3.5 transition-[border-color,background-color] duration-150 hover:bg-hover has-checked:border-accent-500 has-checked:bg-[color-mix(in_oklab,var(--lu-accent-soft)_55%,var(--lu-bg-panel))] has-checked:shadow-[0_0_0_1px_var(--lu-accent-500)]"

  @chip "group relative inline-flex h-8 cursor-pointer items-center gap-1.5 border border-line-strong bg-panel px-3 text-[13.5px] text-ink-2 has-checked:border-(--c) has-checked:bg-(--c-soft) has-checked:text-(--c-ink) has-checked:shadow-[inset_0_0_0_1px_var(--c)]"

  @tile "group relative grid size-[52px] cursor-pointer place-items-center rounded-lg border border-line-strong bg-panel text-[15px] font-semibold text-ink-2 has-checked:border-(--c) has-checked:bg-(--c-soft) has-checked:text-(--c-ink) has-checked:shadow-[inset_0_0_0_1px_var(--c)]"

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

  slot :trailing,
    doc: "Card only: content at the right, inside the card, outside the `<label>`."

  def choice(%{variant: "card", trailing: [_ | _]} = assigns) do
    assigns =
      assigns
      |> assign(:cls, [
        @card,
        Color.vars("primary"),
        assigns.control == "end" && "[&_input]:order-3",
        assigns.disabled && "cursor-not-allowed opacity-45",
        assigns.class
      ])

    # The card is a div so the trailing content (a button, a link) never sits inside the `<label>`:
    # the label owns the text and is stretched over the whole card (`after:inset-0`), so a click
    # anywhere selects the radio; the trailing box is raised above it and only its interactive
    # children take clicks (a badge lets the click through to the label).
    ~H"""
    <div data-part="choice" class={@cls} {Options.style_attrs(@style)}>
      <input
        data-part="choice-input"
        type={@type}
        class={[
          Checkbox.input_class(
            @type,
            "md",
            if(@type == "radio", do: "circle", else: "square"),
            false,
            @disabled
          ),
          @input_class
        ]}
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
        box_class="group-has-checked:bg-accent-soft group-has-checked:text-accent-content"
      />
      <label
        for={@id}
        data-part="choice-text"
        class={[
          "flex min-w-0 flex-col gap-0.5 after:absolute after:inset-0 after:content-['']",
          !@disabled && "cursor-pointer"
        ]}
      >
        <b data-part="choice-label" class="text-sm">
          <%= if @content != [] do %>
            {render_slot(@content)}
          <% else %>
            {@label}
          <% end %>
        </b>
        <span :if={@description} data-part="choice-description" class="text-xs text-muted">
          {@description}
        </span>
      </label>
      <span
        :if={@count}
        data-part="choice-count"
        class="ml-auto font-semibold tabular-nums"
      >{@count}</span>
      <div
        data-part="choice-trailing"
        inert={@disabled}
        class={[
          "pointer-events-none relative z-10 ml-auto flex shrink-0 items-center gap-2 self-center",
          "[&_:is(a,button,input,select,textarea,summary,[tabindex])]:pointer-events-auto"
        ]}
      >
        {render_slot(@trailing)}
      </div>
    </div>
    """
  end

  def choice(%{variant: "card"} = assigns) do
    assigns =
      assigns
      |> assign(:cls, [
        @card,
        Color.vars("primary"),
        assigns.control == "end" && "[&_input]:order-3",
        assigns.disabled && "cursor-not-allowed opacity-45",
        assigns.class
      ])

    ~H"""
    <label data-part="choice" class={@cls} {Options.style_attrs(@style)}>
      <input
        data-part="choice-input"
        type={@type}
        class={[
          Checkbox.input_class(
            @type,
            "md",
            if(@type == "radio", do: "circle", else: "square"),
            false,
            @disabled
          ),
          @input_class
        ]}
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
        box_class="group-has-checked:bg-accent-soft group-has-checked:text-accent-content"
      />
      <span data-part="choice-text" class="flex flex-col gap-0.5">
        <b data-part="choice-label" class="text-sm">
          <%= if @content != [] do %>
            {render_slot(@content)}
          <% else %>
            {@label}
          <% end %>
        </b>
        <span :if={@description} data-part="choice-description" class="text-xs text-muted">
          {@description}
        </span>
      </span>
      <span
        :if={@count}
        data-part="choice-count"
        class="ml-auto font-semibold tabular-nums"
      >{@count}</span>
    </label>
    """
  end

  def choice(%{variant: "chip"} = assigns) do
    assigns =
      assigns
      |> assign(:cls, [
        @chip,
        color_vars(assigns.color),
        if(assigns.shape == "pill", do: "rounded-full", else: "rounded-md"),
        assigns.disabled && "cursor-not-allowed opacity-45",
        assigns.class
      ])
      |> assign(:vh, @vh)

    ~H"""
    <label data-part="choice" class={@cls} {Options.style_attrs(@style)}>
      <input
        data-part="choice-input"
        type={@type}
        class={@vh}
        id={@id}
        name={@name}
        value={@value}
        checked={@checked}
        disabled={@disabled}
        {@rest}
      />
      <span
        :if={@type == "checkbox"}
        data-part="choice-tick"
        class="hidden group-has-checked:inline"
      >✓ </span>
      <.icon :if={@icon} name={@icon} size="sm" />
      <%= if @content != [] do %>
        {render_slot(@content)}
      <% else %>
        {@label}
      <% end %>
      <span :if={@count} data-part="choice-count" class="text-muted tabular-nums">
        {@count}
      </span>
    </label>
    """
  end

  def choice(%{variant: "tile"} = assigns) do
    assigns =
      assigns
      |> assign(:cls, [
        @tile,
        color_vars(assigns.color),
        assigns.disabled && "cursor-not-allowed opacity-35",
        assigns.class
      ])
      |> assign(:vh, @vh)

    ~H"""
    <label data-part="choice" class={@cls} {Options.style_attrs(@style)}>
      <input
        data-part="choice-input"
        type={@type}
        class={@vh}
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

  @doc "The utilities that hide a native input but keep it focusable."
  def vh, do: @vh

  @doc "The `--c*` variables of a theme colour (`neutral` is the accent, as in the design)."
  def color_vars(color) when color in @colors, do: Color.vars(color)
  def color_vars(_), do: Color.vars("primary")
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

  `variant` is `basic`/`outline` (the round radio of `checkbox/1`), `card` (with `control="end"`),
  `chip` (`shape="pill"` for round ends), `segmented` (the look of
  `LedgerUI.Components.Segmented`, a button per option over a real radio) and `tile` (a 52px
  square with free content and an `aria_label`). Every variant keeps a real radio, so the form,
  `field` errors, the arrow keys and `phx-change` work; the chosen look follows the radio
  (`has-checked:` utilities, and the `LedgerUI.Segmented` hook for `segmented`).

  `card` takes `<:trailing :let={opt}>`: content at the right, inside the card (a badge, a button), given
  each option. The card then is a `div` (the radio, a `<label for>` stretched over the card and the trailing
  box), so a button there never sits inside a `<label>`: it takes its own click and does not select
  the radio, while a click on the card or on a non-interactive trailing selects it. A disabled option
  makes the whole card, trailing included, inert.

      <.radio_group field={@form[:signer]} variant="card" options={@signers}>
        <:trailing :let={opt}>
          <.button :if={opt.value == "ana"} size="sm" variant="outline">Enviar certificado</.button>
        </:trailing>
      </.radio_group>

  Options are `{label, value}` tuples, plain values, maps with `:label`, `:value`,
  `:description`, `:count`, `:icon`, `:color`, `:disabled`, or `:radio` slots.
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Checkbox
  alias LedgerUI.Components.Radio.Choice
  alias LedgerUI.Components.Segmented
  alias LedgerUI.Components.Select.Options

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

  slot :trailing,
    doc: "`card` only: content at the right of each card; receives the option (`:let={opt}`)."

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
        data-part="radio-group"
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
      data-part="radio"
      class={[
        Checkbox.label_class(@size, i.disabled),
        Checkbox.color_vars(i.color_name),
        @variant == "outline" && Checkbox.outline_class()
      ]}
    >
      <input
        data-part="radio-input"
        type="radio"
        id={i.id}
        name={@name}
        value={@name && i.value}
        checked={i.checked}
        disabled={i.disabled}
        class={[
          Checkbox.input_class(
            "radio",
            @size,
            i.shape || @shape,
            i.filled || @filled,
            i.disabled
          ),
          @radio_class
        ]}
        aria-label={i.aria_label}
      />
      <span
        :if={i.content != [] || i.label not in [nil, ""]}
        data-part="radio-text"
        class={Checkbox.text_class()}
      >
        <%= if i.content != [] do %>
          {render_slot(i.content)}
        <% else %>
          {i.label}
        <% end %>
        <small :if={i.description} data-part="radio-description" class={Checkbox.description_class()}>{i.description}</small>
      </span>
    </label>
    """
  end

  defp render_items(%{variant: "segmented"} = assigns) do
    assigns =
      assign(
        assigns,
        :btn_class,
        Segmented.button_class(
          if(assigns.size in ~w(xs sm), do: "sm", else: "md"),
          false,
          false,
          false
        )
      )

    ~H"""
    <%= for i <- @items do %>
      <input
        data-part="radio-input"
        type="radio"
        id={i.id}
        name={@name}
        value={i.value}
        checked={i.checked}
        disabled={i.disabled}
        class={Choice.vh()}
        tabindex="-1"
        aria-hidden="true"
      /><button
        type="button"
        data-part="segmented-item"
        class={@btn_class}
        data-lu-value={i.value}
        aria-pressed={to_string(i.checked)}
        disabled={i.disabled}
      >{i.label}<span :if={i.count} data-part="segmented-count" class={Segmented.count_class()}>{i.count}</span></button>
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
      <:trailing :if={@trailing != [] and @variant == "card"}>
        {render_slot(@trailing, i)}
      </:trailing>
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
    |> Map.put(:color_name, color)
  end

  defp container_class(%{variant: "segmented"} = a),
    do: [Segmented.track_class(false, false, false), a.class]

  defp container_class(%{class: class}) when not is_nil(class), do: class

  defp container_class(%{variant: v}) when v in ["chip", "tile"],
    do: "flex flex-wrap items-center gap-2.5"

  defp container_class(_), do: "flex flex-col gap-2.5"

  defp hook("segmented"), do: "LedgerUI.Segmented"
  defp hook(_), do: nil

  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :any, default: nil
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :options, :list, default: []

  attr :color, :string,
    default: "neutral",
    values: ["neutral", "primary", "secondary", "info", "success", "warning", "error"]

  attr :variant, :string,
    default: "basic",
    values: ["basic", "outline", "card", "chip", "segmented", "tile"]

  attr :control, :string, default: "start", values: ["start", "end"]
  attr :filled, :boolean, default: false
  attr :shape, :string, default: "circle", values: ["circle", "squircle", "pill"]
  attr :size, :string, default: "md", values: ["xs", "sm", "md", "lg"]
  attr :label, :string, default: nil
  attr :label_class, :any, default: nil
  attr :label_hint, :string, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :disabled, :boolean, default: false
  attr :wrapper_class, :any, default: nil
  attr :radio_class, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ["form", "required"]

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

  slot :trailing,
    doc: "`card` only: content at the right of each card; receives the option (`:let={opt}`)."

  @doc "Same as `radio_group/1` (same attributes and slots), under the name the design vitrine uses."
  def radio_choice(assigns), do: radio_group(assigns)

  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :any, default: nil
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :options, :list, default: []

  attr :color, :string,
    default: "neutral",
    values: ["neutral", "primary", "secondary", "info", "success", "warning", "error"]

  attr :variant, :string,
    default: "basic",
    values: ["basic", "outline", "card", "chip", "segmented", "tile"]

  attr :control, :string, default: "start", values: ["start", "end"]
  attr :filled, :boolean, default: false
  attr :shape, :string, default: "circle", values: ["circle", "squircle", "pill"]
  attr :size, :string, default: "md", values: ["xs", "sm", "md", "lg"]
  attr :label, :string, default: nil
  attr :label_class, :any, default: nil
  attr :label_hint, :string, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :disabled, :boolean, default: false
  attr :wrapper_class, :any, default: nil
  attr :radio_class, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ["form", "required"]

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

  slot :trailing,
    doc: "`card` only: content at the right of each card; receives the option (`:let={opt}`)."

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
