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

  # the opening tag of the n-th element with `data-part`
  defp tag(html, part, n \\ 0) do
    ~r/<[a-z0-9]+[^>]*data-part="#{part}"[^>]*>/ |> Regex.scan(html) |> Enum.at(n) |> hd()
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
    # the trigger is a primary solid md button; the menu span knows its placement
    assert tag(html, "dropdown-toggle") =~ "[--c:var(--color-accent)]"
    assert tag(html, "dropdown-toggle") =~ "h-9"
    assert tag(html, "dropdown-menu") =~ ~s(data-lu-placement="top-end")
    assert tag(html, "dropdown") =~ "relative inline-flex"
    assert tag(html, "pop") =~ "bg-panel"
    assert tag(html, "pop") =~ ~s(role="menu")
    refute html =~ "keep-"
    refute html =~ ~r/[\s"]lu-/
    assert html =~ ~s(role="menuitem")
  end

  test "neutral color is outline; shape square" do
    assigns = %{}

    html =
      out(fn -> ~H|<.dropdown id="d" label="x" shape="square">
  <.dropdown_item>a</.dropdown_item>
</.dropdown>| end)

    assert tag(html, "dropdown-toggle") =~ "bg-panel"
    assert tag(html, "dropdown-toggle") =~ "w-9"
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
    assert tag(html, "dropdown-kebab") =~ "size-8"
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

    assert tag(html, "dropdown-split") =~ "inline-flex"
    assert tag(html, "dropdown-action") =~ "rounded-r-none"
    assert tag(html, "dropdown-toggle") =~ "rounded-l-none"
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
    assert tag(html, "dropdown") =~ ~r/class="[^"]*\bopen\b/
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
    assert tag(html, "pop-item", 0) =~ "text-accent-content"
    assert html =~ ~r/<kbd[^>]*>Ctrl<\/kbd><kbd[^>]*>E<\/kbd>/
    assert html =~ ~s(aria-disabled="true")
    assert tag(html, "pop-item", 1) =~ "text-neg"
    assert tag(html, "pop-check") =~ "size-3.5"
    assert html =~ ~s(type="button")
  end

  test "media item has no menuitem role (the hook adds it)" do
    assigns = %{}
    html = out(fn -> ~H|<.dropdown_item variant="media">x</.dropdown_item>| end)
    assert tag(html, "pop-item") =~ "h-auto"
    refute tag(html, "pop-item") =~ "role="
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
    assert tag(html, "badge") =~ "bg-accent-soft"
    assert html =~ "a@b.c"
    assert tag(html, "pop-search") =~ "h-9"
    assert html =~ ~s(placeholder="Find")
    assert tag(html, "pop-label") =~ "uppercase"
    assert tag(html, "pop-separator") =~ "h-px"
  end

  test "footer locale, counts, apply" do
    assigns = %{}

    html =
      out(fn ->
        ~H|<.dropdown_footer locale="pt_BR" apply_count={3} on_apply="go" apply_color="mono" />|
      end)

    assert html =~ "Limpar"
    assert html =~ "Aplicar (3)"
    assert html =~ "[--c:var(--lu-ink)]"
    assert tag(html, "pop-foot") =~ "border-t"
    assert html =~ ~s(data-dd="clear")

    submit = out(fn -> ~H|<.dropdown_footer show_apply={false} />| end)
    assert submit =~ "Clear"
    refute submit =~ ~s(data-dd="apply")
  end

  test "hook file exists" do
    assert File.exists?("priv/static/ledger_ui/hooks/dropdown.js")
  end

  test "row actions: ghost trigger, title, part prefix, row_mark, kbd and two_line" do
    assigns = %{}

    html =
      out(fn ->
        ~H"""
        <.dropdown id="r" label="Actions of Acme" part="action-menu" trigger_style="ghost" row_mark>
          <:title>Acme</:title>
          <.dropdown_item kbd="⌘ K" description="A hint" two_line>Open</.dropdown_item>
        </.dropdown>
        """
      end)

    assert tag(html, "action-menu") =~ ~s(phx-hook="LedgerUI.Dropdown")
    assert tag(html, "action-menu") =~ "data-row-mark"
    assert tag(html, "action-menu-trigger") =~ ~s(aria-label="Actions of Acme")
    assert tag(html, "action-menu-trigger") =~ ~s(aria-controls="r-menu")
    assert tag(html, "action-menu-trigger") =~ "bg-transparent"
    assert tag(html, "action-menu-panel") =~ ~s(popover="manual")
    assert tag(html, "pop-label") =~ ~s(role="presentation")
    assert tag(html, "pop-item") =~ "h-auto"
    assert tag(html, "pop-item") =~ ~s(role="menuitem")
    assert html =~ ~r/<kbd[^>]*>⌘ K<\/kbd>/
    refute html =~ "dropdown-toggle"
    refute html =~ "chevron-down"
  end

  test "the default part names are unchanged" do
    assigns = %{}

    html =
      out(fn ->
        ~H"""
        <.dropdown id="d" label="Menu">
          <.dropdown_item>A</.dropdown_item>
        </.dropdown>
        """
      end)

    assert html =~ ~s(data-part="dropdown")
    assert html =~ ~s(data-part="dropdown-toggle")
    assert html =~ ~s(data-part="dropdown-menu")
    refute html =~ "data-row-mark"
  end

  test "dropdown_item with phx-click has automatic loading; opt-out and links do not" do
    assigns = %{}
    html = rendered_to_string(~H|<.dropdown_item phx-click="del">Delete</.dropdown_item>|)
    assert html =~ "[&amp;.phx-click-loading]:pointer-events-none"
    assert html =~ ~s(data-part="pop-item-spinner")

    off =
      rendered_to_string(
        ~H|<.dropdown_item phx-click="del" auto_loading={false}>X</.dropdown_item>|
      )

    refute off =~ "phx-click-loading"

    plain = rendered_to_string(~H|<.dropdown_item>X</.dropdown_item>|)
    refute plain =~ "phx-click-loading"
    link = rendered_to_string(~H|<.dropdown_item navigate="/a" phx-click="x">X</.dropdown_item>|)
    refute link =~ "phx-click-loading"
  end
end
