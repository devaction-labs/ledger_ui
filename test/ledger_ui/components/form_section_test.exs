defmodule LedgerUI.Components.FormSectionTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.FormSection

  test "stacked section: title, description, two columns and a divider" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form_section title="Contato" description="Usado na NF-e">fields</.form_section>
      """)

    assert html =~ ~s(class="lu-fsec")
    assert html =~ "<b>Contato</b>"
    assert html =~ "Usado na NF-e"
    assert html =~ ~s(style="--cols:2")
    assert html =~ "border-bottom"
    assert html =~ "fields"
  end

  test "aside layout has no divider by default; columns and divider overrides" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.form_section title="T" layout="aside" columns={3}>x</.form_section>|
      )

    assert html =~ ~s(class="lu-fsec aside")
    assert html =~ ~s(style="--cols:3")
    refute html =~ "border-bottom"

    html = rendered_to_string(~H|<.form_section title="T" divider={false}>x</.form_section>|)
    refute html =~ "border-bottom"

    html =
      rendered_to_string(~H|<.form_section title="T" layout="aside" divider>x</.form_section>|)

    assert html =~ "border-bottom"
  end

  test "action slot sits next to the title" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.form_section title="T"><:action><a href="#">Editar</a></:action>x</.form_section>
      """)

    assert html =~ ~s(data-part="action")
    assert html =~ "Editar"
  end

  test "passes id, class and rest attributes" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.form_section title="T" id="s1" class="mt" data-x="1">x</.form_section>|
      )

    assert html =~ ~s(id="s1")
    assert html =~ "lu-fsec mt"
    assert html =~ ~s(data-x="1")
  end
end
