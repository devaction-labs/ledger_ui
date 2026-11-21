defmodule LedgerUI.JSHiddenAttrTest do
  @moduledoc """
  Tailwind v4's preflight has `[hidden]:where(:not([hidden=until-found])) { display: none !important }`,
  so `JS.toggle/show/hide` (which only set an inline `display`) never open an element that is
  rendered with the `hidden` attribute. Such targets must be driven with `set_attr`/`toggle_attr`/
  `remove_attr` on `hidden` instead (#11).
  """
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.AppShell
  import LedgerUI.Components.Sidebar
  import LedgerUI.Components.Navbar
  import LedgerUI.Components.ThemePicker

  @display_ops ~w(toggle show hide)

  # Every phx-* JSON command in the HTML, as `{attr, [[op, args], ...]}`.
  defp commands(html) do
    html
    |> LazyHTML.from_fragment()
    |> LazyHTML.query("*")
    |> LazyHTML.attributes()
    |> Enum.flat_map(fn attrs ->
      for {name, "[[" <> _ = v} <- attrs,
          String.starts_with?(name, "phx-"),
          do: {name, Jason.decode!(v)}
    end)
  end

  defp ids_with_hidden(html) do
    html
    |> LazyHTML.from_fragment()
    |> LazyHTML.query("[hidden][id]")
    |> LazyHTML.attribute("id")
  end

  defp ops(html, op), do: for({_, cmds} <- commands(html), [^op, args] <- cmds, do: args)

  # No display op (toggle/show/hide) may target an element that carries the `hidden` attribute.
  defp refute_display_ops_on_hidden(html) do
    hidden = ids_with_hidden(html)

    for {name, cmds} <- commands(html), [op, args] <- cmds, op in @display_ops do
      refute args["to"] in Enum.map(hidden, &("#" <> &1)),
             "#{name}: #{op} targets #{args["to"]}, which uses the hidden attribute"
    end
  end

  defp hidden_ops(html, op),
    do:
      Enum.filter(ops(html, op), fn args ->
        args["attr"] == "hidden" or args["attr"] == ["hidden", "hidden"] or
          hd(List.wrap(args["attr"])) == "hidden"
      end)

  test "rail_module toggles the hidden attribute of its body" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.rail_module id="m" label="Sales">
  <:icon>i</:icon>
  <:item navigate="/o">O</:item>
</.rail_module>|)

    assert html =~ ~r/<div[^>]*id="m-body"[^>]*hidden/

    assert [%{"to" => "#m-body", "attr" => ["hidden", "hidden"]}] =
             hidden_ops(html, "toggle_attr") |> Enum.filter(&(&1["to"] == "#m-body"))

    assert [%{"to" => "#m-head"}] =
             Enum.filter(ops(html, "toggle_attr"), &(&1["to"] == "#m-head"))

    assert ops(html, "toggle") == []
    refute_display_ops_on_hidden(html)
  end

  test "sidebar_nav_group toggles hidden and closes the others by attribute" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.sidebar_nav_group id="g" label="G">
  <:item href="/a">A</:item>
</.sidebar_nav_group>|)

    assert Enum.any?(hidden_ops(html, "toggle_attr"), &(&1["to"] == "#g-body"))
    assert [%{"to" => sel, "attr" => ["hidden", ""]}] = hidden_ops(html, "set_attr")
    assert sel =~ "data-lu-sb-body"
    refute_display_ops_on_hidden(html)
    assert ops(html, "hide") == []
  end

  test "sub_nav groups toggle the hidden attribute" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.sub_nav title="Cases">
  <:group label="Status">x</:group>
</.sub_nav>|)

    assert Enum.any?(hidden_ops(html, "toggle_attr"), &(&1["to"] =~ "subnav-cases-0"))
    assert ops(html, "toggle") == []
  end

  test "sidebar_profile, header tools and horizontal nav use the hidden attribute" do
    assigns = %{}

    profile = rendered_to_string(~H|<.sidebar_profile id="pf" name="Ana" src="/a.png" alt="Ana">
  <:item href="/x">X</:item>
</.sidebar_profile>|)
    assert Enum.any?(hidden_ops(profile, "toggle_attr"), &(&1["to"] == "#pf-box"))
    assert Enum.any?(hidden_ops(profile, "set_attr"), &(&1["to"] == "#pf-box"))
    refute_display_ops_on_hidden(profile)

    header =
      rendered_to_string(~H|<.header id="h">
  <:notifications>n</:notifications>
  <:search_results>r</:search_results>
</.header>|)

    assert Enum.any?(hidden_ops(header, "toggle_attr"), &(&1["to"] == "#h-notifications"))
    assert Enum.any?(hidden_ops(header, "set_attr"), &(&1["to"] == "#h-results"))
    assert Enum.any?(hidden_ops(header, "remove_attr"), &(&1["to"] == "#h-results"))
    refute_display_ops_on_hidden(header)

    nav = rendered_to_string(~H|<.horizontal_nav_menu id="n" label="Pages">
  <:item navigate="/p">P</:item>
</.horizontal_nav_menu>|)
    assert Enum.any?(hidden_ops(nav, "toggle_attr"), &(&1["to"] == "#n-box"))
    refute_display_ops_on_hidden(nav)

    link = rendered_to_string(~H|<.horizontal_nav_link navigate="/p">P</.horizontal_nav_link>|)
    assert [_] = hidden_ops(link, "set_attr")
  end

  test "navbar_user and theme_picker toggle the hidden attribute" do
    assigns = %{}

    user = rendered_to_string(~H|<.navbar_user id="me" user={%{name: "Ana B"}}>
  <:menu>m</:menu>
</.navbar_user>|)
    assert Enum.any?(hidden_ops(user, "toggle_attr"), &(&1["to"] == "#me-menu"))
    assert Enum.any?(hidden_ops(user, "set_attr"), &(&1["to"] == "#me-menu"))
    refute_display_ops_on_hidden(user)

    picker =
      rendered_to_string(~H|<.theme_picker id="p" variant="menu" themes={~w(ledger noite)} />|)

    assert Enum.any?(hidden_ops(picker, "toggle_attr"), &(&1["to"] == "#p-pop"))
    refute_display_ops_on_hidden(picker)
  end

  test "sidebar team and user menus toggle the hidden attribute" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.sidebar
  id="sb"
  format="nested"
  footer="user"
  brand={%{name: "Acme", menu: [%{label: "One", href: "/1"}]}}
  user={%{name: "Ana", menu: [%{label: "Out", href: "/o"}]}}
/>|)

    assert Enum.any?(hidden_ops(html, "toggle_attr"), &(&1["to"] == "#sb-team"))
    assert Enum.any?(hidden_ops(html, "toggle_attr"), &(&1["to"] == "#sb-user"))
    refute_display_ops_on_hidden(html)
  end
end
