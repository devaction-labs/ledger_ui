# Visual status: canvas vs showcase

Tooling (headless Chromium over CDP, no dependencies): `scripts/visual/`.

```sh
cd showcase && PORT=4500 mix phx.server &          # showcase under test (restart it after editing examples or lib/: they are compiled in)
DESIGN=design scripts/visual/run.sh /tmp/lu-visual # canvas pages + templates -> screenshots -> diff -> visual-report/index.html
ONLY=button,input THEMES=light scripts/visual/run.sh   # subset (ids; templates are tpl-auth-login, tpl-dashboard, tpl-tabela, ...)
```
`run.sh` runs `canvas`, `tcanvas` (templates), `showcase`, `tshowcase`, `diff`, `report`; with `ONLY` the diff keeps the
previous results of the other ids.

`DESIGN` points at the directory holding `canvas/G*Claro*.dc.html` and `canvas/canvas.css`, so a refreshed
canvas is a drop-in. If results from a previous run exist in the scratch dir they are kept as
`results-before.json` and shown as "before" in the report.

Method: each board `<x-dc>` markup is rendered with `canvas.css` (light, and dark by switching
`data-theme`); mapping canvas demo -> showcase section is the one of `showcase/test/support/canvas.ex`.
Showcase side: `/full/:id?theme=...`, section N = N-th `.d-ex`. Animations frozen identically on both sides.
Harness normalisation: the showcase `.d-in2` gets the canvas demo width, `align-items:stretch`, `gap:4px`.
Diff: per pixel (channel delta > 24) over the overlap of both shots; if > 0.3% it also tries +-1px shifts and keeps
the best (sub-pixel layout offsets). Size mismatches > 1px are flagged separately. Hover: elements are taken from
the `:hover` rules of the loaded stylesheets (+ buttons, links, inputs, tr, cards, chips), paired by tag+`lu-*`
class signature (up to 3 per section), the mouse is moved over them on both sides and shots are diffed;
"hover missing" = canvas changes on hover and the showcase does not.

Page templates: `/templates/<slug>?theme=` against `canvas/T<Name>Claro|Escuro.dc.html` (each theme uses its own board). Entry
`tpl-<slug> #1` is the whole board (1440 x board height; the showcase viewport is set to the board height so fixed overlays and
`100vh` match; hover included, up to 12 elements), `#2` is the 1440x900 viewport crop (only when the board is taller). The
showcase's own back/theme buttons (`.tpl-chrome`) are hidden for the shot.

## Result (run on the new canvas, before = first run, after = final run)

| set | before: compared / <1% / <5% / mean | after: compared / <1% / <5% / mean |
|---|---|---|
| components light | 476 / 220 / 412 / 2.46% | 476 / 405 / 462 / 0.66% |
| components dark | 476 / 226 / 422 / 2.16% | 476 / 406 / 464 / 0.62% |
| components hover | 780 / 278 / 680 / 2.53% | 780 / 638 / 759 / 0.66% |
| templates light (board + viewport) | 13 / 1 / 5 / 9.79% | 13 / 9 / 12 / 1.79% |
| templates dark | 13 / 1 / 5 / 5.09% | 13 / 10 / 13 / 1.03% |
| templates hover | 80 / 4 / 32 / 8.38% | 124 / 100 / 124 / 0.95% |

Sections whose size differs by more than 1px: 68 -> 8. Hover missing: 9 -> 5 (all triaged below). The template "before" was taken
with the first harness (viewport 900 for every board, no `.tpl-chrome` hiding), so part of it was harness; the real template
defects are listed below.

## Fixed (real defects)

- **Systematic line-height/font-size (the 1-5px height differences, most of the diff everywhere):** the showcase `body` is
  15px/1.6 for its prose and the demo areas and template pages inherited it, while `ledger.css`/canvas use 14px/20px.
  `showcase.css`: `.d-exp, .tpl-root { font-size: 14px; line-height: 20px }`.
- Templates: showcase `main { padding: 30px 0 80px }` leaked into the app shell's `<main>` (`.tpl-root main { padding: 0 }`);
  the top bar shrank (flex column with `overflow:auto`): `.lu-app > main > .lu-topbar { flex-shrink: 0 }` (ledger_ui.css).
- `.lu-check input:indeterminate::after` was in flow and moved the input baseline: the select-all header row of tables was 3px
  shorter than the canvas (everything below shifted). The bar is now absolutely positioned (ledger_ui.css).
- Loading button (`disabled` + `aria-busy`) was faded to 45%; the canvas' loading button is solid (ledger_ui.css).
- Examples that were raw copies with empty `<i data-i>` placeholders (no icon rendered): dropdown #3, logo #3, shell-floating #1,
  theme-picker #1/#2, theme-switch #3, time-picker #2, upload #4, view-switcher #1 now use `<.icon>`.
- textarea #3: the demo padded the value with visible `x` to reach the 184/214 counters; now zero-width spaces (same counter, no filler).
- autocomplete: options accept `:tone` (`t1`..`t5`) for the avatar color (the canvas uses t1/t2/t3 in order; default stays the label hash). Test added.
- showcase `act.js`: the narrow-page "grid collapses to one column" heuristic counted the animated drawer mock's off-screen panel as
  overflow and stacked the drawer demo; `.lu-mst` children are ignored and the original `--cols` is kept in `data-cols0`
  (the harness restores it, since the harness page is as wide as the canvas).

## Harness fixes (not component defects)

- Page scroll left by the hover of the previous entry shifted the next clip (hover shots of upload #4, scroll-area, ...): scroll reset, no `inline:center` scroll.
- CSS animations that were already running when the freeze style was added kept their elapsed time (random phase per run; e.g. sheet 8% -> 46% between runs): all animations are now rewound to 0 and paused with the -0.5s delay.
- Screenshots were capped at 7000px, now 15000.

## Remaining differences and why

| where | diff | reason |
|---|---|---|
| carousel #1 (dark 33%, light similar) | animation | the canvas slides in a loop (frozen mid-slide); ours is the real JS carousel, frozen on slide 1 |
| scroll-area #2 | 18% | the canvas board overlaps this demo with the next section ("Digitando o e-mail", social buttons): the canvas export is broken there, nothing comparable |
| typography #4 | 15% | identical text; sub-pixel vertical offset of one text line (antialiasing) |
| autocomplete #3 hover | 11% | the canvas row highlight uses a bold match on hover state and a 1366px stage; ours is 380px (stage width) with the same markup now (avatar tones fixed) |
| shell #3, shell-floating #1 (hover) | 6-10% | animated mini-app mocks (hover frames land on different animation frames) |
| tpl-tabela-modal #2 (viewport crop), tpl-tabela #2 | 10% / 3.6% | by design: overlays and the floating bulk bar are anchored to the viewport (900px) in the app, to the 1180px board in the canvas; the full-board entry (#1) is 3.7% / 0.6% |
| progress-bar | up to 9% | documented parity exception (animated bars) |
| input #6, date/time/color inputs | 5.7% | browser-native control chrome (`type=date|time|color`) against the canvas' text mock |
| accordion #1 | 5.6% | the showcase adds a body to closed items so they can open (act.js), taller than the static canvas |
| treeview #2, bulk-bar #2 (hover on input) | hover "missing" | the canvas export is static: its `data-ind` checkbox is a plain unchecked box, ours is really indeterminate (teal, correct); hover on it changes in the canvas only because of that |
| filter-menu #2 dark (hover) | 40px | sub-threshold: markup and classes are identical to the canvas |
| pagination #3 (hover target) | unpaired | documented exception (select rendered as span in the canvas) |
| tooltip #3, radio-choice #2, phone-input #2, logo #3, password-input #2, popover #2 | 3-6% | static mock vs real component (native input, tooltip position), no markup defect found; all below 6% |
| tpl-tabela(-gaveta/-modal) | select-all header | real indeterminate state with 3 rows selected, the canvas draws it empty |

The drawer/modal open-close motion and the orders template are being reworked by other agents (not touched here).
