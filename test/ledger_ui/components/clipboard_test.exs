defmodule LedgerUI.Components.ClipboardTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Clipboard

  test "button copies a value" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.clipboard id="c" value="LDG-1" icon color="neutral" variant="soft" size="sm">Copiar</.clipboard>|
      )

    # the soft neutral small button of `button/1`
    assert html =~ "[--c:var(--lu-ink)]"
    assert html =~ "bg-(--c-soft)"
    assert html =~ "h-8"
    refute html =~ ~r/class="(?:[^"]*\s)?lu-/
    assert html =~ ~s(data-lu-copy="LDG-1")
    assert html =~ ~s(phx-hook="LedgerUI.Clipboard")
    assert html =~ ~s(data-icon="copy")
    assert html =~ ~r/<span data-part="clipboard-label">\s*Copiar\s*<\/span>/
    assert html =~ ~s(data-lu-toast="Text Copied")
  end

  test "locale, toast and error toast" do
    assigns = %{}
    html = rendered_to_string(~H|<.clipboard id="c" value="x" locale="pt_BR" />|)
    assert html =~ "Copiar"
    assert html =~ ~s(data-lu-toast="Texto copiado")
    assert html =~ ~s(data-lu-error="Erro ao copiar")
    html = rendered_to_string(~H|<.clipboard id="c" value="x" toast={nil} />|)
    refute html =~ "data-lu-toast"
    refute html =~ "data-lu-error"
    html = rendered_to_string(~H|<.clipboard id="c" value="x" toast="ok" error_toast="no" />|)
    assert html =~ ~s(data-lu-toast="ok")
    assert html =~ ~s(data-lu-error="no")
  end

  test "from selector, copied label, on_copy and target" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.clipboard id="c" from="#cmd" copied_label="Copiado" on_copy="copied" target="#x" />|
      )

    assert html =~ ~s(data-lu-copy-from="#cmd")
    refute html =~ "data-lu-copy="
    assert html =~ ~s(data-lu-copied-label="Copiado")
    assert html =~ ~s(data-lu-on-copy="copied")
    assert html =~ ~s(data-lu-target="#x")

    assigns = %{js: Phoenix.LiveView.JS.push("copied")}
    html = rendered_to_string(~H|<.clipboard id="c" value="x" on_copy={@js} />|)
    assert html =~ "data-lu-on-copy-js="
  end

  test "the hook gets the class list of the copied state" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.clipboard id="c" value="x" color="neutral" variant="outline" size="sm" class="ml-auto" />|
      )

    [copied] = Regex.run(~r/data-lu-copied-class="([^"]*)"/, html, capture: :all_but_first)
    assert copied =~ "[--c:var(--lu-pos)]"
    assert copied =~ "bg-(--c-soft)"
    assert copied =~ "ml-auto"
    refute copied =~ "[--c:var(--lu-ink)]"
  end

  test "icon_only has no label" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.clipboard id="c" value="x" icon_only variant="ghost" aria-label="Copiar" />|
      )

    assert html =~ ~s(aria-label="Copiar")
    refute html =~ "clipboard-label"
    assert html =~ "bg-transparent"
  end

  test "copied state" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.clipboard id="c" value="x" size="sm" copied icon copied_label="Copiado" />|
      )

    assert html =~ "[--c:var(--lu-pos)]"
    assert html =~ "bg-(--c-soft)"
    assert html =~ "h-8"
    assert html =~ ~s(data-icon="check")
    assert html =~ "Copiado"
    refute html =~ "data-lu-copy"
  end

  test "clipboard_input" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.clipboard_input id="key" value="sk" field_label="Chave" leading_icon="key" readonly />|
      )

    assert html =~ ~s(<label)
    assert html =~ ~s(data-part="label")
    assert html =~ "Chave"
    assert html =~ ~s(data-part="clipboard-input-addon")
    assert html =~ ~s(<input id="key")
    assert html =~ "readonly"
    assert html =~ ~s(data-lu-copy-from="#key")
    assert html =~ ~s(id="key-copy")
    assert html =~ "Copy"
  end
end
