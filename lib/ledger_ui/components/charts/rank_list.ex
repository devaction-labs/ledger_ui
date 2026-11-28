defmodule LedgerUI.Components.RankList do
  @moduledoc """
  A ranking of items with a thumb: name, `value · units` and the change in percent with a trend
  arrow, under a header (title, subtitle and an action such as "See all") and over a footer
  ("8 of 12 categories").

      <.rank_list
        title="Principais categorias"
        subtitle="Receita, 4 semanas até 22 nov"
        format={&brl/1}
        units_label="un"
        footer="8 de 12 categorias · R$ 1,4 mi"
        note="vs 4 semanas anteriores"
        rows={[
          %{id: "cafe", icon: "package", color: "#8a5a3c", label: "Café", value: 238_800, units: 5191, delta: 45.5},
          %{id: "audio", icon: "monitor", color: "#2f6f8f", label: "Áudio", value: 212_700, units: 1558, delta: -12.0}
        ]}
      >
        <:action><.button size="sm" variant="outline">Ver todas</.button></:action>
      </.rank_list>

  A row is `%{id, icon, color, label, value, units, detail, delta, delta_tone}`: the thumb is the `icon`
  (or the first letter of the `label`) over `color`, a CSS colour (`#8a5a3c`, `var(--lu-chart-2)`;
  default `inverse`); the second line is `value · units units_label`, or `detail` as it is; `delta` is the
  change in percent, drawn without sign beside a trend arrow (a small arrow, `\u2197` green when positive, `\u2198` red when negative), `delta_tone` forces the tone. `format` writes `value` (default:
  the number in the locale).

  It is a card (`rounded-[18px]`, `border-line`, `bg-panel`); `bare` leaves out the frame, the
  header and footer keep their padding. The rows are an `ul` named by `title`.
  """
  use LedgerUI.Component

  alias LedgerUI.Components.OpsFormat, as: F

  @card "flex min-w-0 flex-col overflow-hidden rounded-[18px] border border-line bg-panel shadow-xs"
  @row "flex items-center gap-3 border-t border-line px-[18px] py-2.5"
  @thumb "grid size-9 flex-none place-items-center rounded-[11px] [&_svg]:size-[18px]"
  @tag "ml-auto inline-flex h-[22px] items-center gap-1 rounded-[7px] px-2 text-xs font-medium whitespace-nowrap tabular-nums [&_svg]:size-3"
  @safe_color ~r/\A[#a-zA-Z0-9(),.%\s\-_\/]+\z/

  attr :id, :string, default: nil

  attr :rows, :list,
    required: true,
    doc: "`[%{id, icon, color, label, value, units, detail, delta, delta_tone}]`."

  attr :title, :string, default: nil
  attr :subtitle, :string, default: nil
  attr :format, :any, default: nil, doc: "`fn number -> text` for `value`."

  attr :units_label, :string,
    default: nil,
    doc: "Written after `units` (`un`); default: the translated `units`."

  attr :delta_decimals, :integer,
    default: 1,
    doc: "Decimal places of the change (`12,0%`)."

  attr :footer, :string,
    default: nil,
    doc: "Text at the left of the footer (`8 de 12 categorias`)."

  attr :note, :string, default: nil, doc: "Text at the right of the footer."
  attr :bare, :boolean, default: false, doc: "`true` leaves out the card frame."
  attr :class, :any, default: nil

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  attr :rest, :global
  slot :action, doc: "Beside the header's title (a `See all` button)."

  def rank_list(assigns) do
    changed0 = assigns.__changed__
    units = assigns.units_label || I18n.t("rank_list.units", assigns.locale)

    assigns =
      assigns
      |> assign(:classes, cx([!assigns.bare && @card, assigns.class]))
      |> assign(
        :items,
        items(assigns.rows, assigns.format, units, assigns.locale, assigns.delta_decimals)
      )
      |> assign(:head?, assigns.title != nil or assigns.subtitle != nil)
      |> assign(:foot?, assigns.footer != nil or assigns.note != nil)
      |> assign(:row_class, @row)
      |> assign(:thumb_class, @thumb)
      |> assign(:tag_class, @tag)

    assigns =
      settle(assigns, changed0,
        classes: [:bare, :class],
        items: [:rows, :format, :units_label, :locale, :delta_decimals],
        head?: [:title, :subtitle],
        foot?: [:footer, :note],
        row_class: [],
        thumb_class: [],
        tag_class: []
      )

    ~H"""
    <div id={@id} data-part="rank-list" class={@classes} {@rest}>
      <div
        :if={@head? or @action != []}
        data-part="rank-head"
        class="flex items-start justify-between gap-3 px-[18px] pt-4 pb-3"
      >
        <div class="min-w-0">
          <b :if={@title} class="block text-[15.5px] font-medium">{@title}</b>
          <span :if={@subtitle} class="mt-px block text-[12.5px] text-muted">{@subtitle}</span>
        </div>
        <div :if={@action != []} data-part="rank-action" class="flex-none">
          {render_slot(@action)}
        </div>
      </div>
      <ul data-part="rank-rows" aria-label={@title} class="m-0 list-none p-0">
        <.row
          :for={r <- @items}
          :key={r.key}
          r={r}
          row_class={@row_class}
          thumb_class={@thumb_class}
          tag_class={@tag_class}
        />
      </ul>
      <div
        :if={@foot?}
        data-part="rank-footer"
        class="mt-auto flex items-center justify-between gap-3 border-t border-line px-[18px] py-3 text-xs text-muted"
      >
        <span>{@footer}</span><span>{@note}</span>
      </div>
    </div>
    """
  end

  defp row(assigns) do
    ~H"""
    <li data-part="rank-row" class={@row_class}>
      <span data-part="rank-thumb" class={[@thumb_class, @r.thumb]} style={@r.style}>
        <.icon :if={@r.icon} name={@r.icon} size="base" /><span
          :if={!@r.icon}
          aria-hidden="true"
          class="text-sm font-semibold"
        >{@r.initial}</span>
      </span>
      <div class="min-w-0">
        <b class="block truncate text-sm font-medium">{@r.label}</b>
        <span data-part="rank-sub" class="text-[12.5px] text-muted">{@r.sub}</span>
      </div>
      <span
        :if={@r.delta}
        data-part="rank-delta"
        data-tone={@r.delta.tone}
        class={[@tag_class, @r.delta.tag]}
      >
        <.icon name={@r.delta.icon} size="sm" class={@r.delta.turn} />{@r.delta.text}
      </span>
    </li>
    """
  end

  defp items(rows, format, units, locale, decimals) do
    rows
    |> Enum.with_index()
    |> Enum.map(fn {r, i} ->
      color = safe_color(r[:color])

      %{
        key: r[:id] || i,
        icon: r[:icon],
        initial: r[:label] |> to_string() |> String.first() |> to_string() |> String.upcase(),
        thumb: if(color, do: "text-white", else: "bg-inverse text-on-inverse"),
        style: color && "background:" <> color,
        label: r[:label],
        sub: r[:detail] || sub(r, format, units, locale),
        delta: delta_of(r, locale, decimals)
      }
    end)
  end

  defp sub(r, format, units, locale) do
    value = r[:value] && F.fmt(format, r.value, locale)
    un = r[:units] && "#{F.value(r.units, locale)} #{units}"
    [value, un] |> Enum.reject(&is_nil/1) |> Enum.join(" · ")
  end

  defp delta_of(%{delta: d} = r, locale, decimals) when is_number(d) do
    tone = (r[:delta_tone] && F.tone(r[:delta_tone])) || sign_tone(d)

    %{
      tone: tone,
      tag: F.tag(tone),
      icon: "arrow-up-right",
      turn: if(d < 0, do: "rotate-90"),
      text: F.percent(abs(d), locale, decimals, pad: true)
    }
  end

  defp delta_of(_, _, _), do: nil

  defp sign_tone(d) when d > 0, do: "pos"
  defp sign_tone(d) when d < 0, do: "neg"
  defp sign_tone(_), do: "neutral"

  defp safe_color(c) when is_binary(c), do: if(Regex.match?(@safe_color, c), do: c)
  defp safe_color(_), do: nil
end
