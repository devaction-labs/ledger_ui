# PasswordInput

Campo de senha com o botão de olho que mostra e oculta o que foi digitado.

**Grupo:** 03 · Formulários — texto  
**Resumo visual:** mostrar/ocultar · força da senha · size · variant · state

## Uso (Phoenix / HEEx)

```heex
<.password_input field={@form[:password]} label="Senha" autocomplete="new-password" />
<.password_input field={@form[:password]} show_label="Mostrar a senha" hide_label="Ocultar a senha" size="lg" />
```

## Regras

- O olho alterna entre pontos e texto; o rótulo acessível troca junto (`show_label`/`hide_label`).
- Senha nova: mostre a força em 4 segmentos abaixo do campo.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: password_input)

Todos os function components, atributos, valores e slots que este componente cobre.

A password field with the button that shows what was typed.

    <.password_input name="password" placeholder="Enter password" />

It is an `input/1` of `type="password"` (every attr of `input/1` is taken) with an eye at the end. The button flips the
type of the field between `password` and `text` with `Phoenix.LiveView.JS`, so it needs no hook, and its icon follows
the type.

### `<.password_input>`

Renders the field and the eye.

    <.password_input field={@form[:password]} label="Password" />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` | `:string` | `nil` | Defaults to the field id, `name`, or a generated one. |
| `show_label` | `:string` | `"Show the password"` |  |
| `hide_label` | `:string` | `"Hide the password"` |  |
| `class` | `:any` | `nil` |  |
| `field` | `{:struct, Phoenix.HTML.FormField}` | `nil` | A form field, as for `input/1`. |
| `name` | `:string` | `nil` |  |
| `value` | `:any` | `nil` |  |
| `label` | `:string` | `nil` |  |
| `help` | `:string` | `nil` |  |
| `errors` | `:list` | `[]` |  |
| `placeholder` | `:string` | `nil` |  |
| `disabled` | `:boolean` | `false` |  |
| `size` | `:string` | `"md"` | `sm`, `md`, `lg` |
| `variant` | `:string` | `"outlined"` | `outlined`, `filled`, `plain` |
| `state` | `:string` | `nil` | ``, `success`, `error` |
| `autocomplete` | `:string` | `nil` |  |
| `required` | `:boolean` | `nil` |  |
| `minlength` | `:integer` | `nil` |  |
| `maxlength` | `:integer` | `nil` |  |
| `form` | `:string` | `nil` |  |

Any other HTML/phx attribute goes to the root element.
