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

    # the rest of the components over `<.link>` (#97)
    def pager(assigns),
      do: ~H|<.pagination page={@page} total_pages={20} patch={&"/x?page=#{&1}"} />|

    def login(assigns), do: ~H|<.landing_login navigate="/x">{@body}</.landing_login>|
    def cta(assigns), do: ~H|<.landing_cta navigate="/x">{@body}</.landing_cta>|
    def cta_href(assigns), do: ~H|<.landing_cta href="/x">{@body}</.landing_cta>|
    def feature(assigns), do: ~H|<.landing_feature navigate="/x" title={@body} />|
    def oauth(assigns), do: ~H|<.oauth_button provider="google" href="/a">{@body}</.oauth_button>|

    def oauth_block(assigns),
      do: ~H|<.oauth_button provider="google" href="/a" block>{@body}</.oauth_button>|

    def card_link(assigns), do: ~H|<.card navigate="/x">{@body}</.card>|
    def menu_item_(assigns), do: ~H|<.menu_item navigate="/x">{@body}</.menu_item>|
    def menu_row_(assigns), do: ~H|<.menu_row navigate="/x" title={@body} />|

    def tabs_(assigns),
      do: ~H|<.tabs id="t" selected="a">
  <:tab name="a" patch="/a">{@body}</:tab>
</.tabs>|

    def switcher(assigns),
      do:
        ~H|<.view_switcher id="v" value="a" views={[%{label: @body, value: "a", patch: "/a"}]} />|

    def trace_(assigns), do: ~H|<.trace_line navigate="/x" title={@body} />|
    def rail(assigns), do: ~H|<.rail_link navigate="/x" label={@body} />|

    def min_link(assigns),
      do: ~H|<.sidebar_min_link navigate="/x" label="m">{@body}</.sidebar_min_link>|

    def main_link(assigns),
      do: ~H|<.main_sidebar_link navigate="/x" label="m">{@body}</.main_sidebar_link>|

    def nav_menu_item(assigns),
      do: ~H|<.navbar_menu_item navigate="/a">{@body}</.navbar_menu_item>|

    def hnav_link(assigns),
      do: ~H|<.horizontal_nav_link navigate="/h">{@body}</.horizontal_nav_link>|
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
        {"navbar_links", &W.nav_links/1, 80},
        {"landing_login", &W.login/1, 40},
        {"landing_cta navigate", &W.cta/1, 70},
        {"landing_cta href", &W.cta_href/1, 70},
        {"landing_feature", &W.feature/1, 40},
        {"oauth_button", &W.oauth/1, 70},
        {"oauth_button block", &W.oauth_block/1, 70},
        {"card link", &W.card_link/1, 150},
        {"menu_item link", &W.menu_item_/1, 80},
        {"menu_row link", &W.menu_row_/1, 70},
        {"tabs link", &W.tabs_/1, 100},
        {"view_switcher link", &W.switcher/1, 100},
        {"trace_line link", &W.trace_/1, 130},
        {"rail_link", &W.rail/1, 40},
        {"sidebar_min_link", &W.min_link/1, 40},
        {"main_sidebar_link", &W.main_link/1, 50},
        {"navbar_menu_item", &W.nav_menu_item/1, 50},
        {"horizontal_nav_link", &W.hnav_link/1, 40}
      ] do
    test "#{name}: a new body sends at most #{max} bytes" do
      json = check(unquote(fun), @base, body: "bbb")
      assert byte_size(json) <= unquote(max), "#{byte_size(json)} B: #{json}"
    end
  end

  test "pagination: changing the page with `patch` links sends less than before (1 330 B, 2 673 B)" do
    next = fn page -> patch(&W.pager/1, %{page: 3}, page: page) end
    assert byte_size(next.(4)) <= 700
    assert byte_size(next.(12)) <= 2_400
  end

  test "100 texts with a new body: at most 3 000 bytes" do
    json = check(&W.texts/1, @base, body: "bbb")
    assert byte_size(json) <= 3_000, "#{byte_size(json)} B"
  end
end
