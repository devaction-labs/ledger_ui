defmodule LedgerUI.Components.MiniCardTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.MiniCard

  test "a panel with an icon box and the label" do
    assigns = %{}
    html = rendered_to_string(~H|<.mini_card icon="file" tone="accent" label="Novo pedido" />|)
    assert html =~ "lu-panel"
    assert html =~ ~s(class="lu-ic acc")
    assert html =~ "Novo pedido"
    refute html =~ "arrow-up-right"
  end

  test "a link has an arrow" do
    assigns = %{}
    html = rendered_to_string(~H|<.mini_card label="x" href="/x" />|)
    assert html =~ ~s(<a)
    assert html =~ "arrow-up-right"
  end

  test "a figure puts the label over the value" do
    assigns = %{}
    html = rendered_to_string(~H|<.mini_card label="A receber" value="R$ 41,2 mil" />|)
    assert html =~ ~s(class="lu-xs lu-muted">A receber)
    assert html =~ "R$ 41,2 mil"
  end

  test "card surface" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.mini_card surface="card" icon="file" tone="success" label="Receber">
  <span>Pix</span>
</.mini_card>|)

    assert html =~ "lu-cv default"
    assert html =~ "c-success v-soft sh-rounded"
    assert html =~ "<span>Pix</span>"
  end
end
