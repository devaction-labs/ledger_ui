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

    assert html =~ ~s(data-part="form-section")
    assert html =~ "Contato</b>"
    assert html =~ "Usado na NF-e"
    assert html =~ "grid-cols-2"
    assert html =~ "border-b border-line pb-[18px]"
    assert html =~ "fields"
  end

  test "aside layout has no divider by default; columns and divider overrides" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.form_section title="T" layout="aside" columns={3}>x</.form_section>|
      )

    assert html =~ "grid-cols-[220px_1fr]"
    assert html =~ "grid-cols-3"
    refute html =~ "border-b"

    html = rendered_to_string(~H|<.form_section title="T" divider={false}>x</.form_section>|)
    refute html =~ "border-b"

    html =
      rendered_to_string(~H|<.form_section title="T" layout="aside" divider>x</.form_section>|)

    assert html =~ "border-b"
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
    assert html =~ ~r/class="[^"]* mt"/
    assert html =~ ~s(data-x="1")
  end
end
