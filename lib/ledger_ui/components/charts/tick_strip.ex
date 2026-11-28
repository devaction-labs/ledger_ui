defmodule LedgerUI.Components.TickStrip do
  @moduledoc """
  One thin stroke per item, coloured by its status: the mini chart of a `kpi_card` that shows
  how many items are fine (`pos`), low (`warn`) or out (`neg`). Drawn on the server as one SVG that
  stretches to the width of its box (the strokes keep their 2.5px).

      <.tick_strip items={@skus} by={&(&1.status)} />

  `by` returns the tone of an item: `pos`, `warn`, `neg`, `info`, `neutral` or a series colour `c1`..`c5`
  (`success`, `warning` and `error` are read as `pos`, `warn` and `neg`). Without `by` an item is
  its own tone (`["pos", "pos", "neg"]`) or a map with a `:tone` or `:status` key. `item_title`
  returns the hover text of a stroke (a native tooltip; default: the `:label` or `:name` of a map).

  The SVG is `role="img"` with an `aria-label` that sums it up (`29 items: 15 good, 8 warning, 6
  critical`, translated); `label` replaces it.
  """
  use LedgerUI.Component

  alias LedgerUI.Components.OpsFormat, as: F

  @w 300
  @pad 1.5
  @svg "block h-4 w-full overflow-visible"

  attr :id, :string, default: nil
  attr :items, :list, required: true, doc: "One stroke per item."

  attr :by, :any,
    default: nil,
    doc:
      "`fn item -> tone`: `pos`, `warn`, `neg`, `info`, `neutral`, `c1`..`c5`. Default: the item itself, or its `:tone`/`:status`."

  attr :item_title, :any,
    default: nil,
    doc: "`fn item -> text`: the native tooltip of a stroke. Default: `:label`/`:name` of a map."

  attr :label, :string,
    default: nil,
    doc: "The `aria-label`; default: the count per tone, translated."

  attr :class, :any, default: nil

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  attr :rest, :global

  def tick_strip(assigns) do
    changed0 = assigns.__changed__
    marks = marks(assigns.items, assigns.by, assigns.item_title)

    assigns =
      assigns
      |> assign(:svg_class, cx([@svg, assigns.class]))
      |> assign(:viewbox, "0 0 #{@w} 16")
      |> assign(:marks, marks)
      |> assign(:aria, assigns.label || summary(marks, assigns.locale))

    assigns =
      settle(assigns, changed0,
        svg_class: [:class],
        viewbox: [],
        marks: [:items, :by, :item_title],
        aria: [:items, :by, :item_title, :label, :locale]
      )

    ~H"""
    <svg
      id={@id}
      data-part="tick-strip"
      role="img"
      aria-label={@aria}
      class={@svg_class}
      viewBox={@viewbox}
      preserveAspectRatio="none"
      {@rest}
    >
      <line
        :for={m <- @marks}
        :key={m.i}
        data-part="tick"
        data-tone={m.tone}
        class={m.class}
        x1={m.x}
        x2={m.x}
        y1="2"
        y2="14"
        stroke-width="2.5"
        stroke-linecap="round"
        vector-effect="non-scaling-stroke"
      >
        <title :if={m.title}>{m.title}</title>
      </line>
    </svg>
    """
  end

  defp marks(items, by, item_title) do
    n = length(items)

    items
    |> Enum.with_index()
    |> Enum.map(fn {item, i} ->
      tone = F.tone(tone_of(item, by))

      %{
        i: i,
        x: F.num(x(i, n)),
        tone: tone,
        class: F.stroke(tone),
        title: title_of(item, item_title)
      }
    end)
  end

  defp x(_i, 1), do: @w / 2
  defp x(i, n), do: @pad + i * (@w - 2 * @pad) / (n - 1)

  defp tone_of(item, by) when is_function(by, 1), do: by.(item)
  defp tone_of(item, _) when is_binary(item) or is_atom(item), do: item
  defp tone_of(%{} = item, _), do: Map.get(item, :tone) || Map.get(item, :status)
  defp tone_of(_, _), do: nil

  defp title_of(item, fun) when is_function(fun, 1), do: fun.(item)
  defp title_of(%{} = item, _), do: Map.get(item, :label) || Map.get(item, :name)
  defp title_of(_, _), do: nil

  defp summary(marks, locale) do
    counts = Enum.frequencies_by(marks, & &1.tone)

    parts =
      for tone <- ~w(pos warn neg info neutral c1 c2 c3 c4 c5 ink),
          n = counts[tone],
          n != nil,
          do: "#{n} #{F.tone_word(tone, locale)}"

    I18n.t("tick_strip.summary", locale, count: length(marks), parts: Enum.join(parts, ", "))
  end
end
