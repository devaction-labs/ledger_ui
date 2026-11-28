defmodule LedgerUI.A11yStructureTest do
  # #121: structural accessibility checks over the HTML each public component renders, with the
  # smallest assigns that make it render (required attrs, required slots). No browser, no axe:
  #
  #   * every `for`, `aria-labelledby`, `aria-controls` and `aria-describedby` points to an `id`
  #     that exists in the same rendering;
  #   * parent and child roles match: `option` lives in a `listbox`, `menuitem`, `menuitemcheckbox`
  #     and `menuitemradio` in a `menu` (or `menubar`), `tab` in a `tablist`, `radio` in a
  #     `radiogroup`. The nearest ancestor that has one of those parent roles decides.
  #
  # Each component is rendered twice: with its required slots only, and with every declared slot.
  #
  # `@known` lists the violations that open issues describe, so the test passes today. Each entry is
  # `{component, check, issue}`. When an issue is fixed the entry has to go: an entry that no longer
  # matches any violation fails the test (the list can only shrink).
  use ExUnit.Case, async: true

  alias LedgerUI.A11yStructureTest.Render

  # {component, check, issue}. `:ref` is a dangling reference or a dialog without a name, `:role` a
  # parent and child role that do not match (or a role on a `label`), `:label` a field label that
  # names no control.
  @known [
    {:select, :role, 112},
    {:pillbox, :role, 112},
    {:tags_input, :role, 112},
    {:modal, :ref, 114},
    {:drawer, :ref, 114},
    {:sheet, :ref, 114},
    {:switch, :role, 114},
    {:switch, :label, 114},
    {:autocomplete, :label, 113},
    {:number_input, :label, 113},
    {:time_picker, :label, 113},
    # Found by this test, no issue yet: `role="radio"` outside a `role="radiogroup"`, and a
    # `role="dialog"` with no name in `popover`.
    {:popover, :ref, nil},
    # Same defect as #113 (`label=` names no control), found in other components by this test.
    {:color_picker, :label, 113},
    {:date_time_picker, :label, 113},
    {:datetime_picker, :label, 113},
    {:number_stepper, :label, 113},
    {:rating, :label, 113},
    {:signature_pad, :label, 113},
    {:tags_input, :label, 113},
    # The link and image dialogs of the editors: labels with no control. No issue yet.
    {:comment_editor, :label, nil},
    {:rich_text_editor, :label, nil},
    {:text_editor, :label, nil},
    {:date_time_picker, :role, nil},
    {:datetime_picker, :role, nil}
  ]

  # Not defects: the sweep gives a slot attr the same fake value ("x") in every slot, so the panel
  # of `tabs` points to a tab id that the index-named tab does not have; `right_sidebar_toggle`
  # points to the fake id it is given. And the parts that are made to live inside a parent the
  # sweep does not render (a menu item without its `menu`).
  @artifacts [
    {:tabs, :ref},
    {:right_sidebar_toggle, :ref},
    # the `label` and `field` components rendered alone have no control to name
    {:label, :label},
    {:field, :label},
    {:dropdown_item, :role},
    {:dropdown_checkbox, :role},
    {:dropdown_footer, :role},
    {:dropdown_radio, :role},
    {:dropdown_submenu, :role},
    {:navbar_menu_item, :role},
    {:horizontal_nav_link, :role}
  ]

  @refs ~w(for aria-labelledby aria-controls aria-describedby)

  @parents ~w(listbox menu menubar tablist radiogroup)
  @owns %{
    "option" => ["listbox"],
    "menuitem" => ["menu", "menubar"],
    "menuitemcheckbox" => ["menu", "menubar"],
    "menuitemradio" => ["menu", "menubar"],
    "tab" => ["tablist"],
    "radio" => ["radiogroup"]
  }

  @controls ~w(input select textarea)

  defp analyse(html) do
    tree = html |> LazyHTML.from_fragment() |> LazyHTML.to_tree()
    els = elements(tree)
    ids = for {_, attrs, _} <- els, {"id", id} <- attrs, into: MapSet.new(), do: id

    refs =
      for {tag, attrs, _} <- els,
          {k, v} <- attrs,
          k in @refs,
          not (tag == "form" and k == "for"),
          id <- String.split(v),
          do: {tag, k, id}

    labelled =
      for {_, attrs, _} <- els,
          {"aria-labelledby", v} <- attrs,
          id <- String.split(v),
          into: MapSet.new(),
          do: id

    named_for =
      for {"label", attrs, _} <- els, {"for", v} <- attrs, into: MapSet.new(), do: v

    %{
      dangling: for({tag, k, id} <- refs, not MapSet.member?(ids, id), do: {tag, k, id}),
      roles: roles(tree, nil, []) ++ label_roles(els),
      labels: orphan_labels(els, labelled, named_for),
      nameless:
        for({"div", attrs, _} = el <- els, nameless_dialog?(attrs), do: {elem(el, 0), "dialog"})
    }
  end

  defp elements(nodes) do
    Enum.flat_map(nodes, fn
      {_, _, children} = el -> [el | elements(children)]
      _ -> []
    end)
  end

  # A `role="dialog"` with neither `aria-label` nor `aria-labelledby`.
  defp nameless_dialog?(attrs) do
    role = attrs |> List.keyfind("role", 0, {nil, nil}) |> elem(1) |> first_token()

    role in ["dialog", "alertdialog"] and
      not Enum.any?(attrs, fn {k, v} -> k in ["aria-label", "aria-labelledby"] and v != "" end)
  end

  defp label_roles(els),
    do: for({"label", attrs, _} <- els, {"role", role} <- attrs, do: {role, "label"})

  # `<label>` or `data-part="label"` that is neither `for` an existing control, nor around a
  # control, nor named by an `aria-labelledby`.
  defp orphan_labels(els, labelled, _named_for) do
    for {tag, attrs, children} <- els,
        tag == "label" or {"data-part", "label"} in attrs,
        not label_ok?(tag, attrs, children, labelled),
        do: {tag, text(children)}
  end

  defp label_ok?(tag, attrs, children, labelled) do
    id = attrs |> List.keyfind("id", 0, {nil, nil}) |> elem(1)

    (id != nil and MapSet.member?(labelled, id)) or
      (tag == "label" and List.keymember?(attrs, "for", 0)) or
      (tag == "label" and Enum.any?(elements(children), &control?/1))
  end

  defp control?({tag, attrs, _}),
    do: tag in @controls and {"type", "hidden"} not in attrs

  defp text(nodes) do
    nodes
    |> Enum.map_join(" ", fn
      t when is_binary(t) -> t
      {_, _, c} -> text(c)
      _ -> ""
    end)
    |> String.trim()
    |> String.slice(0, 40)
  end

  # The role violations: `{role, nearest_parent_role | nil}`.
  defp roles(nodes, parent, acc) do
    Enum.reduce(nodes, acc, fn
      {_tag, attrs, children}, acc ->
        role = attrs |> List.keyfind("role", 0, {nil, nil}) |> elem(1) |> first_token()
        acc = if bad_role?(role, parent), do: [{role, parent} | acc], else: acc
        roles(children, if(role in @parents, do: role, else: parent), acc)

      _, acc ->
        acc
    end)
  end

  defp first_token(nil), do: nil
  defp first_token(v), do: v |> String.split() |> List.first()

  defp bad_role?(role, parent) do
    case @owns[role] do
      nil -> false
      allowed -> parent not in allowed
    end
  end

  defp violations(component, html) do
    a = analyse(html)

    Enum.map(a.dangling, &{component, :ref, &1}) ++
      Enum.map(a.nameless, &{component, :ref, &1}) ++
      Enum.map(a.roles, &{component, :role, &1}) ++
      Enum.map(a.labels, &{component, :label, &1})
  end

  setup_all do
    results = Render.all()
    {:ok, results: results}
  end

  test "the sweep renders almost every public component", %{results: results} do
    rendered = for {_, {:ok, _}} <- results.runs, do: :ok

    assert length(rendered) >= 300,
           "only #{length(rendered)} renders worked; failed: #{inspect(results.failed)}"
  end

  test "references and role pairs, apart from the known issues", %{results: results} do
    all =
      for {component, {:ok, html}} <- results.runs,
          v <- violations(component, html),
          do: v

    all = Enum.reject(all, fn {c, k, _} -> {c, k} in @artifacts end)
    known = @known

    new =
      for {component, check, detail} <- all,
          not Enum.any?(known, fn {c, k, _} -> c == component and k == check end),
          uniq: true,
          do: {component, check, detail}

    assert new == [],
           "structural accessibility violations not in @known:\n" <>
             Enum.map_join(new, "\n", &"  #{inspect(&1)}")

    stale =
      for {c, k, issue} <- known,
          not Enum.any?(all, fn {component, check, _} -> component == c and check == k end),
          do: {c, k, issue}

    assert stale == [],
           "@known entries that no longer match a violation (remove them): #{inspect(stale)}"
  end
end
