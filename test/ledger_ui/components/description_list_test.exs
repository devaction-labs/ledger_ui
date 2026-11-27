defmodule LedgerUI.Components.DescriptionListTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.DescriptionList

  test "pairs in a grid with cols" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.description_list cols={3}>
        <:item label="CNPJ" mono>12.345</:item>
        <:item label="Cidade">Feira</:item>
      </.description_list>
      """)

    assert html =~ "grid-cols-[repeat(3,minmax(0,1fr))]"
    assert html =~ "CNPJ"
    assert html =~ "font-mono"
    assert html =~ "Feira"
  end

  test "inline layout and empty values" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.description_list layout="inline" empty="n/a"><:item label="x" /></.description_list>|
      )

    assert html =~ "flex flex-row justify-between"
    assert html =~ "border-b border-line"
    assert html =~ "n/a"

    assert rendered_to_string(~H|<.description_list><:item label="x" /></.description_list>|) =~
             "—"
  end

  test "item id, class, style and wrapper attrs" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.description_list>
        <:item
          label="E-mail"
          id="mail"
          class="c"
          style="overflow-wrap:anywhere"
          wrapper_id="w"
          wrapper_class="wc"
        >
          a@b
        </:item>
      </.description_list>
      """)

    assert html =~ ~s(id="mail")
    assert html =~ "overflow-wrap:anywhere"
    assert html =~ ~s(id="w")
    assert html =~ "wc"
    assert html =~ ~s(class="m-0 text-[14px] leading-5 font-medium c")
  end

  describe "divider" do
    defp item_classes(html) do
      html
      |> LazyHTML.from_fragment()
      |> LazyHTML.query("[data-part=description-list-item]")
      |> Enum.map(fn item -> item |> LazyHTML.attribute("class") |> hd() |> String.split() end)
    end

    test "the default is unchanged" do
      assigns = %{}

      default =
        rendered_to_string(~H|<.description_list layout="inline">
  <:item label="a">1</:item>
</.description_list>|)

      all =
        rendered_to_string(~H|<.description_list layout="inline" divider="all">
  <:item label="a">1</:item>
</.description_list>|)

      assert default == all
      assert default =~ "gap-y-[14px]"
      assert default =~ "border-b border-line pb-2.5"
    end

    test "between: no line and no bottom padding on the last item (one column)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.description_list layout="inline" cols={1} divider="between">
          <:item label="a">1</:item>
          <:item label="b">2</:item>
          <:item label="c">3</:item>
        </.description_list>
        """)

      assert html =~ "gap-y-0"
      refute html =~ "gap-y-[14px]"
      [a, b, c] = item_classes(html)
      assert "border-b" in a and "pt-0" in a and "pb-2.5" in a
      assert "border-b" in b and "pt-2.5" in b and "pb-2.5" in b
      refute "border-b" in c
      assert "pb-0" in c and "pt-2.5" in c
      refute "pb-2.5" in c
    end

    test "between with cols: the last item of each column" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.description_list layout="inline" cols={2} divider="between">
          <:item :for={n <- 1..5} label={"i#{n}"}>{n}</:item>
        </.description_list>
        """)

      classes = item_classes(html)
      assert Enum.map(classes, &("border-b" in &1)) == [true, true, true, false, false]
      assert Enum.map(classes, &("pb-0" in &1)) == [false, false, false, true, true]
      assert Enum.map(classes, &("pt-0" in &1)) == [true, true, false, false, false]
    end

    test "none: symmetric spacing without lines" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.description_list layout="inline" cols={1} divider="none">
          <:item label="a">1</:item>
          <:item label="b">2</:item>
        </.description_list>
        """)

      refute html =~ "border-b"
      assert html =~ "gap-y-0"
    end

    test "stacked ignores divider" do
      assigns = %{}

      with_divider =
        rendered_to_string(~H|<.description_list divider="between">
  <:item label="a">1</:item>
</.description_list>|)

      plain =
        rendered_to_string(~H|<.description_list>
  <:item label="a">1</:item>
</.description_list>|)

      assert with_divider == plain
    end
  end
end
