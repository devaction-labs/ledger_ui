defmodule LedgerUI.Components.PillboxTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Pillbox

  @options [
    %{label: "Tintas", value: "tintas", count: 128},
    %{label: "Ferramentas", value: "ferramentas", count: 86},
    %{label: "Ana Souza", value: "ana", color: "#8a5cd6"}
  ]

  test "renders chosen values as pills, name[] and the empty entry" do
    assigns = %{options: @options}

    html =
      rendered_to_string(~H"""
      <.pillbox name="categories" value={["tintas"]} options={@options} label="Categories" clear />
      """)

    assert html =~ ~s(phx-hook="LedgerUI.Select")
    assert html =~ ~s(data-lu-pillbox)
    assert html =~ ~s(data-lu-search="panel")
    assert html =~ ~s(class="lu-pbox one")
    assert html =~ ~s(name="categories[]")
    assert html =~ ~s(<option value="" selected></option>)
    assert html =~ ~s(<option value="tintas" selected>Tintas</option>)
    assert html =~ ~s(data-lu-remove="tintas")
    assert html =~ "data-lu-clear"
    # a check box on every row and the count at the right
    assert html =~ ~r/<span class="r">\s*128\s*<\/span>/
    assert length(Regex.scan(~r/<span class="lu-check/, html)) == 3
    assert html =~ ~s(<span class="lu-av")
  end

  test "size, overflow wrap and readonly" do
    assigns = %{options: @options}

    html =
      rendered_to_string(~H"""
      <.pillbox name="c" value={["tintas"]} options={@options} size="lg" overflow="wrap" readonly />
      """)

    assert html =~ ~s(class="lu-pbox lg")
    assert html =~ ~s(data-lu-overflow="wrap")
    assert html =~ "data-lu-readonly"
    refute html =~ "data-lu-remove"
    refute html =~ ~s(data-icon="chevron-down")
  end

  test "single choice submits name (not name[]) and shows one pill" do
    assigns = %{options: @options}

    html =
      rendered_to_string(~H"""
      <.pillbox
        name="product_id"
        value="ana"
        options={@options}
        multiple={false}
        panel_min_width="26rem"
      />
      """)

    assert html =~ ~s(name="product_id")
    refute html =~ ~s(name="product_id[]")
    refute html =~ "data-lu-multiple"
    assert html =~ ~s(data-lu-value="ana")
    assert html =~ "min-width:26rem"
    refute html =~ ~s(<span class="lu-check)
  end

  test "create row words and hidden label" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pillbox
        name="t"
        options={~w(a)}
        create
        create_label="Make"
        create_hint="Enter"
        hidden_label="%{count} off"
        empty_label="Nada"
      />
      """)

    assert html =~ ~s(data-lu-create-label="Make")
    assert html =~ ~s(data-lu-create-hint="Enter")
    assert html =~ ~s(data-lu-more-label="%{count} off")
    assert html =~ "Nada"
  end
end
