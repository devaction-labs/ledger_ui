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

  alias LedgerUI.Components.Chip
  alias LedgerUI.Components.FieldBox
  alias LedgerUI.Components.Select.Options

  # the tags are the chips of the design (11px sides, 24px high), concentric to the field (see `FieldBox.chip_class/2`)
  @tag_remove Chip.remove_class()

  defp cls_json(shape) do
    Jason.encode!(%{
      tag: cx(FieldBox.chip_class("md", shape)),
      remove: @tag_remove,
      right: Options.right_class(),
      icon:
        "inline flex-none fill-none stroke-current stroke-[1.75] [stroke-linecap:round] [stroke-linejoin:round] align-middle size-3.5"
    })
  end

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
  attr :clear_label, :string, default: nil
  attr :remove_label, :string, default: nil
  attr :create_label, :string, default: nil
  attr :persist, :boolean, default: true
  attr :restore_on_backspace, :boolean, default: false
  attr :create_hint, :string, default: nil
  attr :max, :integer, default: nil
  attr :counter, :boolean, default: true
  attr :limit_placeholder, :string, default: nil
  attr :create_position, :string, default: "top", values: ~w(top bottom)
  attr :compact, :boolean, default: false

  attr :loop, :boolean,
    default: false,
    doc:
      "Demo animation (CSS only): the last tag fades in and `loop_text` is typed after it, over and over."

  attr :loop_text, :string, default: nil, doc: "The text typed by `loop`."
  attr :no_results, :string, default: nil

  attr :shape, :string,
    default: "rounded",
    values: ~w(rounded pill),
    doc: "Shape of the field; the tags follow it."

  attr :disabled, :boolean, default: false
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(form)

  slot :item
  slot :option

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def tags_input(assigns) do
    changed0 = assigns.__changed__

    assigns =
      I18n.texts(assigns,
        clear_label: "common.clear",
        remove_label: "common.remove",
        create_label: "select.add",
        create_hint: "tags.enter",
        limit_placeholder: "tags.limit",
        no_results: "select.no_results"
      )

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
      |> assign(
        :box_class,
        FieldBox.classes(
          "outlined",
          "md",
          assigns.shape,
          if(assigns.errors != [], do: "error"),
          assigns.disabled,
          free_height: true,
          gap: "gap-1.5"
        )
        |> List.wrap()
        |> then(&["flex-wrap" | &1])
      )
      |> assign(:tag_class, cx(FieldBox.chip_class("md", assigns.shape)))
      |> assign(:tag_remove_class, @tag_remove)
      |> assign(:option_class, Options.option_class())
      |> assign(:cls_json, cls_json(assigns.shape))

    assigns =
      settle(assigns, changed0,
        id: [:field, :name, :label],
        opts: [:options, :suggestions],
        tags: [:options, :suggestions, :selected_options, :value],
        selected_values: [:value],
        at_max?: [:max, :tags],
        field_name: [:name],
        pop_id: [:id],
        locked?: [:disabled],
        pop?: [:opts, :on_search, :options],
        box_class: [:shape, :errors, :disabled],
        tag_class: [:shape],
        tag_remove_class: [],
        option_class: [],
        cls_json: [:shape]
      )

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
        data-part="tags-input"
        class={@box_class}
        id={@id}
        phx-hook="LedgerUI.TagsInput"
        data-lu-cls={@cls_json}
        data-lu-create={!@create && "false"}
        data-lu-removable={@removable && @tags == [] && ""}
        data-lu-remove-label={@tags == [] && I18n.non_default(@remove_label, "common.remove")}
        data-lu-create-label={I18n.non_default(@create_label, "select.add")}
        data-lu-create-hint={I18n.non_default(@create_hint, "tags.enter")}
        data-lu-create-position={@create_position == "bottom" && "bottom"}
        data-lu-max={@max}
        data-lu-limit-placeholder={@max && @limit_placeholder}
        data-lu-persist={!@persist && "false"}
        data-lu-restore={@restore_on_backspace && ""}
        data-lu-on-search={@on_search}
        data-lu-debounce={@on_search && @debounce != 300 && @debounce}
        data-lu-target={@target && to_string(@target)}
        data-lu-no-results={I18n.non_default(@no_results, "select.no_results")}
        data-lu-compact={@compact && ""}
        data-lu-disabled={@disabled && ""}
        data-lu-placeholder={@max && @placeholder}
        {@rest}
      >
        <span
          :for={{t, i} <- Enum.with_index(@tags)}
          data-part="tags-input-tag"
          class={[
            @tag_class,
            @loop && i == length(@tags) - 1 &&
              "animate-[mo-stg_6s_cubic-bezier(.2,.8,.2,1)_infinite]"
          ]}
          data-lu-value={t.value != t.label && t.value}
        >
          <%= if @item != [] do %>
            {render_slot(@item, t)}
          <% else %>
            {t.label}
          <% end %>
          <button
            :if={@removable && !@locked?}
            type="button"
            data-part="tags-input-tag-remove"
            class={@tag_remove_class}
            data-lu-remove=""
            aria-label={@remove_label}
          >
            <.icon name="x" size="sm" />
          </button>
        </span>
        <span
          :if={@loop && @loop_text}
          data-part="tags-input-typing"
          class="inline-block max-w-0 animate-[lu-typeloop_6s_steps(var(--steps,24))_infinite] overflow-hidden align-bottom text-sm whitespace-nowrap"
          style={"--steps:#{String.length(@loop_text)}"}
        >{@loop_text}</span>
        <input
          data-part="tags-input-control"
          class="h-[26px] min-w-[72px] flex-1 appearance-none border-0 bg-transparent p-0 text-sm outline-0"
          placeholder={if @at_max?, do: @limit_placeholder, else: @placeholder}
          disabled={@disabled || @at_max?}
          role={@pop? && "combobox"}
          aria-haspopup={@pop? && "listbox"}
          aria-autocomplete={@pop? && "list"}
          aria-controls={@pop? && @pop_id}
          aria-expanded={@pop? && "false"}
        />
        <button
          :if={@clearable && !@locked? && @tags != []}
          type="button"
          data-part="tags-input-clear"
          class="ml-auto inline-grid cursor-pointer border-0 bg-transparent p-0 text-muted"
          data-lu-clear
          aria-label={@clear_label}
          title={@clear_label}
        >
          <.icon name="x" size="sm" />
        </button>
        <div
          :if={@pop?}
          id={@pop_id}
          class={[Options.panel_class(), @option_class]}
          role="listbox"
          aria-multiselectable="true"
          hidden
          data-part="tags-input-panel"
          phx-mounted={JS.ignore_attributes(["hidden", "style"])}
        >
          <div data-lu-list>
            <button
              :for={o <- @opts}
              type="button"
              role="option"
              id={Options.opt_id(@pop_id, o.value)}
              data-part="listbox-option"
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
              <span :if={o.hint} data-part="listbox-option-right" class={Options.right_class()}>
                {o.hint}
              </span>
            </button>
          </div>
          <button
            :if={@create}
            type="button"
            role="option"
            id={@pop_id <> "-create"}
            data-part="listbox-option"
            data-lu-create-row
            hidden
          >{@create_label}</button>
          <div data-part="tags-input-empty" class={Options.group_label_class()} data-lu-empty hidden>
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
        data-part="tags-input-counter"
        class="text-right text-[12.5px] leading-[17px] text-muted"
        data-lu-counter
        hidden={!@at_max?}
      >
        {length(@tags)} / {@max}
      </span>
    </Options.shell>
    """
  end
end
