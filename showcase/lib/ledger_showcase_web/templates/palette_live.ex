defmodule LedgerShowcaseWeb.Templates.PaletteLive do
  @moduledoc """
  The Crepúsculo palette page (`/templates/paleta`, board `TCrepPaleta`, page 14 of the canvas): the
  tokens grouped by role (surfaces, text, borders and brand, agent states, gradients) as
  swatches, and the same components on the palette: `hero_card`, `stat_group`, the state dots.

  The page always shows the `crepusculo` palette (`data-palette` on the template root), whatever
  the palette of the showcase; light or dark follows the theme. Swatches and gradients are
  layout of the page (`div`s painted with the tokens); the rest are library components.
  """
  use Phoenix.LiveView
  use LedgerUI

  alias LedgerShowcaseWeb.Templates.Shell

  @swatches [
    {"Base e superfícies",
     [
       {"Fundo da página", "--bg-page"},
       {"Fundo alternativo", "--bg-shell"},
       {"Painel (cards)", "--panel-glass"},
       {"Painel forte", "--panel-strong"},
       {"Tela do card", "--bg-tray"},
       {"Tela do card 2", "--bg-panel"},
       {"Terminal", "--terminal"},
       {"Chip", "--chip"}
     ]},
    {"Texto",
     [
       {"Principal", "--ink"},
       {"Secundário", "--ink-2"},
       {"Apoio (corpo)", "--muted"},
       {"Fraco (legendas)", "--subtle"},
       {"Segunda linha dos títulos", "--title-2"}
     ]},
    {"Bordas e marca",
     [
       {"Linha fina", "--line"},
       {"Linha de destaque", "--line-accent"},
       {"Botão principal", "--inverse"},
       {"Texto do botão", "--on-inverse"},
       {"Botão secundário", "--btn-2-bg"},
       {"Borda do secundário", "--btn-2-line"},
       {"Marca (índigo)", "--accent"},
       {"Brilho azul-violeta", "--glow"}
     ]},
    {"Estados dos agentes",
     [
       {"Trabalhando", "--state-working"},
       {"Precisa de você", "--state-needs-you"},
       {"Pronto", "--state-ready"},
       {"Pausado", "--state-paused"},
       {"Erro", "--state-error"}
     ]}
  ]

  @states [
    {"Trabalhando", "--state-working"},
    {"Precisa de você", "--state-needs-you"},
    {"Pronto", "--state-ready"},
    {"Pausado", "--state-paused"},
    {"Erro", "--state-error"}
  ]

  @orders_spark [6, 30, 0, 48, 77, 59, 95, 131, 113, 149, 184, 220]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Paleta Crepúsculo · Templates", slug: "paleta")}
  end

  @impl true
  def render(assigns) do
    assigns =
      assign(assigns, swatches: @swatches, states: @states, spark: @orders_spark)

    ~H"""
    <Shell.frame slug={@slug} palette="crepusculo" scroll>
      <div style="width:100%;max-width:1440px;margin:0 auto;padding:44px 48px 56px;box-sizing:border-box;background:var(--bg-page);color:var(--ink);display:flex;flex-direction:column;gap:30px">
        <div>
          <span class="lu-sec-h" style="margin:0">Paleta · data-palette="crepusculo"</span>
          <h1 style="margin:10px 0 4px;font:650 44px/1.1 var(--font-display);letter-spacing:-.035em">
            Crepúsculo<br /><span style="color:var(--title-2)">azul-noite, lavanda e o horizonte rosado</span>
          </h1>
          <p style="margin:12px 0 0;max-width:70ch;color:var(--muted);font-size:15px">
            A paleta da landing nova sobre os mesmos componentes do Ledger UI. Títulos em Inter Tight, texto em Inter, números e códigos em Geist Mono.
          </p>
        </div>
        <div :for={{title, items} <- @swatches} style="display:flex;flex-direction:column;gap:12px">
          <p class="lu-sec-h" style="margin:0">{title}</p>
          <div style="display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:14px 18px">
            <div
              :for={{label, token} <- items}
              style="display:flex;gap:12px;align-items:center;min-width:0"
            >
              <span style={"width:52px;height:52px;border-radius:12px;flex:none;background:var(#{token});box-shadow:inset 0 0 0 1px var(--line)"}></span>
              <span style="display:flex;flex-direction:column;line-height:1.3;min-width:0">
                <b style="font-size:13.5px">{label}</b><code
                  class="mono"
                  style="font-size:11.5px;color:var(--muted)"
                >{token}</code>
              </span>
            </div>
          </div>
        </div>
        <div style="display:flex;flex-direction:column;gap:12px">
          <p class="lu-sec-h" style="margin:0">Gradientes</p>
          <div style="display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:18px">
            <div style="display:flex;flex-direction:column;gap:8px">
              <span style="height:260px;border-radius:14px;background:var(--gradient-sky);"></span>
              <b style="font-size:13.5px">Céu da abertura</b><code
                class="mono"
                style="font-size:11.5px;color:var(--muted)"
              >--gradient-sky</code>
            </div>
            <div style="display:flex;flex-direction:column;gap:8px">
              <span style="height:260px;border-radius:14px;background:var(--gradient-feature);box-shadow:inset 0 0 0 1px var(--line-feature)"></span>
              <b style="font-size:13.5px">Plano em destaque</b><code
                class="mono"
                style="font-size:11.5px;color:var(--muted)"
              >--gradient-feature</code>
            </div>
            <div style="display:flex;flex-direction:column;gap:8px">
              <span style="height:260px;border-radius:14px;background:var(--gradient-cta);"></span>
              <b style="font-size:13.5px">Painel final</b><code
                class="mono"
                style="font-size:11.5px;color:var(--muted)"
              >--gradient-cta</code>
            </div>
            <div style="display:flex;flex-direction:column;gap:8px">
              <span style="height:260px;border-radius:14px;background:var(--bg-tray);position:relative;overflow:hidden">
                <svg viewBox="0 0 300 260" style="position:absolute;inset:0;width:100%;height:100%">
                  <path
                    d="M-20 250 Q150 40 320 250"
                    fill="none"
                    stroke="var(--light-arc)"
                    stroke-width="3"
                  />
                  <circle cx="150" cy="146" r="60" fill="var(--glow)" />
                </svg>
              </span>
              <b style="font-size:13.5px">Arco de luz e brilho</b><code
                class="mono"
                style="font-size:11.5px;color:var(--muted)"
              >--light-arc · --glow</code>
            </div>
          </div>
        </div>
        <div style="display:flex;flex-direction:column;gap:12px">
          <p class="lu-sec-h" style="margin:0">Nos componentes</p>
          <div style="display:grid;grid-template-columns:minmax(0,1.3fr) minmax(0,1fr);gap:18px">
            <.hero_card
              id="paleta-hero"
              eyebrow="Agentes"
              title="Seus agentes trabalham enquanto você dorme"
              description="Três concluíram tarefas desde ontem. Um precisa de você."
            >
              <:actions>
                <.button color="mono" size="lg"><.icon name="plus" />Criar agente</.button>
                <.button variant="outline" size="lg">Ver planos</.button>
              </:actions>
            </.hero_card>
            <div style="display:flex;flex-direction:column;gap:14px">
              <.stat_group>
                <.stat_item
                  label="Tarefas hoje"
                  value="128"
                  delta="18%"
                  hint="vs. ontem"
                  spark={@spark}
                />
                <.stat_item label="Precisam de você" value="3" tone="accent" />
              </.stat_group>
              <div class="lu-card" style="padding:16px;display:flex;flex-wrap:wrap;gap:14px 18px">
                <span :for={{label, token} <- @states} class="lu-row" style="gap:8px;font-size:13.5px">
                  <i style={"width:9px;height:9px;border-radius:50%;background:var(#{token});box-shadow:0 0 0 4px color-mix(in srgb,var(#{token}) 22%,transparent)"}>
                  </i>{label}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Shell.frame>
    """
  end
end
