defmodule Mix.Tasks.LedgerUi.Install do
  @shortdoc "Writes Ledger UI's Claude Code skill and prints the setup lines"

  @moduledoc """
  Writes the Claude Code skill (`mix ledger_ui.gen.skill`), points `AGENTS.md` and `CLAUDE.md`
  (those that exist) at it, and prints the lines to add by hand to the CSS, the JS, the web module,
  `mix.exs` (the `:ledger_ui_skill` compiler that refreshes the skill on every package update)
  and the config (the vendored icons). Running it twice changes nothing the second time.

      mix ledger_ui.install

  It edits no source file besides appending the pointer to the agent files, and needs no extra
  dependency.
  """

  use Mix.Task

  @impl true
  def run(_args) do
    Mix.Task.run("ledger_ui.gen.skill", [])
    Enum.each(~w(AGENTS.md CLAUDE.md), &point/1)
    Mix.shell().info(instructions())
  end

  defp point(file) do
    case File.read(file) do
      {:ok, contents} -> append_once(file, contents)
      {:error, :enoent} -> :ok
    end
  end

  defp append_once(file, contents) do
    unless String.contains?(contents, LedgerUI.Skill.marker()) do
      File.write!(file, String.trim_trailing(contents) <> "\n\n" <> LedgerUI.Skill.pointer())
    end
  end

  @doc false
  def instructions do
    """

    Finish the setup by hand (once):

      assets/css/app.css:
        @import "tailwindcss";
        @import "../../deps/ledger_ui/assets/css/ledger_ui.css";   /* after tailwindcss */

      assets/js/app.js:
        import {Hooks as LedgerHooks, DOM as LedgerDOM} from "ledger_ui"
        // LiveSocket options:
        //   hooks: {...colocatedHooks, ...LedgerHooks},
        //   dom: {onBeforeElUpdated(from, to) { LedgerDOM.onBeforeElUpdated(from, to) }}

      lib/<app>_web.ex, in html_helpers/0:
        use LedgerUI

      mix.exs, in project/0 (keeps the skill in step with the installed version):
        compilers: [:ledger_ui_skill] ++ Mix.compilers()

    Optional, Hugeicons Stroke Rounded beyond the built-in icons:

      config/config.exs:
        config :ledger_ui, :icons_path, "priv/hugeicons"

      then download the icons your sources use:
        mix ledger_ui.icons sync
    """
  end
end
