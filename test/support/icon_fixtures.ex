defmodule LedgerUI.IconFixtures do
  @moduledoc false

  @upstream ~s(<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">\n) <>
              ~s(<path d="M17 17L21 21" stroke="#141B34" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>\n) <>
              ~s(<circle cx="11" cy="11" r="8" stroke="#141B34" stroke-width="1.5"/>\n</svg>\n)

  def upstream_svg, do: @upstream

  @doc "A tmp dir removed on exit."
  def tmp_dir(name) do
    dir = Path.join(System.tmp_dir!(), "ledger_ui_#{name}_#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    ExUnit.Callbacks.on_exit(fn -> File.rm_rf!(dir) end)
    dir
  end
end
