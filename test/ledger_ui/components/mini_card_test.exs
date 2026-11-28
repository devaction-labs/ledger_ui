defmodule LedgerUI.Components.MiniCardTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.MiniCard

  test "a panel with an icon box and the label" do
    assigns = %{}
    html = rendered_to_string(~H|<.mini_card icon="file" tone="accent" label="Novo pedido" />|)
    assert html =~ "rounded-[18px] border border-line bg-panel"
    assert html =~ ~s(data-part="icon-box")
    assert html =~ "bg-accent-soft text-accent-content"
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
    assert html =~ ~s(data-part="mini-card-label" class="text-xs/4 text-muted">A receber)
    assert html =~ "font-mono"
    assert html =~ "R$ 41,2 mil"
  end

  test "card surface" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.mini_card surface="card" icon="file" tone="success" label="Receber">
  <span>Pix</span>
</.mini_card>|)

    assert html =~ "rounded-[18px] border border-line bg-panel"
    assert html =~ "[--c:var(--lu-pos)]"
    assert html =~ "rounded-[28%]"
    assert html =~ "<span>Pix</span>"
  end
end
