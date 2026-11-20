defmodule LedgerUI.Components.A11yTest do
  @moduledoc "ARIA/roles/tabindex are rendered by the server (hooks only update state)."
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  use LedgerUI

  defp html(fun), do: rendered_to_string(fun.(%{}))

  test "tabs: tablist, tab, aria-selected, roving tabindex, aria-controls, tabpanel" do
    html =
      html(fn assigns ->
        ~H"""
        <.tabs id="t" selected="b">
          <:tab name="a">A</:tab>
          <:tab name="b">B</:tab>
          <:tab name="c">C</:tab>
          <:panel name="a">pa</:panel>
          <:panel name="b">pb</:panel>
        </.tabs>
        """
      end)

    assert html =~ ~s(role="tablist")

    assert html =~ ~s(aria-selected="true")
    assert html =~ ~s(tabindex="0")

    assert html =~ ~s(aria-selected="false")
    assert html =~ ~s(tabindex="-1")
    assert html =~ ~s(aria-controls="t-panel-a")
    # tab without panel: no aria-controls
    refute html =~ ~s(aria-controls="t-panel-c")
    assert html =~ ~s(role="tabpanel")
    assert html =~ ~s(aria-labelledby="t-tab-a")
  end

  test "tabs: vertical sets aria-orientation" do
    html =
      html(fn assigns ->
        ~H|<.tabs id="t" orientation="vertical">
  <:tab name="a">A</:tab>
</.tabs>|
      end)

    assert html =~ ~s(aria-orientation="vertical")
  end

  test "view_switcher: aria-pressed on buttons and trigger ARIA on the menu" do
    html =
      html(fn assigns ->
        ~H"""
        <.view_switcher
          id="v"
          value="list"
          views={["list", "board"]}
          options={[%{label: "Table", value: "table"}]}
        />
        """
      end)

    assert html =~ ~s(aria-pressed="true")
    assert html =~ ~s(aria-pressed="false")
    assert html =~ ~s(aria-haspopup="menu")
    assert html =~ ~s(aria-controls="v-add-menu")
    assert html =~ ~s(aria-expanded="false")
  end

  test "breadcrumb: current page and the collapsed trigger" do
    html =
      html(fn assigns ->
        ~H"""
        <.breadcrumb id="bc" max_items={3}>
          <:item href="/1">One</:item>
          <:item href="/2">Two</:item>
          <:item href="/3">Three</:item>
          <:item href="/4">Four</:item>
          <:item>Five</:item>
        </.breadcrumb>
        """
      end)

    assert html =~ ~s(aria-current="page")
    assert html =~ ~s(aria-haspopup="menu")
    assert html =~ ~s(aria-controls="bc-more-menu")
  end

  test "pagination: aria-current on the page, also when display-only and classic" do
    html = html(fn assigns -> ~H|<.pagination page={2} total_pages={5} />| end)
    assert html =~ ~r/<span class="on" aria-current="page">\s*2\s*<\/span>/

    html =
      html(fn assigns ->
        ~H|<.pagination page={2} total_pages={5} on_change="go" shape="classic" />|
      end)

    assert html =~ ~s(aria-current="page")
    assert html =~ ~s(aria-label="Page 2")
  end

  test "steps: list roles, aria-current and the state name" do
    html =
      html(fn assigns ->
        ~H"""
        <.stepper current={1}>
          <:step label="Account" />
          <:step label="Plan" />
          <:step label="Pay" />
        </.stepper>
        """
      end)

    assert html =~ ~s(role="list")
    assert html =~ ~s(role="listitem")
    assert html =~ ~s(aria-current="step")
    assert html =~ ~s(aria-label="Account, Completed")
    assert html =~ ~s(aria-label="Plan, Current")
    assert html =~ ~s(aria-label="Pay, Upcoming")
    assert length(String.split(html, ~s(aria-current="step"))) == 2
  end

  test "dropdown: trigger ARIA, popover, menu roles" do
    html =
      html(fn assigns ->
        ~H"""
        <.dropdown id="d" label="Actions" open>
          <.dropdown_label>Title</.dropdown_label>
          <.dropdown_item>Edit</.dropdown_item>
          <.dropdown_separator />
        </.dropdown>
        """
      end)

    assert html =~ ~s(aria-haspopup="menu")
    assert html =~ ~s(aria-expanded="true")
    assert html =~ ~s(aria-controls="d-menu")
    assert html =~ ~s(popover="manual")
    assert html =~ ~s(role="menu")
    assert html =~ ~s(role="menuitem")
    assert html =~ ~s(role="separator")
    assert html =~ ~s(role="presentation")
  end

  test "dropdown: a toggle slot receives the trigger attributes; demos have no popover" do
    html =
      html(fn assigns ->
        ~H"""
        <.dropdown id="d">
          <:toggle :let={t}><button type="button" {t}>Go</button></:toggle>
          <.dropdown_item>Edit</.dropdown_item>
        </.dropdown>
        """
      end)

    assert html =~ ~s(aria-controls="d-menu")

    demo =
      html(fn assigns ->
        ~H|<.dropdown id="d" label="X" anchor_class="m-click">
  <.dropdown_item>E</.dropdown_item>
</.dropdown>|
      end)

    refute demo =~ "popover="
  end

  test "action_menu and context_menu: ARIA and popover" do
    html =
      html(fn assigns ->
        ~H"""
        <.action_menu id="am" label="Actions">
          <.action_menu_item>Open</.action_menu_item>
          <.action_menu_separator />
        </.action_menu>
        """
      end)

    assert html =~ ~s(aria-haspopup="menu")
    assert html =~ ~s(aria-controls="am-menu")
    assert html =~ ~s(popover="manual")
    assert html =~ ~s(role="menu")
    assert html =~ ~s(role="separator")

    html =
      html(fn assigns ->
        ~H|<.context_menu id="cm">
  <p>x</p><:item>Rename</:item>
</.context_menu>|
      end)

    assert html =~ ~s(role="menu")
    assert html =~ ~s(popover="manual")
  end

  test "menu_list: aria-current on the active link" do
    html =
      html(fn assigns ->
        ~H"""
        <.menu_list>
          <:item href="/a" active>A</:item>
          <:item href="/b">B</:item>
        </.menu_list>
        """
      end)

    assert length(String.split(html, ~s(aria-current="page"))) == 2
  end

  test "scrollspy: the item marked `on` has aria-current" do
    html =
      html(fn assigns ->
        ~H"""
        <.scrollspy id="s">
          <:item href="#a" class="on">A</:item>
          <:item href="#b">B</:item>
        </.scrollspy>
        """
      end)

    assert length(String.split(html, ~s(aria-current="true"))) == 2
  end

  test "modal and drawer: dialog roles in the live and inline forms" do
    html = html(fn assigns -> ~H|<.modal id="m" title="T" description="D">x</.modal>| end)
    assert html =~ ~s(role="dialog")
    assert html =~ ~s(aria-modal="true")
    assert html =~ ~s(aria-labelledby="m-title")
    assert html =~ ~s(aria-describedby="m-desc")

    html = html(fn assigns -> ~H|<.modal id="m" title="T" inline>x</.modal>| end)
    assert html =~ ~s(role="dialog")
    assert html =~ ~s(aria-labelledby="m-title")

    html = html(fn assigns -> ~H|<.drawer id="dr" title="T">x</.drawer>| end)
    assert html =~ ~s(role="dialog")
    assert html =~ ~s(aria-modal="true")

    html = html(fn assigns -> ~H|<.drawer id="dr" title="T" inline>x</.drawer>| end)
    assert html =~ ~s(role="dialog")
  end

  test "popover and tooltip: roles, ids and trigger attributes" do
    html =
      html(fn assigns ->
        ~H"""
        <.popover id="p" label="Info">
          <:trigger :let={t}><button type="button" {t}>i</button></:trigger>
          body
        </.popover>
        """
      end)

    assert html =~ ~s(role="dialog")
    assert html =~ ~s(aria-haspopup="dialog")
    assert html =~ ~s(aria-controls="p-panel")
    assert html =~ ~s(id="p-panel")

    html =
      html(fn assigns ->
        ~H|<.tooltip id="tt" text="Hi"><button type="button">?</button></.tooltip>|
      end)

    assert html =~ ~s(role="tooltip")
    assert html =~ ~s(id="tt-tip")
  end

  test "command_palette: dialog, combobox, listbox and options" do
    html =
      html(fn assigns ->
        ~H"""
        <.command_palette
          id="cp"
          items={[%{label: "Orders", value: "o"}, %{label: "Clients", value: "c"}]}
        />
        """
      end)

    assert html =~ ~s(role="dialog")
    assert html =~ ~s(aria-modal="true")
    assert html =~ ~s(role="combobox")
    assert html =~ ~s(aria-controls="cp-list")
    assert html =~ ~s(aria-autocomplete="list")
    assert html =~ ~s(role="listbox")
    assert html =~ ~s(id="cp-list")
    assert html =~ ~s(role="option")
    assert html =~ ~s(id="cp-opt-0")
    assert html =~ ~s(id="cp-opt-1")
    refute html =~ ~s(role="menuitem")

    inline =
      html(fn assigns ->
        ~H|<.command_palette id="cp" inline items={[%{label: "Orders"}]} />|
      end)

    assert inline =~ ~s(role="menuitem")
    assert inline =~ ~s(role="dialog")
    refute inline =~ "aria-modal"
  end

  test "notification_center: dialog panel and tablist" do
    html =
      html(fn assigns ->
        ~H"""
        <.notification_center
          id="nc"
          variant="classic"
          tabs={[%{id: "all", label: "All"}, %{id: "unread", label: "Unread"}]}
          items={[%{id: "1", title: "Hello", read: false}]}
        />
        """
      end)

    assert html =~ ~s(role="dialog")
    assert html =~ ~s(role="tablist")
    assert html =~ ~s(role="tab")
    assert html =~ ~s(aria-selected="true")
    assert html =~ ~s(aria-controls="nc-panel")
  end

  test "accordion: button header, aria-expanded/-controls and region body" do
    html =
      html(fn assigns ->
        ~H"""
        <.accordion id="acc">
          <.accordion_item id="i1" title="One" open>body</.accordion_item>
          <.accordion_item id="i2" title="Two">body</.accordion_item>
        </.accordion>
        """
      end)

    assert html =~ ~s(role="button")
    assert html =~ ~s(tabindex="0")
    assert html =~ ~s(aria-expanded="true")
    assert html =~ ~s(aria-expanded="false")
    assert html =~ ~s(aria-controls="i1-bd")
    assert html =~ ~s(role="region")
    assert html =~ ~s(aria-labelledby="i1-hd")
  end

  test "collapse: native details/summary, text toggle keeps aria-expanded/-controls" do
    html =
      html(fn assigns ->
        ~H|<.collapse_text id="ct">long</.collapse_text>|
      end)

    assert html =~ ~s(aria-expanded="false")
    assert html =~ ~s(aria-controls="ct-text")
  end

  test "no phx-lu-* attributes anywhere" do
    html =
      html(fn assigns ->
        ~H"""
        <.modal id="m" title="T">x</.modal>
        <.tooltip id="tt" text="Hi"><button type="button">?</button></.tooltip>
        <.accordion id="a">
          <.accordion_item id="a1" title="x">y</.accordion_item>
        </.accordion>
        <.command_palette id="cp" items={[%{label: "O"}]} />
        """
      end)

    refute html =~ "phx-lu-"
    assert html =~ "data-lu-kind"
  end

  test "button: group role, loading is inert/aria-busy (no disabled attribute)" do
    html = html(fn assigns -> ~H|<.button_group><.button>A</.button></.button_group>| end)
    assert html =~ ~s(role="group")

    html = html(fn assigns -> ~H|<.button loading>Save</.button>| end)
    assert html =~ ~s(aria-busy="true")
    assert html =~ ~s(aria-disabled="true")
    assert html =~ "inert"
    refute html =~ "disabled=\"\""
  end

  test "fab_dial: aria-controls, menu id, closed actions out of the tab order" do
    html =
      html(fn assigns ->
        ~H"""
        <.fab_dial id="fd" label="Create">
          <:action label="New" phx-click="n"><.icon name="plus" /></:action>
        </.fab_dial>
        """
      end)

    assert html =~ ~s(aria-controls="fd-menu")
    assert html =~ ~s(id="fd-menu")
    assert html =~ ~s(role="menuitem")
    assert html =~ ~s(tabindex="-1")
  end

  test "treeview: tree, treeitem, aria-expanded/-selected/-checked and roving tabindex" do
    html =
      html(fn assigns ->
        ~H"""
        <.treeview id="tv">
          <.tree_item id="a" label="A" expanded>
            <.tree_item id="b" label="B" selected checked="mixed" />
          </.tree_item>
        </.treeview>
        """
      end)

    assert html =~ ~s(role="tree")
    assert html =~ ~s(role="treeitem")
    assert html =~ ~s(aria-expanded="true")
    assert html =~ ~s(aria-selected="true")
    assert html =~ ~s(aria-selected="false")
    assert html =~ ~s(aria-checked="mixed")
    assert html =~ ~s(aria-owns="a-kids")
    assert html =~ ~s(role="group")
    assert html =~ ~s(tabindex="0")
    assert html =~ ~s(tabindex="-1")
  end

  test "step_group: toggles carry aria-expanded/-controls" do
    html =
      html(fn assigns ->
        ~H"""
        <.step_group id="sg" title="Run" status={:done}>
          <:step id="s1" title="One" status={:done}>log</:step>
        </.step_group>
        """
      end)

    assert html =~ ~s(aria-controls="sg-panel")
    assert html =~ ~s(aria-expanded="true")
    assert html =~ ~s(aria-controls="s1-log")
    assert html =~ ~s(aria-expanded="false")
  end

  test "divider: vertical separator" do
    html = html(fn assigns -> ~H|<.divider orientation="vertical" />| end)
    assert html =~ ~s(role="separator")
    assert html =~ ~s(aria-orientation="vertical")
  end

  test "ai: data-lu-status instead of data-status" do
    html =
      html(fn assigns ->
        ~H|<.ai_message status="error">oops</.ai_message>|
      end)

    assert html =~ ~s(data-lu-status="error")
    refute html =~ ~s( data-status=)
  end
end
