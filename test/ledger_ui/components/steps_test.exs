defmodule LedgerUI.Components.StepsTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Steps

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

  test "stepper: states follow current, markers and labels" do
    assigns = %{}

    html =
      norm(~H"""
      <.stepper current={1}>
        <:step label="Company" />
        <:step label="Certificate" />
        <:step label="Tax" />
      </.stepper>
      """)

    assert tag(html, "steps") =~ "items-start"
    assert tag(html, "step", 0) =~ "before:bg-(--c)"
    assert tag(html, "step-marker", 0) =~ "bg-(--c)"
    assert html =~ ~s(data-icon="check")
    assert tag(html, "step", 1) =~ "font-medium"
    assert tag(html, "step", 1) =~ ~s(aria-current="step")
    assert tag(html, "step", 2) =~ "text-muted"
    assert html =~ ~r/step-marker"[^>]*>2<\/b>/
    assert html =~ ~r/step-marker"[^>]*>3<\/b>/
    refute html =~ ~r/[\s"]lu-/
    assert html =~ "Tax"
  end

  test "error flags the current step with !" do
    assigns = %{}

    html =
      norm(~H|<.stepper current={0} error><:step label="A" /><:step label="B" /></.stepper>|)

    assert tag(html, "step") =~ "text-neg"
    assert tag(html, "step-marker") =~ "bg-neg-soft"
    assert html =~ ~r/step-marker"[^>]*>!<\/b>/
  end

  test "a step's own state wins; marker and icon override" do
    assigns = %{}

    html =
      norm(~H"""
      <.stepper current={0}>
        <:step label="A" state="done" marker="1" />
        <:step label="B" state="error" />
        <:step label="C" icon="file" />
      </.stepper>
      """)

    assert tag(html, "step", 0) =~ "before:bg-(--c)"
    assert html =~ ~r/step-marker"[^>]*>1<\/b>/
    assert html =~ ~r/step-marker"[^>]*>!<\/b>/
    assert html =~ ~s(data-icon="file")
  end

  test "color, size and the xs/sm dots show numbers when done" do
    assigns = %{}

    html =
      norm(~H"""
      <.stepper current={1} color="success" size="xs"><:step label="A" /><:step label="B" /></.stepper>
      """)

    assert tag(html, "steps") =~ "[--c:var(--lu-pos)]"
    assert tag(html, "step-marker") =~ "size-2.5"
    assert tag(html, "step-marker") =~ "text-[0px]"
    assert html =~ ~r/step-marker"[^>]*>1<\/b>/
    refute html =~ "data-icon"
  end

  test "vertical: label and sub in a span, content after" do
    assigns = %{}

    html =
      norm(~H"""
      <.stepper orientation="vertical" current={0}>
        <:step label="Company" sub="12 registered"><button>Import</button></:step>
      </.stepper>
      """)

    assert tag(html, "steps") =~ "flex-col"
    assert tag(html, "step") =~ "flex-row"

    assert html =~
             ~r/step-label"[^>]*>Company<small[^>]*>12 registered<\/small><button>Import<\/button><\/span>/
  end

  test "classic variant renders lu-steps with lines" do
    assigns = %{}

    html =
      norm(~H"""
      <.stepper variant="classic" current={1}>
        <:step label="A" /><:step label="B" /><:step label="C" />
      </.stepper>
      """)

    assert tag(html, "steps") =~ "items-center"
    assert tag(html, "step", 1) =~ "font-medium"
    assert tag(html, "step-marker", 0) =~ "bg-accent"
    assert tag(html, "step-line", 0) =~ "bg-accent"
    assert tag(html, "step-line", 1) =~ "bg-line-strong"
  end

  test "steps/1: points with their content, colors and sizes" do
    assigns = %{}

    html =
      norm(~H"""
      <.steps color="primary" size="sm" orientation="vertical">
        <:step label="Cart" state="done">1</:step>
        <:step label="Ship" current color="success">2</:step>
        <:step label="Pay" />
      </.steps>
      """)

    assert tag(html, "steps") =~ "[--c:var(--color-accent)]"
    assert tag(html, "step", 0) =~ "before:bg-(--c)"
    assert html =~ ~r/step-marker"[^>]*>1<\/b>/
    assert tag(html, "step", 1) =~ "font-medium"
    assert tag(html, "step", 1) =~ "[--c:var(--lu-pos)]"
    assert html =~ ~r/step-label"[^>]*>Cart<\/span>/
  end
end
