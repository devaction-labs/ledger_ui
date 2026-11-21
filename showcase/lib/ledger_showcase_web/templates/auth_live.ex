defmodule LedgerShowcaseWeb.Templates.AuthLive do
  @moduledoc """
  The auth templates: `auth-login`, `auth-login-erro`, `auth-cadastro`, `auth-codigo` and
  `auth-senha`. One LiveView, the screen chosen by `live_action`; each starts in the state of its
  canvas board and every form is real (`phx-change` validates, `phx-submit` acts).

    * login: demo credentials `ana@bompreco.com.br` / `demo123456`; a wrong pair shows the error
      notice with the tries left, three misses lock the form; the right pair goes to the dashboard
    * cadastro: three steps; typing a CNPJ looks it up in a mock table (`12.345.678/0001-90` is
      found and fills the company data)
    * código: six digits, the demo code is `482915`; the resend counts down from 0:42
    * senha: the recovery link; the notice appears when the form is submitted
  """
  use Phoenix.LiveView
  use LedgerUI
  alias Phoenix.LiveView.JS

  alias LedgerShowcaseWeb.Templates.Shell

  @demo_email "ana@bompreco.com.br"
  @demo_password "demo123456"
  @demo_code "482915"

  @companies %{
    "12345678000190" => %{
      razao: "Bom Preço Distribuidora Ltda",
      cidade: "Feira de Santana",
      telefone: "(75) 99812-4410"
    },
    "98765432000110" => %{
      razao: "Padaria Central Ltda",
      cidade: "Feira de Santana",
      telefone: "(75) 3221-0099"
    }
  }

  @plans [
    {"inicial", "Inicial", "R$ 0", "1 usuário, 50 pedidos por mês"},
    {"negocio", "Negócio", "R$ 89", "5 usuários, pedidos e NF-e sem limite"},
    {"rede", "Rede", "R$ 249", "Usuários ilimitados, várias lojas"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    action = socket.assigns.live_action

    if action == :codigo and connected?(socket), do: Process.send_after(self(), :tick, 1000)

    {:ok,
     socket
     |> assign(page_title: "Templates · " <> title(action))
     |> assign(slug: slug(action))
     |> init(action)}
  end

  defp title(:login), do: "Entrar"
  defp title(:login_erro), do: "Entrar com erro"
  defp title(:cadastro), do: "Criar conta"
  defp title(:codigo), do: "Código por e-mail"
  defp title(:senha), do: "Recuperar a senha"

  defp slug(:login), do: "auth-login"
  defp slug(:login_erro), do: "auth-login-erro"
  defp slug(:cadastro), do: "auth-cadastro"
  defp slug(:codigo), do: "auth-codigo"
  defp slug(:senha), do: "auth-senha"

  defp init(socket, a) when a in [:login, :login_erro] do
    assign(socket,
      email: @demo_email,
      password: @demo_password,
      remember: true,
      tries_left: if(a == :login_erro, do: 2, else: 3),
      error: a == :login_erro,
      email_error: nil
    )
  end

  defp init(socket, :cadastro) do
    assign(socket,
      step: 2,
      name: "Ana Souza",
      email: @demo_email,
      password: @demo_password,
      cnpj: "12.345.678/0001-90",
      cnpj_state: :found,
      razao: "Bom Preço Distribuidora Ltda",
      cidade: "Feira de Santana",
      telefone: "(75) 99812-4410",
      regime: "Simples",
      plan: "negocio",
      errors: %{}
    )
  end

  defp init(socket, :codigo) do
    assign(socket,
      email: @demo_email,
      code: "4829",
      code_state: nil,
      seconds: 42,
      verified: false
    )
  end

  defp init(socket, :senha) do
    assign(socket, email: @demo_email, sent: true, email_error: nil)
  end

  ## Login

  @impl true
  def handle_event("validate", %{"login" => p}, %{assigns: %{live_action: a}} = socket)
      when a in [:login, :login_erro] do
    email = String.trim(p["email"] || "")

    {:noreply,
     assign(socket,
       email: email,
       password: p["password"] || "",
       remember: p["remember"] == "true",
       email_error: email_error(email)
     )}
  end

  def handle_event("login", %{"login" => p}, %{assigns: %{live_action: a}} = socket)
      when a in [:login, :login_erro] do
    email = String.trim(p["email"] || "")

    cond do
      socket.assigns.tries_left <= 0 ->
        {:noreply, socket}

      email_error(email) ->
        {:noreply, assign(socket, email: email, email_error: email_error(email))}

      email == @demo_email and p["password"] == @demo_password ->
        {:noreply, push_navigate(socket, to: "/templates/dashboard")}

      true ->
        {:noreply,
         assign(socket,
           email: email,
           password: p["password"] || "",
           error: true,
           tries_left: max(socket.assigns.tries_left - 1, 0)
         )}
    end
  end

  def handle_event("google", _params, socket) do
    {:noreply, push_navigate(socket, to: "/templates/dashboard")}
  end

  ## Cadastro

  def handle_event("validate", %{"signup" => p}, %{assigns: %{live_action: :cadastro}} = socket) do
    socket = assign(socket, :errors, %{})

    socket =
      case socket.assigns.step do
        1 ->
          assign(socket,
            name: p["name"] || "",
            email: String.trim(p["email"] || ""),
            password: p["password"] || ""
          )

        2 ->
          lookup(socket, p)

        _ ->
          socket
      end

    {:noreply, socket}
  end

  def handle_event("next", params, %{assigns: %{live_action: :cadastro}} = socket) do
    socket = if map_size(params) > 0, do: assign_signup(socket, params), else: socket

    case step_errors(socket.assigns) do
      errors when map_size(errors) == 0 ->
        if socket.assigns.step == 3,
          do: {:noreply, push_navigate(socket, to: "/templates/dashboard")},
          else: {:noreply, assign(socket, step: socket.assigns.step + 1, errors: %{})}

      errors ->
        {:noreply, assign(socket, errors: errors)}
    end
  end

  def handle_event("back", _params, %{assigns: %{live_action: :cadastro}} = socket) do
    {:noreply, assign(socket, step: max(socket.assigns.step - 1, 1), errors: %{})}
  end

  def handle_event("regime", %{"value" => r}, socket)
      when r in ["Simples", "Presumido", "Real"] do
    {:noreply, assign(socket, regime: r)}
  end

  def handle_event("plan", %{"id" => id}, socket) do
    {:noreply, assign(socket, plan: id)}
  end

  ## Código

  def handle_event("code", %{"verify" => %{"code" => code}}, socket) do
    {:noreply, assign(socket, code: String.replace(code, ~r/\D/, ""), code_state: nil)}
  end

  def handle_event("verify", params, socket) do
    code = get_in(params, ["verify", "code"]) || socket.assigns.code

    cond do
      String.length(code) < 6 ->
        {:noreply, assign(socket, code: code, code_state: :incomplete)}

      code == @demo_code ->
        {:noreply, push_navigate(socket, to: "/templates/dashboard")}

      true ->
        {:noreply, assign(socket, code: "", code_state: :wrong)}
    end
  end

  def handle_event("resend", _params, %{assigns: %{seconds: 0}} = socket) do
    Process.send_after(self(), :tick, 1000)
    {:noreply, assign(socket, seconds: 42, code_state: nil)}
  end

  def handle_event("resend", _params, socket), do: {:noreply, socket}

  ## Senha

  def handle_event("recover_validate", %{"recover" => %{"email" => email}}, socket) do
    email = String.trim(email)
    {:noreply, assign(socket, email: email, sent: false, email_error: email_error(email))}
  end

  def handle_event("recover", %{"recover" => %{"email" => email}}, socket) do
    email = String.trim(email)

    case email_error(email) do
      nil -> {:noreply, assign(socket, email: email, sent: true, email_error: nil)}
      error -> {:noreply, assign(socket, email: email, sent: false, email_error: error)}
    end
  end

  @impl true
  def handle_info(:tick, %{assigns: %{live_action: :codigo, seconds: s}} = socket) when s > 0 do
    Process.send_after(self(), :tick, 1000)
    {:noreply, assign(socket, seconds: s - 1)}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  ## Helpers

  defp email_error(""), do: "Informe o e-mail."

  defp email_error(email) do
    if Regex.match?(~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/, email), do: nil, else: "E-mail inválido."
  end

  defp assign_signup(socket, %{"signup" => p}) do
    case socket.assigns.step do
      1 ->
        assign(socket,
          name: p["name"] || "",
          email: String.trim(p["email"] || ""),
          password: p["password"] || ""
        )

      2 ->
        lookup(socket, p)

      _ ->
        socket
    end
  end

  defp assign_signup(socket, _), do: socket

  defp step_errors(%{step: 1} = a) do
    %{}
    |> put_error(:name, String.trim(a.name) == "", "Informe seu nome.")
    |> put_error(:email, email_error(a.email) != nil, "E-mail inválido.")
    |> put_error(:password, String.length(a.password) < 8, "Use ao menos 8 caracteres.")
  end

  defp step_errors(%{step: 2} = a) do
    %{}
    |> put_error(:cnpj, a.cnpj_state != :found, "Informe um CNPJ válido para continuar.")
  end

  defp step_errors(_), do: %{}

  defp put_error(errors, key, true, msg), do: Map.put(errors, key, msg)
  defp put_error(errors, _, false, _), do: errors

  # CNPJ lookup mock: 14 digits found in the table fill the company data.
  defp lookup(socket, p) do
    cnpj = p["cnpj"] || socket.assigns.cnpj
    digits = String.replace(cnpj, ~r/\D/, "")

    cond do
      String.length(digits) < 14 ->
        assign(socket, cnpj: cnpj, cnpj_state: :typing)

      company = @companies[digits] ->
        assign(socket,
          cnpj: cnpj,
          cnpj_state: :found,
          razao: company.razao,
          cidade: company.cidade,
          telefone: company.telefone
        )

      true ->
        assign(socket, cnpj: cnpj, cnpj_state: :missing, razao: p["razao"] || "")
    end
  end

  defp clock(s),
    do: "#{div(s, 60)}:#{s |> rem(60) |> Integer.to_string() |> String.pad_leading(2, "0")}"

  ## Render

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :plans, @plans)

    ~H"""
    <Shell.frame slug={@slug} palette={@palette}>
      <.login :if={@live_action in [:login, :login_erro]} {assigns} />
      <.cadastro :if={@live_action == :cadastro} {assigns} />
      <.codigo :if={@live_action == :codigo} {assigns} />
      <.senha :if={@live_action == :senha} {assigns} />
    </Shell.frame>
    """
  end

  defp footer(assigns) do
    ~H"""
    <span>© 2026 DevAction Labs</span><span>Privacidade · Termos</span>
    """
  end

  defp art(assigns) do
    ~H"""
    <.auth_art id={@id}>
      <:chip top="44px" right="40px">
        <.avatar initials="BP" color="t1" size="md" />
        <span><b>R$ 3.120,50</b><small class="text-[length:smaller]">Pix recebido · agora</small></span>
      </:chip>
      <:chip top="132px" right="120px">
        <span class="grid size-9 place-items-center rounded-[10px] bg-accent-soft text-accent-content">
          <.icon name="invoice" />
        </span>
        <span><b>NF-e 48.211</b><small class="text-[length:smaller]">autorizada pela SEFAZ</small></span>
      </:chip>
      <:quote
        author="Lia Santos"
        role="Mercearia Dona Lia · Feira de Santana"
        initials="LI"
        tone="t4"
      >
        Antes eu fechava o caixa no caderno. Hoje vejo pedidos, notas e o que tenho a receber numa tela só.
      </:quote>
    </.auth_art>
    """
  end

  ## Login

  defp login(assigns) do
    ~H"""
    <.auth_page form_id="login-form" on_submit="login" on_change="validate">
      <h1>Entrar no Ledger</h1>
      <p class="sub">Pedidos, notas e financeiro da sua empresa num lugar só.</p>
      <.oauth_button provider="google" block phx-click="google">Entrar com Google</.oauth_button>
      <div class="or">ou com e-mail</div>
      <.auth_alert :if={@error and @tries_left > 0}>
        <b>E-mail ou senha incorretos.</b> {tries_text(@tries_left)}
      </.auth_alert>
      <.auth_alert :if={@tries_left == 0}>
        <b>Acesso bloqueado por 15 minutos.</b> Use "Esqueci a senha".
      </.auth_alert>
      <.input
        name="login[email]"
        type="email"
        label="E-mail"
        icon="mail"
        value={@email}
        autocomplete="username"
        errors={List.wrap(@email_error)}
      />
      <.password_input
        id="login-password"
        name="login[password]"
        label="Senha"
        value={@password}
        autocomplete="current-password"
        state={@error && "error"}
        show_label="Mostrar a senha"
        hide_label="Ocultar a senha"
      >
        <:label_aside>
          <a href="#" phx-click={JS.navigate("/templates/auth-senha")} class="text-[13px]">Esqueci a senha</a>
        </:label_aside>
      </.password_input>
      <.checkbox
        name="login[remember]"
        color="primary"
        size={nil}
        hidden_input={false}
        checked={@remember}
        value="true"
        label="Manter conectado neste computador"
      />
      <.button
        color="mono"
        size="lg"
        type="submit"
        disabled={@tries_left == 0}
        class="w-full justify-center shadow-none!"
      >Entrar</.button>
      <p class="mt-1 mb-0 text-center text-[13px] leading-[18px] text-muted">
        Ainda não usa o Ledger?
        <a href="#" phx-click={JS.navigate("/templates/auth-cadastro")}>Criar conta grátis</a>
      </p>
      <:footer><.footer /></:footer>
      <:art><.art id="tpa" /></:art>
    </.auth_page>
    """
  end

  defp tries_text(1), do: "Resta 1 tentativa."
  defp tries_text(n), do: "Restam #{n} tentativas."

  ## Cadastro

  defp cadastro(assigns) do
    ~H"""
    <.auth_page form_id="signup-form" on_submit="next" on_change="validate">
      <.stepper color="primary" current={@step - 1}>
        <:step label="Você" marker="1" />
        <:step label="Empresa" marker="2" />
        <:step label="Plano" marker="3" />
      </.stepper>
      <%= case @step do %>
        <% 1 -> %>
          <h1>Crie sua conta</h1>
          <p class="sub">Comece com o que você usa no dia a dia. Leva dois minutos.</p>
          <.input
            name="signup[name]"
            label="Seu nome"
            icon="user"
            value={@name}
            errors={List.wrap(@errors[:name])}
          />
          <.input
            name="signup[email]"
            type="email"
            label="E-mail de trabalho"
            icon="mail"
            value={@email}
            errors={List.wrap(@errors[:email])}
          />
          <.password_input
            id="signup-password"
            name="signup[password]"
            label="Senha"
            value={@password}
            autocomplete="new-password"
            errors={List.wrap(@errors[:password])}
          />
          <.button color="mono" size="lg" type="submit" class="w-full justify-center shadow-none!">Continuar</.button>
        <% 2 -> %>
          <h1>Conte sobre sua empresa</h1>
          <p class="sub">Usamos esses dados nas notas fiscais. Dá para mudar depois.</p>
          <.input
            name="signup[cnpj]"
            label="CNPJ"
            icon="building"
            value={@cnpj}
            mask="cpf_cnpj"
            errors={List.wrap(@errors[:cnpj])}
            help={cnpj_help(@cnpj_state)}
          >
            <:trailing :if={@cnpj_state == :found}>
              <.badge canvas color="success" class="ml-auto">
                <.icon name="check" size="sm" />Encontrado
              </.badge>
            </:trailing>
          </.input>
          <.input name="signup[razao]" label="Razão social" icon="file" value={@razao} />
          <div class="grid grid-cols-2 gap-3">
            <.input name="signup[cidade]" label="Cidade" icon="map" value={@cidade} />
            <.input name="signup[telefone]" label="Telefone" icon="phone" value={@telefone} />
          </div>
          <.segmented
            id="signup-regime"
            label="Regime tributário"
            stretch
            value={@regime}
            on_change="regime"
            options={~w(Simples Presumido Real)}
          />
          <div class="flex flex-wrap items-center gap-2">
            <.button variant="outline" size="lg" phx-click="back"><.icon name="arrow-left" />Voltar</.button>
            <.button color="mono" size="lg" type="submit" class="flex-1 justify-center shadow-none!">Continuar</.button>
          </div>
        <% 3 -> %>
          <h1>Escolha seu plano</h1>
          <p class="sub">Todos incluem 14 dias grátis. Troque quando quiser.</p>
          <div class="flex flex-col gap-2.5">
            <button
              :for={{id, name, price, desc} <- @plans}
              type="button"
              class="block w-full cursor-pointer rounded-[16px] border-0 bg-transparent p-0 text-left focus-visible:shadow-[0_0_0_3px_var(--lu-focus)] focus-visible:outline-none"
              aria-pressed={to_string(id == @plan)}
              phx-click="plan"
              phx-value-id={id}
            >
              <.card
                variant={if id == @plan, do: "soft", else: "default"}
                color="primary"
                size="sm"
                class="!min-h-0"
              >
                <span class="flex items-center justify-between gap-3">
                  <span class="flex flex-col gap-0.5">
                    <b>{name}</b><small class="text-[length:smaller] text-muted">{desc}</small>
                  </span>
                  <b class="font-mono">{price}<small class="text-[length:smaller] text-muted">/mês</small></b>
                </span>
              </.card>
            </button>
          </div>
          <div class="flex flex-wrap items-center gap-2">
            <.button variant="outline" size="lg" phx-click="back"><.icon name="arrow-left" />Voltar</.button>
            <.button color="mono" size="lg" type="submit" class="flex-1 justify-center shadow-none!">Criar conta</.button>
          </div>
      <% end %>
      <:footer><.footer /></:footer>
      <:art><.art id="tps" /></:art>
    </.auth_page>
    """
  end

  defp cnpj_help(:missing), do: "CNPJ não encontrado. Preencha os dados abaixo."
  defp cnpj_help(_), do: nil

  ## Código

  defp codigo(assigns) do
    ~H"""
    <.auth_page form_id="verify-form" on_submit="verify" on_change="code">
      <span class="grid size-12 place-items-center rounded-[14px] bg-accent-soft text-accent-content">
        <.icon name="mail" />
      </span>
      <h1>Confira seu e-mail</h1>
      <p class="sub">
        Enviamos um código de 6 dígitos para <b class="text-ink">{@email}</b>.
      </p>
      <.otp_input
        id="verify-code"
        name="verify[code]"
        length={6}
        separator={3}
        value={@code}
        autofocus
        state={@code_state == :wrong && "error"}
        on_complete="verify"
        class="justify-start"
      />
      <p :if={@code_state == :wrong} class="m-0 text-[13px] leading-[18px] text-neg" role="alert">
        Código incorreto. Confira o e-mail e tente de novo.
      </p>
      <p
        :if={@code_state == :incomplete}
        class="m-0 text-[13px] leading-[18px] text-neg"
        role="alert"
      >
        Digite os 6 dígitos.
      </p>
      <.button color="mono" size="lg" type="submit" class="w-full justify-center shadow-none!">Confirmar</.button>
      <p class="m-0 text-[13px] leading-[18px] text-muted">
        Não chegou? <span :if={@seconds > 0} class="font-mono">Reenviar em {clock(@seconds)}</span>
        <a :if={@seconds == 0} href="#" phx-click="resend">Reenviar o código</a>
        · <a href="#" phx-click={JS.navigate("/templates/auth-login")}>Usar outro e-mail</a>
      </p>
      <:footer><.footer /></:footer>
      <:art><.art id="tpo" /></:art>
    </.auth_page>
    """
  end

  ## Senha

  defp senha(assigns) do
    ~H"""
    <.auth_page form_id="recover-form" on_submit="recover" on_change="recover_validate">
      <a
        href="#"
        phx-click={JS.navigate("/templates/auth-login")}
        class="inline-flex items-center gap-1.5 text-[13px] leading-[18px]"
      >
        <.icon name="arrow-left" size="sm" />Voltar para o login
      </a>
      <h1>Recuperar a senha</h1>
      <p class="sub">Informe o e-mail da conta. Mandamos um link que vale por 30 minutos.</p>
      <.input
        name="recover[email]"
        type="email"
        label="E-mail"
        icon="mail"
        value={@email}
        errors={List.wrap(@email_error)}
      />
      <.button color="mono" size="lg" type="submit" class="w-full justify-center shadow-none!">Enviar link</.button>
      <.alert
        :if={@sent}
        color="success"
        variant="soft"
        role="status"
        class="gap-2.5! py-3 text-[13.5px]!"
      >
        <:icon><.icon name="check-circle" /></:icon>
        <span>
          <b>Link enviado.</b><br />
          <span class="text-ink-2">Confira a caixa de entrada e o spam de {@email}.</span>
        </span>
      </.alert>
      <:footer><.footer /></:footer>
      <:art><.art id="tpf" /></:art>
    </.auth_page>
    """
  end
end
