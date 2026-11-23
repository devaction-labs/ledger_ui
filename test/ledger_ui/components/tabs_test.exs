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

  # the opening tag of the n-th element with `data-part`
  defp tag(html, part, n \\ 0) do
    ~r/<[a-z0-9]+[^>]*data-part="#{part}"[^>]*>/ |> Regex.scan(html) |> Enum.at(n) |> hd()
  end

  test "pill variant: rounded by default, shape=\"pill\" is fully round" do
    assigns = %{}

    rounded = norm(~H|<.tabs id="t" variant="pill">
  <:tab name="a">A</:tab>
</.tabs>|)
    pill = norm(~H|<.tabs id="t" variant="pill" shape="pill">
  <:tab name="a">A</:tab>
</.tabs>|)

    assert tag(rounded, "tab", 0) =~ "rounded-md"
    refute tag(rounded, "tab", 0) =~ "rounded-full"
    assert tag(pill, "tab", 0) =~ "rounded-full"
    refute tag(pill, "tab", 0) =~ ~r/[\s"]rounded-md/
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

    list = tag(html, "tabs-list")
    assert list =~ ~s(role="tablist")
    assert list =~ ~s(phx-hook="LedgerUI.Tabs")
    assert list =~ "gap-1"
    # pill, xs: 28px high, 12px font; the neutral selected tab is the ink one
    assert tag(html, "tab", 0) =~ "h-7"
    assert tag(html, "tab", 0) =~ "text-[12px]"
    assert tag(html, "tab", 0) =~ "data-[state=on]:bg-ink"
    assert tag(html, "tab", 0) =~ ~s(id="t-tab-a")
    assert tag(html, "tab", 0) =~ ~s(data-state="on")
    assert tag(html, "tab", 0) =~ ~s(aria-selected="true")
    refute tag(html, "tab", 1) =~ ~s(data-state="on")
    assert tag(html, "tab", 1) =~ ~s(aria-selected="false")
    refute html =~ ~r/[\s"]lu-/
  end

  test "selected, vertical, md size and the primary look by default" do
    assigns = %{}

    html =
      norm(~H"""
      <.tabs id="t" selected="b" orientation="vertical">
        <:tab name="a">A</:tab>
        <:tab name="b">B</:tab>
      </.tabs>
      """)

    list = tag(html, "tabs-list")
    assert list =~ "flex-col"
    assert list =~ "w-[180px]"
    assert list =~ "border-l"
    assert tag(html, "tab", 0) =~ "h-[34px]"
    assert tag(html, "tab", 1) =~ ~s(id="t-tab-b")
    assert tag(html, "tab", 1) =~ ~s(data-state="on")
    assert tag(html, "tab", 1) =~ "data-[state=on]:after:w-0.5"
    assert tag(html, "tabs-list") =~ ~s(aria-orientation="vertical")
  end

  test "all variants render" do
    assigns = %{}

    for v <- ~w(line boxed pill text segmented nav) do
      assigns = %{v: v}
      html = norm(~H|<.tabs id="t" variant={@v}>
  <:tab name="a">A</:tab>
</.tabs>|)
      assert tag(html, "tabs-list") =~ "flex"
      assert tag(html, "tab") =~ "data-[state=on]:"
    end

    assert tag(
             norm(~H|<.tabs id="t" variant="boxed">
  <:tab name="a">A</:tab>
</.tabs>|),
             "tabs-list"
           ) =~
             "bg-sunken"

    assert tag(
             norm(~H|<.tabs id="t" variant="segmented">
  <:tab name="a">A</:tab>
</.tabs>|),
             "tabs-list"
           ) =~
             "border-line-strong"

    html = norm(~H|<.tabs id="t" variant="classic">
  <:tab name="a" count={3} count_tone="acc">A</:tab>
</.tabs>|)
    assert tag(html, "tabs-list") =~ "border-b"
    assert tag(html, "tab") =~ "h-10"
    assert tag(html, "tab") =~ "data-[state=on]:after:bg-ink"
    assert tag(html, "tab") =~ ~s(data-state="on")
    assert html =~ ~s(data-lu-single)
    # the classic count is the small canvas badge, the primary tone
    assert tag(html, "tab-count") =~ "h-[18px]"
    assert tag(html, "tab-count") =~ "bg-accent-soft"
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

    assert tag(html, "tab-count", 0) =~ "bg-sunken"
    assert tag(html, "tab-count", 0) =~ "h-[22px]"
    assert tag(html, "tab-count", 1) =~ "bg-neg-soft"
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
