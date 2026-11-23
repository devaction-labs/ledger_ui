defmodule LedgerUI.Components.FxFormsBTest do
  @moduledoc "Canvas-fidelity additions: mini calendar sizes/strip/loop, bare time list, color picker compact/row, loops, menu_panel..."
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest

  import LedgerUI.Components.{
    Breadcrumb,
    Calendar,
    ColorPicker,
    Dropdown,
    Pagination,
    Range,
    SignaturePad,
    Steps,
    Tabs,
    TextEditor,
    TimePicker,
    Upload,
    ViewSwitcher
  }

  describe "range" do
    test "the lower value of a pair uses --lu-rlo, not the animated angle --lu-a" do
      assigns = %{}

      html =
        rendered_to_string(~H|<.range id="r" start_name="a" end_name="b" value={{20, 80}} />|)

      assert html =~ "--lu-sp:80%;--lu-rlo:20%"
      refute html =~ ~r/--lu-a[:)\]]/
    end

    test "loop animates the value and the thumb" do
      assigns = %{}
      html = rendered_to_string(~H|<.range id="r" name="x" value={50} loop />|)
      assert html =~ "animate-[lu-slloop_5s_cubic-bezier(.45,0,.25,1)_infinite]"
      assert html =~ "animate-[lu-grab_5s_infinite]"
    end
  end

  describe "calendar mini" do
    test "size sets the columns, the rows and the digits" do
      for {size, cols, row, font} <- [
            {"sm", "grid-cols-[repeat(7,28px)]", "h-[26px]", "text-xs"},
            {"md", "grid-cols-[repeat(7,34px)]", "h-8", "text-[13px]"},
            {"lg", "grid-cols-[repeat(7,42px)]", "h-10", "text-sm"}
          ] do
        assigns = %{size: size}

        html =
          rendered_to_string(
            ~H|<.calendar id="c" variant="mini" size={@size} card={false} date={~D[2023-09-19]} />|
          )

        assert html =~ cols
        assert html =~ row
        assert html =~ font
      end
    end

    test "view=week is a strip: the letters and the seven days of the week of the date" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<.calendar id="c" variant="mini" view="week" card={false} date={~D[2023-09-19]} />|
        )

      days = Regex.scan(~r/data-part="calendar-day"/, html)
      assert length(days) == 7
      assert html =~ ~s(data-date="2023-09-17")
      assert html =~ ~s(data-date="2023-09-23")
      refute html =~ ~s(data-date="2023-09-24")
    end

    test "loop pick delays each day of the month by 0.25s" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<.calendar id="c" variant="mini" loop="pick" card={false} date={~D[2023-09-19]} />|
        )

      assert html =~ "animate-[mo-day_8s_infinite]"
      assert html =~ "--dl:0.0s"
      assert html =~ "--dl:7.25s"
    end
  end

  describe "time_picker_panel bare" do
    test "is the plain list: 110px, 180px, mono, 32px rows, no popover box" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<.time_picker_panel variant="bare" loop times={["12:00", "12:30"]} value="12:30" />|
        )

      assert html =~ "w-[110px] overflow-hidden"
      assert html =~ "height:180px"
      assert html =~ "font-mono text-[13px]"
      assert html =~ "h-8"
      assert html =~ "animate-[mo-scroll_8s_ease-in-out_infinite]"
      assert html =~ ~s(aria-checked="true")
      refute html =~ "shadow-md"
    end

    test "height" do
      assigns = %{}
      html = rendered_to_string(~H|<.time_picker_panel variant="bare" height={120} times={[]} />|)
      assert html =~ "height:120px"
      refute html =~ "mo-scroll"
    end
  end

  describe "color_picker" do
    test "compact is the 220px area and the hue bar only" do
      assigns = %{}

      html =
        rendered_to_string(~H|<.color_picker id="c" variant="compact" value="#1F9282" loop />|)

      assert html =~ "w-[220px]"
      assert html =~ ~s(data-part="color-picker-area")
      assert html =~ ~s(data-part="color-picker-hue")
      assert html =~ "animate-[mo-svpick_6s_ease-in-out_infinite]"
      refute html =~ ~s(data-part="color-picker-swatches")
      refute html =~ "-hex"
    end

    test "row is a wrapping flex row; swatch_size gives 20/26/34px" do
      for {size, cls} <- [{"sm", "size-5"}, {"md", "size-[26px]"}, {"lg", "size-[34px]"}] do
        assigns = %{size: size}

        html =
          rendered_to_string(
            ~H|<.color_picker id="c" variant="row" swatch_size={@size} swatches={["#141514", "#1F9282"]} />|
          )

        assert html =~ "inline-flex flex-wrap gap-2"
        assert html =~ cls
      end
    end

    test "row loop walks the selection with per-swatch delays" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<.color_picker id="c" variant="row" loop swatches={["#141514", "#1F9282"]} />|
        )

      assert html =~ "animate-[mo-swsel_8s_infinite]"
      assert html =~ "--dl:0.8s"
    end
  end

  describe "steps" do
    test "connectors are 2px lines" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.steps>
          <:step label="A" current>1</:step>
          <:step label="B">2</:step>
        </.steps>
        """)

      assert html =~ "before:h-0.5"
      refute html =~ "before:h-[1.5px]"
    end
  end

  describe "signature_pad" do
    test "name_input={false} hides the field of the type mode" do
      assigns = %{}

      with_input =
        rendered_to_string(~H|<.signature_pad id="s" mode="type" modes={["type"]} text="Ana" />|)

      without =
        rendered_to_string(
          ~H|<.signature_pad id="s" mode="type" modes={["type"]} text="Ana" name_input={false} />|
        )

      assert with_input =~ "data-sig-name"
      refute without =~ "data-sig-name"
      assert without =~ ~s(data-part="signature-typed")
    end
  end

  describe "text_editor density" do
    test "compact: 12px radius, 28px tools, 90px area; loop staggers the toolbar" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<.rich_text_editor id="e" density="compact" loop toolbar={[~w(bold italic)]} />|
        )

      assert html =~ "rounded-[12px]"
      assert html =~ "min-h-[90px] px-3.5 py-3 text-sm"
      assert html =~ "h-7 w-[30px]"
      assert html =~ "animate-[mo-tbon_6s_infinite]"
      assert html =~ "--dl:1.2s"
      assert html =~ "[&amp;_p]:my-0"
    end

    test "a known @handle in the value is turned into a chip by the hook config" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<.comment_editor id="c" mentions={[%{handle: "Carlos", label: "Carlos"}]} value="oi @Carlos" />|
        )

      assert html =~ "bg-accent-soft"
      assert html =~ "Carlos"
    end
  end

  describe "view_switcher" do
    test "stretch shares the width; loop adds the sliding highlight" do
      views = [%{label: "A", value: "a"}, %{label: "B", value: "b"}, %{label: "C", value: "c"}]
      assigns = %{views: views}

      stretch = rendered_to_string(~H|<.view_switcher id="v" value="a" views={@views} stretch />|)
      assert stretch =~ "flex flex-1 justify-center"

      loop = rendered_to_string(~H|<.view_switcher id="v" value="a" views={@views} loop />|)
      assert loop =~ "--n:3"
      assert loop =~ "before:animate-[lu-segslide_6s_cubic-bezier(.4,0,.2,1)_infinite]"
      refute loop =~ "aria-pressed:bg-panel"
    end
  end

  describe "loops" do
    test "upload_drop and upload_file" do
      assigns = %{}
      html = rendered_to_string(~H|<.upload_drop loop />|)
      assert html =~ "animate-[lu-dragover_5s_ease-in-out_infinite]"

      html = rendered_to_string(~H|<.upload_file name="a.csv" progress={60} loop />|)
      assert html =~ "animate-[lu-upfill_4s_cubic-bezier(.4,0,.2,1)_infinite]"
    end

    test "breadcrumb staggers the steps 0.5s apart" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.breadcrumb loop>
          <:item href="#">A</:item>
          <:item href="#">B</:item>
          <:item>C</:item>
        </.breadcrumb>
        """)

      assert html =~ "animate-[mo-stg_6s_cubic-bezier(.2,.8,.2,1)_infinite]"
      assert html =~ "--dl:0.0s"
      assert html =~ "--dl:0.5s"
      assert html =~ "--dl:1.0s"
    end

    test "tabs loop: indicator, tab colours and panels" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tabs id="t" loop selected="a" transition="up">
          <:tab name="a" class="w-[110px]">A</:tab>
          <:tab name="b" class="w-[110px]">B</:tab>
          <:tab name="c" class="w-[110px]">C</:tab>
          <:panel name="a">1</:panel>
          <:panel name="b">2</:panel>
          <:panel name="c">3</:panel>
        </.tabs>
        """)

      assert html =~ ~s(data-part="tabs-indicator")
      assert html =~ "--x2:132px;--x3:264px"
      assert html =~ "animate-[lu-tbc2_6s_infinite]"
      assert html =~ "animate-[lu-tu3_6s_infinite]"
      refute html =~ ~r/\shidden[\s>]/
    end
  end

  describe "menu_panel" do
    test "is the open menu box in the page" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.menu_panel width="w-[230px]" class="mt-4">
          <.dropdown_item>Edit</.dropdown_item>
        </.menu_panel>
        """)

      assert html =~ ~s(data-part="pop")
      assert html =~ ~s(role="menu")
      assert html =~ "w-[230px]"
      assert html =~ "mt-4"
      refute html =~ "min-w-[220px]"
      assert html =~ "shadow-popover"
    end
  end

  describe "pagination arrows_at" do
    test "sides puts the previous arrow before the pages" do
      assigns = %{}

      end_html = rendered_to_string(~H|<.pagination page={2} total_pages={5} />|)
      sides = rendered_to_string(~H|<.pagination page={2} total_pages={5} arrows_at="sides" />|)

      first = fn html ->
        [{pos, _} | _] = :binary.matches(html, "data-part=\"pagination-")
        String.slice(html, pos, 40)
      end

      assert first.(sides) =~ "pagination-arrow"
      refute first.(end_html) =~ "pagination-arrow"
    end
  end
end
