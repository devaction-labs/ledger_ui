defmodule LedgerShowcase.Vitrine do
  @moduledoc """
  Static data of the vitrine (`design/vitrine`), loaded at compile time:

    * `nav/0` - the 15 groups (`NAV` of `index.html`)
    * `all/0` - every component `%{id, name, new, sub, g}` in NAV order
    * `colors/0` - the `COLORS` tokens
    * `page/1` - everything a component page needs (docs.json + sec/<id>.json), pre-rendered
      (markdown, syntax highlight, wide detection). Sections that have an example in
      `LedgerShowcase.Examples` are `live: true` (code = HEEx source); the others carry the
      vitrine's raw `h` HTML as a static fallback.

  Nothing here reads files or parses JSON at runtime.
  """

  alias LedgerShowcase.Examples
  alias LedgerShowcase.Vitrine.Markup
  import Markup, only: [md: 1, hl: 1, safe: 1]

  @design Path.expand("../../../design/vitrine", __DIR__)
  @index Path.join(@design, "index.html")
  @docs_path Path.join(@design, "docs.json")

  @external_resource @index
  @external_resource @docs_path
  @extras_path Path.expand("../../../design/canvas/extras.json", __DIR__)
  @external_resource @extras_path
  @extras @extras_path |> File.read!() |> Jason.decode!()

  @index_src File.read!(@index)

  # --- navigation ---

  @nav Markup.js_const(@index_src, "NAV")
  @colors Markup.js_const(@index_src, "COLORS")
  @count Markup.js_const(@index_src, "COUNT")
  # `PALETTES` of index.html: `[%{"id", "name", "description", "display", "sw" => %{"light"/"dark" => [[token, label, value]]}, "grad"}]`
  @palettes Markup.js_const(@index_src, "PALETTES")
  @palettes_json Jason.encode!(@palettes)

  @nav Enum.map(@nav, fn g ->
         short = g["g"] |> String.split(" · ") |> List.last()

         %{
           title: g["g"],
           short: short,
           items:
             Enum.map(g["items"], fn i ->
               %{
                 id: i["id"],
                 name: i["name"],
                 new: i["new"],
                 sub: i["sub"] || "",
                 g: g["g"],
                 short: short
               }
             end)
         }
       end)

  @all Enum.flat_map(@nav, & &1.items)

  @colors Enum.map(@colors, &%{n: &1["n"], l: &1["l"], d: &1["d"]})

  @search Jason.encode!(Enum.map(@all, &[&1.id, &1.name, &1.short]))

  @doc "Groups with their items."
  def nav, do: @nav
  @doc "All components in NAV order."
  def all, do: @all
  @doc "Color tokens."
  def colors, do: @colors
  @doc "Component count shown on the intro."
  def count, do: @count

  @doc "The palettes (`data-palette`) with their swatches, as in the vitrine."
  def palettes, do: @palettes

  @doc "The palettes as JSON for the header menu (`#d-palettes`)."
  def palettes_json, do: @palettes_json
  @doc "JSON `[[id, name, group]]` for the client-side command palette."
  def search_json, do: @search
  # --- component pages ---

  @docs @docs_path |> File.read!() |> Jason.decode!()

  @pages (for {d, i} <- Enum.with_index(@docs), into: %{} do
            id = d["id"]
            sec_path = Path.join([@design, "sec", id <> ".json"])
            Module.put_attribute(__MODULE__, :external_resource, sec_path)
            # vitrine sections in their order, then the canvas-only demos in canvas order
            secs =
              LedgerShowcase.Sections.vitrine(id) ++
                Enum.map(Map.get(@extras, id, []), &Map.merge(%{"lang" => "html"}, &1))

            examples = Map.new(Examples.sections(id), &{&1.index, &1})

            sections =
              for {s, k} <- Enum.with_index(secs, 1) do
                ex = examples[k]
                code = if ex, do: ex.source, else: s["code"] || s["h"]
                lines = code |> String.split("\n") |> length()

                %{
                  k: k - 1,
                  index: k,
                  t: s["t"],
                  live: ex != nil,
                  lang: if(ex, do: "heex", else: s["lang"]),
                  wide:
                    Regex.match?(
                      ~r/lu-grid|lu-table|lu-tbl|grid-template-columns|lu-shell|lu-wire|lu-kanban|lu-dt/,
                      s["h"]
                    ),
                  long: lines > 9,
                  code: code,
                  code_html: safe(hl(code)),
                  h: if(ex, do: nil, else: safe(s["h"]))
                }
              end

            prev = Enum.at(@docs, i - 1)
            prev = if i > 0 and prev, do: %{id: prev["id"], name: prev["name"]}
            nxt = Enum.at(@docs, i + 1)
            nxt = if nxt, do: %{id: nxt["id"], name: nxt["name"]}
            notes = d["notes"] || []

            {id,
             %{
               id: id,
               name: d["name"],
               group: d["group"],
               subtitle: d["subtitle"],
               summary_html: safe(md(d["summary"])),
               usage: d["usage"],
               usage_html: safe(hl(d["usage"])),
               notes_html: Enum.map(notes, &safe(md(&1))),
               api_html: if(d["api"] not in [nil, ""], do: safe(d["api"])),
               sections: sections,
               prev: prev,
               next: nxt
             }}
          end)

  @pages_ids @pages |> Map.keys() |> MapSet.new()

  @doc "Prepared page data for a component id, or nil."
  def page(id), do: Map.get(@pages, id)

  @doc "Component page ids known to the vitrine."
  def ids, do: @pages_ids

  # --- static pages ---

  @install [
    {"1. Dependência", "# mix.exs\ndefp deps do\n  [\n    {:ledger_ui, \"~> 0.1\"}\n  ]\nend",
     nil},
    {"2. Componentes",
     "# lib/my_app_web.ex\ndefp html_helpers do\n  quote do\n    use LedgerUI\n  end\nend", nil},
    {"3. Estilos e ícones",
     "/* assets/css/app.css */\n@import \"tailwindcss\";\n@import \"../../deps/ledger_ui/assets/css/ledger_ui.css\";",
     "Os ícones são Hugeicons Stroke Rounded, renderizados no servidor e usados por nome: <code>&lt;.icon name=\"huge-home-01\" /&gt;</code>."},
    {"4. JavaScript",
     "// assets/js/app.js (NODE_PATH inclui deps)\nimport {Hooks, DOM} from \"ledger_ui\"\n\nconst liveSocket = new LiveSocket(\"/live\", Socket, {\n  hooks: {...Hooks},\n  dom: {onBeforeElUpdated(from, to) { DOM.onBeforeElUpdated(from, to) }},\n  params: {_csrf_token: csrfToken}\n})",
     "Sem bundler, sirva <code>priv/static</code> com <code>Plug.Static</code> e importe <code>/ledger_ui/ledger_ui.esm.js</code> num <code>&lt;script type=\"module\"&gt;</code>."},
    {"5. Toaster", "<.toaster flash={@flash} position=\"center-bottom\" />", nil}
  ]

  @install Enum.map(@install, fn {t, code, note} ->
             %{t: t, code: safe(hl(code)), note: note && safe(note)}
           end)

  @temas safe(
           hl(
             "<html data-theme=\"dark\" data-palette=\"crepusculo\">\n<.theme_switch id=\"mode\" variant=\"segmented\" />\n<.theme_picker id=\"palette\" themes={~w(ledger crepusculo)} />"
           )
         )

  @doc "Installation steps `[%{t, code, note}]` (code pre-highlighted)."
  def install, do: @install
  @doc "Highlighted snippet of the themes page."
  def temas_code, do: @temas
end
