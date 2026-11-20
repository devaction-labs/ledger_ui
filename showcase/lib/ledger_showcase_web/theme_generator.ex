defmodule LedgerShowcaseWeb.ThemeGenerator do
  @moduledoc """
  The "Faça o seu tema" section of `/temas` (the vitrine's `tgSection` + `tgDrawer`): accent row,
  gray row, light/dark bar, a preview of real `LedgerUI` components that reacts live, and the
  drawer with the generated CSS.

  The section element carries `data-theme` of the chosen mode and an inline style with
  `--color-gray-50..950`, `--color-accent*` and the derived legacy variables
  (`LedgerShowcase.ThemeGen.style/3`); the library recomputes its `--lu-*` variables there. State
  lives in `ShowcaseLive` (`tg_acc`, `tg_gray`, `tg_mode`); the `ThemeGen` hook persists it in
  `localStorage["lu-tg"]`.
  """
  use Phoenix.Component
  use LedgerUI

  alias LedgerShowcase.ThemeGen

  attr :acc, :string, required: true
  attr :gray, :string, required: true
  attr :mode, :string, required: true

  def generator(assigns) do
    assigns =
      assign(assigns,
        style: ThemeGen.style(assigns.acc, assigns.gray, assigns.mode),
        code: ThemeGen.code(assigns.acc, assigns.gray),
        accents: ThemeGen.accents(),
        grays: ["ledger" | ThemeGen.gray_ids()],
        base: ThemeGen.base("light")["accent"]
      )

    ~H"""
    <section
      class="d-tg"
      id="tg"
      phx-hook="ThemeGen"
      data-theme={@mode}
      data-acc={@acc}
      data-gray={@gray}
      data-mode={@mode}
      style={@style}
    >
      <div class="d-tgh">
        <h2>Faça o seu tema</h2>
        <p>
          Escolha a cor de destaque e o cinza. Os componentes abaixo mudam na hora; “Gerar tema” entrega o CSS.
        </p>
      </div>
      <div class="d-tgacc" data-part="tg-accents">
        <button
          type="button"
          class={if @acc == "base", do: "on"}
          aria-pressed={to_string(@acc == "base")}
          phx-click="tg_acc"
          phx-value-id="base"
        >
          <i style={"background:#{@base}"}></i>Ledger
        </button>
        <button
          :for={a <- @accents}
          type="button"
          class={if @acc == a["id"], do: "on"}
          aria-pressed={to_string(@acc == a["id"])}
          phx-click="tg_acc"
          phx-value-id={a["id"]}
        >
          <i style={"background:#{hd(a["v"]["light"])}"}></i>{ThemeGen.cap(a["id"])}
        </button>
      </div>
      <div class="d-tggray" data-part="tg-grays">
        <%= for {g, k} <- Enum.with_index(@grays) do %>
          <span :if={k > 0} class="ln"></span>
          <button
            type="button"
            class={if @gray == g, do: "on"}
            aria-pressed={to_string(@gray == g)}
            phx-click="tg_gray"
            phx-value-id={g}
          >
            <i style={"background:#{ThemeGen.gray_swatch(g, @mode)}"}></i>{ThemeGen.cap(g)}
          </button>
        <% end %>
      </div>
      <div class="d-tgbar">
        <div class="d-tgseg" role="tablist" data-part="tg-mode">
          <button
            :for={{m, label, icon} <- [{"light", "Claro", "sun"}, {"dark", "Escuro", "moon"}]}
            type="button"
            role="tab"
            class={if @mode == m, do: "on"}
            aria-selected={to_string(@mode == m)}
            phx-click="tg_mode"
            phx-value-mode={m}
          >
            <.icon name={icon} size="md" />{label}
          </button>
        </div>
        <span class="div"></span>
        <.button
          type="button"
          id="tggen"
          color="primary"
          variant="solid"
          icon="huge-code"
          phx-click={LedgerUI.open("tgdr")}
        >
          Gerar tema
        </.button>
      </div>
      <div class="d-tgprev" data-part="tg-preview">
        <.preview />
      </div>
    </section>
    <.drawer
      id="tgdr"
      side="right"
      size="lg"
      title="Tema do seu projeto"
      description="O Ledger UI lê só o destaque (3 variáveis) e a escala de cinza; o resto é derivado."
    >
      <ol class="d-tgsteps">
        <li>
          <span>1</span>
          <div>
            <b>Cole no <code>assets/css/app.css</code></b>
            <div class="d-cb">
              <.clipboard
                id="tgcp"
                value={@code}
                color="neutral"
                variant="outline"
                size="sm"
                copied_label="Copiado"
                toast={nil}
                class="d-tgcp"
              >
                Copiar
              </.clipboard>
              <pre class="d-code" id="tgcode">{@code}</pre>
            </div>
          </div>
        </li>
        <li>
          <span>2</span>
          <div>
            <b>Claro e escuro</b>
            <span style="color:var(--muted)">
              O tema segue <code>data-theme</code>
              no <code>&lt;html&gt;</code>; troque com <code>&lt;.theme_switch /&gt;</code>.
            </span>
          </div>
        </li>
      </ol>
    </.drawer>
    """
  end

  # The preview grid (`TG.preview`) with real components.
  defp preview(assigns) do
    ~H"""
    <div class="d-tgc">
      <div class="flex flex-wrap justify-center gap-2">
        <.button color="neutral" variant="outline" type="button">Botão</.button>
        <.button color="primary" variant="solid" type="button">Primary</.button>
        <.button color="neutral" variant="soft" type="button">Filled</.button>
      </div>
    </div>
    <div class="d-tgc">
      <div class="flex flex-col gap-2.5">
        <b style="font-weight:500">Forma de pagamento</b>
        <.radio_group
          id="tg-pay"
          name="tg-pay"
          color="primary"
          value="card"
          options={[{"Cartão de crédito", "card"}, {"Pix", "pix"}, {"Boleto", "boleto"}]}
        />
      </div>
    </div>
    <div class="d-tgc">
      <div class="flex flex-col gap-3">
        <b style="font-weight:500">Perfil</b>
        <.checkbox
          id="tg-admin"
          color="primary"
          checked
          label="Administrador"
          description="Pode fazer qualquer ação."
        />
        <.checkbox id="tg-editor" color="primary" label="Editor" description="Lê, cria e altera." />
        <.checkbox id="tg-reader" color="primary" label="Leitor" description="Só lê." />
      </div>
    </div>
    <div class="d-tgc">
      <div class="flex flex-col gap-4">
        <.switch
          id="tg-sw1"
          color="primary"
          checked
          label="E-mails da conta"
          description="Atividade da sua conta."
        />
        <.switch
          id="tg-sw2"
          color="primary"
          checked
          label="Novidades"
          description="Produtos e recursos novos."
        />
        <.switch
          id="tg-sw3"
          color="primary"
          label="Segurança"
          description="Acessos e alertas."
        />
      </div>
    </div>
    <div class="d-tgc">
      <div class="flex flex-col gap-2">
        <b style="font-weight:500">Entrega</b>
        <.radio_group id="tg-ship" name="tg-ship" variant="card" color="primary" value="std">
          <:radio value="std" label="Padrão" description="4 a 10 dias úteis" />
          <:radio value="exp" label="Expressa" description="2 a 5 dias úteis" />
          <:radio value="next" label="Amanhã" description="1 dia útil" />
        </.radio_group>
      </div>
    </div>
    <div class="d-tgc">
      <.menu_list variant="pill" color="primary" class="w-full">
        <:item href="#" active><.icon name="grid" />Início</:item>
        <:item href="#" count="12"><.icon name="cart" />Pedidos</:item>
        <:item href="#"><.icon name="users" />Clientes</:item>
        <:item href="#"><.icon name="settings" />Ajustes</:item>
      </.menu_list>
    </div>
    <div class="d-tgc wide">
      <.stat_group class="w-full">
        <.stat_item
          icon="wallet"
          label="Faturamento"
          value="R$ 184.320"
          change="12,4%"
          note="vs. outubro"
          sparkline={[0, 3.5, 2.3, 6.1, 5.2, 8.7, 11, 9.8, 13.3, 15.1, 17.7, 22]}
        />
        <.stat_item
          label="Meta do mês"
          value="72%"
          goal={72}
          goal_label="R$ 184 mil de R$ 256 mil"
        />
        <.stat_item label="Total" value="R$ 3.120" tone="accent" />
      </.stat_group>
    </div>
    <div class="d-tgc wide">
      <div class="flex flex-wrap items-end gap-4">
        <div class="w-[280px]">
          <.input
            id="tg-email"
            name="tg-email"
            label="E-mail"
            icon="mail"
            placeholder="voce@empresa.com"
          />
        </div>
        <.segmented
          id="tg-seg"
          name="tg-seg"
          value="Semana"
          options={["Dia", "Semana", "Mês"]}
        />
        <.badge color="primary">Novo</.badge>
        <.button color="primary" variant="soft" size="sm" icon="huge-sparkles" type="button">
          Ação
        </.button>
        <.progress value={62} color="primary" class="w-40" />
      </div>
    </div>
    """
  end
end
