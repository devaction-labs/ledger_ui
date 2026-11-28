defmodule LedgerUI.Components.RailTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Rail

  defp html(fun), do: fun.(%{}) |> rendered_to_string()

  defp basic(extra \\ []) do
    assigns = Map.new(extra)

    html(fn _ ->
      ~H"""
      <.rail
        id="rail"
        current={assigns[:current]}
        variant={assigns[:variant] || "compact"}
        shape={assigns[:shape] || "rounded"}
      >
        <:top><span id="brand">B</span></:top>
        <:item
          path="/contatos"
          icon="users"
          label="Contatos"
          alert={true}
          count={214}
          preview_title="Contatos"
          preview_description="Clientes e pessoas"
        >
          <i id="art">art</i>
        </:item>
        <:item path="/contratos" icon="huge-home-01" label="Contratos" />
        <:item
          path="/relatorios"
          icon="shield"
          label="Relatórios"
          disabled={true}
          preview_title="Relatórios"
        />
        <:bottom><span id="foot">F</span></:bottom>
      </.rail>
      """
    end)
  end

  test "default render: nav with hook, three groups, links with navigate" do
    html = basic()
    assert html =~ ~s(<nav id="rail")
    assert html =~ ~s(aria-label="Main navigation")
    assert html =~ ~s(phx-hook="LedgerUI.RailPreview")
    assert html =~ ~s(data-variant="compact")
    assert html =~ ~s(data-shape="rounded")
    assert html =~ ~s(data-lu-delay="150")
    assert html =~ "w-16"
    assert html =~ ~s(data-group="top")
    assert html =~ ~s(data-group="nav")
    assert html =~ ~s(data-group="bottom")
    assert html =~ ~s(id="brand")
    assert html =~ ~s(id="foot")
    assert html =~ ~s(href="/contatos")
    assert html =~ ~s(data-phx-link="redirect")
    assert html =~ "rounded-[18px]"
    assert html =~ "backdrop-blur-[14px]"
    assert html =~ "size-10"
    assert html =~ "rounded-md"
    refute html =~ "rounded-full border"
  end

  test "expanded: 232px, label visible and count" do
    html = basic(variant: "expanded")
    assert html =~ "w-[232px]"
    assert html =~ "w-full"
    assert html =~ ~r/<span class="max-md:sr-only[^"]*">Contatos<\/span>/
    assert html =~ ~r/tabular-nums">214<\/span>/
  end

  test "compact: the label is for screen readers, no visible count" do
    html = basic()
    assert html =~ ~r/<span class="sr-only">Contatos<span> \(214\)<\/span><\/span>/
    refute html =~ ~r/tabular-nums">214/
  end

  test "pill makes groups and items fully round" do
    html = basic(shape: "pill")
    assert html =~ ~s(data-shape="pill")
    assert html =~ ~r/data-group="nav" class="[^"]*rounded-\[27px\]/
    assert html =~ ~r/data-rail-item[^>]*class="[^"]*rounded-full/
    refute html =~ ~r/data-part="rail-group"[^>]*rounded-\[18px\]/
  end

  test "the active item follows current: exact, prefix on a segment boundary, longest wins" do
    html = basic(current: "/contatos")

    assert html =~
             ~r/aria-current="page"[^>]*href="\/contatos"|href="\/contatos"[^>]*aria-current="page"/

    assert length(Regex.scan(~r/aria-current="page"/, html)) == 1
    assert html =~ "bg-panel text-ink"

    assert basic(current: "/contatos/3?tab=a") =~ ~r/aria-current="page"/
    refute basic(current: "/contatos-2") =~ "aria-current"
    refute basic(current: nil) =~ "aria-current"

    assigns = %{}

    html =
      html(fn _ ->
        ~H"""
        <.rail id="r" current="/a/b/c">
          <:item path="/a" icon="home" label="A" />
          <:item path="/a/b" icon="home" label="AB" />
          <:item path="/" icon="home" label="Root" />
        </.rail>
        """
      end)

    assert length(Regex.scan(~r/aria-current="page"/, html)) == 1
    assert html =~ ~r/aria-current="page"[^>]*href="\/a\/b"|href="\/a\/b"[^>]*aria-current="page"/
  end

  test "alert draws the dot with a ring and a text for screen readers" do
    html = basic()
    assert html =~ ~s(data-part="rail-alert")
    assert html =~ "size-[7px]"
    assert html =~ "bg-neg ring-2 ring-panel"
    assert html =~ "Needs attention"
    assert length(Regex.scan(~r/data-part="rail-alert"/, html)) == 1
  end

  test "disabled is dimmed, not a link and aria-disabled" do
    html = basic()
    assert html =~ ~r/<span role="link" aria-disabled="true"[^>]*data-disabled/
    assert html =~ "opacity-35"
    refute html =~ ~s(href="/relatorios")
  end

  test "previews are in the DOM, hidden, and the items describe themselves with them" do
    html = basic()
    assert html =~ ~s(id="rail-pv-0")
    assert html =~ ~s(aria-describedby="rail-pv-0")
    assert html =~ ~s(id="rail-pv-2")
    assert html =~ ~s(aria-describedby="rail-pv-2")
    # the item without title and description has none
    refute html =~ "rail-pv-1"
    assert html =~ ~s(role="tooltip")
    assert html =~ ~s(data-part="rail-preview")
    assert html =~ "w-[236px]"
    assert html =~ "bg-tip-glass"
    assert html =~ "backdrop-blur-[18px]"
    assert html =~ "hidden"
    assert html =~ ~r/<i id="art">art<\/i>/
    assert html =~ ~r/text-\[15px\][^>]*>Contatos<\/b>/
    assert html =~ "Clientes e pessoas"
    assert html =~ "text-white/62"
    # a preview outside the groups: backdrop-filter would capture its `fixed`
    [_, after_nav] = String.split(html, ~s(data-group="bottom"), parts: 2)
    assert after_nav =~ "rail-pv-0"
  end

  test "mobile: bottom bar classes and no top group" do
    html = basic()
    assert html =~ "max-md:fixed"
    assert html =~ "max-md:h-16"
    assert html =~ "max-md:rounded-xl"
    assert html =~ ~r/data-group="top" class="[^"]*max-md:hidden/
  end

  test "preview_delay goes to the hook and an empty rail renders" do
    assigns = %{}

    html =
      html(fn _ -> ~H|<.rail id="r" preview_delay={300} />| end)

    assert html =~ ~s(data-lu-delay="300")
    refute html =~ "data-group"
  end

  test "pt_BR texts" do
    assigns = %{}

    html =
      html(fn _ ->
        ~H|<.rail id="r" locale="pt_BR"><:item path="/a" icon="home" label="A" alert={true} /></.rail>|
      end)

    assert html =~ ~s(aria-label="Navegação principal")
    assert html =~ "Requer atenção"
  end

  describe "rail_user_menu/1" do
    defp menu(extra \\ []) do
      assigns = Map.new(extra)

      html(fn _ ->
        ~H"""
        <.rail_user_menu
          id="um"
          name="Ana Souza"
          email="ana@example.com"
          profile_path={assigns[:profile_path] || "/perfil"}
          settings_path="/config"
          sign_out_path="/sair"
          theme={Map.get(assigns, :theme, true)}
        />
        """
      end)
    end

    test "avatar trigger and a 280px popover with header, links, theme and sign out" do
      html = menu()
      assert html =~ ~s(data-part="rail-user-menu")
      assert html =~ ~s(aria-label="Account menu")
      assert html =~ ~s(aria-haspopup="dialog")
      assert html =~ "--w:280px"
      assert html =~ "Ana Souza"
      assert html =~ "ana@example.com"
      assert html =~ ~s(href="/perfil")
      assert html =~ "Profile"
      assert html =~ ~s(href="/config")
      assert html =~ "Settings"
      assert html =~ ~s(phx-hook="LedgerUI.ThemeSwitch")
      assert html =~ ~s(id="um-theme")
      assert html =~ ~s(data-icon="sun")
      assert html =~ ~s(data-icon="moon")
      assert html =~ ~s(data-icon="monitor") or html =~ "data-lu-system"
      assert html =~ ~s(href="/sair")
      assert html =~ ~s(data-method="delete")
      assert html =~ "Sign out"
    end

    test "theme can be left out" do
      refute menu(theme: false) =~ "LedgerUI.ThemeSwitch"
    end
  end
end
