defmodule LedgerUI.Components.ThemeSwitch do
  @moduledoc """
  The light / dark / system choice.

      <.theme_switch id="theme" />
      <.theme_switch id="theme" variant="icons" size="sm" />
      <.theme_switch id="theme" variant="switch" />
      <.theme_switch id="theme" system={false} light_label="Claro" dark_label="Escuro" />
      <.theme_switch id="theme" variant="switch" value="dark"><:icon><.icon name="moon" /></:icon></.theme_switch>

  `variant` is `"segmented"` (a track with the chosen icon raised), `"icons"` (the same without the
  track, round), `"switch"` (a toggle: on is dark) or `"cards"` (a radiogroup of cards, each with a
  small preview of the mode: light, dark, and the two halves side by side for system; the preview
  carries its own `data-theme`, so it shows the mode right whatever the page is, in the active palette). `size="sm"` is the compact one;
  `system={false}` leaves only light and dark.

  ## What it does

  The `LedgerUI.ThemeSwitch` hook (`priv/static/ledger_ui/hooks/theme_switch.js`) reads the stored
  choice (`localStorage["theme"]`: `"light"`, `"dark"` or `"system"`), puts the resolved mode on
  `<html data-theme="light|dark">` (the choice itself on `data-theme-choice`), keeps `on`,
  `aria-checked` and `tabindex` in step, and makes the markup a `radiogroup` of `radio`s (arrow keys
  move the choice) or a `switch`. "System" follows `prefers-color-scheme` live. Every switch on the
  page listens to the `ledger:theme` window event and follows.

  The mode is apart from the palette (`<html data-palette="ledger|crepusculo">`, chosen with
  `theme_picker/1`): every palette has a light and a dark token set, so any mode works with any palette.

  Put `<.theme_script />` in the root layout `<head>` so the first paint already has the mode and the palette.

  The server renders the light choice (or the one given by `value`); the hook owns the state. The labels travel as
  `data-lu-light|dark|system|label` (read by the hook, which turns them into accessible names).
  """
  use LedgerUI.Component

  # the segmented track and its three states; the hook keeps `aria-checked` (the "on" look)
  @track "relative inline-flex gap-0.5 rounded-[10px] bg-sunken p-[3px]"
  @track_icons "relative inline-flex gap-1 p-[3px]"
  @seg_item "relative z-[1] grid place-items-center text-[13px] text-muted aria-checked:text-ink"
  @seg_on "rounded-[7px] aria-checked:bg-panel aria-checked:shadow-[var(--lu-shadow-xs),0_0_0_1px_var(--lu-line)]"
  @icons_on "rounded-full aria-checked:bg-selected"
  @item_size %{"md" => "h-7 w-8", "sm" => "h-[22px] w-[26px]"}

  # `loop`: a raised pill slides under the choices (the choices carry no state look of their own)
  @loop_slide "before:absolute before:top-[3px] before:left-[3px] before:rounded-[7px] before:bg-panel before:shadow-[var(--lu-shadow-xs),0_0_0_1px_var(--lu-line)] before:animate-[mo-tsslide_6s_cubic-bezier(.4,0,.2,1)_infinite] before:content-['']"
  @loop_size %{"md" => "before:h-7 before:w-8", "sm" => "before:h-[22px] before:w-[26px]"}

  # the toggle switch (`variant="switch"`): the same track and thumb as `Switch`
  @sw_size %{
    "md" => "[--tw:36px] [--th:22px] [--r:7px] text-[14px]",
    "sm" => "[--tw:30px] [--th:18px] [--r:6px] text-[13px]"
  }
  @sw_track "relative block h-(--th) w-(--tw) flex-none rounded-(--r) bg-line-strong transition-[background-color] duration-150 after:absolute after:top-(--in) after:left-(--in) after:size-[calc(var(--th)-2*var(--in))] after:rounded-[calc(var(--r)-var(--in)+1px)] after:bg-white after:shadow-[0_1px_2px_rgba(0,0,0,.25)] after:transition-transform after:duration-[180ms] after:ease-[cubic-bezier(.3,.7,.4,1)] after:content-[''] group-aria-checked:bg-accent group-aria-checked:after:translate-x-[calc(var(--tw)-var(--th))]"

  # the cards (`variant="cards"`): the chosen one gets the accent ring (`aria-checked`, kept by the hook)
  @card "group/card flex w-36 cursor-pointer flex-col gap-2 rounded-xl p-1 text-[13px] text-muted ring-2 ring-transparent outline-none transition-[box-shadow,color] duration-150 aria-checked:text-ink aria-checked:ring-accent focus-visible:shadow-[0_0_0_3px_var(--lu-focus)]"
  @card_win "relative block h-[72px] overflow-hidden rounded-lg border border-line bg-page"

  defp sw_track, do: @sw_track

  attr :id, :string, required: true
  attr :variant, :string, default: "segmented", values: ~w(segmented icons switch cards)
  attr :size, :string, default: "md", values: ~w(md sm)
  attr :system, :boolean, default: true

  attr :value, :string,
    default: nil,
    values: [nil, "light", "dark", "system"],
    doc:
      "The choice drawn on the server when nothing is stored yet (`nil`: light, then the hook decides). It is only the initial state: it does not change the page mode by itself."

  attr :light_label, :string, default: "Light"
  attr :dark_label, :string, default: "Dark"
  attr :system_label, :string, default: "System"

  attr :label, :string,
    default: nil,
    doc: ~s|Names the group (default "Theme") or the switch (default "Dark mode").|

  attr :loop, :boolean,
    default: false,
    doc: "The demo motion: the raised choice (or the thumb) slides on its own. For the showcase."

  attr :class, :any, default: nil
  attr :rest, :global

  slot :icon,
    doc:
      "`variant=\"switch\"`: what sits beside the track (an icon) instead of the `dark_label` text."

  def theme_switch(%{variant: "switch"} = assigns) do
    assigns =
      assign(
        assigns,
        :classes,
        cx([
          "group inline-flex cursor-pointer items-center gap-2.5 text-ink [--in:3px]",
          @sw_size[assigns.size],
          assigns.loop &&
            "[&>i]:animate-[lu-swtrack_3.6s_ease-in-out_infinite] [&>i]:after:animate-[lu-swthumb_3.6s_cubic-bezier(.3,.7,.4,1)_infinite]",
          assigns.class
        ])
      )

    ~H"""
    <span
      id={@id}
      phx-hook="LedgerUI.ThemeSwitch"
      data-lu-variant="switch"
      data-lu-label={@label || "Dark mode"}
      data-lu-default={@value}
      role="switch"
      aria-checked={to_string(@value == "dark")}
      aria-label={@label || "Dark mode"}
      tabindex="0"
      data-part="theme-switch"
      class={@classes}
      {@rest}
    >
      <i data-part="theme-switch-track" class={sw_track()}></i><span
        data-part="theme-switch-label"
        class="flex flex-col gap-0.5"
      >{if @icon == [], do: @dark_label}{render_slot(@icon)}</span>
    </span>
    """
  end

  def theme_switch(%{variant: "cards"} = assigns) do
    choices = if assigns.system, do: ~w(light dark system), else: ~w(light dark)
    on = if assigns.value in choices, do: assigns.value, else: "light"

    assigns =
      assigns
      |> assign(:on, on)
      |> assign(:choices, choices)
      |> assign(:card, @card)
      |> assign(:win, @card_win)
      |> assign(:classes, cx(["inline-flex gap-3", assigns.class]))

    ~H"""
    <span
      id={@id}
      phx-hook="LedgerUI.ThemeSwitch"
      data-lu-variant="cards"
      role="radiogroup"
      aria-label={@label || "Theme"}
      data-lu-label={@label || "Theme"}
      data-lu-light={@light_label}
      data-lu-dark={@dark_label}
      data-lu-system={@system && @system_label}
      data-lu-default={@value}
      data-part="theme-switch"
      class={@classes}
      {@rest}
    >
      <span
        :for={choice <- @choices}
        data-part="theme-switch-item"
        data-lu-choice={choice}
        class={@card}
        role="radio"
        aria-checked={to_string(@on == choice)}
        aria-label={card_label(assigns, choice)}
        tabindex={if @on == choice, do: "0", else: "-1"}
      >
        <span data-part="theme-switch-preview" class={@win}>
          <.mode_window :if={choice == "light"} mode="light" />
          <.mode_window :if={choice == "dark"} mode="dark" />
          <.mode_window :if={choice == "system"} mode="light" />
          <.mode_window
            :if={choice == "system"}
            mode="dark"
            class="absolute inset-0 [clip-path:inset(0_0_0_50%)]"
          />
        </span>
        <span data-part="theme-switch-label" class="text-center">{card_label(assigns, choice)}</span>
      </span>
    </span>
    """
  end

  def theme_switch(assigns) do
    icons? = assigns.variant == "icons"
    choices = if assigns.system, do: ~w(light dark system), else: ~w(light dark)
    on = if assigns.value in choices, do: assigns.value, else: "light"

    assigns =
      assigns
      |> assign(:on, on)
      |> assign(
        :classes,
        cx([
          if(icons?, do: @track_icons, else: @track),
          assigns.loop && !icons? && @loop_slide,
          assigns.loop && !icons? && @loop_size[assigns.size],
          assigns.class
        ])
      )
      |> assign(
        :item,
        cx([
          @seg_item,
          @item_size[assigns.size],
          cond do
            icons? -> @icons_on
            assigns.loop -> "rounded-[7px]"
            true -> @seg_on
          end
        ])
      )

    ~H"""
    <span
      id={@id}
      phx-hook="LedgerUI.ThemeSwitch"
      data-lu-variant={@variant}
      role="radiogroup"
      aria-label={@label || "Theme"}
      data-lu-label={@label || "Theme"}
      data-lu-light={@light_label}
      data-lu-dark={@dark_label}
      data-lu-system={@system && @system_label}
      data-lu-default={@value}
      data-part="theme-switch"
      class={@classes}
      {@rest}
    >
      <span
        data-part="theme-switch-item"
        class={@item}
        role="radio"
        aria-checked={to_string(@on == "light")}
        aria-label={@light_label}
        tabindex={if @on == "light", do: "0", else: "-1"}
      ><.icon name="sun" size="md" /></span><span
        data-part="theme-switch-item"
        class={@item}
        role="radio"
        aria-checked={to_string(@on == "dark")}
        aria-label={@dark_label}
        tabindex={if @on == "dark", do: "0", else: "-1"}
      ><.icon name="moon" size="md" /></span><span
        :if={@system}
        data-part="theme-switch-item"
        class={@item}
        role="radio"
        aria-checked={to_string(@on == "system")}
        aria-label={@system_label}
        tabindex={if @on == "system", do: "0", else: "-1"}
      ><.icon name="monitor" size="md" /></span>
    </span>
    """
  end

  defp card_label(assigns, "light"), do: assigns.light_label
  defp card_label(assigns, "dark"), do: assigns.dark_label
  defp card_label(assigns, "system"), do: assigns.system_label

  # a tiny window (sidebar, lines, a button) under its own `data-theme`, so the tokens resolve to that mode
  attr :mode, :string, required: true
  attr :class, :any, default: nil

  defp mode_window(assigns) do
    ~H"""
    <span
      data-theme={@mode}
      data-part="theme-switch-window"
      class={cx(["flex size-full bg-page", @class])}
    >
      <span class="block w-1/4 border-r border-line bg-sunken"></span>
      <span class="flex flex-1 flex-col gap-1.5 p-2">
        <span class="block h-1.5 w-3/4 rounded-full bg-ink"></span>
        <span class="block h-1 w-full rounded-full bg-line-strong"></span>
        <span class="block h-1 w-2/3 rounded-full bg-line-strong"></span>
        <span class="mt-auto block h-3 w-1/3 rounded bg-accent"></span>
      </span>
    </span>
    """
  end

  attr :theme, :string,
    default: nil,
    doc: "The named palette when the user chose none (`config :ledger_ui, :theme`)."

  attr :default, :string,
    default: "system",
    values: ~w(light dark system),
    doc: "The mode when nothing is stored."

  attr :nonce, :string,
    default: nil,
    doc: "The CSP nonce put on the `<script>` (`script-src 'nonce-...'`). Omitted when `nil`."

  attr :rest, :global, doc: "Extra attributes for the `<script>` tag."

  @doc """
  Inline script for the root layout `<head>`: applies the stored mode (`data-theme`) and palette
  (`data-palette`) before the first paint, so there is no flash. It is plain and synchronous on
  purpose (it must block rendering).

      <head>
        <.theme_script />
      </head>

  With a strict CSP (`script-src 'nonce-...'`) the browser blocks an inline script that has no
  nonce, and the page flashes the wrong mode on first paint. Pass the request nonce:

      <.theme_script nonce={assigns[:csp_nonce]} />

  renders `<script nonce="...">`. Without `nonce` the output is the same as always. Other
  attributes (`rest`) go to the `<script>` as well.
  """
  def theme_script(assigns) do
    palette = assigns.theme || Application.get_env(:ledger_ui, :theme)

    assigns =
      assigns
      |> assign(:mode_default, assigns.default)
      |> assign(:palette, palette)

    ~H"""
    <script nonce={@nonce} {@rest}>
      <%= Phoenix.HTML.raw(script_body(@mode_default, @palette)) %>
    </script>
    """
  end

  @doc false
  def script_body(default, palette) do
    default = Jason.encode!(default)
    palette = Jason.encode!(palette)

    """
    (function(){try{var d=document.documentElement,c=localStorage.getItem("theme")||#{default};\
    var dk=c==="dark"||(c==="system"&&window.matchMedia("(prefers-color-scheme: dark)").matches);\
    d.setAttribute("data-theme",dk?"dark":"light");d.setAttribute("data-theme-choice",c);\
    var p=localStorage.getItem("ledger-palette")||localStorage.getItem("ledger-theme")||#{palette};if(p)d.setAttribute("data-palette",p);\
    if(localStorage.getItem("monochrome-mode")==="true"){var m=function(){document.body.classList.add("is-monochrome")};document.body?m():document.addEventListener("DOMContentLoaded",m)}\
    }catch(e){}})();\
    """
  end

  attr :id, :string, default: "theme-toggle"
  attr :class, :any, default: nil
  attr :rest, :global

  @doc """
  A single button that flips light and dark: a moon in light mode, a sun in dark (both are in the
  markup, the `dark:` variant shows the right one). It shares the storage and the `ledger:theme` event with `theme_switch/1`.
  """
  def theme_toggle(assigns) do
    ~H"""
    <button
      id={@id}
      type="button"
      phx-hook="LedgerUI.ThemeSwitch"
      data-lu-variant="toggle"
      aria-label="Toggle dark mode"
      data-part="theme-toggle"
      class={cx([LedgerUI.Components.Shell.tbtn_classes(), @class])}
      {@rest}
    >
      <span data-part="theme-toggle-moon" class="contents dark:hidden"><.icon name="moon" /></span><span
        data-part="theme-toggle-sun"
        class="hidden dark:contents"
      ><.icon name="sun" /></span>
    </button>
    """
  end
end
