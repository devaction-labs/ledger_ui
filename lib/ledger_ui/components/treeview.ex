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

  The canvas look is flat rows: `div.lu-tree-i`, indented with an inline `padding-left`. Nested
  `tree_item`s are wrapped in a `div.lu-tree-kids` that indents them, so no `depth` is needed;
  rows written side by side (as the design does) take `depth`.

  ## Streams

      <.treeview id="files" rows={@streams.files}>
        <:row :let={{_dom_id, file}}>
          <.tree_item id={"file-\#{file.id}"} label={file.name} />
        </:row>
      </.treeview>
  """
  use LedgerUI.Component

  attr :id, :string, required: true
  attr :expanded, :list, default: [], doc: "Ids of the branches that are open."
  attr :on_toggle, :any, default: nil
  attr :on_select, :any, default: nil
  attr :on_check, :any, default: nil
  attr :variant, :string, default: "canvas", values: ~w(canvas lineone)
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
      |> assign(
        :classes,
        cx(["lu-tree lu-panel", assigns.variant == "lineone" && "lineone", assigns.class])
      )
      |> assign(:attrs, root_attrs(assigns))
      |> assign(:stream?, stream?)
      |> assign(:rows, rows(assigns.rows, assigns.row_id, stream?))

    ~H"""
    <div
      id={@id}
      data-part="treeview"
      class={@classes}
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
  attr :rest, :global

  slot :icon, doc: "An icon before the label."
  slot :inner_block, doc: "The children; makes the item a branch."

  def tree_item(assigns) do
    kids? = !blank_slot?(assigns.inner_block)
    branch? = kids? or assigns.branch or assigns.expanded

    assigns =
      assigns
      |> assign(:classes, cx(["lu-tree-i", assigns.selected && "on", assigns.class]))
      |> assign(:row_style, "padding-left:#{8 + 18 * assigns.depth}px")
      |> assign(:branch?, branch?)
      |> assign(:kids?, kids?)
      |> assign(:chevron_name, if(assigns.expanded, do: "chevron-down", else: "chevron-right"))
      |> assign(:chevron_attrs, chevron_attrs(assigns.chevron_class))
      |> assign(:check_attrs, check_attrs(assigns.checked))
      |> assign(:kids_style, kids_style(assigns.expanded))
      |> assign(:kids_id, assigns.id && "#{assigns.id}-kids")

    ~H"""
    <.dynamic_tag :if={@tag} tag_name={@tag} role="none">
      <.tree_row {assigns} />
    </.dynamic_tag>
    <.tree_row :if={!@tag} {assigns} />
    """
  end

  # A call with a body but only named slots still carries an empty `inner_block`.
  defp blank_slot?(slot) when slot in [nil, []], do: true
  defp blank_slot?([%{inner_block: %Phoenix.LiveView.Rendered{static: [""]}}]), do: true
  defp blank_slot?(_), do: false

  defp chevron_attrs(nil), do: %{style: "display:inline-grid"}
  defp chevron_attrs(class), do: %{class: class, style: "display:inline-grid"}

  defp check_attrs(nil), do: nil
  defp check_attrs(true), do: %{checked: true}
  defp check_attrs(false), do: %{}
  defp check_attrs("mixed"), do: %{"data-ind" => "1"}

  defp kids_style(true), do: "padding-left:18px"
  defp kids_style(_), do: "padding-left:18px;display:none"

  defp tree_row(assigns) do
    ~H"""
    <div
      id={@id}
      data-part="tree-item"
      class={@classes}
      style={@row_style}
      {@rest}
    >
      <span :if={@chevron and @branch?} {@chevron_attrs}><.icon name={@chevron_name} class="tw" /></span><span
        :if={@chevron and !@branch?}
        style="width:16px"
      ></span><label :if={@check_attrs} class="lu-check" style="margin-right:2px"><input
          type="checkbox"
          {@check_attrs}
        /></label>{render_slot(
        @icon
      )}{@label}<span class="r">{@count}</span>
    </div>
    <div :if={@kids?} id={@kids_id} class="lu-tree-kids" role="group" style={@kids_style}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
