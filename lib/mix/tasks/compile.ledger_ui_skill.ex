defmodule Mix.Tasks.Compile.LedgerUiSkill do
  @shortdoc "Keeps the Claude Code skill of Ledger UI in step with the installed version"

  @moduledoc """
  A Mix compiler that regenerates `.claude/skills/ledger-ui/` when the installed `ledger_ui` is not
  the version the skill was written for, so `mix deps.update ledger_ui` and a compile leave the
  skill exact. Opt in, in the host app's `mix.exs`:

      def project do
        [
          compilers: [:ledger_ui_skill] ++ Mix.compilers(),
          ...
        ]
      end

  It does nothing when the app has no skill yet (run `mix ledger_ui.install` or
  `mix ledger_ui.gen.skill` once), when the skill is already for this version, and in the `:prod`
  environment.
  """

  use Mix.Task.Compiler

  alias LedgerUI.Skill

  @impl true
  def run(_args), do: refresh(Mix.env(), Skill.default_path())

  @doc false
  def refresh(:prod, _path), do: {:noop, []}
  def refresh(_env, path), do: refresh(Skill.installed_version(path), Skill.version(), path)

  defp refresh(nil, _version, _path), do: {:noop, []}
  defp refresh(version, version, _path), do: {:noop, []}

  defp refresh(_stale, version, path) do
    files = Skill.write!(path)

    Mix.shell().info(
      "Ledger UI skill updated to #{version} (#{length(files) - 1} component references)"
    )

    {:ok, []}
  end
end
