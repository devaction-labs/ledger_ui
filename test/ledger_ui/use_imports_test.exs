defmodule LedgerUI.UseImportsTest do
  use ExUnit.Case, async: true

  defmodule Host do
    use LedgerUI
    def imported, do: __ENV__.functions
  end

  @api_names ~w(dismiss_alert calendar_range date_picker_clear table_toggle_row insert_html
                insert_image sanitize show_toast put_toast send_toast update_toast
                dismiss_toast clear_toasts)a

  test "use LedgerUI imports only function components and documented JS helpers" do
    imported =
      for {mod, funs} <- Host.imported(),
          String.starts_with?(inspect(mod), "LedgerUI.Components."),
          {name, arity} <- funs,
          do: {mod, name, arity}

    assert imported != []

    offenders =
      for {mod, name, arity} <- imported,
          not component?(mod, name, arity),
          name not in @api_names,
          do: {mod, name, arity}

    assert offenders == []
  end

  test "Chart helpers are not leaked" do
    refute Enum.any?(Host.imported(), fn {_m, funs} ->
             Enum.any?(funs, fn {n, _} -> n in [:num, :money, :kilo, :wf_axis] end)
           end)
  end

  test "documented helpers stay imported" do
    names = for {_m, funs} <- Host.imported(), {n, _} <- funs, do: n
    for n <- @api_names, do: assert(n in names, "#{n} not imported")
  end

  defp component?(mod, name, 1),
    do: function_exported?(mod, :__components__, 0) and Map.has_key?(mod.__components__(), name)

  defp component?(_, _, _), do: false
end
