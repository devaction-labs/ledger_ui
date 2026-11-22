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

  import LedgerUI.Components.Badge, only: [badge: 1]
  import LedgerUI.Components.Button, only: [button: 1]
  import LedgerUI.Components.Trace
  import LedgerUI.Components.CodeBlock

  @line_status %{"running" => "running", "waiting" => "pending", "error" => "error"}
  @tones %{"running" => "acc", "waiting" => "warn", "done" => "pos", "error" => "neg"}
  @badge_colors %{
    "running" => "primary",
    "waiting" => "warning",
    "done" => "success",
    "error" => "error",
    "denied" => "neutral"
  }
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

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

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
    assigns =
      assigns
      |> assign(:text, assigns.title || title_text(assigns))
      |> assign(:tone, @tones[assigns.state])
      |> assign(:badge_color, @badge_colors[assigns.state])
      |> assign(:pad, if(assigns.description, do: "py-3", else: "py-2.5"))

    ~H"""
    <div
      id={@id}
      data-part="tool"
      class={["flex items-center gap-3 rounded-lg border border-line bg-panel px-3.5", @pad, @class]}
      {@rest}
    >
      <.icon name={@icon} size="md" boxed tone={@tone} />
      <div :if={@description} data-part="tool-text" class="flex min-w-0 flex-1 flex-col gap-0.5">
        <b data-part="tool-title" class="text-[13px] leading-[18px]">{@text}</b>
        <span data-part="tool-description" class="text-xs leading-4 text-muted">{@description}</span>
      </div>
      <b :if={!@description} data-part="tool-title" class="min-w-0 flex-1 text-[13px] leading-[18px]">
        {@text}
      </b>
      <span
        :if={@indicator == "ring" and @state == "running"}
        data-part="tool-ring"
        class="size-5 flex-none animate-[lu-spin_.9s_linear_infinite] rounded-full border-2 border-accent-500 border-r-transparent"
      ></span>
      <.badge :if={@indicator == "badge" or @state != "running"} canvas color={@badge_color} dot>
        {@state}
      </.badge>
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
          locale={@locale}
          id={"#{@id}-input"}
          code={@input}
          size="sm"
          wrap
          max_height={256}
        />
        <.code_block
          :if={@output}
          locale={@locale}
          id={"#{@id}-output"}
          code={@output}
          size="sm"
          wrap
          max_height={256}
          variant={@block_variant}
          class={@input && "mt-2"}
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

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  attr :class, :any, default: nil
  attr :rest, :global

  @doc "A tool call that waits for the user: the question, the input and Deny / Approve."
  def tool_approval(assigns) do
    run = I18n.t("tool.run", assigns.locale)
    approve = I18n.t("tool.approve", assigns.locale)
    deny = I18n.t("tool.deny", assigns.locale)

    assigns =
      assigns
      |> assign(:run, run)
      |> assign(:approve, assigns.approve_label || approve)
      |> assign(:deny, assigns.deny_label || deny)

    ~H"""
    <div
      id={@id}
      data-part="tool-approval"
      class={[
        "flex flex-col gap-2.5 rounded-lg border border-line bg-panel px-3.5 py-3",
        @class
      ]}
      {@rest}
    >
      <div data-part="tool-approval-head" class="flex flex-nowrap items-center gap-2.5">
        <.icon name={@icon} size="md" boxed tone="warn" />
        <span data-part="tool-approval-text" class="flex min-w-0 flex-1 flex-col gap-0.5">
          <b data-part="tool-approval-title" class="text-[13px] leading-[18px]">
            <%= if @title do %>
              {@title}
            <% else %>
              {@run} <code>{@subject}</code>?
            <% end %>
          </b>
          <span
            :if={@description}
            data-part="tool-approval-description"
            class="text-xs leading-4 text-muted"
          >
            {@description}
          </span>
        </span>
      </div>
      <.code_block
        :if={@input}
        id={"#{@id}-input"}
        code={@input}
        size="sm"
        wrap
        max_height={256}
        locale={@locale}
      />
      <div data-part="tool-approval-actions" class="flex flex-wrap items-center justify-end gap-2.5">
        <.button
          canvas
          size="sm"
          appearance="ghost"
          phx-click={@on_deny}
          phx-value-value={@value}
          phx-target={@target}
        >
          {@deny}
        </.button>
        <.button
          canvas
          size="sm"
          appearance="primary"
          phx-click={@on_approve}
          phx-value-value={@value}
          phx-target={@target}
        >
          <.icon name="check" />{@approve}
        </.button>
      </div>
    </div>
    """
  end

  # The verb of the state: `verbs` (atom keys) over the locale ones.
  defp verb(%{state: state, verbs: verbs, locale: locale}) do
    atom = Enum.find_value(@verb_keys, fn {atom, name} -> name == state && atom end)
    verbs[atom] || verbs[state] || I18n.t("tool.verb.#{state}", locale)
  end

  defp title_text(assigns) do
    case assigns.subject do
      nil -> verb(assigns)
      subject -> "#{verb(assigns)} #{subject}"
    end
  end
end
