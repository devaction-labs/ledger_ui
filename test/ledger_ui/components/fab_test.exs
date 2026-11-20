defmodule LedgerUI.Components.FabTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Fab
  import LedgerUI.Components.Icon

  test "canvas fab shows icon and label" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.fab id="n" label="Novo pedido" fixed={false} phx-click="new" />|)

    assert html =~ ~s(class="lu-fabc")
    assert html =~ "Novo pedido"
    assert html =~ ~s(data-icon="sparkles")
    assert html =~ ~s(phx-click="new")
    refute html =~ "style="
  end

  test "fixed by default" do
    assigns = %{}
    html = rendered_to_string(~H|<.fab id="n" label="N" offset={24} />|)
    assert html =~ "position:fixed;z-index:var(--ledger-z-fab,90);right:24px;bottom:24px"
  end

  test "pill classes, state and badge" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.fab
        id="c"
        label="Chat"
        variant="pill"
        fixed={false}
        retract="always"
        color="light"
        position="bottom-left"
        badge={3}
      />
      """)

    assert html =~ "lu-fab2 k-light r-always s-md pos-bl"
    assert html =~ ~s(data-state="collapsed")
    assert html =~ ~s(aria-label="Chat")
    assert html =~ ~s(title="Chat")
    assert html =~ ~s(<span class="badge">3</span>)
    refute html =~ "phx-hook"
  end

  test "retract never and expanded are open; auto uses the hook" do
    assigns = %{}
    never = rendered_to_string(~H|<.fab id="a" label="A" variant="pill" retract="never" />|)
    assert never =~ ~s(data-state="expanded")
    forced = rendered_to_string(~H|<.fab id="a" label="A" variant="pill" expanded />|)
    assert forced =~ ~s(data-state="expanded")

    auto =
      rendered_to_string(
        ~H|<.fab id="a" label="A" variant="pill" retract="auto" retract_after={6000} />|
      )

    assert auto =~ ~s(phx-hook="LedgerUI.Fab")
    assert auto =~ ~s(data-after="6000")
    assert auto =~ "keep-data-state"
  end

  test "slots replace the icon and the label" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.fab id="a" label="A" variant="pill"><:icon><.icon name="plus" size="md" /></:icon>Custom</.fab>
      """)

    assert html =~ ~s(data-icon="plus")
    assert html =~ ~s(<span class="lbl">Custom</span>)
  end

  test "link when navigate is given" do
    assigns = %{}
    html = rendered_to_string(~H|<.fab id="a" label="A" navigate="/x" />|)
    assert html =~ ~s(href="/x")
    refute html =~ "<button"
  end

  test "fab_dial" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.fab_dial id="q" label="Ações" fixed={false} variant="pill" open>
        <:action label="Novo" phx-click="new"><.icon name="user-plus" /></:action>
        <:action label="Ver" navigate="/v"><.icon name="file" /></:action>
      </.fab_dial>
      """)

    assert html =~ ~s(class="lu-dial pill")
    assert html =~ ~s(data-state="open")
    assert html =~ ~s(phx-hook="LedgerUI.FabDial")
    assert html =~ ~s(aria-expanded="true")
    assert html =~ ~s(aria-haspopup="menu")
    assert html =~ ~s(role="menu")
    assert html =~ ~s(phx-click="new")
    assert html =~ ~s(href="/v")
    assert length(String.split(html, ~s(role="menuitem"))) == 3
    assert html =~ "<span>Novo</span>"

    closed =
      rendered_to_string(~H"""
      <.fab_dial id="q" label="Ações" position="top-left">
        <:action label="A"><.icon name="file" /></:action>
      </.fab_dial>
      """)

    assert closed =~ ~s(data-state="closed")
    assert closed =~ "left:18px"
    assert closed =~ "top:18px"
  end
end
