defmodule LedgerUI.Components.Pagination do
  @moduledoc """
  Pagination: the canvas pager (`lu-pg2`, `shape` `canvas`, `rounded` or `pill`) or the classic
  bar of buttons (`lu-pages`, `shape="classic"`), in three sizes.

      <.pagination page={@page} total_pages={10} patch={&"/orders?page=\#{&1}"} />
      <.pagination page={@page} total_pages={10} on_change="paginate" shape="pill" />

  Each page is a link when `patch`, `navigate` or `href` is given (a function from the page number
  to a path); otherwise a button pushing `on_change` with `%{"page" => "3"}` (to `target`). With
  neither, the pager is display-only (plain `span`s). Pages far from the current one collapse
  into `…`: `siblings` pages on each side of the current one and `boundaries` at each end.

  A list footer: `total_entries` and `page_size` add the "Showing 1–15 of 128" summary (and work
  out `total_pages`), `page_sizes` a rows-per-page select in its own `<form>` pushing
  `on_page_size` with `%{"page_size" => "30"}`. With a summary, a select or an `:aside` the root
  is a `lu-row` around the pages.

  The canvas shapes style `> span`, so interactive pages are `span`s holding the
  button or link. `summary` defaults to "Showing %{first}–%{last} of %{total}" when
  `total_entries` is given; an explicit `summary` is shown as-is without it.
  `shape="classic"` is an addition to the README.
  """
  use LedgerUI.Component

  @shapes ~w(canvas rounded pill classic)
  @sizes %{"sm" => "s-sm", "md" => nil, "lg" => "s-lg"}
  @reset "background:none;border:0;padding:0;font:inherit;color:inherit;cursor:pointer;min-width:100%;height:100%;text-decoration:none;display:grid;place-items:center"
  @default_summary "Showing %{first}–%{last} of %{total}"

  attr :page, :integer, required: true
  attr :total_pages, :integer, default: nil
  attr :total_entries, :integer, default: nil
  attr :page_size, :integer, default: nil
  attr :page_sizes, :list, default: []
  attr :on_page_size, :any, default: nil
  attr :summary, :string, default: nil
  attr :page_size_label, :string, default: "%{size} / page"
  attr :page_size_aria, :string, default: "Rows per page"
  attr :siblings, :integer, default: 1
  attr :boundaries, :integer, default: 1
  attr :patch, :any, default: nil
  attr :navigate, :any, default: nil
  attr :href, :any, default: nil
  attr :on_change, :any, default: nil
  attr :target, :any, default: nil
  attr :divided, :boolean, default: false
  attr :shape, :string, default: "canvas", values: @shapes
  attr :size, :string, default: "md", values: ~w(sm md lg)
  attr :arrows, :boolean, default: true
  attr :prev_label, :string, default: "Previous page"
  attr :next_label, :string, default: "Next page"
  attr :page_label, :string, default: "Page %{page}"

  attr :page_attrs, :any,
    default: nil,
    doc:
      "Function from a page number (or `:ellipsis`) to extra attrs (`%{style: ..., class: ...}`) of its item, e.g. for staggered animations."

  attr :class, :any, default: nil
  attr :rest, :global

  slot :aside

  def pagination(assigns) do
    total = total_pages(assigns)
    page = min(assigns.page, total)

    footer? =
      assigns.summary != nil or assigns.total_entries != nil or assigns.page_sizes != [] or
        assigns.aside != []

    assigns =
      assigns
      |> assign(:footer?, footer?)
      |> assign(:single?, total <= 1)
      |> assign(:pages, pages(page, total, assigns))
      |> assign(:nav_class, nav_class(assigns, footer?))
      |> assign(:nav_rest, if(footer?, do: %{}, else: assigns.rest))
      |> assign(:summary_text, summary_text(assigns, page))
      |> assign(:summary_role, if(assigns.total_entries, do: "status"))
      |> assign(:ellipsis_attrs, extra_attrs(assigns.page_attrs, :ellipsis)[:attrs] || %{})
      |> assign(:prev, arrow(assigns, page - 1, page > 1, assigns.prev_label, "chevron-left"))
      |> assign(
        :next,
        arrow(assigns, page + 1, page < total, assigns.next_label, "chevron-right")
      )
      |> assign(:sizes, Enum.map(assigns.page_sizes, &size_option(&1, assigns)))
      |> assign(:row_class, cx(["lu-row", assigns.class]))

    ~H"""
    <div :if={@footer?} class={@row_class} {@rest}>
      <span :if={@summary_text} class="lu-small lu-muted" role={@summary_role}>{@summary_text}</span>
      <span class="lu-grow"></span>
      {render_slot(@aside)}
      <.pager
        :if={!(@single? and @aside != [])}
        shape={@shape}
        class={@nav_class}
        rest={@nav_rest}
        pages={@pages}
        arrows={@arrows}
        prev={@prev}
        next={@next}
        on_change={@on_change}
        target={@target}
        ellipsis_attrs={@ellipsis_attrs}
      />
      <form :if={@sizes != []} phx-change={@on_page_size} phx-target={@target}>
        <select name="page_size" aria-label={@page_size_aria} class="lu-input sm">
          <option :for={s <- @sizes} value={s.value} selected={s.selected}>{s.label}</option>
        </select>
      </form>
    </div>
    <.pager
      :if={!@footer?}
      shape={@shape}
      class={@nav_class}
      rest={@nav_rest}
      pages={@pages}
      arrows={@arrows}
      prev={@prev}
      next={@next}
      on_change={@on_change}
      target={@target}
      ellipsis_attrs={@ellipsis_attrs}
    />
    """
  end

  attr :shape, :string, required: true
  attr :class, :string, required: true
  attr :rest, :any, required: true
  attr :pages, :list, required: true
  attr :arrows, :boolean, required: true
  attr :prev, :map, required: true
  attr :next, :map, required: true
  attr :on_change, :any, required: true
  attr :target, :any, required: true
  attr :ellipsis_attrs, :map, default: %{}

  defp pager(%{shape: "classic"} = assigns) do
    ~H"""
    <div class={@class} data-lu-single {@rest}>
      <.classic_arrow :if={@arrows} arrow={@prev} />
      <%= for p <- @pages do %>
        <button :if={p == :ellipsis} type="button">…</button>
        <.link :if={p != :ellipsis and p.link != %{}} class={p.on? && "on"} {p.link}>{p.page}</.link>
        <button
          :if={p != :ellipsis and p.link == %{}}
          class={p.on? && "on"}
          type="button"
          phx-click={@on_change}
          phx-value-page={p.page}
          phx-target={@target}
        >{p.page}</button>
      <% end %>
      <.classic_arrow :if={@arrows} arrow={@next} />
    </div>
    """
  end

  defp pager(assigns) do
    assigns = assign(assigns, :reset, @reset)

    ~H"""
    <div class={@class} {@rest}>
      <%= for p <- @pages do %>
        <span :if={p == :ellipsis} {@ellipsis_attrs}>…</span>
        <span :if={p != :ellipsis} class={cx([p.on? && "on", p.class])} {p.attrs}>
          <%= cond do %>
            <% !p.interactive? -> %>
              {p.page}
            <% p.link != %{} -> %>
              <.link style={@reset} aria-label={p.label} aria-current={p.on? && "page"} {p.link}>{p.page}</.link>
            <% true -> %>
              <button
                type="button"
                style={@reset}
                aria-label={p.label}
                aria-current={p.on? && "page"}
                phx-click={@on_change}
                phx-value-page={p.page}
                phx-target={@target}
              >{p.page}</button>
          <% end %>
        </span>
      <% end %>
      <span :if={@arrows} class="ar"><.arrow_body arrow={@prev} reset={@reset} /></span>
      <span :if={@arrows} class="ar"><.arrow_body arrow={@next} reset={@reset} /></span>
    </div>
    """
  end

  attr :arrow, :map, required: true
  attr :reset, :string, required: true

  defp arrow_body(%{arrow: %{enabled?: true, interactive?: true}} = assigns) do
    ~H"""
    <.link :if={@arrow.link != %{}} style={@reset} aria-label={@arrow.label} {@arrow.link}><.icon
      name={@arrow.icon}
      size="sm"
    /></.link>
    <button
      :if={@arrow.link == %{}}
      type="button"
      style={@reset}
      aria-label={@arrow.label}
      phx-click={@arrow.on_change}
      phx-value-page={@arrow.page}
      phx-target={@arrow.target}
    ><.icon name={@arrow.icon} size="sm" /></button>
    """
  end

  defp arrow_body(assigns) do
    ~H"""
    <.icon name={@arrow.icon} size="sm" />
    """
  end

  attr :arrow, :map, required: true

  defp classic_arrow(assigns) do
    ~H"""
    <.link
      :if={@arrow.link != %{} and @arrow.enabled?}
      aria-label={@arrow.label}
      class="lu-btn icon ghost sm"
      {@arrow.link}
    ><.icon name={@arrow.icon} /></.link>
    <button
      :if={@arrow.link == %{} or !@arrow.enabled?}
      aria-label={@arrow.label}
      class="lu-btn icon ghost sm"
      type="button"
      disabled={!@arrow.enabled?}
      phx-click={@arrow.enabled? && @arrow.on_change}
      phx-value-page={@arrow.page}
      phx-target={@arrow.target}
    ><.icon name={@arrow.icon} /></button>
    """
  end

  # -- data -------------------------------------------------------------------------------

  defp total_pages(%{total_pages: n}) when is_integer(n), do: max(n, 1)

  defp total_pages(%{total_entries: t, page_size: s})
       when is_integer(t) and is_integer(s) and s > 0,
       do: max(div(t + s - 1, s), 1)

  defp total_pages(_), do: 1

  defp interactive?(a), do: Enum.any?([a.patch, a.navigate, a.href, a.on_change])

  defp link_attrs(a, page) do
    cond do
      is_function(a[:patch], 1) -> %{patch: a.patch.(page)}
      is_function(a[:navigate], 1) -> %{navigate: a.navigate.(page)}
      is_function(a[:href], 1) -> %{href: a.href.(page)}
      true -> %{}
    end
  end

  # {class, other attrs} of the item from `page_attrs`.
  defp extra_attrs(nil, _), do: %{class: nil, attrs: %{}}

  defp extra_attrs(fun, p) when is_function(fun, 1) do
    extra = fun.(p) |> Map.new()
    %{class: extra[:class], attrs: Map.drop(extra, [:class])}
  end

  defp arrow(a, page, enabled?, label, icon) do
    %{
      page: page,
      enabled?: enabled?,
      interactive?: interactive?(a),
      label: label,
      icon: icon,
      link: if(enabled?, do: link_attrs(a, page), else: %{}),
      on_change: a.on_change,
      target: a.target
    }
  end

  defp nav_class(%{shape: "classic"} = a, footer?),
    do: cx(["lu-pages", !footer? && a.class])

  defp nav_class(a, footer?) do
    cx([
      "lu-pg2",
      a.shape != "canvas" && a.shape,
      @sizes[a.size],
      a.divided && "divided",
      !footer? && a.class
    ])
  end

  defp summary_text(a, page) do
    template = a.summary || if(a.total_entries, do: @default_summary)

    if template do
      size = a.page_size || 0
      total = a.total_entries || 0
      first = if total == 0, do: 0, else: (page - 1) * size + 1
      last = if size > 0, do: min(page * size, total), else: total
      shown = max(last - first + 1, 0)

      template
      |> String.replace("%{first}", fmt(first))
      |> String.replace("%{last}", fmt(last))
      |> String.replace("%{shown}", fmt(shown))
      |> String.replace("%{total}", fmt(total))
    end
  end

  defp fmt(n), do: Integer.to_string(n)

  defp size_option(size, a) do
    %{
      value: size,
      label: String.replace(a.page_size_label, "%{size}", to_string(size)),
      selected: size == a.page_size
    }
  end

  defp pages(page, total, a) do
    interactive? = interactive?(a)

    Enum.map(items(page, total, a), fn
      :ellipsis ->
        :ellipsis

      p ->
        %{
          page: p,
          on?: p == page,
          interactive?: interactive?,
          link: link_attrs(a, p),
          label: String.replace(a.page_label, "%{page}", to_string(p)),
          class: extra_attrs(a.page_attrs, p)[:class],
          attrs: extra_attrs(a.page_attrs, p)[:attrs]
        }
    end)
  end

  # The numbers (and `:ellipsis`) to show.
  @doc false
  def items(page, total, a) do
    b = a.boundaries
    s = a.siblings
    slots = 2 * b + 2 * s + 2

    cond do
      total <= slots ->
        Enum.to_list(1..total)

      page <= b + s + 2 ->
        Enum.to_list(1..(slots - b - 1)) ++ [:ellipsis] ++ Enum.to_list((total - b + 1)..total)

      page >= total - (b + s + 1) ->
        Enum.to_list(1..b) ++ [:ellipsis] ++ Enum.to_list((total - (slots - b - 1) + 1)..total)

      true ->
        Enum.to_list(1..b) ++
          [:ellipsis] ++
          Enum.to_list((page - s)..(page + s)) ++
          [:ellipsis] ++ Enum.to_list((total - b + 1)..total)
    end
  end
end
