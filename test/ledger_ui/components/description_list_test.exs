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

    assert html =~ ~s(class="lu-dl2")
    assert html =~ "--cols:3"
    assert html =~ "<dt>CNPJ</dt>"
    assert html =~ ~s(class="mono")
    assert html =~ "Feira"
  end

  test "inline layout and empty values" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.description_list layout="inline" empty="n/a"><:item label="x" /></.description_list>|
      )

    assert html =~ "lu-dl2 inline"
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
    assert html =~ ~s(class="wc")
  end
end
