# Palette

A paleta do kit: um teal de marca sobre neutros quentes, com sinais de estado e cinco séries de gráfico.

**Grupo:** 01 · Fundamentos  
**Resumo visual:** Teal da marca, neutros quentes, sinais e séries de gráfico — claro e escuro

## Uso (Phoenix / HEEx)

```heex
<div style="background: var(--bg-tray); color: var(--ink)">…</div>
```

## Regras

- Use sempre o token semântico (`accent`, `pos`, `neg`), nunca o passo da escala diretamente em componentes.
- O botão principal é preto (`inverse`), não teal: o teal fica para dados, links e estados ativos.
- No tema escuro a escala teal inverte (50 escuro → 900 claro) para manter contraste igual.
- Verde de variação positiva (`pos`) e teal de marca diferem em luminosidade: não use um no lugar do outro.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.
