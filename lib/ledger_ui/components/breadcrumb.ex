defmodule LedgerUI.Components.Breadcrumb do
  @moduledoc """
  The trail of pages above the current one; the last `:item` is the current page.

      <.breadcrumb>
        <:item navigate={~p"/customers"}>Customers</:item>
        <:item>Casa das Tintas</:item>
      </.breadcrumb>

  An item with `href`, `navigate` or `patch` is a link; one with `phx-click` is a link-looking
  button; the others are plain text. `nil`/`false` destinations count as absent. Any other attr
  of the item (`phx-target`, `phx-value-*`, `id`, `data-*`, `aria-*`) goes to the link.

  `max_items` collapses a long trail: it keeps the first step and the last `max_items - 2`, and
  the ones in between become a "…" button opening a `dropdown/1` (id `"\#{id}-more"`).

  `variant` is `canvas`, `plain` or `bordered`. The default is `nil`: the base `lu-crumb` look,
  which is the canvas one without the extra pill classes. The `:separator` slot replaces the
  default `/`.

  Additions to the README: the item attr `icon` (an icon drawn before the step, outside the
  link) and `style` (on the current step, or on a span wrapping a link and its separator, for
  staggered animations).
  """
  use LedgerUI.Component
  import LedgerUI.Components.Dropdown, only: [dropdown: 1, dropdown_item: 1]

  attr :variant, :string, default: nil, values: [nil, "canvas", "plain", "bordered"]
  attr :label, :string, default: "Breadcrumb"
  attr :max_items, :integer, default: nil
  attr :more_label, :string, default: "Show hidden steps"
  attr :id, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :item, required: true do
    attr :href, :string
    attr :navigate, :string
    attr :patch, :string
    attr :class, :any
    attr :icon, :string
    attr :style, :string
    attr :title, :string
    attr :id, :string
    attr :"phx-click", :any
    attr :"phx-target", :any
    attr :"phx-value-id", :any
  end

  slot :separator

  def breadcrumb(assigns) do
    entries = entries(assigns.item, assigns.max_items)

    assigns =
      assigns
      |> assign(:classes, cx(["lu-crumb", assigns.variant, assigns.class]))
      |> assign(:entries, entries)
      |> assign(:more_id, (assigns.id || "breadcrumb") <> "-more")

    ~H"""
    <nav id={@id} aria-label={@label} class={@classes} {@rest}>
      <%= for e <- @entries do %>
        <%= case e do %>
          <% {:more, hidden} -> %>
            <.dropdown id={@more_id} placement="bottom-start">
              <:toggle>
                <a role="button" tabindex="0" style="cursor:pointer" aria-label={@more_label}>…</a>
              </:toggle>
              <.dropdown_item :for={h <- hidden} {h.attrs}>{render_slot(h.item)}</.dropdown_item>
            </.dropdown>
            {separator(assigns)}
          <% {:item, step} -> %>
            <.step step={step} separator={@separator} />
        <% end %>
      <% end %>
    </nav>
    """
  end

  defp separator(assigns) do
    ~H"""
    <%= if @separator == [] do %>
      <span class="s">/</span>
    <% else %>
      {render_slot(@separator)}
    <% end %>
    """
  end

  attr :step, :map, required: true
  attr :separator, :list, required: true

  defp step(%{step: %{last?: true}} = assigns) do
    ~H"""
    <.icon :if={@step.icon} name={@step.icon} size="md" /><span
      class={cx(["cur", @step.class])}
      {@step.cur_attrs}
    >{render_slot(@step.item)}</span>
    """
  end

  defp step(%{step: %{style: style}} = assigns) when is_binary(style) do
    ~H"""
    <span style={@step.style <> ";display:inline-flex;gap:4px;align-items:center"}>
      <.link_part step={@step} />{separator(assigns)}
    </span>
    """
  end

  defp step(assigns) do
    ~H"""
    <.icon :if={@step.icon} name={@step.icon} size="md" /><.link_part step={@step} />{separator(
      assigns
    )}
    """
  end

  attr :step, :map, required: true

  defp link_part(assigns) do
    ~H"""
    <.link :if={@step.link?} class={@step.class} {@step.attrs} {@step.link} {@step.rest}>{render_slot(
      @step.item
    )}</.link>
    <a
      :if={!@step.link? and @step.click?}
      href="#"
      role="button"
      class={@step.class}
      {@step.attrs}
      {@step.rest}
    >{render_slot(@step.item)}</a>
    <span :if={!@step.link? and !@step.click?} class={@step.class} title={@step.title}>{render_slot(
      @step.item
    )}</span>
    """
  end

  # Builds the steps; with `max_items` the middle ones collapse into `{:more, hidden}`.
  defp entries(items, max) do
    count = length(items)

    steps =
      items |> Enum.with_index(1) |> Enum.map(fn {item, i} -> step_data(item, i == count) end)

    max = if max, do: max(max, 3)

    if max && count > max do
      tail = max - 2
      [first | rest] = steps
      {hidden, shown} = Enum.split(rest, count - 1 - tail)

      [{:item, first}, {:more, Enum.map(hidden, &hidden_item/1)}] ++
        Enum.map(shown, &{:item, &1})
    else
      Enum.map(steps, &{:item, &1})
    end
  end

  defp step_data(item, last?) do
    link =
      item |> Map.take([:href, :navigate, :patch]) |> Enum.filter(fn {_, v} -> v end) |> Map.new()

    rest =
      Map.drop(item, [
        :__slot__,
        :inner_block,
        :href,
        :navigate,
        :patch,
        :class,
        :icon,
        :style,
        :title
      ])

    %{
      item: [item],
      last?: last?,
      link: link,
      link?: link != %{},
      click?: Map.has_key?(item, :"phx-click"),
      rest: rest,
      class: item[:class],
      icon: item[:icon],
      style: item[:style],
      title: item[:title],
      attrs: for({k, v} <- [title: item[:title]], v, into: %{}, do: {k, v}),
      cur_attrs:
        for({k, v} <- [style: item[:style], title: item[:title]], v, into: %{}, do: {k, v})
    }
  end

  defp hidden_item(step), do: %{item: step.item, attrs: Map.merge(step.link, step.rest)}
end
