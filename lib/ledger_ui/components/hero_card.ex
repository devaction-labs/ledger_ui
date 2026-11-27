defmodule LedgerUI.Components.HeroCard do
  @moduledoc """
  The hero card: the welcome or the insight at the top of a page. The text on the left (an
  eyebrow (mono, 11.5px, upper-case) with an optional ink icon, the title, the description, a goal meter or a
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

  The picture on the right is the summit landscape (`picture="summit"`, drawn with the `--lu-hero-*`
  tokens, so it follows the theme), an `<img>` (`src`), the `:art` slot (your own SVG) or nothing
  (`picture="none"`). `size="lg"` makes the card taller; `variant="panel"` puts it on the panel color
  instead of the soft gray (with a 1px `border-line` and `shadow-xs`, like a card) and `variant="ai"` is the soft card with the violet eyebrow (suggestions
  from the assistant). `animated` adds the canvas loop: the text rises, the landscape breathes and
  the meter fills (`lu-hero-*` keyframes). Styled only with Tailwind utilities.

  `hero_summit/1` is the landscape on its own, for other surfaces. Give each one on the page its
  own `id` (the gradient ids derive from it).
  """
  use LedgerUI.Component

  @sizes %{
    "md" => %{root: "min-h-[230px]", tx: "gap-2.5 px-[34px] py-[30px]", h: "text-[26px]"},
    "lg" => %{root: "min-h-[300px]", tx: "gap-3 px-11 py-[42px]", h: "text-[34px]"}
  }

  @variants %{
    "soft" => "bg-sunken",
    "panel" => "border border-line bg-panel shadow-xs",
    "ai" => "bg-sunken"
  }

  # the canvas loop: the children of the text rise one after another, the meter fills, the landscape moves
  @loop [
    "[&_[data-part=hero-text]>*]:animate-[lu-hero-in_7s_cubic-bezier(.2,.8,.2,1)_infinite]",
    "[&_[data-part=hero-text]>:nth-child(2)]:animate-[lu-hero-in_7s_cubic-bezier(.2,.8,.2,1)_.1s_infinite]",
    "[&_[data-part=hero-text]>:nth-child(3)]:animate-[lu-hero-in_7s_cubic-bezier(.2,.8,.2,1)_.2s_infinite]",
    "[&_[data-part=hero-text]>:nth-child(4)]:animate-[lu-hero-in_7s_cubic-bezier(.2,.8,.2,1)_.3s_infinite]",
    "[&_[data-part=hero-text]>:nth-child(5)]:animate-[lu-hero-in_7s_cubic-bezier(.2,.8,.2,1)_.4s_infinite]",
    "[&_[data-part=hero-meter]_i]:animate-[lu-hero-fill_7s_cubic-bezier(.2,.8,.2,1)_infinite]",
    "[&_.m3]:animate-[lu-hero-drift_14s_ease-in-out_infinite]",
    "[&_.m2]:animate-[lu-hero-drift_10s_ease-in-out_infinite_reverse]",
    "[&_.sun]:origin-[350px_110px] [&_.sun]:animate-[lu-hero-sun_7s_ease-in-out_infinite]",
    "[&_.sun-c]:origin-[350px_110px] [&_.sun-c]:animate-[lu-hero-sun_7s_ease-in-out_infinite]",
    "[&_.ln]:[stroke-dashoffset:1] [&_.ln]:animate-[lu-hero-line_7s_ease-in-out_infinite]"
  ]

  # the chips of a checklist: the dot and the box follow the state
  @step "inline-flex h-7 items-center gap-1.5 rounded-md px-2.5 text-[12.5px] before:size-[7px] before:rounded-full before:content-['']"
  @steps %{
    "done" => "bg-[color-mix(in_srgb,var(--lu-ink)_5%,transparent)] text-ink-2 before:bg-pos",
    "current" =>
      "bg-panel text-ink shadow-[inset_0_0_0_1px_var(--lu-line-strong)] before:bg-accent-500 before:shadow-[0_0_0_3px_var(--lu-focus)]",
    "todo" =>
      "bg-[color-mix(in_srgb,var(--lu-ink)_5%,transparent)] text-muted before:bg-line-strong"
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
        state = Map.get(step, :state, "todo")
        attrs = if state == "current", do: ["aria-current": "step"], else: []
        %{label: step.label, class: [@step, @steps[state] || @steps["todo"]], attrs: attrs}
      end

    meta? = assigns.meta != nil or assigns.meter != nil
    size = @sizes[assigns.size]

    assigns =
      assigns
      |> assign(
        :classes,
        cx([
          "relative isolate flex w-full overflow-hidden rounded-xl text-ink",
          size.root,
          @variants[assigns.variant],
          assigns.animated && @loop,
          assigns.class
        ])
      )
      |> assign(:tx_class, ["relative z-2 flex flex-[0_1_60%] flex-col items-start", size.tx])
      |> assign(
        :h_class,
        [
          "m-0 max-w-[22ch] font-display leading-[1.15] font-[650] tracking-[-.03em]",
          size.h
        ]
      )
      |> assign(
        :eb_class,
        [
          "inline-flex items-center gap-[7px] font-mono text-[11.5px] leading-none font-semibold tracking-[.09em] uppercase [&_svg]:size-[15px]",
          if(assigns.variant == "ai",
            do: "text-violet [&_svg]:text-violet",
            else: "text-muted [&_svg]:text-ink"
          )
        ]
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
      <div data-part="hero-text" class={@tx_class}>
        <span :if={@eyebrow} data-part="hero-eyebrow" class={@eb_class}>{render_slot(@icon)}{@eyebrow}</span>
        <.dynamic_tag tag_name={@heading} id={@title_id} data-part="hero-title" class={@h_class}>
          {@title}
        </.dynamic_tag>
        <p
          :if={@description}
          data-part="hero-description"
          class="m-0 max-w-[46ch] text-[14.5px] leading-normal text-ink-2"
        >
          {@description}
        </p>
        <div :if={@has_in} data-part="hero-extra" class="mt-1 w-full max-w-[420px]">
          <div
            :if={@show_meta}
            data-part="hero-meta"
            class="flex flex-col gap-1.5 text-[13px] text-muted"
          >
            <div data-part="hero-meta-row" class="flex flex-wrap items-center justify-between gap-2.5">
              <span>{@meta}</span>
              <b data-part="hero-meta-value" class="font-semibold tabular-nums text-ink">{@meta_value}</b>
            </div>
            <span
              :if={@meter}
              data-part="hero-meter"
              class="mt-0.5 block h-1.5 overflow-hidden rounded-[4px] bg-[color-mix(in_srgb,var(--lu-ink)_8%,transparent)]"
              role="progressbar"
              aria-label={@meta}
              aria-valuemin="0"
              aria-valuemax="100"
              aria-valuenow={@meter}
            ><i
              data-part="hero-meter-bar"
              class="block h-full w-(--lu-sp) rounded-[4px] bg-[linear-gradient(90deg,var(--lu-accent-600),var(--lu-accent-400))]"
              style={"--lu-sp:#{@meter}%"}
            ></i></span>
          </div>
          <div :if={@steps != []} data-part="hero-steps" class="flex flex-wrap gap-1.5">
            <span :for={step <- @steps} data-part="hero-step" class={step.class} {step.attrs}>{step.label}</span>
          </div>
          {render_slot(@inner_block)}
        </div>
        <div :if={@actions != []} data-part="hero-actions" class="mt-2 flex flex-wrap gap-2">
          {render_slot(@actions)}
        </div>
      </div>
      <div :if={@src} data-part="hero-art" class={art_class()}>
        <img src={@src} alt={@alt} style={@img_style} />
      </div>
      <div :if={@art != []} data-part="hero-art" class={art_class()}>{render_slot(@art)}</div>
      <div :if={@summit?} data-part="hero-art" class={art_class()}>
        <.hero_summit id={@art_id} class="size-full" />
      </div>
    </section>
    """
  end

  # The picture fades into the card from the left.
  defp art_class do
    [
      "absolute inset-y-0 right-0 z-1 w-[56%] [-webkit-mask-image:linear-gradient(90deg,transparent_0%,#000_42%)] [mask-image:linear-gradient(90deg,transparent_0%,#000_42%)]",
      "[&_svg]:block [&_svg]:size-full [&_img]:block [&_img]:size-full [&_img]:object-cover"
    ]
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
