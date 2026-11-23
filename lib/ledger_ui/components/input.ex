defmodule LedgerUI.Components.Input do
  @moduledoc """
  Single-line text field styled only with Tailwind utilities: `outlined`, `filled` or `plain`,
  `rounded` or `pill`, three sizes, icon, prefix and suffix, states, masks.

      <.input field={@form[:name]} label="Nome" />
      <.input field={@form[:total]} align="right" label="Total" prefix="R$" suffix="BRL" />
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

  `prefix` and `suffix` are text addons (`R$`, `%`, `.com.br`) separated by a divider. The slots
  `:leading` and `:trailing` hold a control inside the box (a button, a `kbd`, a clear icon).
  `:label_aside` goes at the right of the caption and `:below` between the box and the help line.

  ## Shortcut

  `shortcut` draws a `kbd` at the end of the field and focuses the field when the key is pressed
  anywhere on the page (the search of a list):

      <.input type="search" name="q" placeholder="Buscar" shortcut="/" />

  The value is a combination as in `hotkey/1` (`"/"`, `"Mod+k"`); modifiers must match exactly, so
  `"/"` does not fire with Ctrl, Meta or Alt. The press is ignored while the focus is in another
  `input`, `select`, `textarea` or `contenteditable` element, and Esc inside the field takes the
  focus out. The field gets `aria-keyshortcuts` and the `kbd` is `aria-hidden`. With several
  fields with `shortcut` on one page, only the first visible one (in document order) answers.
  The hook (`LedgerUI.SearchShortcut`) sits on the box, so it does not clash with `mask`'s hook;
  it needs an `id` (it comes from `field`, or is derived from `name`). Without `shortcut` the
  markup is unchanged.

  Inside an `input_group` use `variant="plain"`: the group draws the shared border.
  """
  use LedgerUI.Component

  import LedgerUI.Components.Typography, only: [kbd: 1]

  alias LedgerUI.Components.Form

  @types ~w(text email password number search tel url date time datetime-local month week color file hidden)

  # height, horizontal padding (right, left), radius
  @sizes %{
    "sm" => {"h-8", "px-2.5", "pr-2.5", "rounded-md"},
    "md" => {"h-9", "px-3", "pr-3", "rounded-md"},
    "lg" => {"h-10", "px-3", "pr-3", "rounded-lg"}
  }

  @variants ~w(outlined filled plain)

  @base "flex min-w-0 items-center gap-2 border transition-[border-color,box-shadow] duration-150"

  @doc false
  # The class list of the box. Every axis picks ONE utility per CSS property here.
  def box_classes(variant, size, shape, state, disabled) do
    {h, px, pr, r} = @sizes[size]
    plain? = variant == "plain"

    [
      @base,
      h,
      if(shape == "pill",
        do: "rounded-full px-4",
        else: [r, if(plain?, do: [pr, "pl-0.5"], else: px)]
      ),
      colors(variant, state, disabled),
      focus(variant, state),
      disabled && "cursor-not-allowed [&_input]:cursor-not-allowed"
    ]
  end

  defp colors(variant, state, disabled) do
    bg =
      cond do
        variant == "plain" -> "bg-transparent"
        variant == "filled" or disabled -> "bg-sunken"
        true -> "bg-panel"
      end

    border =
      cond do
        state == "error" ->
          "border-neg"

        state == "success" ->
          "border-pos"

        variant == "outlined" ->
          "border-line-strong not-focus-within:hover:border-[color-mix(in_oklab,var(--lu-line-strong)_60%,var(--lu-muted))]"

        true ->
          "border-transparent"
      end

    [bg, border, if(disabled, do: "text-muted", else: "text-ink")]
  end

  defp focus("plain", _state), do: "focus-within:shadow-none"

  defp focus(variant, state) do
    ring =
      if state == "error",
        do: "focus-within:shadow-[0_0_0_3px_color-mix(in_oklab,var(--lu-neg)_25%,transparent)]",
        else: "focus-within:shadow-[0_0_0_3px_var(--lu-focus)]"

    [ring, (variant == "outlined" and state == nil) && "focus-within:border-accent-500"]
  end

  attr :field, Phoenix.HTML.FormField,
    default: nil,
    doc: "A form field: fills id/name/value/errors."

  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :any, default: nil
  attr :type, :string, default: "text", values: @types
  attr :variant, :string, default: "outlined", values: @variants
  attr :size, :string, default: "md", values: Map.keys(@sizes)
  attr :shape, :string, default: "rounded", values: ~w(rounded pill)
  attr :align, :string, default: "left", values: ~w(left right)
  attr :state, :string, default: nil, values: [nil, "", "success", "error"]
  attr :label, :string, default: nil
  attr :label_class, :any, default: nil
  attr :hint, :string, default: nil, doc: "Text at the right of the label (alias: `label_hint`)."
  attr :label_hint, :string, default: nil
  attr :optional, :boolean, default: false, doc: "Adds \"(opcional)\" to the label."
  attr :required, :boolean, default: false
  attr :layout, :string, default: "stacked", values: ~w(stacked inline)
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :disabled, :boolean, default: false
  attr :options, :list, default: [], doc: "Suggestions, rendered as the input's `<datalist>`."
  attr :icon, :string, default: nil, doc: "Icon name at the left of the text."
  attr :prefix, :string, default: nil, doc: "Text addon before the input (`R$`)."
  attr :suffix, :string, default: nil, doc: "Text addon after the input (`BRL`)."

  attr :mask, :string,
    default: nil,
    values: [nil, "", "blocks", "credit_card", "date", "time", "phone", "numeral", "cpf_cnpj"]

  attr :mask_options, :map, default: %{}
  attr :mask_submit, :string, default: "formatted", values: ~w(formatted raw)
  attr :clear_on_submit, :boolean, default: false

  attr :shortcut, :string,
    default: nil,
    doc: "A key that focuses the field (`\"/\"`); draws a `kbd` at the end. See \"Shortcut\"."

  attr :wrapper_class, :any,
    default: nil,
    doc: "Classes of the field wrapper (caption, box, help)."

  attr :class, :any, default: nil, doc: "Classes of the box."

  attr :rest, :global,
    include:
      ~w(accept autocomplete autofocus form list max maxlength min minlength multiple pattern placeholder readonly step inputmode size)

  slot :below
  slot :label_aside
  slot :leading, doc: "A control at the start of the box, after the icon."
  slot :trailing, doc: "A control at the end of the box (a button, a `kbd`)."

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
    shortcut? = assigns.shortcut not in [nil, ""]

    # A hook needs a stable DOM id: derive it from the name when none was given.
    assigns =
      if (hook? or shortcut?) and assigns.id in [nil, ""] and is_binary(assigns.name) do
        assign(assigns, :id, "lu-in-" <> String.replace(assigns.name, ~r/[^A-Za-z0-9_-]+/, "-"))
      else
        assigns
      end

    has_msg? =
      assigns.label != nil or assigns.help != nil or errors != [] or assigns.below != [] or
        assigns.label_aside != []

    state =
      if errors != [],
        do: "error",
        else: if(assigns.state in [nil, ""], do: nil, else: assigns.state)

    input_attrs =
      rest
      |> maybe_put(:inputmode, assigns.mask == "cpf_cnpj" && "numeric")
      |> maybe_put(:list, assigns.options != [] && assigns.id && assigns.id <> "-list")
      |> maybe_put(:"aria-invalid", if(state == "error", do: "true"))
      |> maybe_put(:"aria-keyshortcuts", shortcut? && assigns.shortcut)

    assigns =
      assigns
      |> assign(:box_class, [
        box_classes(assigns.variant, assigns.size, assigns.shape, state, assigns.disabled),
        assigns.class
      ])
      |> assign(:input_class, [
        "h-full min-w-0 flex-1 appearance-none border-0 bg-transparent p-0 text-sm outline-0",
        assigns.align == "right" && "text-right tabular-nums",
        # masked dots as in the canvas (18px, 3px apart); the placeholder and the revealed text stay 14px
        assigns.type == "password" &&
          "[&[type=password]:not(:placeholder-shown)]:text-[18px] [&[type=password]:not(:placeholder-shown)]:tracking-[3px]"
      ])
      |> assign(:input_attrs, input_attrs)
      |> assign(:value_attr, Phoenix.HTML.Form.normalize_value(assigns.type, assigns.value))
      |> assign(:has_msg, has_msg?)
      |> assign(:state, state)
      |> assign(:raw, raw?)
      |> assign(:hook, hook?)
      |> assign(:shortcut_on, shortcut? and assigns.id not in [nil, ""])
      |> assign(
        :required,
        assigns.required == true or rest[:required] in [true, "true", "required", ""]
      )
      |> assign(:mask_json, if(masked?, do: Jason.encode!(assigns.mask_options)))
      |> assign(:as, if(assigns.label, do: "label", else: "div"))
      |> assign(:debounce, Map.take(rest, [:"phx-debounce", :"phx-throttle"]))

    ~H"""
    <Form.field
      :if={@has_msg}
      as={@as}
      label={@label}
      label_class={@label_class}
      label_hint={@hint || @label_hint}
      optional={@optional}
      help={@help}
      errors={@errors}
      state={@state}
      layout={@layout}
      required={@required}
      class={@wrapper_class}
    >
      <:label_aside :if={@label_aside != []}>{render_slot(@label_aside)}</:label_aside>
      <:below :if={@below != []}>{render_slot(@below)}</:below>
      <.box {assigns} />
    </Form.field>
    <.box :if={!@has_msg} {assigns} />
    """
  end

  defp box(assigns) do
    ~H"""
    <span
      id={@shortcut_on && @id <> "-box"}
      data-part="input"
      class={@box_class}
      phx-hook={@shortcut_on && "LedgerUI.SearchShortcut"}
      data-lu-shortcut={@shortcut_on && @shortcut}
    >
      <.icon :if={@icon} name={@icon} class="text-muted" />
      <span
        :if={@prefix}
        data-part="input-addon"
        class="mr-0.5 flex items-center self-stretch border-r border-line pr-2.5 text-[13.5px] whitespace-nowrap text-muted"
      >{@prefix}</span>
      {render_slot(@leading)}
      <input
        id={@id}
        data-part="input-control"
        name={if @raw, do: nil, else: @name}
        type={@type}
        value={@value_attr}
        disabled={@disabled}
        required={@required}
        class={@input_class}
        phx-hook={@hook && "LedgerUI.InputMask"}
        data-lu-mask={@mask}
        data-lu-mask-options={@mask_json}
        data-lu-mask-raw={@raw && "true"}
        data-lu-clear-on-submit={@clear_on_submit && "true"}
        {@input_attrs}
      />
      <input :if={@raw} type="hidden" name={@name} value={@value_attr} {@debounce} />
      <span
        :if={@suffix}
        data-part="input-addon"
        class="flex items-center self-stretch border-l border-line pl-2.5 text-[13.5px] whitespace-nowrap text-muted"
      >{@suffix}</span>
      {render_slot(@trailing)}
      <.kbd :if={@shortcut_on} aria-hidden="true">{@shortcut}</.kbd>
      <datalist :if={@options != []} id={@id && @id <> "-list"}>
        <option :for={opt <- @options} value={opt}></option>
      </datalist>
    </span>
    """
  end

  defp maybe_put(map, _key, value) when value in [nil, false], do: map
  defp maybe_put(map, key, value), do: Map.put_new(map, key, value)
end
