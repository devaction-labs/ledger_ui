defmodule LedgerShowcase.CanvasTest do
  use ExUnit.Case, async: true

  alias LedgerShowcase.{Canvas, Parity}

  @names %{"Thing" => "thing"}
  @secs %{"thing" => ["Um", "Dois", "Dois"]}

  defp refs(html), do: Canvas.board_refs(html, @names, @secs)

  test "leaf demos map to sections by title; em loop suffix and spec removed" do
    refs =
      refs("""
      <div class="lu-board"><section><h2>Thing</h2>
        <div class="lu-demo"><div class="lu-spec">Um · em loop</div><button class="lu-btn">A</button></div>
        <div class="lu-demo"><div class="lu-spec">Dois</div><b>x</b></div>
        <div class="lu-demo"><div class="lu-spec">Dois</div><b>y</b></div>
      </section></div>
      """)

    assert Map.keys(refs) |> Enum.sort() == [{"thing", 1}, {"thing", 2}, {"thing", 3}]
    assert [{"button", _, _}] = refs[{"thing", 1}]
    assert Parity.flatten(refs[{"thing", 2}]) |> hd() |> elem(1) == {:el, "b", []}
    assert [{"b", _, ["y"]}] = refs[{"thing", 3}]
  end

  test "nested demos: only leaves; unknown h2 and unknown titles are ignored" do
    refs =
      refs("""
      <section><h2>Other</h2><div class="lu-demo"><div class="lu-spec">Um</div>x</div></section>
      <section><h2>Thing</h2>
        <div class="lu-demo"><div class="lu-spec">Um</div>
          <div class="lu-demo"><div class="lu-spec">Dois</div><i>leaf</i></div>
        </div>
        <div class="lu-demo"><div class="lu-spec">Nope</div>z</div>
      </section>
      """)

    assert Map.keys(refs) == [{"thing", 2}, {"thing", 4}]
  end

  test "demos whose title matches no vitrine section are appended after the vitrine sections" do
    refs =
      refs("""
      <section><h2>Thing</h2>
        <div class="lu-demo"><div class="lu-spec">Novo A · em loop</div><i>a</i></div>
        <div class="lu-demo"><div class="lu-spec">Um</div>u</div>
        <div class="lu-demo"><div class="lu-spec">Novo B</div><i>b</i></div>
        <div class="lu-demo"><div class="lu-spec">Dois</div>d</div>
        <div class="lu-demo"><div class="lu-spec">Dois</div>d2</div>
        <div class="lu-demo"><div class="lu-spec">Dois</div>d3</div>
      </section>
      """)

    # vitrine has 3 sections: extras are 4 (Novo A), 5 (Novo B), 6 (third "Dois")
    assert Map.keys(refs) |> Enum.sort() == for(i <- 1..6, do: {"thing", i})
    assert {:extra, "Novo A", [{"i", _, ["a"]}]} = refs[{"thing", 4}]
    assert {:extra, "Novo B", _} = refs[{"thing", 5}]
    assert {:extra, "Dois", _} = refs[{"thing", 6}]
  end

  test "design/canvas/extras.json is the current list of canvas-only sections" do
    path = Path.expand("../../design/canvas/extras.json", __DIR__)
    json = Jason.encode!(Canvas.extras(), pretty: true) <> "\n"

    if System.get_env("UPDATE_CANVAS_EXTRAS") do
      File.write!(path, json)
    else
      assert File.read!(path) == json,
             "canvas changed: run `UPDATE_CANVAS_EXTRAS=1 mix test test/canvas_test.exs`"
    end
  end

  test "template escapes are normalized on both sides" do
    a = Parity.flatten(~s(<p>Olá {{cliente}}</p>))
    b = Parity.flatten(~s(<p>Olá { {cliente} }</p>))
    assert a == b
  end

  test "real boards resolve: canvas refs exist and sources are reported" do
    ref = Canvas.reference()
    assert map_size(ref) > 300
    assert Canvas.source("button", 1) in [:canvas, :vitrine]
    assert Canvas.source("no-such", 1) == :vitrine
  end
end
