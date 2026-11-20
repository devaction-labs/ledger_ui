defmodule LedgerUI.Components.TagsInput do
  @moduledoc """
  A tag input: what is typed becomes a tag on Enter, Tab or a comma (pasting a comma separated
  list creates several); tags are removed with Backspace or their remove button. Behaviour lives
  in the `LedgerUI.TagsInput` hook (`priv/static/ledger_ui/hooks/tags_input.js`).

      <.tags_input label="Tags" placeholder="Enter tags" field={@form[:tags]} removable />
      <.tags_input name="tags" value={["awesome", "neat"]} removable restore_on_backspace />
      <.tags_input name="tags" value="clear,items" clearable max={5} />

  `value` is a list of strings or a comma separated string. The tags are submitted as `name[]`
  (plus an empty `name[]`, so an empty list still reaches the server) through a hidden
  `<select multiple>`, and each change fires a bubbling `input` event for `phx-change`.
  `suggestions` (or `options`) are offered in the list while typing; with `create={false}` only
  listed options can be chosen and `on_search` pushes `%{"id" => id, "query" => text}` to
  `target` (or the LiveView), which answers by re-rendering `options`.
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Select.Options

  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :any, default: nil
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :label, :string, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :placeholder, :string, default: nil
  attr :suggestions, :list, default: []
  attr :options, :list, default: nil
  attr :selected_options, :list, default: []
  attr :create, :boolean, default: true
  attr :on_search, :string, default: nil
  attr :debounce, :integer, default: 300
  attr :removable, :boolean, default: false
  attr :clearable, :boolean, default: false
  attr :clear_label, :string, default: "Clear"
  attr :remove_label, :string, default: "Remove"
  attr :create_label, :string, default: "Add"
  attr :persist, :boolean, default: true
  attr :restore_on_backspace, :boolean, default: false
  attr :create_hint, :string, default: "Enter"
  attr :max, :integer, default: nil
  attr :counter, :boolean, default: true
  attr :limit_placeholder, :string, default: "Limit reached"
  attr :create_position, :string, default: "top", values: ~w(top bottom)
  attr :compact, :boolean, default: false
  attr :no_results, :string, default: "No results found"
  attr :disabled, :boolean, default: false
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(form)

  slot :item
  slot :option

  def tags_input(assigns) do
    assigns = Options.resolve(assigns, "tags-input")
    opts = Options.normalize(assigns.options || assigns.suggestions)
    flat = Options.flatten(opts)

    known =
      Map.new(
        flat ++ Options.flatten(Options.normalize(assigns.selected_options)),
        &{&1.value, &1}
      )

    values = Options.csv_values(assigns.value)
    tags = Enum.map(values, fn v -> Map.get(known, v) || %{label: v, value: v} end)
    at_max? = assigns.max != nil && length(tags) >= assigns.max

    name =
      assigns.name &&
        if(String.ends_with?(assigns.name, "[]"), do: assigns.name, else: assigns.name <> "[]")

    assigns =
      assigns
      |> assign(:opts, flat)
      |> assign(:tags, tags)
      |> assign(:selected_values, values)
      |> assign(:at_max?, at_max?)
      |> assign(:field_name, name)
      |> assign(:pop_id, assigns.id <> "-pop")
      |> assign(:locked?, assigns.disabled)
      |> assign(:pop?, flat != [] || assigns.on_search != nil || assigns.options != nil)

    ~H"""
    <Options.shell
      tag="label"
      label={@label}
      help={@help}
      errors={@errors}
      for={@id}
      bare={false}
      class={@class}
    >
      <span
        class="lu-input"
        style="height:auto;min-height:38px;padding:5px 8px;flex-wrap:wrap;gap:6px"
        id={@id}
        phx-hook="LedgerUI.TagsInput"
        data-lu-create={!@create && "false"}
        data-lu-removable={@removable && @tags == [] && ""}
        data-lu-remove-label={@tags == [] && @remove_label != "Remove" && @remove_label}
        data-lu-create-label={@create_label != "Add" && @create_label}
        data-lu-create-hint={@create_hint != "Enter" && (@create_hint || "")}
        data-lu-create-position={@create_position == "bottom" && "bottom"}
        data-lu-max={@max}
        data-lu-limit-placeholder={@max && @limit_placeholder}
        data-lu-persist={!@persist && "false"}
        data-lu-restore={@restore_on_backspace && ""}
        data-lu-on-search={@on_search}
        data-lu-debounce={@on_search && @debounce != 300 && @debounce}
        data-lu-target={@target && to_string(@target)}
        data-lu-no-results={@no_results != "No results found" && @no_results}
        data-lu-compact={@compact && ""}
        data-lu-disabled={@disabled && ""}
        data-lu-placeholder={@max && @placeholder}
        {@rest}
      >
        <span :for={t <- @tags} class="lu-tag" data-lu-value={t.value != t.label && t.value}>
          <%= if @item != [] do %>
            {render_slot(@item, t)}
          <% else %>
            {t.label}
          <% end %>
          <button
            :if={@removable && !@locked?}
            type="button"
            data-lu-remove=""
            aria-label={@remove_label}
          >
            <.icon name="x" size="sm" />
          </button>
        </span>
        <input
          placeholder={if @at_max?, do: @limit_placeholder, else: @placeholder}
          style="min-width:160px;height:26px"
          disabled={@disabled || @at_max?}
        />
        <button
          :if={@clearable && !@locked? && @tags != []}
          type="button"
          data-lu-clear
          aria-label={@clear_label}
          title={@clear_label}
          style="border:0;background:none;padding:0;display:inline-grid;cursor:pointer;color:var(--muted);margin-left:auto"
        >
          <.icon name="x" size="sm" />
        </button>
        <div
          :if={@pop?}
          id={@pop_id}
          class="lu-pop"
          hidden
          data-part="panel"
          phx-mounted={JS.ignore_attributes(["hidden", "style"])}
        >
          <div data-lu-list>
            <button
              :for={o <- @opts}
              type="button"
              role="menuitem"
              class="lu-menu-item"
              data-lu-value={o.value}
              data-lu-label={o.label}
              data-lu-hint={o.hint}
              aria-disabled={o.disabled && "true"}
            >
              <%= if @option != [] do %>
                {render_slot(@option, o)}
              <% else %>
                {o.label}
              <% end %>
              <span :if={o.hint} class="r">{o.hint}</span>
            </button>
          </div>
          <button type="button" class="lu-menu-item" data-lu-create-row hidden></button>
          <div class="lu-menu-label" data-lu-empty hidden>
            {Options.interpolate(@no_results, query: "")}
          </div>
        </div>
        <select
          :if={@field_name}
          name={@field_name}
          multiple
          hidden
          aria-hidden="true"
          tabindex="-1"
          disabled={@disabled}
        >
          <option value="" selected></option>
          <option :for={t <- @tags} value={t.value} selected>{t.label}</option>
        </select>
      </span>
      <span
        :if={@max && @counter}
        class="lu-help"
        data-lu-counter
        hidden={!@at_max?}
        style="text-align:right"
      >
        {length(@tags)} / {@max}
      </span>
    </Options.shell>
    """
  end
end
