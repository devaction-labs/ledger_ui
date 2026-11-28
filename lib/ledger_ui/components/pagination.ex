defmodule LedgerUI.Components.Pagination do
  @moduledoc """
  Pagination: the canvas pager (`shape` `canvas`, `rounded` or `pill`) or the classic bar of
  buttons (`shape="classic"`), in three sizes. Styled only with Tailwind utilities; every part
  carries `data-part` (`pagination`, `pagination-page`, `pagination-arrow`, `pagination-ellipsis`,
  `pagination-footer`, `pagination-summary`, `pagination-size`...).

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
  Accessibility, rendered server-side: the current page carries `aria-current="page"` (on the
  link/button, or on the `span` when the pager is display-only), every page and arrow has an
  `aria-label` (`page_label`, `prev_label`, `next_label`), the summary is `role="status"`.
  `shape="classic"` is an addition to the README.

  `shape="compact"` is the pager of long lists: the previous arrow, `page / total` in mono and the
  next arrow (no page numbers), e.g. `‹ 1 / 8.775 ›`. With one page both arrows are disabled
  (`aria-disabled="true"`). The current page text carries `aria-current="page"`.

  Numbers in the summary and in the compact pager use the thousands separator of the locale
  (`105.299` in `pt_BR`, `105,299` in `en`). Without `summary` the summary is the translated
  `pagination.summary` ("Mostrando 1–15 de 128" in `pt_BR`). To put text from the app in front
  (`1 selecionado ·`) write it in the `summary` template: `summary="1 selecionado · %{shown} de %{total}"`.

  `page_size_at` places the page size select: `end` (default, after the pages), `summary` (right
  after the summary) or `before` (before the pages). With an `id`, the select's form is
  `"\#{id}-size-form"` and the select `"\#{id}-page-size"`.
  """
  use LedgerUI.Component

  @shapes ~w(canvas rounded pill classic compact)

  # the button or link inside a page of the canvas pager: it fills the page
  @reset "grid h-full min-w-full cursor-pointer place-items-center border-0 bg-transparent p-0 no-underline"

  # canvas pager: a page / the current page / an arrow, per shape and size
  @pager_font %{"sm" => "text-[12px]", "md" => "text-[13px]", "lg" => "text-[14px]"}
  @page_dims %{
    "sm" => "min-w-[26px] h-[26px]",
    "md" => "min-w-8 h-8",
    "lg" => "min-w-10 h-10"
  }
  @page_off "text-ink-2"
  @page_on %{
    "canvas" => "bg-ink text-on-inverse font-semibold",
    "rounded" =>
      "bg-panel text-ink font-semibold shadow-[0_0_0_1px_var(--lu-line-strong),var(--lu-shadow-xs)]",
    "pill" => "bg-accent text-accent-foreground font-semibold"
  }
  @arrow_dims %{
    "sm" => "min-w-[26px] h-[26px]",
    "md" => "min-w-7 h-7",
    "lg" => "min-w-10 h-10"
  }

  # classic bar: the button of a page, and the ghost icon button of the arrows
  @classic_base "inline-grid h-8 min-w-8 cursor-pointer place-items-center rounded-md border-0 bg-transparent px-2 text-[13.5px] text-ink-2 tabular-nums no-underline hover:bg-hover"
  # the current page is the one with `aria-current="page"` (links and buttons)
  @classic_on "aria-[current=page]:bg-panel aria-[current=page]:font-semibold aria-[current=page]:text-ink aria-[current=page]:shadow-[0_0_0_1px_var(--lu-line-strong),var(--lu-shadow-xs)]"
  @classic_page @classic_base <> " " <> @classic_on
  # the arrows are buttons like the pages (the original `lu-btn` ghost icon ones take the bar's rules)
  @classic_arrow @classic_base <>
                   " disabled:cursor-not-allowed disabled:opacity-45 disabled:hover:bg-transparent [&_svg]:size-4"

  @size_select "h-8 min-w-0 rounded-md border border-line-strong bg-panel px-2.5 text-ink transition-[border-color,box-shadow] hover:border-[color-mix(in_oklab,var(--lu-line-strong)_60%,var(--lu-muted))] focus-within:border-accent-500 focus-visible:outline-none focus-visible:shadow-[0_0_0_3px_var(--lu-focus)]"

  attr :page, :integer, required: true
  attr :total_pages, :integer, default: nil
  attr :total_entries, :integer, default: nil
  attr :page_size, :integer, default: nil
  attr :page_sizes, :list, default: []
  attr :on_page_size, :any, default: nil
  attr :summary, :string, default: nil
  attr :page_size_label, :string, default: nil
  attr :page_size_aria, :string, default: nil
  attr :siblings, :integer, default: 1
  attr :boundaries, :integer, default: 1
  attr :patch, :any, default: nil
  attr :navigate, :any, default: nil
  attr :href, :any, default: nil
  attr :on_change, :any, default: nil
  attr :target, :any, default: nil
  attr :divided, :boolean, default: false

  attr :loop, :boolean,
    default: false,
    doc: "The animated mock: pages 1-4 take the current look in turn (give `page={0}`)."

  attr :shape, :string, default: "canvas", values: @shapes

  attr :variant, :string,
    default: nil,
    values: [nil | @shapes],
    doc: "The same as `shape`; it wins when given."

  attr :size, :string, default: "md", values: ~w(sm md lg)
  attr :arrows, :boolean, default: true

  attr :page_size_at, :string,
    default: "end",
    values: ~w(end summary before),
    doc:
      "Where the page size select goes: `end` (after the pages), `summary` (right after the summary) or `before` (before the pages)."

  attr :arrows_at, :string,
    default: "end",
    values: ~w(end sides),
    doc:
      "Where the arrows go in the canvas pager: `end` (the bundle: both after the pages) or `sides` (previous before the pages, next after them, as in the classic bar)."

  attr :prev_label, :string, default: nil
  attr :next_label, :string, default: nil
  attr :page_label, :string, default: nil

  attr :page_attrs, :any,
    default: nil,
    doc:
      "Function from a page number (or `:ellipsis`) to extra attrs (`%{style: ..., class: ...}`) of its item, e.g. for staggered animations."

  attr :class, :any, default: nil
  attr :rest, :global

  slot :aside

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def pagination(assigns) do
    changed0 = assigns.__changed__

    assigns =
      I18n.texts(assigns,
        page_size_label: "pagination.page_size",
        page_size_aria: "pagination.rows_per_page",
        prev_label: "pagination.prev_page",
        next_label: "pagination.next_page",
        page_label: "pagination.page"
      )

    assigns = assign(assigns, :shape, assigns.variant || assigns.shape)
    total = total_pages(assigns)
    page = min(assigns.page, total)

    footer? =
      assigns.summary != nil or assigns.total_entries != nil or assigns.page_sizes != [] or
        assigns.aside != []

    assigns =
      assigns
      |> assign(:footer?, footer?)
      |> assign(:single?, total <= 1)
      |> assign(:pages, if(assigns.shape == "compact", do: [], else: pages(page, total, assigns)))
      |> assign(:nav_class, nav_class(assigns, footer?))
      |> assign(:nav_rest, if(footer?, do: %{}, else: assigns.rest))
      |> assign(:summary_text, summary_text(assigns, page))
      |> assign(:current_text, current_text(assigns, page, total))
      |> assign(:form_id, assigns.rest[:id] && "#{assigns.rest[:id]}-size-form")
      |> assign(:select_id, assigns.rest[:id] && "#{assigns.rest[:id]}-page-size")
      |> assign(:summary_role, if(assigns.total_entries, do: "status"))
      |> assign(:ellipsis_attrs, extra_attrs(assigns.page_attrs, :ellipsis)[:attrs] || %{})
      |> assign(:prev, arrow(assigns, page - 1, page > 1, assigns.prev_label, "chevron-left"))
      |> assign(
        :next,
        arrow(assigns, page + 1, page < total, assigns.next_label, "chevron-right")
      )
      |> assign(:sizes, Enum.map(assigns.page_sizes, &size_option(&1, assigns)))
      |> assign(:row_class, cx(["flex flex-wrap items-center gap-2.5", assigns.class]))
      |> assign(:size_select, @size_select)

    # What reads the locale of the process (when `locale` is not given) is not listed.
    nav = [:patch, :navigate, :href, :on_change]
    count = [:total_pages, :total_entries, :page_size]

    assigns =
      settle(
        assigns,
        changed0,
        [
          shape: [:variant],
          footer?: [:summary, :total_entries, :page_sizes, :aside],
          single?: count,
          pages:
            [:shape, :page, :siblings, :boundaries, :page_label, :page_attrs, :loop, :divided] ++
              count ++ nav,
          nav_class: [:shape, :footer?, :class],
          nav_rest: [:footer?, :rest],
          form_id: [:rest],
          select_id: [:rest],
          summary_role: [:total_entries],
          ellipsis_attrs: [:page_attrs],
          prev: [:page, :prev_label, :target] ++ count ++ nav,
          next: [:page, :next_label, :target] ++ count ++ nav,
          sizes: [:page_sizes, :page_size, :page_size_label],
          row_class: [:class],
          size_select: []
        ] ++
          if(assigns.locale,
            do: [
              summary_text: [:summary, :page] ++ count ++ [:locale],
              current_text: [:shape, :page] ++ count ++ [:locale]
            ],
            else: []
          )
      )

    ~H"""
    <div :if={@footer?} data-part="pagination-footer" class={@row_class} {@rest}>
      <span
        :if={@summary_text}
        data-part="pagination-summary"
        class="text-[13px] leading-[18px] text-muted"
        role={@summary_role}
      >{@summary_text}</span>
      <.size_form
        :if={@sizes != [] and @page_size_at == "summary"}
        sizes={@sizes}
        on_page_size={@on_page_size}
        target={@target}
        aria_label={@page_size_aria}
        class={@size_select}
        form_id={@form_id}
        select_id={@select_id}
      />
      <span data-part="pagination-spacer" class="min-w-0 flex-1"></span>
      {render_slot(@aside)}
      <.size_form
        :if={@sizes != [] and @page_size_at == "before"}
        sizes={@sizes}
        on_page_size={@on_page_size}
        target={@target}
        aria_label={@page_size_aria}
        class={@size_select}
        form_id={@form_id}
        select_id={@select_id}
      />
      <.pager
        :if={!(@single? and @aside != [])}
        shape={@shape}
        size={@size}
        class={@nav_class}
        rest={@nav_rest}
        pages={@pages}
        arrows={@arrows}
        arrows_at={@arrows_at}
        prev={@prev}
        next={@next}
        on_change={@on_change}
        target={@target}
        ellipsis_attrs={@ellipsis_attrs}
        current_text={@current_text}
      />
      <.size_form
        :if={@sizes != [] and @page_size_at == "end"}
        sizes={@sizes}
        on_page_size={@on_page_size}
        target={@target}
        aria_label={@page_size_aria}
        class={@size_select}
        form_id={@form_id}
        select_id={@select_id}
      />
    </div>
    <.pager
      :if={!@footer?}
      shape={@shape}
      size={@size}
      class={@nav_class}
      rest={@nav_rest}
      pages={@pages}
      arrows={@arrows}
      arrows_at={@arrows_at}
      prev={@prev}
      next={@next}
      on_change={@on_change}
      target={@target}
      ellipsis_attrs={@ellipsis_attrs}
      current_text={@current_text}
    />
    """
  end

  attr :sizes, :list, required: true
  attr :on_page_size, :any, required: true
  attr :target, :any, required: true
  attr :aria_label, :string, required: true
  attr :class, :string, required: true
  attr :form_id, :string, default: nil
  attr :select_id, :string, default: nil

  defp size_form(assigns) do
    ~H"""
    <form id={@form_id} phx-change={@on_page_size} phx-target={@target}>
      <select
        id={@select_id}
        data-part="pagination-size"
        name="page_size"
        aria-label={@aria_label}
        class={@class}
      >
        <option :for={s <- @sizes} value={s.value} selected={s.selected}>{s.label}</option>
      </select>
    </form>
    """
  end

  attr :shape, :string, required: true
  attr :size, :string, required: true
  attr :class, :any, required: true
  attr :rest, :any, required: true
  attr :pages, :list, required: true
  attr :arrows, :boolean, required: true
  attr :arrows_at, :string, default: "end"
  attr :prev, :map, required: true
  attr :next, :map, required: true
  attr :on_change, :any, required: true
  attr :target, :any, required: true
  attr :ellipsis_attrs, :map, default: %{}
  attr :current_text, :string, default: nil

  defp pager(%{shape: "compact"} = assigns) do
    changed0 = assigns.__changed__

    assigns =
      assign(assigns,
        reset: @reset,
        arrow_class: arrow_class("rounded", assigns.size)
      )

    assigns = settle(assigns, changed0, reset: [], arrow_class: [:size])

    ~H"""
    <div data-part="pagination" class={@class} {@rest}>
      <span
        :if={@arrows}
        data-part="pagination-arrow"
        class={[@arrow_class, !@prev.enabled? && "opacity-45"]}
        aria-disabled={!@prev.enabled? && "true"}
      ><.arrow_body arrow={@prev} reset={@reset} /></span>
      <span data-part="pagination-current" class="px-1.5 text-ink" aria-current="page">{@current_text}</span>
      <span
        :if={@arrows}
        data-part="pagination-arrow"
        class={[@arrow_class, !@next.enabled? && "opacity-45"]}
        aria-disabled={!@next.enabled? && "true"}
      ><.arrow_body arrow={@next} reset={@reset} /></span>
    </div>
    """
  end

  defp pager(%{shape: "classic"} = assigns) do
    changed0 = assigns.__changed__
    assigns = assign(assigns, page: @classic_page)
    assigns = settle(assigns, changed0, page: [])

    ~H"""
    <div data-part="pagination" class={@class} data-lu-single {@rest}>
      <.classic_arrow :if={@arrows} arrow={@prev} />
      <%= for p <- @pages do %>
        <button :if={p == :ellipsis} data-part="pagination-ellipsis" type="button" class={@page}>…</button>
        <a
          :if={p != :ellipsis and p.link != %{}}
          data-part="pagination-page"
          class={@page}
          aria-label={p.label}
          aria-current={p.on? && "page"}
          {p.link}
        >{p.page}</a>
        <button
          :if={p != :ellipsis and p.link == %{}}
          data-part="pagination-page"
          class={@page}
          type="button"
          aria-label={p.label}
          aria-current={p.on? && "page"}
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
    changed0 = assigns.__changed__

    assigns =
      assign(assigns,
        reset: @reset,
        page_off: @page_off,
        page_class: page_class(assigns.shape, assigns.size),
        on_class: @page_on[assigns.shape],
        arrow_class: arrow_class(assigns.shape, assigns.size)
      )

    assigns =
      settle(assigns, changed0,
        reset: [],
        page_off: [],
        page_class: [:shape, :size],
        on_class: [:shape],
        arrow_class: [:shape, :size]
      )

    ~H"""
    <div data-part="pagination" class={@class} {@rest}>
      <span :if={@arrows and @arrows_at == "sides"} data-part="pagination-arrow" class={@arrow_class}><.arrow_body
        arrow={@prev}
        reset={@reset}
      /></span>
      <%= for p <- @pages do %>
        <span
          :if={p == :ellipsis}
          data-part="pagination-ellipsis"
          class={[@page_class, @page_off]}
          {@ellipsis_attrs}
        >…</span>
        <span
          :if={p != :ellipsis}
          data-part="pagination-page"
          class={cx([@page_class, if(p.on?, do: @on_class, else: @page_off), p.class])}
          aria-current={!p.interactive? && p.on? && "page"}
          {p.attrs}
        >
          <%= cond do %>
            <% !p.interactive? -> %>
              {p.page}
            <% p.link != %{} -> %>
              <a
                data-part="pagination-link"
                class={@reset}
                aria-label={p.label}
                aria-current={p.on? && "page"}
                {p.link}
              >{p.page}</a>
            <% true -> %>
              <button
                data-part="pagination-button"
                type="button"
                class={@reset}
                aria-label={p.label}
                aria-current={p.on? && "page"}
                phx-click={@on_change}
                phx-value-page={p.page}
                phx-target={@target}
              >{p.page}</button>
          <% end %>
        </span>
      <% end %>
      <span :if={@arrows and @arrows_at != "sides"} data-part="pagination-arrow" class={@arrow_class}><.arrow_body
        arrow={@prev}
        reset={@reset}
      /></span>
      <span :if={@arrows} data-part="pagination-arrow" class={@arrow_class}><.arrow_body
        arrow={@next}
        reset={@reset}
      /></span>
    </div>
    """
  end

  attr :arrow, :map, required: true
  attr :reset, :string, required: true

  defp arrow_body(%{arrow: %{enabled?: true, interactive?: true}} = assigns) do
    ~H"""
    <a
      :if={@arrow.link != %{}}
      data-part="pagination-link"
      class={@reset}
      aria-label={@arrow.label}
      {@arrow.link}
    ><.icon name={@arrow.icon} size="sm" /></a>
    <button
      :if={@arrow.link == %{}}
      data-part="pagination-button"
      type="button"
      class={@reset}
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
    changed0 = assigns.__changed__
    assigns = assign(assigns, :arrow_class, @classic_arrow)
    assigns = settle(assigns, changed0, arrow_class: [])

    ~H"""
    <a
      :if={@arrow.link != %{} and @arrow.enabled?}
      data-part="pagination-arrow"
      aria-label={@arrow.label}
      class={@arrow_class}
      {@arrow.link}
    ><.icon name={@arrow.icon} /></a>
    <button
      :if={@arrow.link == %{} or !@arrow.enabled?}
      data-part="pagination-arrow"
      aria-label={@arrow.label}
      class={@arrow_class}
      type="button"
      disabled={!@arrow.enabled?}
      phx-click={@arrow.enabled? && @arrow.on_change}
      phx-value-page={@arrow.page}
      phx-target={@arrow.target}
    ><.icon name={@arrow.icon} /></button>
    """
  end

  defp page_class(shape, size) do
    [
      "grid place-items-center px-1.5",
      @page_dims[size],
      @pager_font[size],
      if(shape == "pill", do: "rounded-full", else: "rounded-md")
    ]
  end

  defp arrow_class(shape, size) do
    [
      "grid place-items-center border border-line-strong px-1.5 text-ink-2",
      @arrow_dims[size],
      @pager_font[size],
      if(shape == "pill", do: "rounded-full", else: "rounded-md")
    ]
  end

  # -- data -------------------------------------------------------------------------------

  defp total_pages(%{total_pages: n}) when is_integer(n), do: max(n, 1)

  defp total_pages(%{total_entries: t, page_size: s})
       when is_integer(t) and is_integer(s) and s > 0,
       do: max(div(t + s - 1, s), 1)

  defp total_pages(_), do: 1

  defp interactive?(a), do: Enum.any?([a.patch, a.navigate, a.href, a.on_change])

  defp link_attrs(a, page) do
    # the attributes of the `<a>` that `<.link>` would render (see `LedgerUI.LinkAttrs`)
    cond do
      is_function(a[:patch], 1) -> LedgerUI.LinkAttrs.resolve(%{patch: a.patch.(page)})
      is_function(a[:navigate], 1) -> LedgerUI.LinkAttrs.resolve(%{navigate: a.navigate.(page)})
      is_function(a[:href], 1) -> LedgerUI.LinkAttrs.resolve(%{href: a.href.(page)})
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
    do: cx(["flex items-center gap-1", !footer? && a.class])

  defp nav_class(a, footer?),
    do: cx(["flex items-center gap-1 font-mono", !footer? && a.class])

  defp summary_text(a, page) do
    template = a.summary || if(a.total_entries, do: I18n.t("pagination.summary", a.locale))
    loc = I18n.locale(a.locale)

    if template do
      size = a.page_size || 0
      total = a.total_entries || 0
      first = if total == 0, do: 0, else: (page - 1) * size + 1
      last = if size > 0, do: min(page * size, total), else: total
      shown = max(last - first + 1, 0)

      template
      |> String.replace("%{first}", fmt(first, loc))
      |> String.replace("%{last}", fmt(last, loc))
      |> String.replace("%{shown}", fmt(shown, loc))
      |> String.replace("%{total}", fmt(total, loc))
    end
  end

  defp current_text(%{shape: "compact"} = a, page, total) do
    loc = I18n.locale(a.locale)
    fmt(page, loc) <> " / " <> fmt(total, loc)
  end

  defp current_text(_, _, _), do: nil

  # the integer with the thousands separator of the locale: `.` in pt_BR, `,` otherwise
  defp fmt(n, locale) do
    sep = if locale == "pt_BR", do: ".", else: ","

    n
    |> Integer.to_string()
    |> String.replace(~r/\B(?=(\d{3})+(?!\d))/, sep)
  end

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
          class: cx([loop_class(a, p), extra_attrs(a.page_attrs, p)[:class]]),
          attrs: loop_attrs(a, p, extra_attrs(a.page_attrs, p)[:attrs])
        }
    end)
  end

  # `loop`: pages 1-4 take the current look in turn, 1.5s apart
  defp loop_class(%{loop: true}, p) when is_integer(p) and p <= 4,
    do: "animate-[lu-pgon_6s_infinite] [animation-delay:var(--dl)]"

  defp loop_class(_, _), do: nil

  defp loop_attrs(%{loop: true}, p, attrs) when is_integer(p) and p <= 4,
    do: Map.put_new(attrs, :style, "--dl:#{Float.round((p - 1) * 1.5, 1)}s")

  defp loop_attrs(_, _, attrs), do: attrs

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
