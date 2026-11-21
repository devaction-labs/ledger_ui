defmodule LedgerUI.IconsTest do
  # Mutates application env and :persistent_term.
  use ExUnit.Case, async: false

  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Icon
  import LedgerUI.IconFixtures
  import ExUnit.CaptureLog

  alias LedgerUI.Icons.Hugeicons

  setup do
    dir = tmp_dir("icons")
    Application.put_env(:ledger_ui, :icons_path, dir)

    on_exit(fn ->
      LedgerUI.Icons.reload()
      Application.delete_env(:ledger_ui, :icons_path)
    end)

    {:ok, dir: dir}
  end

  defp vendor(dir, name, svg \\ upstream_svg()) do
    {:ok, inner} = Hugeicons.convert(svg)
    File.write!(Path.join(dir, name <> ".svg"), Hugeicons.wrap(inner))
  end

  defp html(name) do
    assigns = %{name: name}
    rendered_to_string(~H|<.icon name={@name} size="sm" />|)
  end

  test "a vendored icon renders the same markup as a built-in one", %{dir: dir} do
    vendor(dir, "search-01")

    assert html("huge-search-01") ==
             ~s(<svg class="inline flex-none fill-none stroke-current stroke-[1.5] [stroke-linecap:round] [stroke-linejoin:round] align-middle size-3.5") <>
               ~s( viewBox="0 0 24 24" aria-hidden="true" data-icon="search-01">) <>
               ~s(<path d="M17 17L21 21"/><circle cx="11" cy="11" r="8"/></svg>)

    assert html("search-01") == html("huge-search-01")
    assert html("hugeicons:search-01") == html("huge-search-01")
    assert LedgerUI.Icons.names() == ["search-01"]
  end

  test "built-in names win over a vendored file of the same name", %{dir: dir} do
    vendor(dir, "download")
    assert html("download") =~ ~s(data-icon="download")
    refute html("download") =~ "circle"
  end

  test "huge-NN prefers the vendored file over the suffix-stripped built-in", %{dir: dir} do
    assert html("huge-download-01") =~ ~s(data-icon="download")
    refute html("huge-download-01") =~ "circle"

    vendor(dir, "download-01")
    assert html("huge-download-01") =~ ~s(data-icon="download-01")
    assert html("huge-download-01") =~ "circle"
  end

  test "an unknown name still warns and renders nothing" do
    log = capture_log(fn -> assert html("huge-nope-99") == "" end)
    assert log =~ "LedgerUI icon not found"
  end

  test "icons vendored after the first load are found without a restart", %{dir: dir} do
    vendor(dir, "a-01")
    assert html("a-01") =~ "circle"

    capture_log(fn -> assert html("b-02") == "" end)
    vendor(dir, "b-02")
    assert html("b-02") =~ ~s(data-icon="b-02")
  end

  test "without :icons_path only built-ins resolve" do
    Application.delete_env(:ledger_ui, :icons_path)
    assert LedgerUI.Icons.fetch("zzz-01") == nil
    assert LedgerUI.Icons.names() == []
    assert html("huge-search-01") =~ ~s(data-icon="search")
    capture_log(fn -> assert html("huge-zzz-01") == "" end)
  end

  test "{app, path} resolves inside the app dir" do
    Application.put_env(:ledger_ui, :icons_path, {:ledger_ui, "priv/hugeicons"})
    assert LedgerUI.Icons.path() == Path.join(Application.app_dir(:ledger_ui), "priv/hugeicons")
  end

  test "files with a bad name or no shapes are ignored", %{dir: dir} do
    File.write!(Path.join(dir, "Bad Name.svg"), upstream_svg())
    File.write!(Path.join(dir, "empty-01.svg"), "<svg></svg>")
    vendor(dir, "ok-01")
    assert LedgerUI.Icons.names() == ["ok-01"]
  end

  test "builtin?/1" do
    assert builtin?("download")
    assert builtin?("huge-download")
    refute builtin?("search-01")
  end
end
