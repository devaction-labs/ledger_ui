defmodule LedgerUI.Components.ChipTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Chip
  alias Phoenix.LiveView.JS

  test "a plain chip is a span with the label" do
    assigns = %{}
    html = rendered_to_string(~H|<.chip label="Matriz" id="c" style="--dl:0s" />|)
    assert html =~ ~r/<span id="c" data-part="chip" class="[^"]*h-\[30px\][^"]*" style="--dl:0s">/
    assert html =~ "Matriz"
    refute html =~ "<button"
  end

  test "shape: rounded by default, pill is fully round" do
    assigns = %{}
    default = rendered_to_string(~H|<.chip label="A" />|)
    pill = rendered_to_string(~H|<.chip label="A" shape="pill" />|)

    assert default =~ "rounded-md"
    refute default =~ "rounded-full"
    assert pill =~ "rounded-full"
    refute pill =~ "rounded-md"
  end

  test "size: md (default) is 30px, lg is 32px, sm is 24px" do
    assigns = %{}
    default = rendered_to_string(~H|<.chip label="A" />|)
    assert default == rendered_to_string(~H|<.chip label="A" size="md" />|)
    assert default =~ "h-[30px]"
    refute default =~ "h-8"

    html = rendered_to_string(~H|<.chip label="A" size="lg" selected={false} on_remove="x" />|)
    assert html =~ "h-8"
    refute html =~ "h-[30px]"

    assert rendered_to_string(~H|<.chip label="A" size="sm" />|) =~ "h-6"
  end

  test "selected makes a toggle button that flips in the browser" do
    assigns = %{}
    html = rendered_to_string(~H|<.chip selected={true}>Pro</.chip>|)
    assert html =~ "aria-pressed:bg-inverse"
    assert html =~ ~s(aria-pressed="true")
    assert html =~ "data-lu-toggle"
    assert html =~ "phx-click"

    html =
      rendered_to_string(~H|<.chip selected={false} phx-click="toggle" value="pro">Pro</.chip>|)

    assert html =~ ~s(aria-pressed="false")
    assert html =~ ~s(phx-click="toggle")
    assert html =~ ~s(value="pro")
  end

  test "dashed, icon, count and tone" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.chip dashed icon="plus" tone="acc" selected={true} count={12}>Filtro</.chip>|
      )

    assert html =~ "border-dashed text-muted"
    assert html =~ "aria-pressed:bg-accent-soft"
    assert html =~ ~s(data-icon="plus")
    assert html =~ ~s(data-part="chip-count")
    assert html =~ ">12</span>"
  end

  test "on_remove adds an x: event name or JS command" do
    assigns = %{js: JS.hide(to: "#c1")}

    html =
      rendered_to_string(
        ~H|<.chip label="A" id="c1" on_remove="remove_it" target="#t" remove_label="Del" />|
      )

    assert html =~ ~s(aria-label="Del")
    assert html =~ "remove_it"
    assert html =~ "&quot;id&quot;:&quot;c1&quot;"

    html = rendered_to_string(~H|<.chip label="A" id="c1" on_remove={@js} />|)
    assert html =~ "hide"
  end

  test "links have no x; remove_patch makes the x a patch link" do
    assigns = %{}
    html = rendered_to_string(~H|<.chip href="/extract" label="Conta 1" on_remove="x" />|)

    # the attributes of the `<a>` come from `LedgerUI.LinkAttrs` (#97): the order is not the one of `<.link>`
    assert html =~ ~r/<a [^>]*data-part="chip"[^>]*>/
    assert html =~ ~r/<a [^>]*href="\/extract"[^>]*>/
    refute html =~ "<button"

    html = rendered_to_string(~H|<.chip label="Aberta" remove_patch="/tasks" />|)
    assert html =~ ~s(data-phx-link="patch")
    assert html =~ ~s(href="/tasks")
  end

  test "avatar with initials, colour and picture" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.chip avatar="Marina Costa" avatar_color="#8a5cd6">Marina Costa</.chip>|
      )

    assert html =~ ~s(data-part="person-avatar")
    assert html =~ "background:#8a5cd6"
    assert html =~ "MC"
    assert html =~ "--s:24px"

    html = rendered_to_string(~H|<.chip avatar="Marina Costa" avatar_src="/m.png" label="M" />|)
    assert html =~ ~s(<img src="/m.png")
    refute html =~ "MC"
  end
end
