defmodule LedgerUI.Components.BreadcrumbTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Breadcrumb

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

  test "links, separators and the current item" do
    assigns = %{}

    html =
      norm(~H"""
      <.breadcrumb variant="canvas" label="Trilha">
        <:item navigate="/customers">Customers</:item>
        <:item>Casa das Tintas</:item>
      </.breadcrumb>
      """)

    assert html =~ ~s(aria-label="Trilha")
    assert tag(html, "breadcrumb") =~ "gap-1"
    assert tag(html, "breadcrumb-link") =~ ~s(href="/customers")
    assert tag(html, "breadcrumb-link") =~ "hover:bg-hover"
    assert html =~ ~r/data-part="breadcrumb-separator"[^>]*>\/<\/span>/
    assert tag(html, "breadcrumb-current") =~ ~s(aria-current="page")
    assert tag(html, "breadcrumb-current") =~ "bg-sunken"
    assert html =~ "Casa das Tintas</span>"
  end

  test "default is the plain trail; default label" do
    assigns = %{}
    html = norm(~H|<.breadcrumb>
  <:item href="/">A</:item><:item>B</:item>
</.breadcrumb>|)
    assert tag(html, "breadcrumb") =~ "gap-2"
    assert tag(html, "breadcrumb") =~ "text-[15px]"
    assert tag(html, "breadcrumb") =~ ~s(aria-label="Breadcrumb")
    refute html =~ ~r/[\s"]lu-/
  end

  test "phx-click items are buttons that look like links; nil destinations are text" do
    assigns = %{}

    html =
      norm(~H"""
      <.breadcrumb>
        <:item phx-click="open" phx-value-id="1">Folder</:item>
        <:item navigate={nil}>Plain</:item>
        <:item>Now</:item>
      </.breadcrumb>
      """)

    assert html =~ ~s(role="button")
    assert html =~ ~s(phx-click="open")
    assert html =~ ~s(phx-value-id="1")
    assert html =~ ~r/<span[^>]*>Plain<\/span>/
    refute html =~ ~r/<a[^>]*>Plain/
  end

  test "custom separator and icon" do
    assigns = %{}

    html =
      norm(~H"""
      <.breadcrumb>
        <:separator><b>&gt;</b></:separator>
        <:item icon="grid" href="/">Home</:item>
        <:item>Now</:item>
      </.breadcrumb>
      """)

    assert html =~ "<b>&gt;</b>"
    refute html =~ "breadcrumb-separator"
    assert html =~ ~s(data-icon="grid")
  end

  test "max_items collapses the middle into a dropdown" do
    assigns = %{}

    html =
      norm(~H"""
      <.breadcrumb id="path" max_items={4} more_label="More">
        <:item navigate="/1">One</:item>
        <:item navigate="/2">Two</:item>
        <:item navigate="/3">Three</:item>
        <:item navigate="/4">Four</:item>
        <:item>Five</:item>
      </.breadcrumb>
      """)

    assert html =~ ~s(id="path-more")
    assert html =~ ~s(aria-label="More")
    # first, "...", last two
    assert html =~ ~s(href="/1")
    assert html =~ ~s(href="/2")
    assert html =~ ~s(href="/3")
    assert html =~ ~s(href="/4")
    assert tag(html, "breadcrumb-current") =~ ~s(aria-current="page")
    assert length(String.split(html, ~s(data-part="pop-item"))) == 3
  end

  test "style goes on the current step or a wrapper of link and separator" do
    assigns = %{}

    html =
      norm(~H"""
      <.breadcrumb>
        <:item href="/" style="--dl:0s">A</:item><:item style="--dl:1s">B</:item>
      </.breadcrumb>
      """)

    assert tag(html, "breadcrumb-current") =~ ~s(style="--dl:1s")
    assert html =~ "--dl:0s;display:inline-flex"
  end
end
