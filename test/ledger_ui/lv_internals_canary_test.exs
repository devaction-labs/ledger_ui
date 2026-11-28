defmodule LedgerUI.LvInternalsCanaryTest do
  # #107: `LedgerUI.Helpers.settle/3` and `LedgerUI.I18n.track/2` write to `assigns.__changed__`, and
  # `LedgerUI.Helpers.render_slot_full/2` calls `Phoenix.Component.__render_slot__/3` (`@doc false`).
  # None of this is public API of Phoenix LiveView. If a LiveView release changes it, the
  # compiler stays quiet and the failure shows up as a stale page or a wrong diff size. These
  # tests fail first, with a message that says what moved. The weekly job `lv-main.yml` runs the
  # suite against the `main` branch of LiveView so this shows up before a release.
  use ExUnit.Case, async: true
  use Phoenix.Component

  alias Phoenix.LiveView.Diff

  def probe(assigns) do
    send(self(), {:probe_changed, assigns.__changed__})
    ~H"<i>{@a}{@b}</i>"
  end

  def parent(assigns) do
    ~H"<.probe a={@a} b={@b} />"
  end

  defp changed_seen(base, changes) do
    {_, prints, comps} =
      Diff.render(
        %Phoenix.LiveView.Socket{},
        parent(Map.put(base, :__changed__, nil)),
        Diff.new_fingerprints(),
        Diff.new_components()
      )

    flush()
    next = Map.merge(base, Map.new(changes))

    Diff.render(
      %Phoenix.LiveView.Socket{},
      parent(Map.put(next, :__changed__, Map.new(changes, fn {k, _} -> {k, true} end))),
      prints,
      comps
    )

    receive do
      {:probe_changed, changed} -> changed
    after
      0 -> :not_called
    end
  end

  defp flush do
    receive do
      {:probe_changed, _} -> flush()
    after
      0 -> :ok
    end
  end

  test "assigns.__changed__ is a map whose keys are the assigns that changed" do
    changed = changed_seen(%{a: 1, b: 2}, a: 3)

    assert is_map(changed),
           "LiveView no longer hands a component `assigns.__changed__` as a map " <>
             "(got #{inspect(changed)}). `LedgerUI.Helpers.settle/3` and `LedgerUI.I18n.track/2` " <>
             "depend on that shape: review them against the new LiveView before upgrading."

    assert Map.has_key?(changed, :a),
           "`assigns.__changed__` no longer lists the changed assign `:a` " <>
             "(got #{inspect(changed)}): `settle/3` would drop or keep the wrong keys."

    refute Map.has_key?(changed, :b),
           "`assigns.__changed__` now lists an assign that did not change " <>
             "(got #{inspect(changed)}): `settle/3` assumes a key is present only when it changed."
  end

  test "settle/3 still removes a derived key from __changed__ and keeps one whose source changed" do
    assigns = %{a: 1, b: 2, cls: "x", __changed__: %{cls: true, a: true}}

    assert %{__changed__: changed} = LedgerUI.Helpers.settle(assigns, %{}, cls: [:b])

    assert changed == %{a: true},
           "`settle/3` no longer edits `assigns.__changed__` the way it did (got #{inspect(changed)})"

    assert %{__changed__: %{cls: true, a: true}} =
             LedgerUI.Helpers.settle(assigns, %{}, cls: [:a])
  end

  test "Phoenix.Component.__render_slot__/3 still exists with arity 3" do
    Code.ensure_loaded!(Phoenix.Component)

    assert function_exported?(Phoenix.Component, :__render_slot__, 3),
           "`Phoenix.Component.__render_slot__/3` is gone or changed arity. " <>
             "`LedgerUI.Helpers.render_slot_full/2` (and `card.ex`, until it uses the helper) call it: " <>
             "replace that single call site in lib/ledger_ui/helpers.ex."
  end

  test "render_slot_full/2 draws a slot body whatever the changed map" do
    slot = %{__slot__: :inner_block, inner_block: fn _changed, _arg -> "body" end}

    assert LedgerUI.Helpers.render_slot_full([slot]) in ["body", ["body"]],
           "`render_slot_full/2` no longer draws the slot body"
  end
end
