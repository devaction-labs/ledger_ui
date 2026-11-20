defmodule LedgerUI.Components.HeroCard do
  @moduledoc """
  The hero card: the welcome or the insight at the top of a page. The text on the left (an
  eyebrow in mono caps with an optional icon, the title, the description, a goal meter or a
  list of steps, and the actions) and a landscape on the right that fades into the card.

      <.hero_card eyebrow="Bem-vindo de volta" title="Metas do trimestre" description="Alinhe a equipe.">
        <:actions>
          <.button color="mono" size="lg"><.icon name="plus" />Novo pedido</.button>
        </:actions>
      </.hero_card>

      <.hero_card
        eyebrow="Bom dia, Alex"
        title="Novembro está 12% acima de outubro"
        meta="Meta de novembro"
        meta_value="R$ 184 mil de R$ 250 mil"
        meter={74}
        animated
      />

      <.hero_card
        eyebrow="Configuração"
        title="Falta pouco para emitir sua primeira NF-e"
        picture="none"
        steps={[
          %{label: "Empresa", state: "done"},
          %{label: "Série e numeração", state: "current"},
          %{label: "Teste"}
        ]}
      />

  The picture on the right is the summit landscape (`picture="summit"`, drawn with the `--hero-*`
  tokens, so it follows the theme), an `<img>` (`src`), the `:art` slot (your own SVG) or nothing
  (`picture="none"`). `size="lg"` makes the card taller; `variant="panel"` puts it on the panel color
  instead of the soft gray and `variant="ai"` is the soft card with the violet eyebrow (suggestions
  from the assistant). `animated` adds the canvas loop (`mo-hero`): the text rises, the landscape
  breathes and the meter fills.

  `hero_summit/1` is the landscape on its own, for other surfaces. Give each one on the page its
  own `id` (the gradient ids derive from it).
  """
  use LedgerUI.Component

  @styles %{
    "size" => %{"md" => "md", "lg" => "lg"},
    "variant" => %{"soft" => "soft", "panel" => "panel", "ai" => "soft ai"}
  }

  attr :eyebrow, :string, default: nil, doc: "The small mono caps line above the title."
  attr :title, :string, required: true
  attr :description, :string, default: nil
  attr :src, :string, default: nil, doc: "The picture on the right (replaces the landscape)."
  attr :alt, :string, default: ""
  attr :position, :string, default: "center", doc: "The crop of the picture (`object-position`)."

  attr :picture, :string,
    default: "summit",
    values: ~w(summit none),
    doc: "The picture when there is no `src` nor `:art` slot."

  attr :size, :string, default: "md", values: ~w(md lg)
  attr :variant, :string, default: "soft", values: ~w(soft panel ai)
  attr :heading, :string, default: "h2", values: ~w(h1 h2 h3)
  attr :meta, :string, default: nil, doc: "The label of the goal line (needs `meta_value`)."
  attr :meta_value, :string, default: nil, doc: "The figures of the goal line, already formatted."
  attr :meter, :integer, default: nil, doc: "Goal progress, 0 to 100: draws the bar under `meta`."

  attr :steps, :list,
    default: [],
    doc:
      "Chips of a checklist: `%{label: \"Empresa\", state: \"done\" | \"current\" | \"todo\"}`."

  attr :animated, :boolean, default: false, doc: "The canvas loop (`mo-hero`)."
  attr :id, :string, default: nil, doc: "Names the card (`aria-labelledby`) and prefixes the art."
  attr :class, :any, default: nil
  attr :rest, :global

  slot :actions
  slot :art, doc: "The picture as markup (an SVG), instead of `src`."
  slot :icon, doc: "An icon before the eyebrow."
  slot :inner_block, doc: "Under the description: a note, a form, anything of your own."

  def hero_card(assigns) do
    steps =
      for step <- assigns.steps do
        case Map.get(step, :state, "todo") do
          "done" -> %{label: step.label, attrs: [class: "d"]}
          "current" -> %{label: step.label, attrs: [class: "c", "aria-current": "step"]}
          _ -> %{label: step.label, attrs: []}
        end
      end

    meta? = assigns.meta != nil or assigns.meter != nil

    assigns =
      assigns
      |> assign(
        :classes,
        cx([
          "lu-hero",
          @styles["size"][assigns.size],
          @styles["variant"][assigns.variant],
          assigns.animated && "mo-hero",
          assigns.class
        ])
      )
      |> assign(:steps, steps)
      |> assign(:show_meta, meta?)
      |> assign(:has_in, meta? or steps != [] or not blank_slot?(assigns.inner_block))
      |> assign(:title_id, assigns.id && "#{assigns.id}-title")
      |> assign(:art_id, "#{assigns.id || "hero"}-art")
      |> assign(:img_style, assigns.position != "center" && "object-position:#{assigns.position}")
      |> assign(:summit?, assigns.src == nil and assigns.art == [] and assigns.picture != "none")

    ~H"""
    <section
      data-part="hero-card"
      id={@id}
      class={@classes}
      aria-labelledby={@title_id}
      {@rest}
    >
      <div class="tx">
        <span :if={@eyebrow} class="eb">{render_slot(@icon)}{@eyebrow}</span>
        <.dynamic_tag tag_name={@heading} id={@title_id}>{@title}</.dynamic_tag>
        <p :if={@description}>{@description}</p>
        <div :if={@has_in} class="in">
          <div :if={@show_meta} class="lu-hmeta">
            <div class="lu-row" style="justify-content:space-between">
              <span>{@meta}</span>
              <b>{@meta_value}</b>
            </div>
            <span
              :if={@meter}
              class="lu-smeter"
              role="progressbar"
              aria-label={@meta}
              aria-valuemin="0"
              aria-valuemax="100"
              aria-valuenow={@meter}
            ><i style={"--sp:#{@meter}%"}></i></span>
          </div>
          <div :if={@steps != []} class="lu-hsteps">
            <span :for={step <- @steps} {step.attrs}>{step.label}</span>
          </div>
          {render_slot(@inner_block)}
        </div>
        <div :if={@actions != []} class="ac">{render_slot(@actions)}</div>
      </div>
      <div :if={@src} class="art">
        <img src={@src} alt={@alt} style={@img_style} />
      </div>
      <div :if={@art != []} class="art">{render_slot(@art)}</div>
      <div :if={@summit?} class="art"><.hero_summit id={@art_id} /></div>
    </section>
    """
  end

  # A slot is blank when it only holds whitespace (the body of a component that has named slots
  # and nothing else): it must not open the `.in` box.
  defp blank_slot?(slots) do
    Enum.all?(slots, fn
      %{inner_block: %Phoenix.LiveView.Rendered{static: static, dynamic: dynamic}} ->
        Enum.all?(static, &(String.trim(&1) == "")) and dynamic.(false) == []

      _ ->
        false
    end)
  end

  attr :id, :string,
    default: "hs",
    doc: "Prefix of the gradient ids (`hs-sky`...): one per summit on a page."

  attr :class, :any, default: nil
  attr :rest, :global

  @doc """
  The landscape of `hero_card/1`: sky, sun, stars, three ridges and a dotted trail, painted with
  the `--hero-*` tokens (light and dark). Decorative: `aria-hidden`.
  """
  def hero_summit(assigns) do
    ~H"""
    <svg
      data-part="summit"
      class={cx(["lu-summit", "teal", @class])}
      viewBox="0 0 520 300"
      preserveAspectRatio="xMidYMid slice"
      aria-hidden="true"
      {@rest}
    >
      <defs>
        <linearGradient id={"#{@id}-sky"} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stop-color="var(--hero-sky1)" />
          <stop offset="1" stop-color="var(--hero-sky2)" />
        </linearGradient>
        <linearGradient id={"#{@id}-m1"} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stop-color="var(--hero-m1a)" />
          <stop offset="1" stop-color="var(--hero-m1b)" />
        </linearGradient>
        <linearGradient id={"#{@id}-m2"} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stop-color="var(--hero-m2a)" />
          <stop offset="1" stop-color="var(--hero-m2b)" />
        </linearGradient>
        <linearGradient id={"#{@id}-m3"} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stop-color="var(--hero-m3a)" />
          <stop offset="1" stop-color="var(--hero-m3b)" />
        </linearGradient>
        <radialGradient id={"#{@id}-sun"} cx=".5" cy=".5" r=".5">
          <stop offset="0" stop-color="var(--hero-sun)" />
          <stop offset="1" stop-color="var(--hero-sun)" stop-opacity="0" />
        </radialGradient>
      </defs>
      <rect width="520" height="300" fill={"url(##{@id}-sky)"} />
      <circle class="sun" cx="350" cy="110" r="90" fill={"url(##{@id}-sun)"} />
      <circle class="sun-c" cx="350" cy="110" r="26" fill="var(--hero-sun)" opacity=".9" />
      <g class="st">
        <circle cx="90" cy="40" r="1.2" />
        <circle cx="160" cy="70" r="1" />
        <circle cx="430" cy="34" r="1.3" />
        <circle cx="470" cy="80" r="1" />
        <circle cx="250" cy="28" r="1" />
      </g>
      <path
        class="m3"
        d="M0 205 L70 150 L120 175 L190 110 L250 160 L310 120 L380 170 L450 125 L520 160 V300 H0 Z"
        fill={"url(##{@id}-m3)"}
      />
      <path
        class="m2"
        d="M0 235 L60 200 L130 225 L210 170 L270 210 L340 185 L420 225 L520 190 V300 H0 Z"
        fill={"url(##{@id}-m2)"}
      />
      <path
        class="m1"
        d="M0 268 L90 238 L170 258 L260 228 L350 262 L440 240 L520 258 V300 H0 Z"
        fill={"url(##{@id}-m1)"}
      />
      <path
        class="ln"
        d="M180 300 C 230 270, 300 268, 330 250 S 400 230, 430 238"
        fill="none"
        stroke="var(--hero-line)"
        stroke-width="1.5"
        stroke-dasharray="3 5"
        pathLength="1"
      />
    </svg>
    """
  end
end
