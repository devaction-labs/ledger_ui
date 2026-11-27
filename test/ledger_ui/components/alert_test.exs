defmodule LedgerUI.Components.AlertTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Alert
  import LedgerUI.Components.Icon

  test "colour, variant, shape and accent become utilities" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.alert color="warning" variant="soft" shape="pill" accent="left">x</.alert>|
      )

    assert html =~ ~s(data-part="alert")
    assert html =~ "[--c:var(--lu-warn)]"
    assert html =~ "bg-(--c-soft)"
    assert html =~ "rounded-full"
    assert html =~ "shadow-[inset_3px_0_0_var(--c)]"
    assert html =~ ~s(role="alert")
    refute html =~ "lu-al"
  end

  test "title and description draw the two lines; the quiet ink is for tinted variants" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.alert color="info" variant="soft" title="Heads up" description="Details" />|
      )

    assert html =~ ~s(data-part="alert-title">Heads up</b>)
    assert html =~ ~s(data-part="alert-description")
    assert html =~ "text-ink-2"

    solid =
      rendered_to_string(~H|<.alert color="info" variant="solid" title="T" description="D" />|)

    refute solid =~ "text-ink-2"
  end

  test "icon, action and dismiss button" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.alert id="a1" dismissible on_dismiss="hide" close_label="Fechar">
        <:icon boxed><.icon name="info" /></:icon>
        body
        <:action><button>Go</button></:action>
      </.alert>
      """)

    assert html =~ ~s(data-part="alert-icon")
    assert html =~ ~s(aria-label="Fechar")
    assert html =~ ~s(data-part="alert-close")
    assert html =~ "hide"
    assert html =~ "Go"
  end

  test "the canvas variant tints the icon with the colour" do
    assigns = %{}

    assert rendered_to_string(~H|<.alert color="error">x</.alert>|) =~
             "[&amp;&gt;svg]:text-(--c-ink)"
  end

  test "closed alert is hidden and dismiss_alert/0 hides the closest alert" do
    assigns = %{}
    assert rendered_to_string(~H|<.alert open={false}>x</.alert>|) =~ "hidden"

    assert %Phoenix.LiveView.JS{
             ops: [["hide", %{to: %{closest: "[data-part=alert]"}}]]
           } = dismiss_alert()
  end

  test "a nil colour and variant leave the bare box" do
    assigns = %{}
    html = rendered_to_string(~H|<.alert color={nil} variant={nil}>x</.alert>|)
    assert html =~ "border-transparent"
    refute html =~ "[--c:"
    refute html =~ "bg-(--c"
  end

  test "loop plays the entering loop; without it there is no animation" do
    assigns = %{}

    assert rendered_to_string(~H|<.alert loop>x</.alert>|) =~
             "animate-[mo-alin_6s_cubic-bezier(.2,.8,.2,1)_infinite]"

    refute rendered_to_string(~H|<.alert>x</.alert>|) =~ "mo-alin"
  end

  describe "inner block with a title or description" do
    test "a long text goes inside alert-text, after the title, in the quiet ink" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert color="info" variant="soft" title="Contratos da licitação">
          Um texto bem mais longo que o título.
        </.alert>
        """)

      [_, text] = String.split(html, ~s(data-part="alert-text"), parts: 2)
      [inside, after_text] = String.split(text, "</div>\n  </div>", parts: 2)

      assert inside =~ ~s(data-part="alert-title">Contratos da licitação</b>)
      assert inside =~ ~s(data-part="alert-body" class="text-ink-2")
      assert inside =~ "Um texto bem mais longo"
      refute after_text =~ "Um texto bem mais longo"

      {title_at, _} = :binary.match(html, "alert-title")
      {body_at, _} = :binary.match(html, "Um texto bem")
      assert title_at < body_at
    end

    test "markup goes below the title too, and the solid variant keeps its ink" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert color="warning" variant="solid" title="Datas sugeridas">
          <ul>
            <li>10/01</li>
          </ul>
          <div class="mt-2 flex gap-2"><button>Aplicar</button></div>
          <:action><button>Fechar</button></:action>
        </.alert>
        """)

      [text, rest] = String.split(html, "    </div>\n  </div>", parts: 2)
      assert text =~ "<li>10/01</li>"
      assert text =~ "Aplicar"
      refute text =~ "Fechar"
      assert rest =~ "Fechar"
      refute html =~ "text-ink-2"
    end

    test "with only an :action slot there is no empty body" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert title="T" description="D">
          <:action>go</:action>
        </.alert>
        """)

      refute html =~ "alert-body"
    end
  end

  describe "html without an inner block over a title/description is unchanged" do
    test "text only: the inner block is a sibling of nothing, no alert-text" do
      assigns = %{}
      html = rendered_to_string(~H|<.alert color="info" variant="soft">só texto</.alert>|)

      refute html =~ "alert-text"
      refute html =~ "alert-body"
      assert html =~ ~r|\n\s+só texto\n|
    end

    test "title and description: only the two lines in alert-text" do
      assigns = %{}

      html =
        rendered_to_string(~H|<.alert color="info" variant="soft" title="T" description="D" />|)

      assert html =~
               ~s(<b data-part="alert-title">T</b><span data-part="alert-description" class="text-ink-2">D</span>\n  </div>)

      refute html =~ "alert-body"
    end
  end
end
