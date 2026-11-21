defmodule LedgerUI.Components.FxFeedbackTest do
  use ExUnit.Case, async: true
  use LedgerUI
  import Phoenix.Component
  import Phoenix.LiveViewTest

  describe "progress_ring" do
    test "draws the arc by --p and the value in the centre" do
      assigns = %{}
      html = rendered_to_string(~H|<.progress_ring value={64} />|)
      assert html =~ ~s(data-part="progress-ring")
      assert html =~ "--p:64"
      assert html =~ "conic-gradient"
      assert html =~ ~s(role="progressbar")
      assert html =~ ~s(aria-valuenow="64")
      assert html =~ ">64%</span>"
    end

    test "max, size, label and color" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<.progress_ring value={3} max={4} size="lg" label="3/4" color="success" />|
        )

      assert html =~ "--p:75"
      assert html =~ "size-[72px]"
      assert html =~ ">3/4</span>"
      assert html =~ "[--ring:var(--c)]"
    end
  end

  describe "toast_card steps" do
    test "done, current and pending segments" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<.toast_card title="Lote" steps={4} step={1} dismissible={false} />|
        )

      assert length(String.split(html, ~s(data-part="toast-seg"))) - 1 == 4
      assert html =~ "bg-accent-500"
      assert html =~ "animate-[lu-pulse_1.2s_infinite]"
      assert html =~ ~s(aria-valuenow="1")
      assert html =~ ~s(aria-valuemax="4")
    end

    test "steps_loop animates each segment" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<.toast_card title="Lote" steps={5} steps_loop dismissible={false} />|
        )

      assert html =~ "animate-[lu-seg_6s_steps(1)_infinite]"
      assert html =~ "animate-[lu-seg5_6s_steps(1)_infinite]"
    end

    test "no steps, no segments" do
      assigns = %{}
      html = rendered_to_string(~H|<.toast_card title="Lote" />|)
      refute html =~ "toast-segs"
    end
  end

  describe "connection_banner preview" do
    test "draws the strip of the state, with no hooks" do
      assigns = %{}

      html =
        rendered_to_string(~H|<.connection_banner preview state="re" label="Reconectando…" />|)

      assert html =~ ~s(role="status")
      assert html =~ "bg-warn-soft"
      assert html =~ "Reconectando…"
      assert html =~ "lu-spin"
      refute html =~ "phx-disconnected"
    end

    test "cycle draws the three texts" do
      assigns = %{}
      html = rendered_to_string(~H|<.connection_banner preview state="cycle" />|)
      assert html =~ "mo-conn_9s"
      assert html =~ "mo-connt3_9s"
      assert html =~ "Reconnecting…"
    end

    test "without preview it is still the hidden hook" do
      assigns = %{}
      html = rendered_to_string(~H|<.connection_banner />|)
      assert html =~ "phx-disconnected"
      assert html =~ "hidden"
    end
  end

  describe "command_palette no_match" do
    test "the empty text and the assistant row" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.command_palette
          id="p"
          state="no_match"
          query="bolet"
          empty="Nada para bolet"
          assistant={%{label: "Ask: %{query}"}}
        />
        """)

      assert html =~ ~s(data-state="no_match")
      assert html =~ "Nada para bolet"
      assert html =~ "Ask: bolet"
      refute html =~ "phx-hook"
    end
  end

  describe "inline_empty" do
    test "dashed box, line-strong border, no background" do
      assigns = %{}
      html = rendered_to_string(~H|<.inline_empty icon="inbox" text="Nada" />|)
      assert html =~ "border-dashed"
      assert html =~ "border-line-strong"
      assert html =~ "gap-2"
      refute html =~ "bg-panel"
    end
  end

  describe "notification_center rich text" do
    test "text replaces the title and body" do
      assigns = %{
        items: [
          %{
            id: 1,
            title: "Pagamento",
            text: Phoenix.HTML.raw("Pagamento de <b>Acme</b> · R$ 3"),
            read: true
          }
        ]
      }

      html = rendered_to_string(~H|<.notification_center id="n" inline items={@items} />|)
      assert html =~ "Pagamento de <b>Acme</b> · R$ 3"
      refute html =~ ~s(data-part="notification-strong")
    end
  end

  describe "tooltip_tip" do
    test "only the bubble, with the arrow" do
      assigns = %{}

      html =
        rendered_to_string(~H|<.tooltip_tip size="md" arrow="bottom">Buscar</.tooltip_tip>|)

      assert html =~ ~s(data-part="tooltip-tip")
      assert html =~ ~s(data-part="tooltip-arrow")
      assert html =~ "bg-ink"
      refute html =~ "phx-hook"
    end

    test "no arrow by default" do
      assigns = %{}
      html = rendered_to_string(~H|<.tooltip_tip>Oi</.tooltip_tip>|)
      refute html =~ "tooltip-arrow"
    end
  end

  describe "badge dot live, count and delta" do
    test "the live dot blinks (opacity) over a static ring" do
      assigns = %{}
      html = rendered_to_string(~H|<.badge dot="live">Live</.badge>|)
      assert html =~ "animate-[mo-blink_1.4s_ease-in-out_infinite]"
      refute html =~ "lu-pulse"
    end

    test "count" do
      assigns = %{}
      html = rendered_to_string(~H|<.count tone="warning">8</.count>|)
      assert html =~ ~s(data-part="count")
      assert html =~ "rounded-[5px]"
      assert html =~ "#f59e0b"
      assert html =~ ">8</span>"
    end

    test "delta follows the trend unless the tone says otherwise" do
      assigns = %{}
      up = rendered_to_string(~H|<.delta trend="up">8.8%</.delta>|)
      down = rendered_to_string(~H|<.delta trend="down">0.4</.delta>|)
      bad = rendered_to_string(~H|<.delta trend="up" tone="error">0.4</.delta>|)
      assert up =~ "text-pos" and up =~ "border-b-current"
      assert down =~ "text-neg" and down =~ "border-t-current"
      assert bad =~ "text-neg" and bad =~ "border-b-current"
    end
  end

  describe "error_state compact" do
    test "72px gradient number, no icon, can float" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<.error_state code={404} compact float title="T" description="D" />|
        )

      assert html =~ "text-[72px]"
      assert html =~ "bg-clip-text"
      assert html =~ "mo-float"
      refute html =~ "<svg"
    end
  end
end
