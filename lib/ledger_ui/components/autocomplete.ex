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

  alias LedgerUI.Components.Select.Options

  @styles %{"size" => %{"sm" => "sm", "md" => nil, "lg" => "lg"}}

  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :any, default: nil
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :label, :string, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :options, :list, default: []
  attr :placeholder, :string, default: nil
  attr :disabled, :boolean, default: false
  attr :display_value, :string, default: nil
  attr :free_text, :boolean, default: false
  attr :on_search, :string, default: nil
  attr :debounce, :integer, default: 300
  attr :search_threshold, :integer, default: 0
  attr :target, :any, default: nil
  attr :open_on_focus, :boolean, default: false
  attr :clearable, :boolean, default: false
  attr :clear_label, :string, default: "Clear"
  attr :no_results, :string, default: "No results found"
  attr :loading_text, :string, default: "Searching…"
  attr :create, :string, default: nil
  attr :on_create, :any, default: nil
  attr :size, :string, default: "md", values: ~w(sm md lg)
  attr :open, :boolean, default: false, doc: "Renders the list open (static previews)."
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(autofocus form required)

  slot :option
  slot :prefix

  def autocomplete(assigns) do
    assigns = Options.resolve(assigns, "autocomplete")
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
      |> assign(:text, text)
      |> assign(:box_class, cx(["lu-input", @styles["size"][assigns.size]]))
      |> assign(:root_class, cx(["lu-sel2", assigns.class]))
      |> assign(:list_id, assigns.id <> "-list")
      |> assign(:on_create_js, on_create(assigns.on_create))
      |> assign(:no_results_text, Options.interpolate(assigns.no_results, query: ""))

    ~H"""
    <Options.shell tag="div" label={@label} help={@help} errors={@errors} for={@id} bare={true}>
      <div
        id={@id}
        class={@root_class}
        style="width:100%"
        phx-hook="LedgerUI.Autocomplete"
        data-lu-free={@free_text && ""}
        data-lu-on-search={@on_search}
        data-lu-debounce={@on_search && @debounce != 300 && @debounce}
        data-lu-threshold={@on_search && @search_threshold > 0 && @search_threshold}
        data-lu-target={@target && to_string(@target)}
        data-lu-open-on-focus={@open_on_focus && ""}
        data-lu-no-results={@no_results != "No results found" && @no_results}
        data-lu-create={@create}
        data-lu-on-create={@on_create_js}
        data-lu-disabled={@disabled && ""}
      >
        <span class={@box_class} style="width:100%" data-part="control">
          <.icon :if={@prefix == []} name="search" size="md" />
          {render_slot(@prefix)}
          <input
            type="text"
            id={@id <> "-input"}
            role="combobox"
            aria-autocomplete="list"
            aria-expanded={to_string(@open)}
            aria-controls={@list_id}
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
            data-lu-clear
            hidden={@text == ""}
            aria-label={@clear_label}
            title={@clear_label}
            style="border:0;background:none;padding:0;display:inline-grid;cursor:pointer;color:var(--muted)"
          >
            <.icon name="x" size="sm" />
          </button>
        </span>
        <div
          id={@list_id}
          class="lu-pop"
          role="listbox"
          hidden={!@open}
          data-part="panel"
          phx-mounted={JS.ignore_attributes(["hidden", "style"])}
        >
          <div data-lu-list>
            <button
              :for={o <- @opts}
              type="button"
              role="option"
              class={["lu-menu-item", o.value == @val && "sel"]}
              data-lu-value={o.value}
              data-lu-label={o.label}
              aria-disabled={o.disabled && "true"}
            >
              <.icon :if={o.icon} name={o.icon} />
              <span
                :if={o.initials}
                class={["lu-av", o.tone || Options.avatar_tone(o.label)]}
                style="--s:24px"
              >
                {o.initials}
              </span>
              <%= if @option != [] do %>
                {render_slot(@option, o)}
              <% else %>
                <span data-lu-lbl>{o.label}</span>
              <% end %>
              <span :if={o.hint} class="r">{o.hint}</span>
            </button>
          </div>
          <div class="lu-menu-label" role="status" data-lu-empty hidden>{@no_results_text}</div>
          <div class="lu-menu-label" role="status" data-lu-loading hidden>
            <span class="mo-spin" style="display:inline-grid;vertical-align:middle">
              <.icon name="refresh" size="sm" />
            </span>
            {@loading_text}
          </div>
          <div :if={@create} class="lu-menu-sep" data-lu-create-sep hidden></div>
          <button :if={@create} type="button" class="lu-menu-item" data-lu-create-row hidden></button>
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

  defp on_create(nil), do: nil
  defp on_create(name) when is_binary(name), do: name

  defp on_create(%Phoenix.LiveView.JS{} = js),
    do: Phoenix.json_library().encode!(js.ops)
end
