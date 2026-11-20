defmodule LedgerUI.Components.Input do
  @moduledoc """
  Single-line text field: `outlined`, `filled` or `plain`, `rounded` or `pill`, three sizes, icon,
  prefix and suffix, states, masks.

      <.input field={@form[:name]} label="Nome" />
      <.input field={@form[:total]} align="right" label="Total"><:prefix text>R$</:prefix></.input>
      <.input field={@form[:email]} type="email" variant="filled" size="lg" state="success" help="E-mail verificado" />
      <.input field={@form[:q]} shape="pill" layout="inline" label="Buscar" label_hint="opcional" />

  `field={@form[:name]}` fills `id`, `name`, `value` and `errors`. With errors the help line shows
  the messages and the box turns red.

  ## Masks

  `mask` formats what is typed (hook `LedgerUI.InputMask`, which needs a stable `id`; it comes
  from `field`):

      <.input name="doc" mask="cpf_cnpj" label="CPF ou CNPJ" mask_submit="raw" />
      <.input name="amount" mask="numeral" mask_options={%{thousands: "lakh"}} />
      <.input name="code" mask="blocks" mask_options={%{blocks: [3, 2, 3], delimiter: "-", uppercase: true}} />

  | mask | options |
  |---|---|
  | `blocks` | `blocks`, `delimiter`, `delimiters`, `prefix`, `uppercase`, `lowercase`, `numeric` |
  | `credit_card` | `delimiter` |
  | `date` | `pattern` (`~w(d m Y)`), `delimiter` |
  | `time` | `pattern` (`~w(h m s)`), `delimiter` |
  | `phone` | `blocks`, `delimiter` |
  | `cpf_cnpj` | none |
  | `numeral` | `thousands`, `decimals`, `delimiter`, `decimal_mark`, `positive`, `prefix` |

  The input submits the masked text; `mask_submit="raw"` submits the unmasked value through a
  hidden input that carries the field's name.

  ## Slots

  `:prefix` and `:suffix` hold an icon (or, with `text`, an addon such as `R$`, `%`, `.com.br`);
  `interactive` puts a button there. `:label_aside` goes at the right of the caption and `:below`
  between the box and the help line.

  Inside an `input_group` use `variant="plain"`: the group draws the shared border.
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Form

  @types ~w(text email password number search tel url date time datetime-local month week color file hidden)

  @styles %{
    "variant" => %{"outlined" => nil, "filled" => "filled", "plain" => "plain"},
    "size" => %{"sm" => "sm", "md" => nil, "lg" => "lg"},
    "shape" => %{"rounded" => nil, "pill" => "pill"},
    "align" => %{"left" => nil, "right" => "right"}
  }

  attr :field, Phoenix.HTML.FormField,
    default: nil,
    doc: "A form field: fills id/name/value/errors."

  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :any, default: nil
  attr :type, :string, default: "text", values: @types
  attr :variant, :string, default: "outlined", values: ~w(outlined filled plain)
  attr :size, :string, default: "md", values: ~w(sm md lg)
  attr :shape, :string, default: "rounded", values: ~w(rounded pill)
  attr :align, :string, default: "left", values: ~w(left right)
  attr :state, :string, default: nil, values: [nil, "", "success", "error"]
  attr :label, :string, default: nil
  attr :label_class, :any, default: nil
  attr :label_hint, :string, default: nil
  attr :layout, :string, default: "stacked", values: ~w(stacked inline)
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :disabled, :boolean, default: false
  attr :options, :list, default: [], doc: "Suggestions, rendered as the input's `<datalist>`."
  attr :icon, :string, default: nil, doc: "Icon name at the left of the text."

  attr :mask, :string,
    default: nil,
    values: [nil, "", "blocks", "credit_card", "date", "time", "phone", "numeral", "cpf_cnpj"]

  attr :mask_options, :map, default: %{}
  attr :mask_submit, :string, default: "formatted", values: ~w(formatted raw)
  attr :clear_on_submit, :boolean, default: false
  attr :wrapper_class, :any, default: nil
  attr :class, :any, default: nil

  attr :rest, :global,
    include:
      ~w(accept autocomplete autofocus form list max maxlength min minlength multiple pattern placeholder readonly required step inputmode size)

  slot :below
  slot :label_aside

  slot :prefix do
    attr :interactive, :boolean
    attr :text, :boolean
    attr :class, :any
  end

  slot :suffix do
    attr :interactive, :boolean
    attr :text, :boolean
    attr :class, :any
  end

  @doc "Renders a text-like `<input>`, with its caption, help and errors when given."
  def input(%{type: "hidden"} = assigns) do
    assigns = Form.lu_assign_field(assigns)

    ~H"""
    <input
      type="hidden"
      id={@id}
      name={@name}
      value={Phoenix.HTML.Form.normalize_value("hidden", @value)}
      {@rest}
    />
    """
  end

  def input(assigns) do
    assigns = Form.lu_assign_field(assigns)
    errors = assigns.errors
    rest = assigns.rest
    masked? = assigns.mask not in [nil, ""]
    raw? = masked? and assigns.mask_submit == "raw"
    hook? = masked? or assigns.clear_on_submit

    has_msg? =
      assigns.label != nil or assigns.help != nil or errors != [] or assigns.below != [] or
        assigns.label_aside != []

    state_class = Form.lu_state_class(assigns.state, errors)

    box_class =
      cx([
        "lu-input",
        @styles["variant"][assigns.variant],
        @styles["size"][assigns.size],
        @styles["shape"][assigns.shape],
        @styles["align"][assigns.align],
        state_class,
        assigns.disabled && "disabled",
        assigns.class
      ])

    input_attrs =
      rest
      |> maybe_put(:inputmode, assigns.mask == "cpf_cnpj" && "numeric")
      |> maybe_put(:list, assigns.options != [] && assigns.id && assigns.id <> "-list")
      |> maybe_put(
        :"aria-invalid",
        if(errors != [] or assigns.state == "error", do: "true")
      )

    value = Phoenix.HTML.Form.normalize_value(assigns.type, assigns.value)

    assigns =
      assigns
      |> assign(:box_class, box_class)
      |> assign(:input_attrs, input_attrs)
      |> assign(:value_attr, value)
      |> assign(:has_msg, has_msg?)
      |> assign(:masked, masked?)
      |> assign(:raw, raw?)
      |> assign(:hook, hook?)
      |> assign(:required, rest[:required] in [true, "true", "required", ""])
      |> assign(:mask_json, if(masked?, do: Jason.encode!(assigns.mask_options)))
      |> assign(:as, if(assigns.label, do: "label", else: "div"))
      |> assign(:debounce, Map.take(rest, [:"phx-debounce", :"phx-throttle"]))

    ~H"""
    <Form.field
      :if={@has_msg}
      as={@as}
      label={@label}
      label_class={@label_class}
      label_hint={@label_hint}
      help={@help}
      errors={@errors}
      state={@state}
      layout={@layout}
      required={@required}
      class={@wrapper_class}
    >
      <:label_aside :if={@label_aside != []}>{render_slot(@label_aside)}</:label_aside>
      <:below :if={@below != []}>{render_slot(@below)}</:below>
      <.box
        box_class={@box_class}
        input_attrs={@input_attrs}
        value_attr={@value_attr}
        id={@id}
        name={@name}
        type={@type}
        disabled={@disabled}
        icon={@icon}
        options={@options}
        mask={@mask}
        mask_json={@mask_json}
        raw={@raw}
        hook={@hook}
        clear_on_submit={@clear_on_submit}
        debounce={@debounce}
        prefix={@prefix}
        suffix={@suffix}
      />
    </Form.field>
    <.box
      :if={!@has_msg}
      box_class={@box_class}
      input_attrs={@input_attrs}
      value_attr={@value_attr}
      id={@id}
      name={@name}
      type={@type}
      disabled={@disabled}
      icon={@icon}
      options={@options}
      mask={@mask}
      mask_json={@mask_json}
      raw={@raw}
      hook={@hook}
      clear_on_submit={@clear_on_submit}
      debounce={@debounce}
      prefix={@prefix}
      suffix={@suffix}
    />
    """
  end

  attr :box_class, :string
  attr :input_attrs, :map
  attr :value_attr, :any, default: nil
  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :type, :string
  attr :disabled, :boolean, default: false
  attr :icon, :string, default: nil
  attr :options, :list, default: []
  attr :mask, :string, default: nil
  attr :mask_json, :string, default: nil
  attr :raw, :boolean, default: false
  attr :hook, :boolean, default: false
  attr :clear_on_submit, :boolean, default: false
  attr :debounce, :map, default: %{}
  attr :prefix, :list, default: []
  attr :suffix, :list, default: []

  # The `.lu-input` box with its input, icon, prefix and suffix.
  defp box(assigns) do
    ~H"""
    <span data-part="input" class={@box_class}>
      <.icon :if={@icon} name={@icon} />
      <.addon :for={p <- @prefix} slot={p} side="sep" />
      <input
        id={@id}
        name={if @raw, do: nil, else: @name}
        type={@type}
        value={@value_attr}
        disabled={@disabled}
        phx-hook={@hook && "LedgerUI.InputMask"}
        data-lu-mask={@mask}
        data-lu-mask-options={@mask_json}
        data-lu-mask-raw={@raw && "true"}
        data-lu-clear-on-submit={@clear_on_submit && "true"}
        {@input_attrs}
      />
      <input :if={@raw} type="hidden" name={@name} value={@value_attr} {@debounce} />
      <.addon :for={s <- @suffix} slot={s} side="sep-r" />
      <datalist :if={@options != []} id={@id && @id <> "-list"}>
        <option :for={opt <- @options} value={opt}></option>
      </datalist>
    </span>
    """
  end

  attr :slot, :map, required: true
  attr :side, :string, required: true

  defp addon(%{slot: %{interactive: true}} = assigns) do
    ~H"""
    {render_slot(@slot)}
    """
  end

  defp addon(%{slot: %{text: true}} = assigns) do
    ~H"""
    <span class={cx(["addon", @side, @slot[:class]])}>{render_slot(@slot)}</span>
    """
  end

  defp addon(assigns) do
    ~H"""
    <span
      class={cx(["lu-input-i", @slot[:class]])}
      style="display:inline-flex;pointer-events:none;color:var(--muted)"
    >
      {render_slot(@slot)}
    </span>
    """
  end

  defp maybe_put(map, _key, value) when value in [nil, false], do: map
  defp maybe_put(map, key, value), do: Map.put_new(map, key, value)
end
