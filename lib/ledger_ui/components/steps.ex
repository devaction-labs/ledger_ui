defmodule LedgerUI.Components.Steps do
  @moduledoc """
  Steps: numbered or plain points joined by a line (`steps/1`) and the progress stepper of a
  wizard (`stepper/1`). Both draw the canvas `lu-st2`; `stepper variant="classic"` is the old
  `lu-steps` bar.

      <.stepper current={2}>
        <:step label="Account" sub="Tax id and address" />
        <:step label="Plan" />
        <:step label="Payment" />
      </.stepper>

      <.steps color="primary" size="sm">
        <:step label="Cart" state="done">1</:step>
        <:step label="Shipping" state="current">2</:step>
      </.steps>

  `current` is the 0-based index of the step being worked on: the ones before are `done`, the
  ones after `todo`; with `error` the current one is flagged. A step's own `state` wins. The
  marker of a step is, in order: its `marker` text, its `icon`, a check when `done` (numbers for
  the `xs`/`sm` dots), `!` when `error`, else its number.

  Notes:

    * `color` and `size` on `stepper/1` are additions to the README (the canvas previews vary them).
    * The canvas markup carries no ARIA of its own, as in the design previews, so `state_names`
      is accepted but not rendered; a `:step` takes `style` (animation delays) and any other attribute.
    * The kit CSS classes the README mentions (`steps`, `step-primary`) are replaced by `lu-st2`.
  """
  use LedgerUI.Component

  @colors ~w(neutral primary secondary accent info success warning error)
  @sizes %{"xs" => "s-xs", "sm" => "s-sm", "md" => nil, "lg" => "s-lg"}
  @state_class %{"done" => "done", "current" => "cur", "error" => "err", "todo" => nil}
  @default_state_names %{
    "current" => "Current",
    "done" => "Completed",
    "error" => "Needs attention",
    "todo" => "Upcoming"
  }

  # ---------------------------------------------------------------------------------------
  # steps

  attr :color, :string, default: "neutral", values: @colors
  attr :orientation, :string, default: "horizontal", values: ~w(horizontal vertical)
  attr :size, :string, default: "md", values: ~w(xs sm md lg)
  attr :line_space, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global

  slot :step, required: true do
    attr :label, :string
    attr :color, :string
    attr :ping, :boolean
    attr :current, :boolean
    attr :state, :string
    attr :class, :any
    attr :style, :string
  end

  def steps(assigns) do
    assigns =
      assigns
      |> assign(:classes, classes(assigns, assigns.color))
      |> assign(:vertical, assigns.orientation == "vertical")
      |> assign(:items, Enum.map(assigns.step, &steps_item/1))

    ~H"""
    <div class={@classes} {@rest}>
      <div :for={s <- @items} class={s.class} {s.attrs}>
        <b>{if s.inner?, do: render_slot(s.slot)}</b>
        <span :if={@vertical and s.label}>{s.label}</span>
        <%= if !@vertical do %>
          {s.label}
        <% end %>
      </div>
    </div>
    """
  end

  defp steps_item(step) do
    state = step[:state] || if(step[:current], do: "current", else: "todo")

    %{
      slot: [step],
      inner?: step[:inner_block] != nil,
      label: step[:label],
      class: cx(["s", @state_class[state], step[:class]]),
      attrs: style_attrs(step_style(step))
    }
  end

  defp style_attrs(nil), do: %{}
  defp style_attrs(style), do: %{style: style}

  defp step_style(step) do
    case {step[:style], step[:color]} do
      {nil, nil} -> nil
      {style, nil} -> style
      {nil, color} -> "--c:var(--#{color})"
      {style, color} -> "#{style};--c:var(--#{color})"
    end
  end

  # ---------------------------------------------------------------------------------------
  # stepper

  attr :orientation, :string, default: "horizontal", values: ~w(horizontal vertical)
  attr :current, :integer, default: nil
  attr :error, :boolean, default: false
  attr :variant, :string, default: "canvas", values: ~w(canvas classic)
  attr :state_names, :map, default: @default_state_names
  attr :color, :string, default: nil, values: [nil | @colors]
  attr :size, :string, default: nil, values: [nil | Map.keys(@sizes)]
  attr :class, :any, default: nil
  attr :rest, :global

  slot :step, required: true do
    attr :label, :string
    attr :sub, :string
    attr :state, :string
    attr :marker, :string
    attr :icon, :string
    attr :class, :any
    attr :style, :string
  end

  def stepper(%{variant: "classic"} = assigns) do
    assigns = assign(assigns, :items, classic_items(assigns))

    ~H"""
    <div class={cx(["lu-steps", @class])} {@rest}>
      <%= for s <- @items do %>
        <div :if={s.line} class={s.line}></div>
        <div class={s.class}>
          <span class="n"><.icon :if={s.check?} name="check" size="sm" /><%= if !s.check? do %>{s.marker}<% end %></span>{s.label}
        </div>
      <% end %>
    </div>
    """
  end

  def stepper(assigns) do
    vertical? = assigns.orientation == "vertical"
    size = assigns.size

    assigns =
      assigns
      |> assign(:classes, classes(assigns, assigns.color))
      |> assign(:vertical, vertical?)
      |> assign(:items, canvas_items(assigns, size in ["xs", "sm"]))

    ~H"""
    <div class={@classes} {@rest}>
      <div :for={s <- @items} class={s.class} {s.attrs}>
        <b><.icon :if={s.icon} name={s.icon} size="sm" />
        <%= if !s.icon do %>
          {s.marker}
        <% end %></b>
        <%= if @vertical or s.sub do %>
          <span>{s.label}<small :if={s.sub}>{s.sub}</small>{if s.inner?, do: render_slot(s.slot)}</span>
        <% else %>
          {s.label}{if s.inner?, do: render_slot(s.slot)}
        <% end %>
      </div>
    </div>
    """
  end

  defp classes(a, color) do
    cx([
      "lu-st2",
      color && "c-" <> color,
      @sizes[a.size],
      a.orientation == "vertical" && "vert",
      a.class
    ])
  end

  defp state_of(step, index, a) do
    cond do
      step[:state] -> step.state
      a.current == nil -> nil
      index < a.current -> "done"
      index == a.current -> if(a.error, do: "error", else: "current")
      true -> "todo"
    end
  end

  defp canvas_items(a, dots?) do
    a.step
    |> Enum.with_index()
    |> Enum.map(fn {step, i} ->
      state = state_of(step, i, a)

      {icon, marker} =
        cond do
          step[:marker] -> {nil, step.marker}
          step[:icon] -> {step.icon, nil}
          state == "done" and not dots? -> {"check", nil}
          state == "error" -> {nil, "!"}
          true -> {nil, Integer.to_string(i + 1)}
        end

      %{
        slot: [step],
        inner?: step[:inner_block] != nil,
        label: step[:label],
        sub: step[:sub],
        icon: icon,
        marker: marker,
        class: cx(["s", @state_class[state], step[:class]]),
        attrs: style_attrs(step[:style])
      }
    end)
  end

  defp classic_items(a) do
    a.step
    |> Enum.with_index()
    |> Enum.map(fn {step, i} ->
      state = state_of(step, i, a)
      prev = if i > 0, do: state_of(Enum.at(a.step, i - 1), i - 1, a)

      %{
        label: step[:label],
        marker: step[:marker] || Integer.to_string(i + 1),
        check?: state == "done" and is_nil(step[:marker]),
        class: cx(["lu-step", @state_class[state]]),
        line: if(i > 0, do: cx(["lu-step-line", prev == "done" && "done"]))
      }
    end)
  end
end
