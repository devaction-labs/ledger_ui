# `lu-*` class tokens still present in the RENDERED example (`examples/<id>/NN.heex`): PENDING rewrites.
# `LedgerShowcase.ExamplesTest` fails on any token not listed here AND on a listed token that is gone, so the
# list only shrinks. When you rewrite an example with real components, delete its line. NEVER add a line for new
# code; a genuinely permanent exception stays in the list with a `# permanent: <reason>` comment above its line
# (none today).
%{
  # pendente: o item de navegação da sidebar (`sidebar_nav_link`) não tem atributo `color` (fundo --c-soft + texto --c-ink do canvas); as 6 células "color=…" ficam em marcação crua
  {"shell", 3} => ["lu-nav-item"],
}
