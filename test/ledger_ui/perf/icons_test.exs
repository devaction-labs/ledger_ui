defmodule LedgerUI.Perf.IconsTest do
  # #85 (icons): a built-in icon's shapes are the static part of its `Rendered`, so the LiveView
  # sends them once per page (shared by every occurrence in a list) and never again on a
  # re-render. The HTML must stay the same as the old `{:safe, [head, class, mid, attrs, tail]}`.
  use ExUnit.Case, async: false
  use Phoenix.Component

  import LedgerUI.DiffCase
  import LedgerUI.IconFixtures
  import LedgerUI.Components.Icon, only: [icon: 1]

  alias LedgerUI.Components.Icon

  @icons "../../../priv/icons.json" |> Path.expand(__DIR__) |> File.read!() |> Jason.decode!()

  @base "inline flex-none fill-none stroke-current stroke-[1.75] [stroke-linecap:round] [stroke-linejoin:round] align-middle"

  @defaults %{
    name: nil,
    size: "base",
    class: nil,
    boxed: false,
    tone: nil,
    box_size: nil,
    box_class: nil,
    rest: %{},
    inner_block: []
  }

  # The old rendering, spelled out: the class and attrs strings between the three parts (the
  # attrs come with two leading spaces: the old code added one to the one `attributes_escape` adds).
  defp reference(name, class, attrs) do
    inner = Map.fetch!(@icons, name)

    ~s(<svg class="#{class}" viewBox="0 0 24 24" aria-hidden="true" data-icon="#{name}"#{attrs}>) <>
      inner <> "</svg>"
  end

  defp render(a), do: html(&Icon.icon/1, Map.merge(@defaults, a))

  test "HTML of every built-in icon is the old markup (sizes, class, rest attrs)" do
    cases = [
      {%{}, "#{@base} size-[18px]", ""},
      {%{size: "sm"}, "#{@base} size-3.5", ""},
      {%{size: "xl", class: "text-ink mt-1"}, "#{@base} size-7 text-ink mt-1", ""},
      {%{size: nil}, "#{@base} size-[18px]", ""},
      {%{size: "nope"}, "#{@base}", ""},
      {%{class: ["a", false, "b"]}, "#{@base} size-[18px] a b", ""},
      {%{class: "x\"<&"}, "#{@base} size-[18px] x&quot;&lt;&amp;", ""},
      {%{rest: %{"data-x": "1", id: "i<d"}, size: "md"}, "#{@base} size-4",
       ~s(  id="i&lt;d" data-x="1")}
    ]

    for name <- Map.keys(@icons), {attrs, class, rest} <- cases do
      assert render(Map.put(attrs, :name, name)) == reference(name, class, rest),
             "#{name} #{inspect(attrs)}"
    end
  end

  test "huge-* names, unknown names and the boxed icon" do
    assert render(%{name: "huge-download-01"}) == render(%{name: "download"})
    assert render(%{name: "hugeicons:download"}) == render(%{name: "download"})
    assert render(%{name: "nope"}) == ""

    boxed = render(%{name: "download", boxed: true, tone: "success", rest: %{id: "b"}})
    assert boxed =~ ~s(<span data-part="icon-box" class=")
    assert boxed =~ ~s(id="b")
    assert boxed =~ reference("download", "#{@base} size-[18px]", "")

    slot = [%{__slot__: :inner_block, inner_block: fn _, _ -> "SLOT" end}]
    assert render(%{name: "download", boxed: true, inner_block: slot}) =~ "SLOT"
    refute render(%{name: "download", boxed: true, inner_block: slot}) =~ "<svg"
  end

  defp list(assigns), do: ~H|<.icon :for={n <- @names} name={n} />|
  defp list_box(assigns), do: ~H|<.icon :for={n <- @names} name={n} boxed tone="success" />|

  defp rows(assigns),
    do: ~H|<div :for={{n, l} <- @items}><.icon name={n} /> {l}</div>|

  defp button(assigns),
    do: ~H|<button><.icon name="download" /> {@label}</button>|

  defp paths(json), do: json |> String.split("<path") |> length() |> Kernel.-(1)

  test "100 equal icons send the shapes once, and well under a quarter of the old diff" do
    {json, html} = first(&list/1, %{names: List.duplicate("download", 100)})
    assert html =~ ~s(data-icon="download")
    assert paths(json) == 2, "the two shapes of `download` appear once (in the shared template)"
    # the old diff of this list was 44066 bytes
    assert byte_size(json) * 4 < 44_066
  end

  test "100 equal boxed icons send the shapes once" do
    {json, _html} = first(&list_box/1, %{names: List.duplicate("download", 100)})
    assert paths(json) == 2
    # the old diff of this list was 58925 bytes
    assert byte_size(json) * 2 < 58_925
  end

  test "a list with two different icons carries each icon's shapes once" do
    names = Enum.flat_map(1..50, fn _ -> ["download", "check-circle"] end)
    {json, _html} = first(&list/1, %{names: names})
    assert paths(json) == paths(elem(first(&list/1, %{names: ["download", "check-circle"]}), 0))
    assert byte_size(json) * 4 < 96_766
  end

  test "re-rendering the parent without changing the icon does not resend any shape" do
    names = List.duplicate("download", 10)
    # the parent re-renders the list item by item with only the text changing
    items = fn l -> Enum.map(1..10, &{"download", "#{l}#{&1}"}) end
    json = patch(&rows/1, %{items: items.("a")}, items: items.("b"))
    refute json =~ "<path"
    refute json =~ "<svg"
    refute json =~ "stroke-linecap"
    assert names != []

    json = check(&button/1, %{label: "A"}, label: "B")
    refute json =~ "<path"
    refute json =~ "stroke-"
  end

  test "each source of the class and attrs reaches the client (built-in icon)" do
    base = Map.put(@defaults, :name, "download")

    each_source(&Icon.icon/1, base,
      size: "lg",
      class: "text-ink",
      rest: %{id: "x"},
      name: "check-circle"
    )

    json = patch(&Icon.icon/1, base, size: "lg")
    refute json =~ "<path"
    refute json =~ "stroke-linecap"
  end

  test "each source of the boxed icon reaches the client" do
    base = Map.merge(@defaults, %{name: "download", boxed: true})

    each_source(&Icon.icon/1, base,
      name: "check-circle",
      size: "lg",
      class: "text-ink",
      tone: "error",
      box_size: "lg",
      box_class: "m-2",
      rest: %{id: "x"}
    )

    json = patch(&Icon.icon/1, base, tone: "error")
    refute json =~ "<path"
  end

  describe "vendored icons" do
    setup do
      dir = tmp_dir("perf_icons")
      Application.put_env(:ledger_ui, :icons_path, dir)

      on_exit(fn ->
        LedgerUI.Icons.reload()
        Application.delete_env(:ledger_ui, :icons_path)
      end)

      {:ok, dir: dir}
    end

    test "still render through the dynamic path, with the same markup", %{dir: dir} do
      {:ok, inner} = LedgerUI.Icons.Hugeicons.convert(upstream_svg())
      File.write!(Path.join(dir, "search-01.svg"), LedgerUI.Icons.Hugeicons.wrap(inner))
      LedgerUI.Icons.reload()

      html = render(%{name: "huge-search-01", size: "sm", rest: %{id: "v"}})

      assert html ==
               ~s(<svg class="#{@base} size-3.5" viewBox="0 0 24 24" aria-hidden="true") <>
                 ~s( data-icon="search-01"  id="v"><path d="M17 17L21 21"/>) <>
                 ~s(<circle cx="11" cy="11" r="8"/></svg>)

      base = Map.put(@defaults, :name, "huge-search-01")
      each_source(&Icon.icon/1, base, size: "lg", class: "c", rest: %{id: "y"})
      assert render(%{name: "huge-search-01", boxed: true}) =~ "circle"
    end
  end
end
