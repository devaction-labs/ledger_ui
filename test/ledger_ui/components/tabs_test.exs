defmodule LedgerUI.Components.TabsTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Tabs

  defp norm(rendered) do
    rendered
    |> rendered_to_string()
    |> String.replace(~r/\s+/, " ")
    |> String.replace(~r/>\s+/, ">")
    |> String.replace(~r/\s+</, "<")
  end

  test "variant, size, color and the first tab selected by default" do
    assigns = %{}

    html =
      norm(~H"""
      <.tabs id="t" variant="pill" size="xs" color="neutral">
        <:tab name="a">A</:tab>
        <:tab name="b">B</:tab>
      </.tabs>
      """)

    assert html =~ ~s(class="lu-tb pill s-xs c-neutral")
    assert html =~ ~s(role="tablist")
    assert html =~ ~s(phx-hook="LedgerUI.Tabs")
    assert html =~ ~s(<button id="t-tab-a" class="on" type="button" role="tab")
    refute html =~ ~s(id="t-tab-b" class="on")
  end

  test "selected, vertical, md size has no size class and color is nil by default" do
    assigns = %{}

    html =
      norm(~H"""
      <.tabs id="t" selected="b" orientation="vertical">
        <:tab name="a">A</:tab>
        <:tab name="b">B</:tab>
      </.tabs>
      """)

    assert html =~ ~s(class="lu-tb line vert")
    assert html =~ ~s(id="t-tab-b" class="on")
  end

  test "all variants render" do
    assigns = %{}

    for v <- ~w(line boxed pill text segmented nav) do
      assigns = %{v: v}
      html = norm(~H|<.tabs id="t" variant={@v}>
  <:tab name="a">A</:tab>
</.tabs>|)
      assert html =~ "lu-tb #{v}"
    end

    html = norm(~H|<.tabs id="t" variant="classic">
  <:tab name="a" count={3} count_tone="acc">A</:tab>
</.tabs>|)
    assert html =~ "lu-tabs"
    assert html =~ "lu-tab on"
    assert html =~ ~s(data-lu-single)
    assert html =~ ~s(<span class="lu-badge acc">3</span>)
  end

  test "panels: wrapper, hidden state and the id convention" do
    assigns = %{}

    html =
      norm(~H"""
      <.tabs id="t" selected="b" transition="up" on_change="changed" target="#c">
        <:tab name="a">A</:tab>
        <:tab name="b">B</:tab>
        <:panel name="a">Panel A</:panel>
        <:panel name="b" class="p">Panel B</:panel>
      </.tabs>
      """)

    assert html =~ ~s(id="t-panel-a")
    assert html =~ ~s(role="tabpanel")
    assert html =~ ~s(aria-labelledby="t-tab-a")
    assert html =~ ~r/id="t-panel-a"[^>]*\shidden\skeep-hidden/
    refute html =~ ~r/id="t-panel-b"[^>]*\shidden\s/
    assert html =~ ~s(data-transition="up")
    assert html =~ ~s(data-on-change="changed")
    assert html =~ ~s(data-target="#c")
  end

  test "on_change JS is passed as data-on-change-js" do
    assigns = %{js: Phoenix.LiveView.JS.push("x")}
    html = norm(~H|<.tabs id="t" on_change={@js}>
  <:tab name="a">A</:tab>
</.tabs>|)
    assert html =~ "data-on-change-js"
  end

  test "count, overdue, disabled, soon" do
    assigns = %{}

    html =
      norm(~H"""
      <.tabs id="t" soon_label="Soon">
        <:tab name="a" count={12}>A</:tab>
        <:tab name="b" count={2} overdue>B</:tab>
        <:tab name="c" disabled>C</:tab>
        <:tab name="d" soon>D</:tab>
      </.tabs>
      """)

    assert html =~ ~s(<span class="lu-badge">12</span>)
    assert html =~ ~s(<span class="lu-badge neg">2</span>)
    assert html =~ "disabled"
    assert html =~ ~s(title="Soon")
  end

  test "link tabs render links with aria-current on the selected one" do
    assigns = %{}

    html =
      norm(~H"""
      <.tabs id="t" variant="nav" selected="o">
        <:tab name="o" navigate="/o">O</:tab>
        <:tab name="p" href="/p">P</:tab>
      </.tabs>
      """)

    assert html =~ ~s(aria-current="page")
    assert html =~ ~s(href="/p")
    refute html =~ ~s(role="tab")
  end
end
