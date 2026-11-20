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
end
