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

  ## Choosing what is imported

  `use LedgerUI` imports every component, so a name that your own modules (Phoenix's generated
  `CoreComponents`: `button`, `input`, `table`, `header`, `icon`, `modal`, `label`, `error`...)
  also define is ambiguous where it is called. Leave the colliding ones out, or take only the ones
  you want (a name is every arity, `{name, arity}` one of them):

      use LedgerUI, except: [:button, :input, :table, :header, :icon, :modal]
      use LedgerUI, only: [:card, :badge, :progress, :sidebar]

  The left-out ones stay available by their module, `<LedgerUI.Components.Button.button>`, or
  import them under a prefix of your own. A name that is not a component raises at compile time.

  ## Mode and palette

  Two independent switches on `<html>`: `data-theme="light|dark"` (the mode, `theme_switch/1`) and
  `data-palette="ledger|classic|crepusculo"` (the palette; `ledger` is the default, Aurora; `classic` is the palette from before Aurora, `theme_picker/1`). Every palette defines its own
  light and dark token sets in `assets/css/ledger_ui.css`; components never change. Both choices are kept in
  `localStorage` (`theme`, `ledger-palette`) and applied before the first paint by `theme_script/1`:

      <html data-theme="dark" data-palette="crepusculo">
      <.theme_switch id="mode" />
      <.theme_picker id="palette" themes={~w(ledger classic crepusculo)} />

  ## Opening and closing elements

  Overlays (modal, drawer, popover, menus...) are shown by the CSS class `open`.
  These helpers toggle it:

    * `open/2`, `close/2`, `toggle/2` on a `Phoenix.LiveView.JS` struct: client-side,
      no round trip. They add/remove/toggle the class `open` on `#id` and update
      `aria-expanded` on the triggers that point at it with `aria-controls="id"`.

          <button phx-click={LedgerUI.open("my-drawer")} aria-controls="my-drawer">Open</button>

    * `open/2` and `close/2` on a socket: push the `"ledger:js"` event with `%{id: id, open: boolean,
      js: ops}`, where `ops` is the same command `open/1`/`close/1` build, encoded with
      `Phoenix.LiveView.JS.to_encodable/1`. The glue in `ledger_ui.js` runs it with
      `liveSocket.execJS`, so the change is sticky: the class `open` and the triggers' `aria-expanded`
      survive the server's next patch (needs `window.liveSocket`, as in the generated `app.js`; without
      it the glue sets the class directly, which a patch can undo).

          def handle_event("save", _, socket), do: {:noreply, LedgerUI.close(socket, "my-drawer")}

  ## Language

  Every default text of the components (labels, `aria-label`s, placeholders, empty states, month and
  weekday names...) is in English and Brazilian Portuguese. From the highest to the lowest
  precedence: the component's `locale` attr, the locale of the process (`put_locale/1`), the app
  config `config :ledger_ui, locale: "pt_BR"` and `"en"`. A text given by the caller always wins.
  See `LedgerUI.I18n`.

  ## Scrolling

  `scroll_to/3` scrolls to an element from the server; `<.scroll_target>` does it when an assign changes.
  """

  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.Socket

  defmacro __using__(opts) do
    {opts, _} = Code.eval_quoted(opts, [], __CALLER__)
    imports = LedgerUI.__imports__(opts)

    quote do
      unquote(
        for {mod, only} <- imports do
          quote do: import(unquote(mod), only: unquote(only))
        end
      )
    end
  end

  @doc false
  # `[{module, [{name, arity}]}]` that `use LedgerUI` imports, after `only:` and `except:`.
  def __imports__(opts \\ []) do
    unknown = Keyword.keys(opts) -- [:only, :except]

    if unknown != [],
      do:
        raise(
          ArgumentError,
          "use LedgerUI: unknown options #{inspect(unknown)}, expected :only and :except"
        )

    all =
      for mod <- LedgerUI.Components.__modules__(),
          do: {mod, LedgerUI.Components.__imports__(mod)}

    known = Enum.flat_map(all, &elem(&1, 1))
    only = Keyword.get(opts, :only)
    except = Keyword.get(opts, :except, [])

    for {kind, list} <- [only: only, except: except], list != nil do
      case Enum.reject(list, &known?(&1, known)) do
        [] ->
          :ok

        bad ->
          raise ArgumentError,
                "use LedgerUI, #{kind}: #{inspect(bad)} are not components or helpers of LedgerUI"
      end
    end

    for {mod, funs} <- all,
        funs = Enum.filter(funs, &keep?(&1, only, except)),
        funs != [],
        do: {mod, funs}
  end

  defp keep?(fun, only, except),
    do:
      (only == nil or Enum.any?(only, &match_fun?(&1, fun))) and
        not Enum.any?(except, &match_fun?(&1, fun))

  defp known?(spec, known), do: Enum.any?(known, &match_fun?(spec, &1))

  # `:button` is every arity of `button`; `button: 1` is `button/1`
  defp match_fun?(name, {name, _arity}) when is_atom(name), do: true
  defp match_fun?({name, arity}, {name, arity}), do: true
  defp match_fun?(_, _), do: false

  @doc """
  Sets the locale (`"en"` or `"pt_BR"`) of the current process: the components rendered by it use it
  unless they have their own `locale` attr. See `LedgerUI.I18n`.
  """
  defdelegate put_locale(locale), to: LedgerUI.I18n

  @doc "The locale of the current process, or `nil` when none was set (see `put_locale/1`)."
  defdelegate get_locale(), to: LedgerUI.I18n

  @doc """
  Adds the class `open` to `#id` (and sets `aria-expanded="true"` on its triggers).

  With a socket, pushes the `"ledger:js"` event instead (the same commands, encoded: see the
  module docs).
  """
  def open(js_or_socket \\ %JS{}, id)

  def open(%Socket{} = socket, id) when is_binary(id),
    do: push_js(socket, id, true, open(id))

  def open(%JS{} = js, id) when is_binary(id) do
    js
    |> JS.add_class("open", to: "#" <> id)
    |> JS.set_attribute({"aria-expanded", "true"}, to: controls(id))
  end

  @doc """
  Removes the class `open` from `#id` (and sets `aria-expanded="false"` on its triggers).

  With a socket, pushes the `"ledger:js"` event instead (the same commands, encoded: see the
  module docs).
  """
  def close(js_or_socket \\ %JS{}, id)

  def close(%Socket{} = socket, id) when is_binary(id),
    do: push_js(socket, id, false, close(id))

  def close(%JS{} = js, id) when is_binary(id) do
    js
    |> JS.remove_class("open", to: "#" <> id)
    |> JS.set_attribute({"aria-expanded", "false"}, to: controls(id))
  end

  @doc """
  Scrolls smoothly to the first element that matches `selector` (a CSS selector).

  Pushes the `"ledger:scroll"` event with `%{selector:, block:, scope:}`; the glue in
  `ledger_ui.js` runs it, and `prefers-reduced-motion: reduce` turns the animation off.

  Options:

    * `:block` - where the element lands: `"start"`, `"center"`, `"end"` or `"nearest"` (default).
    * `:scope` - a CSS selector of a container: `selector` is searched only inside it. Without it,
      the whole document is searched.

      def handle_event("open_block", %{"block" => block}, socket) do
        {:noreply, LedgerUI.scroll_to(socket, ~s([data-block="\#{block}"]), block: "start")}
      end
  """
  def scroll_to(%Socket{} = socket, selector, opts \\ []) when is_binary(selector) do
    block = Keyword.get(opts, :block, "nearest")

    unless block in ~w(start center end nearest),
      do:
        raise(
          ArgumentError,
          "scroll_to: :block must be start, center, end or nearest, got: #{inspect(block)}"
        )

    Phoenix.LiveView.push_event(socket, "ledger:scroll", %{
      selector: selector,
      block: block,
      scope: Keyword.get(opts, :scope)
    })
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

  defp push_js(socket, id, open?, %JS{} = js),
    do:
      Phoenix.LiveView.push_event(socket, "ledger:js", %{
        id: id,
        open: open?,
        js: JS.to_encodable(js)
      })

  defp controls(id), do: ~s([aria-controls="#{id}"])
end
