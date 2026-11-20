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
    assert html =~ "bg-tray"
    assert html =~ ~s(data-part="card-table-body")

    html = rendered_to_string(~H|<.card_table id="f" variant="flat" rows={@rows}>
  <:col :let={r} label="N">{r.n}</:col>
</.card_table>|)
    refute html =~ "bg-tray"
    assert html =~ "lu-table flat"
  end

  test "status adds a bar" do
    assigns = %{rows: [%{n: 1}]}

    html = rendered_to_string(~H|<.card_table id="c" rows={@rows} status={fn _ -> "error" end}>
  <:col :let={r} label="N">{r.n}</:col>
</.card_table>|)
    assert html =~ "data-status=\"error\""
    assert html =~ "inset 3px 0 0 var(--lu-neg)"
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

  describe "card layout, panel, copy, edit, row_action" do
    defp rows,
      do: [
        %{id: 1, n: "ORD-1", c: "Ana", t: "10", i: "Acme"},
        %{id: 2, n: "ORD-2", c: "Bia", t: "20", i: "Foo"}
      ]

    test "roles draw the card layout css and the role classes" do
      assigns = %{rows: rows()}

      html = rendered_to_string(~H|<.card_table id="c" rows={@rows}>
  <:col :let={r} label="N" role="head">{r.n}</:col>
  <:col :let={r} label="C" role="title" width="minmax(120px,1.3fr)">{r.c}</:col>
  <:col :let={r} label="T" role="value" align="end">{r.t}</:col>
  <:col :let={r} label="I" card>{r.i}</:col>
</.card_table>|)

      assert html =~ "lu-r-head"
      assert html =~ "lu-r-title lu-ct-flex" or html =~ "lu-ct-flex"
      assert html =~ "lu-ckeep"
      assert html =~ "min-width:120px"
      assert html =~ "@container (max-width:520px){#c thead"
      assert html =~ ~s(role="row")
    end

    test "custom last breakpoint moves the card layout" do
      assigns = %{rows: rows()}

      html =
        rendered_to_string(~H|<.card_table id="c" rows={@rows} breakpoints={[1180, 980, 560]}>
  <:col :let={r} label="N" role="head">{r.n}</:col>
</.card_table>|)

      assert html =~ "@container (max-width:560px){#c thead"
    end

    test "no roles, no card layout and no extra markup" do
      assigns = %{rows: rows()}

      html = rendered_to_string(~H|<.card_table id="c" rows={@rows}>
  <:col :let={r} label="N">{r.n}</:col>
</.card_table>|)

      refute html =~ "lu-r-"
      refute html =~ "role="
      refute html =~ "LedgerUI.CardTable"
    end

    test "details panel with detail slots and hidden columns, hook on the tbody" do
      assigns = %{rows: rows()}

      html = rendered_to_string(~H|<.card_table id="c" rows={@rows}>
  <:col :let={r} label="N">{r.n}</:col>
  <:col :let={r} label="Issuer" priority={2}>{r.i}</:col>
  <:col :let={r} label="Dup" priority={1}>{r.t}</:col>
  <:detail :let={r} label="Dup">{r.t}</:detail>
</.card_table>|)

      assert html =~ ~s(phx-hook="LedgerUI.CardTable")
      assert html =~ ~s(aria-expanded="false")
      assert html =~ "data-ct-row"
      assert html =~ ~s(role="group" aria-label="Details")
      assert html =~ "lu-ct-prow"
      assert html =~ "lu-wh2"
      # the column with the label of a detail is not repeated as a hidden column
      refute html =~ "lu-ct-pi lu-wh1"
    end

    test "copy column draws a button with tooltip text" do
      assigns = %{rows: rows()}

      html = rendered_to_string(~H|<.card_table id="c" rows={@rows}>
  <:col
    :let={r}
    label="N"
    copy={& &1.n}
    copy_label="Copiar"
    copied_label="Copiado"
    copy_show="inline"
    copy_tip="value_label"
  >
    {r.n}
  </:col>
</.card_table>|)

      assert html =~ ~s(data-lu-ct-copy="ORD-1")
      assert html =~ ~s(aria-label="Copiar")
      assert html =~ "Copiado"
      assert html =~ "lu-ct-val inline"
      assert html =~ ~s(phx-hook="LedgerUI.CardTable")
    end

    test "row_editing swaps the cells for the edit slot, row_action leaves an action out" do
      assigns = %{rows: rows()}

      html =
        rendered_to_string(
          ~H|<.card_table id="c" rows={@rows} row_editing={&(&1.id == 1)} row_action={&(&1.id != 2)}>
  <:col :let={r} label="N">{r.n}</:col>
  <:edit :let={r}>
    <form>edit {r.n}</form>
  </:edit>
  <:action :let={r}>act {r.id}</:action>
</.card_table>|
        )

      assert html =~ ~s(data-editing="true")
      assert html =~ "edit ORD-1"
      refute html =~ "act 1"
      refute html =~ "act 2"
      refute html =~ ~r/>\s*ORD-1\s*</
      assert html =~ ~r/>\s*ORD-2\s*</
    end

    test "action priority and card=false" do
      assigns = %{rows: rows()}

      html = rendered_to_string(~H|<.card_table id="c" rows={@rows}>
  <:col :let={r} label="N" role="head">{r.n}</:col>
  <:action :let={r} priority={3} card={false}>x{r.id}</:action>
</.card_table>|)

      assert html =~ "lu-p3"
      assert html =~ "lu-ct-nocard"
    end
  end
end
