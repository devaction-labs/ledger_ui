defmodule LedgerUI.Components.IconTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Icon
  import ExUnit.CaptureLog

  doctest LedgerUI.Components.Icon

  test "renders hydrate-equivalent svg" do
    assigns = %{}
    html = rendered_to_string(~H|<.icon name="download" />|)

    assert html =~
             ~s(<svg class="lu-i" viewBox="0 0 24 24" aria-hidden="true" data-icon="download"><path)

    assert String.ends_with?(html, "</svg>")
  end

  test "size, class and rest" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.icon name="check" size="sm" class="x" id="i1" aria-label="ok" />|)

    assert html =~ ~s(<svg class="lu-i sm x" viewBox)
    assert html =~ ~s(id="i1")
    assert html =~ ~s(aria-label="ok")
  end

  test "huge-* names" do
    assigns = %{}
    assert resolve("huge-download-01") == "download"
    assert resolve("hugeicons:home") == "home"
    assert resolve("download") == "download"
    assert resolve("huge-zzz-99") == nil
    assert rendered_to_string(~H|<.icon name="huge-download-01" />|) =~ ~s(data-icon="download")
  end

  test "unknown renders nothing and warns" do
    assigns = %{}

    log =
      capture_log(fn ->
        assert rendered_to_string(~H|<.icon name="zzz" />|) == ""
      end)

    assert log =~ "icon not found"
  end

  test "boxed with tone and size" do
    assigns = %{}
    html = rendered_to_string(~H|<.icon name="check" boxed tone="success" box_size="lg" />|)
    assert html =~ ~s(<span data-part="icon-box" class="lu-ic pos lg")
    assert html =~ ~s(data-icon="check")
    html = rendered_to_string(~H|<.icon boxed box_size="30"><b>x</b></.icon>|)
    assert html =~ "width:30px;height:30px"
    assert html =~ "<b>x</b>"
  end

  test "icon dictionary is complete" do
    assert length(names()) == 141
  end
end
