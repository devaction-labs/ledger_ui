defmodule LedgerShowcase.HeroStatCanvasTest do
  @moduledoc """
  Parity of the demos of `hero-card` (sections 01..04) and `stat` (01..05) against
  their canvas demo bodies, read straight from the boards. Their vitrine sections are retired
  (`design/canvas/retired.json`), so the canvas demos are the whole list; this test does not depend on that numbering
  infrastructure, only on `LedgerShowcase.Parity` and the board parser of `LedgerShowcase.Canvas`.
  """
  use ExUnit.Case, async: true

  alias LedgerShowcase.{Canvas, Parity}

  @design Path.expand("../../design/canvas", __DIR__)

  @cases [
    {"hero-card", "HeroCard", "G06ExibicaoClaro2.dc.html", 0,
     [
       "A saudação entra, a paisagem respira e a meta enche",
       "size",
       "variant",
       "<:icon> · <:inner_block> · sem arte"
     ]},
    {"stat", "Stat", "G07MetricasEGraficosClaro.dc.html", 0,
     [
       "Os números sobem, a linha se desenha e a variação aparece",
       "stat_group · card e variant",
       "stat_item · tone × size · unit",
       "Variação, meta e tendência",
       "No contexto: resumo do pedido"
     ]}
  ]

  for {id, name, file, vitrine, titles} <- @cases do
    describe "#{id} canvas demos" do
      for {title, k} <- Enum.with_index(titles, 1) do
        test "#{String.pad_leading("#{vitrine + k}", 2, "0")} #{title}" do
          id = unquote(id)
          index = unquote(vitrine + k)

          refs =
            Canvas.board_refs(
              File.read!(Path.join(@design, unquote(file))),
              %{unquote(name) => id},
              %{id => unquote(titles)}
            )

          expected = refs |> Map.fetch!({id, unquote(k)}) |> Parity.flatten()
          actual = id |> Parity.actual_html(index) |> Parity.flatten()

          mismatches = expected |> Parity.diff(actual) |> Enum.reject(&Parity.extras_only?/1)
          assert mismatches == [], inspect(Enum.take(mismatches, 5), pretty: true, limit: 50)
        end
      end
    end
  end
end
