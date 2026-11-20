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
  "var(--teal-400)", delay: "0.6s"}`, percentages of the total), `duration` (at the end) and
  `depth` (indent) to show spans.

  `trace_step/1` is a native `<details>`: the line is its summary and the block shows under it.
  """
  use LedgerUI.Component

  @status_icons %{"error" => "alert"}

  attr :spans, :list,
    default: [],
    doc:
      "Lines as data, before the inner block: maps with `:title` (or `:name`) and optionally `:icon`, `:description`, `:status`, `:duration`, `:depth` and the bar (`:start`, `:width`, `:color`, `:delay`, percentages of the total)."

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block

  @doc "The list of steps."
  def trace(assigns) do
    ~H"""
    <div data-part="trace" class={cx(["lu-trace", @class])} {@rest}>
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
    {style, rest} = Map.pop(assigns.rest, :style)

    assigns =
      assigns
      |> assign(:style, row_style(assigns, style))
      |> assign(:rest, rest)
      |> assign(:link?, assigns.href || assigns.navigate || assigns.patch)

    ~H"""
    <.link
      :if={@link?}
      href={@href}
      navigate={@navigate}
      patch={@patch}
      data-part="trace-line"
      class={cx(["lu-trace-i", @class])}
      {sa(@style)}
      {@rest}
    >
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
    </.link>
    <div
      :if={!@link?}
      data-part="trace-line"
      class={cx(["lu-trace-i", @class])}
      {sa(@style)}
      {@rest}
    >
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
    assigns =
      assigns
      |> assign_new(:summary, fn -> [] end)
      |> assign_new(:bar, fn -> nil end)
      |> assign_new(:end_icon, fn -> nil end)
      |> assign_new(:duration, fn -> nil end)
      |> assign_new(:description, fn -> nil end)
      |> then(&assign(&1, :lead, lead_icon(&1.status, &1.icon)))
      |> then(&assign(&1, :name_style, name_style(&1.bar)))
      |> then(&assign(&1, :bar_style, bar_style(&1.bar)))
      |> then(&assign(&1, :ms_style, &1.bar && "width:56px;text-align:right"))

    ~H"""
    <span :if={@status == "running"} class="lu-ring2" style="width:14px;height:14px;border-width:2px"></span>
    <.icon :if={@lead} name={@lead} size="sm" class={@status != "error" && "lu-muted"} />
    <span class="nm" style={@name_style}>
      {if @summary != [], do: render_slot(@summary), else: @title}{render_slot(@inner_block)}
    </span>
    <span :if={@description} class="lu-xs lu-muted">{@description}</span>
    <div
      :if={@bar}
      style="flex:1;position:relative;height:8px;background:var(--bg-sunken);border-radius:4px"
    >
      <i class={@bar[:delay] && "lu-spanbar"} style={@bar_style}></i>
    </div>
    <span :if={@duration} class="ms" {sa(@ms_style)}>{@duration}</span>
    <.icon :if={@end_icon} name={@end_icon} size="sm" class="lu-muted" />
    """
  end

  # `style={nil}` would render `style=""`: pass the attribute through a map instead.
  defp sa(style) when style in [nil, false, ""], do: %{}
  defp sa(style), do: %{style: style}

  defp lead_icon("running", _), do: nil
  defp lead_icon(status, icon), do: @status_icons[status] || icon

  defp name_style(nil),
    do: "min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap"

  defp name_style(_bar), do: "width:180px"

  defp bar_style(nil), do: nil

  defp bar_style(bar) do
    [
      "position:absolute",
      "left:#{pct(bar[:start] || 0)}",
      "width:#{pct(bar[:width] || 100)}",
      "top:0",
      "bottom:0",
      "border-radius:4px",
      "background:#{bar[:color] || "var(--teal-500)"}",
      bar[:delay] && "--dl:#{bar[:delay]}"
    ]
    |> Enum.filter(& &1)
    |> Enum.join(";")
  end

  defp pct(n), do: "#{n}%"

  defp row_style(assigns, extra) do
    [
      (assigns.depth > 0 or assigns.bar) && "padding-left:#{12 + 18 * assigns.depth}px",
      assigns.status == "error" && "color:var(--neg)",
      assigns.status == "pending" && "opacity:.55",
      (assigns.href || assigns.navigate || assigns.patch) && "text-decoration:none;color:inherit",
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
    ~H"""
    <details data-part="trace-step" class={@class} open={@open} {@rest}>
      <summary style="cursor:pointer">
        <div
          class="lu-trace-i"
          style={
            row_style(
              %{depth: 0, bar: nil, status: @status, href: nil, navigate: nil, patch: nil},
              "border-top:0"
            )
          }
        >
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
      <div style="margin:0 12px 10px 28px;padding-left:12px;border-left:1px solid var(--line)">
        {render_slot(@inner_block)}
      </div>
    </details>
    """
  end
end
