defmodule LedgerUI.Components.ButtonTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Button

  test "defaults to the black solid button" do
    assigns = %{}
    html = rendered_to_string(~H|<.button>Save</.button>|)
    assert html =~ ~s(class="lu-b c-neutral v-solid s-md sh-rounded")
    assert html =~ ~s(type="button")
    refute html =~ "style="
  end

  test "color, variant, size, shape" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.button color="primary" variant="soft" size="lg" shape="pill" class="x">Ok</.button>|
      )

    assert html =~ ~s(class="lu-b c-primary v-soft s-lg sh-pill x")
  end

  test "current colour has no colour class and icon is square" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.button color="current" variant="ghost" icon aria-label="m">x</.button>|
      )

    assert html =~ ~s(class="lu-b v-ghost s-md sh-square")
    assert html =~ ~s(aria-label="m")
  end

  test "loading disables, marks busy and adds the spinner" do
    assigns = %{}
    html = rendered_to_string(~H|<.button loading loading_label="Saving">Save</.button>|)
    assert html =~ "disabled"
    assert html =~ ~s(aria-busy="true")
    assert html =~ "color:transparent;position:relative"
    assert html =~ ~s(class="lu-sp v-border s-sm")
    assert html =~ ~s(aria-label="Saving")
  end

  test "pip adds the dot and relative positioning" do
    assigns = %{}
    html = rendered_to_string(~H|<.button icon pip aria-label="n">x</.button>|)
    assert html =~ "position:relative"
    assert html =~ "background:var(--neg)"
  end

  test "disabled and user style" do
    assigns = %{}
    html = rendered_to_string(~H|<.button disabled style="width:9px">x</.button>|)
    assert html =~ "disabled"
    assert html =~ ~s(style="width:9px")
  end

  test "link when href, navigate or patch" do
    assigns = %{}
    html = rendered_to_string(~H|<.button href="/a" variant="outline">Go</.button>|)
    assert html =~ ~s(<a href="/a")
    assert html =~ "v-outline"
    refute html =~ "<button"
  end

  test "rest attributes reach the button" do
    assigns = %{}
    html = rendered_to_string(~H|<.button phx-click="go" form="f" name="n" value="v">x</.button>|)
    assert html =~ ~s(phx-click="go")
    assert html =~ ~s(form="f")
  end

  test "button_group" do
    assigns = %{}
    assert rendered_to_string(~H|<.button_group>a</.button_group>|) =~ ~s(class="lu-bgroup")
    html = rendered_to_string(~H|<.button_group shape="pill">a</.button_group>|)
    assert html =~ ~s(class="lu-bgroup sh-pill")
  end

  test "icon_button variants and sizes" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.icon_button icon="plus" label="Add" variant="primary" size="sm" />|)

    assert html =~ ~s(class="lu-btn icon primary sm")
    assert html =~ ~s(aria-label="Add")
    assert html =~ ~s(data-icon="plus")

    assert rendered_to_string(~H|<.icon_button icon="x" label="a" />|) =~ ~s(class="lu-btn icon")
    html = rendered_to_string(~H|<.icon_button icon="bell" label="a" variant="topbar" dot />|)
    assert html =~ ~s(class="lu-tbtn dot")
    html = rendered_to_string(~H|<.icon_button icon="arrow-right" label="a" variant="go" />|)
    assert html =~ ~s(class="lu-round-go")
  end

  test "insight_button" do
    assigns = %{}
    html = rendered_to_string(~H|<.insight_button count={3}>New AI insights</.insight_button>|)
    assert html =~ ~s(<span class="n">3</span>)
    assert html =~ "New AI insights"
  end
end
