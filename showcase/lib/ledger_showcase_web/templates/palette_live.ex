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
      <div class="mx-auto box-border flex w-full max-w-[1440px] flex-col gap-[30px] bg-page px-12 pt-11 pb-14 text-ink">
        <div>
          <span class={Shell.sec_h()}>Paleta · data-palette="crepusculo"</span>
          <h1 class="mt-2.5 mb-1 font-display text-[44px] leading-[1.1] font-[650] tracking-[-.035em]">
            Crepúsculo<br /><span class="text-(--lu-title-2)">azul-noite, lavanda e o horizonte rosado</span>
          </h1>
          <p class="mt-3 mb-0 max-w-[70ch] text-[15px] text-muted">
            A paleta da landing nova sobre os mesmos componentes do Ledger UI. Títulos em Inter Tight, texto em Inter, números e códigos em Geist Mono.
          </p>
        </div>
        <div :for={{title, items} <- @swatches} class="flex flex-col gap-3">
          <p class={Shell.sec_h()}>{title}</p>
          <div class="grid grid-cols-4 gap-x-[18px] gap-y-3.5">
            <div :for={{label, token} <- items} class="flex min-w-0 items-center gap-3">
              <span
                class="size-[52px] flex-none rounded-[12px] bg-(--swatch) shadow-[inset_0_0_0_1px_var(--lu-line)]"
                style={"--swatch:#{var(token)}"}
              ></span>
              <span class="flex min-w-0 flex-col leading-[1.3]">
                <b class="text-[13.5px]">{label}</b><span class="font-mono text-[11.5px] text-muted">{token}</span>
              </span>
            </div>
          </div>
        </div>
        <div class="flex flex-col gap-3">
          <p class={Shell.sec_h()}>Gradientes</p>
          <div class="grid grid-cols-4 gap-[18px]">
            <div class="flex flex-col gap-2">
              <span class="h-[260px] rounded-[14px] bg-(image:--lu-gradient-sky)"></span>
              <b class="text-[13.5px]">Céu da abertura</b><span class="font-mono text-[11.5px] text-muted">--gradient-sky</span>
            </div>
            <div class="flex flex-col gap-2">
              <span class="h-[260px] rounded-[14px] bg-(image:--lu-gradient-feature) shadow-[inset_0_0_0_1px_var(--lu-line-feature)]"></span>
              <b class="text-[13.5px]">Plano em destaque</b><span class="font-mono text-[11.5px] text-muted">--gradient-feature</span>
            </div>
            <div class="flex flex-col gap-2">
              <span class="h-[260px] rounded-[14px] bg-(image:--lu-gradient-cta)"></span>
              <b class="text-[13.5px]">Painel final</b><span class="font-mono text-[11.5px] text-muted">--gradient-cta</span>
            </div>
            <div class="flex flex-col gap-2">
              <span class="relative h-[260px] overflow-hidden rounded-[14px] bg-tray">
                <svg viewBox="0 0 300 260" class="absolute inset-0 size-full">
                  <path
                    d="M-20 250 Q150 40 320 250"
                    fill="none"
                    stroke="var(--lu-light-arc)"
                    stroke-width="3"
                  />
                  <circle cx="150" cy="146" r="60" fill="var(--lu-glow)" />
                </svg>
              </span>
              <b class="text-[13.5px]">Arco de luz e brilho</b><span class="font-mono text-[11.5px] text-muted">--light-arc · --glow</span>
            </div>
          </div>
        </div>
        <div class="flex flex-col gap-3">
          <p class={Shell.sec_h()}>Nos componentes</p>
          <div class="grid grid-cols-[minmax(0,1.3fr)_minmax(0,1fr)] gap-[18px]">
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
            <div class="flex flex-col gap-3.5">
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
              <.card padded={false} class="flex-row! flex-wrap gap-x-[18px] gap-y-3.5 p-4">
                <span :for={{label, token} <- @states} class="flex items-center gap-2 text-[13.5px]">
                  <i
                    class="size-[9px] rounded-full bg-(--dot) shadow-[0_0_0_4px_color-mix(in_srgb,var(--dot)_22%,transparent)]"
                    style={"--dot:#{var(token)}"}
                  >
                  </i>{label}
                </span>
              </.card>
            </div>
          </div>
        </div>
      </div>
    </Shell.frame>
    """
  end

  # `--bg-page` (the name the board shows) is `--lu-bg-page` in the theme.
  defp var("--" <> name), do: "var(--lu-#{name})"
end
