defmodule LedgerUI.Components.CardTableTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.CardTable

  test "rows variant in a card, flat bare" do
    assigns = %{rows: [%{n: 1}]}

    html = rendered_to_string(~H|<.card_table id="c" rows={@rows}>
  <:col :let={r} label="N">{r.n}</:col>
</.card_table>|)
    assert html =~ "lu-card"
    assert html =~ "lu-card-b"

    html = rendered_to_string(~H|<.card_table id="f" variant="flat" rows={@rows}>
  <:col :let={r} label="N">{r.n}</:col>
</.card_table>|)
    refute html =~ "lu-card"
    assert html =~ "lu-table flat"
  end

  test "status adds a bar" do
    assigns = %{rows: [%{n: 1}]}

    html = rendered_to_string(~H|<.card_table id="c" rows={@rows} status={fn _ -> "error" end}>
  <:col :let={r} label="N">{r.n}</:col>
</.card_table>|)
    assert html =~ "data-status=\"error\""
    assert html =~ "inset 3px 0 0 var(--neg)"
  end

  test "breakpoints are validated" do
    assigns = %{rows: []}

    assert_raise ArgumentError, fn ->
      rendered_to_string(~H|<.card_table id="c" rows={@rows} breakpoints={[1, 2]}>
  <:col label="N">x</:col>
</.card_table>|)
    end
  end

  test "sub line classes" do
    assigns = %{}
    html = rendered_to_string(~H|<.ctable_sub priority={2} when_hidden="p1">x</.ctable_sub>|)
    assert html =~ "lu-p2"
    assert html =~ "lu-wh1"
  end
end
