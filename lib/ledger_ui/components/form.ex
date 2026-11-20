defmodule LedgerUI.Components.Form do
  @moduledoc """
  The pieces Ledger UI's forms are made of: a caption (`label/1`), a help line (`help_text/1`),
  an error line (`error/1`) and the `field/1` wrapper that puts them around any control.

      <.label for="email">Email</.label>
      <.help_text>We never share it.</.help_text>
      <.error>can't be blank</.error>

      <.field label="Country" help="Where you live" errors={@form[:country].errors}>
        <select>…</select>
      </.field>

  `input/1`, `textarea/1`, `otp_input/1`, `phone_input/1` and the groups already render their own
  field, so `field/1` is for the controls Ledger UI does not draw (a native `<select>`, a
  third-party widget).
  """
  use LedgerUI.Component

  @states %{"success" => "ok", "error" => "err"}

  # The look of the caption and of the help/error lines (Tailwind utilities only).
  @label "flex items-center gap-1.5 text-[13px] font-medium text-ink"
  @help "text-[12.5px] leading-[17px] text-muted"
  @help_err "flex items-center gap-[5px] text-[12.5px] leading-[17px] text-neg"
  @help_ok "flex items-center gap-[5px] text-[12.5px] leading-[17px] text-pos"

  # ---------------------------------------------------------------------------------------------
  # Shared helpers (used by the other form modules; `@doc false`)
  # ---------------------------------------------------------------------------------------------

  @doc false
  # Resolves `field={@form[:x]}` into id/name/value/errors, as in the Phoenix core components.
  # `errors` given by hand are kept and the field's own (once used) are appended.
  def lu_assign_field(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    own = if Phoenix.Component.used_input?(field), do: field.errors, else: []
    given = Map.get(assigns, :errors) || []

    assigns
    |> assign(:field, nil)
    |> assign(:id, Map.get(assigns, :id) || field.id)
    |> assign(:name, Map.get(assigns, :name) || field.name)
    |> assign(:value, Map.get(assigns, :value, nil) || field.value)
    |> assign(:errors, given ++ Enum.map(own, &lu_translate_error/1))
  end

  def lu_assign_field(assigns), do: assigns

  @doc false
  def lu_translate_error({msg, opts}) when is_binary(msg) and is_list(opts) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", fn _ -> to_string(value) end)
    end)
  end

  def lu_translate_error(msg) when is_binary(msg), do: msg
  def lu_translate_error(other), do: to_string(other)

  @doc false
  # "err" when there are errors, otherwise the class of an explicit state.
  def lu_state_class(state, errors) do
    cond do
      errors not in [nil, []] -> "err"
      true -> @states[state]
    end
  end

  # ---------------------------------------------------------------------------------------------
  # <.label>
  # ---------------------------------------------------------------------------------------------

  attr :for, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "A caption for the control with the id `for`."
  def label(assigns) do
    assigns = assign(assigns, :label, @label)

    ~H"""
    <label data-part="label" for={@for} class={[@label, @class]} {@rest}>
      {render_slot(@inner_block)}
    </label>
    """
  end

  # ---------------------------------------------------------------------------------------------
  # <.error>
  # ---------------------------------------------------------------------------------------------

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "A validation message in the small red text. It has `role=\"alert\"`."
  def error(assigns) do
    assigns = assign(assigns, :cls, @help_err)

    ~H"""
    <span data-part="error" role="alert" class={[@cls, @class]} {@rest}>
      <.icon name="warn-circle" size="sm" />{render_slot(@inner_block)}
    </span>
    """
  end

  # ---------------------------------------------------------------------------------------------
  # <.help_text>
  # ---------------------------------------------------------------------------------------------

  attr :state, :string, default: nil, values: [nil, "", "success", "error"]
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc """
  The small line under a control. `state="success"` paints it green (with a check-circle icon)
  and `state="error"` red.
  """
  def help_text(%{state: "success"} = assigns) do
    assigns = assign(assigns, :cls, @help_ok)

    ~H"""
    <span data-part="help" class={[@cls, @class]} {@rest}>
      <.icon name="check-circle" size="sm" />{render_slot(@inner_block)}
    </span>
    """
  end

  def help_text(%{state: "error"} = assigns) do
    assigns = assign(assigns, :cls, @help_err)

    ~H"""
    <span data-part="help" class={[@cls, @class]} {@rest}>
      <.icon name="warn-circle" size="sm" />{render_slot(@inner_block)}
    </span>
    """
  end

  def help_text(assigns) do
    assigns = assign(assigns, :cls, @help)

    ~H"""
    <span data-part="help" class={[@cls, @class]} {@rest}>{render_slot(@inner_block)}</span>
    """
  end

  # ---------------------------------------------------------------------------------------------
  # <.field>
  # ---------------------------------------------------------------------------------------------

  attr :field, Phoenix.HTML.FormField, default: nil, doc: "Takes the errors from a form field."
  attr :id, :string, default: nil, doc: "The id of the control, for the caption's `for`."
  attr :label, :string, default: nil
  attr :label_class, :any, default: nil
  attr :label_hint, :string, default: nil
  attr :optional, :boolean, default: false, doc: "Adds \"(opcional)\" to the caption."
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :state, :string, default: nil, values: [nil, "", "success", "error"]
  attr :as, :string, default: "label", values: ~w(label div)
  attr :layout, :string, default: "stacked", values: ~w(stacked inline)
  attr :required, :boolean, default: false, doc: "Adds the red asterisk to the caption."
  attr :label_id, :string, default: nil, doc: "Id of the caption (for `aria-labelledby`)."

  attr :msg_id, :string,
    default: nil,
    doc: "Id of the first help/error line (`aria-describedby`)."

  attr :class, :any, default: nil

  attr :bare, :boolean,
    default: false,
    doc: "With nothing to show around the control (no caption, help, errors) render it alone."

  attr :rest, :global

  slot :aside, doc: "At the right of the help/error line (a character counter)."
  slot :below, doc: "Between the control and the help line (strength bars)."
  slot :inner_block, required: true

  slot :label_aside,
    doc: "At the right of the caption (a \"Forgot?\" link): the caption and this sit in one row."

  @doc """
  Wraps a control with its caption, help line and errors.

  With `as="label"` (default) the whole block is a `<label>`, so a click on the caption focuses
  the control. When there are errors they replace the help line.
  """
  def field(assigns) do
    assigns = lu_assign_field(assigns)

    if assigns.bare and assigns.label == nil and assigns.help == nil and assigns.errors == [] and
         assigns.aside == [] and assigns.below == [] and assigns.label_aside == [] and
         assigns.class == nil do
      ~H"""
      {render_slot(@inner_block)}
      """
    else
      field_full(assigns)
    end
  end

  defp field_full(assigns) do
    has_aside = assigns.aside != []
    has_msg = assigns.errors != [] or assigns.help != nil or has_aside

    assigns =
      assigns
      |> assign(:root_class, [
        "flex min-w-0",
        assigns.layout == "inline" &&
          "flex-row items-center gap-3.5 [&>:not([data-part=label])]:flex-1",
        assigns.layout != "inline" && "flex-col gap-1.5",
        assigns.class
      ])
      |> assign(:label_cls, [
        @label,
        assigns.layout == "inline" && "w-[120px] flex-none",
        assigns.label_class
      ])
      |> assign(:has_aside, has_aside)
      |> assign(:wrap, assigns.layout == "inline" and has_msg)
      |> assign(:help_state, if(assigns.errors == [], do: assigns.state, else: "error"))

    ~H"""
    <.dynamic_tag tag_name={@as} data-part="field" class={@root_class} {@rest}>
      <div
        :if={@label != nil and @label_aside != []}
        data-part="label-row"
        class="flex flex-wrap items-center justify-between gap-2.5"
      >
        <span id={@label_id} class={@label_cls}>
          {@label}
          <span :if={@required} class="text-neg">*</span><span
            :if={@optional}
            class="font-normal text-muted"
          >(opcional)</span>
          <span :if={@label_hint} class="ml-auto text-[12.5px] font-normal text-subtle">{@label_hint}</span>
        </span>
        {render_slot(@label_aside)}
      </div>
      <span
        :if={@label != nil and @label_aside == []}
        data-part="label"
        id={@label_id}
        class={@label_cls}
      >
        {@label}
        <span :if={@required} class="text-neg">*</span><span
          :if={@optional}
          class="font-normal text-muted"
        >(opcional)</span>
        <span :if={@label_hint} class="ml-auto text-[12.5px] font-normal text-subtle">{@label_hint}</span>
      </span>
      <div :if={@wrap} class="flex flex-col gap-1.5">
        <.field_main
          inner={@inner_block}
          below={@below}
          aside={@aside}
          has_aside={@has_aside}
          help={@help}
          errors={@errors}
          help_state={@help_state}
          msg_id={@msg_id}
        />
      </div>
      <.field_main
        :if={!@wrap}
        inner={@inner_block}
        below={@below}
        aside={@aside}
        has_aside={@has_aside}
        help={@help}
        errors={@errors}
        help_state={@help_state}
        msg_id={@msg_id}
      />
    </.dynamic_tag>
    """
  end

  attr :inner, :list, default: []
  attr :below, :list, default: []
  attr :aside, :list, default: []
  attr :has_aside, :boolean, default: false
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :help_state, :string, default: nil
  attr :msg_id, :string, default: nil

  defp field_main(assigns) do
    ~H"""
    {render_slot(@inner)}{render_slot(@below)}
    <.field_msg
      has_aside={@has_aside}
      help={@help}
      errors={@errors}
      help_state={@help_state}
      aside={@aside}
      msg_id={@msg_id}
    />
    """
  end

  attr :has_aside, :boolean, default: false
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :help_state, :string, default: nil
  attr :aside, :list, default: []
  attr :msg_id, :string, default: nil

  defp field_msg(%{has_aside: true} = assigns) do
    assigns = assign(assigns, help_err: @help_err, help_cls: @help)

    ~H"""
    <div class="flex items-baseline gap-2.5">
      <span
        :for={{msg, i} <- Enum.with_index(@errors)}
        id={i == 0 && @msg_id}
        role="alert"
        class={@help_err}
      >
        <.icon name="warn-circle" size="sm" />{msg}
      </span>
      <.help_text :if={@errors == [] and @help != nil} id={@msg_id} state={@help_state}>
        {@help}
      </.help_text>
      <span :if={@errors == [] and @help == nil} class={@help_cls}></span>
      {render_slot(@aside)}
    </div>
    """
  end

  defp field_msg(assigns) do
    assigns = assign(assigns, help_err: @help_err)

    ~H"""
    <span
      :for={{msg, i} <- Enum.with_index(@errors)}
      id={i == 0 && @msg_id}
      role="alert"
      class={@help_err}
    >
      <.icon name="warn-circle" size="sm" />{msg}
    </span>
    <.help_text :if={@errors == [] and @help != nil} id={@msg_id} state={@help_state}>
      {@help}
    </.help_text>
    """
  end
end
