defmodule LedgerUI.Components.BulkBarTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.BulkBar

  test "actions get the automatic loading state of phx-click-loading (#74)" do
    for variant <- ["inverse", "float"] do
      assigns = %{variant: variant}

      html =
        rendered_to_string(~H|<.bulk_bar id="b" count={2} variant={@variant}>
  <:action phx-click="a">A</:action>
</.bulk_bar>|)

      [action] = Regex.run(~r/<button[^>]*data-part="bulk-bar-action"[^>]*>/, html)
      assert action =~ "[&amp;.phx-click-loading]:pointer-events-none"
      assert action =~ "[&amp;.phx-click-loading]:opacity-60"
    end
  end

  test "hidden at zero" do
    assigns = %{}
    assert rendered_to_string(~H|<.bulk_bar id="b" count={0} />|) == ""
  end

  test "pill with separators, plural label and close" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.bulk_bar
  id="b"
  count={3}
  label="item"
  label_plural="items"
  floating={false}
  on_clear="clear"
  show_esc
>
  <:action icon="file" phx-click="a">A</:action>
  <:action variant="danger" phx-click="d">D</:action>
</.bulk_bar>|)

    assert html =~ "3 items"
    assert html =~ "bg-inverse"
    assert length(String.split(html, "data-part=\"bulk-bar-separator\"")) == 3
    assert html =~ "Esc"
    assert html =~ "phx-window-keydown"
  end

  test "disabled actions drop phx attrs, confirm opens a card" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.bulk_bar id="b" count={1} variant="solid">
  <:action disabled phx-click="x">X</:action>
  <:action phx-click="del" confirm="Sure?" confirm_text="t" confirm_label="Yes" cancel_label="No">
    Del
  </:action>
</.bulk_bar>|)

    assert html =~ "aria-disabled=\"true\""
    refute html =~ "phx-click=\"x\""
    assert html =~ "Sure?"
    assert html =~ "alertdialog"
    assert html =~ "fixed bottom-6 left-1/2"
    assert html =~ "bg-accent-600"
  end

  test "progress and inline variants" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.bulk_bar id="b" count={12} label="Emitindo" progress={5} progress_max={12} />|
      )

    assert html =~ "5/12"

    html =
      rendered_to_string(
        ~H|<.bulk_bar id="b" count={2} total={10} variant="inline" on_select_all="all" />|
      )

    assert html =~ "bg-accent-soft"
    assert html =~ ~s(data-part="checkbox")
    assert html =~ "Select all 10"
  end

  test "float: the dark pill with a rule before the danger action and a close" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.bulk_bar
  id="b"
  variant="float"
  count={3}
  label="selecionado"
  label_plural="selecionados"
  on_clear="clear"
  clear_label="Limpar"
>
  <:action icon="file" phx-click="a">A</:action>
  <:action variant="danger" icon="trash" phx-click="d">D</:action>
</.bulk_bar>|)

    assert html =~ "absolute bottom-[22px] left-1/2"
    assert html =~ "3 selecionados</b>"
    assert html =~ ~s(data-part="bulk-bar-separator")
    assert html =~ "text-[#ff9b8f]"
    assert html =~ ~s(aria-label="Limpar")
    refute html =~ "w-max"
    refute html =~ "fixed bottom-6"

    assert rendered_to_string(~H|<.bulk_bar id="b" variant="float" count={0} />|) == ""
  end

  describe "inline" do
    defp inline_html(extra \\ %{}) do
      assigns = Map.merge(%{clear: "clear"}, extra)

      rendered_to_string(~H|<.bulk_bar
  id="b"
  variant="inline"
  count={3}
  total={105_299}
  label="selecionado"
  label_plural="selecionados"
  select_all_label="Selecionar todos os %{total}"
  clear_label="Limpar seleção (Esc)"
  on_select_all="all"
  on_clear={@clear}
>
  <:field><button type="button" class="lu-btn">Mover para</button></:field>
  <:action icon="file" phx-click="nf">Emitir NF-e</:action>
  <:action variant="primary" phx-click="exp">Exportar</:action>
  <:action variant="danger" phx-click="del" confirm="Cancelar?">Cancelar</:action>
</.bulk_bar>|)
    end

    test "order: checkbox, count, select all, rule, field, actions, rule, close" do
      html = inline_html()

      positions =
        for part <-
              ~w(checkbox bulk-bar-count bulk-bar-select-all bulk-bar-separator bulk-bar-field bulk-bar-action bulk-bar-clear) do
          {pos, _} = :binary.match(html, ~s(data-part="#{part}"))
          pos
        end

      assert positions == Enum.sort(positions)
      assert html =~ ~s(indeterminate)
      assert html =~ "3 selecionados</b>"
      assert html =~ "Selecionar todos os 105299"
      assert length(String.split(html, ~s(data-part="bulk-bar-separator"))) == 3
    end

    test "count is 13.5px ink; padding, gap and no wrapping" do
      html = inline_html()
      assert html =~ "text-[13.5px] font-semibold text-ink"
      assert html =~ "py-1.5 pr-1.5 pl-3"
      assert html =~ "gap-2.5"
      assert html =~ "flex-nowrap"
      assert html =~ "whitespace-nowrap"
    end

    test "every action is ghost, danger is ghost with the negative colour" do
      html = inline_html()

      assigns = %{}

      plain =
        rendered_to_string(~H|<.bulk_bar id="b" variant="inline" count={2}>
  <:action phx-click="a">A</:action>
  <:action variant="primary" phx-click="p">P</:action>
  <:action variant="danger" phx-click="d">D</:action>
</.bulk_bar>|)

      refute plain =~ "bg-neg-soft"
      refute plain =~ "bg-inverse"
      refute plain =~ "shadow-xs"
      assert length(String.split(html, "text-ink-2 hover:bg-hover")) - 1 == 3
      assert html =~ "text-neg hover:bg-hover"
      assert length(String.split(html, "data-neg")) == 2
    end

    test "close button: aria-label, title, on_clear and target; only with on_clear" do
      html = inline_html()
      assert html =~ ~s|aria-label="Limpar seleção (Esc)"|
      assert html =~ ~s|title="Limpar seleção (Esc)"|
      assert html =~ ~s(data-part="bulk-bar-clear")
      assert html =~ ~s(phx-key="Escape")

      html = inline_html(%{clear: nil})
      refute html =~ ~s(data-part="bulk-bar-clear")
      assert length(String.split(html, ~s(data-part="bulk-bar-separator"))) == 2
    end

    test "close button targets the component" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<.bulk_bar id="b" variant="inline" count={1} on_clear="clear" target="#t" />|
        )

      assert html =~ ~r/data-part="bulk-bar-clear"[^>]*phx-target="#t"/
    end

    test "field buttons are styled ghost" do
      html = inline_html()
      assert html =~ "[&amp;_button:not([role=menuitem])]:bg-transparent"
      assert html =~ "[&amp;_button:not([role=menuitem])]:border-transparent"
    end
  end

  describe "action variants" do
    test "ghost and neg are accepted in every look" do
      assigns = %{}

      for v <- ~w(inverse soft solid inline float) do
        assigns = %{v: v}

        html =
          rendered_to_string(~H|<.bulk_bar id="b" variant={@v} count={2}>
  <:action variant="ghost" phx-click="a">A</:action>
  <:action variant="neg" phx-click="d">D</:action>
</.bulk_bar>|)

        assert html =~ ~r/>\s*A\s*</
        assert html =~ ~r/>\s*D\s*</
      end
    end

    test "neg in a pill is set apart by a rule, like danger" do
      assigns = %{}

      html =
        rendered_to_string(~H|<.bulk_bar id="b" count={2} floating={false}>
  <:action phx-click="a">A</:action>
  <:action variant="neg" phx-click="d">D</:action>
</.bulk_bar>|)

      assert length(String.split(html, ~s(data-part="bulk-bar-separator"))) == 3
    end
  end

  describe "canvas pill (#53)" do
    test "default pill: no checkbox, centred as before, X has a title" do
      assigns = %{}

      html =
        rendered_to_string(~H|<.bulk_bar id="b" count={2} on_clear="clear">
  <:action variant="danger">D</:action>
</.bulk_bar>|)

      refute html =~ ~s(id="b-check")
      assert html =~ "ml-[var(--lu-bulk-offset,0px)]"
      refute html =~ "--lu-bulk-offset:"
      assert html =~ ~s(title="Clear selection")
      refute html =~ "text-neg"
    end

    test "canvas adds the checkbox, rules, accent-300 select all and negative danger" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.bulk_bar id="b" count={2} total={9} canvas on_clear="clear" on_select_all="all">
          <:action>A</:action>
          <:action variant="danger">D</:action>
        </.bulk_bar>
        """)

      assert html =~ ~s(id="b-check")
      assert html =~ ~s(aria-label="Selection")
      assert html =~ ~s(data-ind="1")
      assert html =~ "bg-accent-500"
      assert html =~ "text-accent-300"
      assert html =~ "text-neg"
      assert html =~ "whitespace-nowrap"
      assert length(String.split(html, ~s(data-part="bulk-bar-separator"))) - 1 >= 3
    end

    test "offset sets the CSS variable" do
      assigns = %{}
      html = rendered_to_string(~H|<.bulk_bar id="b" count={2} offset={136} />|)
      assert html =~ "--lu-bulk-offset:136px"
      html = rendered_to_string(~H|<.bulk_bar id="b" count={2} offset={-74} />|)
      assert html =~ "--lu-bulk-offset:-74px"
    end

    test "offset auto centres on the shell main area and writes no inline style" do
      assigns = %{}
      html = rendered_to_string(~H|<.bulk_bar id="b" count={2} offset="auto" />|)
      assert html =~ "var(--lu-sidebar-w,0px)"
      assert html =~ "var(--lu-aside-w,0px)"
      refute html =~ "--lu-bulk-offset"
      refute html =~ "left-1/2"
    end

    test "offset rejects other values" do
      assigns = %{}

      assert_raise ArgumentError, fn ->
        rendered_to_string(~H|<.bulk_bar id="b" count={2} offset="left" />|)
      end
    end

    test "the field of a pill is ghost in the pill colour, menu items excluded" do
      for {variant, color} <- [
            {"inverse", "text-on-inverse"},
            {"soft", "text-accent-content"},
            {"solid", "text-accent-foreground"}
          ] do
        assigns = %{variant: variant}

        html =
          rendered_to_string(~H"""
          <.bulk_bar id="b" variant={@variant} count={2}>
            <:field><button>Move</button></:field>
          </.bulk_bar>
          """)

        [_, field] = Regex.run(~r/<div data-part="bulk-bar-field" class="([^"]*)"/, html)
        assert field =~ "[&amp;_button:not([role=menuitem])]:#{color}"
        assert field =~ "[&amp;_button:not([role=menuitem])]:bg-transparent"
        assert field =~ "[&amp;_button:not([role=menuitem])]:border-transparent"
        assert field =~ "[&amp;_button:not([role=menuitem])]:shadow-none"
        assert field =~ "[&amp;_button:not([role=menuitem]):hover]:bg-[rgba(127,127,127,.22)]"
      end
    end
  end
end
