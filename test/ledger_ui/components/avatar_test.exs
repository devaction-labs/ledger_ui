defmodule LedgerUI.Components.AvatarTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Avatar

  test "initials come from the name, upper-cased, and size maps to pixels" do
    assigns = %{}
    html = rendered_to_string(~H|<.avatar name="ana souza" size="md" />|)
    assert html =~ "AS"
    assert html =~ "--s:36px"
    assert rendered_to_string(~H|<.avatar initials="jd" size="40" />|) =~ "--s:40px"
  end

  test "color, variant and shape classes" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.avatar initials="jd" color="info" variant="soft" shape="hexagon" />|
      )

    assert html =~ ~s(class="lu-av c-info v-soft sh-hexagon")
  end

  test "color auto is stable for the same name" do
    assigns = %{}
    a = rendered_to_string(~H|<.avatar name="Ana Souza" color="auto" />|)
    b = rendered_to_string(~H|<.avatar name="Ana Souza" color="auto" />|)
    assert a == b
    assert a =~ ~r/c-(neutral|primary|secondary|info|success|warning|error)/
  end

  test "status dot: presence, position, ping and none" do
    assigns = %{}

    assert rendered_to_string(~H|<.avatar initials="A" status="online" />|) =~
             ~s(<span class="st on">)

    html =
      rendered_to_string(
        ~H|<.avatar initials="A" status="busy" status_position="top-left" ping />|
      )

    assert html =~ ~s(class="st busy m tl")
    refute rendered_to_string(~H|<.avatar initials="A" status={false} />|) =~ ~s(class="st)
  end

  test "image avatar, gradient, ring and kind" do
    assigns = %{}
    html = rendered_to_string(~H|<.avatar src="/a.jpg" alt="Ana" gradient="sky-blue" ring />|)
    assert html =~ ~s(src="/a.jpg")
    assert html =~ ~s(alt="Ana")
    assert html =~ "grad g-sky-blue"
    assert html =~ "ring1"
    html = rendered_to_string(~H|<.avatar kind="company" />|)
    assert html =~ "c-neutral v-soft"
    assert html =~ ~s(data-icon="building")
  end

  test "avatar_group: overlap, more and label" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.avatar_group overlap="3" more={3} size="md" label="7 people" spread>
        <.avatar initials="A" />
      </.avatar_group>
      """)

    assert html =~ "lu-av-grp ov3 spread"
    assert html =~ "+3"
    assert html =~ ~s(role="group")
    assert html =~ ~s(aria-label="7 people")
  end

  test "avatar_group: hidden people open a popover" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.avatar_group id="team" hidden={[%{name: "Carla Lima"}, %{name: "Bruno Melo"}]}>
        <.avatar initials="A" />
      </.avatar_group>
      """)

    assert html =~ "+2"
    assert html =~ ~s(id="team-more")
    assert html =~ "Carla Lima"
    assert html =~ "phx-click"
  end
end
