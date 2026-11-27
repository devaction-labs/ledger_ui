defmodule LedgerUI.Components.TableCellWrapTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Table

  defp cell_class(html, nth \\ 0) do
    [_ | rest] = String.split(html, ~s(data-part="table-cell"))
    chunk = Enum.at(rest, nth)
    [_, class] = Regex.run(~r/class="([^"]*)"/, chunk)
    class
  end

  defp tokens(class), do: String.split(class)

  describe ":cell of table_row" do
    test "without the new attrs it is nowrap and padded, as before" do
      assigns = %{}

      html =
        rendered_to_string(~H|<.table_row>
  <:cell>a</:cell>
</.table_row>|)

      class = cell_class(html)
      assert "whitespace-nowrap" in tokens(class)
      assert "px-[var(--tpx,14px)]" in tokens(class)
      assert "py-[var(--td-py,12px)]" in tokens(class)
    end

    test "wrap=auto renders whitespace-normal and no whitespace-nowrap" do
      assigns = %{}
      html = rendered_to_string(~H|<.table_row>
  <:cell wrap="auto">a</:cell>
</.table_row>|)
      class = cell_class(html)
      assert "whitespace-normal" in tokens(class)
      refute "whitespace-nowrap" in tokens(class)
      refute html =~ ~s(wrap=)
    end

    test "wrap=truncate cuts with an ellipsis" do
      assigns = %{}

      html =
        rendered_to_string(~H|<.table_row>
  <:cell wrap="truncate" title="t">a</:cell>
</.table_row>|)

      class = cell_class(html)
      assert "text-ellipsis" in tokens(class)
      assert "max-w-0" in tokens(class)
      assert html =~ ~s(title="t")
    end

    test "padded=false drops the horizontal and vertical padding" do
      assigns = %{}
      html = rendered_to_string(~H|<.table_row>
  <:cell padded={false}>a</:cell>
</.table_row>|)
      class = cell_class(html)
      refute "px-[var(--tpx,14px)]" in tokens(class)
      refute "py-[var(--td-py,12px)]" in tokens(class)
      refute html =~ "padded"
    end
  end

  describe "table_cell" do
    test "defaults" do
      assigns = %{}
      class = cell_class(rendered_to_string(~H|<.table_cell>a</.table_cell>|))
      assert "whitespace-nowrap" in tokens(class)
      assert "px-[var(--tpx,14px)]" in tokens(class)
    end

    test "wrap=auto and padded=false" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<.table_cell colspan="7" wrap="auto" padded={false}>a</.table_cell>|
        )

      class = cell_class(html)
      assert "whitespace-normal" in tokens(class)
      refute "whitespace-nowrap" in tokens(class)
      refute "px-[var(--tpx,14px)]" in tokens(class)
      refute "py-[var(--td-py,12px)]" in tokens(class)
      assert html =~ ~s(colspan="7")
    end
  end

  describe "table_foot" do
    test "default keeps nowrap and padding" do
      assigns = %{}
      class = cell_class(rendered_to_string(~H|<.table_foot>
  <:cell>t</:cell>
</.table_foot>|))
      assert "whitespace-nowrap" in tokens(class)
      assert "font-semibold" in tokens(class)
      assert "px-[var(--tpx,14px)]" in tokens(class)
    end

    test "wrap=auto and padded=false" do
      assigns = %{}

      html =
        rendered_to_string(~H|<.table_foot>
  <:cell wrap="auto" padded={false}>t</:cell>
</.table_foot>|)

      class = cell_class(html)
      assert "whitespace-normal" in tokens(class)
      refute "whitespace-nowrap" in tokens(class)
      refute "px-[var(--tpx,14px)]" in tokens(class)
    end
  end

  describe "table_detail_row and table_empty" do
    test "detail row: nowrap by default, wrap=auto wraps" do
      assigns = %{}

      default =
        rendered_to_string(~H|<.table_detail_row row_id="r">x</.table_detail_row>|)

      assert "whitespace-nowrap" in tokens(cell_class(default))

      auto =
        rendered_to_string(~H|<.table_detail_row row_id="r" wrap="auto">x</.table_detail_row>|)

      assert "whitespace-normal" in tokens(cell_class(auto))
      refute "whitespace-nowrap" in tokens(cell_class(auto))
    end

    test "empty: nowrap by default, wrap=auto wraps" do
      assigns = %{}
      default = rendered_to_string(~H|<.table_empty id="e">x</.table_empty>|)
      assert "whitespace-nowrap" in tokens(cell_class(default))

      auto = rendered_to_string(~H|<.table_empty id="e" wrap="auto">x</.table_empty>|)
      assert "whitespace-normal" in tokens(cell_class(auto))
      refute "whitespace-nowrap" in tokens(cell_class(auto))
    end
  end
end
