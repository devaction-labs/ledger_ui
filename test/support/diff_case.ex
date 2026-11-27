defmodule LedgerUI.DiffCase do
  @moduledoc false
  # Diff harness shared by the change-tracking tests (#85-#89 and later): renders a component the
  # way the LiveView does (`Phoenix.LiveView.Diff.render/4`) with a `__changed__` naming only
  # what the caller changed, and applies the patch with `Phoenix.LiveViewTest.Diff.merge_diff/2`
  # (internal API of the LiveView, isolated here).
  #
  #   import LedgerUI.DiffCase
  #   json = check(&my_fun/1, base, label: "B")   # asserts first render + patch == fresh render
  #   each_source(&my_fun/1, base, variant: "x", size: "lg")
  #   json = patch(&my_fun/1, base, label: "B")   # only the patch, no HTML comparison
  #   {json, html} = first(&my_fun/1, base)       # first render as JSON + HTML

  import ExUnit.Assertions
  alias Phoenix.LiveView.Diff

  def full_render(fun, assigns) do
    Diff.render(
      %Phoenix.LiveView.Socket{},
      fun.(Map.put(assigns, :__changed__, nil)),
      Diff.new_fingerprints(),
      Diff.new_components()
    )
  end

  def html(fun, assigns),
    do: fun.(Map.put(assigns, :__changed__, nil)) |> Phoenix.LiveViewTest.rendered_to_string()

  def first(fun, assigns) do
    {full, _, _} = full_render(fun, assigns)
    {Jason.encode!(full), html(fun, assigns)}
  end

  def check(fun, base, changes) do
    {full, prints, comps} = full_render(fun, base)
    next = Map.merge(base, Map.new(changes))
    changed = Map.new(changes, fn {k, _} -> {k, true} end)

    {patch, _, _} =
      Diff.render(
        %Phoenix.LiveView.Socket{},
        fun.(Map.put(next, :__changed__, changed)),
        prints,
        comps
      )

    before_html = html(fun, base)
    after_html = html(fun, next)

    assert before_html != after_html,
           "the change #{inspect(changes)} changes nothing in the HTML: the test is wrong"

    merged =
      full
      |> Phoenix.LiveViewTest.Diff.merge_diff(patch)
      |> Diff.to_iodata()
      |> IO.iodata_to_binary()

    assert merged == after_html,
           "after changing only #{inspect(changes)} the client would show a stale page"

    Jason.encode!(patch)
  end

  def patch(fun, base, changes) do
    {_, prints, comps} = full_render(fun, base)
    next = Map.merge(base, Map.new(changes))
    changed = Map.new(changes, fn {k, _} -> {k, true} end)

    {patch, _, _} =
      Diff.render(
        %Phoenix.LiveView.Socket{},
        fun.(Map.put(next, :__changed__, changed)),
        prints,
        comps
      )

    Jason.encode!(patch)
  end

  def each_source(fun, base, changes) do
    for {key, value} <- changes do
      try do
        check(fun, base, [{key, value}])
      rescue
        e in ExUnit.AssertionError ->
          reraise %{e | message: "[#{inspect(key)}] " <> e.message}, __STACKTRACE__
      end
    end
  end
end
