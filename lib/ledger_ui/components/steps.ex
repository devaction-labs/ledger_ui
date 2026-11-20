defmodule LedgerUI.Components.Steps do
  @moduledoc """
  Steps: numbered or plain points joined by a line (`steps/1`) and the progress stepper of a
  wizard (`stepper/1`). Both draw the canvas steps; `stepper variant="classic"` is the old bar of
  numbered squares. Styled only with Tailwind utilities; the colour enters as `--c`, `--c-on` and
  `--c-ink` (see `LedgerUI.Color`; `accent` is `primary`) and every part carries `data-part`
  (`steps`, `step`, `step-marker`, `step-label`, `step-sub`, `step-line`).

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
    * Accessibility is rendered server-side: the root is `role="list"`, each step `role="listitem"`;
      the current (or flagged) one has `aria-current="step"` and, on `stepper/1`, every step has
      an `aria-label` with its label and its state name (`state_names`, e.g. "Company, Completed").
      A `:step` takes `style` (animation delays) and any other attribute.
    * The kit CSS classes the README mentions (`steps`, `step-primary`) are replaced by utilities.
  """
  use LedgerUI.Component

  @colors ~w(neutral primary secondary accent info success warning error)
  @sizes ~w(xs sm md lg)
  @default_state_names %{
    "current" => "Current",
    "done" => "Completed",
    "error" => "Needs attention",
    "todo" => "Upcoming"
  }

  # the default colour is the accent
  @accent_vars "[--c:var(--color-accent)] [--c-on:#fff] [--c-ink:var(--color-accent-content)]"

  @step_base "relative before:absolute before:content-['']"
  @step_h "flex flex-1 flex-col items-center gap-1.5 text-center before:left-[calc(-50%+16px)] before:right-[calc(50%+16px)] before:h-[1.5px] first:before:hidden"
  @step_v "flex flex-none flex-row items-start gap-3 pb-[18px] text-left before:-top-[18px] before:left-[11px] before:h-[18px] before:w-[1.5px] first:before:hidden"
  @marker "z-[1] grid place-items-center rounded-full border-[1.5px] font-semibold"

  defp root_vars(nil), do: @accent_vars
  defp root_vars("accent"), do: LedgerUI.Color.vars("primary")
  defp root_vars(color), do: LedgerUI.Color.vars(color)

  defp root_classes(a, color) do
    cx([
      "flex items-start",
      a.orientation == "vertical" && "flex-col gap-0",
      root_vars(color),
      a.class
    ])
  end

  # one step: the connector `before` is part of it (filled once the step is done or current)
  defp step_classes(state, size, vertical?, loop? \\ false) do
    [
      @step_base,
      if(vertical?,
        do: @step_v,
        else: [@step_h, if(size == "lg", do: "before:top-4", else: "before:top-3")]
      ),
      cond do
        loop? -> nil
        state in ["done", "current"] -> "before:bg-(--c)"
        true -> "before:bg-line-strong"
      end,
      if(size in ["xs", "sm"], do: "text-[11.5px]", else: "text-[12.5px]"),
      case state do
        "current" -> "font-medium text-ink"
        "error" -> "text-neg"
        _ -> "text-muted"
      end
    ]
  end

  defp marker_classes(state, size) do
    [
      @marker,
      case size do
        "xs" -> "mt-[7px] size-2.5 text-[0px]"
        "sm" -> "mt-[5px] size-3.5 text-[0px]"
        "lg" -> "size-8 text-[13px]"
        _ -> "size-6 text-[11.5px]"
      end,
      case state do
        "done" ->
          "border-(color:--c) bg-(--c) text-(--c-on)"

        "current" ->
          "border-(color:--c) bg-panel text-(--c-ink) shadow-[0_0_0_4px_color-mix(in_oklab,var(--c)_16%,transparent)]"

        "error" ->
          "border-neg bg-neg-soft text-neg"

        _ ->
          "border-line-strong bg-panel text-muted"
      end
    ]
  end

  # ---------------------------------------------------------------------------------------
  # steps

  attr :color, :string, default: "neutral", values: @colors
  attr :orientation, :string, default: "horizontal", values: ~w(horizontal vertical)
  attr :size, :string, default: "md", values: @sizes
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
    vertical? = assigns.orientation == "vertical"

    assigns =
      assigns
      |> assign(:classes, root_classes(assigns, assigns.color))
      |> assign(:vertical, vertical?)
      |> assign(:items, Enum.map(assigns.step, &steps_item(&1, assigns.size, vertical?)))

    ~H"""
    <div data-part="steps" class={@classes} role="list" {@rest}>
      <div
        :for={s <- @items}
        data-part="step"
        class={s.class}
        role="listitem"
        aria-current={s.current}
        {s.attrs}
      >
        <b data-part="step-marker" class={s.marker}>{if s.inner?, do: render_slot(s.slot)}</b>
        <span :if={@vertical and s.label} data-part="step-label" class={s.label_class}>{s.label}</span>
        <%= if !@vertical do %>
          {s.label}
        <% end %>
      </div>
    </div>
    """
  end

  defp steps_item(step, size, vertical?) do
    state = step[:state] || if(step[:current], do: "current", else: "todo")

    %{
      slot: [step],
      inner?: step[:inner_block] != nil,
      label: step[:label],
      current: state == "current" && "step",
      class:
        cx([
          step_classes(state, size, vertical?),
          step[:color] && root_vars(step[:color]),
          step[:class]
        ]),
      marker: marker_classes(state, size),
      label_class: "flex flex-col gap-0.5 pt-0.5",
      attrs: style_attrs(step[:style])
    }
  end

  defp style_attrs(nil), do: %{}
  defp style_attrs(style), do: %{style: style}

  # ---------------------------------------------------------------------------------------
  # stepper

  attr :orientation, :string, default: "horizontal", values: ~w(horizontal vertical)
  attr :current, :integer, default: nil
  attr :error, :boolean, default: false
  attr :variant, :string, default: "canvas", values: ~w(canvas classic)
  attr :state_names, :map, default: @default_state_names
  attr :color, :string, default: nil, values: [nil | @colors]
  attr :size, :string, default: nil, values: [nil | @sizes]

  attr :loop, :boolean,
    default: false,
    doc:
      "The animated mock: the steps fill in turn (stagger them with `style=\"--dl:1.4s\"`); the states are not drawn."

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
    <div data-part="steps" class={cx(["flex items-center gap-0", @class])} {@rest}>
      <%= for s <- @items do %>
        <div :if={s.line} data-part="step-line" class={s.line}></div>
        <div
          data-part="step"
          class={s.class}
          aria-current={s.current}
          aria-label={s.aria_label}
        >
          <span data-part="step-marker" class={s.marker_class}><.icon
            :if={s.check?}
            name="check"
            size="sm"
          /><%= if !s.check? do %>{s.marker}<% end %></span>{s.label}
        </div>
      <% end %>
    </div>
    """
  end

  def stepper(assigns) do
    vertical? = assigns.orientation == "vertical"
    size = assigns.size || "md"

    assigns =
      assigns
      |> assign(:classes, root_classes(assigns, assigns.color))
      |> assign(:vertical, vertical?)
      |> assign(:items, canvas_items(assigns, size, vertical?, assigns.loop))

    ~H"""
    <div data-part="steps" class={@classes} role="list" {@rest}>
      <div
        :for={s <- @items}
        data-part="step"
        class={s.class}
        role="listitem"
        aria-current={s.current}
        aria-label={s.aria_label}
        {s.attrs}
      >
        <b data-part="step-marker" class={s.marker_class}><.icon :if={s.icon} name={s.icon} size="sm" />
        <%= if !s.icon do %>
          {s.marker}
        <% end %></b>
        <%= if @vertical or s.sub do %>
          <span data-part="step-label" class={s.label_class}>{s.label}<small
            :if={s.sub}
            data-part="step-sub"
            class="text-[length:smaller] font-normal text-muted"
          >{s.sub}</small>{if s.inner?, do: render_slot(s.slot)}</span>
        <% else %>
          {s.label}{if s.inner?, do: render_slot(s.slot)}
        <% end %>
      </div>
    </div>
    """
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

  @loop_marker "animate-[lu-stp_6s_infinite] [animation-delay:var(--dl)]"
  @loop_line "before:bg-[linear-gradient(90deg,var(--color-accent)_50%,var(--lu-line-strong)_50%)] before:bg-[length:200%_100%] before:bg-[position:100%_0] before:animate-[lu-stl_6s_infinite] before:[animation-delay:calc(var(--dl)-.6s)]"

  defp canvas_items(a, size, vertical?, loop?) do
    dots? = size in ["xs", "sm"]

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
        current: state in ["current", "error"] && "step",
        aria_label: aria_label(step[:label], state, a.state_names),
        class:
          cx([
            step_classes(if(loop?, do: "todo", else: state), size, vertical?, loop?),
            loop? && @loop_line,
            step[:class]
          ]),
        marker_class: [
          marker_classes(if(loop?, do: "todo", else: state), size),
          loop? && @loop_marker
        ],
        label_class: "flex flex-col gap-0.5 pt-0.5",
        attrs: style_attrs(step[:style])
      }
    end)
  end

  defp aria_label(label, state, names) when is_binary(label) and not is_nil(state) do
    case names[state] do
      nil -> nil
      name -> label <> ", " <> name
    end
  end

  defp aria_label(_, _, _), do: nil

  @classic_step "flex items-center gap-2.5 whitespace-nowrap text-[14px]"
  @classic_marker "grid size-[26px] place-items-center rounded-[8px] border text-[12.5px] font-semibold"

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
        current: state in ["current", "error"] && "step",
        aria_label: aria_label(step[:label], state, a.state_names),
        class:
          cx([
            @classic_step,
            if(state == "current", do: "font-medium text-ink", else: "text-muted")
          ]),
        marker_class: [
          @classic_marker,
          case state do
            "done" -> "border-accent bg-accent text-accent-foreground"
            "current" -> "border-ink bg-panel text-ink shadow-[0_0_0_3px_var(--lu-bg-sunken)]"
            _ -> "border-line-strong bg-panel"
          end
        ],
        line:
          if(i > 0,
            do: [
              "mx-3 h-[1.5px] min-w-6 flex-1",
              if(prev == "done", do: "bg-accent", else: "bg-line-strong")
            ]
          )
      }
    end)
  end
end
