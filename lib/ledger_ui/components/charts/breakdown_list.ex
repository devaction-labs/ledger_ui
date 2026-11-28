defmodule LedgerUI.Components.BreakdownList do
  @moduledoc """
  The breakdown of a total by origin: a list of rows, each with an icon in a soft frame of its
  series colour, the label, its share and a detail, the value and the change with an arrow, then a
  row with the total.

      <.breakdown_list
        label="Origem"
        delta_label="vs mês passado"
        format={&brl/1}
        rows={[
          %{id: "direta", icon: "home", color: "c1", label: "Venda direta", share: 45,
            detail: "R$ 3,5 mil em trânsito", value: 136_000, delta: 0.8},
          %{id: "cd", icon: "package", color: "c2", label: "Reposição do CD", share: 27,
            detail: "R$ 4,3 mil em trânsito", value: 82_600, delta: -9.9}
        ]}
        total={%{label: "Todas as origens", value: 303_600, delta: -3.4}}
      />

  A row is `%{id, icon, color, label, share, detail, value, delta}`: `color` is a series colour
  (`c1`..`c5`, or `pos`, `warn`, `neg`, `info`, `neutral`) for the frame of the icon; `share` is a
  percentage (`45` is `45%`); `detail` follows it after a `·`; `delta` is the change in percent (`0.8`,
  `-9.9`), written with its sign in the locale, green and an up arrow when positive, red and a down arrow
  when negative; `delta_tone` forces the tone (a cost that fell is `pos`), `delta_text` and `value_text`
  replace the written change and value. `format` writes the values (`fn number -> text`; default: the
  number in the locale). `total` has `label` (default: `Total`, translated), `value` and `delta`.

  ## Linked to a `ring_month`

  `ring` is the `id` of a `ring_month`; a row with `series: "<id of the series>"` then gets
  `data-lu-series`, `tabindex="0"` and a focus ring, and the root `data-lu-ring`. The hook of the ring
  does the wiring: hovering or focusing the row lights the series on the ring, and the ring puts
  `data-active` on the row (and the row takes `bg-hover`, as it does on `:hover` and `:focus-visible`).
  Without `ring` none of this is rendered. `color` of the row is the colour of the series
  (`c1`..`c5`: the chart tokens `--lu-chart-N`; the `--lu-series-N` palette will replace them in the
  maps of `LedgerUI.Components.OpsFormat`).

  The rows are an `ul` (`label` names it); the header (`label` on the left, `delta_label` on the right)
  and the `:footer` slot sit around it. Meant to live inside a card: it draws no frame.
  """
  use LedgerUI.Component

  alias LedgerUI.Components.OpsFormat, as: F

  @row "flex items-center gap-3 border-b border-line py-2.5"
  @frame "grid size-[34px] flex-none place-items-center rounded-[10px]"
  @link "-mx-2 cursor-pointer rounded-[10px] px-2 transition-colors duration-150 outline-none " <>
          "hover:bg-hover focus-visible:bg-hover focus-visible:shadow-[0_0_0_3px_var(--lu-focus)] " <>
          "data-[active]:bg-hover motion-reduce:transition-none"
  @delta "inline-flex h-[22px] items-center gap-1 rounded-[7px] px-2 text-xs font-medium whitespace-nowrap tabular-nums [&_svg]:size-3"

  attr :id, :string, default: nil

  attr :rows, :list,
    required: true,
    doc:
      "`[%{id, icon, color, label, share, detail, value, delta, delta_tone, delta_text, value_text}]`."

  attr :total, :map,
    default: nil,
    doc: "`%{label, value, delta, delta_tone, delta_text, value_text}`: the closing row."

  attr :ring, :string,
    default: nil,
    doc:
      "The `id` of the `ring_month` this list drives: rows with a `series` key light that series on hover or focus."

  attr :label, :string,
    default: nil,
    doc: "Header at the left; also the `aria-label` of the list."

  attr :delta_label, :string, default: nil, doc: "Header at the right (`vs mês passado`)."
  attr :format, :any, default: nil, doc: "`fn number -> text` for the values."
  attr :class, :any, default: nil

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  attr :rest, :global
  slot :footer, doc: "Content under the list (a note, a link)."

  def breakdown_list(assigns) do
    changed0 = assigns.__changed__

    assigns =
      assigns
      |> assign(:items, items(assigns.rows, assigns.format, assigns.locale, assigns.ring))
      |> assign(:sum, sum(assigns.total, assigns.format, assigns.locale))
      |> assign(:head?, assigns.label != nil or assigns.delta_label != nil)
      |> assign(:row_class, @row)
      |> assign(:link_class, @link)
      |> assign(:frame_class, @frame)
      |> assign(:delta_class, @delta)

    assigns =
      settle(assigns, changed0,
        items: [:rows, :format, :locale, :ring],
        sum: [:total, :format, :locale],
        head?: [:label, :delta_label],
        row_class: [],
        link_class: [],
        frame_class: [],
        delta_class: []
      )

    ~H"""
    <div id={@id} data-part="breakdown-list" data-lu-ring={@ring} class={@class} {@rest}>
      <div
        :if={@head?}
        data-part="breakdown-head"
        class="flex justify-between pt-3.5 pb-1 text-[12.5px] text-muted"
      >
        <span>{@label}</span><span>{@delta_label}</span>
      </div>
      <ul data-part="breakdown-rows" aria-label={@label} class="m-0 list-none p-0">
        <.row
          :for={r <- @items}
          :key={r.key}
          r={r}
          row_class={@row_class}
          link_class={@link_class}
          frame_class={@frame_class}
          delta_class={@delta_class}
        />
        <li :if={@sum} data-part="breakdown-total" class="flex items-center gap-3 pt-3.5 pb-1">
          <b class="text-sm font-medium">{@sum.label}</b>
          <div class="ml-auto flex items-center gap-2.5">
            <b class="text-sm font-medium tabular-nums">{@sum.value}</b>
            <.delta :if={@sum.delta} d={@sum.delta} delta_class={@delta_class} />
          </div>
        </li>
      </ul>
      <div :if={@footer != []} data-part="breakdown-footer" class="pt-2 text-xs text-muted">
        {render_slot(@footer)}
      </div>
    </div>
    """
  end

  defp row(assigns) do
    ~H"""
    <li
      data-part="breakdown-row"
      data-lu-series={@r.series}
      tabindex={@r.series && "0"}
      class={[@row_class, @r.series && @link_class]}
    >
      <span :if={@r.icon} data-part="breakdown-icon" class={[@frame_class, @r.soft]}>
        <.icon name={@r.icon} size="base" />
      </span>
      <div class="min-w-0">
        <b class="block text-sm leading-[17px] font-medium">{@r.label}</b>
        <span :if={@r.sub} data-part="breakdown-sub" class="text-[12.5px] text-muted">{@r.sub}</span>
      </div>
      <div class="ml-auto flex flex-col items-end gap-1">
        <b data-part="breakdown-value" class="text-sm leading-[17px] font-medium tabular-nums">{@r.value}</b>
        <.delta :if={@r.delta} d={@r.delta} delta_class={@delta_class} />
      </div>
    </li>
    """
  end

  defp delta(assigns) do
    ~H"""
    <span data-part="breakdown-delta" data-tone={@d.tone} class={[@delta_class, @d.tag]}>
      <.icon :if={@d.icon} name={@d.icon} size="sm" />{@d.text}
    </span>
    """
  end

  defp items(rows, format, locale, ring) do
    rows
    |> Enum.with_index()
    |> Enum.map(fn {r, i} ->
      share = r[:share] && F.percent(r.share, locale, 0)

      %{
        key: r[:id] || i,
        series: ring && r[:series],
        icon: r[:icon],
        soft: F.soft(r[:color]),
        label: r[:label],
        sub: sub([share, r[:detail]]),
        value: r[:value_text] || F.fmt(format, r[:value], locale),
        delta: delta_of(r, locale)
      }
    end)
  end

  defp sum(nil, _, _), do: nil

  defp sum(total, format, locale) do
    %{
      label: total[:label] || I18n.t("breakdown_list.total", locale),
      value: total[:value_text] || F.fmt(format, total[:value], locale),
      delta: delta_of(total, locale)
    }
  end

  defp sub(parts), do: parts |> Enum.reject(&(&1 in [nil, ""])) |> Enum.join(" · ") |> blank()
  defp blank(""), do: nil
  defp blank(s), do: s

  defp delta_of(%{delta: d} = r, locale) when is_number(d) do
    tone = (r[:delta_tone] && F.tone(r[:delta_tone])) || sign_tone(d)

    %{
      tone: tone,
      tag: F.tag(tone),
      icon: arrow(d),
      text: r[:delta_text] || F.signed_percent(d, locale, 1, pad: true)
    }
  end

  defp delta_of(_, _), do: nil

  defp sign_tone(d) when d > 0, do: "pos"
  defp sign_tone(d) when d < 0, do: "neg"
  defp sign_tone(_), do: "neutral"

  defp arrow(d) when d > 0, do: "arrow-up"
  defp arrow(d) when d < 0, do: "arrow-down"
  defp arrow(_), do: nil
end
