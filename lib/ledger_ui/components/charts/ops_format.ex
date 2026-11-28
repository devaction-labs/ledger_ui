defmodule LedgerUI.Components.OpsFormat do
  @moduledoc false
  # Shared by the operation components (`tick_strip`, `target_sparkline`, `segment_bar`, `countdown_bar`,
  # `breakdown_list`, `rank_list`): the locale-aware number format and the tone vocabulary.
  #
  # Marks (bars, strokes, dots) of `pos`, `warn` and `neg` use the bright series colours (`series-1` mint,
  # `series-3` yellow, `series-4` pink), as the board does: the `pos`/`warn`/`neg` tokens are dark text
  # colours. The status tags and the icon frames keep the tokens `pos`, `warn`, `neg` (text on soft).
  #
  # A tone is `pos`, `warn`, `neg`, `info`, `neutral` or a series colour `c1`..`c5` (the series tokens;
  # the series palette `--lu-series-*`). The long
  # names `success`, `warning`, `error` are read as the short ones.

  import LedgerUI.Helpers, only: [tone_short: 1]

  @bg %{
    "ink" => "bg-ink-2",
    "pos" => "bg-series-1",
    "warn" => "bg-series-3",
    "neg" => "bg-series-4",
    "info" => "bg-info",
    "neutral" => "bg-line-strong",
    "c1" => "bg-series-1",
    "c2" => "bg-series-2",
    "c3" => "bg-series-3",
    "c4" => "bg-series-4",
    "c5" => "bg-series-5"
  }
  @stroke %{
    "ink" => "stroke-ink-2",
    "pos" => "stroke-series-1",
    "warn" => "stroke-series-3",
    "neg" => "stroke-series-4",
    "info" => "stroke-info",
    "neutral" => "stroke-line-strong",
    "c1" => "stroke-series-1",
    "c2" => "stroke-series-2",
    "c3" => "stroke-series-3",
    "c4" => "stroke-series-4",
    "c5" => "stroke-series-5"
  }
  @fill %{
    "ink" => "fill-ink-2",
    "pos" => "fill-series-1",
    "warn" => "fill-series-3",
    "neg" => "fill-series-4",
    "info" => "fill-info",
    "neutral" => "fill-line-strong",
    "c1" => "fill-series-1",
    "c2" => "fill-series-2",
    "c3" => "fill-series-3",
    "c4" => "fill-series-4",
    "c5" => "fill-series-5"
  }
  @text %{
    "pos" => "text-pos",
    "warn" => "text-warn",
    "neg" => "text-neg",
    "info" => "text-info",
    "neutral" => "text-muted",
    "ink" => "text-ink-2",
    "c1" => "text-series-1",
    "c2" => "text-series-2",
    "c3" => "text-series-3",
    "c4" => "text-series-4",
    "c5" => "text-series-5"
  }
  # a soft frame with the series colour on the icon (breakdown rows)
  @soft %{
    "ink" => "bg-sunken text-ink-2",
    "pos" => "bg-pos/15 text-pos",
    "warn" => "bg-warn/15 text-warn",
    "neg" => "bg-neg/15 text-neg",
    "info" => "bg-info/15 text-info",
    "neutral" => "bg-sunken text-ink-2",
    "c1" => "bg-series-1/15 text-series-1",
    "c2" => "bg-series-2/15 text-series-2",
    "c3" => "bg-series-3/15 text-series-3",
    "c4" => "bg-series-4/15 text-series-4",
    "c5" => "bg-series-5/15 text-series-5"
  }
  # the status tag (delta of the lists)
  @tag %{
    "pos" => "bg-pos-soft text-pos",
    "warn" => "bg-warn-soft text-warn",
    "neg" => "bg-neg-soft text-neg",
    "neutral" => "bg-sunken text-ink-2"
  }

  @words %{"pos" => "ops.tone.pos", "warn" => "ops.tone.warn", "neg" => "ops.tone.neg"}

  @tones Map.keys(@bg)

  def tones, do: @tones

  @doc "The short tone of `tone` (`nil` and unknown names are `neutral`)."
  def tone(nil), do: "neutral"

  def tone(tone) when is_atom(tone), do: tone(Atom.to_string(tone))

  def tone(tone) when is_binary(tone) do
    short = tone_short(tone)
    if Map.has_key?(@bg, short), do: short, else: "neutral"
  end

  def tone(_), do: "neutral"

  def bg(t), do: @bg[tone(t)]
  def stroke(t), do: @stroke[tone(t)]
  def fill(t), do: @fill[tone(t)]
  def text(t), do: @text[tone(t)]
  def soft(t), do: @soft[tone(t)]
  def tag(t), do: @tag[tone(t)] || @tag["neutral"]

  @doc "The translated word of a tone (`pos` -> `good`)."
  def tone_word(t, locale),
    do: LedgerUI.I18n.t(Map.get(@words, tone(t), "ops.tone.neutral"), locale)

  @minus "−"

  @doc """
  A number in the locale: `1234.5` is `"1,234.5"` in `"en"` and `"1.234,5"` in `"pt_BR"`.
  `decimals` is the most digits after the separator; trailing zeros are dropped unless `pad: true`.
  """
  def number(value, locale, decimals \\ 1, opts \\ []) do
    loc = LedgerUI.I18n.locale(locale)
    {dsep, tsep} = if loc == "pt_BR", do: {",", "."}, else: {".", ","}
    v = value * 1.0
    rounded = Float.round(abs(v), decimals)
    neg? = v < 0 and rounded > 0
    str = :erlang.float_to_binary(rounded, decimals: decimals)
    [int, frac] = String.split(str <> if(decimals == 0, do: ".", else: ""), ".", parts: 2)

    frac =
      if opts[:pad], do: frac, else: String.trim_trailing(frac, "0")

    int = group(int, tsep)
    out = if frac == "", do: int, else: int <> dsep <> frac
    if neg?, do: @minus <> out, else: out
  end

  defp group(int, sep) do
    int
    |> String.reverse()
    |> String.replace(~r/(\d{3})(?=\d)/, "\\1" <> sep)
    |> String.reverse()
  end

  @doc "A value: integers as they are, floats with up to 1 decimal, in the locale."
  def value(v, locale) when is_integer(v), do: number(v, locale, 0)
  def value(v, locale) when is_float(v), do: number(v, locale, 1)
  def value(v, _locale), do: to_string(v)

  @doc "`45.5` is `\"45,5%\"`; `pad: true` keeps the zeros (`12.0` is `\"12,0%\"`)."
  def percent(v, locale, decimals \\ 1, opts \\ []), do: number(v, locale, decimals, opts) <> "%"

  @doc "`0.8` is `\"+0,8%\"`, `-9.9` is `\"−9,9%\"`."
  def signed_percent(v, locale, decimals \\ 1, opts \\ []) do
    cond do
      v > 0 -> "+" <> percent(v, locale, decimals, opts)
      v < 0 -> percent(v, locale, decimals, opts)
      true -> percent(0, locale, decimals, opts)
    end
  end

  @doc "`format.(v)` for a function, the locale format for `nil`."
  def fmt(nil, v, locale), do: value(v, locale)
  def fmt(fun, v, _locale) when is_function(fun, 1), do: fun.(v)

  def num(v) when is_integer(v), do: Integer.to_string(v)

  def num(v) when is_float(v) do
    r = Float.round(v, 2)
    if r == Float.round(r), do: Integer.to_string(round(r)), else: Float.to_string(r)
  end
end
