defmodule Mix.Tasks.LedgerUi.IconsTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.LedgerUi.Icons
  import LedgerUI.IconFixtures

  @moduletag :capture_log

  setup do
    Mix.shell(Mix.Shell.Process)
    on_exit(fn -> Mix.shell(Mix.Shell.IO) end)

    dir = tmp_dir("task_icons")
    {:ok, dir: Path.join(dir, "hugeicons"), root: dir}
  end

  # An offline stand-in for the GitHub requests; records the urls it was asked for.
  defp http(test_pid \\ self()) do
    fn url ->
      send(test_pid, {:http, url})

      cond do
        url =~ "/icons/missing" -> {:error, :not_found}
        url =~ "/icons/boom" -> {:error, :timeout}
        url =~ "/icons/" -> {:ok, upstream_svg()}
        url =~ "LICENSE.md" -> {:ok, "MIT License"}
        url =~ "/commits/" -> {:ok, ~s({"sha": "#{String.duplicate("a", 40)}"})}
        url =~ "/git/trees/" -> {:ok, tree(["search-01", "search-02", "tick-02"])}
      end
    end
  end

  defp tree(names) do
    Jason.encode!(%{
      "tree" => [%{"path" => "README.md"} | for(n <- names, do: %{"path" => "icons/#{n}.svg"})]
    })
  end

  defp ctx(dir, extra \\ %{}) do
    Map.merge(
      %{dir: dir, ref: "testref", prune: false, roots: [], http: http(), cache: false},
      extra
    )
  end

  test "get downloads, converts, writes manifest and license", %{dir: dir} do
    assert :ok = Icons.command(["get", "huge-search-01", "TICK-02.svg"], ctx(dir))

    assert Icons.vendored(dir) == ["search-01", "tick-02"]
    svg = File.read!(Path.join(dir, "search-01.svg"))
    assert svg =~ ~s(stroke="currentColor")
    assert svg =~ ~s(<path d="M17 17L21 21"/>)
    refute svg =~ "141B34"

    assert File.read!(Path.join(dir, "LICENSE.md")) == "MIT License"
    manifest = Icons.manifest(dir)
    assert manifest["ref"] == "testref"
    assert manifest["names"] == ["search-01", "tick-02"]
    assert manifest["source"] == "https://github.com/hugeicons/hugeicons"

    assert_received {:http,
                     "https://raw.githubusercontent.com/hugeicons/hugeicons/testref/icons/search-01.svg"}

    assert Path.wildcard(Path.join(dir, "*.tmp-*")) == []
  end

  test "get raises on an unknown icon and suggests names", %{dir: dir} do
    assert_raise Mix.Error, ~r/Unknown icons: missing/, fn ->
      Icons.command(["get", "missing"], ctx(dir))
    end

    assert_received {:mix_shell, :error, [msg]}
    assert msg =~ ~s(Unknown icon "huge-missing")
  end

  test "a network failure raises and writes nothing for that icon", %{dir: dir} do
    assert_raise Mix.Error, ~r/boom/, fn -> Icons.command(["get", "boom"], ctx(dir)) end
    assert Icons.vendored(dir) == []
  end

  test "get with a bad name raises", %{dir: dir} do
    assert_raise Mix.Error, ~r/Not an icon name/, fn ->
      Icons.command(["get", "../etc/passwd"], ctx(dir))
    end
  end

  test "sync downloads only the missing, non built-in names from the sources", %{
    dir: dir,
    root: root
  } do
    src = Path.join(root, "lib")
    File.mkdir_p!(src)

    File.write!(Path.join(src, "page.heex"), """
    <.icon name="download" />
    <.icon name="huge-search-01" />
    <.icon name="huge-tick-02" />
    <.icon name="missing-01" />
    """)

    assert :ok = Icons.command(["sync"], ctx(dir, %{roots: [src]}))
    # `download` is built-in; `missing-01` is unknown upstream but not fatal
    assert Icons.vendored(dir) == ["search-01", "tick-02"]
    assert_received {:mix_shell, :info, ["3 non built-in icon names" <> _]}

    # second run: nothing missing except the still unknown one
    assert :ok = Icons.command(["sync"], ctx(dir, %{roots: [src]}))
    assert Icons.manifest(dir)["names"] == ["search-01", "tick-02"]
  end

  test "sync --prune removes icons no source uses and refuses an empty scan", %{
    dir: dir,
    root: root
  } do
    Icons.command(["get", "search-01", "tick-02"], ctx(dir))
    src = Path.join(root, "lib")
    File.mkdir_p!(src)
    File.write!(Path.join(src, "a.heex"), ~s(<.icon name="huge-search-01" />))

    Icons.command(["sync"], ctx(dir, %{roots: [src], prune: true}))
    assert Icons.vendored(dir) == ["search-01"]
    assert Icons.manifest(dir)["names"] == ["search-01"]

    assert_raise Mix.Error, ~r/refusing to prune/, fn ->
      Icons.command(["sync"], ctx(dir, %{roots: [], prune: true}))
    end
  end

  test "search lists upstream names", %{dir: dir} do
    Icons.command(["search", "search"], ctx(dir))
    assert_received {:mix_shell, :info, ["huge-search-01"]}
    assert_received {:mix_shell, :info, ["huge-search-02"]}
    refute_received {:mix_shell, :info, ["huge-tick-02"]}
  end

  test "update resolves the ref to a commit and re-downloads what is vendored", %{dir: dir} do
    Icons.command(["get", "search-01"], ctx(dir))
    File.write!(Path.join(dir, "search-01.svg"), "stale")

    assert :ok = Icons.command(["update"], ctx(dir, %{ref: "main"}))

    sha = String.duplicate("a", 40)
    assert Icons.manifest(dir)["ref"] == sha
    assert File.read!(Path.join(dir, "search-01.svg")) =~ "<path"
    assert_received {:http, "https://api.github.com/repos/hugeicons/hugeicons/commits/main"}
    assert_received {:http, "https://raw.githubusercontent.com/hugeicons/hugeicons/" <> _}
  end

  test "update on an empty folder says so", %{dir: dir} do
    Icons.command(["update"], ctx(dir, %{ref: String.duplicate("b", 40)}))
    assert_received {:mix_shell, :info, ["Nothing vendored" <> _]}
  end

  test "unknown subcommand shows usage", %{dir: dir} do
    assert_raise Mix.Error, ~r/Usage/, fn -> Icons.command(["nope"], ctx(dir)) end
  end

  test "parse_tree and suggestions" do
    assert {:ok, ["a", "b"]} = Icons.parse_tree(tree(["b", "a"]))

    assert {:error, {:unexpected_response, "Not Found"}} =
             Icons.parse_tree(~s({"message":"Not Found"}))

    assert Icons.suggestions("search", ["search-01", "tick", "sarch"]) |> hd() == "search-01"
  end
end
