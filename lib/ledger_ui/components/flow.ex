defmodule LedgerUI.Components.Flow do
  @moduledoc """
  Workflow editor: steps on a dotted board joined by connections that carry the condition of each
  branch, a toolbar at the bottom and the configuration panel of a step on the right.

      <.flow id="triage" edges={@edges} on_add="add_node" on_move="move_node" aria-label="Triage" class="h-[640px]">
        <:node id="in" kind="Trigger" kind_icon="mail" icon="mail" title="Invoice received">
          <.flow_section label="Event">An invoice arrives at the inbox.</.flow_section>
        </:node>
        <:node id="gate" kind="Approval" icon="shield" title="Approval" selected />
        <:toolbar><button class="lu-b c-primary v-solid s-md">Add node</button></:toolbar>
        <:panel label="Approval">
          <.flow_panel_head icon="shield" title="Approval" on_close="close_panel" />
          <.flow_panel_body>…fields…</.flow_panel_body>
        </:panel>
      </.flow>

  ## Layout

  The server lays the steps out (no measuring): `edges` is a list of maps with `from` and `to`
  (node ids) and optionally `label` and `status` (`"done"` green, `"error"` red; an edge into the
  `selected` node takes the accent). A node's row is its depth along the edges, a parent is centred
  over its children, and every connection is an SVG path drawn in the gap above its target with the
  `label` on it. Without `edges` the nodes are a free grid, four to a row. Rows are
  #{200}px tall plus a gap, so keep a step's card about that size; the `LedgerUI.Flow` hook redraws
  the connections from the real node boxes.

  ## Dragging

  With `on_move` the nodes can be dragged on the board (pointer events); a drop pushes
  `%{"id" => id, "x" => x, "y" => y}` (to `target` when given). Keep the positions on the server
  and pass them back as the `x`/`y` of the `:node`; the connections follow while dragging.

  Events: `on_add` (the + button under nodes with no outgoing edge, `phx-value-id` of the node),
  `on_move` (a node was dragged).
  """
  use LedgerUI.Component

  @pad 40
  @gap_x 48
  @node_h 200
  @gap_y 72
  @gap_y_branch 104
  @radius 16

  # ---------------------------------------------------------------------------
  # Layout (pure)
  # ---------------------------------------------------------------------------

  @doc """
  Lays `node_ids` out along `edges`.

  Returns `%{positions: %{id => {x, y}}, width: w, height: h, edges: [...]}` where every edge has
  its SVG path `d`, the `label` position `{lx, ly}`, `status`, `from` and `to`.
  """
  @spec layout([String.t()], [map()], keyword()) :: map()
  def layout(node_ids, edges, opts \\ []) do
    width = Keyword.get(opts, :node_width, 300)
    overrides = Keyword.get(opts, :positions, %{})
    selected = Keyword.get(opts, :selected)

    edges =
      edges |> Enum.map(&norm_edge/1) |> Enum.filter(&(&1.from in node_ids and &1.to in node_ids))

    base =
      if edges == [],
        do: grid(node_ids, width),
        else: tree(node_ids, edges, width)

    positions = Map.merge(base.positions, overrides)

    {w, h} =
      positions
      |> Map.values()
      |> Enum.reduce({0, 0}, fn {x, y}, {mw, mh} -> {max(mw, x + width), max(mh, y + @node_h)} end)

    %{
      positions: positions,
      width: w + @pad,
      height: h + @pad + 24,
      edges: Enum.map(edges, &edge_path(&1, positions, width, selected))
    }
  end

  defp norm_edge(e) do
    %{
      from: to_string(e[:from] || e["from"]),
      to: to_string(e[:to] || e["to"]),
      label: e[:label] || e["label"],
      status: e[:status] || e["status"]
    }
  end

  defp grid(ids, width) do
    positions =
      ids
      |> Enum.with_index()
      |> Map.new(fn {id, i} ->
        {id, {@pad + rem(i, 4) * (width + @gap_x), @pad + div(i, 4) * (@node_h + @gap_y)}}
      end)

    %{positions: positions}
  end

  defp tree(ids, edges, width) do
    depth = depths(ids, edges)
    parents = Enum.group_by(edges, & &1.to, & &1.from)
    # A node hangs under its first parent that sits one row above.
    primary =
      Map.new(ids, fn id ->
        parent = Enum.find(Map.get(parents, id, []), &(depth[&1] == depth[id] - 1))
        {id, parent}
      end)

    children =
      Enum.group_by(Enum.filter(ids, &primary[&1]), &primary[&1])

    roots = Enum.filter(ids, &(primary[&1] == nil))

    {units, _next} =
      Enum.reduce(roots, {%{}, 0}, fn root, {acc, next} -> place(root, children, acc, next) end)

    gaps = row_gaps(edges, depth)
    rows = depth |> Map.values() |> Enum.max(fn -> 0 end)

    ys =
      Enum.reduce(0..rows, %{}, fn r, acc ->
        y = if r == 0, do: @pad, else: acc[r - 1] + @node_h + Map.get(gaps, r, @gap_y)
        Map.put(acc, r, y)
      end)

    positions =
      Map.new(ids, fn id ->
        {id, {round(@pad + units[id] * (width + @gap_x)), ys[depth[id]]}}
      end)

    %{positions: positions}
  end

  # Longest path from a root; the relaxation is bounded so a cycle cannot loop forever.
  defp depths(ids, edges) do
    start = Map.new(ids, &{&1, 0})

    Enum.reduce_while(1..max(length(ids), 1), start, fn _, acc ->
      next =
        Enum.reduce(edges, acc, fn %{from: f, to: t}, m ->
          if m[t] < m[f] + 1 and m[f] + 1 < length(ids), do: Map.put(m, t, m[f] + 1), else: m
        end)

      if next == acc, do: {:halt, acc}, else: {:cont, next}
    end)
  end

  defp place(id, children, acc, next) do
    case Map.get(children, id, []) do
      [] ->
        {Map.put(acc, id, next), next + 1}

      kids ->
        {acc, next} =
          Enum.reduce(kids, {acc, next}, fn k, {a, n} -> place(k, children, a, n) end)

        mid = (acc[List.first(kids)] + acc[List.last(kids)]) / 2
        {Map.put(acc, id, mid), next}
    end
  end

  # A gap with a branch or a label is taller than a plain one.
  defp row_gaps(edges, depth) do
    branches =
      edges
      |> Enum.group_by(& &1.from)
      |> Enum.filter(fn {_, es} -> length(es) > 1 end)
      |> Map.new()

    edges
    |> Enum.filter(fn e -> e.label || Map.has_key?(branches, e.from) end)
    |> Map.new(fn e -> {depth[e.to], @gap_y_branch} end)
  end

  defp edge_path(e, positions, width, selected) do
    {fx, fy} = positions[e.from]
    {tx, ty} = positions[e.to]
    sx = fx + div(width, 2)
    ex = tx + div(width, 2)
    sy = fy + @node_h
    gap = if e.label, do: @gap_y_branch, else: @gap_y
    # An edge that skips rows is drawn in the gap above its target.
    sy = if ty - sy > gap + 8, do: ty - gap, else: sy
    mid = sy + div(max(ty - sy, 2), 2)

    %{
      from: e.from,
      to: e.to,
      d: path(sx, sy, ex, ty, mid),
      label: e.label,
      lx: div(sx + ex, 2),
      ly: mid,
      status: status(e, selected)
    }
  end

  defp status(%{status: s}, _) when s in ["done", "error", :done, :error], do: to_string(s)
  defp status(%{to: id}, id), do: "selected"
  defp status(_, _), do: nil

  @doc false
  def path(sx, sy, ex, ey, mid) do
    dx = ex - sx

    if dx == 0 do
      "M#{sx} #{sy} V#{ey}"
    else
      r = Enum.min([@radius, div(abs(dx), 2), max(mid - sy, 0), max(ey - mid, 0)])
      dir = if dx > 0, do: 1, else: -1

      "M#{sx} #{sy} V#{mid - r} Q#{sx} #{mid} #{sx + dir * r} #{mid} H#{ex - dir * r} " <>
        "Q#{ex} #{mid} #{ex} #{mid + r} V#{ey}"
    end
  end

  @stroke %{
    "done" => "var(--pos)",
    "error" => "var(--neg)",
    "selected" => "var(--teal-500)",
    nil => "var(--line-strong)"
  }

  @status_dot %{
    "running" => "var(--info)",
    "done" => "var(--pos)",
    "waiting" => "var(--warn)",
    "error" => "var(--neg)",
    "skipped" => "var(--muted)"
  }

  # ---------------------------------------------------------------------------
  # flow
  # ---------------------------------------------------------------------------

  attr :id, :string, required: true
  attr :edges, :list, default: []
  attr :on_add, :any, default: nil

  attr :on_move, :string,
    default: nil,
    doc: "Event pushed when a node is dragged (`id`, `x`, `y`)."

  attr :target, :any, default: nil, doc: "`phx-target` of `on_move`."
  attr :add_label, :string, default: "Add step after"
  attr :node_width, :integer, default: 300
  attr :class, :any, default: nil
  attr :rest, :global

  slot :actions, doc: "Buttons beside the selected node; the node id is the slot argument."

  slot :hint do
    attr :title, :string
    attr :left, :integer
    attr :top, :integer
    attr :width, :integer
    attr :class, :string
  end

  slot :node, required: true do
    attr :id, :string
    attr :title, :string
    attr :icon, :string
    attr :kind, :string
    attr :kind_icon, :string
    attr :status, :string
    attr :selected, :boolean
    attr :class, :string
    attr :metrics, :list
    attr :x, :integer
    attr :y, :integer
  end

  slot :panel do
    attr :label, :string
  end

  slot :toolbar

  def flow(assigns) do
    ids = Enum.map(assigns.node, &to_string(&1.id))

    selected =
      Enum.find_value(assigns.node, fn n -> if n[:selected], do: to_string(n.id) end)

    overrides =
      for n <- assigns.node, is_integer(n[:x]) and is_integer(n[:y]), into: %{} do
        {to_string(n.id), {n.x, n.y}}
      end

    lay =
      layout(ids, assigns.edges,
        node_width: assigns.node_width,
        positions: overrides,
        selected: selected
      )

    sources = MapSet.new(lay.edges, & &1.from)

    items =
      Enum.map(assigns.node, fn n ->
        id = to_string(n.id)
        {x, y} = lay.positions[id]
        %{slot: n, id: id, x: x, y: y, leaf?: not MapSet.member?(sources, id)}
      end)

    assigns =
      assigns
      |> assign(:classes, cx(["lu-flow", assigns.class]))
      |> assign(:lay, lay)
      |> assign(:sp_css, "##{assigns.id} .sp{flex:1}")
      |> assign(:items, items)
      |> assign(:stroke, @stroke)
      |> assign(:dots, @status_dot)
      |> assign(:node_h, @node_h)
      |> assign(:movable?, assigns.on_move != nil)
      |> assign(:attrs, flow_attrs(assigns))

    ~H"""
    <div
      id={@id}
      data-part="flow"
      class={@classes}
      phx-hook="LedgerUI.Flow"
      style="display:flex;min-height:420px;border-radius:16px;border:1px solid var(--line);overflow:hidden;background:var(--bg-tray)"
      {@attrs}
    >
      <.dynamic_tag tag_name="style">{@sp_css}</.dynamic_tag>
      <div style="position:relative;flex:1;min-width:0">
        <div
          data-flow-scroll
          style="position:absolute;inset:0;overflow:auto;background-image:radial-gradient(var(--line-strong) 1px,transparent 1px);background-size:18px 18px"
        >
          <div
            data-flow-stage
            style={"position:relative;width:#{@lay.width}px;height:#{@lay.height}px;min-width:100%;min-height:100%"}
          >
            <svg
              aria-hidden="true"
              style="position:absolute;inset:0;width:100%;height:100%;overflow:visible;pointer-events:none"
            >
              <path
                :for={e <- @lay.edges}
                data-edge
                data-from={e.from}
                data-to={e.to}
                d={e.d}
                fill="none"
                stroke={@stroke[e.status]}
                stroke-width="1.5"
              />
            </svg>
            <span
              :for={e <- @lay.edges}
              :if={e.label}
              data-edge-label
              data-from={e.from}
              data-to={e.to}
              class="lu-badge"
              style={"position:absolute;left:#{e.lx}px;top:#{e.ly}px;transform:translate(-50%,-50%)"}
            >
              {e.label}
            </span>
            <div
              :for={h <- @hint}
              class={h[:class]}
              style={"position:absolute;left:#{h[:left] || 372}px;top:#{h[:top] || 92}px;width:#{h[:width] || 240}px;padding:12px 14px;border-radius:12px;background:var(--bg-panel);border:1px dashed var(--line-strong);font-size:13px"}
            >
              <b :if={h[:title]} style="display:block;margin-bottom:2px">{h[:title]}</b>
              {render_slot(h)}
            </div>
            <div
              :for={n <- @items}
              data-node={n.id}
              data-x={n.x}
              data-y={n.y}
              class={cx(["lu-flow-node", n.slot[:selected] && "on", n.slot[:class]])}
              style={node_style(n, @node_width, @node_h, @movable?, n.slot[:status])}
            >
              <div style="display:flex;align-items:center;gap:6px;padding:6px 12px;font-size:11px;letter-spacing:.06em;text-transform:uppercase;color:var(--muted);border-bottom:1px solid var(--line)">
                <.icon :if={n.slot[:kind_icon]} name={n.slot[:kind_icon]} size="sm" />
                <span>{n.slot[:kind]}</span>
                <span
                  :if={n.slot[:status]}
                  class="lu-dot"
                  data-status={n.slot[:status]}
                  style={"margin-left:auto;color:#{@dots[n.slot[:status]]}"}
                ></span>
              </div>
              <div style="display:flex;align-items:center;gap:10px;padding:10px 12px 0">
                <.icon :if={n.slot[:icon]} name={n.slot[:icon]} boxed />
                <b style="min-width:0">{n.slot[:title]}</b>
              </div>
              <div style="display:flex;flex-direction:column;gap:8px;padding:0 12px 12px">
                {if n.slot[:inner_block], do: render_slot(n.slot)}
              </div>
              <div
                :if={n.slot[:metrics] not in [nil, []]}
                class="lu-xs lu-muted"
                style="display:flex;gap:14px;padding:8px 12px;border-top:1px solid var(--line)"
              >
                <span :for={m <- n.slot[:metrics]}>
                  {metric_label(m)}
                  <a :if={metric(m, :href)} href={metric(m, :href)}><b>{metric(m, :value)}</b></a>
                  <b :if={!metric(m, :href)}>{metric(m, :value)}</b>
                </span>
              </div>
              <div
                :if={n.slot[:selected] && @actions != []}
                data-node-actions
                style="position:absolute;left:100%;top:0;margin-left:8px;display:flex;flex-direction:column;gap:6px"
              >
                {render_slot(@actions, n.id)}
              </div>
              <button
                :if={@on_add && n.leaf?}
                type="button"
                class="lu-btn icon sm"
                aria-label={@add_label}
                phx-click={@on_add}
                phx-value-id={n.id}
                style="position:absolute;left:50%;bottom:-16px;transform:translateX(-50%)"
              >
                <.icon name="plus" />
              </button>
            </div>
          </div>
        </div>
        <div
          :if={@toolbar != []}
          style="position:absolute;left:50%;bottom:16px;transform:translateX(-50%);display:flex;gap:8px;padding:8px;border-radius:14px;background:var(--bg-panel);border:1px solid var(--line);box-shadow:var(--shadow-md)"
        >
          {render_slot(@toolbar)}
        </div>
      </div>
      <aside
        :for={p <- @panel}
        aria-label={p[:label]}
        style="width:380px;flex:none;display:flex;flex-direction:column;background:var(--bg-panel);border-left:1px solid var(--line)"
      >
        {render_slot(p)}
      </aside>
    </div>
    """
  end

  defp flow_attrs(a) do
    rest = a.rest
    rest = if a.on_move, do: Map.put(rest, :"data-lu-move-event", a.on_move), else: rest
    rest = if a.target, do: Map.put(rest, :"phx-target", a.target), else: rest

    rest =
      if a.node_width != 300, do: Map.put(rest, :"data-lu-node-width", a.node_width), else: rest

    if rest[:"aria-label"], do: Map.put_new(rest, :role, "group"), else: rest
  end

  defp node_style(n, width, node_h, movable?, status) do
    [
      "position:absolute;left:#{n.x}px;top:#{n.y}px;width:#{width}px;min-height:#{node_h - 80}px",
      "flex-direction:column;align-items:stretch;gap:0;padding:0",
      movable? && "cursor:grab;touch-action:none",
      status == "skipped" && "opacity:.55"
    ]
    |> Enum.filter(& &1)
    |> Enum.join(";")
  end

  defp metric(m, key), do: m[key] || m[to_string(key)]
  defp metric_label(m), do: metric(m, :label)

  # ---------------------------------------------------------------------------
  # Parts
  # ---------------------------------------------------------------------------

  attr :label, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def flow_section(assigns) do
    ~H"""
    <div
      data-part="flow-section"
      class={@class}
      style="background:var(--bg-sunken);border-radius:8px;padding:8px 10px;font-size:13px"
      {@rest}
    >
      <div
        class="mono"
        style="font-size:10.5px;letter-spacing:.08em;text-transform:uppercase;color:var(--muted);margin-bottom:4px"
      >
        {@label}
      </div>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def flow_chips(assigns) do
    ~H"""
    <div data-part="flow-chips" class={cx(["lu-row", @class])} style="gap:6px;flex-wrap:wrap" {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def flow_chip(assigns) do
    ~H"""
    <span data-part="flow-chip" class={cx(["lu-badge mono", @class])} {@rest}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  attr :title, :string, required: true
  attr :icon, :string, default: nil
  attr :on_close, :any, default: nil
  attr :close_label, :string, default: "Close"
  attr :class, :any, default: nil
  attr :rest, :global

  def flow_panel_head(assigns) do
    ~H"""
    <div
      data-part="flow-panel-head"
      class={@class}
      style="display:flex;align-items:center;gap:10px;padding:14px 16px;border-bottom:1px solid var(--line)"
      {@rest}
    >
      <.icon :if={@icon} name={@icon} boxed />
      <b style="flex:1;min-width:0">{@title}</b>
      <button
        :if={@on_close}
        type="button"
        class="lu-btn icon ghost sm"
        aria-label={@close_label}
        phx-click={@on_close}
      >
        <.icon name="x" />
      </button>
    </div>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def flow_panel_tabs(assigns) do
    ~H"""
    <div
      data-part="flow-panel-tabs"
      class={@class}
      style="padding:0 16px;border-bottom:1px solid var(--line)"
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def flow_panel_body(assigns) do
    ~H"""
    <div
      data-part="flow-panel-body"
      class={@class}
      style="flex:1;min-height:0;overflow:auto;padding:16px;display:flex;flex-direction:column;gap:14px"
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def flow_panel_foot(assigns) do
    ~H"""
    <div
      data-part="flow-panel-foot"
      class={@class}
      style="display:flex;align-items:center;gap:8px;padding:12px 16px;border-top:1px solid var(--line);font-size:12px;color:var(--muted)"
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
