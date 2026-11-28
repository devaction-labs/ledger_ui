defmodule LedgerUI.WrapTest do
  # #102: `LedgerUI.Wrap.call/3` keeps the `__changed__` the wrapper received, so a wrapper of a
  # kit component costs what the kit component costs. The naive wrapper (`{@rest}` in HEEx) is
  # measured next to it to show the difference.
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI

  import LedgerUI.DiffCase

  alias LedgerUI.Components.Badge
  alias LedgerUI.Wrap

  ## put / map / rename / spread, on a probe that records what it receives

  def probe(assigns) do
    send(self(), {:probe, Map.drop(assigns, [:__given__])})
    ~H"<i></i>"
  end

  defp seen do
    receive do
      {:probe, assigns} -> assigns
    after
      0 -> flunk("probe not called")
    end
  end

  test "first render (changed nil): kit gets nil and every derived key" do
    Wrap.call(%{a: 1, rest: %{id: "x"}, __changed__: nil}, &probe/1,
      put: [fixed: 1, derived: {:from, [:a], 2}],
      map: [b: {:a, &(&1 + 10)}],
      rename: [a: :c],
      spread: :rest
    )

    assigns = seen()
    assert assigns.__changed__ == nil
    assert %{fixed: 1, derived: 2, b: 11, c: 1, id: "x"} = assigns
    refute Map.has_key?(assigns, :a)
    refute Map.has_key?(assigns, :rest)
  end

  test "a derived key is in __changed__ only when its source is" do
    run = fn changed ->
      Wrap.call(%{a: 1, z: 0, __changed__: changed}, &probe/1,
        put: [fixed: 1, derived: {:from, [:a], 2}, other: {:from, [:z], 3}],
        map: [b: {:a, &(&1 + 10)}, y: {:z, & &1}],
        rename: [a: :c]
      )

      seen().__changed__
    end

    assert run.(%{}) == %{}
    assert run.(%{z: true}) == %{z: true, y: true, other: true}
    assert run.(%{a: true}) == %{c: true, derived: true, b: true}
    # a fixed key is only marked when the wrapper itself got a key of that name as changed
    assert run.(%{fixed: true}) == %{fixed: true}
  end

  test "spread marks the keys of the rest only when :rest changed" do
    run = fn changed ->
      Wrap.call(%{rest: %{id: "x", title: "t"}, n: 1, __changed__: changed}, &probe/1,
        spread: :rest
      )

      seen().__changed__
    end

    assert run.(%{n: true}) == %{n: true}
    assert run.(%{rest: true}) == %{id: true, title: true}
  end

  ## a wrapper of a badge

  defp kit_color("danger"), do: "error"
  defp kit_color(c), do: c

  attr :color, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def status_badge(assigns) do
    Wrap.call(assigns, &Badge.badge/1,
      put: [variant: {:from, [:color], (assigns.color && "soft") || "outline"}],
      map: [color: {:color, fn c -> kit_color(c || "neutral") end}],
      spread: :rest
    )
  end

  # the naive wrapper of the issue: HEEx with {@rest}
  attr :color, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def naive_badge(assigns) do
    ~H"""
    <Badge.badge variant="soft" color={kit_color(@color || "neutral")} {@rest}>
      {render_slot(@inner_block)}
    </Badge.badge>
    """
  end

  defp badge_page(assigns) do
    ~H"""
    <.status_badge color={@color} title="t">{@text}</.status_badge>
    """
  end

  defp naive_page(assigns) do
    ~H"""
    <.naive_badge color={@color} title="t">{@text}</.naive_badge>
    """
  end

  defp kit_page(assigns) do
    ~H"""
    <.badge variant="soft" color="error" title="t">{@text}</.badge>
    """
  end

  @badge %{color: "danger", text: "Overdue"}

  test "badge wrapper: same HTML as the kit, a text change under 60 B" do
    {_, html} = first(&badge_page/1, @badge)
    assert html =~ "Overdue"
    assert html =~ ~s(title="t")
    assert html =~ "--lu-neg"

    assert normalize(html) == normalize(html(&kit_page/1, @badge))

    bytes = byte_size(check(&badge_page/1, @badge, text: "Paid"))
    naive = byte_size(check(&naive_page/1, @badge, text: "Paid"))
    IO.puts("badge text change: wrapper #{bytes} B, naive {@rest} wrapper #{naive} B")
    assert bytes < 60
    assert naive > 4 * bytes
  end

  test "badge wrapper: every source is tracked" do
    each_source(&badge_page/1, @badge, color: "success", text: "Other")
  end

  ## a wrapper of a card_table with 25 rows

  @rows for i <- 1..25, do: %{id: i, name: "name-#{i}", amount: "R$ #{i}"}

  attr :rows, :list, required: true
  attr :selected, :list, default: []
  attr :on_select, :any, default: nil
  attr :on_select_all, :any, default: nil
  attr :rest, :global

  slot :col do
    attr :label, :string
  end

  slot :action

  def my_table(assigns) do
    Wrap.call(assigns, &LedgerUI.Components.CardTable.card_table/1,
      put: [selection_badge: false, row_key: &row_key/1, row_item: &Function.identity/1],
      spread: :rest
    )
  end

  defp row_key(r), do: to_string(r.id)

  defp table_page(assigns) do
    ~H"""
    <.my_table id="t" rows={@rows} selected={@selected} on_select="s" on_select_all="sa">
      <:col :let={r} label="Name">{r.name}</:col>
      <:col :let={r} label="Amount">{r.amount}</:col>
      <:action :let={r}>act-{r.id}</:action>
    </.my_table>
    """
  end

  attr :rows, :list, required: true
  attr :selected, :list, default: []
  attr :on_select, :any, default: nil
  attr :on_select_all, :any, default: nil
  attr :rest, :global

  slot :col do
    attr :label, :string
  end

  slot :action

  def naive_table(assigns) do
    ~H"""
    <.card_table
      rows={@rows}
      selected={@selected}
      on_select={@on_select}
      on_select_all={@on_select_all}
      selection_badge={false}
      row_key={&row_key/1}
      row_item={&Function.identity/1}
      {@rest}
    >
      <:col :let={r} :for={c <- @col} label={c.label}>{render_slot(c, r)}</:col>
      <:action :let={r} :for={a <- @action}>{render_slot(a, r)}</:action>
    </.card_table>
    """
  end

  defp naive_table_page(assigns) do
    ~H"""
    <.naive_table id="t" rows={@rows} selected={@selected} on_select="s" on_select_all="sa">
      <:col :let={r} label="Name">{r.name}</:col>
      <:col :let={r} label="Amount">{r.amount}</:col>
      <:action :let={r}>act-{r.id}</:action>
    </.naive_table>
    """
  end

  test "card_table wrapper with 25 rows: selecting one row under 1.2 KB" do
    base = %{rows: @rows, selected: []}
    bytes = byte_size(check(&table_page/1, base, selected: ["3"]))
    {first_json, _} = first(&table_page/1, base)

    naive = byte_size(patch(&naive_table_page/1, base, selected: ["3"]))

    IO.puts(
      "card_table selected: wrapper #{bytes} B, naive wrapper #{naive} B, first #{byte_size(first_json)} B"
    )

    assert bytes < 1200
    assert naive > 10 * bytes
  end

  defp normalize(html) do
    html |> String.replace(~r/\s+/, " ") |> String.replace("> <", "><") |> String.trim()
  end
end
