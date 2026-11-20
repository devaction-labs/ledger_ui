defmodule LedgerUI.Components.TextareaTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Textarea

  test "renders a textarea in its frame" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.textarea name="bio" value="Ola" rows={5} placeholder="Escreva" />|)

    assert html =~ ~s(data-part="textarea")
    assert html =~ "border-line-strong"
    assert html =~ ~r/<textarea[^>]*name="bio"/
    assert html =~ ~s(rows="5")
    assert html =~ ~s(placeholder="Escreva")
    assert html =~ ">\nOla</textarea>"
    refute html =~ "phx-hook"
  end

  test "variant, size and state utilities; the focus ring is a focus-within utility" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.textarea name="a" variant="filled" size="lg" state="error" />
      """)

    assert html =~ "bg-sunken"
    assert html =~ "border-neg"
    assert html =~ "px-3.5 py-3 text-[15px]"
    assert html =~ "focus-within:border-neg"
    refute html =~ "phx-focus"

    html =
      rendered_to_string(~H|<.textarea name="a" variant="plain" size="sm" state="success" />|)

    assert html =~ "border-pos"
    assert html =~ "px-2.5 py-2 text-[13px]"
    assert html =~ "min-h-16"
  end

  test "label, hint, help and errors" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.textarea name="obs" label="Observações" label_hint="opcional" help="Ate 6 linhas" />
      """)

    assert html =~ ~s(<div class="flex min-w-0 flex-col gap-1.5" data-part="field")
    assert html =~ "Observações"
    assert html =~ "opcional"
    assert html =~ "Ate 6 linhas"
    assert html =~ ~s(aria-labelledby="obs-label")

    html = rendered_to_string(~H|<.textarea name="obs" errors={["Informe"]} />|)
    assert html =~ "Informe"
    assert html =~ "border-neg"
    assert html =~ ~s(aria-invalid="true")
  end

  test "counter with maxlength: text, warn and over" do
    assigns = %{}

    html = rendered_to_string(~H|<.textarea name="n" value="abc" maxlength={200} counter />|)
    assert html =~ ~s(phx-hook="LedgerUI.Textarea")
    assert html =~ ~s(data-lu-counter="n-cnt")
    assert html =~ ~s(data-lu-max="200")
    assert html =~ ~r/<span id="n-cnt" data-part="textarea-counter"[^>]*>3 \/ 200<\/span>/
    assert html =~ "items-baseline"

    v = String.duplicate("a", 184)
    assigns = %{v: v}
    html = rendered_to_string(~H|<.textarea name="n" value={@v} maxlength={200} counter />|)
    assert html =~ ~s(data-state="warn")
    assert html =~ "184 / 200"

    v = String.duplicate("a", 214)
    assigns = %{v: v}
    html = rendered_to_string(~H|<.textarea name="n" value={@v} maxlength={200} counter />|)
    assert html =~ ~s(data-state="over")
  end

  test "counter format, min_length and start alignment" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.textarea name="n" value="abc" maxlength={300} counter counter_format="%{count} de %{max}" />
      """)

    assert html =~ "3 de 300"

    html = rendered_to_string(~H|<.textarea name="w" value="Curto" counter min_length={20} />|)
    assert html =~ "5 / 20 mín."

    html =
      rendered_to_string(~H|<.textarea name="w" value="Curto" counter counter_align="start" />|)

    assert html =~ ~s(data-part="textarea-counter-row")
    refute html =~ "ml-auto"
  end

  test "autogrow, resizable and tokens" do
    assigns = %{}

    html = rendered_to_string(~H|<.textarea name="g" autogrow max_rows={6} />|)
    assert html =~ ~s(data-lu-autogrow="true")
    assert html =~ ~s(data-lu-max-rows="6")
    assert html =~ ~r/class="[^"]*resize-none overflow-hidden/

    html = rendered_to_string(~H|<.textarea name="r" resizable />|)
    assert html =~ ~r/class="[^"]*resize-y/

    html = rendered_to_string(~H|<.textarea name="t" tokens value="Ola {{cliente}}, ok {{x}}" />|)
    assert html =~ ~s(data-lu-tokens="true")
    assert html =~ "data-lu-mirror"
    assert html =~ "<code>{{cliente}}</code>"
    assert html =~ "<code>{{x}}</code>"
    assert html =~ ~r/class="[^"]*text-transparent caret-ink/
  end

  test "header and footer slots become bars" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.textarea name="p">
        <:header><b>Titulo</b></:header>
        <:footer><span>tools</span></:footer>
      </.textarea>
      """)

    assert html =~ ~s(data-part="textarea-header")
    assert html =~ ~s(data-part="textarea-footer")
    assert html =~ "tools"
  end

  test "field supplies id and name; hook needs an id" do
    form = to_form(%{"note" => "x"}, as: :m)
    assigns = %{f: form[:note]}
    html = rendered_to_string(~H|<.textarea field={@f} counter />|)
    assert html =~ ~s(id="m_note")
    assert html =~ ~s(name="m[note]")

    assigns = %{}

    assert_raise ArgumentError, fn ->
      rendered_to_string(~H|<.textarea counter />|)
    end
  end

  test "parts splits text and tokens" do
    assert LedgerUI.Components.Textarea.parts("a {{b}} c") ==
             [{:text, "a "}, {:token, "{{b}}"}, {:text, " c"}]
  end

  test "no wrapper without caption; sizes and the chrome come from classes" do
    assigns = %{}
    html = rendered_to_string(~H|<.textarea name="n" size="md" />|)
    assert html =~ ~s(data-part="textarea")
    refute html =~ ~s(data-part="field")
    refute html =~ "style="
    html = rendered_to_string(~H|<.textarea name="n" label="Obs" />|)
    assert html =~ ~s(data-part="field")
    assert html =~ ~s(data-part="textarea")
  end

  test "is the design's 84px field by default (min-height, no rows)" do
    assigns = %{}

    html = rendered_to_string(~H|<.textarea name="n" />|)
    assert html =~ "min-h-[84px]"
    refute html =~ "rows="
    assert rendered_to_string(~H|<.textarea name="n" rows={5} />|) =~ ~s(rows="5")
  end
end
