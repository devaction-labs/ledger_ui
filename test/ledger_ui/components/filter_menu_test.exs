defmodule LedgerUI.Components.FilterMenuTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.FilterMenu

  doctest LedgerUI.Components.FilterMenu

  defp groups,
    do: [
      %{
        name: "filter[status]",
        label: "Status",
        icon: "building",
        value: ["approved"],
        options: [{"Faturado", "invoiced", 3}, {"Aprovado", "approved", 2}]
      },
      %{
        name: "filter[sort]",
        label: "Ordenar por",
        caption: "Ordenar por",
        display: :section,
        type: :single,
        value: "value",
        options: [{"Mais recentes", "recent"}, {"Maior valor", "value"}]
      }
    ]

  test "trigger button classes, count of applied values and Apply/Clear" do
    assigns = %{groups: groups()}

    html =
      rendered_to_string(~H"""
      <.filter_menu
        id="fm"
        label="Filtrar"
        variant="soft"
        color="info"
        size="xs"
        dashed
        groups={@groups}
      />
      """)

    assert html =~ ~s(class="lu-b c-info v-soft s-xs sh-rounded")
    assert html =~ "border-style:dashed"
    assert html =~ "Filtrar"
    assert html =~ ~r/data-lu-count[^>]*>1</
    assert html =~ "data-lu-apply"
    assert html =~ "data-lu-clear"
    assert html =~ ~s(phx-hook="LedgerUI.FilterMenu")
  end

  test "options are real inputs: name[] for multiple, name for single, section is flat" do
    assigns = %{groups: groups()}
    html = rendered_to_string(~H|<.filter_menu id="fm" groups={@groups} />|)

    assert html =~ ~r/type="checkbox" name="filter\[status\]\[\]" value="approved" checked/
    assert html =~ ~r/type="radio" name="filter\[sort\]" value="value" checked/
    assert html =~ "data-lu-section"
    assert html =~ ~s(class="lu-menu-label">Ordenar por)
    # sections do not count in the trigger
    assert html =~ ~r/data-lu-count[^>]*>1</
  end

  test "live mode has no Apply; pt_BR words; events" do
    assigns = %{groups: groups()}

    html =
      rendered_to_string(~H"""
      <.filter_menu
        id="fm"
        mode="live"
        locale="pt_BR"
        groups={@groups}
        on_change="c"
        on_clear="x"
        target="#t"
      />
      """)

    refute html =~ "data-lu-apply>"
    assert html =~ "Filtros"
    assert html =~ "Limpar"
    assert html =~ ~s(data-lu-mode="live")
    assert html =~ ~s(data-lu-on-change="c")
    assert html =~ ~s(data-lu-target="#t")
  end

  test "custom period row and the value as custom:FROM..TO" do
    assigns = %{
      groups: [
        %{
          name: "filter[period]",
          label: "Período",
          type: :single,
          custom: true,
          value: "custom:2026-11-01..2026-11-13",
          options: [{"Hoje", "today"}]
        }
      ]
    }

    html = rendered_to_string(~H|<.filter_menu id="fm" groups={@groups} />|)
    assert html =~ "data-lu-custom-row"
    assert html =~ ~s(value="custom:2026-11-01..2026-11-13")
    assert html =~ "2026-11-01 – 2026-11-13"

    assert LedgerUI.Components.FilterMenu.custom_range("custom:2026-11-01..2026-11-13") ==
             {~D[2026-11-01], ~D[2026-11-13]}

    assert LedgerUI.Components.FilterMenu.custom_range("custom:bad") == nil
  end

  test "group slot takes your own content" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.filter_menu id="c">
        <:group name="tags[]" label="Tags" value={["a"]}>
          <input type="checkbox" name="tags[]" value="a" checked />
        </:group>
      </.filter_menu>
      """)

    assert html =~ ~s(name="tags[]" value="a")
    assert html =~ "Tags"
    assert html =~ ~r/data-lu-count[^>]*>1</
  end
end
