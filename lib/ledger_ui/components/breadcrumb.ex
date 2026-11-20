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

  The last step is rendered with `aria-current="page"`; the "…" trigger is a `role="button"`
  with `aria-label`, `aria-haspopup`, `aria-expanded` and `aria-controls` (from `dropdown/1`).

  `variant` is `canvas` (compact, the current step on a sunken chip, links get a hover chip),
  `plain` or `bordered` (every step in a bordered box, no separator). The default is `nil`, the
  plain trail, which `plain` repeats. The `:separator` slot replaces the default `/`.

  Styled only with Tailwind utilities; every part carries `data-part` (`breadcrumb`,
  `breadcrumb-link`, `breadcrumb-current`, `breadcrumb-text`, `breadcrumb-separator`,
  `breadcrumb-more`).

  Additions to the README: the item attr `icon` (an icon drawn before the step, outside the
  link) and `style` (on the current step, or on a span wrapping a link and its separator, for
  staggered animations).
  """
  use LedgerUI.Component
  import LedgerUI.Components.Dropdown, only: [dropdown: 1, dropdown_item: 1]

  # root: gap and font size; links and the current step: padding, radius and border per variant
  @roots %{
    nil => "gap-2 text-[15px]",
    "plain" => "gap-2 text-[15px]",
    "canvas" => "gap-1 text-[13.5px]",
    "bordered" => "gap-1.5 text-[13.5px]"
  }

  @links %{
    nil => nil,
    "plain" => nil,
    "canvas" => "px-2 py-[3px] rounded-[7px] hover:bg-hover",
    "bordered" => "px-2.5 py-[3px] rounded-[8px] border border-line-strong"
  }

  @currents %{
    nil => nil,
    "plain" => nil,
    "canvas" => "px-2 py-[3px] rounded-[7px] bg-sunken",
    "bordered" => "px-2.5 py-[3px] rounded-[8px] border border-line-strong"
  }

  @link_base "text-muted no-underline hover:text-ink"

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
      |> assign(
        :classes,
        cx(["flex items-center", @roots[assigns.variant], "text-muted", assigns.class])
      )
      |> assign(:link_class, cx([@link_base, @links[assigns.variant]]))
      |> assign(:current_class, cx(["text-ink font-medium", @currents[assigns.variant]]))
      |> assign(:sep_class, cx(["text-line-strong", assigns.variant == "bordered" && "hidden"]))
      |> assign(:entries, entries)
      |> assign(:more_id, (assigns.id || "breadcrumb") <> "-more")

    ~H"""
    <nav id={@id} data-part="breadcrumb" aria-label={@label} class={@classes} {@rest}>
      <%= for e <- @entries do %>
        <%= case e do %>
          <% {:more, hidden} -> %>
            <.dropdown id={@more_id} placement="bottom-start">
              <:toggle :let={t}>
                <a
                  data-part="breadcrumb-more"
                  role="button"
                  tabindex="0"
                  class={[@link_class, "cursor-pointer"]}
                  aria-label={@more_label}
                  {t}
                >
                  …
                </a>
              </:toggle>
              <.dropdown_item :for={h <- hidden} {h.attrs}>{render_slot(h.item)}</.dropdown_item>
            </.dropdown>
            <.separator separator={@separator} class={@sep_class} />
          <% {:item, step} -> %>
            <.step
              step={step}
              separator={@separator}
              link_class={@link_class}
              current_class={@current_class}
              sep_class={@sep_class}
            />
        <% end %>
      <% end %>
    </nav>
    """
  end

  attr :separator, :list, required: true
  attr :class, :string, required: true

  defp separator(assigns) do
    ~H"""
    <%= if @separator == [] do %>
      <span data-part="breadcrumb-separator" class={@class}>/</span>
    <% else %>
      {render_slot(@separator)}
    <% end %>
    """
  end

  attr :step, :map, required: true
  attr :separator, :list, required: true
  attr :link_class, :string, required: true
  attr :current_class, :string, required: true
  attr :sep_class, :string, required: true

  defp step(%{step: %{last?: true}} = assigns) do
    ~H"""
    <.icon :if={@step.icon} name={@step.icon} size="md" /><span
      data-part="breadcrumb-current"
      class={cx([@current_class, @step.class])}
      aria-current="page"
      {@step.cur_attrs}
    >{render_slot(@step.item)}</span>
    """
  end

  defp step(%{step: %{style: style}} = assigns) when is_binary(style) do
    ~H"""
    <span style={@step.style <> ";display:inline-flex;gap:4px;align-items:center"}>
      <.link_part step={@step} class={@link_class} /><.separator
        separator={@separator}
        class={@sep_class}
      />
    </span>
    """
  end

  defp step(assigns) do
    ~H"""
    <.icon :if={@step.icon} name={@step.icon} size="md" /><.link_part
      step={@step}
      class={@link_class}
    /><.separator separator={@separator} class={@sep_class} />
    """
  end

  attr :step, :map, required: true
  attr :class, :string, required: true

  defp link_part(assigns) do
    ~H"""
    <.link
      :if={@step.link?}
      data-part="breadcrumb-link"
      class={cx([@class, @step.class])}
      {@step.attrs}
      {@step.link}
      {@step.rest}
    >{render_slot(@step.item)}</.link>
    <a
      :if={!@step.link? and @step.click?}
      data-part="breadcrumb-link"
      href="#"
      role="button"
      class={cx([@class, @step.class])}
      {@step.attrs}
      {@step.rest}
    >{render_slot(@step.item)}</a>
    <span
      :if={!@step.link? and !@step.click?}
      data-part="breadcrumb-text"
      class={@step.class}
      title={@step.title}
    >{render_slot(@step.item)}</span>
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
