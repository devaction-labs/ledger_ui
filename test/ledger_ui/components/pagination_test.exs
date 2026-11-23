defmodule LedgerUI.Components.PaginationTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Pagination

  defp norm(rendered) do
    rendered
    |> rendered_to_string()
    |> String.replace(~r/\s+/, " ")
    |> String.replace(~r/>\s+/, ">")
    |> String.replace(~r/\s+</, "<")
  end

  defp items(page, total, opts \\ []),
    do:
      LedgerUI.Components.Pagination.items(
        page,
        total,
        Map.new([siblings: 1, boundaries: 1] ++ opts)
      )

  # the opening tag of the n-th element with `data-part`
  defp tag(html, part, n \\ 0) do
    ~r/<[a-z0-9]+[^>]*data-part="#{part}"[^>]*>/ |> Regex.scan(html) |> Enum.at(n) |> hd()
  end

  test "page window with ellipses" do
    assert items(2, 44) == [1, 2, 3, 4, :ellipsis, 44]
    assert items(22, 44) == [1, :ellipsis, 21, 22, 23, :ellipsis, 44]
    assert items(43, 44) == [1, :ellipsis, 41, 42, 43, 44]
    assert items(1, 5) == [1, 2, 3, 4, 5]
    assert items(1, 1) == [1]
  end

  test "canvas default: spans, current marked, arrows after the pages" do
    assigns = %{}
    html = norm(~H|<.pagination page={2} total_pages={44} />|)

    assert tag(html, "pagination") =~ "font-mono"
    # the current page: the ink chip, marked aria-current as the pager is display-only
    assert tag(html, "pagination-page", 1) =~ "bg-ink"
    assert tag(html, "pagination-page", 1) =~ ~s(aria-current="page")
    assert tag(html, "pagination-page", 0) =~ "text-ink-2"
    assert html =~ "…"
    assert tag(html, "pagination-arrow") =~ "rounded-md"
    refute tag(html, "pagination-arrow") =~ "rounded-full"
    refute html =~ ~r/[\s"]lu-/
    refute html =~ "<button"
  end

  test "shape and size" do
    assigns = %{}
    html = norm(~H|<.pagination page={1} total_pages={5} shape="pill" size="lg" />|)
    assert tag(html, "pagination-page", 0) =~ "bg-accent"
    assert tag(html, "pagination-page", 0) =~ "rounded-full"
    assert tag(html, "pagination-page", 0) =~ "h-10"
    assert tag(html, "pagination-arrow") =~ "rounded-full"

    html =
      norm(~H|<.pagination page={1} total_pages={5} shape="rounded" size="sm" />|)

    assert tag(html, "pagination-page", 0) =~ "shadow-[0_0_0_1px_var(--lu-line-strong)"
    assert tag(html, "pagination-page", 0) =~ "h-[26px]"
    assert tag(html, "pagination-arrow") =~ "rounded-md"
  end

  test "on_change makes buttons pushing the page" do
    assigns = %{}

    html =
      norm(~H|<.pagination page={2} total_pages={5} on_change="paginate" target="#t" />|)

    assert html =~ "<button"
    assert html =~ ~s(phx-click="paginate")
    assert html =~ ~s(phx-value-page="3")
    assert html =~ ~s(phx-target="#t")
    assert html =~ ~s(aria-current="page")
    assert html =~ ~s(aria-label="Page 3")
    assert html =~ ~s(aria-label="Previous page")
  end

  test "patch builds links; the arrow at the end is inert" do
    assigns = %{}

    html =
      norm(~H|<.pagination page={1} total_pages={3} patch={&"/o?page=#{&1}"} />|)

    assert html =~ ~s(href="/o?page=2")
    assert html =~ ~s(data-phx-link="patch")
    refute html =~ ~s(aria-label="Previous page")
    assert html =~ ~s(aria-label="Next page")
  end

  test "footer: summary, page sizes form" do
    assigns = %{}

    html =
      norm(~H"""
      <.pagination
        page={2}
        page_size={15}
        total_entries={128}
        page_sizes={[15, 30]}
        on_change="p"
        on_page_size="per"
        page_size_label="%{size} / página"
      />
      """)

    assert tag(html, "pagination-footer") =~ "flex-wrap"
    assert tag(html, "pagination-spacer") =~ "flex-1"
    assert tag(html, "pagination-size") =~ "h-8"
    assert html =~ "Showing 16–30 of 128"
    assert html =~ ~s(role="status")
    assert html =~ ~s(phx-change="per")
    assert html =~ ~s(name="page_size")
    assert html =~ "30 / página"
    # 128 / 15 = 9 pages
    assert html =~ ">9<"
  end

  test "custom summary with %{shown}" do
    assigns = %{}

    html =
      norm(~H"""
      <.pagination
        class="lu-pager"
        page={1}
        page_size={10}
        total_entries={14}
        summary="%{shown} de %{total}"
        on_change="p"
      >
        <:aside>Webhook</:aside>
      </.pagination>
      """)

    assert html =~ "10 de 14"
    assert html =~ "Webhook"
    assert tag(html, "pagination-footer") =~ "gap-2.5 lu-pager"
  end

  test "a single page shows the aside instead of the pages" do
    assigns = %{}

    html =
      norm(~H"""
      <.pagination page={1} page_size={10} total_entries={4} on_change="p">
        <:aside>Only</:aside>
      </.pagination>
      """)

    assert html =~ "Only"
    refute html =~ ~s(data-part="pagination")
  end

  test "classic shape: bar of buttons" do
    assigns = %{}

    html =
      norm(~H|<.pagination page={2} total_pages={5} shape="classic" on_change="go" />|)

    assert tag(html, "pagination") =~ "gap-1"
    assert tag(html, "pagination-arrow") =~ "disabled:opacity-45"
    assert tag(html, "pagination-page", 1) =~ ~s(aria-current="page")
    assert tag(html, "pagination-page", 1) =~ "aria-[current=page]:bg-panel"
  end

  test "arrows can be hidden" do
    assigns = %{}
    html = norm(~H|<.pagination page={2} total_pages={5} arrows={false} />|)
    refute html =~ "pagination-arrow"
  end

  test "page_attrs adds attrs per item" do
    assigns = %{}

    html =
      norm(~H"""
      <.pagination page={1} total_pages={3} page_attrs={fn p -> %{style: "--dl:#{p}s", class: "n"} end} />
      """)

    assert html =~ ~s(style="--dl:2s")
    assert tag(html, "pagination-page", 0) =~ "bg-ink"
    assert tag(html, "pagination-page", 0) =~ ~r/ n"/
  end
end
