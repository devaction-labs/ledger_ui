defmodule LedgerUI.Components.Pillbox do
  @moduledoc """
  Multiple (or single) choice drawn as pills inside the field, with a searchable list
  under it. It is the `LedgerUI.Components.Select` listbox (`multiple`, `search="panel"`)
  and shares its hook, `LedgerUI.Select` (`priv/static/ledger_ui/hooks/select.js`).

      <.pillbox field={@form[:categories]} label="Categories" options={@categories} />
      <.pillbox name="tags" options={@tags} value={@chosen} create create_label="Create" />
      <.pillbox name="branches" options={@branches} value={@chosen} overflow="wrap" />
      <.pillbox name="product_id" value={@product_id} options={@products} multiple={false} />

  The pills are submitted as `name[]` (an empty `name[]` first, so an emptied field still
  reaches the server); `multiple={false}` submits `name`. Each change fires a bubbling `input`
  event for `phx-change`. `readonly` keeps the values in the form but takes the x, the chevron
  and the list away; `disabled` also leaves them out of the form.

  Options may carry `:count` (a faint mono number at the right of the row) and `:color` /
  `:initials` (a person: the pill gets a 22px avatar).
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Select

  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :any, default: nil
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :options, :list, default: []
  attr :selected_options, :list, default: []
  attr :label, :string, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :multiple, :boolean, default: true
  attr :size, :string, default: "md", values: ~w(sm md lg)
  attr :panel_min_width, :string, default: nil
  attr :panel_class, :any, default: nil
  attr :placeholder, :string, default: nil
  attr :search_placeholder, :string, default: nil
  attr :overflow, :string, default: "one", values: ~w(one wrap)
  attr :create, :boolean, default: false
  attr :create_label, :string, default: nil
  attr :create_hint, :string, default: "↵"
  attr :empty_label, :string, default: nil

  attr :removable, :boolean,
    default: true,
    doc: "An x on each pill. `false` draws plain pills (they are still removed from the list)."

  attr :chevron, :boolean,
    default: true,
    doc: "The chevron at the end of the field. Without it more pills fit before the `+N`."

  attr :clear, :boolean, default: false
  attr :clear_label, :string, default: nil
  attr :remove_label, :string, default: nil
  attr :hidden_label, :string, default: nil
  attr :readonly, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :on_search, :string, default: nil
  attr :debounce, :integer, default: 300
  attr :target, :any, default: nil
  attr :on_load_more, :string, default: nil
  attr :has_more, :boolean, default: false
  attr :loading_label, :string, default: nil
  attr :open, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(form required)

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def pillbox(assigns) do
    assigns =
      I18n.texts(assigns,
        search_placeholder: "common.search_ellipsis",
        create_label: "pillbox.create",
        empty_label: "select.no_results",
        clear_label: "common.clear",
        remove_label: "common.remove",
        hidden_label: "pillbox.hidden",
        loading_label: "pillbox.loading"
      )

    assigns =
      assigns
      |> assign(:pillbox, true)
      |> assign(:removable, assigns.removable && !assigns.readonly && !assigns.disabled)
      |> assign(:clearable, assigns.clear && !assigns.readonly && !assigns.disabled)
      |> assign(:overflow, if(assigns.overflow == "wrap", do: "wrap", else: "count"))
      |> assign(:more_label, assigns.hidden_label)
      |> assign(:no_results, assigns.empty_label)
      |> assign(:search, "panel")
      |> assign(:persist, true)
      |> assign(:restore_on_backspace, false)
      |> assign(:max, nil)
      |> assign(:footer, false)
      |> assign(:footer_count, "")
      |> assign(:footer_hint, "")
      |> assign(:variant, "outline")
      |> assign(:shape, "rounded")
      |> assign(:icon, nil)
      |> assign(:item, [])
      |> assign(:option, [])

    Select.select_listbox(assigns)
  end
end
