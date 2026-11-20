defmodule LedgerUI.SkillTest do
  # File.cd!/1 and Mix.shell/1 are global.
  use ExUnit.Case, async: false

  alias LedgerUI.{Docs, Skill}
  alias Mix.Tasks.Compile.LedgerUiSkill
  import LedgerUI.IconFixtures

  @moduletag :capture_log

  setup_all do
    {:ok, files: Map.new(Skill.files())}
  end

  test "Docs lists every module with function components", _ do
    components = Docs.components()
    keys = Enum.map(components, & &1.key)
    assert "badge" in keys and "button" in keys and "icon" in keys
    assert keys == Enum.sort(keys)
    assert Docs.key(LedgerUI.Components.ActionMenu) == "action_menu"
  end

  test "SKILL.md names the skill, the version and links every reference", %{files: files} do
    skill = files["SKILL.md"]
    version = Skill.version()

    assert skill =~ "name: ledger-ui"
    assert skill =~ "# LedgerUI #{version}"
    assert skill =~ "HEEx/LiveView"
    assert skill =~ "field={@form[:name]}"
    assert skill =~ "LedgerUI.open"
    assert skill =~ "mix ledger_ui.icons sync"
    assert skill =~ "data-theme"
    assert skill =~ "[badge.md](references/badge.md)"
    assert skill =~ "`<.badge>`"

    for {"references/" <> _ = path, _} <- files do
      assert skill =~ "(#{path})"
    end
  end

  test "a reference documents attrs with type, default, values, doc and slots", %{files: files} do
    badge = files["references/badge.md"]
    assert badge =~ "# LedgerUI.Components.Badge"
    assert badge =~ "## `<.badge>`"

    assert badge =~
             ~s(| `variant` | `:string` | `"soft"` | `solid`, `glow`, `soft`, `outline`, `flat` |)

    assert badge =~ "| `dot` | `:any` | `false` | A dot before the content;"
    assert badge =~ "- `<:inner_block>` (required)"
    assert badge =~ "<.badge color=\"success\" shape=\"pill\">Paid</.badge>"
    refute badge =~ "## Attributes"

    icon = files["references/icon.md"]
    assert icon =~ "## Vendored icons"
    assert icon =~ "`<.icon>`" or icon =~ "## `<.icon>`"
  end

  test "required attrs and slot attrs are marked" do
    all = Skill.files() |> Enum.map_join("\n", &elem(&1, 1))
    assert all =~ "(required)"
    assert all =~ " - attrs: "
  end

  test "write! writes the files and drops stale references" do
    dir = tmp_dir("skill")
    stale = Path.join(dir, "references/gone.md")
    File.mkdir_p!(Path.dirname(stale))
    File.write!(stale, "old")

    files = Skill.write!(dir)
    assert File.exists?(Path.join(dir, "SKILL.md"))
    assert File.exists?(Path.join(dir, "references/badge.md"))
    refute File.exists?(stale)
    assert length(files) > 100
    assert Skill.installed_version(dir) == Skill.version()
  end

  test "installed_version is nil without a SKILL.md" do
    assert Skill.installed_version(tmp_dir("empty")) == nil
  end

  describe "compiler refresh" do
    test "does nothing without a skill, when current, and in prod" do
      dir = tmp_dir("refresh")
      assert {:noop, []} = LedgerUiSkill.refresh(:dev, dir)
      refute File.exists?(Path.join(dir, "SKILL.md"))

      Skill.write!(dir)
      File.write!(Path.join(dir, "references/badge.md"), "edited")
      assert {:noop, []} = LedgerUiSkill.refresh(:dev, dir)
      assert File.read!(Path.join(dir, "references/badge.md")) == "edited"

      File.write!(Path.join(dir, "SKILL.md"), "# LedgerUI 0.0.1\n")
      assert {:noop, []} = LedgerUiSkill.refresh(:prod, dir)
      assert Skill.installed_version(dir) == "0.0.1"
    end

    test "regenerates when the recorded version differs" do
      dir = tmp_dir("refresh_stale")
      Skill.write!(dir)
      File.write!(Path.join(dir, "SKILL.md"), "# LedgerUI 0.0.1\n")
      File.write!(Path.join(dir, "references/badge.md"), "stale")

      Mix.shell(Mix.Shell.Process)
      assert {:ok, []} = LedgerUiSkill.refresh(:dev, dir)
      assert_received {:mix_shell, :info, ["Ledger UI skill updated to" <> _]}
      Mix.shell(Mix.Shell.IO)

      assert Skill.installed_version(dir) == Skill.version()
      assert File.read!(Path.join(dir, "references/badge.md")) =~ "# LedgerUI.Components.Badge"
    end
  end

  test "install points AGENTS.md at the skill once, and prints setup lines" do
    in_tmp = tmp_dir("install")

    File.cd!(in_tmp, fn ->
      Mix.shell(Mix.Shell.Process)
      File.write!("AGENTS.md", "# Agents\n")
      Mix.Tasks.LedgerUi.Install.run([])
      Mix.Tasks.LedgerUi.Install.run([])

      assert File.exists?(".claude/skills/ledger-ui/SKILL.md")
      agents = File.read!("AGENTS.md")
      assert agents =~ ".claude/skills/ledger-ui/SKILL.md"
      assert length(String.split(agents, Skill.marker())) == 2
      refute File.exists?("CLAUDE.md")
    end)

    Mix.shell(Mix.Shell.IO)
    assert Mix.Tasks.LedgerUi.Install.instructions() =~ "compilers: [:ledger_ui_skill]"
  end
end
