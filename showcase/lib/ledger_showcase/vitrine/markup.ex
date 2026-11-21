defmodule LedgerShowcase.Vitrine.Markup do
  @moduledoc false
  # Ports of `esc`, `md` and `hl` from `vitrine/index.html` of the design data, used at compile time.

  def js_const(src, name, default \\ :raise) do
    case {Regex.run(~r/^const #{name} = (.*);$/m, src), default} do
      {[_, json], _} -> Jason.decode!(json)
      {nil, :raise} -> raise ArgumentError, "const #{name} not found"
      {nil, default} -> default
    end
  end

  # --- escaping / highlighting (ports of esc, md, hl from index.html) ---

  @doc false
  def esc(s) do
    String.replace(to_string(s), ~r/[&<>"]/, fn
      "&" -> "&amp;"
      "<" -> "&lt;"
      ">" -> "&gt;"
      "\"" -> "&quot;"
    end)
  end

  @doc false
  def md(s) do
    s
    |> esc()
    |> then(&Regex.replace(~r/`([^`]+)`/, &1, "<code>\\1</code>"))
    |> then(&Regex.replace(~r/\*\*([^*]+)\*\*/, &1, "<b>\\1</b>"))
  end

  @doc false
  def hl(s) do
    s
    |> esc()
    |> then(&Regex.replace(~r/(&lt;\/?)(\.?[:a-z_]+)/, &1, "\\1<span class=\"t\">\\2</span>"))
    |> then(
      &Regex.replace(
        ~r/([a-z_-]+)=(&quot;[^&]*?&quot;|\{[^}]*\})/,
        &1,
        "<span class=\"a\">\\1</span>=<span class=\"s\">\\2</span>"
      )
    )
    |> then(
      &Regex.replace(
        ~r/^(\s*)(defmodule|def|defp|do|end)\b/m,
        &1,
        "\\1<span class=\"k\">\\2</span>"
      )
    )
  end

  @doc false
  def safe(s), do: {:safe, s}
end
