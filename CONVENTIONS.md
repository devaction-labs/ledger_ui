# Conventions (for agents implementing components)

Ledger UI: Phoenix LiveView components over a prebuilt stylesheet (`priv/static/ledger.css`, prefix `lu-`).
Design data lives in `design/` (read-only). Read this file fully before touching code.

## Layout

| Path | What |
|---|---|
| `lib/ledger_ui/components/<api>.ex` | One module per API module of `design/system/PARIDADE.md` (`action_menu` -> `LedgerUI.Components.ActionMenu`). All 109 stubs already exist and are already listed in `LedgerUI.Components.__modules__/0`. |
| `test/ledger_ui/components/<api>_test.exs` | Your tests. |
| `showcase/examples/<id>/NN.heex` | Your showcase examples + parity (see below). |
| `priv/static/ledger_ui/hooks/<name>.js` | Client hook, only if JS commands cannot do the job. |
| `design/canvas/G*Claro*.dc.html` | **Markup source of truth**: the design canvas. When it differs from the vitrine, the canvas wins. |
| `design/vitrine/sec/<id>.json` | Fallback markup (`h` = HTML to reproduce, `t` = title) for sections the canvas does not have. |
| `priv/static/ledger.css` | The design's stylesheet. Untouched. |
| `priv/static/ledger_ui.css` | Companion stylesheet, loaded AFTER `ledger.css`: real controls inside kit wrappers, `[hidden]`, overlay states, `--ledger-z-*`, classes the components/hooks add. Put new rules here, never inject `<style>` from a hook or a component. |
| `design/PARITY_STATUS.md` | Generated work list: failing sections per module owner and raw-copy examples. |
| `design/system/components/<Name>/README.md` | **API source of truth** (function names, attrs, defaults, values, slots). |

Do NOT edit files owned by others: `lib/ledger_ui/components.ex`, `lib/ledger_ui.ex`, `component.ex`, `helpers.ex`,
`components/icon.ex`, `mix.exs`, `priv/static/ledger_ui.esm.js`, `priv/static/ledger.{css,js}`, the showcase app code
(`showcase/lib`, `showcase/test`, `showcase/mix.exs`). If a shared change is needed, say so in your final report.
Edit only your own module file(s), your tests, your example folders and your hook files.
Function names must be unique across modules (all are imported by `use LedgerUI`); if two API READMEs
define the same function name, report it.

## Filling a stub

```elixir
defmodule LedgerUI.Components.Badge do
  @moduledoc """
  Short description, then usage example.
  """
  use LedgerUI.Component          # Phoenix.Component (+ keep- global prefix), JS alias, cx/1, <.icon>

  @styles %{
    "base" => "lu-badge",
    "variant" => %{"soft" => nil, "solid" => "solid", "outline" => "outline"},
    "tone" => %{"neutral" => nil, "success" => "pos", "error" => "neg"},
    "size" => %{"sm" => "sm", "md" => nil}
  }

  attr :variant, :string, default: "soft", values: ~w(soft solid outline)
  attr :tone, :string, default: "neutral", values: ~w(neutral success error)
  attr :size, :string, default: "md", values: ~w(sm md)
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def badge(assigns) do
    # In the function body `@styles` is the module attribute (compile-time, O(1) lookups);
    # inside ~H `@x` is an assign, so compute classes here and pass them as an assign.
    assigns =
      assign(
        assigns,
        :classes,
        cx([
          @styles["base"],
          @styles["variant"][assigns.variant],
          @styles["tone"][assigns.tone],
          @styles["size"][assigns.size],
          assigns.class
        ])
      )

    ~H"""
    <span data-part="badge" class={@classes} {@rest}>
      {render_slot(@inner_block)}
    </span>
    """
  end
end
```

Rules:

- Attribute style: `attr :variant, :string, default: "canvas", values: ~w(...)`, `attr :rest, :global`,
  `attr :class, :any, default: nil` merged last with `cx/1`. Names, defaults, values, slots follow the component README exactly.
- `cx/1` only joins strings, drops `nil`/`false`/empty, accepts `{class, bool}` tuples. No class merging/Tailwind.
- Markup must reproduce the `lu-*` classes and structure of `design/vitrine/sec/<id>.json` previews exactly
  (tag, classes as a set, attributes, text, order). `data-part="<part>"` on roots/parts is allowed (ignored by parity).
- Icons: `<.icon name="download" size="sm" />` (server-side; see `LedgerUI.Components.Icon`). Never `<i data-i>`: we do not rely on `LedgerUI.hydrate()` in LiveView-owned DOM.
- `use LedgerUI.Component` already sets `global_prefixes: ["keep-"]` so `keep-class`, `keep-hidden`, `keep-style`,
  `keep-data-*` flow through `:global`.
- Open/close: use `LedgerUI.open/close/toggle` (class `open` on `#id`) or `Phoenix.LiveView.JS`.

## Performance (mandatory)

- Keep templates mostly static, so LiveView change tracking sends only the dynamic bits. Do not wrap large static markup in conditionals/helpers that touch assigns.
- No `Enum`/heavy computation inside `~H`. Precompute in the function body or at compile time.
- Style maps as module attributes (`@styles`), O(1) lookups; no runtime class building beyond `cx/1`.
- Open/close/toggle via `Phoenix.LiveView.JS` (no server round trip). Hooks only where JS commands cannot do it (positioning, keyboard nav, drag, canvas).
- Hooks: event delegation, clean up in `destroyed`, no polling, respect `prefers-reduced-motion`.
- Lists/tables accept `@streams` (`phx-update="stream"`, `row_id` attr).
- Client-owned DOM (charts, signature pad, editors) goes under `phx-update="ignore"` with a stable `id`.
- Stable ids: never random per render. If an id is needed and not given, require the attr or derive it deterministically.
- Use `attr ... values:`: compile-time validation, free.

## Client hooks

Do not use JS getters (`get x()`) in hook objects: LiveView copies the hook object and evaluates getters before `this.el` exists. Use methods.

A component needing a hook creates `priv/static/ledger_ui/hooks/<name>.js` with `export default { mounted() {...}, updated() {...}, destroyed() {...} }`
and puts `phx-hook="LedgerUI.<Name>"` (filename `dropdown.js` -> `"LedgerUI.Dropdown"`; `my_hook.js` -> `LedgerUI.MyHook`) with a stable `id` on the element.
**Do not edit `ledger_ui.esm.js`**: report your hook files; integration runs `elixir scripts/gen_hooks_index.exs`,
which regenerates imports and the `Hooks` map. Consumers: `import {Hooks, DOM} from "ledger_ui"` (see README).
`ledger.js` stays as the chart/runtime library (`window.LedgerUI.lineChart` etc.); wrap charts in a hook + `phx-update="ignore"`.

## Showcase examples and parity

For every section `N` (1-based, see "Section numbering" below) of `design/vitrine/sec/<id>.json`, create `showcase/examples/<id>/NN.heex` (2 digits),
plain HEEx using `<.component>` calls (and raw HTML where needed) that renders what the section's `h` shows.
`<id>` is the vitrine id (`icon-button`, `button`, ...). Adding a file recompiles `LedgerShowcase.Examples`
(`ids/0`, `sections/1`, `render/3`).

The parity test compares each example with the CANVAS markup of that section (`LedgerShowcase.Canvas`:
board `<section>` `<h2>` = component name, leaf `.lu-demo` `.lu-spec` title = vitrine section `t`, the demo body
is the reference; later boards `Claro2`/`Claro3` override earlier ones; single-example boards without `.lu-demo`
use their first `.lu-stage`). Only when the canvas has no such section it falls back to `h`. The failure message
says which source was used and `mix test test/parity_test.exs` ends with a per-id summary table
(passing/total, canvas|vitrine). `{{x}}` / `{ {x} }` template escapes are normalized, `url(#generated-id)` and
long floats (2 decimals) too. The comparison covers (whitespace-collapsed text, class sets, normalized style, attr order and
`id`/`phx-*`/`data-phx-*`/`data-part`/`keep-*` ignored; `<i data-i>` == `<svg data-icon>`).
An attribute present on OUR element but absent on the reference element is also ignored when it is `aria-*`, `role`,
`tabindex`, `hidden`, `popover`, `inert`, `data-lu-*` or `data-state` (the vitrine only gets these from JS). If the
reference element HAS the attribute, the values must still match. Never drop accessibility to make parity pass; see
"Accessibility". Tags, classes, styles, text and order are always compared.

```sh
cd showcase
mix test test/parity_test.exs --only component:button
```

A genuine exception goes in `showcase/test/parity_exceptions.exs` as `{id, index} => "reason"`, and only when the
difference is real against the canvas (real `<form>`/select instead of a fake span, JS-filled random content...).
`cd showcase && mix test --only parity_status` regenerates `design/PARITY_STATUS.md`.
Examples must use the real components (`<.logo>`, `<.badge>`...), not a raw copy of the canvas HTML, except for demo
wrappers (`lu-demo`, `lu-spec`, `mo-*`, layout grids) and markup of components that do not exist.

### Section numbering (`NN`) with canvas-only demos

The section list of a component is, in this order:

1. the sections of `design/vitrine/sec/<id>.json` (`LedgerShowcase.Sections.vitrine/1`), numbered `01`..`V`, then
2. the **canvas-only demos** appended in canvas order (`V+1`..`V+k`): leaf `.lu-demo`s of the component's board whose
   `.lu-spec` title (minus ` · em loop`) matches no vitrine section `t` (or repeats a title more often than the vitrine does).
   Canvas demos titled "Referência visual" are ignored (the vitrine dropped those sections).

So `NN = V + position` of the demo among the canvas-only ones. Example: `button` has 5 vitrine sections and no extras.
When the vitrine drops or reorders sections, rename the example files (`git mv`) and the keys of `parity_exceptions.exs`.

The list of canvas-only demos is `design/canvas/extras.json` (`{id => [%{t, h}]}`, canvas order), read at compile time by the
showcase (`LedgerShowcase.Examples`, `LedgerShowcase.Vitrine`) so the lib does not need LazyHTML. It is derived from the boards by
`LedgerShowcase.Canvas.extras/0`; after a canvas import regenerate it with
`cd showcase && UPDATE_CANVAS_EXTRAS=1 mix test test/canvas_test.exs` (without the variable the test fails if the file is stale).
Title shown on the page = the `.lu-spec` text; code shown = the example's HEEx; the canvas demo HTML is the parity reference and,
when no example file exists, the static preview.

### The vitrine `code`

The `code` of every section of `design/vitrine/sec/<id>.json` is HEEx written against the component API (the reference
usage). `cd showcase && mix test test/vitrine_code_test.exs` compiles each snippet against the library (unknown component,
attr, slot or value outside `values:` is a failure; "missing required" is ignored). Snippets that do not compile yet are
listed with the reason in `showcase/test/support/vitrine_code_known.ex`; the test fails for a new break and also when a
listed snippet starts to compile (remove it from the list then).

## What `use LedgerUI` imports

Only function components (`name/1` declared with `attr`/`slot`) and the documented JS/socket helpers listed in
`LedgerUI.Components.__imports__/1` (`show_toast/2`, `put_toast/3`, `dismiss_alert/0`, `table_toggle_row/1`...). Every other public
function of a component module is an implementation helper: mark it `@doc false`, call it by its full module name, never rely on
it being imported (`test/ledger_ui/use_imports_test.exs` fails otherwise). A new documented helper goes in the `@api` map of
`lib/ledger_ui/components.ex`.

## Accessibility

- ARIA is rendered **server-side**, in the HEEx: `role` (`dialog`, `menu`, `menuitem*`, `tablist`/`tab`/`tabpanel`,
  `tree`/`treeitem`/`group`, `combobox`/`listbox`/`option`, `tooltip`, `group`...), `aria-modal`, `aria-labelledby`,
  `aria-describedby`, `aria-haspopup`, `aria-expanded`, `aria-controls`, `aria-selected`, `aria-checked`,
  `aria-current`, `aria-busy`, `aria-label` on icon-only controls, `tabindex` (roving tabindex included), `aria-hidden`
  on decorative SVGs. The initial state must be correct in the HTML sent by the server (no JS needed to be accessible).
- Hooks only **update state** of attributes that already exist (flip `aria-expanded`/`aria-selected`/`aria-current`,
  move `tabindex`, focus management). A hook must not be the only source of an ARIA attribute.
- Hook configuration goes in `data-lu-*` attributes. `phx-*` is LiveView's reserved namespace: never invent
  `phx-lu-*` or similar.

## Tests

```elixir
defmodule LedgerUI.Components.BadgeTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Badge

  test "renders tone" do
    assigns = %{}
    html = rendered_to_string(~H|<.badge tone="success">ok</.badge>|)
    assert html =~ "pos"
  end
end
```

Before reporting done: `mix compile --warnings-as-errors && mix format --check-formatted && mix test` in the root and in `showcase/`.

## Git worktrees

Parallel agents use worktrees; share deps, keep a private `_build`:

```sh
git worktree add ../ledger_ui-wt/<name> -b feature/<name>
cd ../ledger_ui-wt/<name> && MIX_DEPS_PATH=/home/alex/ElixirProjects/open-source/ledger_ui/deps mix test
```
