defmodule LedgerUI.Components.DialogDefaultNameTest do
  # #114: a `role="dialog"` always has a name. With a title, a `<:header>` or an `aria-label` it is
  # theirs; with none of them the dialog gets a generic one instead of none.
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI

  import LedgerUI.DiffCase, only: [html: 2, check: 3]

  def t_modal(assigns),
    do: ~H"""
    <.modal id="m" layout={@layout} open locale={@locale} title={@title} aria-label={@aria}>
      body
    </.modal>
    """

  def t_drawer(assigns),
    do: ~H"""
    <.drawer id="d" layout={@layout} open locale={@locale} title={@title} aria-label={@aria}>
      body
    </.drawer>
    """

  def t_sheet(assigns),
    do: ~H"""
    <.sheet id="s" open locale={@locale} title={@title} aria-label={@aria}>body</.sheet>
    """

  def t_popover(assigns),
    do: ~H"""
    <.popover id="p" locale={@locale} label={@label}>
      <:trigger :let={t}><button {t}>open</button></:trigger>
      body
    </.popover>
    """

  @base %{layout: nil, locale: nil, title: nil, aria: nil, label: nil}

  defp dialog(html) do
    [tag] = Regex.run(~r/<[a-z]+[^>]*role="dialog"[^>]*>/, html)
    tag
  end

  for {name, fun, layouts} <- [
        {"modal", :t_modal, [nil, "page"]},
        {"drawer", :t_drawer, [nil, "page"]},
        {"sheet", :t_sheet, [nil]}
      ],
      layout <- layouts do
    describe "#{name} layout=#{inspect(layout)}" do
      @describetag fun: fun, layout: layout

      test "nothing names it: a generic name", %{fun: fun, layout: layout} do
        tag = dialog(html(Function.capture(__MODULE__, fun, 1), %{@base | layout: layout}))
        assert tag =~ ~s(aria-label="Dialog")
        refute tag =~ "aria-labelledby"
      end

      test "pt_BR", %{fun: fun, layout: layout} do
        tag =
          dialog(
            html(Function.capture(__MODULE__, fun, 1), %{@base | layout: layout, locale: "pt_BR"})
          )

        assert tag =~ ~s(aria-label="Diálogo")
      end

      test "a title names it: no generic name", %{fun: fun, layout: layout} do
        tag =
          dialog(
            html(Function.capture(__MODULE__, fun, 1), %{@base | layout: layout, title: "Hi"})
          )

        assert tag =~ "aria-labelledby"
        refute tag =~ ~s(aria-label=)
      end

      test "an aria-label names it, on the dialog itself", %{fun: fun, layout: layout} do
        tag =
          dialog(
            html(Function.capture(__MODULE__, fun, 1), %{@base | layout: layout, aria: "Order"})
          )

        assert tag =~ ~s(aria-label="Order")
        refute tag =~ ~s(aria-label="Dialog")
        refute tag =~ "aria-labelledby"
      end

      test "the patch for a new title is a fresh render", %{fun: fun, layout: layout} do
        f = Function.capture(__MODULE__, fun, 1)
        check(f, %{@base | layout: layout}, title: "T")
        check(f, %{@base | layout: layout}, aria: "A")
        check(f, %{@base | layout: layout}, locale: "pt_BR")
      end
    end
  end

  describe "popover" do
    test "nothing names it: a generic name; a label or a title replaces it" do
      assert dialog(html(&t_popover/1, @base)) =~ ~s(aria-label="Dialog")
      assert dialog(html(&t_popover/1, %{@base | locale: "pt_BR"})) =~ ~s(aria-label="Diálogo")
      assert dialog(html(&t_popover/1, %{@base | label: "Filters"})) =~ ~s(aria-label="Filters")
    end

    test "the patch for a new label or locale is a fresh render" do
      check(&t_popover/1, @base, label: "Filters")
      check(&t_popover/1, @base, locale: "pt_BR")
    end
  end
end
