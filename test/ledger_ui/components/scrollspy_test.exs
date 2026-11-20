defmodule LedgerUI.Components.ScrollspyTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Scrollspy

  defp norm(rendered) do
    rendered
    |> rendered_to_string()
    |> String.replace(~r/\s+/, " ")
    |> String.replace(~r/>\s+/, ">")
    |> String.replace(~r/\s+</, "<")
  end

  # the opening tag of the n-th element with `data-part`
  defp tag(html, part, n \\ 0) do
    ~r/<[a-z0-9]+[^>]*data-part="#{part}"[^>]*>/ |> Regex.scan(html) |> Enum.at(n) |> hd()
  end

  test "renders a nav of anchors with the hook" do
    assigns = %{}

    html =
      norm(~H"""
      <.scrollspy id="nav" offset={96}>
        <:item href="#profile">Profile</:item>
        <:item href="#security" style="--dl:1s">Security</:item>
      </.scrollspy>
      """)

    assert html =~ ~s(<nav id="nav")
    assert html =~ ~s(aria-label="On this page")
    assert html =~ ~s(phx-hook="LedgerUI.Scrollspy")
    assert html =~ ~s(data-offset="96")
    assert tag(html, "scrollspy") =~ "border-l"
    assert tag(html, "scrollspy") =~ "before:w-0.5"
    assert tag(html, "scrollspy-link", 0) =~ ~s(href="#profile")
    assert tag(html, "scrollspy-link", 0) =~ "aria-[current=true]:text-ink"
    assert tag(html, "scrollspy-link", 1) =~ ~s(style="--dl:1s")
    refute html =~ ~r/[\s"]lu-/
  end

  test "active marks aria-current; the legacy class on still does" do
    assigns = %{}

    html =
      norm(~H"""
      <.scrollspy id="n">
        <:item href="#a" active>A</:item>
        <:item href="#b" class="on">B</:item>
        <:item href="#c">C</:item>
      </.scrollspy>
      """)

    assert tag(html, "scrollspy-link", 0) =~ ~s(aria-current="true")
    assert tag(html, "scrollspy-link", 1) =~ ~s(aria-current="true")
    refute tag(html, "scrollspy-link", 2) =~ "aria-current"
    refute tag(html, "scrollspy-link", 1) =~ ~r/class="[^"]*\bon\b/
  end

  test "demo walks the marker by itself and needs no hook" do
    assigns = %{}

    html =
      norm(~H"""
      <.scrollspy id="n" demo label={nil}>
        <:item href="#" style="--dl:2s">A</:item>
      </.scrollspy>
      """)

    refute html =~ "phx-hook"
    assert tag(html, "scrollspy") =~ "animate-[mo-spybar"
    assert tag(html, "scrollspy-link") =~ "animate-[mo-spya"
  end

  test "default offset sends no attribute; label can be dropped" do
    assigns = %{}
    html = norm(~H|<.scrollspy id="n" label={nil}>
  <:item href="#a">A</:item>
</.scrollspy>|)
    refute html =~ "data-offset"
    refute html =~ "aria-label"
  end
end
