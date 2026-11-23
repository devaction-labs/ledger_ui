defmodule LedgerUI.Components.Checkbox do
  @moduledoc """
  `checkbox/1` (the box with label and description) and `checkbox_group/1` (one
  checkbox per option of a list field).

      <.checkbox name="terms" label="I agree" />
      <.checkbox field={@form[:remember]} label="Remember me" color="primary" />
      <.checkbox name="pro" label="Pro plan" description="Billed yearly" color="primary" checked />
      <.checkbox name="all" label="Select all (3 of 8)" indeterminate />

      <.checkbox_group field={@form[:roles]} label="Roles"
        options={[{"Admin", "admin"}, {"Editor", "editor"}]} />
      <.checkbox_group field={@form[:channels]} variant="chip" color="primary" options={[
        %{label: "E-mail", value: "email", count: 3}, %{label: "WhatsApp", value: "whatsapp"}]} />

  Inside a form a named checkbox sends `unchecked_value` through a hidden input when it is off
  (`hidden_input={false}` skips it), so the field is always in the params. `indeterminate`
  draws the dash of a partial selection (`data-ind`); the `indeterminate` property and
  `aria-checked="mixed"` are set by the `LedgerUI.Indeterminate` hook
  (`priv/static/ledger_ui/hooks/indeterminate.js`), so the box needs an `id`: it is taken from
  `id`, the field, the name or the label. Pass `false` when the box can leave that state; a
  click clears the dash.

  Extra HTML attributes (`form`, `required`, `phx-click`, `data-*`...) go to the `<input>`.
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Radio.Choice
  alias LedgerUI.Components.Select.Options

  alias LedgerUI.Color
  alias LedgerUI.Components.Form

  # box size, radius, radio ring, tick and the text size of each `size`
  @sizes %{
    "xs" => %{
      box: "size-3.5",
      r: "rounded-[4px]",
      ring: "checked:border-4",
      tick: "checked:after:h-1.5 checked:after:w-[9px]",
      text: "text-[13px]"
    },
    "sm" => %{
      box: "size-4",
      r: "rounded-[4px]",
      ring: "checked:border-[5px]",
      tick: "checked:after:h-[6.5px] checked:after:w-2.5",
      text: "text-[13px]"
    },
    "md" => %{
      box: "size-[18px]",
      r: "rounded-[4px]",
      ring: "checked:border-[5px]",
      tick: "checked:after:h-[7px] checked:after:w-[11px]",
      text: "text-sm"
    },
    "lg" => %{
      box: "size-[22px]",
      r: "rounded-[4px]",
      ring: "checked:border-[6px]",
      tick: "checked:after:h-2 checked:after:w-[13px]",
      text: "text-[15px]"
    }
  }

  @box "m-0 mt-px grid shrink-0 appearance-none place-items-center border-[1.5px] transition-[background-color,border-color] duration-[120ms] focus-visible:border-accent-500 focus-visible:shadow-[0_0_0_3px_var(--lu-focus)] focus-visible:outline-none"

  @tick "checked:after:content-[''] checked:after:border-2 checked:after:border-t-0 checked:after:border-r-0 checked:after:border-(--c-on) checked:after:[transform:rotate(-45deg)_translate(1px,-1px)]"

  # the dash of a partial selection: the property (set by the hook) or `aria-checked="mixed"`
  @dash [
    "indeterminate:relative indeterminate:border-(--c) indeterminate:bg-(--c) indeterminate:after:absolute indeterminate:after:top-1/2 indeterminate:after:left-1/2 indeterminate:after:h-0.5 indeterminate:after:w-2 indeterminate:after:-translate-1/2 indeterminate:after:rounded-[1px] indeterminate:after:bg-(--c-on) indeterminate:after:content-['']",
    "aria-[checked=mixed]:relative aria-[checked=mixed]:border-(--c) aria-[checked=mixed]:bg-(--c) aria-[checked=mixed]:after:absolute aria-[checked=mixed]:after:top-1/2 aria-[checked=mixed]:after:left-1/2 aria-[checked=mixed]:after:h-0.5 aria-[checked=mixed]:after:w-2 aria-[checked=mixed]:after:-translate-1/2 aria-[checked=mixed]:after:rounded-[1px] aria-[checked=mixed]:after:bg-(--c-on) aria-[checked=mixed]:after:content-['']"
  ]

  @colors ~w(neutral primary secondary info success warning error)

  # `loop`: the box fills and the tick draws by itself (the tick is an unchecked `::after` scaled to 0)
  @loop "animate-[lu-cbbox_3.6s_ease-in-out_infinite] after:h-[5px] after:w-[9px] after:animate-[lu-cbtick_3.6s_ease-in-out_infinite] after:border-2 after:border-t-0 after:border-r-0 after:border-(--c-on) after:[transform:rotate(-45deg)_translate(1px,-1px)_scale(0)] after:content-['']"

  @doc false
  # The class list of the native `<input>` of a checkbox or radio (the box). One utility per
  # CSS property; the checked look is a `checked:` variant (higher specificity than the base).
  def input_class(type, size, shape, filled, disabled, loop \\ false) do
    s = @sizes[size || "md"]
    radio? = type == "radio"

    radius =
      cond do
        shape in ["circle", "pill"] -> "rounded-full"
        radio? and shape == "squircle" -> "rounded-[6px]"
        radio? -> "rounded-full"
        true -> s.r
      end

    surface =
      cond do
        filled and not disabled ->
          "cursor-pointer border-[color-mix(in_oklab,var(--c)_30%,var(--lu-line-strong))] bg-(--c-soft)"

        disabled ->
          "border-line bg-sunken cursor-not-allowed opacity-50"

        true ->
          "cursor-pointer border-[color-mix(in_oklab,var(--lu-line-strong),var(--lu-muted)_30%)] bg-panel hover:border-muted"
      end

    [
      @box,
      s.box,
      radius,
      surface,
      if(radio?,
        do: ["checked:border-(--c) checked:bg-panel", s.ring],
        else: ["checked:border-(--c) checked:bg-(--c)", @tick, s.tick, @dash, loop && @loop]
      )
    ]
  end

  @doc false
  def label_class(size, disabled) do
    [
      "inline-flex items-start gap-2.5",
      @sizes[size || "md"].text,
      if(disabled, do: "cursor-not-allowed text-muted", else: "cursor-pointer text-ink")
    ]
  end

  @doc false
  def color_vars(color) when color in @colors, do: Color.vars(color)
  def color_vars(_), do: Color.vars("primary")

  @doc false
  def text_class, do: "flex flex-col gap-0.5"

  @doc false
  def description_class, do: "text-[13px] leading-[18px] text-muted"

  @doc false
  def outline_class, do: "rounded-md border border-line-strong px-3 py-2"

  attr :field, Phoenix.HTML.FormField, default: nil
  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :any, default: nil
  attr :checked, :boolean, default: nil
  attr :indeterminate, :boolean, default: nil
  attr :checked_value, :string, default: "true"
  attr :unchecked_value, :string, default: "false"
  attr :hidden_input, :boolean, default: true
  attr :color, :string, default: "primary", values: @colors
  attr :variant, :string, default: "basic", values: ~w(basic outline)
  attr :filled, :boolean, default: false
  attr :shape, :string, default: "square", values: ~w(square circle)
  attr :size, :string, default: "md", values: [nil, "xs", "sm", "md", "lg"]
  attr :label, :string, default: nil
  attr :label_class, :any, default: nil
  attr :description, :string, default: nil
  attr :errors, :list, default: []
  attr :disabled, :boolean, default: false

  attr :loop, :boolean,
    default: false,
    doc: "Demo animation (CSS only): the box fills and the tick draws by itself."

  attr :wrapper_class, :any, default: nil, doc: "Classes of the block that wraps box and errors."
  attr :class, :any, default: nil, doc: "Classes of the label (the clickable row)."

  attr :style, :string,
    default: nil,
    doc: "Inline style of the label, not of the input."

  attr :rest, :global, include: ~w(form required autofocus)
  slot :inner_block

  def checkbox(assigns) do
    {assigns, id} = Options.resolve_field(assigns)
    checked = Options.checked?(assigns)

    assigns =
      assigns
      |> assign(:input_id, id)
      |> assign(:is_checked, checked)
      |> assign(
        :hook_id,
        assigns.indeterminate != nil &&
          (id || assigns.name || "cb-#{:erlang.phash2({assigns.label, assigns.description})}")
      )
      |> assign(:label_cls, [
        label_class(assigns.size, assigns.disabled),
        color_vars(assigns.color),
        assigns.variant == "outline" && outline_class(),
        assigns.class
      ])
      |> assign(
        :input_cls,
        input_class(
          "checkbox",
          assigns.size,
          assigns.shape,
          assigns.filled,
          assigns.disabled,
          assigns.loop
        )
      )

    ~H"""
    <Form.field
      bare
      as="div"
      errors={@errors}
      class={@wrapper_class}
    >
      {checkbox_label(assigns)}
    </Form.field>
    """
  end

  defp checkbox_label(assigns) do
    ~H"""
    <label data-part="checkbox" class={@label_cls} {Options.style_attrs(@style)}>
      <input
        :if={@name && @hidden_input}
        type="hidden"
        name={@name}
        value={@unchecked_value}
        disabled={@disabled}
      />
      <input
        data-part="checkbox-input"
        type="checkbox"
        id={@hook_id || @input_id}
        name={@name}
        value={@name && @checked_value}
        checked={@is_checked}
        disabled={@disabled}
        class={@input_cls}
        data-ind={@indeterminate && "1"}
        aria-checked={@indeterminate && "mixed"}
        phx-hook={@hook_id && "LedgerUI.Indeterminate"}
        {@rest}
      />
      <span
        :if={@inner_block != [] || @label || @description}
        data-part="checkbox-text"
        class={[text_class(), @label_class]}
      >
        <%= if @inner_block != [] do %>
          {render_slot(@inner_block)}
        <% else %>
          {@label}
        <% end %>
        <small :if={@description} data-part="checkbox-description" class={description_class()}>{@description}</small>
      </span>
    </label>
    """
  end

  # ---- checkbox_group --------------------------------------------------------------

  attr :field, Phoenix.HTML.FormField, default: nil
  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :any, default: nil
  attr :options, :list, default: []
  attr :color, :string, default: "primary", values: @colors
  attr :variant, :string, default: "basic", values: ~w(basic outline card chip)
  attr :filled, :boolean, default: false
  attr :shape, :string, default: "square", values: ~w(square circle)
  attr :size, :string, default: "md", values: ~w(xs sm md lg)
  attr :label, :string, default: nil
  attr :label_class, :any, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :disabled, :boolean, default: false
  attr :wrapper_class, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :checkbox do
    attr :value, :any
    attr :label, :string
    attr :color, :string
    attr :disabled, :boolean
    attr :description, :string
    attr :count, :any
    attr :icon, :string
  end

  def checkbox_group(assigns) do
    {assigns, id} = Options.resolve_field(assigns)
    assigns = assign(assigns, :id, id || assigns.name || "checkbox-group")
    selected = Options.values(assigns.value)

    name =
      assigns.name &&
        if(String.ends_with?(assigns.name, "[]"), do: assigns.name, else: assigns.name <> "[]")

    items =
      if assigns.checkbox != [] do
        assigns.checkbox
        |> Enum.with_index()
        |> Enum.map(fn {s, i} ->
          %{
            value: Options.str(s[:value]),
            label: s[:label],
            description: s[:description],
            count: s[:count],
            icon: s[:icon],
            color: s[:color] || assigns.color,
            disabled: s[:disabled] || false,
            content: [s],
            idx: i
          }
        end)
      else
        assigns.options
        |> Options.normalize()
        |> Options.flatten()
        |> Enum.with_index()
        |> Enum.map(fn {o, i} ->
          %{
            value: o.value,
            label: o.label,
            description: o.description,
            count: o.count,
            icon: o.icon,
            color: o.color || assigns.color,
            disabled: o.disabled,
            content: [],
            idx: i
          }
        end)
      end

    assigns =
      assigns
      |> assign(:items, items)
      |> assign(:selected, selected)
      |> assign(:field_name, name)
      |> assign(
        :container,
        assigns.class ||
          if(assigns.variant in ["chip"],
            do: "flex flex-wrap items-center gap-2.5",
            else: "flex flex-col gap-2.5"
          )
      )

    ~H"""
    <Options.shell
      tag="div"
      label={@label}
      help={@help}
      errors={@errors}
      for={@id}
      bare={true}
      class={@wrapper_class}
    >
      <div
        id={@id}
        role={@label && "group"}
        aria-labelledby={@label && @id <> "-label"}
        class={@container}
        data-part="checkbox-group"
        {@rest}
      >
        <input :if={@field_name} type="hidden" name={@field_name} value="" />
        <%= for i <- @items do %>
          <%= if @variant in ["basic", "outline"] do %>
            <.group_checkbox g={assigns} i={i} />
          <% else %>
            <Choice.choice
              type="checkbox"
              variant={@variant}
              id={"#{@id}-#{i.idx}"}
              name={@field_name}
              value={i.value}
              checked={i.value in @selected}
              disabled={@disabled || i.disabled}
              label={i.label}
              description={i.description}
              count={i.count}
              icon={i.icon}
              color={i.color}
              shape={if @shape == "circle", do: "pill", else: "square"}
            >
              <:content :if={i.content != []}>{render_slot(i.content)}</:content>
            </Choice.choice>
          <% end %>
        <% end %>
      </div>
    </Options.shell>
    """
  end

  defp group_checkbox(%{g: g, i: i} = assigns) do
    _ = i

    assigns =
      assign(assigns,
        g:
          Map.take(g, [
            :id,
            :field_name,
            :selected,
            :color,
            :variant,
            :filled,
            :shape,
            :size,
            :label_class,
            :disabled
          ])
      )

    ~H"""
    <%= if @i.content == [] do %>
      <.checkbox
        id={"#{@g.id}-#{@i.idx}"}
        name={@g.field_name}
        value={@i.value}
        checked={@i.value in @g.selected}
        checked_value={@i.value}
        hidden_input={false}
        color={@i.color}
        variant={@g.variant}
        filled={@g.filled}
        shape={@g.shape}
        size={@g.size}
        label={@i.label}
        label_class={@g.label_class}
        description={@i.description}
        disabled={@g.disabled || @i.disabled}
      />
    <% else %>
      <.checkbox
        id={"#{@g.id}-#{@i.idx}"}
        name={@g.field_name}
        value={@i.value}
        checked={@i.value in @g.selected}
        checked_value={@i.value}
        hidden_input={false}
        color={@i.color}
        variant={@g.variant}
        filled={@g.filled}
        shape={@g.shape}
        size={@g.size}
        label_class={@g.label_class}
        description={@i.description}
        disabled={@g.disabled || @i.disabled}
      >
        {render_slot(@i.content)}
      </.checkbox>
    <% end %>
    """
  end
end
