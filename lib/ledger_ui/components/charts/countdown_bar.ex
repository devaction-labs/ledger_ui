defmodule LedgerUI.Components.CountdownBar do
  @moduledoc """
  A thin bar that shows how much is left of a span of time or a stock: the fraction `value` (0 to 1)
  of the track is filled, like the 70% of "next delivery in 20h".

      <.countdown_bar value={0.7} />
      <.countdown_bar value={0.2} tone="warn" />

  `tone` colours the fill: `ink` (default), `pos`, `warn`, `neg`, `info`, `neutral` or `c1`..`c5`.
  The bar is `role="img"` with an `aria-label` (`70% left`, translated; `label` replaces it). The
  fill is a width, so the bar moves smoothly when `value` changes (not with `prefers-reduced-motion`).
  """
  use LedgerUI.Component

  alias LedgerUI.Components.OpsFormat, as: F

  @track "h-[5px] w-full overflow-hidden rounded-[4px] bg-line"
  @fill "block h-[5px] rounded-[4px] transition-[width] duration-500 ease-out motion-reduce:transition-none"

  attr :id, :string, default: nil
  attr :value, :any, required: true, doc: "The fraction left: a number from 0 to 1."

  attr :tone, :string,
    default: "ink",
    values: tone_values(F.tones()),
    doc: "The fill: `ink` (default), `pos`, `warn`, `neg`, `info`, `neutral` or `c1`..`c5`."

  attr :label, :string, default: nil, doc: "The `aria-label`; default: `70% left`, translated."
  attr :class, :any, default: nil

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  attr :rest, :global

  def countdown_bar(assigns) do
    changed0 = assigns.__changed__
    pct = pct(assigns.value)

    assigns =
      assigns
      |> assign(:track_class, cx([@track, assigns.class]))
      |> assign(:fill_class, cx([@fill, F.bg(assigns.tone)]))
      |> assign(:width, "width:#{F.num(pct)}%")
      |> assign(
        :aria,
        assigns.label ||
          I18n.t("countdown_bar.summary", assigns.locale, pct: F.percent(pct, assigns.locale, 0))
      )

    assigns =
      settle(assigns, changed0,
        track_class: [:class],
        fill_class: [:tone],
        width: [:value],
        aria: [:value, :label, :locale]
      )

    ~H"""
    <div id={@id} data-part="countdown-bar" role="img" aria-label={@aria} class={@track_class} {@rest}>
      <i data-part="countdown-fill" class={@fill_class} style={@width}></i>
    </div>
    """
  end

  defp pct(v) when is_number(v), do: (min(max(v * 1.0, 0.0), 1.0) * 100) |> Float.round(1)
  defp pct(_), do: 0.0
end
