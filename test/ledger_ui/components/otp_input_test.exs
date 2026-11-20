defmodule LedgerUI.Components.OtpInputTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.OtpInput

  defp count(html, pattern), do: length(String.split(html, pattern)) - 1

  test "renders length boxes, a group role and a hidden input" do
    assigns = %{}
    html = rendered_to_string(~H|<.otp_input name="code" />|)
    assert count(html, "data-lu-otp-box") == 6
    assert html =~ ~s(role="group")
    assert html =~ ~s(aria-label="One-time code")
    assert html =~ ~s(phx-hook="LedgerUI.Otp")
    assert html =~ ~s(id="code")
    assert html =~ ~s(<input type="hidden" name="code" value="" data-lu-otp-value)
    assert html =~ ~s(autocomplete="one-time-code")
    assert html =~ ~s(inputmode="numeric")
    assert html =~ ~s(aria-label="Digit 1")
    assert html =~ ~s(aria-label="Digit 6")
    # boxes themselves have no name
    refute html =~ ~r/data-lu-otp-box[^>]*name=/
  end

  test "length, value (string or integer), mode, mask and separator" do
    assigns = %{}

    html = rendered_to_string(~H|<.otp_input name="pin" length={4} value={1234} mask />|)
    assert count(html, "data-lu-otp-box") == 4
    assert html =~ ~s(type="password")
    assert html =~ ~s(data-lu-filled="true")
    assert html =~ ~s(data-lu-value="1234")

    html = rendered_to_string(~H|<.otp_input name="c" value="48291599" />|)
    assert html =~ ~s(data-lu-value="482915")

    html = rendered_to_string(~H|<.otp_input name="i" length={8} mode="alphanumeric" />|)
    assert html =~ ~s(data-lu-mode="alphanumeric")
    assert html =~ ~s(inputmode="text")

    html = rendered_to_string(~H|<.otp_input name="s" separator={3} />|)
    assert count(html, ~s(class="dash")) == 1
    [before, _] = String.split(html, ~s(class="dash"))
    assert count(before, "data-lu-otp-box") == 3

    html = rendered_to_string(~H|<.otp_input name="s" length={8} separator={[2, 4, 4, 9]} />|)
    assert count(html, ~s(class="dash")) == 2
  end

  test "size, state, disabled" do
    assigns = %{}
    html = rendered_to_string(~H|<.otp_input name="c" size="lg" state="success" help="ok" />|)
    assert html =~ ~s(class="lu-otp2 lg ok")
    assert html =~ ~s(data-icon="check-circle")

    html = rendered_to_string(~H|<.otp_input name="c" size="sm" errors={["Invalido"]} />|)
    assert html =~ ~s(class="lu-otp2 sm err")
    assert html =~ ~s(role="alert")
    assert html =~ ~s(aria-invalid="true")

    html = rendered_to_string(~H|<.otp_input name="c" disabled />|)
    assert html =~ "lu-otp2 dis"
    assert html =~ "disabled"
  end

  test "label names the group; custom aria_label and digit_label" do
    assigns = %{}
    html = rendered_to_string(~H|<.otp_input name="c" label="Codigo" />|)
    assert html =~ ~s(aria-labelledby="c-label")
    refute html =~ "One-time code"

    html =
      rendered_to_string(~H|<.otp_input name="c" aria_label="Codigo" digit_label="Digito" />|)

    assert html =~ ~s(aria-label="Codigo")
    assert html =~ ~s(aria-label="Digito 1")
  end

  test "on_complete as an event or JS, target, autofocus" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.otp_input name="c" on_complete="verify" target="#form" autofocus />|
      )

    assert html =~ ~s(data-lu-on-complete="verify")
    assert html =~ ~s(data-lu-target="#form")
    assert html =~ ~s(data-lu-autofocus="true")

    assigns = %{js: Phoenix.LiveView.JS.push("verify")}
    html = rendered_to_string(~H|<.otp_input name="c" on_complete={@js} />|)
    assert html =~ "data-lu-on-complete-js="
    assert html =~ "verify"
  end

  test "field supplies id, name, value and errors" do
    form = to_form(%{"code" => "12"}, as: :v, errors: [code: {"wrong", []}], action: :validate)
    assigns = %{f: form[:code]}
    html = rendered_to_string(~H|<.otp_input field={@f} />|)
    assert html =~ ~s(id="v_code")
    assert html =~ ~s(name="v[code]")
    assert html =~ ~s(data-lu-value="12")
    assert html =~ "wrong"
  end

  test "needs an id" do
    assigns = %{}
    assert_raise ArgumentError, fn -> rendered_to_string(~H|<.otp_input />|) end
  end

  test "no wrapper without caption; an explicit md size is a class" do
    assigns = %{}
    html = rendered_to_string(~H|<.otp_input name="c" size="md" />|)
    assert html =~ ~s(class="lu-otp2 md")
    refute html =~ "lu-field"
    html = rendered_to_string(~H|<.otp_input name="c" label="Codigo" />|)
    assert html =~ "lu-field"
    assert html =~ ~s(class="lu-otp2")
  end

  test "autofocus marks the first empty box as on" do
    assigns = %{}

    html = rendered_to_string(~H|<.otp_input id="o" name="o" length={4} value="12" autofocus />|)
    assert [_, _] = Regex.scan(~r/data-lu-filled="true"/, html)
    assert html =~ ~r/<i class="on">\s*<input[^>]*Digit 3/
    refute html =~ ~r/<i class="on">\s*<input[^>]*Digit 4/
  end
end
