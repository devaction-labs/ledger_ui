# design/

Dados de design (somente leitura, não vão para o pacote Hex).

- `vitrine/` — o site de vitrine dos componentes. `docs.json` (140 entradas), `sec/<id>.json` (seções com `t` título, `h` HTML renderizado do preview, `code`), `assets/` (`ledger.css`, `ledger.js` e scripts de demo).
  **`vitrine/sec/<id>.json` é a fonte da verdade do markup**: o HTML de `h` é o que os componentes devem reproduzir.
- `canvas/` — o canvas de design: `canvas.json`, `Main.dc.html`, boards `G01…G15` (claro/escuro, já hidratados) e `tokens.json`.
- `system/` — o design system: `README.md`, `PARIDADE.md` (módulo da API ↔ cards), `design-system.json` e `components/<Nome>/README.md` (API HEEx completa por componente).
  Observação: o `tokens.json` do sistema vive em `canvas/tokens.json`.
