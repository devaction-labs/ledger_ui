defmodule LedgerUI.Components.FormsLoopTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.{Checkbox, NumberInput, OtpInput, PasswordInput, Pillbox, Select}
  import LedgerUI.Components.{Switch, TagsInput, Textarea}

  defp render(fun, assigns), do: render_component(fun, assigns)

  test "number_input loop: counter keyframe, press on +, no static text" do
    html = render(&number_input/1, %{id: "n", value: 7, steppers: true, loop: true})
    assert html =~ "animate-[lu-numloop_6s_steps(1)_infinite]"
    assert html =~ "animate-[lu-press_6s_infinite]"
    assert html =~ "after:content-[counter(n)]"
    refute html =~ ">7<"
  end

  test "switch loop: track and thumb keyframes, outline variant" do
    assigns = %{}
    html = rendered_to_string(~H|<.switch loop color="primary" />|)
    assert html =~ "animate-[lu-swtrack_3.6s_ease-in-out_infinite]"
    assert html =~ "after:animate-[lu-swthumb_3.6s_cubic-bezier(.3,.7,.4,1)_infinite]"
    assert html =~ "[--tw:36px]"
    html = rendered_to_string(~H|<.switch loop variant="outline" />|)
    assert html =~ "lu-swtrack-o"
  end

  test "checkbox loop draws the tick" do
    assigns = %{}
    html = rendered_to_string(~H|<.checkbox loop color="success" />|)
    assert html =~ "animate-[lu-cbbox_3.6s_ease-in-out_infinite]"
    assert html =~ "after:animate-[lu-cbtick_3.6s_ease-in-out_infinite]"
  end

  test "otp_input loop: digits in sequence, boxes empty" do
    html = render(&otp_input/1, %{id: "o", name: "o", value: "4829", loop: true, length: 4})
    assert html =~ "lu-otpbox_6s_ease-in-out_var(--dl)_infinite"
    assert html =~ "--dl:0.45s"
    assert html =~ ~s(data-part="otp-demo-digit")
    assert html =~ ~s(data-lu-value="")
  end

  test "textarea loop: CSS counter instead of the hook counter" do
    html =
      render(&textarea/1, %{id: "t", counter: true, loop: true, maxlength: 200, value: "abc"})

    assert html =~ "animate-[lu-cntloop_6s_steps(30)_infinite]"
    assert html =~ "--post:&#39; / 200&#39;"
    refute html =~ "data-lu-counter"
  end

  test "tags_input loop: last tag fades in and the text is typed" do
    html =
      render(&tags_input/1, %{id: "g", value: ["a", "b"], loop: true, loop_text: "bahia"})

    assert html =~ "animate-[mo-stg_6s_cubic-bezier(.2,.8,.2,1)_infinite]"
    assert html =~ "--steps:5"
    assert html =~ ~s(data-part="tags-input-typing")
  end

  test "password_input loop swaps dots and text; visible starts as text" do
    html = render(&password_input/1, %{id: "p", value: "abc", loop: true})
    assert html =~ ~s(type="text")
    assert html =~ "animate-[lu-sw-a_5s_ease-in-out_infinite]"
    assert html =~ "•••"
    html = render(&password_input/1, %{id: "p", value: "abc", visible: true})
    assert html =~ ~s(aria-pressed="true")
  end

  test "password_input derives a selector-safe id from a bracketed name" do
    html = render(&password_input/1, %{name: "login[password]"})
    assert html =~ ~s(id="login-password")
    refute html =~ "#login[password]"
  end

  test "password input draws dots at 18px with 3px spacing, eye is 16px" do
    html = render(&password_input/1, %{id: "p"})
    assert html =~ "tracking-[3px]"
    assert html =~ ~s(id="p-eye")
    assert html =~ "size-4"
  end

  test "the create row exists only with create, and has a name" do
    opts = ["a", "b"]
    refute render(&select/1, %{id: "s", options: opts}) =~ "data-lu-create-row"
    html = render(&select/1, %{id: "s", options: opts, create: true, create_label: "Novo"})
    assert html =~ ~r/data-lu-create-row[^>]*>Novo<\/button>/s
    refute render(&pillbox/1, %{id: "pb", options: opts}) =~ "data-lu-create-row"
    assert render(&pillbox/1, %{id: "pb", options: opts, create: true}) =~ "data-lu-create-row"
  end

  test "pillbox removable and chevron can be turned off" do
    base = %{id: "pb", options: ["a"], value: ["a"]}
    assert render(&pillbox/1, base) =~ "select-chip-remove"
    refute render(&pillbox/1, Map.put(base, :removable, false)) =~ "select-chip-remove"
    assert render(&pillbox/1, base) =~ ~s(data-icon="chevron-down")
    refute render(&pillbox/1, Map.put(base, :chevron, false)) =~ ~s(data-icon="chevron-down")
  end

  test "listbox: static list with check, separator, disabled row and hint" do
    html =
      render(&listbox/1, %{
        value: "Pro",
        options: [
          "Pro",
          "Scale",
          {"", [%{label: "Enterprise", hint: "Em breve", disabled: true}]}
        ]
      })

    assert html =~ ~s(role="listbox")
    assert html =~ ~s(aria-selected="true")
    assert html =~ ~s(data-part="listbox-separator")
    assert html =~ ~s(aria-disabled="true")
    assert html =~ "Em breve"
    assert html =~ ~s(data-icon="check")
  end
end
