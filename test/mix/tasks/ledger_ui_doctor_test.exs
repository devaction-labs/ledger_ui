defmodule Mix.Tasks.LedgerUi.DoctorTest do
  use ExUnit.Case, async: false

  alias Mix.Tasks.LedgerUi.Doctor

  @moduletag :capture_log

  @fixtures Path.expand("../../fixtures", __DIR__)
  @app Path.join(@fixtures, "doctor_app")
  @clean Path.join(@fixtures, "doctor_clean_app")

  setup do
    Mix.shell(Mix.Shell.Process)
    on_exit(fn -> Mix.shell(Mix.Shell.IO) end)
    {:ok, findings: Doctor.scan(@app)}
  end

  # The line of the first occurrence of `marker` in `file` of the fixture app.
  defp line(file, marker) do
    @app
    |> Path.join(file)
    |> File.read!()
    |> String.split("\n")
    |> Enum.find_index(&String.contains?(&1, marker))
    |> Kernel.+(1)
  end

  defp at(findings, code, file, marker) do
    l = line(file, marker)

    assert Enum.any?(findings, &(&1.code == code and &1.file == file and &1.line == l)),
           "no #{code} at #{file}:#{l} (#{marker}); got " <>
             inspect(for(f <- findings, f.code == code, do: {f.file, f.line}))
  end

  @live "lib/my_app_web/live/items_live.ex"
  @wrap "lib/my_app_web/components/wrappers.ex"

  test "locale equal to the app config", %{findings: f} do
    at(f, :locale_redundant, @live, ~s(locale="pt_BR"))
  end

  test "labels equal to the kit text, in the select, the chip and the palette", %{findings: f} do
    at(f, :label_redundant, @live, "no_results=")
    at(f, :label_redundant, @live, "remove_label=")
    at(f, :label_redundant, @live, "command_palette")
  end

  test "whitespace-normal! in a cell and [&_th] selectors", %{findings: f} do
    at(f, :cell_wrap, @live, "whitespace-normal!")
    at(f, :flat_table, @live, "[&_th]")
  end

  test "{@rest} and {assigns} spread onto a kit component", %{findings: f} do
    at(f, :wrapper_spread, @wrap, ~s(<.badge variant="soft" {@rest}>))
    at(f, :wrapper_spread, @wrap, "<.input field={@field} {assigns} />")
  end

  test ":for without :key, table without row_id, palette without defer_items", %{findings: f} do
    at(f, :for_without_key, @live, "<.chip :for=")
    at(f, :table_without_row_id, @live, "<.table id=")
    at(f, :palette_without_defer_items, @live, "<.command_palette")

    refute Enum.any?(f, &(&1.code == :for_without_key and &1.line == line(@live, "<.badge :for")))
  end

  test "wrappers of components left out by use LedgerUI, except:", %{findings: f} do
    at(f, :shadowed_component, @wrap, "def badge(assigns)")
    at(f, :shadowed_component, @wrap, "def input(assigns)")
    at(f, :shadowed_component, @wrap, "def pagination(assigns)")

    msg =
      Enum.find(f, &(&1.code == :shadowed_component and &1.line == line(@wrap, "def input"))).message

    assert msg =~ "error_translator"

    refute Enum.find(f, &(&1.code == :shadowed_component and &1.line == line(@wrap, "def badge"))).message =~
             "error_translator"
  end

  test "an error_translator in the config silences the hint for the fields" do
    f = Doctor.scan(@app, error_translator: true)

    msg =
      Enum.find(f, &(&1.code == :shadowed_component and &1.line == line(@wrap, "def input"))).message

    refute msg =~ "error_translator"
  end

  test "endpoint without compress: true", %{findings: f} do
    at(f, :endpoint_without_compress, "lib/my_app_web/endpoint.ex", ~s(socket "/live"))
  end

  test "app.js importing the whole bundle lists the hooks the app does not use", %{findings: f} do
    finding = Enum.find(f, &(&1.code == :js_full_import))
    assert finding.file == "assets/js/app.js"
    assert finding.line == 2
    assert finding.message =~ "ledger_ui/core"
    # the app uses select, chip, table and command_palette: their hooks are not in the list
    refute finding.message =~ "Select,"
    assert finding.message =~ "Chart"
  end

  test "a clean app has no findings" do
    assert Doctor.scan(@clean) == []
  end

  test "the task prints file:line and exits 1 when there is something to review" do
    assert catch_exit(Doctor.run(["--path", @app])) == {:shutdown, 1}

    assert_received {:mix_shell, :info, [first]}
    assert first =~ ~r/^assets\/js\/app\.js:2: \[js_full_import\]/
    assert_received {:mix_shell, :info, ["
ledger_ui.doctor: " <> _]}
  end

  test "--no-fail exits 0 even with findings" do
    Doctor.run(["--path", @app, "--no-fail"])
    assert_received {:mix_shell, :info, ["\nledger_ui.doctor: " <> _]}
  end

  test "the task exits 0 on a clean app" do
    Doctor.run(["--path", @clean])
    assert_received {:mix_shell, :info, ["ledger_ui.doctor: nothing to report."]}
  end

  test "the doctor reads only: the fixture is not changed" do
    before =
      for p <- Path.wildcard(Path.join(@app, "**/*"), match_dot: true),
          File.regular?(p),
          do: {p, File.stat!(p).mtime}

    Doctor.scan(@app)

    assert before ==
             for(
               p <- Path.wildcard(Path.join(@app, "**/*"), match_dot: true),
               File.regular?(p),
               do: {p, File.stat!(p).mtime}
             )
  end
end
