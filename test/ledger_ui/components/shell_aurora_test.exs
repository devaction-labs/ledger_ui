defmodule LedgerUI.Components.ShellAuroraTest do
  # Phase 6 of the Aurora look: `shell/1` with `layout="aurora"` (rail | main | aside on `bg-app`).
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI

  import LedgerUI.DiffCase
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  def page(assigns),
    do: ~H"""
    <.shell layout="aurora" id="app" tabs_id={@tabs_id} tab={@tab} aside_label={@aside_label}>
      <:rail>
        <.rail id="rail" current="/contatos">
          <:item path="/contatos" icon="users" label="Contatos" />
          <:item path="/funil" icon="home" label="Funil" />
        </.rail>
      </:rail>
      <:tabs :if={@with_tabs}>
        <.folder_tabs id="painel" active={@tab} on_change="tab">
          <:tab id="geral" label="Visao geral" />
          <:tab id="receita" label="Receita" />
        </.folder_tabs>
      </:tabs>
      <:aside :if={@with_aside}>
        <p>assistente</p>
      </:aside>
      <:topbar :if={@with_top}>
        <header>topo</header>
      </:topbar>
      <p>{@body}</p>
    </.shell>
    """

  @base %{
    tabs_id: nil,
    tab: nil,
    aside_label: nil,
    with_tabs: false,
    with_aside: false,
    with_top: false,
    body: "conteudo"
  }

  defp render(changes \\ %{}), do: rendered_to_string(page(Map.merge(@base, changes)))

  test "renders the rail, the panel and the page on the Aurora grid" do
    html = render()

    assert html =~ ~s(data-layout="aurora")
    assert html =~ "bg-app"
    assert html =~ "min-h-dvh"
    assert html =~ "gap-4"
    assert html =~ "md:grid-cols-[auto_minmax(0,1fr)]"
    refute html =~ "lg:grid-cols-[auto_minmax(0,1fr)_440px]"
    assert html =~ ~s(data-part="rail")
    assert html =~ ~s(data-part="shell-panel")
    assert html =~ "conteudo"
  end

  test "without tabs the panel is r24 on the four corners, with a border" do
    html = render()
    [panel] = Regex.run(~r/<div[^>]*data-part="shell-panel"[^>]*>/, html)

    assert panel =~ "rounded-2xl"
    assert panel =~ "bg-panel"
    assert panel =~ "border-line"
    assert panel =~ "shadow-xs"
    refute panel =~ "rounded-tl-none"
    refute panel =~ "role="
    refute html =~ ~s(data-part="shell-tabs")
  end

  test "with tabs the panel loses its top-left corner and is the tabpanel" do
    html = render(%{with_tabs: true, tabs_id: "painel", tab: "geral"})
    [panel] = Regex.run(~r/<div[^>]*data-part="shell-panel"[^>]*>/, html)

    assert html =~ ~s(data-part="shell-tabs")
    assert html =~ ~s(role="tablist")
    assert panel =~ "rounded-tl-none"
    refute panel =~ "border-line"
    assert panel =~ ~s(role="tabpanel")
    assert panel =~ ~s(id="painel-panel")
    assert panel =~ ~s(aria-labelledby="painel-tab-geral")
    # the tab list comes before the panel
    assert :binary.match(html, "shell-tabs") < :binary.match(html, "shell-panel")
  end

  test "the aside is a 440px glass column from lg; without it the grid has two columns" do
    with = render(%{with_aside: true, aside_label: "Assistente"})
    [aside] = Regex.run(~r/<aside[^>]*>/, with)

    assert with =~ "lg:grid-cols-[auto_minmax(0,1fr)_440px]"
    assert aside =~ "rounded-2xl"
    assert aside =~ "bg-panel/50"
    assert aside =~ "backdrop-blur"
    assert aside =~ ~s(aria-label="Assistente")
    assert with =~ "assistente"

    without = render()
    refute without =~ "<aside"
    refute without =~ "440px"
  end

  test "the topbar goes above the panel, inside the column" do
    html = render(%{with_top: true})
    assert :binary.match(html, "topo") < :binary.match(html, "<main")
  end

  test "has one main and one navigation landmark (the rail's)" do
    html = render(%{with_tabs: true, tabs_id: "painel", tab: "geral", with_aside: true})

    assert length(Regex.scan(~r/<main[\s>]/, html)) == 1
    assert length(Regex.scan(~r/<nav[\s>]/, html)) == 1
    assert length(Regex.scan(~r/role="navigation"/, html)) == 0
  end

  test "the rail slot is required in this layout" do
    assigns = %{}

    assert_raise ArgumentError, ~r/:rail/, fn ->
      rendered_to_string(~H|<.shell layout="aurora">x</.shell>|)
    end
  end

  test "the preview variant draws the rail wireframe for aurora" do
    assigns = %{}
    html = rendered_to_string(~H|<.shell variant="preview" layout="aurora" />|)
    assert html =~ ~s(data-part="shell-wire-rail")
  end

  describe "change tracking" do
    @full %{@base | tabs_id: "painel", tab: "geral", with_tabs: true, with_aside: true}

    test "changing only the content does not resend the panel, the grid or the aside" do
      json = check(&page/1, @full, body: "outro")

      assert json =~ "outro"
      refute json =~ "rounded-tl-none"
      refute json =~ "min-h-dvh"
      refute json =~ "backdrop-blur"
      refute json =~ "assistente"
      refute json =~ "painel-panel"
    end

    test "each source of the derived values patches right" do
      each_source(&page/1, @full,
        tab: "receita",
        aside_label: "Detalhe",
        body: "novo"
      )

      each_source(&page/1, @base, tabs_id: "x", with_tabs: true, with_aside: true)
    end
  end
end
