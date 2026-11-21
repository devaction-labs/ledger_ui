defmodule LedgerUI.Components.NotificationCenterTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.NotificationCenter

  @items [
    %{
      id: 1,
      title: "New order",
      body: "from Acme",
      at: "now",
      group: "Today",
      type: "warning",
      category: "orders"
    },
    %{id: 2, title: "Paid", at: "1 h", group: "Today", read: true, navigate: "/orders/2"},
    %{id: 3, title: "Old", at: "2 d", group: "Earlier", read: true}
  ]

  test "bell with the unread count and a hidden panel" do
    assigns = %{items: @items}

    html =
      rendered_to_string(~H|<.notification_center id="n" items={@items} on_read="read" />|)

    assert html =~ ~s(phx-hook="LedgerUI.Float")
    assert html =~ ~s(data-part="notification-bell")
    assert html =~ ~s(aria-label="Notificações")
    assert html =~ ~r/<b data-part="notification-badge"[^>]*>1<\/b>/
    assert html =~ ~s(data-lu-placement="bottom-end")
    assert html =~ "data-lu-fl"
    assert html =~ "hidden"
    assert html =~ ~s(data-lu-on-read="read")
    assert html =~ ~s(aria-controls="n-panel")
  end

  test "unread attr overrides the count; no badge when zero" do
    assigns = %{items: @items}
    html = rendered_to_string(~H|<.notification_center id="n" items={@items} unread={120} />|)
    assert html =~ "99+"
    none = rendered_to_string(~H|<.notification_center id="n" items={@items} unread={0} />|)
    refute none =~ "notification-badge"
  end

  test "canvas rows: groups once, unread tint, links" do
    assigns = %{items: @items}
    html = rendered_to_string(~H|<.notification_center id="n" items={@items} inline />|)
    assert html =~ "bg-[color-mix(in_oklab,var(--lu-accent-soft)_60%,transparent)]"
    assert html =~ ~s(<b data-part="notification-strong">New order</b>)
    assert html =~ "from Acme"
    assert length(String.split(html, "Today")) == 2
    assert html =~ "Earlier"
    assert html =~ ~s(href="/orders/2")
    assert html =~ ~s(data-lu-item="1")
    assert html =~ ~s(data-lu-cat="orders")
  end

  test "classic: title bar, tabs with unread counts, footer" do
    assigns = %{items: @items}

    html =
      rendered_to_string(~H"""
      <.notification_center
        id="n"
        items={@items}
        variant="classic"
        inline
        on_read_all="all"
        tabs={[
          %{id: "all", label: "All"},
          %{id: "unread", label: "Unread"},
          %{id: "orders", label: "Orders", empty: "No orders"}
        ]}
        all_href="/n"
        preferences_href="/prefs"
      />
      """)

    assert html =~ "Notificações"
    assert html =~ "Marcar todas como lidas"
    assert html =~ ~s(data-lu-tab="orders")
    assert html =~ ~s(data-lu-empty="No orders")
    assert html =~ ~r/data-part="notification-tab-badge" class="[^"]*bg-accent-soft[^"]*">1</
    assert html =~ ~s(href="/n")
    assert html =~ ~s(href="/prefs")
    assert html =~ "não lidas"
    # canvas has no tab bar
    canvas = rendered_to_string(~H|<.notification_center id="n" items={@items} inline />|)
    refute canvas =~ "notification-tabs"
  end

  test "empty state: icon tile, tone, text and action" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.notification_center id="n" inline items={[]} empty_tone="info" empty_icon="bell">
        <:empty_action><a href="/x">Go</a></:empty_action>
      </.notification_center>
      """)

    assert html =~ "[--c:var(--lu-info)]"
    assert html =~ "notification-empty-icon"
    assert html =~ "Nenhuma notificação"
    assert html =~ "Quando houver novidades"
    assert html =~ ~s(<a href="/x">Go</a>)
  end

  test "open and placement" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.notification_center id="n" open placement="bottom-start" />|)

    assert html =~ ~s(data-lu-placement="bottom-start")
    assert html =~ ~s(data-lu-open="true")
  end

  test "classic header: actions slot and close button, nothing by default" do
    assigns = %{items: @items}

    plain =
      rendered_to_string(
        ~H|<.notification_center id="n" items={@items} variant="classic" on_read_all="all" />|
      )

    refute plain =~ "notification-close"

    html =
      rendered_to_string(~H"""
      <.notification_center id="n" items={@items} variant="classic" closable close_label="Close">
        <:actions><a href="/prefs" aria-label="Prefs">P</a></:actions>
      </.notification_center>
      """)

    assert html =~ ~s(<a href="/prefs" aria-label="Prefs">P</a>)
    assert html =~ ~r/<button[^>]*data-part="notification-close"[^>]*aria-label="Close"/
    assert html =~ "phx-click"
    assert html =~ "remove_class"
    assert html =~ "#n [data-part=notification-bell]"
    # the actions come after the title and before the close button
    {h, a, c} =
      {pos(html, "notification-heading"), pos(html, ~s(href="/prefs")),
       pos(html, "notification-close")}

    assert h < a and a < c

    inline =
      rendered_to_string(
        ~H|<.notification_center id="n" items={@items} variant="classic" inline closable />|
      )

    refute inline =~ "notification-close"
  end

  test "bell size: md is 36px, sm is the 32px top bar button" do
    assigns = %{items: @items}
    md = rendered_to_string(~H|<.notification_center id="n" items={@items} />|)
    assert md =~ "size-9"

    sm = rendered_to_string(~H|<.notification_center id="n" items={@items} size="sm" />|)
    assert sm =~ ~r/data-part="notification-bell"\s+class="[^"]*\bsize-8\b/
    refute sm =~ "size-9"
    assert sm =~ "notification-badge"
  end

  defp pos(html, needle), do: html |> :binary.match(needle) |> elem(0)
end
