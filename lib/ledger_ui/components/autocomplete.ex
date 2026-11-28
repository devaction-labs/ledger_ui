defmodule LedgerUI.Components.Autocomplete do
  @moduledoc """
  A text input with a list of suggestions under it. The person types, the list narrows (or the
  server searches) and choosing a suggestion sets the field. Behaviour lives in the
  `LedgerUI.Autocomplete` hook (`priv/static/ledger_ui/hooks/autocomplete.js`).

      <.autocomplete field={@form[:customer_id]} label="Customer" options={@customers}
                     on_search="search_customers" placeholder="Pick a customer" clearable />

      <.autocomplete field={@form[:city]} options={["Salvador", "Santos"]} free_text />

  The choice is submitted through a hidden input named like the field; the visible input only
  shows the label. A bubbling `input` event fires from the hidden input, so a surrounding
  `phx-change` runs. With `free_text` the typed text is the value.

  Without `on_search` the list filters itself on the client (ignoring case and accents). With it
  the hook pushes `%{"id" => id, "query" => text}` (after `debounce` ms and `search_threshold`
  characters) to `target` or the LiveView, shows `loading_text` until the reply and the server
  answers by re-rendering `options`. Options may carry `:hint` (a dimmed note at the right),
  `:icon`, `:initials` (an avatar, `:tone` `"t1"`..`"t5"` picks its color, else taken from the label) and `:disabled`.
  """
  use LedgerUI.Component

  alias LedgerUI.Components.FieldBox
  alias LedgerUI.Components.Select.Options

  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :any, default: nil
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :label, :string, default: nil
  attr :label_hint, :string, default: nil, doc: "Muted text beside the label (`opcional`)."
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :options, :list, default: []
  attr :placeholder, :string, default: nil
  attr :disabled, :boolean, default: false
  attr :display_value, :string, default: nil
  attr :free_text, :boolean, default: false

  attr :on_search, :string,
    default: nil,
    doc: "An event name (a `%JS{}` raises: the event carries the text typed)."

  attr :debounce, :integer, default: 300

  attr :cache, :boolean,
    default: true,
    doc:
      "With `on_search`, the browser keeps the last 20 answers (per text) while the field is mounted: " <>
        "a text already searched shows its answer at once and is still sent to the server, which wins " <>
        "when it replies. `cache={false}` sends every text without showing earlier answers " <>
        "(for results that change all the time)."

  attr :search_threshold, :integer, default: 0
  attr :target, :any, default: nil
  attr :open_on_focus, :boolean, default: false
  attr :clearable, :boolean, default: false
  attr :clear_label, :string, default: nil
  attr :no_results, :string, default: nil
  attr :loading_text, :string, default: nil
  attr :create, :string, default: nil
  attr :on_create, :any, default: nil
  attr :size, :string, default: "md", values: ~w(sm md lg)
  attr :open, :boolean, default: false, doc: "Renders the list open (static previews)."
  attr :class, :any, default: nil

  attr :remote, :map,
    default: nil,
    doc:
      "`@remote.name` of `LedgerUI.Remote.attach/3`: fills `options`, `on_search`, `debounce` and, " <>
        "for a value no longer in the options, `display_value`."

  attr :rest, :global, include: ~w(autofocus form required)

  slot :option
  slot :prefix

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def autocomplete(assigns) do
    assigns = remote(assigns)
    changed0 = assigns.__changed__

    assigns =
      I18n.texts(assigns,
        clear_label: "common.clear",
        no_results: "select.no_results",
        loading_text: "autocomplete.loading"
      )

    assigns = Options.resolve(assigns, "autocomplete")
    Options.check_on_search!(assigns.on_search)
    opts = Options.normalize(assigns.options)
    flat = Options.flatten(opts)
    value = assigns.value |> Options.values() |> List.first()
    chosen = value && Enum.find(flat, &(&1.value == value))

    text =
      cond do
        chosen -> chosen.label
        assigns.display_value -> assigns.display_value
        assigns.free_text -> value || ""
        true -> ""
      end

    assigns =
      assigns
      |> assign(:opts, flat)
      |> assign(:val, value)
      |> assign(:rows, for({k, o} <- Options.keyed(flat), do: {k, o, o.value == value}))
      |> assign(:plain?, assigns.option == [] and Enum.all?(flat, &plain_option?/1))
      |> assign(:text, text)
      |> assign(
        :box_class,
        [
          FieldBox.classes(
            "outlined",
            assigns.size,
            "rounded",
            if(assigns.errors != [], do: "error"),
            assigns.disabled
          ),
          "w-full"
        ]
      )
      |> assign(:root_class, ["w-full", assigns.class])
      |> assign(:option_class, Options.option_class())
      |> assign(:label_class, Options.group_label_class())
      |> assign(:list_id, assigns.id <> "-list")
      |> assign(:on_create_js, on_create(assigns.on_create))
      |> assign(:no_results_text, Options.interpolate(assigns.no_results, query: ""))

    # The server answers a search by changing `options` only: the classes of the field are not sent
    # again. The options carry no class: the panel has the rule for them (`Options.option_class/0`,
    # descendant selectors, as in `select`), so a list of 100 options is not 100 copies of it.
    assigns =
      settle(assigns, changed0,
        id: [:field, :name, :label],
        name: [:field],
        value: [:field],
        errors: [:field],
        opts: [:options],
        val: [:value],
        rows: [:opts, :val],
        plain?: [:option, :opts],
        text: [:value, :options, :display_value, :free_text],
        box_class: [:size, :errors, :disabled],
        root_class: [:class],
        option_class: [],
        label_class: [],
        list_id: [:id],
        on_create_js: [:on_create],
        no_results_text: [:no_results]
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
      <div
        id={@id}
        data-part="autocomplete"
        class={@root_class}
        phx-hook="LedgerUI.Autocomplete"
        data-lu-free={@free_text && ""}
        data-lu-on-search={@on_search}
        data-lu-debounce={@on_search && @debounce != 300 && @debounce}
        data-lu-cache={@on_search && !@cache && "false"}
        data-lu-threshold={@on_search && @search_threshold > 0 && @search_threshold}
        data-lu-target={@target && to_string(@target)}
        data-lu-open-on-focus={@open_on_focus && ""}
        data-lu-no-results={I18n.non_default(@no_results, "select.no_results")}
        data-lu-create={@create}
        data-lu-on-create={@on_create_js}
        data-lu-disabled={@disabled && ""}
      >
        <span class={@box_class} data-part="autocomplete-control">
          <.icon :if={@prefix == []} name="search" size="md" class="text-ink" />
          {render_slot(@prefix)}
          <input
            type="text"
            data-part="autocomplete-input"
            class={FieldBox.control_class()}
            id={@id <> "-input"}
            role="combobox"
            aria-autocomplete="list"
            aria-expanded={to_string(@open)}
            aria-controls={@list_id}
            aria-labelledby={@label && @id <> "-label"}
            autocomplete="off"
            value={@text}
            placeholder={@placeholder}
            disabled={@disabled}
            data-lu-q
            {@rest}
          />
          <button
            :if={@clearable && !@disabled}
            type="button"
            data-part="autocomplete-clear"
            class="inline-grid cursor-pointer border-0 bg-transparent p-0 text-muted"
            data-lu-clear
            hidden={@text == ""}
            aria-label={@clear_label}
            title={@clear_label}
          >
            <.icon name="x" size="sm" />
          </button>
        </span>
        <div
          id={@list_id}
          class={[Options.panel_class(), "mt-1.5", @option_class]}
          role="listbox"
          hidden={!@open}
          data-part="autocomplete-panel"
          phx-mounted={JS.ignore_attributes(["hidden", "style"])}
        >
          <div data-lu-list phx-no-format>
            <%= if @plain? do %><button
              :for={{k, o, sel} <- @rows}
              :key={k}
              type="button"
              role="option"
              id={Options.opt_id(@list_id, o.value)}
              data-part="listbox-option"
              data-lu-value={o.value}
              data-lu-label={o.label}
              aria-selected={to_string(sel)}
            >
              
              
              
                <span data-lu-lbl>{o.label}</span>
              
              
            </button><% else %><button
              :for={{k, o, sel} <- @rows}
              :key={k}
              type="button"
              role="option"
              id={Options.opt_id(@list_id, o.value)}
              data-part="listbox-option"
              data-lu-value={o.value}
              data-lu-label={o.label}
              aria-selected={to_string(sel)}
              aria-disabled={o.disabled && "true"}
            >
              <.icon :if={o.icon} name={o.icon} class="text-ink" />
              <Options.avatar
                :if={o.initials}
                tone={o.tone || Options.avatar_tone(o.label)}
                initials={o.initials}
                size={24}
              />
              <%= if @option != [] do %>
                {render_slot(@option, o)}
              <% else %>
                <span data-lu-lbl>{o.label}</span>
              <% end %>
              <span :if={o.hint} data-part="listbox-option-right" class={Options.right_class()}>
                {o.hint}
              </span>
            </button><% end %>
          </div>
          <div
            data-part="autocomplete-empty"
            class={@label_class}
            role="status"
            data-lu-empty
            hidden
          >
            {@no_results_text}
          </div>
          <div
            data-part="autocomplete-loading"
            class={@label_class}
            role="status"
            data-lu-loading
            hidden
          >
            <span class="inline-grid animate-[lu-spin_1.2s_linear_infinite] align-middle">
              <.icon name="refresh" size="sm" />
            </span>
            {@loading_text}
          </div>
          <div :if={@create} class={Options.sep_class()} data-lu-create-sep hidden></div>
          <button
            :if={@create}
            type="button"
            role="option"
            id={@list_id <> "-create"}
            data-part="listbox-option"
            data-lu-create-row
            hidden
          ></button>
        </div>
        <input
          :if={@name}
          type="hidden"
          name={@name}
          value={@val || (@free_text && @text) || ""}
          data-lu-v
        />
      </div>
    </Options.shell>
    """
  end

  # No icon, avatar, hint, disabled flag or slot: the row has only the value, the label and `aria-selected`.
  defp remote(%{remote: %{}} = assigns) do
    assigns = LedgerUI.Remote.apply(assigns)

    case assigns.display_value || LedgerUI.Remote.display_value(assigns) do
      nil -> assigns
      label -> assign(assigns, :display_value, label)
    end
  end

  defp remote(assigns), do: assigns

  defp plain_option?(o), do: !(o.icon || o.initials || o.hint || o.disabled)

  defp on_create(nil), do: nil
  defp on_create(name) when is_binary(name), do: name

  defp on_create(%Phoenix.LiveView.JS{} = js),
    do: LedgerUI.Helpers.js_json(js)
end
