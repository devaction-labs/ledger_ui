defmodule LedgerUI.Components.DropdownTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Dropdown

  defp out(fun), do: norm(fun.())

  defp norm(rendered) do
    rendered
    |> rendered_to_string()
    |> String.replace(~r/\s+/, " ")
    |> String.replace(~r/>\s+/, ">")
    |> String.replace(~r/\s+</, "<")
  end

  test "label button, panel placement and hook" do
    assigns = %{}

    html =
      out(fn ->
        ~H"""
        <.dropdown id="d" label="Ações" placement="top-end" color="primary">
          <.dropdown_item>Editar</.dropdown_item>
        </.dropdown>
        """
      end)

    assert html =~ ~s(id="d")
    assert html =~ ~s(phx-hook="LedgerUI.Dropdown")
    assert html =~ "lu-b c-primary v-solid s-md sh-rounded"
    assert html =~ "fl p-top-end"
    assert html =~ "keep-popover"
    assert html =~ ~s(role="menuitem")
  end

  test "neutral color is outline; shape square" do
    assigns = %{}

    html =
      out(fn -> ~H|<.dropdown id="d" label="x" shape="square">
  <.dropdown_item>a</.dropdown_item>
</.dropdown>| end)

    assert html =~ "v-outline"
    assert html =~ "sh-square"
  end

  test "toggle_icon draws the kebab" do
    assigns = %{}

    html =
      out(fn ->
        ~H|<.dropdown id="d" toggle_icon="dots-vertical" toggle_label="Mais">
  <.dropdown_item>a</.dropdown_item>
</.dropdown>|
      end)

    assert html =~ ~s(aria-label="Mais")
    assert html =~ "lu-kebab"
    assert html =~ ~s(data-icon="more-v")
  end

  test "split button renders the action and the arrow" do
    assigns = %{}

    html =
      out(fn ->
        ~H"""
        <.dropdown id="d" color="mono" toggle_label="Mais">
          <:action phx-click="save">Save</:action>
          <.dropdown_item>b</.dropdown_item>
        </.dropdown>
        """
      end)

    assert html =~ "lu-split c-mono"
    assert html =~ ~s(phx-click="save")
    assert html =~ ~s(aria-label="Mais")
  end

  test "non default options reach the hook as data attributes only" do
    assigns = %{}

    default = out(fn -> ~H|<.dropdown id="d" label="x">
  <.dropdown_item>a</.dropdown_item>
</.dropdown>| end)
    refute default =~ "data-offset"
    refute default =~ "data-hover"

    html =
      out(fn ->
        ~H|<.dropdown
  id="d"
  label="x"
  offset={10}
  hover
  keep_submenus
  close_on_select={false}
  on_open="opened"
>
  <.dropdown_item>a</.dropdown_item>
</.dropdown>|
      end)

    assert html =~ ~s(data-offset="10")
    assert html =~ "data-hover"
    assert html =~ "data-keep-submenus"
    assert html =~ ~s(data-close-on-select="false")
    assert html =~ "data-on-open"
    assert html =~ "opened"
  end

  test "open renders the class open" do
    assigns = %{}
    html = out(fn -> ~H|<.dropdown id="d" label="x" open>
  <.dropdown_item>a</.dropdown_item>
</.dropdown>| end)
    assert html =~ "lu-anc open"
  end

  test "item: link, button, color, disabled, shortcut, selected" do
    assigns = %{}

    html =
      out(fn ->
        ~H"""
        <.dropdown_item href="/x" color="primary" shortcut="Ctrl E">Go</.dropdown_item>
        <.dropdown_item disabled danger selected phx-click="x">Del</.dropdown_item>
        """
      end)

    assert html =~ ~s(<a)
    assert html =~ ~s(href="/x")
    assert html =~ "c-primary"
    assert html =~ ~s(<kbd class="lu-kbd">Ctrl</kbd><kbd class="lu-kbd">E</kbd>)
    assert html =~ ~s(aria-disabled="true")
    assert html =~ "danger"
    assert html =~ "sel"
    assert html =~ ~s(type="button")
  end

  test "media item has no menuitem role (the hook adds it)" do
    assigns = %{}
    html = out(fn -> ~H|<.dropdown_item variant="media">x</.dropdown_item>| end)
    assert html =~ "lu-menu-item media"
    refute html =~ "role="
  end

  test "checkbox and radio: roles, hidden input, checked state" do
    assigns = %{}

    html =
      out(fn ->
        ~H"""
        <.dropdown_checkbox name="f[s][]" value="paid" checked count={3}>Paid</.dropdown_checkbox>
        <.dropdown_radio name="f[sort]" value="recent">Recent</.dropdown_radio>
        """
      end)

    assert html =~ ~s(role="menuitemcheckbox")
    assert html =~ ~s(aria-checked="true")
    assert html =~ ~s(role="menuitemradio")
    assert html =~ ~s(aria-checked="false")
    assert html =~ ~s(type="checkbox")
    assert html =~ ~s(type="radio")
    assert html =~ ~s(name="f[s][]")
    assert html =~ "visibility:hidden"
    assert html =~ "dd-f-s--paid"
  end

  test "submenu, header, search, label, separator" do
    assigns = %{}

    html =
      out(fn ->
        ~H"""
        <.dropdown_submenu label="Move" count={2} placement="left">
          <.dropdown_item>a</.dropdown_item>
        </.dropdown_submenu>
        <.dropdown_header subtitle="a@b.c">Ana</.dropdown_header>
        <.dropdown_search placeholder="Find" name="q" />
        <.dropdown_label>Sort</.dropdown_label>
        <.dropdown_separator />
        """
      end)

    assert html =~ ~s(data-dd="sub")
    assert html =~ ~s(data-placement="left")
    assert html =~ ~s(aria-haspopup="menu")
    assert html =~ "lu-badge acc sm"
    assert html =~ "a@b.c"
    assert html =~ "lu-menu-search"
    assert html =~ ~s(placeholder="Find")
    assert html =~ "lu-menu-label"
    assert html =~ "lu-menu-sep"
  end

  test "footer locale, counts, apply" do
    assigns = %{}

    html =
      out(fn ->
        ~H|<.dropdown_footer locale="pt_BR" apply_count={3} on_apply="go" apply_color="mono" />|
      end)

    assert html =~ "Limpar"
    assert html =~ "Aplicar (3)"
    assert html =~ "c-mono"
    assert html =~ ~s(data-dd="clear")

    submit = out(fn -> ~H|<.dropdown_footer show_apply={false} />| end)
    assert submit =~ "Clear"
    refute submit =~ ~s(data-dd="apply")
  end

  test "hook file exists" do
    assert File.exists?("priv/static/ledger_ui/hooks/dropdown.js")
  end
end
