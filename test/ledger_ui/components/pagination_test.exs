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

    assert html =~ ~s(class="lu-pg2")
    assert html =~ ~s(<span class="on">2</span>)
    assert html =~ "…"
    assert html =~ ~s(<span class="ar">)
    refute html =~ "<button"
  end

  test "shape and size" do
    assigns = %{}
    html = norm(~H|<.pagination page={1} total_pages={5} shape="pill" size="lg" />|)
    assert html =~ "lu-pg2 pill s-lg"

    html =
      norm(~H|<.pagination page={1} total_pages={5} shape="rounded" size="sm" />|)

    assert html =~ "lu-pg2 rounded s-sm"
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

    assert html =~ ~s(class="lu-row")
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
    assert html =~ "lu-row lu-pager"
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
    refute html =~ "lu-pg2"
  end

  test "classic shape: bar of buttons" do
    assigns = %{}

    html =
      norm(~H|<.pagination page={2} total_pages={5} shape="classic" on_change="go" />|)

    assert html =~ ~s(class="lu-pages")
    assert html =~ "lu-btn icon ghost sm"
    assert html =~ ~s(<button class="on")
  end

  test "arrows can be hidden" do
    assigns = %{}
    html = norm(~H|<.pagination page={2} total_pages={5} arrows={false} />|)
    refute html =~ ~s(class="ar")
  end

  test "page_attrs adds attrs per item" do
    assigns = %{}

    html =
      norm(~H"""
      <.pagination page={1} total_pages={3} page_attrs={fn p -> %{style: "--dl:#{p}s", class: "n"} end} />
      """)

    assert html =~ ~s(style="--dl:2s")
    assert html =~ ~s(class="on n")
  end
end
