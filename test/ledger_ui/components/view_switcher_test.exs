defmodule LedgerUI.Components.ViewSwitcherTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.ViewSwitcher

  defp norm(rendered) do
    rendered
    |> rendered_to_string()
    |> String.replace(~r/\s+/, " ")
    |> String.replace(~r/>\s+/, ">")
    |> String.replace(~r/\s+</, "<")
  end

  @views [
    %{label: "List", value: "list", icon: "list"},
    %{label: "Board", value: "kanban", icon: "kanban", count: 4}
  ]

  # the opening tag of the n-th element with `data-part`
  defp tag(html, part, n \\ 0) do
    ~r/<[a-z0-9]+[^>]*data-part="#{part}"[^>]*>/ |> Regex.scan(html) |> Enum.at(n) |> hd()
  end

  test "only views: the root is the segmented control and the chosen one is on" do
    assigns = %{views: @views}

    html =
      norm(~H|<.view_switcher id="v" value="kanban" views={@views} on_change="set" />|)

    assert tag(html, "view-switcher-seg") =~ ~s(id="v")
    assert tag(html, "view-switcher-seg") =~ "bg-sunken"
    assert tag(html, "view-switcher-seg") =~ ~s(data-lu-single="")
    assert tag(html, "view-switcher-view", 1) =~ ~s(aria-pressed="true")
    assert tag(html, "view-switcher-view", 1) =~ "aria-pressed:bg-panel"
    assert tag(html, "view-switcher-view", 0) =~ ~s(aria-pressed="false")
    assert html =~ "set"
    assert tag(html, "view-switcher-count") =~ "bg-selected"
    refute html =~ ~r/[\s"]lu-/
    assert html =~ "size-4"
  end

  test "no chosen value: no data-lu-single; plain strings work" do
    assigns = %{}
    html = norm(~H|<.view_switcher id="v" views={~w(list board)} />|)
    refute html =~ "data-lu-single"
    assert html =~ "list"
    assert html =~ "board"
  end

  test "link views carry aria-current" do
    assigns = %{}

    html =
      norm(~H"""
      <.view_switcher
        id="v"
        value="a"
        views={[%{label: "A", value: "a", patch: "/a"}, %{label: "B", value: "b", patch: "/b"}]}
      />
      """)

    assert html =~ ~s(aria-current="page")
    assert html =~ ~s(href="/b")
  end

  test "options build the add menu as a dropdown" do
    assigns = %{views: @views}

    html =
      norm(~H"""
      <.view_switcher
        id="v"
        views={@views}
        on_add="add"
        add_label="Nova"
        menu_title="Add a new view"
        columns={1}
        options={[
          %{label: "Table", value: "table", icon: "table", description: "Table view"},
          %{label: "Gallery", value: "g", added: true}
        ]}
      />
      """)

    assert tag(html, "view-switcher") =~ "flex-wrap"
    assert tag(html, "view-switcher-add") =~ "bg-transparent"
    assert tag(html, "view-switcher-grid") =~ "grid-cols-1"
    assert html =~ ~s(id="v-add")
    assert html =~ "Nova"
    assert html =~ "Add a new view"
    assert html =~ "Table view"
    assert html =~ "add"
  end

  test "saved views menu" do
    assigns = %{}

    html =
      norm(~H"""
      <.view_switcher
        id="v"
        views={~w(a)}
        saved={["Pro churn watch", "Board packs"]}
        saved_value="Pro churn watch"
        on_saved="load"
      />
      """)

    assert html =~ ~s(id="v-saved")
    assert html =~ "Pro churn watch"
    assert html =~ "Board packs"
  end
end
