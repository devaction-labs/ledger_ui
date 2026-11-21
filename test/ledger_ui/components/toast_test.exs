defmodule LedgerUI.Components.ToastTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Toast

  alias Phoenix.LiveView.{JS, Socket}

  defp socket, do: %Socket{assigns: %{flash: %{}, __changed__: %{}}}

  describe "toaster" do
    test "renders static toasts given in the block inside the stack" do
      assigns = %{}
      html = rendered_to_string(~H|<.toaster>
  <div id="t1">hi</div>
</.toaster>|)
      assert html =~ ~r/data-part="toast-stack".*<div id="t1">hi<\/div>/s
    end

    test "renders the hook, the position and an empty client-owned stack" do
      assigns = %{}
      html = rendered_to_string(~H|<.toaster />|)
      assert html =~ ~s(id="ledger-toaster")
      assert html =~ ~s(phx-hook="LedgerUI.Toaster")
      assert html =~ ~s(data-pos="center-bottom")
      assert html =~ ~s(phx-update="ignore")
      assert html =~ ~s(data-part="toaster")
      assert html =~ "fixed inset-0"
      assert html =~ "pointer-events-none"
      refute html =~ "data-lu-flash"
    end

    test "the class strings of the toasts the hook draws travel in data-lu-cls" do
      assigns = %{}
      html = rendered_to_string(~H|<.toaster />|)
      [_, json] = Regex.run(~r/data-lu-cls="([^"]*)"/, html)

      cls =
        json |> String.replace("&quot;", "\"") |> String.replace("&amp;", "&") |> Jason.decode!()

      for key <-
            ~w(card light dark fail tile body close fill pct segs spinner buttons aura stoast act dot_ok st_auto st_liquid),
          do: assert(Map.has_key?(cls, key), key)

      assert cls["card"] =~ "rounded-[14px]"
      assert cls["aura"]["modes"]["spin"] =~ "overflow-hidden"
      assert cls["buttons"]["primary:outline"] =~ "[--c:var(--color-accent)]"
      assert cls["colors"]["success"] =~ "[--c:var(--lu-pos)]"
    end

    test "contained mode draws no fixed style and only non-default settings are rendered" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<.toaster contained duration={8000} stack={false} invert persist_errors position="right-top" />|
        )

      refute html =~ "fixed inset-0"
      assert html =~ "overflow-hidden"
      assert html =~ "top-4 right-4"
      assert html =~ ~s(data-lu-duration="8000")
      assert html =~ ~s(data-lu-stack="false")
      assert html =~ ~s(data-lu-invert="true")
      assert html =~ ~s(data-lu-persist-errors="true")
      assert html =~ ~s(data-pos="right-top")
      refute html =~ "data-lu-timer"
    end

    test "reads put_toast and the standard flash messages" do
      flash = %{
        "info" => "Saved",
        "error" => "Boom",
        "ledger_toast" => Jason.encode!([%{"title" => "Hi", "_k" => "k1"}])
      }

      assigns = %{flash: flash}
      html = rendered_to_string(~H|<.toaster flash={@flash} />|)
      [_, json] = Regex.run(~r/data-lu-flash="([^"]*)"/, html)

      list =
        json
        |> Phoenix.HTML.html_escape()
        |> then(fn _ -> String.replace(json, "&quot;", "\"") end)
        |> Jason.decode!()

      assert Enum.map(list, & &1["title"]) |> Enum.sort() == ["Boom", "Hi", "Saved"]
      assert Enum.find(list, &(&1["title"] == "Boom"))["kind"] == "error"
    end
  end

  describe "server API" do
    test "send_toast pushes a show event with a normalized payload" do
      s =
        send_toast(socket(), "Copied", color: :info, position: "center-top", duration: :infinity)

      assert [["ledger:toast", payload]] = s.private.live_temp.push_events

      assert %{"op" => "show", "title" => "Copied", "color" => "info", "duration" => "infinity"} =
               payload

      assert payload["id"] =~ "toast-"
    end

    test "actions are normalized and unknown keys dropped" do
      js = JS.push("undo")

      s =
        send_toast(socket(), "x",
          kind: :success,
          bogus: 1,
          actions: [
            [label: "Undo", event: "undo", value: %{id: 1}, js: js, variant: :solid, nope: 1]
          ]
        )

      [["ledger:toast", payload]] = s.private.live_temp.push_events
      refute Map.has_key?(payload, "bogus")
      [action] = payload["actions"]

      assert %{"label" => "Undo", "event" => "undo", "variant" => "solid", "value" => %{id: 1}} =
               action

      assert is_binary(action["js"])
      refute Map.has_key?(action, "nope")
    end

    test "send_toast accepts only options with title" do
      s = send_toast(socket(), id: "x", kind: :loading, title: "Working…")
      [["ledger:toast", payload]] = s.private.live_temp.push_events
      assert %{"id" => "x", "kind" => "loading", "title" => "Working…"} = payload
    end

    test "update, dismiss and clear" do
      s = socket() |> update_toast("nfe", value: 64) |> dismiss_toast("nfe") |> clear_toasts()
      events = Enum.reverse(s.private.live_temp.push_events)
      ops = Enum.map(events, fn ["ledger:toast", p] -> p["op"] end)
      assert ops == ["update", "dismiss", "clear"]
      [["ledger:toast", update] | _] = events
      assert %{"id" => "nfe", "value" => 64} = update
    end

    test "put_toast accumulates in the socket flash" do
      s = socket() |> put_toast("One", color: "success") |> put_toast("Two")
      list = s.assigns.flash |> Map.fetch!("ledger_toast") |> Jason.decode!()
      assert Enum.map(list, & &1["title"]) == ["One", "Two"]
    end

    test "put_toast on a conn goes through the flash" do
      conn =
        Plug.Test.conn(:get, "/")
        |> Plug.Test.init_test_session(%{})
        |> Phoenix.Controller.fetch_flash()
        |> put_toast("Saved", color: "success")

      assert [%{"title" => "Saved", "color" => "success"}] =
               conn.assigns.flash |> Map.fetch!("ledger_toast") |> Jason.decode!()
    end
  end

  describe "browser commands" do
    test "show_toast dispatches the event to the toaster" do
      assert %JS{
               ops: [
                 ["dispatch", %{event: "ledger:toast", to: "#ledger-toaster", detail: detail}]
               ]
             } =
               show_toast("Copied", color: "info")

      assert %{"op" => "show", "title" => "Copied", "color" => "info"} = detail
    end

    test "show_toast/3 chains and honours `to`" do
      js = show_toast(JS.push("x"), "Hi", to: "#other")
      assert [["push", _], ["dispatch", %{to: "#other"}]] = js.ops
      assert %JS{ops: [["dispatch", _]]} = show_toast(%JS{}, "Hi")
    end

    test "dismiss_toast as JS" do
      assert %JS{ops: [["dispatch", %{detail: %{"op" => "dismiss", "id" => "a"}}]]} =
               dismiss_toast("a")

      assert %JS{ops: [["push", _], ["dispatch", _]]} = dismiss_toast(JS.push("x"), "a")
    end
  end

  describe "toast_card" do
    test "kind, tone, icon, description and close" do
      assigns = %{}

      html =
        rendered_to_string(~H|<.toast_card
  kind="error"
  tone="dark"
  icon="x-circle"
  title="T"
  description="D"
  close_label="Fechar"
/>|)

      for c <- [
            ~s(data-part="toast-card"),
            "[--c:var(--lu-neg)]",
            "bg-navy",
            ~s(data-part="toast-title">T</b>),
            ~s(data-part="toast-description"),
            ~s(aria-label="Fechar"),
            ~s(data-part="toast-tile"),
            "bg-[rgba(255,255,255,.1)]"
          ],
          do: assert(html =~ c)
    end

    test "progress states" do
      assigns = %{}
      run = rendered_to_string(~H|<.toast_card title="T" progress={42} />|)
      assert run =~ "scaleX(.42)"
      assert run =~ "42%"
      assert run =~ ~s(data-part="spinner")

      done =
        rendered_to_string(~H|<.toast_card title="T" progress={100} progress_state="done" />|)

      assert done =~ "[--c:var(--lu-pos)]"
      assert done =~ "transform:none"
      assert done =~ "100%"
      fail = rendered_to_string(~H|<.toast_card title="T" progress={10} progress_state="fail" />|)
      assert fail =~ "[--c:var(--lu-neg)]"
      assert fail =~ "bg-neg-soft"
      refute fail =~ ~s(data-part="spinner")
      refute fail =~ "toast-pct"
    end

    test "aura wraps the card; dismissible false drops the close button" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<.toast_card title="T" aura="dual" aura_tone="ai" aura_width="lg" busy dismissible={false} />|
        )

      assert html =~ ~s(data-part="toast-aura")
      assert html =~ "var(--a2)_72%"
      assert html =~ "[--t1:var(--lu-ai-1)]"
      assert html =~ "[--w:2px]"
      assert html =~ "[--r:15px]"
      assert html =~ ~s(data-part="spinner")
      refute html =~ "toast-close"
    end

    test "actions and busy label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toast_card title="T" busy busy_label="Working">
          <:action><button>Go</button></:action>
        </.toast_card>
        """)

      assert html =~ "<button>Go</button>"
      assert html =~ ~s(aria-label="Working")
    end
  end

  describe "status_toast" do
    test "states, percent and actions" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.status_toast state="run" percent={64}>
          Building <b>x</b>
          <:action ghost>Logs</:action>
          <:action patch="/logs" id="l">See</:action>
        </.status_toast>
        """)

      for c <- [
            ~s(data-part="status-toast"),
            ~s(role="status"),
            "--lu-stp:64%",
            "bg-[#0a0a0a]",
            "text-[#c9c9ce]",
            ~s(href="/logs"),
            "Building"
          ],
          do: assert(html =~ c)

      assigns = %{}

      assert rendered_to_string(~H|<.status_toast state="queue">q</.status_toast>|) =~
               "border-dashed"

      assert rendered_to_string(~H|<.status_toast state="run">q</.status_toast>|) =~
               "lu-st-fill_3.2s"

      assert rendered_to_string(~H|<.status_toast state="ok">q</.status_toast>|) =~ "bg-[#22c55e]"

      assert rendered_to_string(~H|<.status_toast state="err">q</.status_toast>|) =~
               "bg-[#ef4444]"
    end
  end
end
