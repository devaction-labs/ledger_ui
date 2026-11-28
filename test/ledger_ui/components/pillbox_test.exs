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
    assert html =~ "flex-nowrap overflow-hidden"
    assert html =~ "data-one"
    assert html =~ ~s(name="categories[]")
    assert html =~ ~s(<option value="" selected></option>)
    assert html =~ ~s(<option value="tintas" selected>Tintas</option>)
    assert html =~ ~s(data-lu-remove="tintas")
    assert html =~ "data-lu-clear"
    # a check box on every row and the count at the right
    assert html =~ ~r/data-part="listbox-option-right"[^>]*>\s*128\s*<\/span>/
    assert length(Regex.scan(~r/data-part="listbox-option-check"/, html)) == 3

    # the check is a presentation span (an input inside role=option is `nested-interactive`), drawn from aria-selected
    refute html =~
             ~r/data-part="listbox-option"[^>]*>\s*<span[^>]*listbox-option-check[^>]*>\s*<input/

    refute html =~ ~s(type="checkbox")
    assert html =~ "in-aria-selected:bg-(--c)"
    assert html =~ ~s(data-part="person-avatar")
  end

  test "size, overflow wrap and readonly" do
    assigns = %{options: @options}

    html =
      rendered_to_string(~H"""
      <.pillbox name="c" value={["tintas"]} options={@options} size="lg" overflow="wrap" readonly />
      """)

    assert html =~ "min-h-10"
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
    refute html =~ ~s(data-part="listbox-option-check")
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

  describe "chevron and +N (#69)" do
    test "the chevron sits at the right end of the field once there are tags" do
      assigns = %{options: @options}

      html =
        rendered_to_string(~H|<.pillbox name="c" value={["tintas"]} options={@options} />|)

      [ctrl] = Regex.run(~r/data-part="select-control".*?<\/span>\s*<div\s+id="[^"]*-pop"/s, html)
      assert ctrl =~ ~r/<svg[^>]*class="[^"]*ml-auto/
      # chips come before it, nothing after it
      {chip, _} = :binary.match(ctrl, "select-chip")
      {svg, _} = :binary.match(ctrl, "ml-auto")
      assert chip < svg
    end

    test "with the clear button, the button takes the auto margin and the chevron follows it" do
      assigns = %{options: @options}

      html =
        rendered_to_string(~H|<.pillbox name="c" value={["tintas"]} options={@options} clear />|)

      assert html =~ ~r/data-part="select-clear"/
      assert html =~ "ml-auto"
      assert html =~ "[[data-lu-clear]:not([hidden])~&amp;]:ml-0"
    end

    test "a plain select chevron does not get the auto margin" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<LedgerUI.Components.Select.select name="s" options={["a"]} value="a" />|
        )

      refute html =~ "text-muted ml-auto"
    end

    test "the hook titles and names the +N chip with the hidden tags, in the right order" do
      js = File.read!("priv/static/ledger_ui/hooks/select.js")
      assert js =~ ~S|.map((c) => c.textContent.trim()).join(", ")|
      assert js =~ "more.title = names"
      assert js =~ ~S|"aria-label"|
      # +N is inserted before the clear button / chevron, so the chevron stays last
      assert js =~ "ctrl.insertBefore(more, ref)"
    end
  end
end
