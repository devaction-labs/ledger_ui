defmodule LedgerShowcase.OrdersDataTest do
  use ExUnit.Case, async: true
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  @endpoint LedgerShowcaseWeb.Endpoint

  alias LedgerShowcase.Templates, as: T

  test "every order's detail adds up to its row" do
    for o <- T.orders() do
      d = T.detail(o)
      assert T.detail_total(d) == o.total, "total of ##{o.id}"
      assert length(d.lines) + d.rest_items == o.items, "items of ##{o.id}"
      assert d.rest_items == 0 == (d.rest_cents == 0), "rest of ##{o.id}"
      assert Enum.all?(d.lines, &(&1.qty > 0 and &1.cents > 0))
    end
  end

  test "order 2495 stays the canvas board's" do
    d = T.detail(T.order(2495))
    assert {d.rest_items, d.rest_cents, d.discount} == {28, 241_004, 3_250}
    assert Enum.map(d.lines, & &1.qty) == [12, 24, 6, 10]
  end

  test "an order link or the gaveta board start without selection and bulk bar" do
    for path <- ["/templates/tabela?pedido=2493", "/templates/tabela-gaveta"] do
      {:ok, _lv, html} = live(build_conn(), path)
      refute html =~ "lu-bulkfloat"
      refute html =~ "selecionados"
    end
  end
end
