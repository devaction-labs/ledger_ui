defmodule LedgerUI.Components.Select.Options do
  @moduledoc """
  Option shapes and form plumbing shared by `select`, `autocomplete`, `pillbox`,
  `tags_input`, `pill_select`, `segmented`, `checkbox_group` and `radio_group`.

  An option is one of

    * a string / number / atom: label and value are the same;
    * `{label, value}` (a keyword entry `[Alabama: "AL"]` is the same);
    * `{label, value, count}`;
    * a map with `:label` and `:value` (`:count`, `:hint`, `:disabled`, `:icon`,
      `:description`, `:color`, `:initials`, `:tone`; every other key goes to `data`);
    * `{group_label, [option]}`, a group.

  `normalize/1` returns a list of option maps (`%{label, value, disabled, hint, count,
  icon, description, color, initials, tone, data}`; `value` is always a string) and
  `%{group: label, options: [option]}` entries.
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Form

  @known ~w(label value count hint disabled icon description color initials tone)a

  @doc "Normalizes options and groups (see the module doc)."
  def normalize(nil), do: []
  def normalize(options), do: Enum.map(options, &normalize_one/1)

  defp normalize_one({group, options}) when is_list(options),
    do: %{group: str(group), options: normalize(options)}

  defp normalize_one({label, value}), do: build(label, value, %{})
  defp normalize_one({label, value, count}), do: build(label, value, %{count: count})

  defp normalize_one(%{} = map) do
    label = Map.get(map, :label) || Map.get(map, "label")
    value = Map.get(map, :value, Map.get(map, "value", label))
    extra = Map.take(map, @known)
    data = map |> Map.drop([:label, :value, "label", "value"]) |> Map.drop(@known)
    build(label || value, value, Map.put(extra, :data, data))
  end

  defp normalize_one(other), do: build(other, other, %{})

  defp build(label, value, extra) do
    %{
      label: str(label),
      value: str(value),
      disabled: Map.get(extra, :disabled, false) || false,
      hint: Map.get(extra, :hint),
      count: Map.get(extra, :count),
      icon: Map.get(extra, :icon),
      description: Map.get(extra, :description),
      color: Map.get(extra, :color),
      initials: Map.get(extra, :initials),
      tone: Map.get(extra, :tone),
      data: Map.get(extra, :data, %{})
    }
  end

  @doc "Options without the group wrappers."
  def flatten(options) do
    Enum.flat_map(options, fn
      %{group: _, options: opts} -> opts
      opt -> [opt]
    end)
  end

  @doc "`%{style: s}` for a style or `%{}`: an empty `style={nil}` would render `style=\"\"`."
  def style_attrs(nil), do: %{}
  def style_attrs(false), do: %{}
  def style_attrs(style), do: %{style: style}

  @doc "A list of chosen values as strings: `nil`, a scalar, a list or a comma separated string."
  def values(nil), do: []
  def values(""), do: []
  def values(list) when is_list(list), do: list |> Enum.map(&str/1) |> Enum.reject(&(&1 == ""))
  def values(other), do: [str(other)]

  @doc "Like `values/1` but a binary is split on commas."
  def csv_values(value) when is_binary(value),
    do:
      value
      |> String.split(",", trim: true)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

  def csv_values(value), do: values(value)

  @doc "To string, for option values (`nil` is the empty string)."
  def str(nil), do: ""
  def str(value) when is_binary(value), do: value
  def str(value) when is_atom(value) or is_number(value), do: to_string(value)
  def str(value), do: inspect(value)

  @doc """
  Fills `id`, `name`, `value` and `errors` from `field` and derives a stable id when none is
  given (never random: a hash of `seed`).
  """
  def resolve(assigns, prefix, seed \\ nil) do
    assigns =
      case assigns[:field] do
        %Phoenix.HTML.FormField{} = f ->
          errors =
            if Phoenix.Component.used_input?(f),
              do: Enum.map(f.errors, &translate_error/1),
              else: []

          assigns
          |> assign(:id, assigns[:id] || f.id)
          |> assign(:name, assigns[:name] || f.name)
          |> assign(:value, if(is_nil(assigns[:value]), do: f.value, else: assigns[:value]))
          |> assign(:errors, (assigns[:errors] || []) ++ errors)

        _ ->
          assigns
      end

    id = assigns[:id] || assigns[:name] || "#{prefix}-#{:erlang.phash2(seed || assigns[:label])}"
    assign(assigns, :id, id)
  end

  @doc "Form field for checkbox-like controls: returns `{assigns, id}`; `checked?/1` tells if it is on."
  def resolve_field(assigns) do
    case assigns.field do
      %Phoenix.HTML.FormField{} = f ->
        errors =
          if Phoenix.Component.used_input?(f),
            do: Enum.map(f.errors, &translate_error/1),
            else: []

        a =
          assigns
          |> assign(:name, assigns.name || f.name)
          |> assign(:value, if(is_nil(assigns.value), do: f.value, else: assigns.value))
          |> assign(:errors, assigns.errors ++ errors)

        {a, assigns.id || f.id}

      _ ->
        {assigns, assigns.id}
    end
  end

  @doc false
  def checked?(%{checked: checked}) when is_boolean(checked), do: checked

  def checked?(%{value: value} = a) do
    value == true || (value != nil && value != false && to_string(value) == a.checked_value)
  end

  @doc "Translates a changeset error (`{msg, opts}`) or passes a binary through."
  def translate_error({msg, opts}) when is_binary(msg) do
    Enum.reduce(opts, msg, fn {k, v}, acc ->
      String.replace(acc, "%{#{k}}", fn _ -> str(v) end)
    end)
  end

  def translate_error(msg) when is_binary(msg), do: msg
  def translate_error(other), do: str(other)

  @doc "Replaces `%{query}` (or any `%{key}`) in a text."
  def interpolate(text, bindings) do
    Enum.reduce(bindings, text, fn {k, v}, acc -> String.replace(acc, "%{#{k}}", str(v)) end)
  end

  @doc "Initials of a label: first letters of the first and last word."
  def initials(label) do
    case label |> to_string() |> String.split(~r/\s+/, trim: true) do
      [] -> ""
      [one] -> one |> String.slice(0, 2) |> String.upcase()
      words -> (String.first(hd(words)) <> String.first(List.last(words))) |> String.upcase()
    end
  end

  @panel "rounded-lg border border-line bg-panel shadow-md"
  @item "flex h-[34px] w-full cursor-pointer items-center gap-2.5 rounded-[8px] border-0 bg-transparent px-2.5 text-left text-sm text-ink-2 hover:bg-hover hover:text-ink data-hl:bg-hover data-hl:text-ink aria-selected:font-medium aria-selected:text-ink aria-disabled:cursor-not-allowed aria-disabled:opacity-45"
  @right "ml-auto flex items-center gap-1 text-xs text-muted"
  @group_label "px-2.5 pt-2 pb-1 text-[11.5px] font-medium tracking-[.06em] text-muted uppercase"
  @sep "-mx-[5px] my-[5px] h-px bg-line"
  # classes of `<.icon size="sm">`, for the icons the hooks draw
  @icon_sm "inline flex-none fill-none stroke-current stroke-[1.5] [stroke-linecap:round] [stroke-linejoin:round] align-middle size-3.5"
  @more "shrink-0 font-mono text-xs text-muted"

  @doc false
  def panel_class(min_width \\ "min-w-[220px]", padding \\ "p-[5px]"),
    do: [@panel, padding, min_width]

  @doc false
  def item_class, do: @item
  @doc false
  def right_class, do: @right
  @doc false
  def group_label_class, do: @group_label
  @doc false
  def sep_class, do: @sep
  @doc false
  def remove_class, do: LedgerUI.Components.Chip.remove_class()

  @doc false
  # The utilities of the nodes a hook draws (items, chips, icons), as the JSON of `data-lu-cls`.
  # Constant, so it is encoded once at compile time.
  @js_classes Jason.encode!(%{
                item: @item,
                right: @right,
                chip: cx(LedgerUI.Components.Chip.chip_class(nil, false, "sm")),
                remove: LedgerUI.Components.Chip.remove_class(),
                more: @more,
                icon: @icon_sm,
                ck: "text-accent-content"
              })
  def js_classes, do: @js_classes

  @doc "Avatar tone (`t1`..`t5`) taken from a name."
  def avatar_tone(name), do: "t#{rem(:erlang.phash2(name), 5) + 1}"

  @tones %{
    "t1" => "bg-accent-100 text-accent-800",
    "t2" => "bg-[#fde3c7] text-[#7a3d0c] dark:bg-[#3a2410] dark:text-[#f6c99a]",
    "t3" => "bg-[#e3e6fb] text-[#2b3577] dark:bg-[#1d2346] dark:text-[#b9c3f5]",
    "t4" => "bg-[#fbe0e6] text-[#7f1f33] dark:bg-[#3a1820] dark:text-[#f3b3c0]",
    "t5" => "bg-[#e2f6c6] text-[#355a0c] dark:bg-[#1f2c10] dark:text-[#c4e78f]"
  }

  attr :tone, :string, default: nil, doc: "`t1`..`t5`."
  attr :color, :string, default: nil, doc: "A CSS colour for the background (white text)."
  attr :src, :string, default: nil
  attr :initials, :string, default: nil
  attr :size, :integer, default: 24

  @doc false
  # The small round avatar of a person inside a chip or an option.
  def avatar(assigns) do
    assigns =
      assign(
        assigns,
        :cls,
        [
          "relative inline-grid size-(--s) flex-none place-items-center rounded-full text-[length:calc(var(--s)*.36)] font-semibold tracking-[-.01em]",
          if(assigns.color,
            do: "text-white",
            else: @tones[assigns.tone] || "bg-sunken text-ink-2"
          )
        ]
      )

    ~H"""
    <span
      data-part="person-avatar"
      class={@cls}
      style={"--s:#{@size}px" <> if(@color, do: ";background:#{@color}", else: "")}
    ><img
      :if={@src}
      src={@src}
      alt=""
      data-part="person-avatar-image"
      class="absolute inset-0 size-full rounded-[inherit] object-cover"
    />
    <%= if !@src do %>
      {@initials}
    <% end %></span>
    """
  end

  attr :label, :string, default: nil
  attr :label_hint, :string, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :tag, :string, default: "div"
  attr :class, :any, default: nil
  attr :for, :string, default: nil
  attr :bare, :boolean, default: true, doc: "No wrapper when there is nothing to caption."
  slot :inner_block, required: true
  slot :label_aside

  @doc false
  # The caption/help/errors frame of a control (`Form.field`).
  def shell(assigns) do
    assigns =
      assign(
        assigns,
        :wrap?,
        !assigns.bare || assigns.label || assigns.help || assigns.errors != [] ||
          assigns.class != nil
      )

    # Written out (not `Form.field`): a slot handed down as an attribute loses change tracking, so a
    # control whose state the server changes (a segmented value) would render stale.
    ~H"""
    <%= if @wrap? do %>
      <.dynamic_tag
        tag_name={@tag}
        data-part="field"
        class={["flex min-w-0 flex-col gap-1.5", @class]}
      >
        <div
          :if={@label != nil and @label_aside != []}
          data-part="label-row"
          class="flex flex-wrap items-center justify-between gap-2.5"
        >
          <span id={@for && @for <> "-label"} class={label_class()}>
            {@label}<span
              :if={@label_hint}
              data-part="label-hint"
              class="ml-auto text-[12.5px] font-normal text-subtle"
            >{@label_hint}</span>
          </span>
          {render_slot(@label_aside)}
        </div>
        <span
          :if={@label != nil and @label_aside == []}
          data-part="label"
          id={@for && @for <> "-label"}
          class={label_class()}
        >
          {@label}<span
            :if={@label_hint}
            data-part="label-hint"
            class="ml-auto text-[12.5px] font-normal text-subtle"
          >{@label_hint}</span>
        </span>
        {render_slot(@inner_block)}
        <Form.error :for={error <- @errors}>{error}</Form.error>
        <Form.help_text :if={@errors == [] and @help != nil}>{@help}</Form.help_text>
      </.dynamic_tag>
    <% else %>
      {render_slot(@inner_block)}
    <% end %>
    """
  end

  defp label_class, do: "flex items-center gap-1.5 text-[13px] font-medium text-ink"
end

defmodule LedgerUI.Components.Select do
  @moduledoc """
  Select: the styled native `<select>` (`native`) and a searchable listbox driven by the
  `LedgerUI.Select` hook (`priv/static/ledger_ui/hooks/select.js`).

      <.select native label="Type" options={~w(Wedding Birthday Other)} />
      <.select field={@form[:plan]} options={["Pro", "Scale", "Starter"]} />
      <.select field={@form[:states]} options={@states} multiple removable clearable />
      <.select field={@form[:author]} options={@authors} on_search="search_authors" target={@myself}>
        <:option :let={author}>{author.label} · {author.data.job}</:option>
      </.select>

  Options are strings, `{label, value}` tuples, maps or `{group, options}` (see
  `LedgerUI.Components.Select.Options`).

  The listbox submits through a hidden `<select>` named like the field (`name[]` when
  `multiple`) and fires a bubbling `input` event when the choice changes, so a surrounding
  `phx-change` runs. Opening, closing, keyboard and filtering never leave the browser; a
  value sent by the server wins over the one in the browser.

  **Width:** the root is `w-[260px]` by default. In a form or a grid pass `class="w-full"` so the
  control and the panel take the whole column (like the inputs next to it):

      <.select field={@form[:status]} options={@statuses} multiple class="w-full" />

  **Search:** `search` is `"auto"` by default: the filter box is in the control for a single
  select and at the top of the panel (focused when it opens) when `multiple`, where the
  control is taken by the chips and the `+N`. `"control"`, `"panel"` and `"none"` are kept as
  given.

  **Height:** with `overflow="count"` (default) a `multiple` control has the height of an
  input of the same `size` with 0, 1 or many chips; `overflow="wrap"` grows with the chips.

  `on_search` pushes `%{"id" => id, "query" => text}` (after `debounce` ms) and
  `on_load_more` pushes `%{"id" => id, "query" => text, "offset" => n}` to `target` or the
  LiveView.
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Checkbox
  alias LedgerUI.Components.Chip
  alias LedgerUI.Components.FieldBox
  alias LedgerUI.Components.Select.Options

  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :any, default: nil
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :label, :string, default: nil
  attr :label_hint, :string, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :options, :list, default: []
  attr :prompt, :string, default: nil
  attr :placeholder, :string, default: nil
  attr :multiple, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :native, :boolean, default: false
  attr :variant, :string, default: "outline", values: ~w(outline filled)
  attr :size, :string, default: "md", values: ~w(sm md lg)
  attr :shape, :string, default: "rounded", values: ~w(rounded pill)
  attr :inline, :boolean, default: false
  attr :icon, :string, default: nil, doc: "An icon before the text."
  attr :removable, :boolean, default: false
  attr :clearable, :boolean, default: false
  attr :clear_label, :string, default: "Clear"
  attr :remove_label, :string, default: "Remove"
  attr :create, :boolean, default: false
  attr :create_label, :string, default: "Add"
  attr :create_hint, :string, default: nil
  attr :persist, :boolean, default: true
  attr :restore_on_backspace, :boolean, default: false
  attr :max, :integer, default: nil
  attr :overflow, :string, default: "count", values: ~w(count wrap)
  attr :footer, :boolean, default: false
  attr :footer_count, :string, default: "%{count} of %{total}"
  attr :footer_hint, :string, default: "Esc to close"
  attr :more_label, :string, default: "more"
  attr :no_results, :string, default: "No results found"

  attr :search, :string,
    default: "auto",
    values: ~w(auto control panel none),
    doc: "Where the filter box is: `auto` is `panel` when `multiple` and `control` otherwise."

  attr :search_placeholder, :string, default: "Search…"
  attr :panel_min_width, :string, default: nil
  attr :panel_class, :any, default: nil
  attr :on_search, :string, default: nil
  attr :debounce, :integer, default: 300
  attr :target, :any, default: nil
  attr :on_load_more, :string, default: nil
  attr :has_more, :boolean, default: false
  attr :loading_label, :string, default: "Loading…"
  attr :open, :boolean, default: false, doc: "Renders the list open (static previews)."
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(form autocomplete required)

  slot :below
  slot :item
  slot :label_aside
  slot :option
  slot :suffix

  # `wrap` grows with the chips (min height, vertical padding); `count` is one line, so its
  # height is fixed and equals the one of an input of the same size.
  @pbox_sizes %{
    "sm" => "min-h-8 py-[5px]",
    "md" => "min-h-[38px] py-[5px]",
    "lg" => "min-h-11 py-[5px]"
  }
  @pbox_fixed %{"sm" => "h-8 py-0", "md" => "h-[38px] py-0", "lg" => "h-11 py-0"}

  def select(%{native: true} = assigns) do
    assigns = Options.resolve(assigns, "select")
    options = Options.normalize(assigns.options)
    selected = Options.values(assigns.value)
    state = if assigns.errors != [], do: "error"

    assigns =
      assigns
      |> assign(:opts, options)
      |> assign(:selected, selected)
      |> assign(
        :box_class,
        [
          FieldBox.classes(
            if(assigns.variant == "filled", do: "filled", else: "outlined"),
            assigns.size,
            assigns.shape,
            state,
            assigns.disabled,
            display: if(assigns.inline, do: "inline-flex", else: "flex")
          ),
          assigns.class
        ]
      )
      |> assign(:select_name, assigns.name && assigns.multiple && assigns.name <> "[]")
      |> assign(
        :select_class,
        [
          FieldBox.control_class(),
          "text-ellipsis",
          if(assigns.disabled, do: "cursor-not-allowed text-muted", else: "cursor-pointer")
        ]
      )

    ~H"""
    <Options.shell
      tag="div"
      label={@label}
      label_hint={@label_hint}
      help={@help}
      errors={@errors}
      for={@id}
      bare={true}
    >
      <:label_aside :if={@label_aside != []}>{render_slot(@label_aside)}</:label_aside>
      <span data-part="select" class={@box_class}>
        <.icon :if={@icon} name={@icon} class="text-muted" />
        <select
          id={@id}
          data-part="select-native"
          class={@select_class}
          name={@select_name || @name}
          multiple={@multiple}
          disabled={@disabled}
          aria-invalid={@errors != [] && "true"}
          {@rest}
        >
          <option :if={@prompt && !@multiple} value="">{@prompt}</option>
          <.native_option :for={o <- @opts} o={o} selected={@selected} />
        </select>
        {render_slot(@suffix)}
        <.icon :if={!@multiple} name="chevron-down" size="md" class="text-muted" />
      </span>
      {render_slot(@below)}
    </Options.shell>
    """
  end

  def select(assigns) do
    assigns = assign(assigns, :uses_label, true)
    select_listbox(assigns)
  end

  defp native_option(%{o: %{group: group, options: options}} = assigns) do
    assigns = assign(assigns, group: group, options: options)

    ~H"""
    <optgroup label={@group}>
      <.native_option :for={o <- @options} o={o} selected={@selected} />
    </optgroup>
    """
  end

  defp native_option(assigns) do
    ~H"""
    <option value={@o.value} selected={@o.value in @selected} disabled={@o.disabled}>
      {@o.label}
    </option>
    """
  end

  @doc false
  # The listbox shared by `select/1` and `LedgerUI.Components.Pillbox.pillbox/1`.
  def select_listbox(assigns) do
    assigns = Options.resolve(assigns, "select")
    pillbox? = Map.get(assigns, :pillbox, false)
    multiple? = assigns.multiple
    opts = Options.normalize(assigns.options)
    flat = Options.flatten(opts)
    selected = Options.values(assigns.value)
    selected = if multiple?, do: selected, else: Enum.take(selected, 1)

    known =
      Map.new(
        flat ++ Options.flatten(Options.normalize(Map.get(assigns, :selected_options, []))),
        &{&1.value, &1}
      )

    chosen =
      Enum.map(selected, fn v ->
        Map.get(known, v) || %{(Options.normalize([v]) |> hd()) | value: v}
      end)

    search =
      cond do
        pillbox? -> "panel"
        assigns.search == "auto" -> if multiple?, do: "panel", else: "control"
        true -> assigns.search
      end

    name =
      assigns.name &&
        if(multiple? && !String.ends_with?(assigns.name, "[]"),
          do: assigns.name <> "[]",
          else: assigns.name
        )

    one_line? =
      (multiple? || pillbox?) && Map.get(assigns, :overflow, "count") in ["count", "one"]

    chips? = multiple? || pillbox?
    state = if assigns.errors != [], do: "error"

    assigns =
      assigns
      |> assign(:opts, opts)
      |> assign(:selected, selected)
      |> assign(:chosen, chosen)
      |> assign(:search_mode, search)
      |> assign(:pillbox?, pillbox?)
      |> assign(:chips?, chips?)
      |> assign(:one_line?, one_line?)
      |> assign(:field_name, name)
      |> assign(:readonly, Map.get(assigns, :readonly, false))
      |> assign(:chevron, Map.get(assigns, :chevron, true))
      |> assign(:single_label, chosen |> List.first() |> then(&(&1 && &1.label)))
      |> assign(
        :box_class,
        if chips? do
          [
            "flex items-center gap-1.5 rounded-md border border-line-strong bg-panel px-2",
            if(one_line?, do: @pbox_fixed[assigns.size], else: @pbox_sizes[assigns.size]),
            if(one_line?, do: "flex-nowrap overflow-hidden", else: "flex-wrap")
          ]
        else
          [
            FieldBox.classes(
              if(assigns.variant == "filled", do: "filled", else: "outlined"),
              assigns.size,
              assigns.shape,
              state,
              assigns.disabled
            ),
            !assigns.disabled && "cursor-pointer"
          ]
        end
      )
      |> assign(:pop_style, assigns.panel_min_width && "min-width:#{assigns.panel_min_width}")
      |> assign(:total, length(flat))
      |> assign(:pop_id, assigns.id <> "-pop")
      |> assign(:cls_json, Options.js_classes())
      |> assign(:chip_class, Chip.chip_class(nil, false, "sm"))
      |> assign(:value_json, value_json(chosen))
      |> assign(:item_class, Options.item_class())
      |> assign(:control_class, FieldBox.control_class())
      |> assign(:check_color, Checkbox.color_vars("primary"))
      |> assign(:check_class, Checkbox.input_class("checkbox", "sm", "square", false, false))

    ~H"""
    <Options.shell
      tag="div"
      label={@label}
      help={@help}
      errors={@errors}
      for={@id}
      bare={true}
    >
      <div
        id={@id}
        data-part="select"
        class={["w-[260px]", @class]}
        phx-hook="LedgerUI.Select"
        data-lu-cls={@cls_json}
        data-lu-value={@value_json}
        data-lu-multiple={@multiple && ""}
        data-lu-search={@search_mode != "control" && @search_mode}
        data-lu-overflow={@multiple && @overflow == "wrap" && "wrap"}
        data-lu-removable={@removable && ""}
        data-lu-remove-label={@remove_label != "Remove" && @remove_label}
        data-lu-placeholder={@placeholder}
        data-lu-max={@max}
        data-lu-create={@create && ""}
        data-lu-create-label={@create && @create_label}
        data-lu-create-hint={@create && @create_hint}
        data-lu-persist={!@persist && "false"}
        data-lu-restore={@restore_on_backspace && ""}
        data-lu-on-search={@on_search}
        data-lu-debounce={@on_search && @debounce != 300 && @debounce}
        data-lu-target={@target && to_string(@target)}
        data-lu-on-load-more={@has_more && @on_load_more}
        data-lu-more-label={@more_label != "more" && @more_label}
        data-lu-no-results={@no_results != "No results found" && @no_results}
        data-lu-footer-count={@footer && @footer_count}
        data-lu-footer-hint={@footer && @footer_hint}
        data-lu-readonly={@readonly && ""}
        data-lu-pillbox={@pillbox? && ""}
        data-lu-disabled={@disabled && ""}
        {@rest}
      >
        <span
          class={["w-full", @box_class]}
          tabindex={if @disabled || @readonly, do: nil, else: "0"}
          role="combobox"
          aria-haspopup="listbox"
          aria-expanded={to_string(@open)}
          aria-controls={@pop_id}
          aria-labelledby={@label && @id <> "-label"}
          aria-invalid={@errors != [] && "true"}
          data-part="select-control"
          data-one={@one_line? && @chips?}
          phx-mounted={JS.ignore_attributes(["aria-expanded"])}
        >
          <.icon :if={@icon && !@chips?} name={@icon} class="text-muted" />
          <%= if @chips? do %>
            <span
              :for={c <- @chosen}
              data-part="select-chip"
              class={@chip_class}
              data-lu-value={c.value}
            >
              <Options.avatar
                :if={@pillbox? && (c.color || c.initials)}
                tone={c.tone || Options.avatar_tone(c.label)}
                color={c.color}
                initials={c.initials || Options.initials(c.label)}
                size={22}
              />
              {if @item != [], do: render_slot(@item, c), else: c.label}
              <button
                :if={@removable && !@readonly && !@disabled}
                type="button"
                data-part="select-chip-remove"
                class={Options.remove_class()}
                data-lu-remove={c.value}
                aria-label={"#{@remove_label} #{c.label}"}
              >
                <.icon name="x" size="sm" />
              </button>
            </span>
            <span
              :if={@chosen == [] && @placeholder}
              data-part="select-value"
              data-ph
              class="min-w-0 flex-1 truncate text-sm text-muted"
            >{@placeholder}</span>
          <% else %>
            <span
              data-part="select-value"
              data-ph={@chosen == [] && ""}
              class="min-w-0 flex-1 truncate text-sm data-ph:text-muted"
            >
              <%= cond do %>
                <% @chosen != [] && @item != [] -> %>
                  {render_slot(@item, hd(@chosen))}
                <% @chosen != [] -> %>
                  {@single_label}
                <% true -> %>
                  {@placeholder}
              <% end %>
            </span>
          <% end %>
          <input
            :if={@search_mode == "control" && !@disabled}
            type="text"
            data-part="select-search"
            class={@control_class}
            data-lu-q
            hidden
            autocomplete="off"
            placeholder={@placeholder}
            aria-label={@label || @placeholder}
          />
          <button
            :if={@clearable && @chosen != [] && !@readonly && !@disabled}
            type="button"
            data-part="select-clear"
            class="inline-grid cursor-pointer border-0 bg-transparent p-0 text-muted"
            data-lu-clear
            aria-label={@clear_label}
            title={@clear_label}
          >
            <.icon name="x" size="sm" />
          </button>
          <.icon
            :if={!@readonly && @chevron}
            name="chevron-down"
            size={if(@chips?, do: "sm", else: "md")}
            class="text-muted"
          />
        </span>
        <div
          id={@pop_id}
          data-part="select-panel"
          class={[Options.panel_class(), "mt-1.5", @panel_class]}
          {Options.style_attrs(@pop_style)}
          hidden={!@open}
          phx-mounted={JS.ignore_attributes(["hidden", "style"])}
        >
          <div
            :if={@search_mode == "panel"}
            data-part="select-panel-search"
            class={[
              FieldBox.classes("outlined", "sm", "rounded", nil, false),
              "mb-[5px]"
            ]}
          >
            <.icon name="search" size="md" class="text-muted" />
            <input
              type="text"
              data-part="select-search"
              class={@control_class}
              data-lu-q
              autocomplete="off"
              placeholder={@search_placeholder}
              aria-label={@search_placeholder}
            />
          </div>
          <div role="listbox" aria-multiselectable={@multiple && "true"} data-lu-list>
            <.option_row
              :for={o <- @opts}
              o={o}
              selected={@selected}
              option={@option}
              multiple={@multiple}
              pillbox={@pillbox?}
              item_class={@item_class}
              check_color={@check_color}
              check_class={@check_class}
            />
          </div>
          <div
            data-part="select-empty"
            class={Options.group_label_class()}
            data-lu-empty
            hidden
          >
            {Options.interpolate(@no_results, query: "")}
          </div>
          <button
            :if={@create}
            type="button"
            data-part="listbox-option"
            class={@item_class}
            data-lu-create-row
            hidden
          >{@create_label}</button>
          <div
            :if={@has_more && @on_load_more}
            data-part="select-loading"
            class={Options.group_label_class()}
            data-lu-loading
          >
            {@loading_label}
          </div>
          <div
            :if={@multiple && @footer}
            data-part="select-footer"
            class={Options.group_label_class()}
            data-lu-footer
          >
            <span data-lu-footer-count>
              {Options.interpolate(@footer_count, count: length(@selected), total: @total)}
            </span>
            <span class="float-right">{@footer_hint}</span>
          </div>
        </div>
        <select
          :if={@field_name}
          name={@field_name}
          multiple={@multiple}
          disabled={@disabled}
          hidden
          aria-hidden="true"
          tabindex="-1"
        >
          <option :if={@multiple} value="" selected></option>
          <option :for={c <- @chosen} value={c.value} selected>{c.label}</option>
        </select>
      </div>
    </Options.shell>
    """
  end

  # What the server drew as chosen, as `data-lu-value` on the root: the hook compares it with the one of
  # the last patch to tell a value the server changed from one it only drew again, and reads the chosen
  # (value and label) from it, never from nodes it has edited itself.
  defp value_json(chosen),
    do: Jason.encode!(Enum.map(chosen, &%{value: &1.value, label: &1.label}))

  attr :id, :string, default: nil

  attr :options, :list,
    required: true,
    doc:
      "Options as in `select/1`; a `{label, [options]}` group is set apart by a divider (its label is drawn when not empty)."

  attr :value, :any,
    default: nil,
    doc: "The chosen value (or list of values): its row is bold with a check."

  attr :label, :string, default: nil, doc: "Accessible name of the list."
  attr :class, :any, default: nil, doc: "Layout classes of the panel (`w-[280px]`)."
  slot :option, doc: "Content of a row (receives the normalized option)."

  @doc """
  A static list of choices (the open panel of a select, without the trigger): the chosen row is
  bold with a check, a `disabled` option is dimmed and a `hint` goes at the right.

      <.listbox value="pro" class="w-[280px]" options={[
        {"Pro", "pro"}, "Scale", "Starter",
        {"", [%{label: "Enterprise", hint: "Soon", disabled: true}]}]} />
  """
  def listbox(assigns) do
    assigns =
      assigns
      |> assign(:opts, Options.normalize(assigns.options))
      |> assign(:selected, Options.values(assigns.value))
      |> assign(:item_class, Options.item_class())

    ~H"""
    <div
      id={@id}
      data-part="listbox"
      role="listbox"
      aria-label={@label}
      class={[Options.panel_class(), @class]}
    >
      <.static_rows
        :for={{o, i} <- Enum.with_index(@opts)}
        o={o}
        i={i}
        selected={@selected}
        item_class={@item_class}
        option={@option}
      />
    </div>
    """
  end

  defp static_rows(%{o: %{group: group, options: options}} = assigns) do
    assigns = assign(assigns, group: group, options: options)

    ~H"""
    <div :if={@i > 0} data-part="listbox-separator" role="separator" class={Options.sep_class()}>
    </div>
    <div
      :if={@group != ""}
      data-part="listbox-group"
      class={Options.group_label_class()}
      role="presentation"
    >
      {@group}
    </div>
    <.static_rows
      :for={{o, j} <- Enum.with_index(@options)}
      o={o}
      i={j}
      selected={@selected}
      item_class={@item_class}
      option={@option}
    />
    """
  end

  defp static_rows(assigns) do
    assigns = assign(assigns, :sel?, assigns.o.value in assigns.selected)

    ~H"""
    <div
      data-part="listbox-option"
      role="option"
      class={@item_class}
      aria-selected={to_string(@sel?)}
      aria-disabled={@o.disabled && "true"}
    >
      <%= if @option != [] do %>
        {render_slot(@option, @o)}
      <% else %>
        {@o.label}
      <% end %>
      <span
        :if={@o.count || @o.hint || @sel?}
        data-part="listbox-option-right"
        class={Options.right_class()}
      >
        {@o.count || @o.hint}<.icon :if={@sel?} name="check" size="sm" class="text-accent-content" />
      </span>
    </div>
    """
  end

  defp option_row(%{o: %{group: group, options: options}} = assigns) do
    assigns = assign(assigns, group: group, options: options)

    ~H"""
    <div data-part="listbox-group" class={Options.group_label_class()} role="presentation">
      {@group}
    </div>
    <.option_row
      :for={o <- @options}
      o={o}
      selected={@selected}
      option={@option}
      multiple={@multiple}
      pillbox={@pillbox}
      item_class={@item_class}
      check_color={@check_color}
      check_class={@check_class}
    />
    """
  end

  defp option_row(assigns) do
    assigns = assign(assigns, :sel?, assigns.o.value in assigns.selected)

    ~H"""
    <button
      type="button"
      role="menuitem"
      data-part="listbox-option"
      class={@item_class}
      data-lu-value={@o.value}
      data-lu-label={@o.label}
      aria-selected={to_string(@sel?)}
      aria-disabled={@o.disabled && "true"}
    >
      <span
        :if={@pillbox && @multiple}
        data-part="listbox-option-check"
        class={["inline-flex", @check_color]}
        aria-hidden="true"
      >
        <input
          type="checkbox"
          tabindex="-1"
          checked={@sel?}
          class={["pointer-events-none", @check_class]}
        />
      </span>
      <Options.avatar
        :if={@pillbox && (@o.color || @o.initials)}
        tone={@o.tone || Options.avatar_tone(@o.label)}
        color={@o.color}
        initials={@o.initials || Options.initials(@o.label)}
        size={24}
      />
      <%= if @option != [] do %>
        {render_slot(@option, @o)}
      <% else %>
        {@o.label}
      <% end %>
      <span
        :if={@o.count || @o.hint || (@sel? && !@pillbox)}
        data-part="listbox-option-right"
        class={Options.right_class()}
      >
        {@o.count || @o.hint}<.icon
          :if={@sel? && !@pillbox}
          name="check"
          size="sm"
          class="text-accent-content"
        />
      </span>
    </button>
    """
  end
end
