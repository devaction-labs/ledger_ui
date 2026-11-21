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
    assert html =~ "[--tbb:0_none]"
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
    assert html =~ "@max-[960px]:hidden"
    assert html =~ "@max-[1180px]:block"
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

      assert html =~ "@max-[520px]:[grid-area:head]"
      assert html =~ "max-w-0"
      assert html =~ "@max-[520px]:[grid-area:keep]"
      assert html =~ "min-width:120px"
      assert html =~ "@max-[520px]:grid-cols-"
      refute html =~ "<style"
      assert html =~ ~s(role="row")
    end

    test "custom last breakpoint moves the card layout" do
      assigns = %{rows: rows()}

      html =
        rendered_to_string(~H|<.card_table id="c" rows={@rows} breakpoints={[1180, 980, 560]}>
  <:col :let={r} label="N" role="head">{r.n}</:col>
</.card_table>|)

      assert html =~ "@max-[560px]:[grid-area:head]"
    end

    test "no roles, no card layout and no extra markup" do
      assigns = %{rows: rows()}

      html = rendered_to_string(~H|<.card_table id="c" rows={@rows}>
  <:col :let={r} label="N">{r.n}</:col>
</.card_table>|)

      refute html =~ "[grid-area:"
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
      assert html =~ ~s(data-part="table-panel-row")
      assert html =~ "@max-[960px]:flex"
      # the column with the label of a detail is not repeated as a hidden column
      refute html =~ "@max-[1180px]:flex"
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
      assert html =~ ~s(data-part="table-copy-value")
      assert html =~ "mr-2 inline"
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

      assert html =~ "@max-[720px]:hidden"
      assert html =~ "@max-[520px]:hidden"
    end
  end

  describe "toolbar and selection inside the card" do
    defp base(extra \\ %{}), do: Map.merge(%{rows: [%{id: 1, n: "A"}, %{id: 2, n: "B"}]}, extra)

    test "without the new options nothing new is drawn" do
      assigns = base()

      html = rendered_to_string(~H|<.card_table id="c" rows={@rows} title="T">
  <:col :let={r} label="N">{r.n}</:col>
</.card_table>|)

      refute html =~ "card-table-toolbar"
      refute html =~ "card-table-selection"
      refute html =~ "card-table-loading"
      refute html =~ "card-table-error"
    end

    test "toolbar renders inside the body with a hairline" do
      assigns = base()

      html = rendered_to_string(~H|<.card_table id="c" rows={@rows}>
  <:toolbar><input name="q" /></:toolbar>
  <:col :let={r} label="N">{r.n}</:col>
</.card_table>|)

      assert html =~ ~s(data-part="card-table-toolbar")
      assert html =~ "border-b border-line"
      assert html =~ ~s(<input name="q")
    end

    test "selection shows only with selected rows and receives the count" do
      assigns = base(%{sel: []})

      tpl = fn assigns ->
        rendered_to_string(~H|<.card_table
  id="c"
  rows={@rows}
  selected={@sel}
  selection_label="selecionado"
  selection_label_plural="selecionados"
>
  <:selection :let={s}><span id="n">{s.count}/{length(s.selected)}</span></:selection>
  <:col :let={r} label="N">{r.n}</:col>
</.card_table>|)
      end

      refute tpl.(assigns) =~ "card-table-selection"

      html = tpl.(%{assigns | sel: [1, 2]})
      assert html =~ ~s(data-part="card-table-selection")
      assert html =~ ~s(aria-live="polite")
      assert html =~ "bg-accent-soft"
      assert html =~ ~s(<span id="n">2/2</span>)
      assert html =~ "2 selecionados"
      assert tpl.(%{assigns | sel: [1]}) =~ "1 selecionado\n"
    end

    test "DOM order: heading, toolbar, selection, table" do
      assigns = base(%{sel: [1]})

      html = rendered_to_string(~H|<.card_table id="c" rows={@rows} title="T" selected={@sel}>
  <:toolbar>tb</:toolbar>
  <:selection>sel</:selection>
  <:col :let={r} label="N">{r.n}</:col>
</.card_table>|)

      pos = fn part -> :binary.match(html, ~s(data-part="#{part}")) |> elem(0) end
      assert pos.("card-table-head") < pos.("card-table-toolbar")
      assert pos.("card-table-toolbar") < pos.("card-table-selection")
      assert pos.("card-table-selection") < pos.("table")
    end
  end
end
