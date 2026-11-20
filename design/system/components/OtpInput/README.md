# OtpInput

Código de uso único em caixas de 46×54; o foco anda sozinho para a próxima ao digitar e o colar preenche tudo.

**Grupo:** 03 · Formulários — texto  
**Resumo visual:** length · mode · size sm/md/lg · mask · separator · state · disabled

## Uso (Phoenix / HEEx)

```heex
<.otp_input field={@form[:code]} length={6} separator={3} on_complete="verify" />
<.otp_input name="pin" length={4} mask size="lg" />
```

## Regras

- `separator={3}` divide seis caixas em 3 e 3.
- `state="success"` pinta de verde; `error` de vermelho, com a mensagem abaixo.
- `mask` mostra pontos, como senha.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: otp_input)

Todos os function components, atributos, valores e slots que este componente cobre.

A one-time code made of single-character boxes, for the second step of a sign-in, a phone or
email confirmation, a recovery PIN.

    <.otp_input field={@form[:code]} label="6-digit code" />
    <.otp_input name="pin" length={4} mask autofocus />
    <.otp_input field={@form[:code]} separator={3} on_complete="verify" />
    <.otp_input name="invite" mode="alphanumeric" length={8} size="lg" />

Typing fills a box and moves to the next, Backspace on an empty box goes back and empties the
previous one, the arrows, Home and End move between boxes, and a paste or an autofill spreads its
characters over the boxes (a text as long as the whole code always starts at the first box).
Characters the `mode` does not allow are dropped.

The boxes have no `name`: a hidden input named like the field carries the joined code, and a
bubbling `input` event fires from it whenever the code changes, so a surrounding `phx-change`
receives `%{"name" => "482913"}` (a partial code while it is typed). `phx-debounce` and
`phx-throttle` go in `rest` of a form, not here. `value` may be an integer or a string; the
server renders it into the boxes, a value the server sends later wins over the one in the
browser (render `value=""` to clear a rejected code), and re-rendering what the browser sent
does nothing.

A filled box keeps the border of the others (it only carries `data-filled`); with errors it keeps the error border and
with `state="success"` the success one. The error line has `role="alert"`; a `help` line under
`state="success"` starts with a check-circle icon.

    <.otp_input field={@form[:code]} state="success" help="Code confirmed" />

### Accessibility

The boxes are a `role="group"` named by the `label` (or by `aria_label`); each box is named
`digit_label` plus its number (`Digit 1`), has `autocomplete="one-time-code"` so the keyboard
offers the code from an SMS, and a numeric keypad on touch devices in `numeric` mode. The
separator is hidden from assistive technology.

The behavior lives in the `LedgerUI.Otp` hook, so the component needs a stable `id` (it gets one
from `field` or `name`).

### `<.otp_input>`

Renders the boxes, with their caption, help and errors when given.

Events: no event of its own besides `on_complete`. The hidden input dispatches a bubbling
`input` event when the code changes. `on_complete` is an event name or a `%JS{}`, sent to
`target` when there is one, each time the code changes while every box is filled, with
`%{"id" => id, "name" => name, "value" => code}`.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` | `:string` |  | The id of the group. Defaults to the field id, then `name`. |
| `name` | `:string` |  | Defaults to the field name. |
| `value` | `:any` |  | The code, a string or an integer. Defaults to the field value. Cut to `length`. |
| `field` | `{:struct, Phoenix.HTML.FormField}` | `nil` | A form field: fills `id`, `name`, `value` and `errors`. |
| `label` | `:string` | `nil` | The caption; it also names the group. |
| `label_class` | `:any` | `nil` | Classes of the caption text. |
| `help` | `:string` | `nil` | The small line under the boxes. |
| `errors` | `:list` | `[]` |  |
| `state` | `:string` | `nil` | ``, `success`, `error` — `success` paints the boxes green and the help line gets a check-circle icon. |
| `length` | `:integer` | `6` | How many boxes (a code of this many characters). |
| `mode` | `:string` | `"numeric"` | `numeric`, `alphanumeric` — `numeric` takes digits only and opens the numeric keypad; `alphanumeric` takes letters and digits. |
| `size` | `:string` | `"md"` | `sm`, `md`, `lg` — `md` is 54px tall, as in the Signetum canvas. |
| `mask` | `:boolean` | `false` | Shows dots instead of the characters, like a password. |
| `disabled` | `:boolean` | `false` |  |
| `autofocus` | `:boolean` | `false` | Focuses the first empty box when it mounts. |
| `separator` | `:any` | `nil` | A dash after this many boxes (`3` splits six boxes into 3 and 3), or a list of positions. |
| `on_complete` | `:any` | `nil` | An event name or a `%JS{}`. |
| `target` | `:any` | `nil` | The `phx-target` of `on_complete`. |
| `aria_label` | `:string` | `"One-time code"` | Names the group when there is no `label`. |
| `digit_label` | `:string` | `"Digit"` | The accessible name of each box, followed by its number. |
| `wrapper_class` | `:any` | `nil` | Classes of the block around the field. |
| `class` | `:any` | `nil` | Classes of every box. |

Any other HTML/phx attribute goes to the root element.
