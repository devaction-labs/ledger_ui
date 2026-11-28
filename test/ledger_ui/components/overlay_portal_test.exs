defmodule LedgerUI.Components.OverlayPortalTest do
  # #110: the opt-in `portal` of modal, drawer and command_palette (`false` is the HTML as it was).
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI

  import LedgerUI.DiffCase, only: [check: 3, each_source: 3]
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  defp render(fun, assigns), do: LedgerUI.DiffCase.html(fun, assigns)

  # -- portal -----------------------------------------------------------------------------

  def p_modal(assigns) do
    ~H"""
    <.modal id="m" title={@title} portal={@portal} layout={@layout} open={@open}>body {@body}</.modal>
    """
  end

  def p_drawer(assigns) do
    ~H"""
    <.drawer id="d" title={@title} portal={@portal} layout={@layout} open={@open}>
      body {@body}
    </.drawer>
    """
  end

  def p_palette(assigns) do
    ~H"""
    <.command_palette
      id="p"
      portal={@portal}
      inline={@inline}
      defer_items={@defer}
      placeholder={@ph}
      items={[%{label: "A", icon: "plus"}]}
    />
    """
  end

  defp pb, do: %{title: "T", portal: false, layout: nil, open: true, body: "x"}

  defp inner(html) do
    [_, inner] =
      Regex.run(~r/<div id="_lv_portal_wrap_[^"]+"[^>]*>(.*)<\/div>\s*<\/template>\s*$/s, html)

    inner
  end

  for {name, fun, base} <- [
        {"modal", :p_modal, quote(do: pb())},
        {"modal page", :p_modal, quote(do: %{pb() | layout: "page"})},
        {"drawer", :p_drawer, quote(do: pb())},
        {"drawer page", :p_drawer, quote(do: %{pb() | layout: "page"})}
      ] do
    describe "portal in #{name}" do
      test "false is the default HTML and true wraps it in a portal to body" do
        f = &apply(__MODULE__, unquote(fun), [&1])
        base = unquote(base)
        plain = render(f, base)
        refute plain =~ "data-phx-portal"
        assert plain == render(f, Map.delete(base, :portal) |> Map.put(:portal, false))

        html = render(f, %{base | portal: true})
        assert html =~ ~s(data-phx-portal="body")
        assert html =~ ~r/<template id="[a-z]-portal"/
        assert html =~ "_lv_portal_wrap_"
        # the same markup inside
        assert String.trim(inner(html)) == String.trim(plain)
      end

      test "a string is the target selector" do
        f = &apply(__MODULE__, unquote(fun), [&1])
        html = render(f, %{unquote(base) | portal: "#modals"})
        assert html =~ ~s(data-phx-portal="#modals")
      end

      test "the patch with a portal is the same as a fresh render" do
        f = &apply(__MODULE__, unquote(fun), [&1])
        each_source(f, %{unquote(base) | portal: true}, title: "Other", body: "y", open: false)
      end
    end
  end

  test "inline ignores the portal" do
    html = render(&p_modal/1, Map.merge(pb(), %{portal: true}))
    assert html =~ "data-phx-portal"

    inline = fn a ->
      assigns = a
      ~H|<.modal id="m" inline portal>body</.modal>|
    end

    refute rendered_to_string(inline.(%{})) =~ "data-phx-portal"
  end

  describe "portal in command_palette" do
    defp cb, do: %{portal: false, inline: false, defer: false, ph: "Search"}

    test "false: unchanged; true: inside a portal; inline: ignored" do
      plain = render(&p_palette/1, cb())
      refute plain =~ "data-phx-portal"
      html = render(&p_palette/1, %{cb() | portal: true})
      assert html =~ ~s(data-phx-portal="body")
      assert String.trim(inner(html)) == String.trim(plain)
      refute render(&p_palette/1, %{cb() | portal: true, inline: true}) =~ "data-phx-portal"
    end

    test "defer_items inside a portal" do
      html = render(&p_palette/1, %{cb() | portal: "#top", defer: true})
      assert html =~ ~s(data-phx-portal="#top")
      assert html =~ "palette-data"
    end

    test "a new placeholder with a portal sends little and patches like a fresh render" do
      size = byte_size(check(&p_palette/1, %{cb() | portal: true}, ph: "Other"))
      IO.puts("MEASURE palette portal placeholder: #{size}")
      assert size < 1500
    end
  end
end
