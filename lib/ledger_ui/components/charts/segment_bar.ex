defmodule LedgerUI.Components.SegmentBar do
  @moduledoc """
  A thin bar split into segments, each as wide as its share of the total and tinted by its tone:
  how many items of a KPI are out of stock, on order... Rounded segments with a small gap.

      <.segment_bar segments={[
        %{value: 3, tone: "neg", label: "sem estoque"},
        %{value: 3, tone: "warn", label: "em encomenda"}
      ]} />

  A segment is `%{value: number, tone: tone, label: text, title: text}`. `tone` is `pos`, `warn`,
  `neg`, `info`, `neutral` or `c1`..`c5` (the long names `success`, `warning`, `error` work too);
  a segment of value 0 is left out. The bar is `role="img"` with an `aria-label` made from the
  segments (`3 sem estoque, 3 em encomenda`; without a `label` the tone word, translated); `label`
  replaces it.
  """
  use LedgerUI.Component

  alias LedgerUI.Components.OpsFormat, as: F

  @bar "flex h-1.5 w-full gap-[3px]"
  @seg "h-1.5 min-w-1 rounded-[4px]"

  attr :id, :string, default: nil

  attr :segments, :list,
    required: true,
    doc: "`[%{value: number, tone: tone, label: text, title: text}]`."

  attr :label, :string, default: nil, doc: "The `aria-label`; default: made from the segments."
  attr :class, :any, default: nil

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  attr :rest, :global

  def segment_bar(assigns) do
    changed0 = assigns.__changed__
    segs = segments(assigns.segments, assigns.locale)

    assigns =
      assigns
      |> assign(:bar_class, cx([@bar, assigns.class]))
      |> assign(:seg_class, @seg)
      |> assign(:segs, segs)
      |> assign(:aria, assigns.label || Enum.map_join(segs, ", ", & &1.text))

    assigns =
      settle(assigns, changed0,
        bar_class: [:class],
        seg_class: [],
        segs: [:segments, :locale],
        aria: [:segments, :locale, :label]
      )

    ~H"""
    <div id={@id} data-part="segment-bar" role="img" aria-label={@aria} class={@bar_class} {@rest}>
      <i
        :for={s <- @segs}
        :key={s.i}
        data-part="segment"
        data-tone={s.tone}
        class={[@seg_class, s.bg]}
        style={s.style}
        title={s.title}
      ></i>
    </div>
    """
  end

  defp segments(segments, locale) do
    segments
    |> Enum.with_index()
    |> Enum.filter(fn {s, _} -> (s[:value] || 0) > 0 end)
    |> Enum.map(fn {s, i} ->
      tone = F.tone(s[:tone])
      word = s[:label] || F.tone_word(tone, locale)
      text = "#{F.value(s.value, locale)} #{word}"

      %{
        i: i,
        tone: tone,
        bg: F.bg(tone),
        style: "flex:#{F.num(s.value * 1.0)}",
        title: s[:title] || text,
        text: text
      }
    end)
  end
end
