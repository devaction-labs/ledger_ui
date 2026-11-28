defmodule LedgerUI.ToneLeftoversTest do
  # #119: the long tone names on navbar_bell, navbar_env and the sidebar item, `values:` on
  # notification_center.placement, and the guard on `on_collapse` (sidebar and framed_sidebar).
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI

  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]
  alias Phoenix.LiveView.JS

  defp same(a, b), do: assert(a == b)

  defp bell_count(tone) do
    assigns = %{tone: tone}
    rendered_to_string(~H|<.navbar_bell count={3} tone={@tone} />|)
  end

  defp bell_dot(tone) do
    assigns = %{tone: tone}
    rendered_to_string(~H|<.navbar_bell dot tone={@tone} />|)
  end

  defp env(tone, compact) do
    assigns = %{tone: tone, compact: compact}
    rendered_to_string(~H|<.navbar_env label="x" tone={@tone} compact={@compact} />|)
  end

  test "navbar_bell takes the long tone names as aliases" do
    for {long, short} <- [{"error", "neg"}, {"warning", "warn"}, {"success", "pos"}] do
      same(bell_count(long), bell_count(short))
      same(bell_dot(long), bell_dot(short))
    end

    assert bell_count("warning") =~ "bg-[#f59e0b]"
  end

  test "navbar_env takes success and warning" do
    for compact <- [true, false] do
      same(env("warning", compact), env("warn", compact))
      same(env("success", compact), env("ok", compact))
    end
  end

  test "the tone attrs declare the long names in values" do
    for {fun, mod} <- [
          navbar_bell: LedgerUI.Components.Navbar,
          navbar_env: LedgerUI.Components.Navbar
        ] do
      %{attrs: attrs} = mod.__components__()[fun]
      tone = Enum.find(attrs, &(&1.name == :tone))
      assert "success" in tone.opts[:values] and "warning" in tone.opts[:values]
    end

    %{attrs: attrs} = LedgerUI.Components.NotificationCenter.__components__().notification_center
    placement = Enum.find(attrs, &(&1.name == :placement))
    assert "bottom-end" in placement.opts[:values]
  end

  test "a sidebar item takes the long tone names" do
    html = fn tone ->
      assigns = %{tone: tone}

      rendered_to_string(~H"""
      <.sidebar id="s" current="a" format="tree">
        <:item name="a" label="A" icon="home" navigate="/a" count={2} tone={@tone} />
      </.sidebar>
      """)
    end

    assert html.("pos") != html.("warn")
    same(html.("error"), html.("neg"))
    same(html.("success"), html.("pos"))
    same(html.("warning"), html.("warn"))
  end

  test "on_collapse of sidebar and framed_sidebar: an event name renders, a JS command raises" do
    assigns = %{js: JS.push("x")}

    assert rendered_to_string(~H|<.sidebar id="s" on_collapse="saved" />|) =~
             ~s(data-lu-on-collapse="saved")

    assert rendered_to_string(~H|<.framed_sidebar id="f" on_collapse="saved">x</.framed_sidebar>|) =~
             ~s(data-lu-on-collapse="saved")

    assert_raise ArgumentError, ~r/`on_collapse` takes a LiveView event name/, fn ->
      rendered_to_string(~H|<.sidebar id="s" on_collapse={@js} />|)
    end

    assert_raise ArgumentError, ~r/`on_collapse` takes a LiveView event name/, fn ->
      rendered_to_string(~H|<.framed_sidebar id="f" on_collapse={@js}>x</.framed_sidebar>|)
    end
  end
end
