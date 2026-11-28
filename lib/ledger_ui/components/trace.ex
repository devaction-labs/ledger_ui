defmodule LedgerUI.Components.Trace do
  @moduledoc """
  What an agent did, one line per step: an icon, a title that truncates, an optional description
  (a count, a duration, a diff) and a status. A step can open to show its output, link somewhere,
  or group the steps under it.

      <.trace>
        <.trace_line icon="brain" title="Thought for 5s" />
        <.trace_line icon="terminal" description="0.4s">Ran <code>pnpm --version</code></.trace_line>
        <.trace_step icon="terminal" title="Ran node --version" open>
          <pre>v24.18.0</pre>
        </.trace_step>
        <.trace_line icon="terminal" status="error">Failed to run <code>pnpm install</code></.trace_line>
      </.trace>

  `trace_line/1` also draws a timing waterfall: pass `bar` (`%{start: 18, width: 30, color:
  "var(--lu-accent-400)", delay: "0.6s"}`, percentages of the total), `duration` (at the end) and
  `depth` (indent) to show spans.

  `trace_step/1` is a native `<details>`: the line is its summary and the block shows under it.
  """
  use LedgerUI.Component

  @status_icons %{"error" => "alert"}

  # `style={nil}` would render `style=""`: pass the attribute through a map instead.
  defp sa(style) when style in [nil, false, ""], do: %{}
  defp sa(style), do: %{style: style}

  @root "rounded-lg border border-line bg-panel text-[13.5px]"

  # one row of the trace: the border between rows is on every row but the first
  @row "flex items-center gap-2.5 px-3 py-[9px]"

  attr :spans, :list,
    default: [],
    doc:
      "Lines as data, before the inner block: maps with `:title` (or `:name`) and optionally `:icon`, `:description`, `:status`, `:duration`, `:depth` and the bar (`:start`, `:width`, `:color`, `:delay`, percentages of the total)."

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block

  @doc "The list of steps."
  def trace(assigns) do
    changed0 = assigns.__changed__
    assigns = assign(assigns, :root, @root)
    assigns = settle(assigns, changed0, root: [])

    ~H"""
    <div data-part="trace" class={[@root, @class]} {@rest}>
      <.trace_line
        :for={s <- @spans}
        icon={s[:icon]}
        title={s[:title] || s[:name]}
        description={s[:description]}
        status={s[:status]}
        duration={s[:duration]}
        depth={s[:depth] || 0}
        bar={span_bar(s)}
      />
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp span_bar(%{bar: bar}) when is_map(bar), do: bar

  defp span_bar(%{start: start, width: width} = s),
    do: %{start: start, width: width, color: s[:color], delay: s[:delay]}

  defp span_bar(_), do: nil

  attr :icon, :string, default: nil, doc: "A `huge-*` icon name."
  attr :title, :string, default: nil, doc: "The title; or pass it as the block."

  attr :description, :any,
    default: nil,
    doc: "Secondary text after the title: a count, a duration, a diff."

  attr :status, :string, default: nil, values: [nil, "", "running", "error", "pending"]
  attr :end_icon, :string, default: nil
  attr :href, :string, default: nil
  attr :navigate, :string, default: nil
  attr :patch, :string, default: nil
  attr :depth, :integer, default: 0, doc: "Indent level (18px each)."
  attr :bar, :map, default: nil, doc: "`%{start, width, color, delay}`: a span bar (percentages)."
  attr :duration, :string, default: nil, doc: "Text at the end of the row (a time)."
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(target rel download)
  slot :inner_block

  @doc "One step: icon, title, description and status; a link with `href`, `navigate` or `patch`."
  def trace_line(assigns) do
    changed0 = assigns.__changed__
    {style, rest} = Map.pop(assigns.rest, :style)
    link? = !!(assigns.href || assigns.navigate || assigns.patch)

    assigns =
      assigns
      |> assign(:style, row_style(assigns, style))
      |> assign(:rest, rest)
      |> assign(:link?, link?)
      |> assign(:row, row_class(assigns.status, link?, "border-t border-line first:border-t-0"))

    assigns =
      assign(
        assigns,
        :link_attrs,
        link? &&
          LedgerUI.LinkAttrs.resolve(
            rest
            |> Map.merge(sa(assigns.style))
            |> Map.merge(Map.take(assigns, [:href, :navigate, :patch])),
            ["data-part", "class"]
          )
      )

    assigns =
      settle(assigns, changed0,
        style: [:rest, :depth, :bar],
        rest: [:rest],
        link?: [:href, :navigate, :patch],
        link_attrs: [:style, :rest, :href, :navigate, :patch],
        row: [:status, :link?]
      )

    ~H"""
    <a :if={@link?} data-part="trace-line" class={[@row, @class]} {@link_attrs}>
      <.line_content
        icon={@icon}
        title={@title}
        description={@description}
        status={@status}
        end_icon={@end_icon}
        bar={@bar}
        duration={@duration}
        inner_block={@inner_block}
      />
    </a>
    <div :if={!@link?} data-part="trace-line" class={[@row, @class]} {sa(@style)} {@rest}>
      <.line_content
        icon={@icon}
        title={@title}
        description={@description}
        status={@status}
        end_icon={@end_icon}
        bar={@bar}
        duration={@duration}
        inner_block={@inner_block}
      />
    </div>
    """
  end

  defp line_content(assigns) do
    changed0 = assigns.__changed__

    assigns =
      assigns
      |> assign_new(:summary, fn -> [] end)
      |> assign_new(:bar, fn -> nil end)
      |> assign_new(:end_icon, fn -> nil end)
      |> assign_new(:duration, fn -> nil end)
      |> assign_new(:description, fn -> nil end)
      |> then(&assign(&1, :lead, lead_icon(&1.status, &1.icon)))
      |> then(&assign(&1, :bar_style, bar_style(&1.bar)))

    assigns =
      settle(assigns, changed0,
        summary: [],
        bar: [],
        end_icon: [],
        duration: [],
        description: [],
        lead: [:status, :icon],
        bar_style: [:bar]
      )

    ~H"""
    <span
      :if={@status == "running"}
      data-part="trace-spinner"
      class="size-3.5 flex-none animate-[lu-spin_.9s_linear_infinite] rounded-full border-2 border-accent-500 border-r-transparent"
    ></span>
    <.icon :if={@lead} name={@lead} size="sm" class={@status != "error" && "text-ink"} />
    <span
      data-part="trace-title"
      class={["font-mono text-[12.5px] text-ink", if(@bar, do: "w-[180px]", else: "min-w-0 truncate")]}
    >
      {if @summary != [], do: render_slot(@summary), else: @title}{render_slot(@inner_block)}
    </span>
    <span :if={@description} data-part="trace-description" class="text-xs leading-4 text-muted">
      {@description}
    </span>
    <div
      :if={@bar}
      data-part="trace-bar"
      class="relative h-2 flex-1 rounded-[4px] bg-sunken"
    >
      <i
        data-part="trace-bar-fill"
        class={[
          "absolute inset-y-0 rounded-[4px]",
          @bar[:delay] &&
            "origin-left animate-[mo-span_6s_cubic-bezier(.4,0,.2,1)_var(--dl)_infinite]"
        ]}
        {sa(@bar_style)}
      ></i>
    </div>
    <span
      :if={@duration}
      data-part="trace-duration"
      class={["ml-auto font-mono text-xs text-muted", @bar && "w-14 text-right"]}
    >
      {@duration}
    </span>
    <.icon :if={@end_icon} name={@end_icon} size="sm" class="text-ink" />
    """
  end

  defp lead_icon("running", _), do: nil
  defp lead_icon(status, icon), do: @status_icons[status] || icon

  defp bar_style(nil), do: nil

  defp bar_style(bar) do
    [
      "left:#{pct(bar[:start] || 0)}",
      "width:#{pct(bar[:width] || 100)}",
      "background:#{bar[:color] || "var(--lu-accent-500)"}",
      bar[:delay] && "--dl:#{bar[:delay]}"
    ]
    |> Enum.filter(& &1)
    |> Enum.join(";")
  end

  defp pct(n), do: "#{n}%"

  # the colour and the fade of the status, and the link look (a link keeps the colour of the text)
  defp row_class(status, link?, border) do
    [
      @row,
      border,
      status == "error" && "text-neg",
      status == "pending" && "opacity-55",
      link? && status != "error" && "text-inherit",
      link? && "no-underline"
    ]
  end

  defp row_style(assigns, extra) do
    [
      (assigns.depth > 0 or assigns.bar) && "padding-left:#{12 + 18 * assigns.depth}px",
      extra
    ]
    |> Enum.filter(& &1)
    |> Enum.join(";")
    |> case do
      "" -> nil
      style -> style
    end
  end

  attr :icon, :string, default: nil
  attr :title, :string, default: nil
  attr :description, :any, default: nil
  attr :status, :string, default: nil, values: [nil, "", "running", "error", "pending"]
  attr :open, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  slot :summary, doc: "The title with markup, in place of `title`."

  @doc "A step that opens: the line is the summary and the block shows under it."
  def trace_step(assigns) do
    changed0 = assigns.__changed__
    assigns = assign(assigns, :row, row_class(assigns.status, false, nil))
    assigns = settle(assigns, changed0, row: [:status])

    ~H"""
    <details data-part="trace-step" class={@class} open={@open} {@rest}>
      <summary data-part="trace-step-summary" class="cursor-pointer">
        <div data-part="trace-line" class={@row}>
          <.line_content
            icon={@icon}
            title={@title}
            description={@description}
            status={@status}
            summary={@summary}
            inner_block={[]}
          />
        </div>
      </summary>
      <div data-part="trace-step-body" class="mr-3 mb-2.5 ml-7 border-l border-line pl-3">
        {render_slot(@inner_block)}
      </div>
    </details>
    """
  end
end
