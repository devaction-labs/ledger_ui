defmodule LedgerUI.Components.Flow do
  @moduledoc """
  Workflow editor: steps on a dotted board joined by connections that carry the condition of each
  branch, a toolbar at the bottom and the configuration panel of a step on the right.

      <.flow id="triage" edges={@edges} on_add="add_node" on_move="move_node" aria-label="Triage" class="h-[640px]">
        <:node id="in" kind="Trigger" kind_icon="mail" icon="mail" title="Invoice received">
          <.flow_section label="Event">An invoice arrives at the inbox.</.flow_section>
        </:node>
        <:node id="gate" kind="Approval" icon="shield" title="Approval" selected />
        <:toolbar><.button color="primary" size="md">Add node</.button></:toolbar>
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

  ## Branching in the browser

  With `steps` (the kinds of step a person may add) every card gets a `+` at its bottom, right and
  left edges. A click opens the menu "Add step"; the chosen kind becomes a new card next to that
  edge, joined by a connection. A kind with `branches` (a condition) also opens one empty
  "Caminho ..." card per branch, each with its labelled connection; a click on an empty card opens
  the menu to fill it. Cards are dragged without a round trip, a click selects one and `Delete`
  removes it. Everything happens in the `LedgerUI.Flow` hook from `<template>`s rendered here
  (so the classes come from this module); `on_branch` is pushed with
  `%{"id" => new, "kind" => kind, "from" => id, "side" => "b" | "r" | "l"}` when set.

      <.flow id="auto" steps={[
        %{key: "acao", label: "Ação", title: "Atualizar pedido", sub: "Ação · ERP", icon: "zap", tone: "acc"},
        %{key: "cond", label: "Condição", title: "Valor acima de R$ 1.000?", sub: "Condição", icon: "filter", tone: "warn",
          branches: [%{label: "Sim", tone: "pos"}, %{label: "Não", tone: "neg"}]}
      ]}>
        <:node id="a" title="Pagamento falhou" icon="zap" />
      </.flow>
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Badge
  alias LedgerUI.Components.Button

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
    "done" => "var(--lu-pos)",
    "error" => "var(--lu-neg)",
    "selected" => "var(--lu-accent-500)",
    nil => "var(--lu-line-strong)"
  }

  @status_dot %{
    "running" => "text-info",
    "done" => "text-pos",
    "waiting" => "text-warn",
    "error" => "text-neg",
    "skipped" => "text-muted"
  }

  # ---------------------------------------------------------------------------
  # flow
  # ---------------------------------------------------------------------------

  attr :id, :string, required: true
  attr :edges, :list, default: []
  attr :on_add, :any, default: nil

  attr :steps, :list,
    default: [],
    doc:
      "Kinds of step the `+` handles add in the browser: maps with `:key`, `:label`, `:title`, `:sub`, `:icon`, `:tone` (`acc`, `pos`, `neg`, `warn`, `info`, `lime`) and optionally `:branches` (`[%{label: \"Sim\", tone: \"pos\"}]`)."

  attr :on_branch, :string,
    default: nil,
    doc: "Event pushed after a step is added in the browser (`id`, `kind`, `from`, `side`)."

  attr :menu_label, :string, default: nil
  attr :ghost_label, :string, default: nil
  attr :branch_label, :string, default: nil

  attr :on_move, :string,
    default: nil,
    doc: "Event pushed when a node is dragged (`id`, `x`, `y`)."

  attr :target, :any, default: nil, doc: "`phx-target` of `on_move`."
  attr :add_label, :string, default: nil
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

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def flow(assigns) do
    assigns =
      I18n.texts(assigns,
        menu_label: "flow.add_step",
        ghost_label: "flow.choose",
        branch_label: "flow.path",
        add_label: "flow.add_after"
      )

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
      |> assign(:lay, lay)
      |> assign(:items, items)
      |> assign(:stroke, @stroke)
      |> assign(:dots, @status_dot)
      |> assign(:node_h, @node_h)
      |> assign(:movable?, assigns.on_move != nil or assigns.steps != [])
      |> assign(:branch?, assigns.steps != [])
      |> assign(:attrs, flow_attrs(assigns))

    ~H"""
    <div
      id={@id}
      data-part="flow"
      class={[
        "flex min-h-[420px] overflow-hidden rounded-[16px] border border-line bg-tray [&_.sp]:flex-1",
        @class
      ]}
      phx-hook="LedgerUI.Flow"
      {@attrs}
    >
      <div data-part="flow-board" class="relative min-w-0 flex-1">
        <div
          data-part="flow-scroll"
          data-flow-scroll
          class="absolute inset-0 overflow-auto bg-[radial-gradient(var(--lu-line-strong)_1px,transparent_1px)] bg-[size:18px_18px]"
        >
          <div
            data-part="flow-stage"
            data-flow-stage
            class="relative min-h-full min-w-full"
            style={"width:#{@lay.width}px;height:#{@lay.height}px"}
          >
            <svg
              aria-hidden="true"
              class="pointer-events-none absolute inset-0 size-full overflow-visible"
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
            <Badge.badge
              :for={e <- @lay.edges}
              :if={e.label}
              canvas
              data-edge-label
              data-from={e.from}
              data-to={e.to}
              class="absolute -translate-x-1/2 -translate-y-1/2"
              style={"left:#{e.lx}px;top:#{e.ly}px"}
            >
              {e.label}
            </Badge.badge>
            <div
              :for={h <- @hint}
              data-part="flow-hint"
              class={[
                "absolute rounded-[12px] border border-dashed border-line-strong bg-panel px-3.5 py-3 text-[13px]",
                h[:class]
              ]}
              style={"left:#{h[:left] || 372}px;top:#{h[:top] || 92}px;width:#{h[:width] || 240}px"}
            >
              <b :if={h[:title]} data-part="flow-hint-title" class="mb-0.5 block">{h[:title]}</b>
              {render_slot(h)}
            </div>
            <div
              :for={n <- @items}
              data-node={n.id}
              data-x={n.x}
              data-y={n.y}
              data-part="flow-node"
              data-selected={n.slot[:selected] && ""}
              class={node_classes(n, @movable?, @branch?)}
              style={"left:#{n.x}px;top:#{n.y}px;width:#{@node_width}px;min-height:#{@node_h - 80}px"}
            >
              <div
                data-part="flow-node-kind"
                class="flex items-center gap-1.5 border-b border-line px-3 py-1.5 text-[11px] tracking-[.06em] text-muted uppercase"
              >
                <.icon :if={n.slot[:kind_icon]} name={n.slot[:kind_icon]} size="sm" />
                <span>{n.slot[:kind]}</span>
                <span
                  :if={n.slot[:status]}
                  data-part="flow-node-status"
                  data-status={n.slot[:status]}
                  class={[
                    "ml-auto inline-block size-[7px] flex-none rounded-full bg-current",
                    @dots[n.slot[:status]]
                  ]}
                ></span>
              </div>
              <div data-part="flow-node-head" class="flex items-center gap-2.5 px-3 pt-2.5">
                <.icon :if={n.slot[:icon]} name={n.slot[:icon]} boxed />
                <b data-part="flow-node-title" class="min-w-0">{n.slot[:title]}</b>
              </div>
              <div data-part="flow-node-body" class="flex flex-col gap-2 px-3 pb-3">
                {if n.slot[:inner_block], do: render_slot(n.slot)}
              </div>
              <div
                :if={n.slot[:metrics] not in [nil, []]}
                data-part="flow-node-metrics"
                class="flex gap-3.5 border-t border-line px-3 py-2 text-xs text-muted"
              >
                <span :for={m <- n.slot[:metrics]}>
                  {metric_label(m)}
                  <a :if={metric(m, :href)} href={metric(m, :href)}><b>{metric(m, :value)}</b></a>
                  <b :if={!metric(m, :href)}>{metric(m, :value)}</b>
                </span>
              </div>
              <div
                :if={n.slot[:selected] && @actions != []}
                data-part="flow-node-actions"
                data-node-actions
                class="absolute top-0 left-full ml-2 flex flex-col gap-1.5"
              >
                {render_slot(@actions, n.id)}
              </div>
              <.handles :if={@branch?} label={@menu_label} />
              <Button.button
                :if={@on_add && n.leaf?}
                canvas
                size="sm"
                icon
                aria-label={@add_label}
                phx-click={@on_add}
                phx-value-id={n.id}
                class="absolute bottom-[-16px] left-1/2 -translate-x-1/2"
              >
                <.icon name="plus" />
              </Button.button>
            </div>
          </div>
        </div>
        <.branching
          :if={@branch?}
          steps={@steps}
          menu_label={@menu_label}
          ghost_label={@ghost_label}
          branch_label={@branch_label}
        />
        <div
          :if={@toolbar != []}
          data-part="flow-toolbar"
          class="absolute bottom-4 left-1/2 flex -translate-x-1/2 gap-2 rounded-lg border border-line bg-panel p-2 shadow-md"
        >
          {render_slot(@toolbar)}
        </div>
      </div>
      <aside
        :for={p <- @panel}
        data-part="flow-panel"
        aria-label={p[:label]}
        class="flex w-[380px] flex-none flex-col border-l border-line bg-panel"
      >
        {render_slot(p)}
      </aside>
    </div>
    """
  end

  # A selected step takes the accent border and the focus ring; a skipped one fades.
  defp node_classes(n, movable?, branch?) do
    [
      "absolute flex flex-col items-stretch rounded-lg border border-line-strong bg-panel p-0 shadow-xs",
      "data-[selected]:border-accent-500 data-[selected]:shadow-[0_0_0_3px_var(--lu-focus)]",
      branch? && "group/node",
      movable? && "cursor-grab touch-none",
      n.slot[:status] == "skipped" && "opacity-55",
      n.slot[:class]
    ]
  end

  defp flow_attrs(a) do
    rest = a.rest

    rest =
      if a.steps != [],
        do:
          rest |> Map.put(:"data-branch", "") |> Map.put(:"data-lu-branch-label", a.branch_label),
        else: rest

    rest = if a.on_branch, do: Map.put(rest, :"data-lu-branch-event", a.on_branch), else: rest
    rest = if a.on_move, do: Map.put(rest, :"data-lu-move-event", a.on_move), else: rest
    rest = if a.target, do: Map.put(rest, :"phx-target", a.target), else: rest

    rest =
      if a.node_width != 300, do: Map.put(rest, :"data-lu-node-width", a.node_width), else: rest

    if rest[:"aria-label"], do: Map.put_new(rest, :role, "group"), else: rest
  end

  # The three `+` of a card (bottom, right, left): they appear on hover and on the selected card.
  @handle "absolute z-[4] grid size-[22px] scale-[.7] cursor-pointer place-items-center rounded-full border border-line-strong bg-panel p-0 text-ink opacity-0 shadow-[0_2px_6px_rgba(0,0,0,.12)] transition-[opacity,scale,background] duration-150 hover:scale-[1.12] hover:border-accent-500 hover:bg-accent-500 hover:text-accent-foreground group-hover/node:scale-100 group-hover/node:opacity-100 group-data-[selected]/node:scale-100 group-data-[selected]/node:opacity-100 group-data-[ghost]/node:hidden group-data-[grab]/node:hidden"
  @sides %{
    "b" => "bottom-[-11px] left-1/2 -ml-[11px]",
    "r" => "top-1/2 right-[-11px] -mt-[11px]",
    "l" => "top-1/2 left-[-11px] -mt-[11px]"
  }
  @node_box "absolute flex w-[220px] items-center gap-2.5 rounded-lg border border-line-strong bg-panel px-3 py-2.5 shadow-xs data-[selected]:border-accent-500 data-[selected]:shadow-[0_0_0_3px_var(--lu-focus)] group/node cursor-grab touch-none data-[grab]:z-[3] data-[grab]:cursor-grabbing data-[grab]:shadow-[0_10px_30px_rgba(0,0,0,.25),0_0_0_3px_var(--lu-focus)]"

  attr :label, :string, required: true

  defp handles(assigns) do
    assigns = assign(assigns, handle: @handle, sides: @sides)

    ~H"""
    <button
      :for={{side, pos} <- @sides}
      type="button"
      data-part="flow-handle"
      data-side={side}
      aria-label={@label}
      class={[@handle, pos]}
    >
      <.icon name="plus" size="sm" />
    </button>
    """
  end

  attr :steps, :list, required: true
  attr :menu_label, :string, required: true
  attr :ghost_label, :string, required: true
  attr :branch_label, :string, required: true

  # What the hook clones to add a card, a connection label or the menu; hidden, in a <template>.
  defp branching(assigns) do
    assigns = assign(assigns, box: @node_box)

    ~H"""
    <template
      :for={t <- @steps}
      data-flow-template="node"
      data-type={t[:key]}
      data-branches={branches_json(t)}
    >
      <div data-part="flow-node" data-kind={t[:key]} class={@box}>
        <.icon name={t[:icon] || "zap"} boxed tone={t[:tone] || "neutral"} />
        <span data-part="flow-node-text" class="flex min-w-0 flex-col">
          <b data-part="flow-node-title" class="text-[13px] leading-[18px]" data-slot="title">{t[
            :title
          ] || t[:label]}</b>
          <small data-part="flow-node-sub" class="text-xs text-muted" data-slot="sub">{t[:sub]}</small>
        </span>
        <.handles label={@menu_label} />
      </div>
    </template>
    <template data-flow-template="ghost">
      <div
        data-part="flow-node"
        data-ghost
        class={[
          @box,
          "cursor-pointer border-dashed bg-transparent text-muted hover:border-accent-500 hover:text-ink"
        ]}
      >
        <.icon name="plus" boxed tone="neutral" />
        <span data-part="flow-node-text" class="flex min-w-0 flex-col">
          <b data-part="flow-node-title" class="text-[13px] leading-[18px]" data-slot="title">{@ghost_label}</b>
          <small data-part="flow-node-sub" class="text-xs text-muted" data-slot="sub"></small>
        </span>
        <.handles label={@menu_label} />
      </div>
    </template>
    <template :for={tone <- ~w(pos neg warn info acc)} data-flow-template="label" data-type={tone}>
      <span
        data-part="flow-edge-label"
        data-edge-label
        class={[
          "absolute -translate-x-1/2 -translate-y-1/2 rounded-md px-2 py-0.5 text-[11px] font-semibold",
          label_tone(tone)
        ]}
      ></span>
    </template>
    <div
      data-part="flow-menu"
      role="menu"
      aria-label={@menu_label}
      hidden
      class="fixed z-[70] w-60 rounded-lg border border-line bg-panel p-1 shadow-md"
    >
      <div
        data-part="flow-menu-label"
        class="px-2.5 pt-1.5 pb-1 text-[11px] tracking-[.06em] text-muted uppercase"
      >
        {@menu_label}
      </div>
      <button
        :for={t <- @steps}
        type="button"
        role="menuitem"
        data-part="flow-menu-item"
        data-flow-type={t[:key]}
        class="flex w-full cursor-pointer items-center gap-2 rounded-md border-0 bg-transparent px-2.5 py-2 text-left text-sm text-ink hover:bg-hover"
      >
        <.icon name={t[:icon] || "zap"} size="md" />{t[:label]}<span
          data-part="flow-menu-sub"
          class="ml-auto text-[11.5px] text-muted"
        >{t[
          :sub
        ]}</span>
      </button>
    </div>
    """
  end

  defp label_tone("pos"), do: "bg-pos-soft text-pos"
  defp label_tone("neg"), do: "bg-neg-soft text-neg"
  defp label_tone("warn"), do: "bg-warn-soft text-warn"
  defp label_tone("info"), do: "bg-info-soft text-info"
  defp label_tone(_), do: "bg-accent-soft text-accent-content"

  defp branches_json(t) do
    case t[:branches] do
      b when b in [nil, []] ->
        nil

      b ->
        Phoenix.json_library().encode!(
          Enum.map(b, &%{label: &1[:label], tone: &1[:tone] || "pos"})
        )
    end
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
      class={["rounded-[8px] bg-sunken px-2.5 py-2 text-[13px]", @class]}
      {@rest}
    >
      <div
        data-part="flow-section-label"
        class="mb-1 font-mono text-[10.5px] tracking-[.08em] text-muted uppercase"
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
    <div data-part="flow-chips" class={["flex flex-wrap items-center gap-1.5", @class]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def flow_chip(assigns) do
    ~H"""
    <Badge.badge canvas class={["font-mono", @class]} {@rest}>
      {render_slot(@inner_block)}
    </Badge.badge>
    """
  end

  attr :title, :string, required: true
  attr :icon, :string, default: nil
  attr :on_close, :any, default: nil
  attr :close_label, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def flow_panel_head(assigns) do
    assigns = I18n.texts(assigns, close_label: "common.close")

    ~H"""
    <div
      data-part="flow-panel-head"
      class={["flex items-center gap-2.5 border-b border-line px-4 py-3.5", @class]}
      {@rest}
    >
      <.icon :if={@icon} name={@icon} boxed />
      <b data-part="flow-panel-title" class="min-w-0 flex-1">{@title}</b>
      <Button.button
        :if={@on_close}
        canvas
        appearance="ghost"
        size="sm"
        icon
        aria-label={@close_label}
        phx-click={@on_close}
      >
        <.icon name="x" />
      </Button.button>
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
      class={["border-b border-line px-4", @class]}
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
      class={["flex min-h-0 flex-1 flex-col gap-3.5 overflow-auto p-4", @class]}
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
      class={["flex items-center gap-2 border-t border-line px-4 py-3 text-[12px] text-muted", @class]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
