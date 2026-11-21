defmodule LedgerShowcaseWeb.Pages do
  @moduledoc "Function components of the showcase pages (replica of `design/vitrine/index.html`)."
  use Phoenix.Component
  use LedgerUI

  alias LedgerShowcase.{Examples, Vitrine}
  alias LedgerShowcaseWeb.ThemeGenerator

  attr :cur, :string, required: true

  @doc "Left index: top links and the 15 groups."
  def side(assigns) do
    assigns =
      assign(assigns,
        templates: LedgerShowcase.Templates.pages(),
        top: [
          {"inicio", "/", "Introdução", "◎"},
          {"instalacao", "/instalacao", "Instalação", "↓"},
          {"cores", "/cores", "Cores", "◐"},
          {"temas", "/temas", "Temas", "✦"},
          {"novidades", "/novidades", "Novidades", "★"}
        ],
        nav: Vitrine.nav()
      )

    ~H"""
    <div class="d-top-links">
      <.link
        :for={{id, href, title, glyph} <- @top}
        patch={href}
        class={if @cur == id, do: "on"}
      ><b>{glyph}</b>{title}</.link>
    </div>
    <div :for={g <- @nav} class="d-grp">
      <h6>{g.short}</h6>
      <div class="d-lst">
        <.link :for={i <- g.items} patch={"/c/#{i.id}"} class={if @cur == i.id, do: "on"}>
          {i.name}<span :if={i.new} class="d-nw">Novo</span>
        </.link>
      </div>
    </div>
    <div class="d-grp" id="side-templates">
      <h6>Templates</h6>
      <div class="d-lst">
        <.link patch="/templates" class={if @cur == "templates", do: "on"}>
          Todos os templates<span class="d-nw">Novo</span>
        </.link>
        <.link :for={t <- @templates} navigate={"/templates/#{t.slug}"}>{t.title}</.link>
      </div>
    </div>
    """
  end

  attr :only_new, :boolean, default: false

  def intro(assigns) do
    groups =
      for g <- Vitrine.nav(),
          items = Enum.filter(g.items, &(not assigns.only_new or &1.new)),
          items != [],
          do: %{title: g.title, items: items}

    assigns =
      assign(assigns,
        groups: groups,
        count: Vitrine.count(),
        templates: LedgerShowcase.Templates.pages()
      )

    ~H"""
    <div class="d-hero">
      <h1>{if @only_new, do: "Novidades", else: "Ledger UI"}</h1>
      <p :if={@only_new}>
        Componentes que entraram no kit agora, com prévia em claro e escuro e movimento.
      </p>
      <p :if={!@only_new}>
        {@count} componentes para Phoenix LiveView, com prévia ao vivo, movimento e a API completa de cada um. Teal para dados, preto para ação, bandejas que abraçam painéis.
      </p>
    </div>
    <%= for g <- @groups do %>
      <div class="d-ghead">{g.title}</div>
      <div class="d-gridc">
        <.link :for={i <- g.items} patch={"/c/#{i.id}"}>
          <b>{i.name} <span :if={i.new} class="d-nw">Novo</span></b><span>{i.sub}</span>
        </.link>
      </div>
    <% end %>
    <%= if !@only_new do %>
      <div class="d-ghead" id="intro-templates">16 · Templates</div>
      <div class="d-gridc">
        <.link patch="/templates">
          <b>Todos os templates <span class="d-nw">Novo</span></b>
          <span>Dez telas inteiras, funcionando: auth, painel e tabela de pedidos, e a paleta Crepúsculo.</span>
        </.link>
        <.link :for={t <- @templates} navigate={"/templates/#{t.slug}"}>
          <b>{t.title}</b><span>{t.sub}</span>
        </.link>
      </div>
    <% end %>
    """
  end

  @doc "The index of the app templates: one card (a live thumbnail) per template."
  def templates(assigns) do
    assigns =
      assign(assigns,
        pages: LedgerShowcase.Templates.pages() ++ LedgerShowcase.Templates.palette_pages()
      )

    ~H"""
    <div class="d-hero">
      <h1>Templates</h1>
      <p>
        Telas inteiras do canvas, montadas só com componentes da biblioteca e funcionando de verdade:
        formulários que validam, gráficos com dados, tabela com seleção, gaveta e modal.
        Cada uma abre em tela cheia; o botão da lua alterna o tema e <code>?palette=crepusculo</code>
        troca a paleta.
      </p>
    </div>
    <%= for group <- ["Auth", "App", "Crepúsculo"] do %>
      <div class="d-ghead">16 · Templates · {group}</div>
      <div class="d-tpl-grid">
        <.link
          :for={t <- Enum.filter(@pages, &(&1.group == group))}
          navigate={tpl_path(t)}
          class="d-tpl"
          id={"tpl-card-#{tpl_id(t)}"}
        >
          <span class="d-tpl-th" aria-hidden="true">
            <iframe
              src={tpl_path(t)}
              title={t.title}
              loading="lazy"
              tabindex="-1"
              aria-hidden="true"
            ></iframe>
          </span>
          <b>{t.title}</b>
          <span>{t.sub}</span>
          <code>{tpl_path(t)}</code>
        </.link>
      </div>
    <% end %>
    """
  end

  defp tpl_path(%{path: path}), do: path
  defp tpl_path(%{slug: slug}), do: "/templates/#{slug}"

  defp tpl_id(%{palette: p, slug: slug}), do: "#{slug}-#{p}"
  defp tpl_id(%{slug: slug}), do: slug

  def install(assigns) do
    assigns = assign(assigns, steps: Vitrine.install())

    ~H"""
    <div class="d-hero">
      <h1>Instalação</h1>
      <p>Adicione o pacote, importe os componentes, os estilos e os hooks.</p>
    </div>
    <section :for={s <- @steps} class="d-doc">
      <h2>{s.t}</h2>
      <div class="d-cb"><pre class="d-code">{s.code}</pre></div>
      <p :if={s.note}>{s.note}</p>
    </section>
    """
  end

  def cores(assigns) do
    assigns = assign(assigns, colors: Vitrine.colors())

    ~H"""
    <div class="d-hero">
      <h1>Cores</h1>
      <p>
        {length(@colors)} tokens, cada um com valor claro e escuro. Use sempre o token, nunca o hex.
      </p>
    </div>
    <div class="d-sw">
      <div :for={c <- @colors}>
        <i><s style={"background:#{c.l}"}></s><s style={"background:#{c.d}"}></s></i>
        <p>--{c.n}<br />{c.l} · {c.d}</p>
      </div>
    </div>
    """
  end

  attr :tg_acc, :string, default: "base"
  attr :tg_gray, :string, default: "ledger"
  attr :tg_mode, :string, default: "light"

  def temas(assigns) do
    assigns = assign(assigns, code: Vitrine.temas_code(), palettes: Vitrine.palettes())

    ~H"""
    <div class="d-hero">
      <h1>Temas</h1>
      <p>
        Claro e escuro saem dos mesmos tokens, e a <b>paleta</b>
        é uma camada por cima: troca fundos, texto, marca, estados e gradientes sem mexer em nenhum componente.
        Clique numa cor ou em “Usar esta” para ver a vitrine inteira na paleta; o botão de cores no topo faz o mesmo de qualquer página.
      </p>
    </div>
    <ThemeGenerator.generator acc={@tg_acc} gray={@tg_gray} mode={@tg_mode} />
    <h2 style="margin:10px 0 6px;font-size:22px">Paletas prontas</h2>
    <section class="d-doc">
      <div class="d-cb">
        <button
          type="button"
          class="d-bt d-cp"
          data-copy={~s(<html data-theme="dark" data-palette="crepusculo">)}
        >
          Copiar
        </button>
        <pre class="d-code">{@code}</pre>
      </div>
    </section>
    <section :for={p <- @palettes} class="d-ex" id={"palette-#{p["id"]}"}>
      <h2>{p["name"]} <small>data-palette="{p["id"]}"</small></h2>
      <p style="color:var(--lu-ink-2);margin:-6px 0 14px">
        {p["description"]}<span :if={p["display"] != ""}> Títulos em <b>Inter Tight</b>.</span>
      </p>
      <div class="d-pgrid">
        <div
          :for={th <- ~w(light dark)}
          class="d-pcol"
          data-theme={th}
          data-palette={p["id"]}
        >
          <div class="d-phd">
            <b>{if th == "light", do: "Claro", else: "Escuro"}</b>
            <button type="button" class="d-papply" data-pal={p["id"]} data-th={th}>Usar esta</button>
          </div>
          <div :if={p["grad"]} class="d-psky" style={"background:#{p["grad"][th]}"}>
            <span>Céu da abertura</span>
          </div>
          <div class="d-psw">
            <button
              :for={[n, label, v] <- p["sw"][th]}
              type="button"
              class="d-swb"
              data-pal={p["id"]}
              data-th={th}
              title={"--#{n}: #{v}"}
            >
              <i style={"background:#{v}"}></i>
              <span><b>{label}</b><code>--{n}</code><small>{v}</small></span>
            </button>
          </div>
          <div class="d-pdemo">
            <.button color="mono" variant="solid" size="sm" shape="rounded" type="button">
              Criar agente
            </.button>
            <.button color="neutral" variant="outline" size="sm" shape="rounded" type="button">
              Ver planos
            </.button>
            <.badge canvas color="success" dot>Pronto</.badge>
            <.badge canvas color="warning" dot>Precisa de você</.badge>
            <.badge canvas color="info" dot>Trabalhando</.badge>
          </div>
        </div>
      </div>
    </section>
    <section class="d-doc">
      <p>
        A paleta Crepúsculo também está montada em tela cheia, só com componentes:
        <.link href="/templates/paleta" class="d-chipl">Paleta · Crepúsculo</.link>
      </p>
    </section>
    """
  end

  attr :id, :string, required: true
  attr :sections, :list, required: true

  @doc "One `.d-ex` per example: live preview (or static fallback) + code box."
  def examples(assigns) do
    ~H"""
    <section :for={s <- @sections} class="d-ex" id={"x-#{s.k}"}>
      <h2>{s.t}</h2>
      <div class="d-exb">
        <div class={["d-exp", s.wide && "wide"]}>
          <div :if={s.live} class="d-in2">{Examples.render(@id, s.index, %{})}</div>
          <div
            :if={!s.live}
            class="d-in2"
            id={"st-#{@id}-#{s.k}"}
            phx-update="ignore"
            data-static
          >
            {s.h}
          </div>
          <span :if={!s.live} class="d-stat" title="Ainda sem exemplo HEEx; HTML da vitrine">
            prévia estática
          </span>
        </div>
        <div class={["d-exc", s.long && "fold"]}>
          <span class="lng">.{s.lang}</span>
          <div class="acts">
            <button :if={s.long} type="button" data-fold>Expandir</button>
            <button type="button" data-copy={s.code}>Copiar</button>
          </div>
          <pre class="d-code">{s.code_html}</pre>
        </div>
      </div>
    </section>
    """
  end

  attr :p, :map, required: true

  def component(assigns) do
    p = assigns.p

    toc =
      Enum.map(p.sections, &{"x-#{&1.k}", &1.t}) ++
        [:sep, {"x-uso", "Uso"}] ++
        if(p.notes_html != [], do: [{"x-regras", "Regras"}], else: []) ++
        if p.api_html, do: [{"x-api", "Referência da API"}], else: []

    assigns = assign(assigns, toc: toc)

    ~H"""
    <div class="d-page">
      <div style="min-width:0">
        <div class="d-crumb">{@p.group}</div>
        <div class="d-hd">
          <h1>{@p.name}</h1>
          <div class="d-tb">
            <button class="d-ib" id="cpl" type="button" aria-label="Copiar o link">
              <svg viewBox="0 0 24 24">
                <rect x="8" y="8" width="12" height="12" rx="3" /><path d="M16 8V6a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h2" />
              </svg>
            </button>
            <button class="d-bt" id="full" type="button" data-id={@p.id} data-name={@p.name}>
              <svg viewBox="0 0 24 24">
                <path d="M4 9V5a1 1 0 0 1 1-1h4M20 9V5a1 1 0 0 0-1-1h-4M4 15v4a1 1 0 0 0 1 1h4M20 15v4a1 1 0 0 1-1 1h-4" />
              </svg><span>Tela cheia</span>
            </button>
          </div>
        </div>
        <p class="d-sub">{@p.subtitle}</p>
        <p style="color:var(--lu-ink-2);max-width:760px;margin:0">{@p.summary_html}</p>
        <.examples id={@p.id} sections={@p.sections} />
        <section class="d-doc d-ex" id="x-uso">
          <h2>Uso</h2>
          <div class="d-cb">
            <button class="d-bt d-cp" type="button" data-copy={@p.usage}>Copiar</button>
            <pre class="d-code">{@p.usage_html}</pre>
          </div>
        </section>
        <section :if={@p.notes_html != []} class="d-doc d-ex" id="x-regras">
          <h2>Regras</h2>
          <ul>
            <li :for={n <- @p.notes_html}>{n}</li>
          </ul>
        </section>
        <section :if={@p.api_html} class="d-doc d-api d-ex" id="x-api">
          <h2>Referência da API</h2>
          {@p.api_html}
        </section>
        <div class="d-pn">
          <.link :if={@p.prev} patch={"/c/#{@p.prev.id}"}>
            <small>Anterior</small><b>{@p.prev.name}</b>
          </.link>
          <.link :if={@p.next} patch={"/c/#{@p.next.id}"} class="r">
            <small>Próximo</small><b>{@p.next.name}</b>
          </.link>
        </div>
      </div>
      <nav class="d-toc" id="toc">
        <h6>Nesta página</h6>
        <%= for t <- @toc do %>
          <div :if={t == :sep} class="sep"></div>
          <a :if={t != :sep} data-go={elem(t, 0)}>{elem(t, 1)}</a>
        <% end %>
      </nav>
    </div>
    """
  end
end
