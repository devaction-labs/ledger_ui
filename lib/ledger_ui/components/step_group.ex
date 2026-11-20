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
  round trip; `collapsed` and `open` set where the state starts.
  """
  use LedgerUI.Component

  @statuses ~w(ok running waiting failed skipped canceled)a
  @icons %{ok: "check", skipped: "minus", failed: "x", canceled: "x"}
  @tones %{"dim" => "dim", "err" => "err", "ok" => "okk"}

  attr :id, :string, default: nil, doc: "Required with a `title` (the collapse button needs it)."
  attr :title, :string, default: nil
  attr :status, :atom, default: :waiting, values: @statuses
  attr :duration, :string, default: nil
  attr :collapsed, :boolean, default: false
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

  def step_group(assigns) do
    assigns =
      assigns
      |> assign(:classes, cx(["lu-sg2", assigns.class]))
      |> assign(:panel_id, assigns.id && "#{assigns.id}-panel")
      |> assign(:steps, steps(assigns))
      |> assign(:panel_style, assigns.collapsed && "display:none")

    ~H"""
    <div id={@id} data-part="step-group" class={@classes} {@rest}>
      <div :if={@title} class="hd" style="display:flex;align-items:center;gap:10px;padding:8px 10px">
        <.status_mark status={@status} />
        <b style="font-weight:600">{@title}</b>
        <time :if={@duration} class="lu-grow mono lu-xs lu-muted" style="margin-left:auto">{@duration}</time>
        <button
          :if={@panel_id}
          type="button"
          class="lu-btn icon sm"
          aria-label="Collapse"
          phx-click={JS.toggle(to: "##{@panel_id}")}
        >
          <.icon name="chevron-down" size="sm" />
        </button>
      </div>
      <div :if={@title} id={@panel_id} class="pn" {panel_attrs(@panel_style)}>
        <.step :for={s <- @steps} step={s} />
      </div>
      <.step :for={s <- @steps} :if={!@title} step={s} />
    </div>
    """
  end

  defp panel_attrs(nil), do: %{}
  defp panel_attrs(false), do: %{}
  defp panel_attrs(style), do: %{style: style}

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

  # A call with a body but only named slots still carries an empty `inner_block`.
  defp blank_slot?(slot) when slot in [nil, []], do: true
  defp blank_slot?([%{inner_block: %Phoenix.LiveView.Rendered{static: [""]}}]), do: true
  defp blank_slot?(_), do: false

  attr :status, :atom, required: true

  defp status_mark(%{status: :running} = assigns) do
    ~H"""
    <span class="lu-ring2"></span>
    """
  end

  defp status_mark(assigns) do
    assigns = assign(assigns, :icon, @icons[assigns.status])

    ~H"""
    <span class="ic"><.icon :if={@icon} name={@icon} size="sm" /></span>
    """
  end

  attr :step, :map, required: true

  defp step(%{step: %{log?: false}} = assigns) do
    ~H"""
    <div id={@step.id} class={cx(["r", @step.status, @step.class])} {@step.attrs}>
      <.status_mark status={@step.status} /><span>{@step.title}</span><time>{@step.result}</time>
    </div>
    """
  end

  defp step(assigns) do
    assigns = assign(assigns, :log_id, assigns.step.id && "#{assigns.step.id}-log")

    ~H"""
    <button
      id={@step.id}
      type="button"
      class={cx(["r", @step.status, @step.class])}
      style="width:100%;text-align:left"
      phx-click={@log_id && JS.toggle(to: "##{@log_id}")}
    >
      <.status_mark status={@step.status} /><span>{@step.title}</span><time>{@step.result}</time><.icon
        name="chevron-down"
        size="sm"
      />
    </button>
    <div
      id={@log_id}
      class="log"
      style={if @step.open, do: "padding:4px 12px 8px", else: "display:none;padding:4px 12px 8px"}
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
    assigns = assign(assigns, :tones, @tones)

    ~H"""
    <div
      data-part="step-group-line"
      class={cx(["r ln mono", @tone && @tones[@tone]])}
      style="display:flex;gap:10px;font-size:12px"
    >
      <span class="n lu-muted">{@n}</span><time :if={@at} class="lu-muted">{@at}</time><span>{render_slot(
        @inner_block
      )}</span>
    </div>
    """
  end
end
