defmodule Mix.Tasks.LedgerUi.Gen.Skill do
  @shortdoc "Writes the Claude Code skill for the installed Ledger UI"

  @moduledoc """
  Writes `.claude/skills/ledger-ui/`: a short `SKILL.md` index and one reference per component,
  generated from the installed package's attrs, slots and docs.

      mix ledger_ui.gen.skill
      mix ledger_ui.gen.skill --path priv/skills/ledger-ui

  Files of a previous run are replaced, and references of components that no longer exist are
  removed, so running it after an upgrade keeps the skill exact. To have it refreshed on its own,
  add the compiler (see `Mix.Tasks.Compile.LedgerUiSkill`).
  """

  use Mix.Task

  @impl true
  def run(args) do
    {opts, _rest} = OptionParser.parse!(args, strict: [path: :string])
    path = Keyword.get(opts, :path, LedgerUI.Skill.default_path())

    Mix.Task.run("app.config")
    {:ok, _} = Application.ensure_all_started(:ledger_ui)

    files = LedgerUI.Skill.write!(path)

    Mix.shell().info(
      "Ledger UI skill written to #{path} (#{length(files) - 1} component references)"
    )
  end
end
