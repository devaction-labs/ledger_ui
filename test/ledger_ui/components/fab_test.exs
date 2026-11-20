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

    assert html =~ "bg-inverse"
    assert html =~ "rounded-[18px]"
    assert html =~ "absolute"
    assert html =~ "right-[var(--fab-o,18px)] bottom-[var(--fab-o,18px)]"
    refute html =~ ~r/class="(?:[^"]*\s)?lu-/
    assert html =~ "Novo pedido"
    assert html =~ ~s(data-icon="sparkles")
    assert html =~ ~s(phx-click="new")
    refute html =~ "style="
  end

  test "fixed by default" do
    assigns = %{}
    html = rendered_to_string(~H|<.fab id="n" label="N" offset={24} />|)
    assert html =~ "fixed z-[var(--ledger-z-fab,90)]"
    assert html =~ ~s(style="--fab-o:24px")
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

    assert html =~ "bg-white text-[#141514]"
    assert html =~ "left-[var(--fab-o,18px)] bottom-[var(--fab-o,18px)]"
    assert html =~ "h-[52px]"
    # `always` never opens on hover
    refute html =~ "hover:gap-2.5"
    assert html =~ ~s(data-state="collapsed")
    assert html =~ ~s(aria-label="Chat")
    assert html =~ ~s(title="Chat")
    assert html =~ ~r/data-part="fab-badge"[^>]*>3<\/span>/
    refute html =~ "phx-hook"
  end

  test "hover and auto open on hover, the label grows with the state" do
    assigns = %{}
    hover = rendered_to_string(~H|<.fab id="a" label="A" variant="pill" fixed={false} />|)
    assert hover =~ "hover:gap-2.5"
    assert hover =~ "focus-visible:gap-2.5"
    assert hover =~ "group-data-[state=expanded]/fab:max-w-[220px]"
    assert hover =~ "group-hover/fab:max-w-[220px]"
    auto = rendered_to_string(~H|<.fab id="a" label="A" variant="pill" retract="auto" />|)
    assert auto =~ "hover:gap-2.5"
    refute auto =~ "focus-visible:gap-2.5"

    big =
      rendered_to_string(~H|<.fab id="a" label="A" variant="pill" size="lg" color="primary" />|)

    assert big =~ "h-[60px]"
    assert big =~ "size-12"
    assert big =~ "bg-accent-600"
  end

  test "loop plays the canvas animation" do
    assigns = %{}
    html = rendered_to_string(~H|<.fab id="a" label="A" variant="pill" loop />|)
    assert html =~ "animate-[lu-fabpad_4.5s_cubic-bezier(.3,.7,.4,1)_infinite]"
    assert html =~ "animate-[lu-fablbl_4.5s_cubic-bezier(.3,.7,.4,1)_infinite]"
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
    assert html =~ ~r/data-part="fab-label"[^>]*>Custom<\/span>/
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

    assert html =~ "group/dial"
    assert html =~ "rounded-full"
    assert html =~ ~s(data-part="fab-dial-button")
    assert html =~ ~s(data-state="open")
    assert html =~ ~s(phx-hook="LedgerUI.FabDial")
    assert html =~ ~s(aria-expanded="true")
    assert html =~ ~s(aria-haspopup="menu")
    assert html =~ ~s(role="menu")
    assert html =~ ~s(phx-click="new")
    assert html =~ ~s(href="/v")
    assert length(String.split(html, ~s(role="menuitem"))) == 3
    assert html =~ ~r/data-part="fab-dial-label"[^>]*>Novo<\/span>/
    refute html =~ ~r/class="(?:[^"]*\s)?lu-/

    closed =
      rendered_to_string(~H"""
      <.fab_dial id="q" label="Ações" position="top-left">
        <:action label="A"><.icon name="file" /></:action>
      </.fab_dial>
      """)

    assert closed =~ ~s(data-state="closed")
    assert closed =~ "left-[var(--fab-o,18px)] top-[var(--fab-o,18px)]"
    assert closed =~ "items-start"
    assert closed =~ "flex-col "
    refute closed =~ "flex-col-reverse"
  end
end
