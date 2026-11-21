defmodule LedgerUI.Components.PlacementStageTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.PlacementStage

  defp html(fun), do: fun.(%{}) |> rendered_to_string()

  test "image, box and handle with the hook" do
    html =
      html(fn assigns ->
        ~H"""
        <.placement_stage
          id="pdf-stage"
          src="/page.png"
          alt="Page 1"
          box={%{left: 10, bottom: 20.5, width: 30, height: 8}}
          on_place="place_signature"
          on_resize="resize_signature"
        >
          Sign here
        </.placement_stage>
        """
      end)

    assert html =~ ~s(id="pdf-stage")
    assert html =~ ~s(phx-hook="LedgerUI.PlacementStage")
    assert html =~ ~s(src="/page.png")
    assert html =~ ~s(alt="Page 1")
    assert html =~ ~s(data-lu-on-place="place_signature")
    assert html =~ ~s(data-lu-on-resize="resize_signature")
    assert html =~ ~s(data-lu-box="10,20.5,30,8")
    assert html =~ "left:10%;bottom:20.5%;width:30%;height:8%"
    assert html =~ "touch-none"
    assert html =~ "border-dashed"
    assert html =~ "Sign here"
    assert html =~ "data-handle"
  end

  test "the box is focusable and labelled" do
    html =
      html(fn assigns ->
        ~H|<.placement_stage
  id="s"
  src="/p.png"
  box={%{left: 1, bottom: 2, width: 3, height: 4}}
  label="Stamp"
/>|
      end)

    assert html =~ ~s(tabindex="0")
    assert html =~ ~s(aria-label="Stamp")
    assert html =~ ~s(role="group")
  end

  test "resizable={false} removes the handle" do
    html =
      html(fn assigns ->
        ~H|<.placement_stage
  id="s"
  src="/p.png"
  box={%{left: 1, bottom: 2, width: 3, height: 4}}
  resizable={false}
/>|
      end)

    refute html =~ "data-handle"
  end

  test "disabled keeps the box but takes away focus, handle and gestures" do
    html =
      html(fn assigns ->
        ~H|<.placement_stage id="s" src="/p.png" box={%{left: 1, bottom: 2, width: 3, height: 4}} disabled />|
      end)

    assert html =~ ~s(data-lu-disabled="true")
    assert html =~ ~s(data-part="placement-box")
    refute html =~ "tabindex"
    refute html =~ "data-handle"
  end

  test "no box draws no box" do
    html = html(fn assigns -> ~H|<.placement_stage id="s" src="/p.png" />| end)

    refute html =~ "placement-box"
    refute html =~ "data-lu-box"
  end

  test "phx-target and class pass through" do
    html =
      html(fn assigns ->
        ~H|<.placement_stage id="s" src="/p.png" phx-target="#form" class="max-w-lg" />|
      end)

    assert html =~ ~s(phx-target="#form")
    assert html =~ "max-w-lg"
  end
end
