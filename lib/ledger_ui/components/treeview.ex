defmodule LedgerUI.Components.Treeview do
  @moduledoc """
  A tree view: a hierarchical list whose branches expand and collapse.

      <.treeview id="notas" on_toggle="toggled" on_select="opened">
        <.tree_item id="2026" label="Notas 2026" expanded>
          <:icon><.icon name="folder" size="md" /></:icon>
          <.tree_item id="out" label="Outubro" branch />
          <.tree_item id="nfe" label="NF-e 48.211.xml" selected />
        </.tree_item>
      </.treeview>

  An item with children is a branch, one without is a leaf. `branch` draws a closed branch
  before its children are there (loaded when it opens). `checked` (`true`, `false` or `"mixed"`)
  puts a checkbox before the label; `chevrons={false}` leaves the chevrons out.

  Branches open and close in the browser (`LedgerUI.Treeview` hook), with no round trip; a
  branch the person toggled stays that way across patches, and the server wins when it changes
  `expanded` for it. `on_toggle` is pushed with `%{"id" => id, "expanded" => boolean}`,
  `on_select` with `%{"id" => id}` when a leaf is clicked (or gets Enter), `on_check` with
  `%{"id" => id, "checked" => boolean}`; all to `target` when given. A `%JS{}` is executed instead.

  The ARIA is rendered by the server: the root is `role="tree"`, each row a `role="treeitem"` with
  `aria-selected`, `aria-expanded` (branches), `aria-checked` (when `checked` is given), `aria-owns`
  pointing at its `role="group"` of children and a roving `tabindex` (`0` on the selected row, `-1` on
  the others; the hook makes sure one row, the first when none is selected, is in the tab order).
  The hook only updates `aria-expanded`/`aria-selected`/`tabindex` as the person interacts.

  The look is flat rows (`data-part="tree-item"`), styled only with Tailwind utilities: a selected
  row is `aria-selected="true"`. Nested `tree_item`s are wrapped in a `data-part="tree-children"`
  box that indents them (and is `hidden` while closed), so no `depth` is needed; rows written side
  by side (as the design does) take `depth`.

  ## Checkboxes

  A row with `checked` cascades in the browser: (un)checking a branch (un)checks everything under
  it, and a branch shows the dash (`indeterminate`, `aria-checked="mixed"`) while only some of its
  children are checked. `on_check` is pushed for the row that was clicked.

  ## Streams

      <.treeview id="files" rows={@streams.files}>
        <:row :let={{_dom_id, file}}>
          <.tree_item id={"file-\#{file.id}"} label={file.name} />
        </:row>
      </.treeview>
  """
  use LedgerUI.Component

  alias LedgerUI.Color
  alias LedgerUI.Components.Checkbox

  attr :id, :string, required: true
  attr :expanded, :list, default: [], doc: "Ids of the branches that are open."
  attr :on_toggle, :any, default: nil
  attr :on_select, :any, default: nil
  attr :on_check, :any, default: nil

  attr :variant, :string,
    default: "canvas",
    values: ~w(canvas lineone),
    doc: "`lineone` is reserved: the design has no style for it."

  attr :chevrons, :boolean, default: true
  attr :target, :any, default: nil
  attr :rows, :any, default: nil, doc: "A list or a stream rendered by `:row`."
  attr :row_id, :any, default: nil, doc: "A function giving each row's DOM id (lists only)."
  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block
  slot :row, doc: "Renders one row; takes `{dom_id, item}`."

  def treeview(assigns) do
    stream? = match?(%Phoenix.LiveView.LiveStream{}, assigns.rows)

    assigns =
      assigns
      |> assign(:classes, ["rounded-lg border border-line bg-panel text-[14px]", assigns.class])
      |> assign(:attrs, root_attrs(assigns))
      |> assign(:stream?, stream?)
      |> assign(:rows, rows(assigns.rows, assigns.row_id, stream?))

    ~H"""
    <div
      id={@id}
      data-part="treeview"
      class={@classes}
      role="tree"
      phx-hook="LedgerUI.Treeview"
      phx-update={@stream? && "stream"}
      {@attrs}
    >
      {render_slot(@inner_block)}
      <%= if @rows do %>
        <%= for {dom_id, row} <- @rows do %>
          <%= for slot <- @row do %>
            {render_slot(slot, {dom_id, row})}
          <% end %>
        <% end %>
      <% end %>
    </div>
    """
  end

  defp rows(nil, _fun, _stream?), do: nil
  defp rows(rows, _fun, true), do: rows
  defp rows(rows, nil, false), do: Enum.map(rows, &{nil, &1})
  defp rows(rows, fun, false), do: Enum.map(rows, &{fun.(&1), &1})

  # Only what is not the default is written.
  defp root_attrs(a) do
    %{
      "data-on-toggle" => event(a.on_toggle),
      "data-on-select" => event(a.on_select),
      "data-on-check" => event(a.on_check),
      "data-target" => a.target && target(a.target),
      "data-chevrons" => !a.chevrons && "false",
      "data-expanded" => a.expanded != [] && Phoenix.json_library().encode!(a.expanded)
    }
    |> Enum.filter(fn {_k, v} -> v end)
    |> Map.new()
    |> Map.merge(a.rest)
  end

  defp event(nil), do: nil
  defp event(%Phoenix.LiveView.JS{} = js), do: Phoenix.json_library().encode!(js.ops)
  defp event(name), do: name

  defp target(%Phoenix.LiveComponent.CID{cid: cid}), do: cid
  defp target(target), do: target

  attr :id, :string, default: nil, doc: "Names the item in events and in `expanded`."
  attr :label, :string, default: nil
  attr :expanded, :boolean, default: false
  attr :selected, :boolean, default: false
  attr :branch, :boolean, default: false, doc: "A branch even with no children yet."
  attr :checked, :any, default: nil, values: [nil, true, false, "mixed"]
  attr :tag, :string, default: nil, values: [nil, "li", "div"], doc: "Wraps the item in this tag."
  attr :count, :string, default: nil, doc: "A trailing count (the mono figure at the right)."
  attr :depth, :integer, default: 0, doc: "Indent level for rows written side by side."
  attr :chevron, :boolean, default: true, doc: "Leaves room for / draws the chevron."
  attr :chevron_class, :any, default: nil
  attr :class, :any, default: nil

  attr :rest, :global,
    include: ~w(icon),
    doc: "`icon=\"name\"` draws that icon before the label (the `:icon` slot takes any markup)."

  slot :icon, doc: "An icon before the label."
  slot :inner_block, doc: "The children; makes the item a branch."

  def tree_item(assigns) do
    {icon_rest, rest} = Map.pop(assigns.rest, :icon)
    # `icon` is a slot; the string form is left in the assigns by Phoenix
    {icon, icon_slot} =
      case assigns.icon do
        text when is_binary(text) -> {text, []}
        list when is_list(list) -> {icon_rest, list}
        _ -> {icon_rest, []}
      end

    assigns = assign(assigns, rest: rest, icon_name: icon, icon: icon_slot)
    kids? = !blank_slot?(assigns.inner_block)
    branch? = kids? or assigns.branch or assigns.expanded

    assigns =
      assigns
      |> assign(:classes, row_classes(assigns))
      |> assign(:row_style, assigns.depth > 0 && "padding-left:#{8 + 18 * assigns.depth}px")
      |> assign(:branch?, branch?)
      |> assign(:kids?, kids?)
      |> assign(:chevron_name, if(assigns.expanded, do: "chevron-down", else: "chevron-right"))
      |> assign(:check_attrs, check_attrs(assigns.checked))
      |> assign(:kids_id, assigns.id && "#{assigns.id}-kids")
      |> assign(:aria, item_aria(assigns, branch?))
      |> assign(:check_label_class, [
        "mr-0.5 inline-flex cursor-pointer items-start gap-2.5 text-[14px] text-ink",
        Color.vars("primary")
      ])
      |> assign(
        :check_input_class,
        Checkbox.input_class("checkbox", "md", "square", false, false)
      )

    ~H"""
    <.dynamic_tag :if={@tag} tag_name={@tag} role="none">
      <.tree_row {assigns} />
    </.dynamic_tag>
    <.tree_row :if={!@tag} {assigns} />
    """
  end

  defp row_classes(a) do
    [
      "flex h-8 cursor-pointer items-center gap-1.5 rounded-[8px] pr-2 text-ink-2",
      a.depth == 0 && "pl-2",
      "not-aria-selected:hover:bg-hover aria-selected:bg-selected aria-selected:font-medium aria-selected:text-ink",
      a.class
    ]
  end

  # A call with a body but only named slots still carries an empty `inner_block`.
  defp blank_slot?(slot) when slot in [nil, []], do: true
  defp blank_slot?([%{inner_block: %Phoenix.LiveView.Rendered{static: [""]}}]), do: true
  defp blank_slot?(_), do: false

  defp item_aria(a, branch?) do
    %{
      "aria-selected" => to_string(a.selected),
      "aria-expanded" => branch? && to_string(a.expanded),
      "aria-checked" => a.checked != nil && to_string(a.checked),
      "aria-owns" => a.id && !blank_slot?(a.inner_block) && "#{a.id}-kids",
      "tabindex" => if(a.selected, do: "0", else: "-1")
    }
    |> Enum.filter(fn {_k, v} -> v end)
    |> Map.new()
  end

  defp check_attrs(nil), do: nil
  defp check_attrs(true), do: %{checked: true}
  defp check_attrs(false), do: %{}
  defp check_attrs("mixed"), do: %{"data-ind" => "1"}

  defp tree_row(assigns) do
    ~H"""
    <div
      id={@id}
      data-part="tree-item"
      class={@classes}
      style={@row_style}
      role="treeitem"
      {@aria}
      {@rest}
    >
      <span
        :if={@chevron and @branch?}
        data-part="tree-chevron"
        class={["inline-grid text-subtle [&_svg]:size-4", @chevron_class]}
      ><.icon name={@chevron_name} class="tw" /></span><span
        :if={@chevron and !@branch?}
        data-part="tree-spacer"
        class="w-4"
      ></span><label :if={@check_attrs} data-part="tree-check" class={@check_label_class}><input
        data-part="tree-check-input"
        type="checkbox"
        class={@check_input_class}
        {@check_attrs}
      /></label><.icon :if={@icon_name} name={@icon_name} />{render_slot(@icon)}{@label}<span
        data-part="tree-count"
        class="ml-auto font-mono text-xs text-muted"
      >{@count}</span>
    </div>
    <div
      :if={@kids?}
      id={@kids_id}
      data-part="tree-children"
      class="pl-[18px]"
      role="group"
      hidden={!@expanded}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :id, :string, default: "tree"

  attr :items, :list,
    required: true,
    doc:
      "Maps with `:label` and optionally `:id`, `:icon`, `:count`, `:checked`, `:expanded` and `:children` (the same shape, nested)."

  attr :selected, :any,
    default: nil,
    doc: "The `id` (or the `label`, without ids) of the selected item."

  attr :expanded, :list, default: [], doc: "Ids of the branches that are open."
  attr :on_toggle, :any, default: nil
  attr :on_select, :any, default: nil
  attr :on_check, :any, default: nil
  attr :variant, :string, default: "canvas", values: ~w(canvas lineone)
  attr :chevrons, :boolean, default: true
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  @doc """
  A tree written as data: the same as `treeview/1` with one `tree_item/1` per map.

      <.tree id="folders" items={[
        %{id: "fiscal", label: "Fiscal", icon: "folder", count: 12, expanded: true,
          children: [%{id: "nfe", label: "NF-e", icon: "file"}]}
      ]} selected="nfe" />
  """
  def tree(assigns) do
    ~H"""
    <.treeview
      id={@id}
      expanded={@expanded}
      on_toggle={@on_toggle}
      on_select={@on_select}
      on_check={@on_check}
      variant={@variant}
      chevrons={@chevrons}
      target={@target}
      class={@class}
      {@rest}
    >
      <.tree_nodes items={@items} selected={@selected} expanded={@expanded} />
    </.treeview>
    """
  end

  attr :items, :list, required: true
  attr :selected, :any, default: nil
  attr :expanded, :list, default: []

  defp tree_nodes(assigns) do
    ~H"""
    <.tree_item
      :for={item <- @items}
      id={item[:id]}
      label={item[:label]}
      icon={item[:icon]}
      count={item[:count] && to_string(item[:count])}
      checked={item[:checked]}
      expanded={item[:expanded] == true or item[:id] in @expanded}
      branch={item[:children] not in [nil, []]}
      selected={@selected != nil and @selected == (item[:id] || item[:label])}
    >
      <.tree_nodes
        :if={item[:children] not in [nil, []]}
        items={item[:children]}
        selected={@selected}
        expanded={@expanded}
      />
    </.tree_item>
    """
  end
end
