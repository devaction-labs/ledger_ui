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

    assert html =~ "[--c:var(--lu-info)]"
    assert html =~ "bg-(--c-soft) text-(--c-ink)"
    assert html =~ "[clip-path:polygon(25%_4%"
    refute html =~ "lu-av"
  end

  test "color auto is stable for the same name" do
    assigns = %{}
    a = rendered_to_string(~H|<.avatar name="Ana Souza" color="auto" />|)
    b = rendered_to_string(~H|<.avatar name="Ana Souza" color="auto" />|)
    assert a == b
    assert a =~ "[--c:"
    assert a =~ "bg-(--c)"
  end

  test "status dot: presence, position, ping and none" do
    assigns = %{}

    assert rendered_to_string(~H|<.avatar initials="A" status="online" />|) =~
             ~s(data-part="avatar-status" class="absolute size-[30%])

    html =
      rendered_to_string(
        ~H|<.avatar initials="A" status="busy" status_position="top-left" ping />|
      )

    assert html =~ "bg-neg"
    assert html =~ "-left-px -top-px"
    assert html =~ "animate-[mo-blink_1.6s_ease-in-out_infinite]"

    assert rendered_to_string(~H|<.avatar initials="A" status="online" />|) =~
             "-right-px -bottom-px"

    refute rendered_to_string(~H|<.avatar initials="A" status={false} />|) =~ "avatar-status"
  end

  test "photo is taken out of grid flow so non-square images stay in the circle (#1)" do
    assigns = %{}
    html = rendered_to_string(~H|<.avatar src="/a.jpg" status="online" />|)
    [_, img] = Regex.run(~r/<img[^>]*>/, html) |> then(&[nil, hd(&1)])
    assert img =~ "avatar-image"
    assert img =~ ~r/class="[^"]*\babsolute\b/
    assert img =~ ~r/class="[^"]*\binset-0\b/
    {i_img, _} = :binary.match(html, "avatar-image")
    {i_dot, _} = :binary.match(html, "avatar-status")
    assert i_dot > i_img
  end

  test "image avatar, gradient, ring and kind" do
    assigns = %{}
    html = rendered_to_string(~H|<.avatar src="/a.jpg" alt="Ana" gradient="sky-blue" ring />|)
    assert html =~ ~s(src="/a.jpg")
    assert html =~ ~s(alt="Ana")
    assert html =~ "bg-[linear-gradient(135deg,var(--g1),var(--g2))]"
    assert html =~ "[--g1:#0ea5e9]"
    assert html =~ "shadow-[0_0_0_1px_var(--lu-bg-page),0_0_0_2px_var(--lu-accent-500)]"
    assert html =~ "data-lu-shadow"
    html = rendered_to_string(~H|<.avatar kind="company" />|)
    assert html =~ "bg-(--c-soft)"
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

    assert html =~ "]:-ml-[3px]"
    assert html =~ "hover:[&amp;&gt;[data-part=avatar]+[data-part=avatar]]:ml-1"
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

  test "mono variant, legacy tones and custom colours use utilities and inline colour" do
    assigns = %{}
    mono = rendered_to_string(~H|<.avatar initials="pb" variant="mono" size="32" />|)
    assert mono =~ "font-mono"
    assert mono =~ "shadow-[inset_0_0_0_1px_var(--lu-line-strong)]"
    refute mono =~ "font-semibold"

    assert rendered_to_string(~H|<.avatar initials="a" color="t1" />|) =~
             "bg-accent-100 text-accent-800"

    assert rendered_to_string(~H|<.avatar initials="a" color="t3" shape="square" />|) =~
             "rounded-[30%]"

    html = rendered_to_string(~H|<.avatar initials="a" tint="#1a7f4b" />|)
    assert html =~ "background:#1a7f4b;color:#fff"
  end

  test "ring colours and the group gap" do
    assigns = %{}
    html = rendered_to_string(~H|<.avatar initials="a" ring ring_color="white" />|)
    assert html =~ "shadow-[0_0_0_2px_#fff]"
    assert html =~ "data-lu-shadow"
    group = rendered_to_string(~H|<.avatar_group><.avatar initials="a" /></.avatar_group>|)
    assert group =~ ":not([data-lu-shadow])"
  end

  test "speak: 2px page gap, 4px ring, pulse" do
    assigns = %{}
    html = rendered_to_string(~H|<.avatar initials="AN" speak />|)
    assert html =~ "box-shadow:0_0_0_2px_var(--lu-bg-page),0_0_0_4px_var(--lu-accent-500)"
    assert html =~ "mo-speak_1.4s"
  end
end
