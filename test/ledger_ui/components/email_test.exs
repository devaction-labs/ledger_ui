defmodule LedgerUI.Components.EmailTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Email

  test "whole document with action, address and dark css" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.email_layout subject="S" title="T" preheader="pre" brand="Acme" eyebrow="E">
  <:body>
    <.email_p>hi</.email_p>
  </:body><:action href="https://x.test/c">Go</:action><:note>n</:note><:footer>f</:footer>
</.email_layout>|
      )

    assert html =~ "<!DOCTYPE html>"
    assert html =~ "<title>S</title>"
    assert html =~ "prefers-color-scheme: dark"
    assert html =~ "https://x.test/c"
    assert html =~ "copy and paste"
    assert html =~ "Go →"
  end

  test "fixed theme has no dark block; ink button; alt_text nil" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.email_layout subject="S" title="T" theme={:dark} button="ink" alt_text={nil}>
  <:body>b</:body><:action href="/c">Go</:action>
</.email_layout>|
      )

    refute html =~ "prefers-color-scheme: dark)"
    refute html =~ "copy and paste"
    refute html =~ "Go →"
  end

  test "code, facts, steps" do
    assigns = %{}

    assert rendered_to_string(~H|<.email_code value="4829" />|) |> String.split("<td") |> length() ==
             5

    facts =
      rendered_to_string(
        ~H|<.email_facts rows={[{"A", "1"}, {"Total", "9", :total}]} header={{"H1", "H2"}} variant="table" />|
      )

    assert facts =~ "Total"
    assert facts =~ "H1"
    steps = rendered_to_string(~H|<.email_steps steps={[{"Paid", true}, {"Sent", false}]} />|)
    assert steps =~ "✓"
  end

  test "variant preview is the canvas fragment, not a mail document" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.email_layout variant="preview" subject="S" title="Seu resumo" brand="Ledgerly">
  <:body>
    <p>hi</p>
  </:body>
  <:action href="#">Abrir</:action>
  <:footer>foot</:footer>
</.email_layout>|
      )

    refute html =~ "<table"
    refute html =~ "<!DOCTYPE"
    assert html =~ "lu-panel"
    assert html =~ ~s(<button class="lu-btn primary lg" type="button">Abrir</button>)
    assert html =~ "lu-sep"
    assert html =~ "Ledgerly"
  end
end
