defmodule LedgerUI do
  @moduledoc """
  Phoenix LiveView components with the Ledger UI design.

  ## Usage

      defmodule MyAppWeb do
        defp html_helpers do
          quote do
            use LedgerUI
          end
        end
      end

  `use LedgerUI` imports the function components (and the documented JS/socket helpers
  such as `show_toast/2`) of every module listed in `LedgerUI.Components.__modules__/0`,
  so `<.button>`, `<.icon>`, etc. are available in HEEx templates. Implementation helpers
  stay in their modules and are not imported.

  ## Mode and palette

  Two independent switches on `<html>`: `data-theme="light|dark"` (the mode, `theme_switch/1`) and
  `data-palette="ledger|crepusculo"` (the palette, `theme_picker/1`). Every palette defines its own
  light and dark token sets in `ledger.css`; components never change. Both choices are kept in
  `localStorage` (`theme`, `ledger-palette`) and applied before the first paint by `theme_script/1`:

      <html data-theme="dark" data-palette="crepusculo">
      <.theme_switch id="mode" />
      <.theme_picker id="palette" themes={~w(ledger crepusculo)} />

  ## Opening and closing elements

  Overlays (modal, drawer, popover, menus...) are shown by the CSS class `open`.
  These helpers toggle it:

    * `open/2`, `close/2`, `toggle/2` on a `Phoenix.LiveView.JS` struct: client-side,
      no round trip. They add/remove/toggle the class `open` on `#id` and update
      `aria-expanded` on the triggers that point at it with `aria-controls="id"`.

          <button phx-click={LedgerUI.open("my-drawer")} aria-controls="my-drawer">Open</button>

    * `open/2` and `close/2` on a socket: push the `"ledger:open"` / `"ledger:close"`
      events with `%{id: id}`; the glue in `ledger_ui.js` adds/removes the class `open`.

          def handle_event("save", _, socket), do: {:noreply, LedgerUI.close(socket, "my-drawer")}
  """

  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.Socket

  defmacro __using__(_opts) do
    quote do
      unquote(
        for mod <- LedgerUI.Components.__modules__() do
          quote do: import(unquote(mod), only: unquote(LedgerUI.Components.__imports__(mod)))
        end
      )
    end
  end

  @doc """
  Adds the class `open` to `#id` (and sets `aria-expanded="true"` on its triggers).

  With a socket, pushes the `"ledger:open"` event instead.
  """
  def open(js_or_socket \\ %JS{}, id)

  def open(%Socket{} = socket, id) when is_binary(id),
    do: Phoenix.LiveView.push_event(socket, "ledger:open", %{id: id})

  def open(%JS{} = js, id) when is_binary(id) do
    js
    |> JS.add_class("open", to: "#" <> id)
    |> JS.set_attribute({"aria-expanded", "true"}, to: controls(id))
  end

  @doc """
  Removes the class `open` from `#id` (and sets `aria-expanded="false"` on its triggers).

  With a socket, pushes the `"ledger:close"` event instead.
  """
  def close(js_or_socket \\ %JS{}, id)

  def close(%Socket{} = socket, id) when is_binary(id),
    do: Phoenix.LiveView.push_event(socket, "ledger:close", %{id: id})

  def close(%JS{} = js, id) when is_binary(id) do
    js
    |> JS.remove_class("open", to: "#" <> id)
    |> JS.set_attribute({"aria-expanded", "false"}, to: controls(id))
  end

  @doc """
  Toggles the class `open` on `#id` (and flips `aria-expanded` on its triggers).
  Client-side only.
  """
  def toggle(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.toggle_class("open", to: "#" <> id)
    |> JS.toggle_attribute({"aria-expanded", "true", "false"}, to: controls(id))
  end

  defp controls(id), do: ~s([aria-controls="#{id}"])
end
