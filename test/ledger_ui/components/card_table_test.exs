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
    # one surface, no tray; the table touches the card (body p-0, no border of its own)
    assert html =~ "rounded-[18px] border border-line bg-panel shadow-xs"
    assert html =~ "overflow-hidden"
    refute html =~ "bg-tray"
    refute html =~ " p-1.5"
    assert html =~ ~s(data-part="card-table-body")
    assert html =~ ~s(class="relative min-w-0 flex-1 p-0")

    html = rendered_to_string(~H|<.card_table id="f" variant="flat" rows={@rows}>
  <:col :let={r} label="N">{r.n}</:col>
</.card_table>|)
    refute html =~ "bg-tray"
    refute html =~ "shadow-xs"
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

  describe "loading and error" do
    test "loading draws skeleton rows with the columns" do
      assigns = %{rows: []}

      html = rendered_to_string(~H|<.card_table id="c" rows={@rows} loading loading_rows={3}>
  <:col label="A">x</:col>
  <:col label="B">x</:col>
</.card_table>|)

      assert html =~ ~s(data-part="card-table-loading")
      assert html =~ ~s(aria-busy="true")
      assert length(String.split(html, ~s(data-part="card-table-loading-row"))) - 1 == 3
      assert length(String.split(html, ~s(data-part="skeleton"))) - 1 == 6

      html = rendered_to_string(~H|<.card_table id="c" rows={@rows} loading>
  <:col label="A">x</:col>
</.card_table>|)

      assert length(String.split(html, ~s(data-part="card-table-loading-row"))) - 1 == 5
    end

    test "error wins over loading and wires the retry event" do
      assigns = %{rows: []}

      html =
        rendered_to_string(
          ~H|<.card_table id="c" rows={@rows} loading error="Falhou" on_retry="retry" target="#x">
  <:col label="A">x</:col>
</.card_table>|
        )

      assert html =~ ~s(data-part="card-table-error")
      assert html =~ "Falhou"
      refute html =~ "card-table-loading"
      assert html =~ ~s(phx-click="retry")
      assert html =~ ~s(phx-target="#x")
      assert html =~ "Tentar novamente"
    end
  end

  describe "copy_toast (#35)" do
    defp copy_html(assigns) do
      rendered_to_string(~H"""
      <.card_table
        id="c"
        rows={@rows}
        loading={@loading}
        error={@error}
        copy_toast={@toast}
        copy_toast_message={@message}
      >
        <:col :let={r} label="N" copy={& &1.n} copied_label="Copiado">{r.n}</:col>
        <:col :let={r} label="M" copy={& &1.m} copy_toast={false}>{r.m}</:col>
      </.card_table>
      """)
    end

    defp toast_base,
      do: %{
        rows: [%{n: "PUB-123", m: "x"}],
        loading: false,
        error: nil,
        toast: true,
        message: nil
      }

    test "on by default: the value in bold, the copied label after it" do
      html = copy_html(toast_base())
      assert html =~ ~s(data-lu-ct-toast="**PUB-123** · Copiado")
      # the column that sets copy_toast={false} has none
      assert length(String.split(html, "data-lu-ct-toast")) == 2
    end

    test "copy_toast_message with %s" do
      html = copy_html(%{toast_base() | message: "%s copiado"})
      assert html =~ ~s(data-lu-ct-toast="**PUB-123** copiado")
    end

    test "copy_toast={false} turns it off; a column can turn it back on" do
      refute copy_html(%{toast_base() | toast: false}) =~ "data-lu-ct-toast"

      assigns = %{rows: [%{n: "A"}]}

      html =
        rendered_to_string(~H"""
        <.card_table id="c" rows={@rows} copy_toast={false}>
          <:col :let={r} label="N" copy={& &1.n} copy_toast>{r.n}</:col>
        </.card_table>
        """)

      assert html =~ ~s(data-lu-ct-toast="**A** · Copied")
    end

    test "a ** in the value cannot break the bold" do
      html = copy_html(%{toast_base() | rows: [%{n: "a**b", m: "x"}]})
      assert html =~ ~s(data-lu-ct-toast="**ab** · Copiado")
    end

    test "no toast with the table loading or with an error (there are no copy buttons)" do
      refute copy_html(%{toast_base() | loading: true}) =~ "data-lu-ct-toast"
      refute copy_html(%{toast_base() | error: "falhou"}) =~ "data-lu-ct-toast"
      refute copy_html(%{toast_base() | loading: true}) =~ "data-lu-ct-copy"
    end
  end

  test "col forwards grow, wrap and min" do
    assigns = %{rows: [%{n: 1}]}

    html = rendered_to_string(~H|<.card_table id="c" rows={@rows}>
  <:col :let={r} label="N" role="title" grow={1} wrap="auto" min="10rem">{r.n}</:col>
  <:col :let={r} label="M" role="value">{r.n}</:col>
</.card_table>|)
    assert html =~ "w-full"
    assert html =~ "--cmin:10rem"
    assert html =~ "whitespace-normal"
  end
end
