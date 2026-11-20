defmodule LedgerUI.Components.TimerTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Timer

  alias Phoenix.LiveView.{JS, Socket}

  test "formats" do
    assert format(11_565, "hms") == "03:12:45"
    assert format(11_565, "hm") == "3h12"
    assert format(11_565, "hh:mm") == "03:12"
    assert format(-5, "hms") == "00:00:00"
  end

  test "ring renders the hook, role and the server's time" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.timer id="t" elapsed={11565} color="primary" size="lg" label="Shift" />|
      )

    for c <- [
          ~s(phx-hook="LedgerUI.Timer"),
          ~s(role="timer"),
          ~s(aria-label="Shift"),
          "03:12:45",
          "[--sz:160px]",
          "[--c:var(--color-accent)]",
          "conic-gradient",
          ~s(data-state="running"),
          ~s(data-lu-elapsed="11565"),
          ~s(data-lu-running="true"),
          ~s(data-lu-direction="up"),
          "--lu-sp:"
        ],
        do: assert(html =~ c)
  end

  test "ring fill and direction down" do
    assigns = %{}
    up = rendered_to_string(~H|<.timer id="t" elapsed={50} total={100} />|)
    assert up =~ "--lu-sp:50%"
    down = rendered_to_string(~H|<.timer id="t" direction="down" elapsed={25} total={100} />|)
    assert down =~ "--lu-sp:75%"
    assert down =~ "00:01:15"
  end

  test "paused is warning; default timer name" do
    assigns = %{}
    html = rendered_to_string(~H|<.timer id="t" running={false} color="primary" />|)
    assert html =~ ~s(data-state="paused")
    assert html =~ "data-[state=paused]:[--c:var(--lu-warn)]"
    assert html =~ ~s(aria-label="Timer")
    assert html =~ ~s(data-lu-running="false")
  end

  test "kicker, label, caption and actions wrap the ring" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.timer id="t" kicker="Open" kicker_paused="Paused" label="Register 01">
        <:actions><button>Pause</button></:actions>
      </.timer>
      """)

    for c <- [
          "Open",
          ~s(data-lu-kicker-paused="Paused"),
          "Register 01",
          "<button>Pause</button>",
          "flex flex-col items-center"
        ],
        do: assert(html =~ c)

    cap = rendered_to_string(~H|<.timer id="t" label="L">
  <:caption>Custom</:caption>
</.timer>|)
    assert cap =~ "Custom"
    refute cap =~ ~s(data-part="timer-label")
  end

  test "mini variant" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.timer id="m" variant="mini" elapsed={5076} label="Shift time" />|)

    for c <- [
          "h-[30px]",
          "bg-sunken",
          "1h24",
          ~s(data-part="timer-dot"),
          ~s(role="timer"),
          ~s(data-lu-format="hm")
        ],
        do: assert(html =~ c)

    refute rendered_to_string(~H|<.timer id="m" variant="mini" running={false} />|) =~
             "timer-dot"
  end

  test "events and target" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.timer id="t" on_toggle="tg" on_tick="tk" on_finish={JS.push("fin")} target="#x" stop_at_total />|
      )

    for c <- [
          ~s(data-lu-on-toggle="tg"),
          ~s(data-lu-on-tick="tk"),
          "data-lu-on-finish-js",
          ~s(phx-target="#x"),
          ~s(data-lu-stop-at-total="true")
        ],
        do: assert(html =~ c)
  end

  describe "LedgerUI.Timer commands" do
    test "browser" do
      assert %JS{
               ops: [
                 ["dispatch", %{event: "ledger:timer", to: "#shift", detail: %{"op" => "toggle"}}]
               ]
             } = LedgerUI.Timer.toggle("shift")

      assert %JS{ops: [["dispatch", %{detail: %{"op" => "pause"}}]]} =
               LedgerUI.Timer.pause("shift")

      assert %JS{ops: [["dispatch", %{detail: %{"op" => "resume"}}]]} =
               LedgerUI.Timer.resume("shift")

      assert %JS{ops: [["dispatch", %{detail: %{"op" => "add", "seconds" => 900}}]]} =
               LedgerUI.Timer.add("shift", 900)
    end

    test "server" do
      socket = %Socket{assigns: %{__changed__: %{}}}
      s = socket |> LedgerUI.Timer.add("shift", -60) |> LedgerUI.Timer.pause("shift")

      assert [
               ["ledger:timer", %{"op" => "add", "seconds" => -60, "id" => "shift"}],
               ["ledger:timer", %{"op" => "pause", "id" => "shift"}]
             ] =
               Enum.reverse(s.private.live_temp.push_events)
    end
  end

  test "the ring is marked for the hook and carries its state" do
    assigns = %{}
    html = rendered_to_string(~H|<.timer id="t" elapsed={10} />|)
    assert html =~ "data-lu-ring"
    assert html =~ ~s(data-state="running")
    refute html =~ "lu-timer"
    extras = rendered_to_string(~H|<.timer id="t" kicker="Open" running={false} />|)
    assert extras =~ ~s(data-part="timer-ring")
    assert extras =~ "data-[state=paused]:text-warn"
  end
end
