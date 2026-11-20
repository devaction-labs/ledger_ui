defmodule LedgerShowcase.ThemeGen do
  @moduledoc """
  Data and logic of the "Faça o seu tema" generator of the `/temas` page (the vitrine's `TG`,
  `tgStyle` and `tgCode`). The data lives in `priv/theme_gen.json` and is read at compile time:

    * `accents/0` - the 17 Tailwind accents (`light`/`dark` color refs and resolved values `v`)
    * `grays/0` - the nine Tailwind grays, in display order
    * `style/3` - the inline style of the preview section (gray scale, accent, legacy variables)
    * `code/2` - the CSS the project pastes into `assets/css/app.css`
  """

  @path Path.expand("../../priv/theme_gen.json", __DIR__)
  @external_resource @path
  @data @path |> File.read!() |> Jason.decode!()

  @steps ~w(50 100 200 300 400 500 600 700 800 900 950)
  @gray_order ~w(slate gray zinc neutral stone mauve olive mist taupe)

  @accents @data["accents"]
  @grays Map.new(@gray_order, &{&1, @data["grays"][&1]})

  @doc "The shades of a gray scale, `50..950`."
  def steps, do: @steps

  @doc "The accents: `[%{\"id\", \"light\", \"dark\", \"v\"}]`."
  def accents, do: @accents

  @doc "The accent ids."
  def accent_ids, do: Enum.map(@accents, & &1["id"])

  @doc "The Tailwind gray ids, in display order."
  def gray_ids, do: @gray_order

  @doc "The Ledger accent (`\"base\"` in the selection) for a mode: `%{\"accent\", \"content\", \"fg\"}`."
  def base(mode), do: @data["base"][mode]

  @doc "The Ledger gray scale."
  def gray_base, do: @data["grayBase"]

  @doc "The scale of a gray id (`\"ledger\"` is the Ledger gray)."
  def gray_scale("ledger"), do: @data["grayBase"]
  def gray_scale(id), do: Map.fetch!(@grays, id)

  @doc "The accent with this id, or `nil` (also for `\"base\"`)."
  def accent(id), do: Enum.find(@accents, &(&1["id"] == id))

  @doc "Capitalizes the first letter (`cap/1` of the vitrine)."
  def cap(<<first::utf8, rest::binary>>), do: String.upcase(<<first::utf8>>) <> rest

  @doc "Swatch color of a gray in a mode: step 200 in light, 800 in dark."
  def gray_swatch(gray, "dark"), do: gray_scale(gray)["800"]
  def gray_swatch(gray, _), do: gray_scale(gray)["200"]

  @doc """
  The inline style of the preview section (`tgStyle`): `--color-gray-50..950`, the three accent
  variables and, for the components still on the old CSS, the derived `--teal-*` variables.
  """
  def style(acc, gray, mode) do
    g = gray_scale(gray)

    [accent, content, fg] =
      case accent(acc) do
        nil ->
          b = base(mode)
          [b["accent"], b["content"], b["fg"]]

        a ->
          a["v"][mode]
      end

    Enum.map_join(@steps, &"--color-gray-#{&1}:#{g[&1]};") <>
      "--color-accent:#{accent};--color-accent-content:#{content};--color-accent-foreground:#{fg};" <>
      @data["derived"][mode]
  end

  @doc "The CSS of the project (`tgCode`)."
  def code(acc, gray) do
    a = accent(acc)

    gray_lines =
      if gray != "ledger" do
        [
          "/* Cinza: #{cap(gray)} no lugar do cinza do Ledger */",
          "@theme {"
          | Enum.map(@steps, &"    --color-gray-#{&1}: var(--color-#{gray}-#{&1});")
        ] ++ ["}", ""]
      else
        []
      end

    accent_lines =
      if a do
        [
          "/* Destaque: #{cap(a["id"])} */",
          "@theme {",
          "    --color-accent: #{ref(Enum.at(a["light"], 0))};",
          "    --color-accent-content: #{ref(Enum.at(a["light"], 1))};",
          "    --color-accent-foreground: #{ref(Enum.at(a["light"], 2))};",
          "}",
          "",
          "@layer theme {",
          "    [data-theme=dark] {",
          "        --color-accent: #{ref(Enum.at(a["dark"], 0))};",
          "        --color-accent-content: #{ref(Enum.at(a["dark"], 1))};",
          "        --color-accent-foreground: #{ref(Enum.at(a["dark"], 2))};",
          "    }",
          "}"
        ]
      else
        []
      end

    lines =
      case gray_lines ++ accent_lines do
        [] -> ["/* Tema padrão do Ledger: não precisa acrescentar nada. */"]
        l -> l
      end

    ~s(@import "tailwindcss";\n@import "../../deps/ledger_ui/assets/css/ledger_ui.css";\n\n) <>
      (lines |> Enum.join("\n") |> String.trim())
  end

  defp ref("white"), do: "var(--color-white)"
  defp ref(x), do: "var(--color-#{x})"
end
