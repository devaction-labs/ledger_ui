defmodule LedgerUI.Components.ThemeSwitch do
  @moduledoc """
  The light / dark / system choice.

      <.theme_switch id="theme" />
      <.theme_switch id="theme" variant="icons" size="sm" />
      <.theme_switch id="theme" variant="switch" />
      <.theme_switch id="theme" system={false} light_label="Claro" dark_label="Escuro" />

  `variant` is `"segmented"` (a track with the chosen icon raised), `"icons"` (the same without the
  track, round) or `"switch"` (a toggle: on is dark). `size="sm"` is the compact one;
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

  The server always renders the light choice; the hook owns the state. The labels travel as
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

  defp sw_track, do: @sw_track

  attr :id, :string, required: true
  attr :variant, :string, default: "segmented", values: ~w(segmented icons switch)
  attr :size, :string, default: "md", values: ~w(md sm)
  attr :system, :boolean, default: true
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
      role="switch"
      aria-checked="false"
      aria-label={@label || "Dark mode"}
      tabindex="0"
      data-part="theme-switch"
      class={@classes}
      {@rest}
    >
      <i data-part="theme-switch-track" class={sw_track()}></i><span
        data-part="theme-switch-span"
        class="flex flex-col gap-0.5"
      >{@dark_label}</span>
    </span>
    """
  end

  def theme_switch(assigns) do
    icons? = assigns.variant == "icons"

    assigns =
      assigns
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
      data-part="theme-switch"
      class={@classes}
      {@rest}
    >
      <span
        data-part="theme-switch-item"
        class={@item}
        role="radio"
        aria-checked="true"
        aria-label={@light_label}
        tabindex="0"
      ><.icon name="sun" size="md" /></span><span
        data-part="theme-switch-item"
        class={@item}
        role="radio"
        aria-checked="false"
        aria-label={@dark_label}
        tabindex="-1"
      ><.icon name="moon" size="md" /></span><span
        :if={@system}
        data-part="theme-switch-item"
        class={@item}
        role="radio"
        aria-checked="false"
        aria-label={@system_label}
        tabindex="-1"
      ><.icon name="monitor" size="md" /></span>
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

  @doc """
  Inline script for the root layout `<head>`: applies the stored mode (`data-theme`) and palette
  (`data-palette`) before the first paint, so there is no flash. It is plain and synchronous on
  purpose (it must block rendering).

      <head>
        <.theme_script />
      </head>
  """
  def theme_script(assigns) do
    palette = assigns.theme || Application.get_env(:ledger_ui, :theme)

    assigns =
      assigns
      |> assign(:mode_default, assigns.default)
      |> assign(:palette, palette)

    ~H"""
    <script>
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
      class={cx([LedgerUI.Components.AppShell.tbtn_classes(), @class])}
      {@rest}
    >
      <span data-part="theme-toggle-span" class="contents dark:hidden"><.icon name="moon" /></span><span
        data-part="theme-toggle-span-2"
        class="hidden dark:contents"
      ><.icon name="sun" /></span>
    </button>
    """
  end
end
