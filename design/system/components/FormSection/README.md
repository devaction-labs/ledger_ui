# FormSection

Agrupa campos relacionados num card com título, descrição e rodapé de ações.

**Grupo:** 03 · Formulários — texto  
**Resumo visual:** layout stacked/aside · columns 1/2/3

## Uso (Phoenix / HEEx)

```heex
<.form_section title="Faturamento" description="…">…<:actions>…</:actions></.form_section>
```

## Regras

- Ações ficam no rodapé à direita: primário por último.
- Uma seção por assunto; não misture cobrança e perfil.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: form_section)

Todos os function components, atributos, valores e slots que este componente cobre.

The canvas form section: a group of fields under a small title, laid out in a grid.

    <.form_section title="Contato">
      <.input field={@form[:email]} label="E-mail" />
      <.input field={@form[:phone]} label="Telefone" />
    </.form_section>

    <.form_section title="Endereço" description="Usado na NF-e" layout="aside">
      <.input field={@form[:zip]} label="CEP" />
      <.input field={@form[:number]} label="Número" />
    </.form_section>

`stacked` (the default) puts the 13px title over the fields and closes the section with a line
(`divider={false}` drops it); `aside` puts the title and its description in a 200px column at
the left of the fields. The fields go in `columns` columns (two by default), one column on a
narrow screen. The `:action` slot sits at the right of a stacked title.

### `<.form_section>`

Renders a form section; the inner block is its fields.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `title` (required) | `:string` |  | The section's title. |
| `description` | `:string` | `nil` | A line under the title. |
| `layout` | `:string` | `"stacked"` | `stacked`, `aside` — `stacked`: the title over the fields; `aside`: the title in a column at their left. |
| `columns` | `:integer` | `2` | `1`, `2`, `3` — Columns of the fields' grid. |
| `divider` | `:boolean` | `nil` | A line under the section; by default on for `stacked`, off for `aside`. |
| `id` | `:string` | `nil` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:action>` — At the right of a stacked title (a link, a toggle).
- `<:inner_block>` (required)
