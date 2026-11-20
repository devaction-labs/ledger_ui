defmodule LedgerShowcase.TemplateParity do
  @moduledoc """
  Parity of the app templates (`/templates/:slug`) with their canvas boards
  (`design/canvas/T*Claro.dc.html`, the source of truth).

  The board's `.lu-auth` / `.lu-app` root is compared with the root
  inside `[data-template]` of the rendered LiveView, with `LedgerShowcase.Parity.flatten/1` and
  `diff/2` (the same comparison as the components). Before comparing, both sides are normalized:

  Both sides

    * the root's own `style` is dropped: the board is a fixed 1440x900 box, the page fills the
      viewport;
    * `data-ind` (the header checkbox's indeterminate state) is dropped: it depends on the
      selection, the board draws it always;
    * the line chart's hook markers (`data-chart`, `data-head`, `data-sub`, `data-legend`; the
      board has the plain `lu-chart` box) are dropped;
    * empty `style=""` / `class=""` serialization artifacts of the canvas export are dropped.

  Our side only (real controls where the board draws static mocks, documented exceptions):

    * the close `button.lu-x` of the overlays loses its `type="button"` (the board has none; ours
      must not submit the modal's form);
    * a `form.lu-modal` / `form.in` (the dialog, the auth column) is the board's `div`; the page
      needs the `<form>` for `phx-change`/`phx-submit`;
    * `lu-input err` (the static error style of a real invalid field) is the board's `m-err`
      (the looping shake class of the demo);
    * a `type="submit"` button is the board's `type="button"`;
    * `<input type="hidden">` (a component's value carrier) is dropped;
    * `label.lu-field` (the field's `<label>`) is a `div.lu-field` on the board;
    * a real `<input>` inside `.lu-input` is the board's `<span class="val">` (password inputs
      are `<span class="val" style="letter-spacing:.2em">` with one bullet per character); an
      input without a value keeps only its `placeholder`;
    * the password field's eye `<button>` is the board's plain small eye icon;
    * a checkbox keeps `type`, `checked` and `data-ind` (our extra `name`/`value`/`phx-*` go);
    * the OTP boxes (`.lu-otp2 > i > input`) are the board's `<b>digit</b>`, the hidden input and
      the `data-lu-*` bookkeeping of the hook go;
    * `textarea` (`.lu-ta`) is the board's `div.tx`; a select (`.lu-sel2`) keeps only its box (our
      popover list, the search and the hidden `<select>` are not on the board).

  Everything else (classes, order, text, icons, styles) must be identical.
  """

  alias LedgerShowcase.Parity

  @canvas Path.expand("../../../design/canvas", __DIR__)
  @max_report 12

  @doc "Board file of a template (`:claro` or `:escuro`)."
  def board_path(board, theme \\ :claro) do
    suffix = if theme == :claro, do: "Claro", else: "Escuro"
    Path.join(@canvas, "#{board}#{suffix}.dc.html")
  end

  @doc "The board's template root as a LazyHTML tree list."
  def board_root(board, theme \\ :claro) do
    board_path(board, theme)
    |> File.read!()
    |> LazyHTML.from_document()
    |> LazyHTML.query(".lu-board .lu-auth, .lu-board .lu-app")
    |> LazyHTML.to_tree()
    |> Enum.map(&clean/1)
    |> Enum.map(&drop_root_style/1)
  end

  @doc "The `data-theme` of the board."
  def board_theme(board, theme) do
    board_path(board, theme)
    |> File.read!()
    |> LazyHTML.from_document()
    |> LazyHTML.query(".lu-board")
    |> LazyHTML.attribute("data-theme")
    |> List.first()
  end

  @doc "The page's template root (inside `[data-template]`) as a normalized tree list."
  def actual_root(html) do
    html
    |> LazyHTML.from_document()
    |> LazyHTML.query("[data-template] > *")
    |> LazyHTML.to_tree()
    |> Enum.map(&normalize/1)
    |> Enum.map(&clean/1)
    |> Enum.map(&drop_root_style/1)
  end

  @doc "`:ok` or `{:error, report}`."
  def compare(expected_tree, actual_tree, label) do
    expected = Parity.flatten(expected_tree)
    actual = Parity.flatten(actual_tree)

    case expected |> Parity.diff(actual) |> Enum.reject(&Parity.extras_only?/1) do
      [] -> :ok
      mismatches -> {:error, report(label, mismatches)}
    end
  end

  defp report(label, mismatches) do
    shown = Enum.take(mismatches, @max_report)

    body =
      Enum.map_join(shown, "\n\n", fn {e, a} ->
        path = elem(e || a, 0)

        "at #{path}\n  expected (board): #{inspect(e && elem(e, 1), limit: 30)}\n  actual   (page) : #{inspect(a && elem(a, 1), limit: 30)}"
      end)

    more = length(mismatches) - length(shown)
    more = if more > 0, do: "\n\n... and #{more} more mismatches", else: ""
    "Template parity mismatch for #{label} (#{length(mismatches)} total):\n\n" <> body <> more
  end

  ## Both sides

  defp clean({"div", attrs, _kids} = el) when is_list(attrs) do
    # the tooltip's position is measured in the browser on the board (px), percent-based here
    if has_class?(attrs, "lu-tip"), do: clean_el(el, ["style"]), else: clean_el(el, [])
  end

  defp clean({_tag, _attrs, _kids} = el), do: clean_el(el, [])
  defp clean(other), do: other

  defp clean_el({tag, attrs, kids}, drop) do
    attrs = Enum.reject(attrs, fn {k, _} -> k in drop end)

    attrs =
      Enum.reject(attrs, fn {k, v} ->
        (k in ["style", "class"] and String.trim(v) == "") or k == "data-ind" or
          k in ["data-chart", "data-head", "data-sub", "data-legend"]
      end)

    {tag, attrs, Enum.map(kids, &clean/1)}
  end

  defp drop_root_style({tag, attrs, kids}), do: {tag, List.keydelete(attrs, "style", 0), kids}

  ## Our side

  defp normalize({"label", attrs, kids}) do
    if has_class?(attrs, "lu-field"),
      do: {"div", attrs, Enum.map(kids, &normalize/1)},
      else: {"label", attrs, Enum.map(kids, &normalize/1)}
  end

  # the password's eye button: the board draws the small eye icon only
  defp normalize({"button", attrs, kids}) do
    attrs = if has_class?(attrs, "lu-x"), do: List.keydelete(attrs, "type", 0), else: attrs

    attrs =
      if List.keyfind(attrs, "type", 0) == {"type", "submit"},
        do: List.keystore(attrs, "type", 0, {"type", "button"}),
        else: attrs

    if has_class?(attrs, "eye") do
      case first_icon(kids) do
        nil -> {"button", attrs, Enum.map(kids, &normalize/1)}
        {t, a, k} -> {t, put_class(a, "sm"), k}
      end
    else
      {"button", attrs, Enum.map(kids, &normalize/1)}
    end
  end

  defp normalize({"span", attrs, kids}) do
    if has_class?(attrs, "lu-input") or has_class?(attrs, "lu-field") do
      attrs = swap_class(attrs, "err", "m-err")
      {"span", attrs, kids |> Enum.map(&normalize_in_input/1) |> Enum.map(&normalize/1)}
    else
      {"span", attrs, Enum.map(kids, &normalize/1)}
    end
  end

  defp normalize({"form", attrs, kids}) do
    if has_class?(attrs, "lu-modal") or has_class?(attrs, "in"),
      do: {"div", attrs, Enum.map(kids, &normalize/1)},
      else: {"form", attrs, Enum.map(kids, &normalize/1)}
  end

  defp normalize({"div", attrs, kids}) do
    cond do
      has_class?(attrs, "lu-otp2") ->
        {"div", otp_attrs(attrs), Enum.flat_map(kids, &otp_box/1)}

      has_class?(attrs, "lu-sel2") ->
        {"div", Enum.filter(attrs, fn {k, _} -> k in ["class", "style"] end), select_box(kids)}

      has_class?(attrs, "lu-ta") ->
        {"div", attrs, Enum.map(kids, &textarea_box/1)}

      true ->
        {"div", attrs, Enum.map(kids, &normalize/1)}
    end
  end

  defp normalize({"input", attrs, kids}) do
    if List.keyfind(attrs, "type", 0) == {"type", "checkbox"} do
      keep = Enum.filter(attrs, fn {k, _} -> k in ["type", "checked", "data-ind"] end)
      {"input", keep, kids}
    else
      keep = Enum.filter(attrs, fn {k, _} -> k in ["placeholder"] end)
      {"input", keep, kids}
    end
  end

  defp normalize({tag, attrs, kids}),
    do: {tag, attrs, kids |> drop_hidden() |> Enum.map(&normalize/1)}

  defp normalize(other), do: other

  defp drop_hidden(kids),
    do: Enum.reject(kids, &match?({"input", [{"type", "hidden"} | _], _}, &1))

  # an `<input>` directly in a `.lu-input` becomes the board's `span.val`
  defp normalize_in_input({"input", attrs, _kids} = el) do
    type = attr(attrs, "type")
    value = attr(attrs, "value")

    cond do
      type in ["checkbox", "hidden"] ->
        el

      type == "password" ->
        {"span", [{"class", "val"}, {"style", "letter-spacing:.2em"}],
         [String.duplicate("•", String.length(value || ""))]}

      value not in [nil, ""] ->
        {"span", [{"class", "val"}], [value]}

      true ->
        el
    end
  end

  defp normalize_in_input({"select", _attrs, kids}) do
    selected =
      Enum.find_value(kids, fn
        {"option", a, [text]} -> if List.keyfind(a, "selected", 0), do: text
        _ -> nil
      end)

    {"span", [{"class", "val"}], [selected || ""]}
  end

  defp normalize_in_input(other), do: other

  defp otp_attrs(attrs), do: Enum.filter(attrs, fn {k, _} -> k == "class" or k == "style" end)

  defp otp_box({"i", attrs, kids}) do
    digit =
      Enum.find_value(kids, "", fn
        {"input", a, _} -> attr(a, "value")
        _ -> nil
      end)

    [
      {"i", Enum.filter(attrs, fn {k, _} -> k == "class" end),
       [{"b", [], if(digit in [nil, ""], do: [], else: [digit])}]}
    ]
  end

  defp otp_box({"input", _, _}), do: []
  defp otp_box(other), do: [normalize(other)]

  defp textarea_box({"textarea", _attrs, kids}), do: {"div", [{"class", "tx"}], kids}
  defp textarea_box(other), do: normalize(other)

  # a select: the board draws the box only; ours also holds the popover and the hidden `<select>`
  defp select_box(kids) do
    for {"span", attrs, box_kids} <- kids, has_class?(attrs, "lu-input") do
      box_kids = Enum.reject(box_kids, &match?({"input", _, _}, &1))
      {"span", attrs, Enum.map(box_kids, &normalize/1)}
    end
  end

  defp first_icon(kids) do
    Enum.find(kids, fn
      {"svg", a, _} -> List.keymember?(a, "data-icon", 0)
      _ -> false
    end)
  end

  defp swap_class(attrs, from, to) do
    if has_class?(attrs, from) do
      {_, v} = List.keyfind(attrs, "class", 0)

      List.keystore(
        attrs,
        "class",
        0,
        {"class", v |> String.split() |> Enum.map_join(" ", &if(&1 == from, do: to, else: &1))}
      )
    else
      attrs
    end
  end

  defp put_class(attrs, class) do
    {_, v} = List.keyfind(attrs, "class", 0, {"class", ""})
    List.keystore(attrs, "class", 0, {"class", v <> " " <> class})
  end

  defp has_class?(attrs, class) do
    case List.keyfind(attrs, "class", 0) do
      {_, v} -> class in String.split(v)
      nil -> false
    end
  end

  defp attr(attrs, name) do
    case List.keyfind(attrs, name, 0) do
      {_, v} -> v
      nil -> nil
    end
  end
end
