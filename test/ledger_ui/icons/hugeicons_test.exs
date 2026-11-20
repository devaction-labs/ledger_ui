defmodule LedgerUI.Icons.HugeiconsTest do
  use ExUnit.Case, async: true

  alias LedgerUI.Icons.Hugeicons
  import LedgerUI.IconFixtures

  doctest LedgerUI.Icons.Hugeicons

  test "convert keeps geometry and drops stroke attributes and the hard-coded colour" do
    assert {:ok, inner} = Hugeicons.convert(upstream_svg())
    assert inner == ~s(<path d="M17 17L21 21"/><circle cx="11" cy="11" r="8"/>)
    refute inner =~ "141B34"
  end

  test "a solid fill becomes currentColor without a stroke" do
    svg = ~s(<svg><path d="M0 0H1V1Z" fill="#141B34" fill-rule="evenodd"/></svg>)

    assert {:ok, ~s(<path d="M0 0H1V1Z" fill-rule="evenodd" fill="currentColor" stroke="none"/>)} =
             Hugeicons.convert(svg)
  end

  test "only shapes and known attributes survive" do
    svg =
      ~s|<svg><script>alert(1)</script><path d="M0 0" onload="x()" style="x"/><use href="#a"/></svg>|

    assert {:ok, ~s(<path d="M0 0"/>)} = Hugeicons.convert(svg)
  end

  test "no shapes is an error" do
    assert {:error, :no_shapes} = Hugeicons.convert("<svg></svg>")
  end

  test "wrap and inner round trip" do
    {:ok, inner} = Hugeicons.convert(upstream_svg())
    wrapped = Hugeicons.wrap(inner)
    assert wrapped =~ ~s(stroke="currentColor" stroke-width="1.5")
    assert {:ok, ^inner} = Hugeicons.inner(wrapped)
    assert :error = Hugeicons.inner("not svg")
  end

  test "names_in finds icon tags and huge-* tokens" do
    text = """
    <.icon name="huge-search-01" />
    <.icon
      name="download" class="x"/>
    <.icon name={@dynamic} />
    <.icon name="hugeicons:tick-02" />
    <.button icon="huge-invoice-01">x</.button>
    Not "huge-" or HUGE-up. <.icon name="Bad Name" />
    """

    assert Hugeicons.names_in(text) == ~w(download invoice-01 search-01 tick-02)
  end

  test "scan reads sources under roots and skips node_modules" do
    root = tmp_dir("scan")
    File.mkdir_p!(Path.join(root, "node_modules/x"))
    File.write!(Path.join(root, "a.heex"), ~s(<.icon name="huge-a-01" />))
    File.write!(Path.join(root, "b.ex"), ~s(~H"<.icon name='b-02' />"))
    File.write!(Path.join(root, "c.png"), "huge-png-01")
    File.write!(Path.join(root, "node_modules/x/d.js"), "huge-vendor-01")

    assert Hugeicons.scan([root]) == ["a-01", "b-02"]
  end
end
