defmodule LedgerUI.Components.KpiCardTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.KpiCard
  import LedgerUI.Components.Icon, only: [icon: 1]

  test "canvas card with delta tone and spark" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.kpi_card
  id="k"
  label="Churn"
  value="2.1"
  unit="%"
  delta="0.4"
  trend="up"
  delta_tone="error"
  spark={[1, 3, 2]}
/>|)

    assert html =~ ~s(data-part="kpi-delta")
    # a bad-news increase: red with an up triangle
    assert html =~ "text-neg"
    assert html =~ "before:border-b-[6px]"
    assert html =~ ~s(data-part="kpi-arrow")
    assert html =~ ~s(data-part="sparkline")
    assert html =~ "k-spark-fill"
    refute html =~ ~r/class="[^"]*\blu-(kpi|card|delta|badge|spark)/
  end

  test "badge variant counts and colors" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.kpi_card variant="badge" color="neutral" label="A" count={5} delta="1" trend="down" />|
      )

    assert html =~ "--to:5"
    assert html =~ ~s(data-part="badge")
    assert html =~ "bg-neg-soft"
    assert html =~ "↘"
  end

  test "progress and loading" do
    assigns = %{}

    assert rendered_to_string(~H|<.kpi_card label="A" progress={40} caption="c" />|) =~
             "width:40%"

    assert rendered_to_string(~H|<.kpi_card loading />|) =~ "aria-busy"
  end

  test "footer slot and value_id are opt-in" do
    assigns = %{}
    base = rendered_to_string(~H|<.kpi_card label="a" value="1" />|)
    refute base =~ "kpi-footer"
    refute base =~ " id="

    html =
      rendered_to_string(~H"""
      <.kpi_card label="a" value="1" value_id="v1">
        <:footer><a href="/r">ver</a></:footer>
      </.kpi_card>
      """)

    assert html =~ ~r/data-part="kpi-value"\s+id="v1"/
    assert html =~ ~s(data-part="kpi-footer")
    assert html =~ ~s(<a href="/r">ver</a>)

    badge =
      rendered_to_string(~H|<.kpi_card variant="badge" label="a" value="1" value_id="v2" />|)

    assert badge =~ ~s(id="v2")
  end

  test "refined look: one surface, 32px figure, plain label, footer rule" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.kpi_card id="k" label="MRR" value="1" delta="2%" spark={[1, 3, 2]} />|
      )

    assert html =~ "rounded-[18px] border border-line bg-panel shadow-xs"
    refute html =~ "bg-tray"
    refute html =~ "uppercase"
    assert html =~ "text-[32px]"
    assert html =~ "border-t"
    assert html =~ "border-line text-muted"
    assert html =~ "font-medium tracking-[-.03em]"
    refute html =~ "font-semibold tracking-[-.035em]"
    assert html =~ "opacity-55"
  end

  describe "tone" do
    test "default keeps the panel and the label in ink-2" do
      assigns = %{}
      html = rendered_to_string(~H|<.kpi_card label="A" value="1" />|)
      assert html =~ "border-line bg-panel"
      assert html =~ "text-ink-2"
      refute html =~ "bg-highlight"
    end

    test "highlight, dark and positive paint the card and the texts" do
      assigns = %{}

      hl = rendered_to_string(~H|<.kpi_card tone="highlight" label="A" value="1" delta="2" />|)
      assert hl =~ "bg-highlight"
      assert hl =~ "text-highlight-ink"
      refute hl =~ "bg-panel"
      refute hl =~ "text-pos"

      dark = rendered_to_string(~H|<.kpi_card tone="dark" label="A" value="1" />|)
      assert dark =~ "bg-inverse text-on-inverse"
      assert dark =~ "text-on-inverse/75"

      pos = rendered_to_string(~H|<.kpi_card tone="positive" label="A" value="1" />|)
      assert pos =~ "bg-pos-soft"
      refute pos =~ "bg-panel"
    end

    test "each value renders" do
      assigns = %{}

      for tone <- ~w(default highlight dark positive) do
        assigns = %{tone: tone}
        html = rendered_to_string(~H|<.kpi_card tone={@tone} label="A" value="1" />|)
        assert html =~ ~s(data-part="kpi-card")
      end
    end

    test "the icon keeps a visible colour in every tone" do
      for {tone, color} <- [
            {"default", "text-ink-2"},
            {"highlight", "text-highlight-ink"},
            {"dark", "text-on-inverse"},
            {"positive", "text-ink-2"}
          ] do
        assigns = %{tone: tone}

        html =
          rendered_to_string(~H"""
          <.kpi_card tone={@tone} label="A" value="1">
            <:icon><.icon name="users" /></:icon>
          </.kpi_card>
          """)

        [icon] =
          Regex.run(~r/<span data-part="kpi-icon" class="([^"]*)"/, html, capture: :all_but_first)

        assert icon =~ color, "#{tone}: #{icon}"
        assert html =~ ~s(data-icon="users")
      end
    end

    test "the round arrow button is 28px, inverse, and only with open_label" do
      assigns = %{}
      none = rendered_to_string(~H|<.kpi_card label="A" value="1" delta="1" />|)
      refute none =~ "kpi-open"

      html = rendered_to_string(~H|<.kpi_card label="A" value="1" open_label="Abrir" />|)

      assert html =~
               ~r/data-part="kpi-open"[^>]*class="[^"]*size-7[^"]*bg-inverse text-on-inverse/

      dark =
        rendered_to_string(~H|<.kpi_card tone="dark" label="A" value="1" open_label="Abrir" />|)

      assert dark =~ "bg-on-inverse text-inverse"
    end

    test "the icon is a 36px ring; soft tones keep their fill, only on the default card" do
      assigns = %{}

      neutral =
        rendered_to_string(~H"""
        <.kpi_card label="A" value="1">
          <:icon>i</:icon>
        </.kpi_card>
        """)

      assert neutral =~ "size-9"
      assert neutral =~ "rounded-full border"
      assert neutral =~ "border-line-strong text-ink-2"
      refute neutral =~ "bg-accent-soft"

      soft =
        rendered_to_string(~H"""
        <.kpi_card label="A" value="1" icon_tone="pos">
          <:icon>i</:icon>
        </.kpi_card>
        """)

      assert soft =~ "bg-pos-soft"

      tinted =
        rendered_to_string(~H"""
        <.kpi_card tone="dark" icon_tone="pos" label="A" value="1">
          <:icon>i</:icon>
        </.kpi_card>
        """)

      refute tinted =~ "bg-pos-soft"
      assert tinted =~ "border-on-inverse/25"
    end

    test "every source of the tone classes is tracked (a patch is never stale)" do
      base = %{
        tone: "default",
        icon_tone: "neutral",
        delta_tone: nil,
        trend: "up",
        class: nil,
        footer_layout: "row",
        label: "MRR",
        open_label: "Abrir"
      }

      LedgerUI.DiffCase.each_source(&t_kpi/1, base,
        tone: "dark",
        icon_tone: "pos",
        delta_tone: "error",
        trend: "down",
        class: "mt-2",
        footer_layout: "stack"
      )

      for tone <- ~w(highlight positive) do
        LedgerUI.DiffCase.check(&t_kpi/1, base, tone: tone)
      end
    end

    test "a new label does not send the classes again" do
      base = %{
        tone: "dark",
        icon_tone: "neutral",
        delta_tone: nil,
        trend: "up",
        class: nil,
        footer_layout: "row",
        label: "MRR",
        open_label: "Abrir"
      }

      patch = LedgerUI.DiffCase.patch(&t_kpi/1, base, label: "ARR")
      assert patch =~ "ARR"
      refute patch =~ "bg-inverse"
      refute patch =~ "rounded"
    end
  end

  defp t_kpi(assigns) do
    ~H"""
    <.kpi_card
      tone={@tone}
      icon_tone={@icon_tone}
      delta_tone={@delta_tone}
      trend={@trend}
      class={@class}
      footer_layout={@footer_layout}
      label={@label}
      value="1"
      delta="2%"
      open_label={@open_label}
    >
      <:icon>i</:icon>
    </.kpi_card>
    """
  end

  describe "extension points" do
    test "without the new attrs the card has none of their markup" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<.kpi_card label="MRR" value="1" delta="8" compare="x" spark={[1, 2]} />|
        )

      refute html =~ "kpi-label-extra"
      refute html =~ ~s(data-part="kpi-number")
      refute html =~ "flex-col items-start"
      assert html =~ "w-[40%]"
      assert html =~ ~s(data-part="sparkline-dot")
      assert html =~ ~s(data-part="kpi-arrow")
    end

    test "label_extra sits at the end of the label row" do
      assigns = %{}

      canvas =
        rendered_to_string(~H"""
        <.kpi_card label="MRR" value="1" live>
          <:label_extra><button>Ver</button></:label_extra>
        </.kpi_card>
        """)

      badge =
        rendered_to_string(~H"""
        <.kpi_card variant="badge" label="MRR" value="1">
          <:label_extra><button>Ver</button></:label_extra>
        </.kpi_card>
        """)

      for html <- [canvas, badge] do
        assert html =~ ~r/data-part="kpi-label-extra" class="ml-auto"><button>Ver<\/button>/
      end
    end

    test "value_tone paints only the figure" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<.kpi_card label="A" prefix="R$" value="9" unit="k" value_tone="warning" />|
        )

      assert html =~ ~r/data-part="kpi-number" class="text-warn">9</
      assert html =~ ~r/data-part="kpi-prefix" class="[^"]*text-subtle/

      err = rendered_to_string(~H|<.kpi_card label="A" value="9" value_tone="error" />|)
      assert err =~ ~r/data-part="kpi-number" class="text-neg">9</

      badge =
        rendered_to_string(
          ~H|<.kpi_card variant="badge" label="A" value="9" value_tone="error" />|
        )

      assert badge =~ ~r/data-part="kpi-number" class="font-semibold text-neg"/
    end

    test "footer_layout stack puts the footer in a column" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.kpi_card label="A" value="1" delta="2" compare="x" open_label="Open" footer_layout="stack">
          <:footer>f</:footer>
        </.kpi_card>
        """)

      assert html =~ ~r/data-part="kpi-footer" class="flex flex-col items-start gap-2/
      refute html =~ ~s(min-w-0 flex-1"></span>)
      assert html =~ "self-end"
    end

    test "spark_variant corner is small, in the corner and without the dot" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<.kpi_card id="c" label="A" value="1" spark={[1, 3, 2]} spark_variant="corner" />|
        )

      assert html =~ "h-[30px] w-24"
      refute html =~ "w-[40%]"
      refute html =~ "sparkline-dot"
    end

    test "arrow false drops the arrow beside the figure in both variants" do
      assigns = %{}

      canvas = rendered_to_string(~H|<.kpi_card label="A" value="1" delta="2" arrow={false} />|)
      refute canvas =~ "kpi-arrow"
      assert canvas =~ "kpi-delta"

      badge =
        rendered_to_string(
          ~H|<.kpi_card variant="badge" label="A" value="1" delta="2" arrow={false} />|
        )

      refute badge =~ "kpi-arrow"
    end

    test "loading still draws the skeleton in the same card" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<.kpi_card loading spark_variant="corner" value_tone="error" arrow={false} footer_layout="stack" />|
        )

      assert html =~ "aria-busy"
      assert html =~ "kpi-skeleton"
    end
  end
end
