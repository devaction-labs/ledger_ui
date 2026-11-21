defmodule LedgerUI.JSHiddenAttrTest do
  @moduledoc """
  Tailwind v4's preflight has `[hidden]:where(:not([hidden=until-found])) { display: none !important }`,
  so `JS.toggle/show/hide` (which only set an inline `display`) never open an element that is
  rendered with the `hidden` attribute. Such targets must be driven with `set_attr`/`toggle_attr`/
  `remove_attr` on `hidden` instead (#11).
  """
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.AppShell

  @display_ops ~w(toggle show hide)

  # Every phx-* JSON command in the HTML, as `{attr, [[op, args], ...]}`.
  defp commands(html) do
    html
    |> LazyHTML.from_fragment()
    |> LazyHTML.query("*")
    |> LazyHTML.attributes()
    |> Enum.flat_map(fn attrs ->
      for {name, "[[" <> _ = v} <- attrs,
          String.starts_with?(name, "phx-"),
          do: {name, Jason.decode!(v)}
    end)
  end

  defp ids_with_hidden(html) do
    html
    |> LazyHTML.from_fragment()
    |> LazyHTML.query("[hidden][id]")
    |> LazyHTML.attribute("id")
  end

  defp ops(html, op), do: for({_, cmds} <- commands(html), [^op, args] <- cmds, do: args)

  # No display op (toggle/show/hide) may target an element that carries the `hidden` attribute.
  defp refute_display_ops_on_hidden(html) do
    hidden = ids_with_hidden(html)

    for {name, cmds} <- commands(html), [op, args] <- cmds, op in @display_ops do
      refute args["to"] in Enum.map(hidden, &("#" <> &1)),
             "#{name}: #{op} targets #{args["to"]}, which uses the hidden attribute"
    end
  end

  defp hidden_ops(html, op),
    do:
      Enum.filter(ops(html, op), fn args ->
        args["attr"] == "hidden" or args["attr"] == ["hidden", "hidden"] or
          hd(List.wrap(args["attr"])) == "hidden"
      end)

  test "rail_module toggles the hidden attribute of its body" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.rail_module id="m" label="Sales">
  <:icon>i</:icon>
  <:item navigate="/o">O</:item>
</.rail_module>|)

    assert html =~ ~r/<div[^>]*id="m-body"[^>]*hidden/

    assert [%{"to" => "#m-body", "attr" => ["hidden", "hidden"]}] =
             hidden_ops(html, "toggle_attr") |> Enum.filter(&(&1["to"] == "#m-body"))

    assert [%{"to" => "#m-head"}] =
             Enum.filter(ops(html, "toggle_attr"), &(&1["to"] == "#m-head"))

    assert ops(html, "toggle") == []
    refute_display_ops_on_hidden(html)
  end
end
