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
    assert html =~ "lu-crumb canvas"
    assert html =~ ~s(href="/customers")
    assert html =~ ~s(<span class="s">/</span>)
    assert html =~ ~s(<span class="cur">Casa das Tintas</span>)
  end

  test "default has no variant class; default label" do
    assigns = %{}
    html = norm(~H|<.breadcrumb>
  <:item href="/">A</:item><:item>B</:item>
</.breadcrumb>|)
    assert html =~ ~s(class="lu-crumb")
    assert html =~ ~s(aria-label="Breadcrumb")
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
    refute html =~ ~s(class="s")
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
    assert html =~ ~s(<span class="cur">Five</span>)
    assert length(String.split(html, ~s(class="lu-menu-item"))) == 3
  end

  test "style goes on the current step or a wrapper of link and separator" do
    assigns = %{}

    html =
      norm(~H"""
      <.breadcrumb>
        <:item href="/" style="--dl:0s">A</:item><:item style="--dl:1s">B</:item>
      </.breadcrumb>
      """)

    assert html =~ ~s(<span class="cur" style="--dl:1s">B</span>)
    assert html =~ "--dl:0s;display:inline-flex"
  end
end
