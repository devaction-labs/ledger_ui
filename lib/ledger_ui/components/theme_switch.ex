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

  Put `<.theme_script />` in the root layout `<head>` so the first paint already has the theme.

  The server always renders the light choice; the hook owns the state. The labels travel as
  `phx-value-light|dark|system|label` (read by the hook, which turns them into accessible names).
  """
  use LedgerUI.Component

  @sizes %{"md" => nil, "sm" => "sm"}

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

  attr :class, :any, default: nil
  attr :rest, :global

  def theme_switch(%{variant: "switch"} = assigns) do
    assigns =
      assign(
        assigns,
        :classes,
        cx(["lu-sw", assigns.size == "sm" && "s-sm", assigns.class])
      )

    ~H"""
    <span
      id={@id}
      phx-hook="LedgerUI.ThemeSwitch"
      phx-value-variant="switch"
      phx-value-label={@label || "Dark mode"}
      data-part="theme-switch"
      class={@classes}
      {@rest}
    >
      <i></i><span class="t">{@dark_label}</span>
    </span>
    """
  end

  def theme_switch(assigns) do
    assigns =
      assign(
        assigns,
        :classes,
        cx([
          "lu-ts",
          assigns.variant == "icons" && "icons",
          @sizes[assigns.size],
          assigns.class
        ])
      )

    ~H"""
    <span
      id={@id}
      phx-hook="LedgerUI.ThemeSwitch"
      phx-value-variant={@variant}
      phx-value-label={@label || "Theme"}
      phx-value-light={@light_label}
      phx-value-dark={@dark_label}
      phx-value-system={@system && @system_label}
      data-part="theme-switch"
      class={@classes}
      {@rest}
    >
      <span class="on"><.icon name="sun" size="md" /></span>
      <span><.icon name="moon" size="md" /></span>
      <span :if={@system}><.icon name="monitor" size="md" /></span>
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
    var p=localStorage.getItem("linea-theme")||#{palette};if(p)d.setAttribute("data-palette",p);\
    if(localStorage.getItem("monochrome-mode")==="true"){var m=function(){document.body.classList.add("is-monochrome")};document.body?m():document.addEventListener("DOMContentLoaded",m)}\
    }catch(e){}})();\
    """
  end

  attr :id, :string, default: "theme-toggle"
  attr :class, :any, default: nil
  attr :rest, :global

  @doc """
  A single button that flips light and dark: a moon in light mode, a sun in dark (the hook swaps
  the icon). It shares the storage and the `ledger:theme` event with `theme_switch/1`.
  """
  def theme_toggle(assigns) do
    ~H"""
    <button
      id={@id}
      type="button"
      phx-hook="LedgerUI.ThemeSwitch"
      phx-value-variant="toggle"
      aria-label="Toggle dark mode"
      data-part="theme-toggle"
      class={cx(["lu-tbtn", @class])}
      {@rest}
    >
      <.icon name="moon" />
    </button>
    """
  end
end
