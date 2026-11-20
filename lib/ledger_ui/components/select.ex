defmodule LedgerUI.Components.Select.Options do
  @moduledoc """
  Option shapes and form plumbing shared by `select`, `autocomplete`, `pillbox`,
  `tags_input`, `pill_select`, `segmented`, `checkbox_group` and `radio_group`.

  An option is one of

    * a string / number / atom: label and value are the same;
    * `{label, value}` (a keyword entry `[Alabama: "AL"]` is the same);
    * `{label, value, count}`;
    * a map with `:label` and `:value` (`:count`, `:hint`, `:disabled`, `:icon`,
      `:description`, `:color`, `:initials`; every other key goes to `data`);
    * `{group_label, [option]}`, a group.

  `normalize/1` returns a list of option maps (`%{label, value, disabled, hint, count,
  icon, description, color, initials, data}`; `value` is always a string) and
  `%{group: label, options: [option]}` entries.
  """
  use LedgerUI.Component

  @known ~w(label value count hint disabled icon description color initials)a

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

  @doc "Avatar tone class (`t1`..`t5`) taken from a name."
  def avatar_tone(name), do: "t#{rem(:erlang.phash2(name), 5) + 1}"

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
  def shell(assigns) do
    assigns =
      assigns
      |> assign(:wrap?, !assigns.bare || assigns.label || assigns.help || assigns.errors != [])
      |> assign(:cls, cx(["lu-field", assigns.class]))

    ~H"""
    <%= if @wrap? do %>
      <.dynamic_tag tag_name={@tag} class={@cls} data-part="field">
        <span :if={@label} class="lu-label" id={@for && @for <> "-label"}>
          {@label}<span :if={@label_hint} class="hint">{@label_hint}</span>{render_slot(@label_aside)}
        </span>
        {render_slot(@inner_block)}
        <span :if={@help} class="lu-help">{@help}</span>
        <span :for={error <- @errors} class="lu-help err">{error}</span>
      </.dynamic_tag>
    <% else %>
      {render_slot(@inner_block)}
    <% end %>
    """
  end
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

  `on_search` pushes `%{"id" => id, "query" => text}` (after `debounce` ms) and
  `on_load_more` pushes `%{"id" => id, "query" => text, "offset" => n}` to `target` or the
  LiveView.
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Select.Options

  @styles %{
    "variant" => %{"outline" => nil, "filled" => "filled"},
    "size" => %{"sm" => "sm", "md" => nil, "lg" => "lg"},
    "shape" => %{"rounded" => nil, "pill" => "pill"},
    "pbox_size" => %{"sm" => "sm", "md" => nil, "lg" => "lg"},
    "overflow" => %{"count" => "one", "one" => "one", "wrap" => nil}
  }

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
  attr :search, :string, default: "control", values: ~w(control panel none)
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

  def select(%{native: true} = assigns) do
    assigns = Options.resolve(assigns, "select")
    options = Options.normalize(assigns.options)
    selected = Options.values(assigns.value)

    assigns =
      assigns
      |> assign(:opts, options)
      |> assign(:selected, selected)
      |> assign(
        :box_class,
        cx([
          "lu-input",
          @styles["variant"][assigns.variant],
          @styles["size"][assigns.size],
          @styles["shape"][assigns.shape],
          assigns.class
        ])
      )
      |> assign(:box_style, if(assigns.inline, do: "width:auto;display:inline-flex"))
      |> assign(:select_name, assigns.name && assigns.multiple && assigns.name <> "[]")

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
      <:label_aside>{render_slot(@label_aside)}</:label_aside>
      <span class={@box_class} {Options.style_attrs(@box_style)}>
        <.icon :if={@icon} name={@icon} />
        <select
          id={@id}
          name={@select_name || @name}
          multiple={@multiple}
          disabled={@disabled}
          {@rest}
        >
          <option :if={@prompt && !@multiple} value="">{@prompt}</option>
          <.native_option :for={o <- @opts} o={o} selected={@selected} />
        </select>
        {render_slot(@suffix)}
        <.icon :if={!@multiple} name="chevron-down" size="sm" />
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

    search = if pillbox?, do: "panel", else: assigns.search

    name =
      assigns.name &&
        if(multiple? && !String.ends_with?(assigns.name, "[]"),
          do: assigns.name <> "[]",
          else: assigns.name
        )

    one_line? =
      (multiple? || pillbox?) && Map.get(assigns, :overflow, "count") in ["count", "one"]

    assigns =
      assigns
      |> assign(:opts, opts)
      |> assign(:selected, selected)
      |> assign(:chosen, chosen)
      |> assign(:search_mode, search)
      |> assign(:pillbox?, pillbox?)
      |> assign(:chips?, multiple? || pillbox?)
      |> assign(:field_name, name)
      |> assign(:readonly, Map.get(assigns, :readonly, false))
      |> assign(:single_label, chosen |> List.first() |> then(&(&1 && &1.label)))
      |> assign(
        :box_class,
        if multiple? || pillbox? do
          cx([
            "lu-pbox",
            one_line? && "one",
            @styles["pbox_size"][assigns.size],
            assigns.disabled && "disabled"
          ])
        else
          cx([
            "lu-input",
            @styles["variant"][assigns.variant],
            @styles["size"][assigns.size],
            @styles["shape"][assigns.shape],
            assigns.disabled && "disabled"
          ])
        end
      )
      |> assign(
        :pop_style,
        assigns.panel_min_width && "min-width:#{assigns.panel_min_width}"
      )
      |> assign(:total, length(flat))
      |> assign(:root_class, cx(["lu-sel2", assigns.class]))
      |> assign(:pop_id, assigns.id <> "-pop")

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
        class={@root_class}
        phx-hook="LedgerUI.Select"
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
        <div
          class={@box_class}
          style="width:100%"
          tabindex={if @disabled || @readonly, do: nil, else: "0"}
          role="combobox"
          aria-haspopup="listbox"
          aria-expanded={to_string(@open)}
          aria-controls={@pop_id}
          aria-labelledby={@label && @id <> "-label"}
          data-part="control"
          phx-mounted={JS.ignore_attributes(["aria-expanded"])}
        >
          <.icon :if={@icon && !@chips?} name={@icon} />
          <%= if @chips? do %>
            <span
              :for={c <- @chosen}
              class="lu-chip"
              style="height:24px"
              data-lu-value={c.value}
            >
              <.person :if={@pillbox? && (c.color || c.initials)} o={c} size={22} />
              {if @item != [], do: render_slot(@item, c), else: c.label}
              <button
                :if={@removable && !@readonly && !@disabled}
                type="button"
                data-lu-remove={c.value}
                aria-label={"#{@remove_label} #{c.label}"}
                style="border:0;background:none;padding:0;display:inline-grid;cursor:pointer;color:inherit"
              >
                <.icon name="x" size="sm" />
              </button>
            </span>
            <span :if={@chosen == [] && @placeholder} class="val ph">{@placeholder}</span>
          <% else %>
            <span class={["val", @chosen == [] && "ph"]}>
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
            data-lu-q
            hidden
            autocomplete="off"
            placeholder={@placeholder}
            aria-label={@label || @placeholder}
          />
          <button
            :if={@clearable && @chosen != [] && !@readonly && !@disabled}
            type="button"
            data-lu-clear
            aria-label={@clear_label}
            title={@clear_label}
            style="border:0;background:none;padding:0;display:inline-grid;cursor:pointer;color:var(--muted)"
          >
            <.icon name="x" size="sm" />
          </button>
          <.icon :if={!@readonly} name="chevron-down" size="sm" />
        </div>
        <div
          id={@pop_id}
          class={cx(["lu-pop", "menu", @panel_class])}
          {Options.style_attrs(@pop_style)}
          hidden={!@open}
          data-part="panel"
          phx-mounted={JS.ignore_attributes(["hidden", "style"])}
        >
          <div :if={@search_mode == "panel"} class="lu-input sm" style="margin-bottom:5px">
            <.icon name="search" size="md" />
            <input
              type="text"
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
            />
          </div>
          <div class="lu-menu-label" data-lu-empty hidden>
            {Options.interpolate(@no_results, query: "")}
          </div>
          <button type="button" class="lu-menu-item" data-lu-create-row hidden></button>
          <div :if={@has_more && @on_load_more} class="lu-menu-label" data-lu-loading>
            {@loading_label}
          </div>
          <div :if={@multiple && @footer} class="lu-menu-label" data-lu-footer>
            <span data-lu-footer-count>
              {Options.interpolate(@footer_count, count: length(@selected), total: @total)}
            </span>
            <span style="float:right">{@footer_hint}</span>
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

  defp person(assigns) do
    assigns = assign(assigns, :initials, assigns.o.initials || Options.initials(assigns.o.label))

    ~H"""
    <span
      class="lu-av"
      style={"--s:#{@size}px" <> if(@o.color, do: ";background:#{@o.color};color:#fff", else: "")}
    >{@initials}</span>
    """
  end

  defp option_row(%{o: %{group: group, options: options}} = assigns) do
    assigns = assign(assigns, group: group, options: options)

    ~H"""
    <div class="lu-menu-label" role="presentation">{@group}</div>
    <.option_row
      :for={o <- @options}
      o={o}
      selected={@selected}
      option={@option}
      multiple={@multiple}
      pillbox={@pillbox}
    />
    """
  end

  defp option_row(assigns) do
    assigns = assign(assigns, :sel?, assigns.o.value in assigns.selected)

    ~H"""
    <button
      type="button"
      role="menuitem"
      class={["lu-menu-item", @sel? && "sel"]}
      data-lu-value={@o.value}
      data-lu-label={@o.label}
      aria-disabled={@o.disabled && "true"}
    >
      <span :if={@pillbox && @multiple} class="lu-check c-primary s-sm" aria-hidden="true">
        <input type="checkbox" tabindex="-1" checked={@sel?} style="pointer-events:none" />
      </span>
      <.person :if={@pillbox && (@o.color || @o.initials)} o={@o} size={24} />
      <%= if @option != [] do %>
        {render_slot(@option, @o)}
      <% else %>
        {@o.label}
      <% end %>
      <span :if={@o.count || @o.hint || (@sel? && !@pillbox)} class="r">
        {@o.count || @o.hint}<.icon :if={@sel? && !@pillbox} name="check" size="sm" class="ck" />
      </span>
    </button>
    """
  end
end
