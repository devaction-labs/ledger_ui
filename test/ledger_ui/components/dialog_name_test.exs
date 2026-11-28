defmodule LedgerUI.Components.DialogNameTest do
  # #114 (item 3): a dialog with `<:header>` has an accessible name and no dangling `aria-labelledby`.
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI

  import LedgerUI.DiffCase, only: [each_source: 3]

  defp render(fun, assigns), do: LedgerUI.DiffCase.html(fun, assigns)

  # every id an `aria-labelledby` points to exists in the HTML
  defp dangling(html) do
    ids = ~r/\sid="([^"]+)"/ |> Regex.scan(html, capture: :all_but_first) |> List.flatten()

    ~r/aria-labelledby="([^"]+)"/
    |> Regex.scan(html, capture: :all_but_first)
    |> List.flatten()
    |> Enum.flat_map(&String.split/1)
    |> Enum.reject(&(&1 in ids))
  end

  defp labelled(html), do: html =~ "aria-labelledby="

  def t_modal(assigns) do
    ~H"""
    <.modal id="m" layout={@layout} title={@title} aria-label={@aria} open={@open}>
      <:header :if={@header?}><b>Free header</b></:header>
      body
    </.modal>
    """
  end

  def t_drawer(assigns) do
    ~H"""
    <.drawer id="d" layout={@layout} title={@title} aria-label={@aria} open={@open}>
      <:header :if={@header?}><b>Free header</b></:header>
      body
    </.drawer>
    """
  end

  def t_sheet(assigns) do
    ~H"""
    <.sheet id="s" title={@title} aria-label={@aria} open={@open}>
      <:header :if={@header?}><b>Free header</b></:header>
      body
    </.sheet>
    """
  end

  defp base(layout, extra),
    do: Map.merge(%{layout: layout, title: nil, aria: nil, header?: false, open: true}, extra)

  @cases for fun <- [:t_modal, :t_drawer, :t_sheet],
             layout <- if(fun == :t_sheet, do: [nil], else: [nil, "page"]),
             do: {fun, layout}

  for {fun, layout} <- @cases do
    describe "#{fun} layout=#{inspect(layout)}" do
      test "only <:header>: named by the header, nothing dangling" do
        html =
          render(&apply(__MODULE__, unquote(fun), [&1]), base(unquote(layout), %{header?: true}))

        assert labelled(html)
        assert dangling(html) == []
      end

      test "title and <:header> together: nothing dangling" do
        html =
          render(
            &apply(__MODULE__, unquote(fun), [&1]),
            base(unquote(layout), %{header?: true, title: "Title"})
          )

        assert labelled(html)
        assert dangling(html) == []
      end

      test "only a title keeps the same name element as before" do
        html =
          render(&apply(__MODULE__, unquote(fun), [&1]), base(unquote(layout), %{title: "Title"}))

        assert dangling(html) == []
        assert html =~ ~r/id="[a-z]-title"/
      end

      test "neither: no aria-labelledby" do
        html = render(&apply(__MODULE__, unquote(fun), [&1]), base(unquote(layout), %{}))
        refute labelled(html)
      end

      test "an aria-label replaces the name from the header" do
        html =
          render(
            &apply(__MODULE__, unquote(fun), [&1]),
            base(unquote(layout), %{header?: true, aria: "Order"})
          )

        refute labelled(html)
        assert html =~ ~s(aria-label="Order")
        # on the dialog, not only on the backdrop
        assert html =~
                 ~r/<(div|aside)[^>]*(role="dialog"[^>]*aria-label="Order"|aria-label="Order"[^>]*role="dialog")/
      end
    end
  end

  test "the header of the page layout carries the id" do
    html = render(&t_modal/1, base("page", %{header?: true}))
    assert html =~ ~r/<header[^>]*id="m-title"/
    html = render(&t_drawer/1, base("page", %{header?: true}))
    assert html =~ ~r/<header[^>]*id="d-title"/
  end

  test "the header container of the canvas dialogs carries the id" do
    assert render(&t_modal/1, base(nil, %{header?: true})) =~
             ~r/<div[^>]*id="m-title"[^>]*data-part="modal-header"/

    assert render(&t_drawer/1, base(nil, %{header?: true})) =~
             ~r/<div[^>]*id="d-title"[^>]*data-part="drawer-header"/
  end

  test "toggling the header patches like a fresh render" do
    each_source(&t_modal/1, base(nil, %{}), header?: true, title: "T", aria: "A")
    each_source(&t_drawer/1, base(nil, %{}), header?: true, title: "T", aria: "A")
    each_source(&t_modal/1, base("page", %{}), header?: true, title: "T")
    each_source(&t_drawer/1, base("page", %{}), header?: true, title: "T")
  end
end
