defmodule LedgerUI.Perf.ContentATest do
  # #85 (A1/A6) in the content components: the classes and the values derived from the attrs are
  # not sent again when only the text or the slot changes (`settle/3`), and no source was left
  # out of a list (`each_source/3`: change ONE attr, and the page the client ends up with is the
  # one a fresh render gives).
  use ExUnit.Case, async: true

  import LedgerUI.DiffCase

  # the wrappers are not compiled with the project (`use LedgerUI` needs the finished components)
  Code.require_file("../../support/content_a_cases.exs", __DIR__)

  alias LedgerUI.ContentACases, as: C

  # one test per call: every attr that feeds a `settle/3` changes alone
  for {name, _fun, _base, _alt} <- C.sources() do
    test "each source of #{name}" do
      {_, fun, base, alt} = Enum.find(C.sources(), &(elem(&1, 0) == unquote(name)))
      each_source(fun, base, alt)
    end
  end

  # the class values of a render, to look for them in a patch
  defp classes_of(html) do
    ~r/class="([^"]{6,})"/
    |> Regex.scan(html, capture: :all_but_first)
    |> List.flatten()
    |> Enum.map(&String.replace(&1, "&amp;", "&"))
    |> Enum.uniq()
  end

  # `only:` limits the check to the classes that start with that text (a comprehension sends all its
  # items again, and a nested component that is not settled sends its own classes again)
  defp no_classes(fun, base, changes, opts \\ []) do
    {json, html} = first(fun, base)

    classes =
      case opts[:only] do
        nil -> classes_of(html)
        prefix -> Enum.filter(classes_of(html), &String.starts_with?(&1, prefix))
      end

    assert classes != []
    patch = check(fun, base, changes)
    assert patch != json

    for c <- classes do
      refute String.contains?(patch, c), "the patch sends the classes again: #{c}"
    end
  end

  describe "a new text or body does not send the classes again" do
    test "kpi_card" do
      no_classes(&C.t_kpi/1, C.d_kpi(), delta: "-9%", compare: "vs Oct")
      no_classes(&C.t_kpi/1, C.d_kpi(), compare: "vs Oct", caption: "faint")
    end

    test "alert" do
      no_classes(&C.t_alert/1, C.d_alert(), body: "Other body")
      no_classes(&C.t_alert/1, C.d_alert(), description: "other", title: "Other")
    end

    test "avatar" do
      no_classes(&C.t_avatar/1, Map.put(C.d_avatar(), :src, "/a.png"), alt: "Alt text")
    end

    test "avatar_group" do
      no_classes(&C.t_avatar_group/1, C.d_avatar_group(), label: "Team")
      no_classes(&C.t_avatar_group/1, C.d_avatar_group(), more: 7)
    end

    test "chip" do
      no_classes(&C.t_chip/1, C.d_chip(), label: "Other")
      no_classes(&C.t_chip/1, Map.put(C.d_chip(), :count, 1), count: 3)
      no_classes(&C.t_chip_click/1, C.d_chip_click(), label: "Other")
    end

    test "drawer" do
      no_classes(&C.t_drawer/1, C.d_drawer(), body: "Other body")
      no_classes(&C.t_drawer/1, C.d_drawer(), title: "Other", description: "other")
      no_classes(&C.t_drawer/1, C.d_drawer_page(), body: "Other body")
    end

    test "input_group" do
      # (`help` sits in `Form.field`, which is not this module's)
      no_classes(&C.t_input_group/1, C.d_input_group_bare(), addon: "R$")
    end

    test "aura, cover, container, divider" do
      no_classes(&C.t_aura/1, C.d_aura(), body: "other")
      no_classes(&C.t_cover/1, C.d_cover(), subtitle: "other")
      no_classes(&C.t_container/1, C.d_container(), body: "other")
      no_classes(&C.t_divider/1, C.d_divider(), label: "and")
    end

    test "carousel and cash_timer" do
      no_classes(&C.t_carousel/1, C.d_carousel(), body: "other")
      no_classes(&C.t_cash_timer/1, C.d_cash_timer(), amount: "$20", title: "Register 2")
    end

    test "collapse, description_list, code_block" do
      # the trigger slot is a source (its `class` and `style` feed `summary_class`), the body is not
      no_classes(&C.t_collapse/1, C.d_collapse(), body: "other")
      no_classes(&C.t_collapse_text/1, C.d_collapse_text(), body: "other")

      no_classes(&C.t_description_list/1, C.d_description_list(), [value: "Bia", label: "Other"],
        only: "grid gap-x-6"
      )
    end

    test "image_input, clipboard, placement_stage" do
      no_classes(&C.t_image_input/1, C.d_image_input(), value: "/p.png")
      no_classes(&C.t_clipboard/1, C.d_clipboard(), value: "def", body: "Other")
      no_classes(&C.t_placement_stage/1, C.d_placement_stage(), alt: "B")
    end

    test "calendar and charts" do
      no_classes(&C.t_calendar/1, C.d_calendar_mini(), selected: ~D[2026-03-12])

      no_classes(&C.t_line_chart/1, C.d_line_chart(), [head: "$20", sub: "other"],
        only: "font-display"
      )

      no_classes(&C.t_donut/1, C.d_donut(), center_value: "$99")
      no_classes(&C.t_bar_chart/1, C.d_bar_chart(), values: [5, 50, 20])
      no_classes(&C.t_heatmap/1, C.d_heatmap(), levels: [4, 3, 2, 1, 0, 0])
    end

    test "fab, bulk_bar, color_picker" do
      no_classes(&C.t_fab/1, C.d_fab(), body: "Other")
      no_classes(&C.t_fab_dial/1, C.d_fab_dial(), action: "Two")
      no_classes(&C.t_bulk_bar/1, C.d_bulk_bar(), count: 10)
      no_classes(&C.t_color_picker/1, C.d_color_picker(), value: "#112233")
    end

    test "error pages, flow, auth" do
      no_classes(&C.t_error_page/1, C.d_error_page(), title: "Broken", description: "Sorry")
      no_classes(&C.t_error_state/1, C.d_error_state(), title: "Broken")
      no_classes(&C.t_flow/1, C.d_flow(), [title: "Other"], only: "flex min-h-[420px]")
      no_classes(&C.t_auth_split/1, C.d_auth_split(), title: "Hello", body: "other")
      no_classes(&C.t_oauth_button/1, C.d_oauth_button(), body: "GitHub")
      no_classes(&C.t_auth_submit/1, C.d_auth_submit(), loading_label: "Hold on")
    end

    test "ai" do
      no_classes(&C.t_ai_insights/1, C.d_ai_insights(), insights: [%{title: "Cost", text: "x"}])
      no_classes(&C.t_ai_promo/1, C.d_ai_promo(), subtitle: "Ask me")
      no_classes(&C.t_ai_greeting/1, C.d_ai_greeting(), greeting: "Hi")
      no_classes(&C.t_ai_message/1, C.d_ai_message(), body: "Other")
      no_classes(&C.t_ai_message/1, C.d_ai_message_user(), body: "Other")
      no_classes(&C.t_prompt_suggestions/1, C.d_prompt_suggestions(), on_pick: "pick")
    end

    test "accordion" do
      no_classes(&C.t_accordion/1, C.d_accordion(), body: "Other body")
      no_classes(&C.t_accordion/1, C.d_accordion(), title: "Other")
    end
  end
end
