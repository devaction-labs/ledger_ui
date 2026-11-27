defmodule LedgerUI.Components.StepGroup do
  @moduledoc """
  A framed card for processes in steps (a build, a deploy, issuing an invoice, an import).

      <.step_group id="deploy" title="Deploy logs" status={:running} duration="1m 04s">
        <:step title="Preparing environment" status={:ok} result="12s" />
        <:step title="Updating the stack" status={:running} result="Running…" open>
          <.step_group_line n={1} at="09:41:02" tone="dim">Connecting</.step_group_line>
          <.step_group_line n={2} at="09:41:04" tone="err">Rejected</.step_group_line>
        </:step>
        <:step title="Routing traffic" status={:waiting} result="Waiting" />
      </.step_group>

  `status` is one of `:ok`, `:running`, `:waiting`, `:failed`, `:skipped` and `:canceled`.

  The content of a `:step` is its log (`step_group_line/1` lines). A step with a log is a
  `<button>` that opens and closes the log; a step without one is a plain row. Without a
  `title` the card is just the list of steps (no header, nothing to collapse).

  Collapsing the card and opening a log happen in the browser (`Phoenix.LiveView.JS`), with no
  round trip; `collapsed` and `open` set where the state starts. `loop` plays the canvas loop
  (`mo-stg`): the rows fade in one after the other (each row's own `--dl` delay, e.g.
  `style="--dl:0.7s"`), forever. Styled only with Tailwind utilities.
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Button

  @statuses ~w(ok running waiting failed skipped canceled)a
  @icons %{ok: "check", skipped: "minus", failed: "x", canceled: "x"}
  @tones %{"dim" => "opacity-55", "err" => "bg-neg-soft", "ok" => "bg-pos-soft"}

  # the row, and the round mark of each status
  @rows %{skipped: "text-muted line-through", canceled: "text-muted"}
  @marks %{
    ok: "bg-pos text-white",
    waiting: "shadow-[inset_0_0_0_1.5px_var(--lu-line-strong)]",
    failed: "bg-neg text-white",
    skipped: "bg-selected text-muted",
    canceled: "text-muted shadow-[inset_0_0_0_1.5px_var(--lu-muted)]"
  }
  @row "flex items-center gap-2.5 rounded-lg px-2.5 py-2 text-[13.5px]"
  @loop "*:animate-[mo-stg_var(--dur,6s)_cubic-bezier(.2,.8,.2,1)_var(--dl,0s)_infinite]"

  attr :id, :string, default: nil, doc: "Required with a `title` (the collapse button needs it)."
  attr :title, :string, default: nil
  attr :status, :atom, default: :waiting, values: @statuses
  attr :duration, :string, default: nil
  attr :collapsed, :boolean, default: false

  attr :loop, :boolean,
    default: false,
    doc: "The canvas loop (`mo-stg`): the rows fade in one by one."

  attr :steps, :list,
    default: [],
    doc:
      "The steps as data, instead of `<:step>` slots: maps with `:title` and optionally `:status`, `:result`, `:id`. (No log: use the slots for that.)"

  attr :current, :integer,
    default: nil,
    doc:
      "With `steps`: the position (from 1) of the step in progress; the ones before it are `:ok`, the ones after `:waiting` (unless a step has its own `:status`)."

  attr :class, :any, default: nil
  attr :rest, :global

  slot :step, doc: "One step; its content is its log." do
    attr :title, :string
    attr :status, :atom
    attr :result, :string
    attr :open, :boolean
    attr :id, :string
    attr :class, :any
    attr :style, :string
  end

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def step_group(assigns) do
    changed0 = assigns.__changed__

    assigns =
      assigns
      |> assign(:panel_id, assigns.id && "#{assigns.id}-panel")
      |> assign(:loop_class, @loop)
      |> assign(:steps, steps(assigns))

    assigns =
      settle(assigns, changed0,
        panel_id: [:id],
        loop_class: [],
        steps: [:steps, :step, :id, :current]
      )

    ~H"""
    <div
      id={@id}
      data-part="step-group"
      class={["flex flex-col gap-0.5", @loop && @loop_class, @class]}
      {@rest}
    >
      <div
        :if={@title}
        data-part="step-group-header"
        class="flex items-center gap-2.5 px-2.5 py-2"
      >
        <.status_mark status={@status} />
        <b data-part="step-group-title" class="font-semibold">{@title}</b>
        <time
          :if={@duration}
          data-part="step-group-duration"
          class="min-w-0 flex-1 font-mono text-xs text-muted"
        >{@duration}</time>
        <Button.button
          :if={@panel_id}
          canvas
          size="sm"
          icon
          aria-label={I18n.t("step_group.collapse", @locale)}
          aria-controls={@panel_id}
          aria-expanded={to_string(!@collapsed)}
          phx-click={toggle(@panel_id)}
        >
          <.icon name="chevron-down" size="sm" />
        </Button.button>
      </div>
      <div
        :if={@title}
        id={@panel_id}
        data-part="step-group-panel"
        class={@collapsed && "hidden"}
      >
        <.step :for={s <- @steps} step={s} />
      </div>
      <.step :for={s <- @steps} :if={!@title} step={s} />
    </div>
    """
  end

  # Shows/hides `id` and flips `aria-expanded` on the button that was clicked.
  defp toggle(id) do
    JS.toggle(to: "##{id}") |> JS.toggle_attribute({"aria-expanded", "true", "false"})
  end

  defp steps(%{steps: [_ | _] = data, id: id, current: current}) do
    data
    |> Enum.with_index(1)
    |> Enum.map(fn {step, i} ->
      %{
        status: step[:status] || position_status(i, current),
        title: step[:title],
        result: step[:result],
        open: false,
        class: step[:class],
        attrs: %{},
        log?: false,
        id: step[:id] || (id && "#{id}-step-#{i - 1}"),
        slot: nil
      }
    end)
  end

  defp steps(%{step: steps, id: id}) do
    steps
    |> Enum.with_index()
    |> Enum.map(fn {step, i} ->
      %{
        status: step[:status] || :waiting,
        title: step[:title],
        result: step[:result],
        open: step[:open] || false,
        class: step[:class],
        attrs: if(step[:style], do: %{style: step[:style]}, else: %{}),
        log?: !blank_slot?(step[:inner_block]),
        id: step[:id] || (id && "#{id}-step-#{i}"),
        slot: step
      }
    end)
  end

  defp position_status(_i, nil), do: :waiting
  defp position_status(i, current) when i < current, do: :ok
  defp position_status(i, current) when i == current, do: :running
  defp position_status(_i, _current), do: :waiting

  # A call with a body but only named slots still carries an empty `inner_block`.
  defp blank_slot?(slot) when slot in [nil, []], do: true
  defp blank_slot?([%{inner_block: %Phoenix.LiveView.Rendered{static: [""]}}]), do: true
  defp blank_slot?(_), do: false

  attr :status, :atom, required: true

  defp status_mark(%{status: :running} = assigns) do
    ~H"""
    <span
      data-part="step-group-mark"
      class="size-5 flex-none animate-[lu-spin_.9s_linear_infinite] rounded-full border-2 border-accent-500 border-r-transparent"
    ></span>
    """
  end

  defp status_mark(assigns) do
    changed0 = assigns.__changed__
    assigns = assign(assigns, icon: @icons[assigns.status], mark: @marks[assigns.status])
    assigns = settle(assigns, changed0, icon: [:status], mark: [:status])

    ~H"""
    <span
      data-part="step-group-mark"
      class={["grid size-5 flex-none place-items-center rounded-full", @mark]}
    >
      <.icon :if={@icon} name={@icon} size="sm" />
    </span>
    """
  end

  attr :step, :map, required: true

  defp step(%{step: %{log?: false}} = assigns) do
    changed0 = assigns.__changed__
    assigns = assign(assigns, row: @row, rows: @rows)
    assigns = settle(assigns, changed0, row: [], rows: [])

    ~H"""
    <div
      id={@step.id}
      data-part="step-group-step"
      class={[@row, @rows[@step.status], @step.class]}
      {@step.attrs}
    >
      <.status_mark status={@step.status} /><span>{@step.title}</span><time
        data-part="step-group-result"
        class="ml-auto font-mono text-[11.5px] text-subtle"
      >{@step.result}</time>
    </div>
    """
  end

  defp step(assigns) do
    changed0 = assigns.__changed__

    assigns =
      assigns
      |> assign(:log_id, assigns.step.id && "#{assigns.step.id}-log")
      |> assign(row: @row, rows: @rows)

    assigns = settle(assigns, changed0, log_id: [:step], row: [], rows: [])

    ~H"""
    <button
      id={@step.id}
      type="button"
      data-part="step-group-step"
      class={["w-full text-left", @row, @rows[@step.status], @step.class]}
      aria-controls={@log_id}
      aria-expanded={@log_id && to_string(@step.open == true)}
      phx-click={@log_id && toggle(@log_id)}
      {@step.attrs}
    >
      <.status_mark status={@step.status} /><span>{@step.title}</span><time
        data-part="step-group-result"
        class="ml-auto font-mono text-[11.5px] text-subtle"
      >{@step.result}</time><.icon
        name="chevron-down"
        size="sm"
      />
    </button>
    <div
      id={@log_id}
      data-part="step-group-log"
      class={["px-3 pt-1 pb-2", !@step.open && "hidden"]}
    >
      {render_slot([@step.slot])}
    </div>
    """
  end

  attr :n, :integer, required: true, doc: "The line number."
  attr :at, :string, default: nil, doc: "The time of the line."
  attr :tone, :string, default: nil, values: [nil | Map.keys(@tones)]
  slot :inner_block, required: true

  def step_group_line(assigns) do
    changed0 = assigns.__changed__
    assigns = assign(assigns, :tone_class, @tones[assigns.tone])
    assigns = settle(assigns, changed0, tone_class: [:tone])

    ~H"""
    <div
      data-part="step-group-line"
      class={[
        "flex items-center gap-2.5 rounded-lg px-2.5 py-2 font-mono text-[12px]",
        @tone_class
      ]}
    >
      <span data-part="step-group-line-n" class="text-muted">{@n}</span><time
        :if={@at}
        data-part="step-group-time"
        class="ml-auto font-mono text-[11.5px] text-subtle"
      >{@at}</time><span>{render_slot(@inner_block)}</span>
    </div>
    """
  end
end
