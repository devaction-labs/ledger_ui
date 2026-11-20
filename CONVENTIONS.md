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
| `design/vitrine/sec/<id>.json` | **Markup source of truth** (`h` = HTML to reproduce, `t` = title). |
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

A component needing a hook creates `priv/static/ledger_ui/hooks/<name>.js` with `export default { mounted() {...}, updated() {...}, destroyed() {...} }`
and puts `phx-hook="LedgerUI.<Name>"` (filename `dropdown.js` -> `"LedgerUI.Dropdown"`; `my_hook.js` -> `LedgerUI.MyHook`) with a stable `id` on the element.
**Do not edit `ledger_ui.esm.js`**: report your hook files; integration runs `elixir scripts/gen_hooks_index.exs`,
which regenerates imports and the `Hooks` map. Consumers: `import {Hooks, DOM} from "ledger_ui"` (see README).
`ledger.js` stays as the chart/runtime library (`window.LedgerUI.lineChart` etc.); wrap charts in a hook + `phx-update="ignore"`.

## Showcase examples and parity

For every section `N` (1-based) of `design/vitrine/sec/<id>.json`, create `showcase/examples/<id>/NN.heex` (2 digits),
plain HEEx using `<.component>` calls (and raw HTML where needed) that renders what the section's `h` shows.
`<id>` is the vitrine id (`icon-button`, `button`, ...). Adding a file recompiles `LedgerShowcase.Examples`
(`ids/0`, `sections/1`, `render/3`).

Parity test compares each example with `h` (whitespace-collapsed text, class sets, normalized style, attr order and
`id`/`phx-*`/`data-phx-*`/`data-part`/`keep-*` ignored; `<i data-i>` == `<svg data-icon>`):

```sh
cd showcase
mix test test/parity_test.exs --only component:button
```

A genuine exception goes in `showcase/test/parity_exceptions.exs` as `{id, index} => "reason"` (add the entry in your final report).

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
