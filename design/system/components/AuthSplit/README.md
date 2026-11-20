# AuthSplit

Tela de autenticação dividida: formulário à esquerda e painel de marca à direita.

**Grupo:** 13 · Estrutura e shell  
**Resumo visual:** variant card · full · provider google/apple/github

## Uso (Phoenix / HEEx)

```heex
<.auth_split>
  <:form>…</:form>
  <:aside>…</:aside>
</.auth_split>
```

## Regras

- Formulário até 380px; SSO primeiro, e-mail depois.
- Painel da marca usa `bg-tray` e um KPI real como prova.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: auth_split)

Todos os function components, atributos, valores e slots que este componente cobre.

The canvas sign in and sign up screen in two halves: the form on the left (brand in the corner, a soft glow
at the top, the title, the subtitle, the form and a line under it) and, on the right, a picture filling its
half with a testimonial over its lower part.

    <.auth_split title="Criar conta" subtitle="Preencha seus dados para criar a conta." src={~p"/images/auth.jpg"}>
      <:brand><img src={~p"/images/logo.svg"} class="size-7" /> Acme</:brand>
      <:providers>
        <.oauth_button provider="google" href={~p"/auth/google"}>Google</.oauth_button>
        <.oauth_button provider="apple" href={~p"/auth/apple"}>Apple</.oauth_button>
      </:providers>
      <.form for={@form} phx-submit="save">…</.form>
      <:quote author="Marina Costa" role="Gerente, Loja Bom Fim" rating={5}>
        Em uma semana a equipe inteira estava usando.
      </:quote>
      <:footer>Já tem conta? <.link navigate={~p"/users/log-in"}>Entrar</.link></:footer>
    </.auth_split>

The picture is `src` or the `:art` slot (`<.summit />`); without either and without `:aside`, the form takes
the whole card. `:quote` lays the testimonial over the picture (`author`, `role`, `rating` from 0 to 5);
`:aside` replaces the whole right half. `:providers` puts the sign in buttons (`oauth_button/1`) in a row
above the inner block, with `divider_label` between them and the form. `variant`: `card` (default, floating
on the dotted canvas) or `full` (the whole screen). `glow={false}` takes the glow away. Under 1024px the
right half goes away. Styles: `canvas-auth-split.css` (`linea-auth`).

The three other states of the screen, as in the canvas:

    <%!-- Link sent: the step after "sign in with a link" --%>
    <.auth_split title="Confira o seu e-mail" subtitle="Mandamos um link para marina@acme.com.">
      <.auth_sent>Abra o e-mail no mesmo aparelho e toque em <b>Entrar</b>.</.auth_sent>
      <.button disabled class="w-full" size="lg">Reenviar em 0:42</.button>
    </.auth_split>

    <%!-- With errors: the notice on top of the form; each field shows its own errors --%>
    <.auth_alert>Não deu para criar a conta. Corrija os campos marcados.</.auth_alert>
    <.input field={@form[:email]} label="E-mail" />

    <%!-- Sending: the submit button disables itself and shows the spinner --%>
    <.auth_submit loading={@saving} loading_label="Criando a conta…">Cadastrar</.auth_submit>

### `<.auth_split>`

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `title` (required) | `:string` |  |  |
| `subtitle` | `:string` | `nil` |  |
| `src` | `:string` | `nil` | The picture of the right half. |
| `alt` | `:string` | `""` |  |
| `variant` | `:string` | `"card"` | `card`, `full` |
| `glow` | `:boolean` | `true` |  |
| `divider_label` | `:string` | `"Or"` | Between the providers and the form. |
| `brand_href` | `:string` | `"/"` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:art>` — The picture as markup, instead of `src`.
- `<:aside>` — Replaces the right half.
- `<:brand>` — The logo and the name, top left.
- `<:footer>` — The line under the form ("Already have an account? Sign in").
- `<:inner_block>` (required) — The form.
- `<:providers>` — The `oauth_button/1`s, in a row above the form.
- `<:quote>` — attrs: `author`, `role`, `rating` — A testimonial over the picture.

### `<.oauth_button>`

A sign in button for an identity provider: the provider's icon and the label, as a link (`href`) or a button.

    <.oauth_button provider="google" href={~p"/auth/google"}>Google</.oauth_button>

`provider` is `google`, `apple` or `github` (their Hugeicons line icons); for another one leave it out and
pass the icon in `:icon`.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `provider` | `:string` | `nil` | ``, `google`, `apple`, `github` |
| `href` | `:string` | `nil` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `type`, `disabled`, `form`, `name`, `value`.

Slots:

- `<:icon>`
- `<:inner_block>` (required)

### `<.auth_sent>`

The "link sent" block: a tile with a mail icon and the message beside it. Announced politely
(`role="status"`).

    <.auth_sent>Abra o e-mail no mesmo aparelho e toque em <b>Entrar</b>.</.auth_sent>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:icon>` — Replaces the mail icon.
- `<:inner_block>` (required)

### `<.auth_alert>`

The notice on top of a form with errors: a cross icon and the message (`role="alert"`).

    <.auth_alert>Não deu para criar a conta. Corrija os campos marcados.</.auth_alert>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)

### `<.auth_submit>`

The form's submit button, full width and accent. With `loading` it disables itself (no double submit),
sets `aria-busy` and shows the spinner before the label; change the label to say what is going on.

    <.auth_submit loading={@saving} loading_label="Criando a conta…">Cadastrar</.auth_submit>

`loading_label` is the label while loading (the inner block when left out).

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `loading` | `:boolean` | `false` |  |
| `loading_label` | `:string` | `nil` | The label while `loading`. |
| `type` | `:string` | `"submit"` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `disabled`, `form`, `name`, `value`.

Slots:

- `<:inner_block>` (required)
