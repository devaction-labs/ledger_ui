# Visual status: canvas vs showcase

Tooling (headless Chromium over CDP, no dependencies): `scripts/visual/`.

```sh
cd showcase && PORT=4500 mix phx.server &          # showcase under test
DESIGN=design scripts/visual/run.sh /tmp/lu-visual # canvas pages -> screenshots -> diff -> visual-report/index.html
ONLY=button,input THEMES=light scripts/visual/run.sh   # subset
```

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

## First run, against the OLD canvas (before the orchestrator refreshed it) - do not fix from these numbers

482 sections x 2 themes + 792 hover pairs, 0 errors.

| set | compared | < 1% | < 5% | mean diff |
|---|---|---|---|---|
| light | 482 | 212 | 403 | 3.15% |
| dark | 482 | 220 | 415 | 2.75% |
| hover | 792 | 275 | 675 | 2.69% |

Worst (max over themes): palette 77, drawer 38, carousel 33, cohort-heatmap 24, progress-bar 24 (documented
exception), alert 20, scroll-area 18, cash-timer 16, glow-text 16, dropdown 15, typography 15, ai-promo 15.
Dark is not systematically worse than light (kpi-card #4 and alert #2 are +3 points in dark).
72 ids have a section whose size differs by more than 1px (mostly 1-5px of height: real spacing/line-height
candidates, plus drawer/autocomplete/palette/typography/glow-text/stat with large differences).
Hover changes on the canvas but not on the showcase: treeview #2 and bulk-bar #2 (input), table #3 (tr, chip),
filter-menu #2 (dark, button); pagination #3 hover target (select span) has no counterpart (documented exception).

Not yet triaged (canvas was being replaced): real defects list is intentionally empty; re-run and triage after the new canvas lands.
