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
  The landscape of `hero_card/1`: a thin delegate to `LedgerUI.Components.Illustration.summit/1`
  (`svg.lu-summit` painted with the `--hero-*` tokens). Decorative: `aria-hidden`.
  """
  def hero_summit(assigns) do
    ~H"""
    <LedgerUI.Components.Illustration.summit id={@id} class={@class} {@rest} />
    """
  end
end
