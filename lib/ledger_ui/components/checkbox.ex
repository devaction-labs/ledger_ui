defmodule LedgerUI.Components.Checkbox do
  @moduledoc """
  `checkbox/1` (the `lu-check` box with label and description) and `checkbox_group/1` (one
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

  @styles %{
    "size" => %{"xs" => "s-xs", "sm" => "s-sm", "md" => "s-md", "lg" => "s-lg"},
    "shape" => %{"square" => nil, "circle" => "circle"},
    "outline" => "padding:8px 12px;border:1px solid var(--line-strong);border-radius:10px"
  }
  @colors ~w(neutral primary secondary info success warning error)

  attr :field, Phoenix.HTML.FormField, default: nil
  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :any, default: nil
  attr :checked, :boolean, default: nil
  attr :indeterminate, :boolean, default: nil
  attr :checked_value, :string, default: "true"
  attr :unchecked_value, :string, default: "false"
  attr :hidden_input, :boolean, default: true
  attr :color, :string, default: "neutral", values: @colors
  attr :variant, :string, default: "basic", values: ~w(basic outline)
  attr :filled, :boolean, default: false
  attr :shape, :string, default: "square", values: ~w(square circle)
  attr :size, :string, default: "md", values: [nil, "xs", "sm", "md", "lg"]
  attr :label, :string, default: nil
  attr :label_class, :any, default: nil
  attr :description, :string, default: nil
  attr :errors, :list, default: []
  attr :disabled, :boolean, default: false
  attr :wrapper_class, :any, default: nil
  attr :class, :any, default: nil
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
      |> assign(
        :classes,
        cx([
          "lu-check",
          "c-" <> assigns.color,
          @styles["size"][assigns.size],
          @styles["shape"][assigns.shape],
          assigns.filled && "filled",
          assigns.disabled && "dis",
          assigns.class
        ])
      )
      |> assign(:outline_style, if(assigns.variant == "outline", do: @styles["outline"]))
      |> assign(:wrap?, assigns.wrapper_class != nil || assigns.errors != [])

    ~H"""
    <%= if @wrap? do %>
      <div class={@wrapper_class}>
        {checkbox_label(assigns)}
        <span :for={e <- @errors} class="lu-help err">{e}</span>
      </div>
    <% else %>
      {checkbox_label(assigns)}
    <% end %>
    """
  end

  defp checkbox_label(assigns) do
    ~H"""
    <label class={@classes} {Options.style_attrs(@outline_style)}>
      <input
        :if={@name && @hidden_input}
        type="hidden"
        name={@name}
        value={@unchecked_value}
        disabled={@disabled}
      />
      <input
        type="checkbox"
        id={@hook_id || @input_id}
        name={@name}
        value={@name && @checked_value}
        checked={@is_checked}
        disabled={@disabled}
        data-ind={@indeterminate && "1"}
        phx-hook={@hook_id && "LedgerUI.Indeterminate"}
        {@rest}
      />
      <span :if={@inner_block != [] || @label || @description} class={cx(["t", @label_class])}>
        <%= if @inner_block != [] do %>
          {render_slot(@inner_block)}
        <% else %>
          {@label}
        <% end %>
        <small :if={@description}>{@description}</small>
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
  attr :color, :string, default: "neutral", values: @colors
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
          if(assigns.variant in ["chip"], do: "lu-row", else: "lu-col")
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
        phx-hook={@variant in ["card", "chip"] && "LedgerUI.ChoiceGroup"}
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
