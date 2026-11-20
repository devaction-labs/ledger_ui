defmodule LedgerUI.Components.ThemePicker do
  @moduledoc """
  Lets the user choose a named palette: a menu in the top bar or a grid of previews on a settings
  page. Each option previews its own colors.

      <.theme_picker id="palette" />
      <.theme_picker id="palette" variant="grid" />
      <.theme_picker id="palette" themes={~w(ledger noite)} label="Tema" />

  The palette is apart from the mode: `theme_switch/1` picks light, dark or system, the picker
  picks which palette. The `LedgerUI.ThemePicker` hook puts the choice on
  `<html data-palette>`, keeps it in `localStorage["ledger-palette"]`, marks the option and tells every
  picker through the `ledger:palette` window event. `on_change` also pushes `%{"theme" => id}` to
  the LiveView. Put `<.theme_script theme="..." />` in the root layout so the stored palette is on
  before the first paint.

  `ledger.css` ships two palettes, `ledger` (default) and `crepusculo` (`<html data-palette="crepusculo">`:
  indigo brand, Inter Tight headings, its own hero and auth art); `themes/0` lists them first-class next to
  the sample previews. Pass `themes={~w(ledger crepusculo)}` for the real ones.

  `themes` takes ids of the built-in list (`themes/0`) or maps `%{id, label}` (optionally `bg`,
  `accent`, `ink` for the preview).
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Dropdown

  @themes [
    %{id: "ledger", label: "Ledger", bg: "#ffffff", accent: "#1f9282", ink: "#141514"},
    %{id: "noite", label: "Noite", bg: "#0e100f", accent: "#2fa792", ink: "#f2f3f2"},
    %{id: "areia", label: "Areia", bg: "#faf6ef", accent: "#b07a2c", ink: "#2a2017"},
    %{id: "oceano", label: "Oceano", bg: "#f3f8fc", accent: "#2d6fb7", ink: "#0f1e2e"},
    %{id: "graphite", label: "Graphite", bg: "#f4f4f2", accent: "#3b3d3b", ink: "#141514"},
    %{id: "amber", label: "Amber", bg: "#f8f4ec", accent: "#c9821a", ink: "#2a1d08"},
    %{id: "rose", label: "Rose", bg: "#faf2f3", accent: "#cc3a52", ink: "#2b0f15"},
    %{id: "crepusculo", label: "Crepúsculo", bg: "#f6f6fb", accent: "#3d5fd6", ink: "#12163a"}
  ]
  @by_id Map.new(@themes, &{&1.id, &1})

  @doc "The built-in themes."
  def themes, do: @themes

  attr :id, :string, required: true
  attr :variant, :string, default: "menu", values: ~w(menu grid)
  attr :themes, :list, default: nil, doc: "Ids or `%{id, label}` maps; default `themes/0`."
  attr :default, :string, default: nil, doc: "The theme shown when nothing is stored."
  attr :current, :string, default: nil, doc: "The same as `default`."
  attr :label, :string, default: "Theme"
  attr :placement, :string, default: "bottom-end", values: ~w(bottom-end bottom-start)
  attr :on_change, :string, default: nil
  attr :target, :any, default: nil

  attr :loop, :boolean,
    default: false,
    doc: "`variant=\"grid\"`: the demo motion, each box takes the highlight in turn."

  attr :class, :any, default: nil
  attr :rest, :global

  def theme_picker(assigns) do
    list = normalize(assigns.themes)

    default =
      assigns.default || assigns.current || Application.get_env(:ledger_ui, :theme) ||
        List.first(list).id

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
      role="radiogroup"
      aria-label={@label}
      class={cx(["flex flex-wrap items-center gap-3", @class])}
      {@rest}
    >
      <div
        :for={{t, i} <- @list}
        data-part="theme-box"
        data-lu-theme={t.id}
        role="radio"
        aria-checked={to_string(t.id == @selected)}
        tabindex={if t.id == @selected, do: "0", else: "-1"}
        class={[
          "group/opt w-[150px] cursor-pointer overflow-hidden rounded-[12px] shadow-[0_0_0_1px_var(--lu-line)] aria-checked:shadow-[0_0_0_2px_var(--lu-accent-500)]",
          @loop && "animate-[mo-thsel_8s_infinite] [animation-delay:var(--dl)]"
        ]}
        style={"--dl:#{i * 2}s"}
      >
        <div class="flex h-[70px] gap-1 p-2" style={"background:#{t.bg}"}>
          <i class="block flex-1 rounded-[4px]" style={"background:#{t.accent}"}></i>
          <i class="block flex-1 rounded-[4px]" style={"background:#{t.ink};opacity:.85"}></i>
          <i class="block flex-1 rounded-[4px]" style={"background:#{t.accent};opacity:.4"}></i>
        </div>
        <div class="flex justify-between bg-panel px-2.5 py-1.5 text-[12.5px]">
          <span>{t.label}</span>
          <span class="hidden group-aria-checked/opt:contents"><.icon name="check" size="sm" /></span>
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
        if(assigns.placement == "bottom-start", do: "left-0", else: "right-0")
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
      role="group"
      class={cx(["relative inline-block", @class])}
      phx-click-away={JS.hide(to: "##{@id}-pop")}
      {@rest}
    >
      <button
        type="button"
        data-part="theme-picker-button"
        class={LedgerUI.Components.AppShell.tbtn_classes()}
        aria-label={@label}
        aria-haspopup="menu"
        aria-controls={"#{@id}-pop"}
        phx-click={JS.toggle(to: "##{@id}-pop")}
      >
        <.icon name="palette" />
      </button>
      <div
        id={"#{@id}-pop"}
        data-part="theme-picker-pop"
        class={
          cx([
            Dropdown.pop_classes(min: "w-[200px] min-w-[220px]"),
            "absolute top-[calc(100%+6px)] z-50",
            @pos
          ])
        }
        role="menu"
        aria-label={@label}
        hidden
        keep-hidden
      >
        <button
          :for={{t, _i} <- @list}
          type="button"
          role="menuitemradio"
          aria-checked={to_string(t.id == @selected)}
          data-part="theme-picker-option"
          data-lu-theme={t.id}
          class={
            cx([
              "group/opt",
              Dropdown.item_classes(),
              "aria-checked:font-medium aria-checked:text-ink"
            ])
          }
        >
          {t.label}<span class={["hidden group-aria-checked/opt:flex", Dropdown.item_end_classes()]}><.icon
            name="check"
            size="sm"
            class="text-accent-content"
          /></span>
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
