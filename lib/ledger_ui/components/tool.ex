defmodule LedgerUI.Components.Tool do
  @moduledoc """
  A tool call an agent makes (running a command, reading a file), from input to output, as a line
  of a `LedgerUI.Components.Trace.trace/1`: a plain line while it runs, a step that opens on its
  output once it has one, red when it fails. A call that waits for the user is a
  `tool_approval/1` card with Deny and Approve.

      <.trace>
        <.tool id="t1" state="running" subject="pnpm install" />
        <.tool id="t2" state="done" subject="node --version" output="v24.18.0" />
        <.tool id="t3" state="error" subject="pnpm lint" output={@stderr} />
      </.trace>

  ## States

  | `state`   | line                | title (en / pt_BR)                  |
  |-----------|---------------------|-------------------------------------|
  | `running` | `running` (spinner) | Running ... / Rodando ...           |
  | `waiting` | `pending` (faded)   | Waiting to run ... / Aguardando ... |
  | `done`    | plain               | Ran ... / Rodou ...                 |
  | `error`   | `error` (red)       | Failed to run ... / Falhou ao rodar ... |
  | `denied`  | plain               | Denied ... / Negado ...             |

  `verbs` overrides them per state (`verbs={%{done: "Read", running: "Reading"}}`) and `title`
  replaces the whole title. `subject` is drawn as code.

  `variant="panel"` draws the call as a panel (tool icon, title, state badge or spinner) instead
  of a line of a trace; `input` / `output` are only shown by the `line` variant.
  """
  use LedgerUI.Component

  import LedgerUI.Components.Trace
  import LedgerUI.Components.CodeBlock

  @verbs %{
    "en" => %{
      "running" => "Running",
      "waiting" => "Waiting to run",
      "done" => "Ran",
      "error" => "Failed to run",
      "denied" => "Denied"
    },
    "pt_BR" => %{
      "running" => "Rodando",
      "waiting" => "Aguardando",
      "done" => "Rodou",
      "error" => "Falhou ao rodar",
      "denied" => "Negado"
    }
  }

  @line_status %{"running" => "running", "waiting" => "pending", "error" => "error"}
  @tones %{"running" => "acc", "waiting" => "warn", "done" => "pos", "error" => "neg"}
  @verb_keys [
    running: "running",
    waiting: "waiting",
    done: "done",
    error: "error",
    denied: "denied"
  ]

  attr :id, :string, required: true, doc: "Names the output block."
  attr :state, :string, default: "done", values: ~w(running waiting done error denied)
  attr :subject, :string, default: nil, doc: "What the tool acted on, drawn as code."
  attr :title, :string, default: nil, doc: "The whole title, in place of verb and subject."
  attr :verbs, :map, default: %{}, doc: "Verbs per state (atom keys), over the `locale` ones."
  attr :locale, :string, default: "en", values: ~w(en pt_BR)
  attr :icon, :string, default: "terminal"
  attr :description, :any, default: nil
  attr :input, :string, default: nil
  attr :output, :string, default: nil
  attr :open, :boolean, default: false
  attr :variant, :string, default: "line", values: ~w(line panel)

  attr :indicator, :string,
    default: "badge",
    values: ~w(badge ring),
    doc: "`panel` only: the state badge, or a spinner while `running`."

  attr :class, :any, default: nil
  attr :rest, :global

  @doc "One tool call, as a line of a `trace/1` (or a panel)."
  def tool(%{variant: "panel"} = assigns) do
    {style, rest} = Map.pop(assigns.rest, :style)
    pad = if assigns.description, do: "12px 14px", else: "10px 14px"

    assigns =
      assigns
      |> assign(:text, assigns.title || title_text(assigns))
      |> assign(:tone, @tones[assigns.state])
      |> assign(
        :style,
        merge_style("padding:#{pad};display:flex;gap:12px;align-items:center", style)
      )
      |> assign(:rest, rest)

    ~H"""
    <div id={@id} data-part="tool" class={cx(["lu-panel", @class])} style={@style} {@rest}>
      <span class={cx(["lu-ic", @tone])}><.icon name={@icon} size="md" /></span>
      <div :if={@description} class="lu-col lu-grow" style="gap:2px">
        <b class="lu-small">{@text}</b>
        <span class="lu-xs lu-muted">{@description}</span>
      </div>
      <b :if={!@description} class="lu-small lu-grow">{@text}</b>
      <span :if={@indicator == "ring" and @state == "running"} class="lu-ring2"></span>
      <span :if={@indicator == "badge" or @state != "running"} class={cx(["lu-badge", @tone])}>
        <span class="lu-dot"></span>{@state}
      </span>
    </div>
    """
  end

  def tool(assigns) do
    assigns =
      assigns
      |> assign(:status, @line_status[assigns.state])
      |> assign(:verb, verb(assigns))
      |> assign(:body?, assigns.input != nil or assigns.output != nil)
      |> assign(:block_variant, if(assigns.state == "error", do: "destructive", else: "default"))

    ~H"""
    <%= if @body? do %>
      <.trace_step
        id={@id}
        icon={@icon}
        description={@description}
        status={@status}
        open={@open}
        class={@class}
        {@rest}
      >
        <:summary>{@title || @verb}{" "}<code :if={!@title and @subject}>{@subject}</code></:summary>
        <.code_block
          :if={@input}
          id={"#{@id}-input"}
          code={@input}
          size="sm"
          wrap
          max_height={256}
        />
        <.code_block
          :if={@output}
          id={"#{@id}-output"}
          code={@output}
          size="sm"
          wrap
          max_height={256}
          variant={@block_variant}
          style={@input && "margin-top:8px"}
        />
      </.trace_step>
    <% else %>
      <.trace_line
        id={@id}
        icon={@icon}
        description={@description}
        status={@status}
        class={@class}
        {@rest}
      >
        {@title || @verb}{" "}<code :if={!@title and @subject}>{@subject}</code>
      </.trace_line>
    <% end %>
    """
  end

  attr :id, :string, required: true
  attr :subject, :string, default: nil, doc: "What would run, drawn as code in the question."
  attr :title, :string, default: nil, doc: ~s(The question, in place of "Run `subject`?".)
  attr :description, :string, default: nil
  attr :input, :string, default: nil
  attr :icon, :string, default: "terminal"
  attr :value, :any, default: nil, doc: "Sent with both events."
  attr :on_approve, :any, default: nil
  attr :on_deny, :any, default: nil
  attr :target, :any, default: nil
  attr :approve_label, :string, default: nil
  attr :deny_label, :string, default: nil
  attr :locale, :string, default: "en", values: ~w(en pt_BR)
  attr :class, :any, default: nil
  attr :rest, :global

  @doc "A tool call that waits for the user: the question, the input and Deny / Approve."
  def tool_approval(assigns) do
    {run, approve, deny} =
      case assigns.locale do
        "pt_BR" -> {"Rodar", "Aprovar", "Negar"}
        _ -> {"Run", "Approve", "Deny"}
      end

    assigns =
      assigns
      |> assign(:run, run)
      |> assign(:approve, assigns.approve_label || approve)
      |> assign(:deny, assigns.deny_label || deny)

    ~H"""
    <div
      id={@id}
      data-part="tool-approval"
      class={cx(["lu-panel", @class])}
      style="padding:12px 14px;display:flex;flex-direction:column;gap:10px"
      {@rest}
    >
      <div class="lu-row" style="flex-wrap:nowrap">
        <span class="lu-ic warn"><.icon name={@icon} size="md" /></span>
        <span class="lu-col lu-grow" style="gap:2px">
          <b class="lu-small">
            <%= if @title do %>
              {@title}
            <% else %>
              {@run} <code>{@subject}</code>?
            <% end %>
          </b>
          <span :if={@description} class="lu-xs lu-muted">{@description}</span>
        </span>
      </div>
      <.code_block :if={@input} id={"#{@id}-input"} code={@input} size="sm" wrap max_height={256} />
      <div class="lu-row" style="justify-content:flex-end">
        <button
          type="button"
          class="lu-btn ghost sm"
          phx-click={@on_deny}
          phx-value-value={@value}
          phx-target={@target}
        >
          {@deny}
        </button>
        <button
          type="button"
          class="lu-btn primary sm"
          phx-click={@on_approve}
          phx-value-value={@value}
          phx-target={@target}
        >
          <.icon name="check" />{@approve}
        </button>
      </div>
    </div>
    """
  end

  defp merge_style(base, extra),
    do: [base, extra] |> Enum.reject(&(&1 in [nil, ""])) |> Enum.join(";")

  # The verb of the state: `verbs` (atom keys) over the locale ones.
  defp verb(%{state: state, verbs: verbs, locale: locale}) do
    atom = Enum.find_value(@verb_keys, fn {atom, name} -> name == state && atom end)
    verbs[atom] || verbs[state] || @verbs[locale][state]
  end

  defp title_text(assigns) do
    case assigns.subject do
      nil -> verb(assigns)
      subject -> "#{verb(assigns)} #{subject}"
    end
  end
end
