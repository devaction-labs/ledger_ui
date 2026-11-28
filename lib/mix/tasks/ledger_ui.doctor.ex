defmodule Mix.Tasks.LedgerUi.Doctor do
  @shortdoc "Lists what an app can delete or change now that Ledger UI covers it (read only)"

  @moduledoc """
  Scans the app and lists, with `file:line`, code that Ledger UI already makes unnecessary or that
  throws away its change tracking. It only reads: it never edits a file.

      mix ledger_ui.doctor
      mix ledger_ui.doctor --path path/to/app
      mix ledger_ui.doctor --no-fail

  It reads `lib/**/*.{ex,heex}`, `assets/js/app.{js,ts}`, `config/*.exs` and the endpoint. Exit code
  `0` when nothing was found, `1` otherwise (`--no-fail` always exits `0`).

  ## What it reports

    * `locale_redundant`: `locale="..."` equal to `config :ledger_ui, :locale`.
    * `label_redundant`: `no_results`, `remove_label`, `close_label`, `clear_label` and the labels of
      `command_palette` equal to the text the kit already translates for the locale in use.
    * `cell_wrap`: `whitespace-normal!` in a `<:cell>` / `<:col>`; the slot has `wrap="auto"`.
    * `flat_table`: `[&_th]:`/`[&_td]:` selectors to bend the table; there is `variant="flat"` and the
      `--tpx` / `--th-py` variables.
    * `wrapper_spread`: a Ledger UI component called with `{@rest}` or `{assigns}`. Inside a HEEx
      wrapper this makes LiveView hand `__changed__: nil` to the kit, which then sends everything again
      on every call. Delegate by function call (see `guides/liveview-eficiente.md`).
    * `for_without_key`: `:for` on a Ledger UI component without `:key` (the list is tracked by index).
    * `table_without_row_id`: `<.table rows=...>` without `row_id`.
    * `palette_without_defer_items`: `<.command_palette>` without `defer_items`.
    * `shadowed_component`: a module of the app defines `def name(assigns)` for a Ledger UI component
      that `use LedgerUI, except: [...]` leaves out: a wrapper to check (and, for the form fields, what
      `config :ledger_ui, :error_translator` replaces).
    * `endpoint_without_compress`: the LiveView socket without `compress: true`.
    * `js_full_import`: `app.js` imports the whole `"ledger_ui"`; it lists the hooks the components
      found in the app do not need (use `ledger_ui/core` and single hooks).

  Finding `<.comp :for=...>` without `:key` and `{@rest}` in wrappers is a text scan of the tags, not a
  compilation: it can miss a tag built dynamically and can flag a tag in a comment.
  """

  use Mix.Task

  @label_attrs %{
    "no_results" => ["select.no_results"],
    "remove_label" => ["common.remove"],
    "close_label" => ["common.close"],
    "clear_label" => ["common.clear", "filter_menu.clear", "dropdown.clear", "page_trail.clear"]
  }

  @palette_labels %{
    "label" => ["cmd.label"],
    "placeholder" => ["cmd.placeholder"],
    "scopes_label" => ["cmd.scopes"],
    "empty" => ["cmd.empty"],
    "hint_navigate" => ["cmd.navigate"],
    "hint_open" => ["cmd.open"],
    "hint_new_tab" => ["cmd.new_tab"],
    "hint_close" => ["common.close"]
  }

  @fields ~w(input select textarea checkbox switch autocomplete number_input segmented radio_group
             pillbox tags_input password_input date_picker date_time_picker phone_input otp_input)

  @impl true
  def run(args) do
    {opts, _rest} = OptionParser.parse!(args, strict: [path: :string, no_fail: :boolean])
    root = Keyword.get(opts, :path, File.cwd!())

    Mix.Task.run("app.config")

    findings = scan(root)
    Enum.each(findings, &Mix.shell().info(format(&1)))

    if findings == [] do
      Mix.shell().info("ledger_ui.doctor: nothing to report.")
    else
      Mix.shell().info("\nledger_ui.doctor: #{length(findings)} item(s) to review.")
      unless opts[:no_fail], do: exit({:shutdown, 1})
    end
  end

  @doc false
  def format(%{file: file, line: line, code: code, message: message}),
    do: "#{file}:#{line}: [#{code}] #{message}"

  @doc """
  Scans the app at `root` and returns the findings, sorted by file and line:
  `%{file: relative_path, line: integer, code: atom, message: String.t()}`.

  Options (for tests): `:locale` and `:error_translator` replace what is read from the config files.
  """
  @spec scan(Path.t(), keyword()) :: [map()]
  def scan(root, opts \\ []) do
    config = config_text(root)
    locale = Keyword.get_lazy(opts, :locale, fn -> config_locale(config) end)

    translator? =
      Keyword.get_lazy(opts, :error_translator, fn ->
        config =~ "error_translator" or Application.get_env(:ledger_ui, :error_translator) != nil
      end)

    files = source_files(root)
    kit = kit_components()

    per_file =
      Enum.map(files, fn path ->
        source = File.read!(path)
        {rel(root, path), source, tags(source)}
      end)

    findings =
      Enum.flat_map(per_file, fn {file, source, tags} ->
        tag_findings(file, tags, kit, locale) ++ flat_table(file, source)
      end) ++
        shadowed(per_file, kit, translator?) ++
        endpoint(root, files) ++
        js_import(root, per_file, kit)

    Enum.sort_by(findings, &{&1.file, &1.line, &1.code})
  end

  # -- files -----------------------------------------------------------------------------------

  defp source_files(root) do
    Path.wildcard(Path.join(root, "lib/**/*.{ex,heex}")) |> Enum.sort()
  end

  defp rel(root, path), do: Path.relative_to(path, root)

  defp config_text(root) do
    root
    |> Path.join("config/*.exs")
    |> Path.wildcard()
    |> Enum.map_join("\n", &File.read!/1)
  end

  defp config_locale(config) do
    case Regex.run(
           ~r/config\s+:ledger_ui\s*,\s*(?::locale\s*,|locale:)\s*(?:"([\w-]+)"|:(\w+))/,
           config
         ) do
      [_, v] -> LedgerUI.I18n.normalize(v)
      [_, "", v] -> LedgerUI.I18n.normalize(v)
      _ -> LedgerUI.I18n.normalize(Application.get_env(:ledger_ui, :locale))
    end
  end

  defp kit_components do
    for module <- LedgerUI.Components.__modules__(),
        Code.ensure_loaded?(module),
        function_exported?(module, :__components__, 0),
        {name, _} <- module.__components__(),
        into: %{},
        do: {Atom.to_string(name), module}
  end

  # -- tag scanner -----------------------------------------------------------------------------

  # Every `<.name ...>` and `<:slot ...>` with the text of its attributes, up to the `>` that closes
  # the opening tag (braces and quotes respected).
  @doc false
  def tags(source) do
    ~r/<([.:])([a-z_][\w]*)/
    |> Regex.scan(source, return: :index)
    |> Enum.map(fn [{start, len}, {kind_at, 1}, {name_at, name_len}] ->
      body_at = start + len
      attrs = read_attrs(source, body_at)

      %{
        kind: if(binary_part(source, kind_at, 1) == ".", do: :component, else: :slot),
        name: binary_part(source, name_at, name_len),
        attrs: attrs,
        line: line_of(source, start)
      }
    end)
  end

  defp line_of(source, offset) do
    source |> binary_part(0, offset) |> :binary.matches("\n") |> length() |> Kernel.+(1)
  end

  defp read_attrs(source, from) do
    rest = binary_part(source, from, byte_size(source) - from)
    take_attrs(rest, 0, nil, 0, [])
  end

  defp take_attrs(<<>>, _, _, _, acc), do: acc |> Enum.reverse() |> IO.iodata_to_binary()

  defp take_attrs(<<c, rest::binary>>, depth, quote, n, acc) do
    cond do
      n > 4000 ->
        acc |> Enum.reverse() |> IO.iodata_to_binary()

      quote != nil ->
        take_attrs(rest, depth, if(c == quote, do: nil, else: quote), n + 1, [<<c>> | acc])

      c in [?", ?'] ->
        take_attrs(rest, depth, c, n + 1, [<<c>> | acc])

      c == ?{ ->
        take_attrs(rest, depth + 1, nil, n + 1, [<<c>> | acc])

      c == ?} ->
        take_attrs(rest, max(depth - 1, 0), nil, n + 1, [<<c>> | acc])

      c == ?> and depth == 0 ->
        acc |> Enum.reverse() |> IO.iodata_to_binary()

      true ->
        take_attrs(rest, depth, nil, n + 1, [<<c>> | acc])
    end
  end

  # The attrs with the inside of quotes and braces blanked, to look for attribute names.
  defp mask(attrs), do: mask(attrs, 0, nil, [])

  defp mask(<<>>, _, _, acc), do: acc |> Enum.reverse() |> IO.iodata_to_binary()

  defp mask(<<c, rest::binary>>, depth, quote, acc) do
    cond do
      quote != nil ->
        mask(rest, depth, if(c == quote, do: nil, else: quote), [" " | acc])

      c in [?", ?'] and depth == 0 ->
        mask(rest, depth, c, [<<c>> | acc])

      c in [?", ?'] ->
        mask(rest, depth, c, [" " | acc])

      c == ?{ ->
        mask(rest, depth + 1, nil, [<<c>> | acc])

      c == ?} ->
        mask(rest, max(depth - 1, 0), nil, [<<c>> | acc])

      depth > 0 ->
        mask(rest, depth, nil, [" " | acc])

      true ->
        mask(rest, depth, nil, [<<c>> | acc])
    end
  end

  defp has_attr?(masked, name),
    do: Regex.match?(~r/(?:^|\s)#{Regex.escape(name)}(?:=|\s|\/|$)/, masked)

  defp literal(attrs, name) do
    case Regex.run(~r/(?:^|\s)#{Regex.escape(name)}="([^"{}]*)"/, attrs) do
      [_, value] -> value
      _ -> nil
    end
  end

  # -- checks over tags ------------------------------------------------------------------------

  defp tag_findings(file, tags, kit, locale) do
    Enum.flat_map(tags, fn tag ->
      masked = mask(tag.attrs)
      component? = tag.kind == :component and Map.has_key?(kit, tag.name)
      f = fn code, message -> %{file: file, line: tag.line, code: code, message: message} end

      cond do
        component? -> component_findings(tag, masked, f, locale)
        tag.kind == :slot and tag.name in ["cell", "col"] -> cell_findings(tag, f)
        true -> []
      end
    end)
  end

  defp cell_findings(tag, f) do
    if (literal(tag.attrs, "class") || "") =~ "whitespace-normal!" do
      [
        f.(
          :cell_wrap,
          ~s(`<:#{tag.name} class="...whitespace-normal!">`: use `wrap="auto"` on the slot)
        )
      ]
    else
      []
    end
  end

  defp component_findings(tag, masked, f, locale) do
    name = tag.name

    spread =
      if Regex.match?(~r/\{\s*(@rest|assigns)\s*\}/, tag.attrs),
        do: [
          f.(
            :wrapper_spread,
            "`<.#{name} ... {@rest}>` (or `{assigns}`) turns change tracking off in the kit: " <>
              "delegate by function call (guides/liveview-eficiente.md, rule 2 and \"Embrulhando um componente\")"
          )
        ],
        else: []

    for_key =
      if has_attr?(masked, ":for") and not has_attr?(masked, ":key"),
        do: [
          f.(
            :for_without_key,
            "`<.#{name} :for=...>` without `:key`: the list is tracked by index (add `:key={item.id}`)"
          )
        ],
        else: []

    row_id =
      if name == "table" and has_attr?(masked, "rows") and not has_attr?(masked, "row_id"),
        do: [f.(:table_without_row_id, "`<.table rows=...>` without `row_id`")],
        else: []

    palette =
      if name == "command_palette" and not has_attr?(masked, "defer_items") and
           not has_attr?(masked, "inline") and not has_attr?(masked, "bare"),
         do: [
           f.(
             :palette_without_defer_items,
             "`<.command_palette>` without `defer_items`: the items go in the HTML on every mount"
           )
         ],
         else: []

    spread ++ for_key ++ row_id ++ palette ++ locale_label(tag, f, locale)
  end

  defp locale_label(tag, f, config_locale) do
    own = literal(tag.attrs, "locale")
    used = if own, do: LedgerUI.I18n.normalize(own), else: config_locale || "en"

    locale =
      if own && config_locale && LedgerUI.I18n.normalize(own) == config_locale,
        do: [
          f.(
            :locale_redundant,
            ~s(`locale="#{own}"` equals `config :ledger_ui, :locale`: remove the attr)
          )
        ],
        else: []

    table = if tag.name == "command_palette", do: @palette_labels, else: @label_attrs

    labels =
      for {attr, keys} <- table,
          value = literal(tag.attrs, attr),
          Enum.any?(keys, &(LedgerUI.I18n.t(&1, used) == value)) do
        f.(
          :label_redundant,
          ~s(`#{attr}="#{value}"` is the kit text for locale "#{used}": remove the attr)
        )
      end

    locale ++ labels
  end

  defp flat_table(file, source) do
    source
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.filter(fn {line, _} -> line =~ ~r/\[&_(th|td|tr)[\]:>\s]/ end)
    |> Enum.map(fn {_, n} ->
      %{
        file: file,
        line: n,
        code: :flat_table,
        message:
          "`[&_th]:`/`[&_td]:` selectors over the table: use `variant=\"flat\"` and the `--tpx` / `--th-py` variables"
      }
    end)
  end

  # -- shadowed components -----------------------------------------------------------------------

  defp shadowed(per_file, kit, translator?) do
    excluded =
      for {_file, source, _} <- per_file,
          [_, list] <- Regex.scan(~r/use\s+LedgerUI\s*,\s*except:\s*\[([^\]]*)\]/s, source),
          [_, name] <- Regex.scan(~r/:?(\w+)/, list),
          Map.has_key?(kit, name),
          into: MapSet.new(),
          do: name

    for {file, source, _} <- per_file,
        {line, n} <- source |> String.split("\n") |> Enum.with_index(1),
        [_, name] <- [Regex.run(~r/^\s*def\s+(\w+)\(assigns\)/, line)],
        MapSet.member?(excluded, name) do
      extra =
        if name in @fields and not translator?,
          do:
            "; if it only translates errors, `config :ledger_ui, :error_translator, {Mod, :fun}` replaces it",
          else: ""

      %{
        file: file,
        line: n,
        code: :shadowed_component,
        message:
          "`def #{name}(assigns)` shadows the Ledger UI component left out by `use LedgerUI, except:`" <>
            "; check that it still adds something#{extra}"
      }
    end
  end

  # -- endpoint ----------------------------------------------------------------------------------

  defp endpoint(root, files) do
    for path <- files,
        Path.basename(path) == "endpoint.ex",
        source = File.read!(path),
        {:ok, line, statement} <- [socket_statement(source)],
        not (statement =~ ~r/compress:\s*true/) do
      %{
        file: rel(root, path),
        line: line,
        code: :endpoint_without_compress,
        message:
          "the LiveView socket without `websocket: [compress: true]`: the diffs compress 30 to 70 times"
      }
    end
  end

  defp socket_statement(source) do
    case Regex.run(~r/^[ \t]*socket\s+"\/live"[^\n]*(?:\n(?![ \t]*\n)[^\n]*){0,6}/m, source,
           return: :index
         ) do
      [{at, len}] ->
        {:ok, line_of(source, at), binary_part(source, at, len)}

      _ ->
        :none
    end
  end

  # -- JS import -----------------------------------------------------------------------------------

  defp js_import(root, per_file, kit) do
    used_modules =
      for {_file, _source, tags} <- per_file,
          %{kind: :component, name: name} <- tags,
          module = Map.get(kit, name),
          into: MapSet.new(),
          do: module

    needed = used_modules |> Enum.flat_map(&module_hooks/1) |> MapSet.new()

    for rel <- ~w(assets/js/app.js assets/js/app.ts),
        path = Path.join(root, rel),
        File.regular?(path),
        {line, n} <- path |> File.read!() |> String.split("\n") |> Enum.with_index(1),
        line =~ ~r/from\s+["']ledger_ui["']/ do
      unused = all_hooks() |> Enum.reject(&MapSet.member?(needed, &1)) |> Enum.sort()

      %{
        file: rel,
        line: n,
        code: :js_full_import,
        message:
          "imports the whole `\"ledger_ui\"` bundle; import `ledger_ui/core` and the heavy hooks one by one. " <>
            "Hooks the components found in the app do not use (#{length(unused)}): " <>
            hook_list(unused)
      }
    end
  end

  defp hook_list(hooks) do
    shown =
      hooks |> Enum.take(12) |> Enum.map_join(", ", &String.replace_prefix(&1, "LedgerUI.", ""))

    if length(hooks) > 12, do: shown <> ", ...", else: shown
  end

  defp module_hooks(module) do
    with source when is_list(source) <- module.module_info(:compile)[:source],
         {:ok, text} <- File.read(List.to_string(source)) do
      for [_, hook] <- Regex.scan(~r/"(LedgerUI\.[A-Z]\w*)"/, text), do: hook
    else
      _ -> []
    end
  end

  defp all_hooks do
    case :code.priv_dir(:ledger_ui) do
      {:error, _} ->
        []

      dir ->
        dir
        |> Path.join("static/ledger_ui/hooks/*.js")
        |> Path.wildcard()
        |> Enum.map(&("LedgerUI." <> Macro.camelize(Path.basename(&1, ".js"))))
    end
  end
end
