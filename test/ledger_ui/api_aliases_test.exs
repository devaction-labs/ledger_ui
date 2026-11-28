defmodule LedgerUI.ApiAliasesTest do
  # #102: opt-in attrs that remove the reason to wrap a component. The default HTML is unchanged;
  # each alias renders the same as the long form.
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI

  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]
  import LedgerUI.DiffCase

  defp r(assigns), do: assigns |> rendered_to_string() |> String.replace(~r/\s+/, " ")

  test "dropdown_item icon_name string == the :icon slot" do
    assigns = %{}
    a = r(~H|<.dropdown_item><:icon><.icon name="edit" /></:icon>Edit</.dropdown_item>|)
    b = r(~H|<.dropdown_item icon_name="edit">Edit</.dropdown_item>|)
    assert a == b
    assert b =~ "Edit"
  end

  test "dropdown_item without icon or description renders as before" do
    assigns = %{}
    html = r(~H|<.dropdown_item>Edit</.dropdown_item>|)
    refute html =~ "<svg"
    refute html =~ "pop-item-text"
  end

  test ~s|dropdown_item two_line="auto" is two-line only with a description| do
    assigns = %{}
    plain = r(~H|<.dropdown_item description="d">Edit</.dropdown_item>|)
    explicit = r(~H|<.dropdown_item two_line description="d">Edit</.dropdown_item>|)
    auto = r(~H|<.dropdown_item two_line="auto" description="d">Edit</.dropdown_item>|)
    assert auto == explicit
    assert auto != plain

    no_desc = r(~H|<.dropdown_item>Edit</.dropdown_item>|)
    assert r(~H|<.dropdown_item two_line="auto">Edit</.dropdown_item>|) == no_desc
  end

  defp item(assigns),
    do: ~H|<.dropdown_item two_line="auto" description={@d} icon_name={@i}>Edit</.dropdown_item>|

  test "dropdown_item auto two-line tracks its sources" do
    each_source(&item/1, %{d: "a", i: "edit"}, d: "b", i: "trash")
    check(&item/1, %{d: nil, i: nil}, d: "now there is one")
  end

  test "avatar size accepts an integer of pixels, like the numeric string" do
    assigns = %{}
    int = r(~H|<.avatar name="Ana Souza" size={40} />|)
    str = r(~H|<.avatar name="Ana Souza" size="40" />|)
    assert int == str
    assert int =~ "--s:40px"
    assert r(~H|<.avatar name="Ana Souza" />|) =~ "--s:30px"
  end

  test "avatar color=auto is deterministic by name" do
    assigns = %{}
    a = r(~H|<.avatar name="Ana Souza" color="auto" variant="soft" />|)
    assert a == r(~H|<.avatar name="Ana Souza" color="auto" variant="soft" />|)
    assert a =~ "AS"
  end

  test "empty_state slot :actions == :action; :action wins when both" do
    assigns = %{}
    a = r(~H|<.empty_state title="T">
  <:action><b>go</b></:action>
</.empty_state>|)
    b = r(~H|<.empty_state title="T">
  <:actions><b>go</b></:actions>
</.empty_state>|)
    assert a == b
    assert b =~ "<b>go</b>"

    both =
      r(~H|<.empty_state title="T">
  <:action>one</:action><:actions>two</:actions>
</.empty_state>|)

    assert both =~ "one"
    refute both =~ "two"

    for v <- ~w(canvas card inline table plain) do
      assigns = %{v: v}
      a = r(~H|<.empty_state variant={@v} title="T">
  <:action>go</:action>
</.empty_state>|)
      b = r(~H|<.empty_state variant={@v} title="T">
  <:actions>go</:actions>
</.empty_state>|)
      assert a == b, "variant #{v}"
    end
  end

  defp es(assigns) do
    ~H"""
    <.empty_state title={@t}>
      <:actions>{@a}</:actions>
    </.empty_state>
    """
  end

  test "empty_state :actions tracks its sources" do
    each_source(&es/1, %{t: "T", a: "go"}, t: "U", a: "stop")
  end
end
