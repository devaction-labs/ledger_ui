defmodule LedgerUI.Components.UploadTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Upload

  defp r(h), do: rendered_to_string(h)

  describe "upload_file in the done state" do
    test "without on_remove only the check is drawn" do
      assigns = %{}
      html = r(~H|<.upload_file name="a.pdf" state="done" ref="3" />|)

      assert html =~ ~s(data-part="upload-file-done")
      refute html =~ "upload-file-remove"
    end

    test "with on_remove the check and the remove button are drawn" do
      assigns = %{}
      html = r(~H|<.upload_file name="a.pdf" state="done" ref="3" on_remove="rm" />|)

      assert html =~ ~s(data-part="upload-file-done")
      assert html =~ ~s(data-part="upload-file-remove")
      assert html =~ ~s(phx-click="rm")
      assert html =~ ~s(phx-value-ref="3")
      assert html =~ ~s(aria-label="Remove")
    end
  end

  test "upload/1 gives a finished entry the remove button" do
    entry = %Phoenix.LiveView.UploadEntry{
      ref: "7",
      client_name: "nfe.xml",
      client_size: 1024,
      client_type: "text/xml",
      progress: 100,
      done?: true,
      valid?: true
    }

    config = %Phoenix.LiveView.UploadConfig{
      name: :docs,
      ref: "phx-upl",
      max_entries: 2,
      entries: [entry]
    }

    assigns = %{config: config}
    html = r(~H|<.upload upload={@config} on_cancel="cancel" />|)

    assert html =~ ~s(data-part="upload-file-done")
    assert html =~ ~s(data-part="upload-file-remove")
    assert html =~ ~s(phx-click="cancel")
    assert html =~ ~s(phx-value-ref="7")
  end
end
