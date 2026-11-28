defmodule LedgerUI.LinkAttrsTest do
  # `LedgerUI.LinkAttrs.resolve/2` must give an `<a>` with the same attributes as
  # `Phoenix.Component.link/1`: if a Phoenix LiveView upgrade changes what `<.link>` emits, this
  # fails instead of the components drifting from it. The order of the attributes is not compared.
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  defp via_link(attrs) do
    assigns = %{attrs: attrs}
    rendered_to_string(~H|<.link {@attrs}>x</.link>|)
  end

  defp via_resolve(attrs) do
    assigns = %{attrs: LedgerUI.LinkAttrs.resolve(attrs)}
    rendered_to_string(~H|<a {@attrs}>x</a>|)
  end

  # `<a a="1" b>` -> sorted list of attributes; the CSRF token is random per call.
  defp attrs_of(html) do
    [_, attrs] = Regex.run(~r/^<a((?:\s+[^\s=>]+(?:="[^"]*")?)*)>x<\/a>$/, html)

    ~r/\s+([^\s=>]+(?:="[^"]*")?)/
    |> Regex.scan(attrs, capture: :all_but_first)
    |> List.flatten()
    |> Enum.map(&Regex.replace(~r/^data-csrf=".*"$/, &1, "data-csrf=TOKEN"))
    |> Enum.sort()
  end

  @cases [
    [navigate: "/a"],
    [navigate: "/a", replace: true],
    [patch: "/a"],
    [patch: "/a", replace: true],
    [navigate: "/a", patch: "/b", href: "/c"],
    [patch: "/b", href: "/c"],
    [href: "/a"],
    [href: "/a?x=1&y=2"],
    [href: "https://example.com/a"],
    [href: "/a", method: "post"],
    [href: "/a", method: "delete", csrf_token: "tok"],
    [href: "/a", method: "put", csrf_token: false],
    [href: "#"],
    [href: nil],
    [navigate: nil, href: "/a"],
    [],
    [navigate: "/a", "aria-label": "L", target: "_blank", rel: "noopener", download: true]
  ]

  for attrs <- @cases do
    test "same attributes as <.link> for #{inspect(attrs)}" do
      attrs = unquote(Macro.escape(attrs))
      assert attrs_of(via_resolve(attrs)) == attrs_of(via_link(attrs))
    end
  end

  test "an attribute the component writes itself is not repeated from the rest" do
    resolved =
      LedgerUI.LinkAttrs.resolve(%{:navigate => "/a", "data-part" => "x", :"aria-label" => "L"}, [
        "data-part"
      ])

    refute Map.has_key?(resolved, "data-part")
    assert resolved[:"aria-label"] == "L"
  end

  test "destinations are validated as <.link> does" do
    assert_raise ArgumentError, fn -> LedgerUI.LinkAttrs.resolve(navigate: "javascript:x") end
    assert_raise ArgumentError, fn -> LedgerUI.LinkAttrs.resolve(href: "javascript:alert(1)") end
  end
end
