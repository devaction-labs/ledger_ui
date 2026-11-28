defmodule LedgerUI.SlotStalenessTest do
  # #91: a slot a component hands to a child under another attr name (`icons={@icon}`,
  # `drawer={@mobile_drawer}`, `slot={@event}`) is redrawn only if the child draws it with
  # `render_slot_full`; otherwise a body that reads an assign of the caller stays stale. Each case
  # changes `@x` alone and asserts that the patch applied equals a fresh render.
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI

  import LedgerUI.DiffCase

  defp t_dropdown_item(assigns) do
    ~H"""
    <.dropdown_item><:icon><.icon name={@x} /></:icon>Edit</.dropdown_item>
    """
  end

  defp t_sidebar_drawer(assigns) do
    ~H"""
    <.sidebar>
      <:item name="a" href="/a">A</:item>
      <:mobile_drawer>{@x}</:mobile_drawer>
    </.sidebar>
    """
  end

  defp t_shell_drawer(assigns) do
    ~H"""
    <.shell id="sh" current="a" nav={[%{name: "a", label: "A", href: "/a"}]}>
      <:mobile_drawer>{@x}</:mobile_drawer>
      page
    </.shell>
    """
  end

  defp t_sidebar_view(assigns) do
    ~H"""
    <.sidebar>
      <:item name="a" href="/a">A</:item>
      <:view name="v" href="/v">{@x}</:view>
    </.sidebar>
    """
  end

  @events [%{id: 1, date: ~D[2026-03-10], title: "E", start: "09:00", end: "10:00"}]

  defp t_calendar(assigns) do
    ~H"""
    <.calendar id="cal" view={@view} date={~D[2026-03-10]} events={@events}>
      <:event :let={e}>{e.title} {@x}</:event>
    </.calendar>
    """
  end

  defp t_tabs(assigns) do
    ~H"""
    <.tabs id="tb" selected="a">
      <:tab name="a">A</:tab>
      <:panel name={@x}>P</:panel>
    </.tabs>
    """
  end

  test "dropdown_item :icon" do
    check(&t_dropdown_item/1, %{x: "edit"}, x: "trash")
  end

  test "sidebar :mobile_drawer" do
    check(&t_sidebar_drawer/1, %{x: "a"}, x: "b")
  end

  test "shell :mobile_drawer" do
    check(&t_shell_drawer/1, %{x: "a"}, x: "b")
  end

  test "sidebar :view" do
    check(&t_sidebar_view/1, %{x: "a"}, x: "b")
  end

  for view <- ~w(month week) do
    test "calendar :event (#{view})" do
      check(&t_calendar/1, %{x: "a", view: unquote(view), events: @events}, x: "b")
    end
  end

  test "tabs: the name of a :panel is a source of the settle" do
    check(&t_tabs/1, %{x: "a"}, x: "zz")
  end
end
