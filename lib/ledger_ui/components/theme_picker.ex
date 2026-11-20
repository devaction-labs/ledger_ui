defmodule LedgerUI.Components.ThemePicker do
  @moduledoc """
  Lets the user choose a named palette: a menu in the top bar or a grid of previews on a settings
  page. Each option previews its own colors.

      <.theme_picker id="palette" />
      <.theme_picker id="palette" variant="grid" />
      <.theme_picker id="palette" themes={~w(ledger noite)} label="Tema" />

  The palette is apart from the mode: `theme_switch/1` picks light, dark or system, the picker
  picks which palette. The `LedgerUI.ThemePicker` hook puts the choice on
  `<html data-palette>`, keeps it in `localStorage["ledger-theme"]`, marks the option and tells every
  picker through the `ledger:palette` window event. `on_change` also pushes `%{"theme" => id}` to
  the LiveView. Put `<.theme_script theme="..." />` in the root layout so the stored palette is on
  before the first paint.

  `themes` takes ids of the built-in list (`themes/0`) or maps `%{id, label}` (optionally `bg`,
  `accent`, `ink` for the preview).
  """
  use LedgerUI.Component

  @themes [
    %{id: "ledger", label: "Ledger", bg: "#ffffff", accent: "#1f9282", ink: "#141514"},
    %{id: "noite", label: "Noite", bg: "#0e100f", accent: "#2fa792", ink: "#f2f3f2"},
    %{id: "areia", label: "Areia", bg: "#faf6ef", accent: "#b07a2c", ink: "#2a2017"},
    %{id: "oceano", label: "Oceano", bg: "#f3f8fc", accent: "#2d6fb7", ink: "#0f1e2e"},
    %{id: "graphite", label: "Graphite", bg: "#f4f4f2", accent: "#3b3d3b", ink: "#141514"},
    %{id: "amber", label: "Amber", bg: "#f8f4ec", accent: "#c9821a", ink: "#2a1d08"},
    %{id: "rose", label: "Rose", bg: "#faf2f3", accent: "#cc3a52", ink: "#2b0f15"}
  ]
  @by_id Map.new(@themes, &{&1.id, &1})

  @doc "The built-in themes."
  def themes, do: @themes

  attr :id, :string, required: true
  attr :variant, :string, default: "menu", values: ~w(menu grid)
  attr :themes, :list, default: nil, doc: "Ids or `%{id, label}` maps; default `themes/0`."
  attr :default, :string, default: nil, doc: "The theme shown when nothing is stored."
  attr :label, :string, default: "Theme"
  attr :placement, :string, default: "bottom-end", values: ~w(bottom-end bottom-start)
  attr :on_change, :string, default: nil
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  def theme_picker(assigns) do
    list = normalize(assigns.themes)

    default =
      assigns.default || Application.get_env(:ledger_ui, :theme) || List.first(list).id

    assigns =
      assigns
      |> assign(:list, Enum.with_index(list))
      |> assign(:selected, default)
      |> assign(:on_change_attr, assigns.on_change)

    case assigns.variant do
      "grid" -> grid(assigns)
      _ -> menu(assigns)
    end
  end

  defp grid(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="LedgerUI.ThemePicker"
      data-lu-variant="grid"
      data-lu-label={@label}
      data-lu-on-change={@on_change_attr}
      data-lu-target={is_binary(@target) && @target}
      data-part="theme-picker"
      class={cx(["lu-row lu-themes", @class])}
      style="gap:12px"
      {@rest}
    >
      <div
        :for={{t, i} <- @list}
        class={cx(["lu-themebox", t.id == @selected && "on"])}
        style={"--dl:#{i * 2}s"}
        data-lu-theme={t.id}
      >
        <div class="pv" style={"background:#{t.bg}"}>
          <i style={"background:#{t.accent}"}></i>
          <i style={"background:#{t.ink};opacity:.85"}></i>
          <i style={"background:#{t.accent};opacity:.4"}></i>
        </div>
        <div class="nm">
          <span>{t.label}</span>
          <.icon :if={t.id == @selected} name="check" size="sm" />
        </div>
      </div>
    </div>
    """
  end

  defp menu(assigns) do
    assigns =
      assign(
        assigns,
        :pos,
        if(assigns.placement == "bottom-start", do: "left:0", else: "right:0")
      )

    ~H"""
    <div
      id={@id}
      phx-hook="LedgerUI.ThemePicker"
      data-lu-variant="menu"
      data-lu-label={@label}
      data-lu-on-change={@on_change_attr}
      data-lu-target={is_binary(@target) && @target}
      data-part="theme-picker"
      class={cx(["lu-theme-menu", @class])}
      style="position:relative;display:inline-block"
      phx-click-away={JS.hide(to: "##{@id}-pop")}
      {@rest}
    >
      <button
        type="button"
        class="lu-tbtn"
        aria-label={@label}
        aria-haspopup="menu"
        aria-controls={"#{@id}-pop"}
        phx-click={JS.toggle(to: "##{@id}-pop")}
      >
        <.icon name="palette" />
      </button>
      <div
        id={"#{@id}-pop"}
        class="lu-pop"
        role="menu"
        aria-label={@label}
        style={"position:absolute;top:calc(100% + 6px);z-index:50;width:200px;#{@pos}"}
        hidden
        keep-hidden
      >
        <button
          :for={{t, _i} <- @list}
          type="button"
          role="menuitem"
          class={cx(["lu-menu-item", t.id == @selected && "sel"])}
          data-lu-theme={t.id}
        >
          {t.label}<span :if={t.id == @selected} class="r"><.icon name="check" size="sm" class="ck" /></span>
        </button>
      </div>
    </div>
    """
  end

  defp normalize(nil), do: @themes

  defp normalize(list) do
    Enum.map(list, fn
      id when is_binary(id) ->
        Map.get(@by_id, id, %{
          id: id,
          label: String.capitalize(id),
          bg: "#ffffff",
          accent: "#888888",
          ink: "#141514"
        })

      %{id: id} = map ->
        base =
          Map.get(@by_id, id, %{
            label: String.capitalize(id),
            bg: "#ffffff",
            accent: "#888888",
            ink: "#141514"
          })

        Map.merge(base, map)
    end)
  end
end
