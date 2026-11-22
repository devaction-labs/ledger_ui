defmodule LedgerUI.Components.ConnectionBannerTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.ConnectionBanner

  test "draws nothing, binds disconnected/connected to the toaster" do
    assigns = %{}
    html = rendered_to_string(~H|<.connection_banner />|)
    assert html =~ ~s(id="ledger-connection-banner")
    assert html =~ ~s(data-part="connection-banner")
    assert html =~ "hidden"
    assert html =~ "phx-disconnected"
    assert html =~ "phx-connected"
    assert html =~ "Connection lost"
    assert html =~ "Trying to reconnect..."
    assert html =~ "ledger:toast"
    assert html =~ "warning"
  end

  test "custom texts, colour and id" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.connection_banner id="cb" title="Sem conexão" description="Tentando" color="error" />|
      )

    assert html =~ "Sem conexão"
    assert html =~ "Tentando"
    assert html =~ "error"
    assert html =~ ~s(id="cb")
  end

  test "position puts the toast at the top or the bottom centre" do
    assigns = %{}
    top = rendered_to_string(~H|<.connection_banner position="top" />|)
    bottom = rendered_to_string(~H|<.connection_banner position="bottom" />|)
    none = rendered_to_string(~H|<.connection_banner />|)
    assert top =~ "center-top"
    assert bottom =~ "center-bottom"
    refute none =~ "center-"
  end
end
