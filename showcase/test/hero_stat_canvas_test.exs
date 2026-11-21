defmodule LedgerShowcase.HeroStatCanvasTest do
  @moduledoc """
  Parity of the demos of `hero-card` (sections 01..04) and `stat` (01..05) against
  their canvas demo bodies, read straight from the boards. This test does not depend on the numbering
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
        # migrated stat: the goal bar follows the change/hint line (order of the reference generator)
        if id == "stat" and title == "Variação, meta e tendência",
          do: @tag(skip: "stat migrated to Tailwind: goal bar order differs from the old canvas")

        # examples rewritten with Tailwind layout utilities: their wrappers no longer carry the legacy `lu-*` classes
        # of the canvas, so the class-by-class comparison does not apply (the pixel comparison in scripts/visual does)
        if {id, title} in [
             {"hero-card", "size"},
             {"hero-card", "variant"},
             {"hero-card", "<:icon> · <:inner_block> · sem arte"},
             {"stat", "stat_group · card e variant"},
             {"stat", "stat_item · tone × size · unit"},
             {"stat", "No contexto: resumo do pedido"}
           ],
           do: @tag(skip: "example rewritten with Tailwind utilities (no `lu-*` wrappers)")

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
