defmodule LedgerUI.Perf.LinkTest do
  # #97: `heading`, `text` and the components over `<.link>` write their tag in the template, so
  # a new body is the only thing in the patch (before, the opening tag went again each time).
  use ExUnit.Case, async: true

  import LedgerUI.DiffCase

  defmodule W do
    use Phoenix.Component
    use LedgerUI

    def heading_(assigns), do: ~H"<.heading>{@body}</.heading>"
    def heading_style(assigns), do: ~H|<.heading level={3} style="color:red">{@body}</.heading>|
    def text_(assigns), do: ~H"<.text>{@body}</.text>"
    def text_span(assigns), do: ~H|<.text as="span" size="sm">{@body}</.text>|
    def texts(assigns), do: ~H|<div>
  <.text :for={i <- 1..100}>{@body}{i}</.text>
</div>|
    def text_link_(assigns), do: ~H|<.text_link navigate="/x">{@body}</.text_link>|
    def button_navigate(assigns), do: ~H|<.button navigate="/x">{@body}</.button>|
    def button_patch(assigns), do: ~H|<.button patch="/x">{@body}</.button>|
    def button_href(assigns), do: ~H|<.button href="/x">{@body}</.button>|
    def nav_link(assigns), do: ~H|<.sidebar_nav_link navigate="/x">{@body}</.sidebar_nav_link>|
    def item(assigns), do: ~H|<.dropdown_item navigate="/x">{@body}</.dropdown_item>|

    def nav_links(assigns),
      do: ~H|<.navbar_links items={[%{label: @body, href: "/a"}]} />|
  end

  @base %{body: "aaa"}

  # a body of the same size as the one before, so that the patch is the same for any text
  for {name, fun, max} <- [
        {"heading", &W.heading_/1, 30},
        {"heading with style", &W.heading_style/1, 60},
        {"text", &W.text_/1, 30},
        {"text as span", &W.text_span/1, 30},
        {"text_link", &W.text_link_/1, 30},
        {"button navigate", &W.button_navigate/1, 60},
        {"button patch", &W.button_patch/1, 60},
        {"button href", &W.button_href/1, 60},
        {"sidebar_nav_link", &W.nav_link/1, 30},
        {"dropdown_item", &W.item/1, 80},
        {"navbar_links", &W.nav_links/1, 80}
      ] do
    test "#{name}: a new body sends at most #{max} bytes" do
      json = check(unquote(fun), @base, body: "bbb")
      assert byte_size(json) <= unquote(max), "#{byte_size(json)} B: #{json}"
    end
  end

  test "100 texts with a new body: at most 3 000 bytes" do
    json = check(&W.texts/1, @base, body: "bbb")
    assert byte_size(json) <= 3_000, "#{byte_size(json)} B"
  end
end
