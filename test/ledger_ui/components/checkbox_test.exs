defmodule LedgerUI.Components.CheckboxTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Checkbox

  describe "checkbox" do
    test "classes follow color, size, shape, filled and disabled" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox color="primary" size="lg" shape="circle" filled disabled label="Ok" />
        """)

      # the colour enters as local variables, the size/shape/state as one utility each
      assert html =~ "[--c:var(--color-accent)]"
      assert html =~ "size-[22px]"
      assert html =~ "rounded-full"
      assert html =~ "bg-(--c-soft)" or html =~ "bg-sunken"
      assert html =~ "cursor-not-allowed text-muted"
      refute html =~ "lu-check"
      # the disabled box is not faded (opacity), only sunken
      refute html =~ "opacity-"
      assert html =~ ~r/<input[^>]*disabled/
      assert html =~ ~s(data-part="checkbox-text")
    end

    test "inside a form it sends unchecked_value through a hidden input" do
      assigns = %{}
      html = rendered_to_string(~H|<.checkbox name="terms" label="I agree" checked />|)
      assert html =~ ~s(<input type="hidden" name="terms" value="false")

      assert html =~
               ~r/<input data-part="checkbox-input" type="checkbox" name="terms" value="true" checked/

      html =
        rendered_to_string(
          ~H|<.checkbox name="terms" hidden_input={false} unchecked_value="0" />|
        )

      refute html =~ ~s(type="hidden")
    end

    test "field fills id, name and checked, and shows errors once used" do
      form =
        to_form(%{"remember" => "true"}, as: "f", errors: [remember: {"must be accepted", []}])

      assigns = %{form: form}
      html = rendered_to_string(~H|<.checkbox field={@form[:remember]} label="Remember me" />|)
      assert html =~ ~s(id="f_remember")
      assert html =~ ~s(name="f[remember]")
      assert html =~ "checked"
      assert html =~ "must be accepted"
      assert html =~ ~s(data-part="error")
      assert html =~ ~s(role="alert")

      form = to_form(%{"remember" => "false"}, as: "f")
      assigns = %{form: form}
      html = rendered_to_string(~H|<.checkbox field={@form[:remember]} />|)
      refute html =~ ~r/<input[^>]*type="checkbox"[^>]* checked[ >]/
    end

    test "checked_value compares against the value" do
      assigns = %{}
      html = rendered_to_string(~H|<.checkbox name="x" value="yes" checked_value="yes" />|)
      assert html =~ ~r/value="yes" checked/
    end

    test "indeterminate draws data-ind and attaches the hook with an id" do
      assigns = %{}
      html = rendered_to_string(~H|<.checkbox name="all" label="Select all" indeterminate />|)
      assert html =~ ~s(data-ind="1")
      assert html =~ ~s(phx-hook="LedgerUI.Indeterminate")
      assert html =~ ~s(id="all")

      html = rendered_to_string(~H|<.checkbox label="Select all" indeterminate />|)
      assert html =~ ~r/id="cb-\d+"/

      html = rendered_to_string(~H|<.checkbox name="x" />|)
      refute html =~ "phx-hook"

      html = rendered_to_string(~H|<.checkbox name="x" indeterminate={false} />|)
      assert html =~ "phx-hook"
      refute html =~ "data-ind"
    end

    test "description, inner block, label_class and wrapper" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox name="p" description="Billed yearly" label_class="strong" wrapper_class="grid">
          Pro plan
        </.checkbox>
        """)

      assert html =~ "Billed yearly</small>"
      assert html =~ ~s(data-part="checkbox-description")
      assert html =~ ~r/data-part="checkbox-text" class="[^"]*strong"/
      assert html =~ ~r/<div class="[^"]*grid"/
      assert html =~ "Pro plan"
    end

    test "outline variant draws a border and extra attributes reach the input" do
      assigns = %{}

      html =
        rendered_to_string(~H|<.checkbox variant="outline" form="f1" required phx-click="t" />|)

      assert html =~ "rounded-md border border-line-strong px-3 py-2"
      assert html =~ ~s(form="f1")
      assert html =~ "required"
      assert html =~ ~s(phx-click="t")
    end
  end

  describe "checkbox_group" do
    test "one checkbox per option, name[] and an empty entry first" do
      form = to_form(%{"roles" => ["admin"]}, as: "f")
      assigns = %{form: form}

      html =
        rendered_to_string(~H"""
        <.checkbox_group
          field={@form[:roles]}
          label="Roles"
          options={[{"Admin", "admin"}, {"Editor", "editor"}]}
        />
        """)

      assert html =~ ~s(<input type="hidden" name="f[roles][]" value="")
      assert html =~ ~r/name="f\[roles\]\[\]" value="admin" checked/
      assert html =~ ~r/name="f\[roles\]\[\]" value="editor"/
      assert html =~ ~s(role="group")
      assert length(Regex.scan(~r/data-part="checkbox"/, html)) == 2
    end

    test "chip variant keeps a real checkbox, the tick and the count" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox_group
          name="channels"
          variant="chip"
          color="primary"
          value={["email"]}
          options={[%{label: "E-mail", value: "email", count: 3}, %{label: "WhatsApp", value: "whatsapp"}]}
        />
        """)

      # the chosen look follows the input (`has-checked:`), no hook mirrors it
      refute html =~ "LedgerUI.ChoiceGroup"
      assert html =~ "has-checked:bg-(--c-soft)"
      assert html =~ "[--c:var(--color-accent)]"
      assert html =~ ~r/<input[^>]*type="checkbox"[^>]*name="channels\[\]"/
      assert html =~ "✓"
      assert html =~ ~r/>\s*3\s*</
    end

    test "card variant and the checkbox slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox_group
          name="x"
          variant="card"
          options={[%{label: "Emitir", value: "1", description: "Ao confirmar"}]}
        />
        """)

      assert html =~ ~s(data-part="choice")
      assert html =~ "has-checked:border-accent-500"
      assert html =~ "Ao confirmar"
      assert html =~ "rounded-[5px]"

      html =
        rendered_to_string(~H"""
        <.checkbox_group name="roles" value={["admin"]}>
          <:checkbox value="admin" color="primary">Admin</:checkbox>
          <:checkbox value="editor">Editor</:checkbox>
        </.checkbox_group>
        """)

      assert html =~ "Admin"
      assert html =~ "Editor"
      assert html =~ "[--c:var(--color-accent)]"
    end
  end
end
