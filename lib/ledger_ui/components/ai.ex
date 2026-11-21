defmodule LedgerUI.Components.Ai do
  @moduledoc """
  The assistant ("Assistente (IA)"): the conversation, its messages, the proposals the user
  approves, the queries the assistant shows it made, the field to ask, the list of conversations
  and the starting suggestions. The assistant proposes and the user approves; nothing changes
  without a confirmation.

      <.ai_chat id="assistente" messages={@messages} user={@current_user}
        on_send="send" on_approve="approve" on_reject="reject" />

  Or piece by piece (`ai_message/1`, `ai_proposal/1`, `ai_tool_trace/1`, `ai_composer/1`,
  `conversation_list/1`, `prompt_suggestions/1`, `ai_insights/1`, `ai_promo/1`, `ai_greeting/1`).

  A message of `ai_chat` is a map: `:id`, `:role` (`:user` or `:assistant`), `:text` (paragraphs
  separated by a blank line, `**bold**` is bold), `:name` (of the user, for the avatar), `:trace`
  (`%{tools: [...], duration_ms: 3000, running: false}`), `:proposal` (`%{id:, title:, status:,
  changes: [%{label:, from:, to:, text:}], note:, editable:}`), `:streaming` and `:status`.
  `messages` can be a list or a LiveView stream (`stream(socket, :messages, ...)`).

  The composer is a form: Enter sends, Shift+Enter breaks the line (hook `LedgerUI.AiComposer`,
  file `priv/static/ledger_ui/hooks/ai_composer.js`). With `streaming` the form gets `data-lu-streaming` and
  Enter does not send until the answer is over (the stop button replaces send; Shift+Enter still breaks the line).
  """
  use LedgerUI.Component

  import LedgerUI.Components.Aura, only: [aura: 1]
  import LedgerUI.Components.Avatar, only: [avatar: 1]
  import LedgerUI.Components.Badge, only: [badge: 1]
  import LedgerUI.Components.Button, only: [button: 1, icon_button: 1]
  import LedgerUI.Components.Input, only: [input: 1]
  import LedgerUI.Components.Typography, only: [kbd: 1]

  alias LedgerUI.Components.Button
  alias Phoenix.LiveView.LiveStream

  @default_placeholder "Pergunte sobre pedidos, estoque, fiscal ou financeiro"

  # {badge colour, label}: the label is the default of the status
  @status_badges %{
    "pending" => {"warning", nil},
    "applying" => {"primary", "Aplicando"},
    "approved" => {"success", "Aprovado"},
    "rejected" => {"neutral", "Recusado"},
    "failed" => {"error", "Falhou"}
  }

  # the old tone names of an impact badge (`neg`, `pos`, ...) and the canvas colours
  @tones %{
    "acc" => "primary",
    "pos" => "success",
    "neg" => "error",
    "warn" => "warning",
    "info" => "info",
    "lime" => "lime",
    "primary" => "primary",
    "success" => "success",
    "error" => "error",
    "warning" => "warning"
  }

  @context_known %{
    "pedidos" => {"Pedidos", "invoice"},
    "catalogo" => {"Catálogo", "package"},
    "clientes" => {"Clientes", "users"},
    "financeiro" => {"Financeiro", "wallet"},
    "fiscal" => {"Fiscal", "file"},
    "banco" => {"Banco", "bank"}
  }

  # shared looks (the tray card of the proposal and the insights, the panel, the chip)
  @tray "flex min-w-0 flex-col rounded-xl border border-line bg-tray p-1.5"
  @tray_header "flex min-h-11 items-center gap-2.5 pt-2 pr-2.5 pb-2.5 pl-3.5"
  @tray_heading "m-0 inline-flex items-center gap-2 font-display text-xs leading-4 font-medium tracking-[.08em] text-ink-2 uppercase"
  @tray_body "relative min-w-0 flex-1 rounded-lg border border-line bg-panel p-4"
  @tray_footer "flex items-center gap-2 pt-2.5 pr-3 pb-1.5 pl-3.5 text-[13px] text-muted"
  @panel "rounded-lg border border-line bg-panel"
  @chip "inline-flex h-7 cursor-pointer items-center gap-1.5 rounded-md border border-line-strong bg-panel px-[11px] text-[13px] font-medium text-ink-2 hover:bg-hover"

  # -- helpers -----------------------------------------------------------------

  defp esc(text), do: text |> Phoenix.HTML.html_escape() |> elem(1)

  # `**bold**` -> <tag>bold</tag>; everything else is escaped.
  defp inline_md(text, tag, class, part \\ nil)
  defp inline_md(nil, _tag, _class, _part), do: ""

  defp inline_md(text, tag, class, part) do
    iodata =
      ~r/\*\*(.+?)\*\*/
      |> Regex.split(to_string(text), include_captures: true)
      |> Enum.map(fn
        "**" <> rest = piece ->
          if String.ends_with?(rest, "**") and byte_size(rest) > 2,
            do: [
              "<",
              tag,
              if(part, do: [~s( data-part="), part, ~s(")], else: ""),
              if(class, do: [~s( class="), class, ~s(")], else: ""),
              ">",
              esc(binary_part(rest, 0, byte_size(rest) - 2)),
              "</",
              tag,
              ">"
            ],
            else: esc(piece)

        piece ->
          esc(piece)
      end)

    # every piece of `iodata` is escaped above
    {:safe, iodata}
  end

  # `style={nil}` would render `style=""`: pass the attribute through a map instead.
  defp sa(style) when style in [nil, false, ""], do: %{}
  defp sa(style), do: %{style: style}

  defp key(value) when is_atom(value) and not is_nil(value), do: Atom.to_string(value)
  defp key(value), do: value

  defp initials(nil), do: nil

  defp initials(name) do
    name
    |> to_string()
    |> String.split(~r/\s+/, trim: true)
    |> Enum.map(&String.first/1)
    |> then(fn
      [] -> []
      [one] -> [one]
      list -> [hd(list), List.last(list)]
    end)
    |> Enum.join()
    |> String.upcase()
  end

  defp seconds(nil), do: nil
  defp seconds(ms) when rem(ms, 1000) == 0, do: "#{div(ms, 1000)}s"
  defp seconds(ms), do: "#{Float.round(ms / 1000, 1)}s"

  defp prop_status(status), do: key(status) |> to_string()

  defp tone(nil), do: "neutral"
  defp tone(name), do: @tones[to_string(name)] || "neutral"

  # -- ai_insights -------------------------------------------------------------

  attr :insights, :list,
    required: true,
    doc:
      "Maps `%{icon, title, text, impact, tone, action, href, navigate, patch, style}`; `**bold**` in `text` is bold."

  attr :variant, :string,
    default: "card",
    values: ~w(card list),
    doc: "`card` has the header; `list` is the items only."

  attr :title, :string, default: "AI insights"
  attr :count, :integer, default: nil, doc: "Number of new insights, as a badge in the header."
  attr :count_label, :string, default: "new"

  attr :on_chat, :any,
    default: nil,
    doc: "Shows the chat button in the header; an event name or a `JS` command."

  attr :chat_label, :string, default: "Abrir chat"
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  @doc "Card of AI insights: icon, title, sentence with bold numbers, impact badge and action."
  def ai_insights(%{variant: "list"} = assigns) do
    ~H"""
    <div data-part="ai-insights" class={@class} {@rest}>
      <.insight_item :for={insight <- @insights} insight={insight} />
    </div>
    """
  end

  def ai_insights(assigns) do
    assigns =
      assign(assigns,
        tray: @tray,
        header: @tray_header,
        heading: @tray_heading,
        body: @tray_body
      )

    ~H"""
    <section data-part="ai-insights" class={[@tray, @class]} {@rest}>
      <header data-part="ai-insights-header" class={@header}>
        <h3 data-part="ai-insights-title" class={@heading}>
          {@title}
          <.badge :if={@count} canvas color="lime">
            <.icon name="huge-sparkles" />{@count} {@count_label}
          </.badge>
        </h3>
        <div :if={@on_chat} data-part="ai-insights-actions" class="ml-auto flex items-center gap-1.5">
          <.icon_button
            icon="huge-message"
            label={@chat_label}
            size="sm"
            phx-click={@on_chat}
            phx-target={@target}
          />
        </div>
      </header>
      <div data-part="ai-insights-body" class={@body}>
        <div>
          <.insight_item :for={insight <- @insights} insight={insight} />
        </div>
      </div>
    </section>
    """
  end

  attr :insight, :map, required: true

  defp insight_item(assigns) do
    i = assigns.insight

    assigns =
      assign(assigns,
        i: i,
        text: inline_md(i[:text], "strong", "font-semibold text-ink", "ai-insight-strong"),
        has_footer: i[:impact] != nil or i[:action] != nil
      )

    ~H"""
    <div
      data-part="ai-insight"
      class="flex gap-3 border-t border-line px-1 py-3.5 first:border-t-0 first:pt-1"
      {sa(@i[:style])}
    >
      <.icon :if={@i[:icon]} name={@i[:icon]} class="mt-0.5 text-ink-2" />
      <div data-part="ai-insight-body" class="flex min-w-0 flex-1 flex-col gap-[3px]">
        <b data-part="ai-insight-title" class="text-[15px] font-semibold">{@i[:title]}</b>
        <p data-part="ai-insight-text" class="m-0 text-sm leading-5 text-muted">{@text}</p>
        <div
          :if={@has_footer}
          data-part="ai-insight-footer"
          class="mt-2 flex items-center justify-between gap-2"
        >
          <.badge :if={@i[:impact]} canvas color={tone(@i[:tone])}>{@i[:impact]}</.badge>
          <a
            :if={@i[:action]}
            data-part="ai-insight-action"
            class="inline-flex cursor-pointer items-center gap-1.5 px-2.5 text-[13px] leading-none font-medium whitespace-nowrap text-accent-content no-underline underline-offset-[3px] hover:underline"
            href={@i[:href] || "#"}
            data-phx-link={@i[:navigate] && "redirect"}
          >
            {@i[:action]} <.icon name="huge-arrow-right" size="md" />
          </a>
        </div>
      </div>
    </div>
    """
  end

  # -- ai_promo ----------------------------------------------------------------

  attr :title, :string, default: "Assistente"
  attr :count, :integer, default: nil, doc: "Number of new suggestions/insights."
  attr :subtitle, :string, default: nil, doc: "Replaces the default \"N novas sugestões\"."
  attr :text, :string, default: nil, doc: "A sentence under the title (card variant)."
  attr :action, :string, default: nil, doc: "Label of the main action button (card variant)."
  attr :variant, :string, default: "card", values: ~w(card rail)
  attr :tone, :string, default: "brand", values: ~w(brand warm)

  attr :on_click, :any,
    default: nil,
    doc: "Event name or `JS` command of the call (the action for `card`)."

  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  # the glow in the corner of the call
  @promo "relative flex flex-col gap-2.5 overflow-hidden rounded-[16px] border border-line bg-panel p-3.5 " <>
           "after:pointer-events-none after:absolute after:-top-10 after:-right-10 after:size-[140px] after:rounded-full after:opacity-80 after:content-[''] " <>
           "after:bg-[radial-gradient(circle,var(--lu-accent-100),transparent_70%)]"

  @doc "Call to the assistant pinned on the sidebar, with insight count and main action."
  def ai_promo(%{variant: "rail"} = assigns) do
    assigns =
      assigns
      |> assign(:sub, promo_subtitle(assigns))
      |> assign(:aura, if(assigns.tone == "warm", do: "warn", else: "ai"))
      |> assign(:promo, @promo)

    ~H"""
    <.aura
      data-part="ai-promo"
      tone={@aura}
      class={@class}
      style="width:100%"
      {@rest}
    >
      <div
        data-part="ai-promo-call"
        class={[@promo, "m-0"]}
        role={@on_click && "button"}
        tabindex={@on_click && "0"}
        phx-click={@on_click}
        phx-target={@target}
      >
        <.icon name="huge-sparkles" size="md" />
        <b>{@title}</b><span :if={@sub} data-part="ai-promo-sub" class="text-xs leading-4 text-muted">{@sub}</span>
      </div>
    </.aura>
    """
  end

  def ai_promo(assigns) do
    assigns = assign(assigns, sub: promo_subtitle(assigns), promo: @promo)

    ~H"""
    <div data-part="ai-promo" class={[@promo, @class]} {@rest}>
      <div data-part="ai-promo-row" class="flex flex-nowrap items-center gap-2.5">
        <span
          data-part="ai-promo-icon"
          class="grid size-9 flex-none place-items-center rounded-[10px] bg-lime-soft text-lime"
        >
          <.icon name="huge-sparkles" size="md" />
        </span>
        <span data-part="ai-promo-titles" class="flex flex-col gap-0">
          <b>{@title}</b>
          <span :if={@sub} data-part="ai-promo-sub" class="text-xs leading-4 text-muted">{@sub}</span>
        </span>
      </div>
      <span :if={@text} data-part="ai-promo-text" class="text-[13px] leading-[18px] text-ink-2">
        {@text}
      </span>
      <.button
        :if={@action}
        canvas
        appearance="primary"
        class="w-full"
        phx-click={@on_click}
        phx-target={@target}
      >
        <span data-part="ai-promo-action" class="flex flex-1 items-center gap-2">
          <span
            data-part="ai-promo-lead"
            class="-ml-2 grid size-[26px] place-items-center rounded-[7px] bg-on-inverse text-inverse"
          >
            <.icon name="huge-sparkles" size="sm" />
          </span>{@action}
        </span><.icon name="huge-arrow-right" size="sm" />
      </.button>
    </div>
    """
  end

  defp promo_subtitle(%{subtitle: sub}) when is_binary(sub), do: sub
  defp promo_subtitle(%{count: count}) when is_integer(count), do: "#{count} novas sugestões"
  defp promo_subtitle(_), do: nil

  # -- ai_greeting -------------------------------------------------------------

  attr :name, :string,
    default: nil,
    doc: "Who is greeted; `Bom dia` / `Boa tarde` / `Boa noite` by the hour."

  attr :greeting, :string, default: nil, doc: "Replaces the whole first line."
  attr :tagline, :string, default: "Em que posso ajudar hoje?"
  attr :size, :string, default: "lg", values: ~w(sm md lg)
  attr :tone, :string, default: "brand", values: ~w(brand warm)
  attr :class, :any, default: nil
  attr :rest, :global

  # first line and tagline: the lines rise in when they appear (`starting:`), the second a beat later
  @greeting_sizes %{
    "sm" => {"text-[30px]", "text-[22px]"},
    "md" => {"text-[36px]", "text-[28px]"},
    "lg" => {"text-[40px]", "text-[32px]"}
  }

  @greeting_tones %{
    "brand" => "bg-[linear-gradient(90deg,var(--lu-accent),var(--lu-info),#8b5cf6,#ec4899)]",
    "warm" => "bg-[linear-gradient(90deg,#ec4899,#f43f5e,#f97316,#d946ef)]"
  }

  @doc "The greeting of the assistant: the first line in a gradient and the question under it."
  def ai_greeting(assigns) do
    {line_size, tag_size} = @greeting_sizes[assigns.size]

    assigns =
      assigns
      |> assign(:line, greeting_line(assigns))
      |> assign(:gradient, @greeting_tones[assigns.tone])
      |> assign(:line_size, line_size)
      |> assign(:tag_size, tag_size)

    ~H"""
    <div data-part="ai-greeting" class={["flex flex-col gap-1", @class]} {@rest}>
      <b
        data-part="ai-greeting-line"
        class={[
          "w-fit bg-clip-text leading-[1.15] tracking-[-.02em] text-transparent",
          "transition-[opacity,translate] duration-500 ease-[cubic-bezier(.2,.7,.2,1)] starting:translate-y-2 starting:opacity-0 motion-reduce:transition-none",
          @line_size,
          @gradient
        ]}
      >
        {@line}
      </b>
      <span
        data-part="ai-greeting-tagline"
        class={[
          "leading-[1.2] text-muted",
          "transition-[opacity,translate] delay-[120ms] duration-500 ease-[cubic-bezier(.2,.7,.2,1)] starting:translate-y-2 starting:opacity-0 motion-reduce:transition-none",
          @tag_size
        ]}
      >
        {@tagline}
      </span>
    </div>
    """
  end

  defp greeting_line(%{greeting: greeting}) when is_binary(greeting), do: greeting

  defp greeting_line(%{name: name}) do
    hello = greeting_for_hour(Time.utc_now().hour)
    if name, do: "#{hello}, #{name}", else: hello
  end

  defp greeting_for_hour(hour) when hour < 12, do: "Bom dia"
  defp greeting_for_hour(hour) when hour < 18, do: "Boa tarde"
  defp greeting_for_hour(_), do: "Boa noite"

  # -- ai_tool_trace -----------------------------------------------------------

  attr :tools, :list,
    default: [],
    doc: "Maps `%{label, title, detail, ms, icon, failed, running}`."

  attr :steps, :list, default: [], doc: "The same as `tools`."
  attr :running, :boolean, default: false, doc: "The queries are still going on."
  attr :expanded, :boolean, default: false, doc: "Opens the list of queries."
  attr :duration_ms, :integer, default: nil, doc: "The total time, shown in seconds."

  attr :loop, :boolean,
    default: false,
    doc:
      "The canvas loop: each query runs (a spinner) and ends (a check), one after the other, forever."

  attr :variant, :string,
    default: "default",
    values: ~w(default bare),
    doc:
      "`bare` leaves the summary header out: just the rows, without the first row's top border."

  attr :summary, :boolean,
    default: true,
    doc:
      "Shows the `<summary>` header (count and time). `false` is the same as `variant=\"bare\"`: the box is then a `div` that is always open."

  attr :class, :any, default: nil
  attr :rest, :global

  @doc "What the assistant consulted: summary (count and time) and one row per query."
  def ai_tool_trace(assigns) do
    tools = assigns.tools ++ assigns.steps

    assigns =
      assigns
      |> assign(:tools, Enum.with_index(tools))
      |> assign(:show_summary, assigns.summary and assigns.variant != "bare")
      |> assign(
        :open_attr,
        if(assigns.summary and assigns.variant != "bare" and assigns.expanded,
          do: [open: true],
          else: []
        )
      )
      |> assign(:count, length(tools))
      |> assign(:total, seconds(assigns.duration_ms))

    ~H"""
    <.dynamic_tag
      tag_name={if @show_summary, do: "details", else: "div"}
      data-part="ai-tool-trace"
      class={["rounded-lg border border-line bg-panel text-[13.5px]", @class]}
      {@open_attr}
      {@rest}
    >
      <summary
        :if={@show_summary}
        data-part="ai-tool-trace-summary"
        class="flex cursor-pointer list-none flex-wrap items-center gap-2.5 border-b border-line px-3 py-[9px]"
      >
        <.icon name="huge-tool" size="md" class="text-muted" />
        <span data-part="ai-tool-trace-title" class="text-[13px] leading-[18px]">
          {tool_summary(@count, @running)}
        </span>
        <span data-part="ai-tool-trace-spacer" class="min-w-0 flex-1"></span>
        <span
          :if={@total}
          data-part="ai-tool-trace-total"
          class="font-mono text-xs leading-4 text-muted"
        >
          {@total}
        </span>
      </summary>
      <div
        :for={{tool, index} <- @tools}
        data-part="ai-tool-trace-row"
        class={[
          "flex items-center gap-2.5 border-line px-3 py-[9px]",
          if(index == 0 and !@show_summary, do: "border-t-0", else: "border-t"),
          tool[:failed] && "text-neg",
          @loop && "animate-[mo-runrow_6s_var(--dl)_infinite]"
        ]}
        {sa(@loop && "--dl:#{Float.round(index * 1.1, 1)}s")}
      >
        <span
          :if={@loop}
          data-part="ai-tool-trace-status"
          class="relative grid size-4 flex-none place-items-center"
        >
          <span
            data-part="ai-tool-trace-run"
            class="absolute size-3.5 animate-[lu-spin_.8s_linear_infinite,mo-rnout_6s_var(--dl)_infinite] rounded-full border-2 border-accent-500 border-r-transparent"
          ></span>
          <span
            data-part="ai-tool-trace-ok"
            class="text-pos opacity-0 animate-[mo-okin_6s_var(--dl)_infinite]"
          >
            <.icon name="huge-check-circle" size="sm" />
          </span>
        </span>
        <.icon :if={!@loop} name={tool_icon(tool)} size="md" />
        <span data-part="ai-tool-trace-name" class="font-mono text-[12.5px] text-ink">
          {tool[:title] || tool[:label]}
        </span>
        <span data-part="ai-tool-trace-detail" class="text-xs leading-4 text-muted">{tool[:detail]}</span>
        <span data-part="ai-tool-trace-ms" class="ml-auto font-mono text-xs text-muted">{tool[:ms]}</span>
      </div>
    </.dynamic_tag>
    """
  end

  defp tool_icon(%{failed: true}), do: "huge-warn-circle"
  defp tool_icon(%{running: true}), do: "huge-refresh"
  defp tool_icon(_), do: "huge-check-circle"

  defp tool_summary(_count, true), do: "Em andamento"
  defp tool_summary(1, _), do: "Usou 1 ferramenta"
  defp tool_summary(count, _), do: "Usou #{count} ferramentas"

  # -- ai_message --------------------------------------------------------------

  attr :role, :string, default: "assistant", values: ~w(user assistant)

  attr :variant, :string,
    default: "card",
    values: ~w(card plain),
    doc: "`card` frames the assistant's content; `plain` is loose text beside the spark."

  attr :streaming, :boolean,
    default: false,
    doc: "Shows the blinking cursor after the last paragraph."

  attr :thinking, :boolean,
    default: false,
    doc: "Three bouncing dots in place of the content (the assistant has not started to write)."

  attr :status, :string, default: "ok", values: ~w(ok error)
  attr :name, :string, default: nil, doc: "The user's name: its initials make the avatar."

  attr :actions, :list,
    default: [],
    doc: "Buttons under the content: `copy`, `useful`, `useless`, `regenerate`."

  attr :on_action, :any, default: nil, doc: "Event name (payload `%{action}`) or `JS` command."
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block
  slot :trace, doc: "The queries the assistant made, above the content."

  @actions %{
    "copy" => {"Copiar", "huge-copy"},
    "useful" => {"Útil", "huge-thumb-up"},
    "useless" => {"Não útil", "huge-thumb-down"},
    "regenerate" => {"Gerar de novo", "huge-refresh"}
  }

  # The blinking cursor: after the text being written. It follows the last paragraph (a `p` or a
  # `div` that is the last child); a content without them takes it on its own end.
  @cursor_last "[&>:is(p,div):last-child]:after:ml-0.5 [&>:is(p,div):last-child]:after:inline-block [&>:is(p,div):last-child]:after:h-[1.05em] [&>:is(p,div):last-child]:after:w-[.5em] [&>:is(p,div):last-child]:after:rounded-[1px] [&>:is(p,div):last-child]:after:bg-accent-500 [&>:is(p,div):last-child]:after:align-text-bottom [&>:is(p,div):last-child]:after:content-[''] [&>:is(p,div):last-child]:after:animate-[lu-caret_1s_steps(1)_infinite] motion-reduce:[&>:is(p,div):last-child]:after:animate-none"
  # the end of the block itself, only when its last child is not a `p` or a `div`
  @cursor_end "not-has-[>p:last-child]:not-has-[>div:last-child]:after:ml-0.5 " <>
                "not-has-[>p:last-child]:not-has-[>div:last-child]:after:inline-block " <>
                "not-has-[>p:last-child]:not-has-[>div:last-child]:after:h-[1.05em] not-has-[>p:last-child]:not-has-[>div:last-child]:after:w-[.5em] " <>
                "not-has-[>p:last-child]:not-has-[>div:last-child]:after:rounded-[1px] not-has-[>p:last-child]:not-has-[>div:last-child]:after:bg-accent-500 " <>
                "not-has-[>p:last-child]:not-has-[>div:last-child]:after:align-text-bottom not-has-[>p:last-child]:not-has-[>div:last-child]:after:content-[''] " <>
                "not-has-[>p:last-child]:not-has-[>div:last-child]:after:animate-[lu-caret_1s_steps(1)_infinite]"

  @doc "A message of the conversation."
  def ai_message(%{role: "user"} = assigns) do
    assigns = assign(assigns, :initials, initials(assigns.name))

    ~H"""
    <div
      data-part="ai-message"
      class={["ml-auto flex max-w-[620px] flex-row-reverse items-start gap-2.5", @class]}
      {@rest}
    >
      <.avatar
        :if={@initials}
        initials={@initials}
        size="30"
        shape="squircle"
        color="neutral"
        variant="soft"
      />
      <div
        data-part="ai-message-bubble"
        class="rounded-[14px_14px_4px_14px] bg-inverse px-3.5 py-2.5 text-[14.5px] leading-[22px] text-on-inverse"
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  def ai_message(assigns) do
    assigns =
      assigns
      |> assign(:action_list, for(a <- assigns.actions, do: {key(a), @actions[key(a)]}))
      |> assign(:panel, @panel)
      |> assign(:cursor_last, @cursor_last)
      |> assign(:cursor_end, @cursor_end)

    ~H"""
    <div
      data-part="ai-message"
      class={["flex max-w-[620px] items-start gap-2.5", @class]}
      data-lu-status={@status == "error" && "error"}
      {@rest}
    >
      <span
        data-part="ai-message-spark"
        class="grid size-[30px] flex-none place-items-center rounded-[9px] bg-lime-soft text-lime"
      ><.icon name="huge-sparkles" size="md" /></span>
      <div
        data-part="ai-message-body"
        class="flex min-w-0 flex-col gap-2 text-[14.5px] leading-[22px]"
      >
        {render_slot(@trace)}
        <span :if={@thinking} data-part="ai-message-typing" class="mt-2.5 inline-flex w-fit gap-1">
          <i
            data-part="ai-message-dot"
            class="size-1.5 animate-[lu-bounce_1s_infinite] rounded-full bg-muted"
          ></i>
          <i
            data-part="ai-message-dot"
            class="size-1.5 animate-[lu-bounce_1s_.15s_infinite] rounded-full bg-muted"
          ></i>
          <i
            data-part="ai-message-dot"
            class="size-1.5 animate-[lu-bounce_1s_.3s_infinite] rounded-full bg-muted"
          ></i>
        </span>
        <div :if={!@thinking and @status == "error"} data-part="ai-message-error" class="text-neg">
          <.icon name="huge-warn-circle" size="sm" /> {render_slot(@inner_block)}
        </div>
        <div
          :if={!@thinking and @status != "error" and @variant == "card"}
          data-part="ai-message-content"
          class={[
            @panel,
            "px-3 py-2.5",
            @streaming && [@cursor_last, @cursor_end]
          ]}
        >
          {render_slot(@inner_block)}
        </div>
        <div
          :if={!@thinking and @status != "error" and @variant == "plain" and @streaming}
          data-part="ai-message-content"
          class={[@cursor_last, @cursor_end]}
        >
          {render_slot(@inner_block)}
        </div>
        {if !@thinking and @status != "error" and @variant == "plain" and not @streaming,
          do: render_slot(@inner_block)}
        <div :if={@action_list != []} data-part="ai-message-actions" class="flex gap-0.5 text-muted">
          <.icon_button
            :for={{action, {label, icon}} <- @action_list}
            icon={icon}
            label={label}
            variant="ghost"
            size="sm"
            phx-click={@on_action}
            phx-value-action={action}
            phx-target={@target}
          />
        </div>
      </div>
    </div>
    """
  end

  # -- ai_proposal -------------------------------------------------------------

  attr :id, :string, required: true
  attr :title, :string, required: true, doc: "What will be done."
  attr :heading, :string, default: "Proposta", doc: "Title of the card header."

  attr :status, :any,
    default: "pending",
    doc: "`pending`, `applying`, `approved`, `rejected` or `failed`, as an atom or a string."

  attr :pending_label, :string, default: "Aguardando você"
  attr :pending_note, :string, default: nil
  attr :layout, :string, default: "list", values: ~w(list definition table)

  attr :headers, :list,
    default: ["Regra", "Atual", "Proposto"],
    doc: "Column headers of the `table` layout."

  attr :editable, :boolean, default: false
  attr :note, :string, default: nil
  attr :on_approve, :any, default: nil
  attr :on_reject, :any, default: nil
  attr :on_undo, :any, default: nil
  attr :on_edit, :any, default: nil
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :action, doc: "A button in the footer of a failed proposal."

  slot :change, doc: "A row of the proposal." do
    attr :label, :string
    attr :from, :string
    attr :to, :string
  end

  slot :impact, doc: "The effect in numbers." do
    attr :label, :string
  end

  slot :preview, doc: "A preview of the message or document." do
    attr :label, :string
  end

  @th "border-b border-line px-3 py-[9px] text-left text-[11.5px] leading-4 font-medium tracking-[.07em] whitespace-nowrap text-muted uppercase"
  @td "border-b border-line px-3 py-2 whitespace-nowrap group-last/row:border-b-0"

  @doc "An action the assistant proposes, which only happens when the user approves."
  def ai_proposal(assigns) do
    status = prop_status(assigns.status)
    {color, label} = @status_badges[status] || @status_badges["pending"]

    assigns =
      assigns
      |> assign(:state, status)
      |> assign(:badge_color, color)
      |> assign(:badge_label, label || assigns.pending_label)
      |> assign(
        :footer?,
        status == "pending" or (status == "approved" and assigns.on_undo != nil) or
          (status == "failed" and assigns.action != [])
      )
      |> assign(
        tray: @tray,
        header: @tray_header,
        heading_class: @tray_heading,
        body: @tray_body,
        footer: @tray_footer,
        panel: @panel,
        th: @th,
        td: @td
      )

    ~H"""
    <section
      id={@id}
      data-part="ai-proposal"
      class={[@tray, @class]}
      data-lu-status={@state}
      {@rest}
    >
      <header data-part="ai-proposal-header" class={@header}>
        <h3 data-part="ai-proposal-title" class={@heading_class}>
          {@heading}
          <.badge canvas color={@badge_color}>{@badge_label}</.badge>
        </h3>
      </header>
      <div data-part="ai-proposal-body" class={@body}>
        <div data-part="ai-proposal-content" class="flex flex-col gap-3">
          <div data-part="ai-proposal-head" class="flex flex-wrap items-center gap-2.5">
            <.icon name="huge-sparkles" size="md" boxed tone="lime" />
            <b>{@title}</b>
          </div>
          <div
            :if={@change != [] and @layout == "table"}
            data-part="ai-proposal-table"
            class="overflow-auto rounded-lg border border-line bg-panel"
          >
            <table
              data-part="ai-proposal-grid"
              class="w-full border-separate border-spacing-0 text-sm"
            >
              <thead>
                <tr>
                  <th :for={h <- @headers} data-part="ai-proposal-th" class={@th}>{h}</th>
                </tr>
              </thead>
              <tbody>
                <tr :for={change <- @change} data-part="ai-proposal-row" class="group/row">
                  <td data-part="ai-proposal-td" class={[@td, "text-ink-2"]}>{change[:label]}</td>
                  <%= if change[:from] || change[:to] do %>
                    <td data-part="ai-proposal-td" class={[@td, "text-ink-2"]}>
                      <s data-part="ai-proposal-from" class="text-muted">{change[:from]}</s>
                    </td>
                    <td data-part="ai-proposal-td" class={[@td, "font-medium text-ink"]}>
                      {change[:to]}
                    </td>
                  <% else %>
                    <td data-part="ai-proposal-td" class={[@td, "font-medium text-ink"]} colspan="2">
                      {render_slot(change)}
                    </td>
                  <% end %>
                </tr>
              </tbody>
            </table>
          </div>
          <div
            :if={@change != [] and @layout != "table"}
            data-part="ai-proposal-changes"
            class="flex flex-col gap-1.5"
          >
            <div
              :for={change <- @change}
              data-part="ai-proposal-change"
              class="flex flex-wrap items-center gap-2"
            >
              <span
                data-part="ai-proposal-label"
                class="min-w-[84px] text-[13px] leading-[18px] text-muted"
              >
                {change[:label]}
              </span>
              <%= if change[:from] || change[:to] do %>
                <s data-part="ai-proposal-from" class="text-muted">{change[:from]}</s>
                <.icon :if={@layout == "list"} name="huge-arrow-right" size="sm" />
                <b :if={@layout == "list"} data-part="ai-proposal-to" class="text-pos">{change[:to]}</b>
                <.badge :if={@layout == "definition"} canvas color="success">{change[:to]}</.badge>
              <% else %>
                <span>{render_slot(change)}</span>
              <% end %>
            </div>
          </div>
          <div :for={preview <- @preview} data-part="ai-proposal-preview" class="flex flex-col gap-1">
            <span data-part="ai-proposal-label" class="text-xs leading-4 text-muted">
              {preview[:label] || "Mensagem"}
            </span>
            <div data-part="ai-proposal-preview-box" class={[@panel, "px-3 py-2.5"]}>
              {render_slot(preview)}
            </div>
          </div>
          <div
            :for={impact <- @impact}
            data-part="ai-proposal-impact"
            class="flex flex-wrap items-center gap-2.5"
          >
            <span
              :if={@layout != "table"}
              data-part="ai-proposal-label"
              class="text-xs leading-4 text-muted"
            >
              {impact[:label] || "Impacto"}
            </span>
            {render_slot(impact)}
          </div>
          <span
            :if={@note && @state != "pending"}
            data-part="ai-proposal-note"
            class="text-[13px] leading-[18px] text-muted"
          >
            {@note}
          </span>
        </div>
      </div>
      <div :if={@footer?} data-part="ai-proposal-footer" class={@footer}>
        <span
          :if={@pending_note && @state == "pending"}
          data-part="ai-proposal-pending-note"
          class="text-xs leading-4 text-muted"
        >
          {@pending_note}
        </span>
        <span data-part="ai-proposal-spacer" class="min-w-0 flex-1"></span>
        <%= if @state == "pending" do %>
          <.button
            canvas
            size="sm"
            appearance="ghost"
            phx-click={@on_reject}
            phx-value-id={@id}
            phx-target={@target}
          >
            Rejeitar
          </.button>
          <.button
            :if={@editable}
            canvas
            size="sm"
            phx-click={@on_edit}
            phx-value-id={@id}
            phx-target={@target}
          >
            <.icon name="huge-edit" />Editar
          </.button>
          <.button
            canvas
            size="sm"
            appearance="primary"
            phx-click={@on_approve}
            phx-value-id={@id}
            phx-target={@target}
          >
            <.icon name="huge-check" />Aprovar
          </.button>
        <% end %>
        <.button
          :if={@state == "approved" and @on_undo}
          canvas
          size="sm"
          appearance="ghost"
          phx-click={@on_undo}
          phx-value-id={@id}
          phx-target={@target}
        >
          <.icon name="huge-refresh" />Desfazer
        </.button>
        {if @state == "failed", do: render_slot(@action)}
      </div>
    </section>
    """
  end

  # -- ai_composer -------------------------------------------------------------

  attr :id, :string, default: nil, doc: "Needed for Enter-to-send (the hook needs a stable id)."
  attr :variant, :string, default: "default", values: ~w(default canvas)
  attr :send_label, :string, default: "Enviar"
  attr :mic, :boolean, default: false
  attr :on_mic, :any, default: nil
  attr :mention, :boolean, default: false, doc: "Shows the mention (@) button."
  attr :on_mention, :any, default: nil
  attr :mention_label, :string, default: "Mencionar"
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :name, :string, default: nil
  attr :value, :string, default: nil
  attr :context, :list, default: []
  attr :attachments, :list, default: []
  attr :upload, :any, default: nil

  attr :streaming, :boolean,
    default: false,
    doc:
      "An answer is arriving: sets `data-lu-streaming` (the hook ignores Enter) and shows the stop button."

  attr :on_stop, :any, default: nil
  attr :target, :any, default: nil
  attr :placeholder, :string, default: @default_placeholder

  attr :loop, :string,
    default: nil,
    doc:
      "The canvas loop: this text is typed in place of the field, again and again, and the send button pulses."

  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(autocomplete phx-submit phx-change phx-target)

  slot :chip, doc: "A custom chip, after the context ones."

  @composer "gap-2 rounded-[16px] border border-line-strong bg-panel pt-2.5 pr-2.5 pb-2 pl-3.5 shadow-sm flex"
  @send "grid size-[34px] cursor-pointer place-items-center rounded-[10px] border-0 bg-inverse text-on-inverse"

  @doc "The field to ask the assistant: context chips, text, attachment and send (a form)."
  def ai_composer(assigns) do
    {name, value} =
      case assigns.field do
        %Phoenix.HTML.FormField{} = f -> {f.name, f.value}
        _ -> {assigns.name || "message", assigns.value}
      end

    attachments =
      if assigns.upload,
        do: Enum.map(assigns.upload.entries, &%{name: &1.client_name, size: &1.client_size}),
        else: assigns.attachments

    assigns =
      assigns
      |> assign(:field_name, name)
      |> assign(:field_value, Phoenix.HTML.Form.normalize_value("textarea", value))
      |> assign(:chips, Enum.map(assigns.context, &context_chip/1))
      |> assign(:files, Enum.map(attachments, &file_chip/1))
      |> assign(:hook, assigns.id && "LedgerUI.AiComposer")
      |> assign(:canvas?, assigns.variant == "canvas")
      |> assign(:composer, @composer)
      |> assign(:chip_class, @chip)
      |> assign(:send_class, @send)

    ~H"""
    <form
      id={@id}
      data-part="ai-composer"
      class={[@composer, if(@canvas?, do: "flex-row items-center", else: "flex-col"), @class]}
      phx-hook={@hook}
      data-lu-streaming={@streaming && ""}
      {@rest}
    >
      <div
        :if={@files != []}
        data-part="ai-composer-files"
        class="flex flex-wrap items-center gap-1.5"
      >
        <span :for={{file, size} <- @files} data-part="ai-composer-file" class={@chip_class}>
          <.icon name="huge-file" size="sm" />{file}<span
            :if={size}
            data-part="ai-composer-file-size"
            class="text-xs text-muted tabular-nums"
          >{size}</span>
        </span>
      </div>
      <.composer_clip :if={@canvas?} upload={@upload} />
      <div
        :if={@loop}
        data-part="ai-composer-typing"
        class={["min-h-11 py-0.5 text-[15px] leading-[22px]", @canvas? && "flex-1"]}
      >
        <span
          data-part="ai-composer-typed"
          class="inline-block max-w-0 animate-[lu-typeloop_6s_steps(var(--steps,24))_infinite] overflow-hidden align-bottom whitespace-nowrap"
          style={"--steps:#{String.length(@loop)}"}
        >{@loop}</span>
      </div>
      <textarea
        :if={!@loop}
        data-part="ai-composer-input"
        name={@field_name}
        rows="2"
        placeholder={@placeholder}
        aria-label={@placeholder}
        enterkeyhint="send"
        class={[
          "min-h-11 resize-none border-0 bg-transparent px-0 py-0.5 text-[15px] leading-[22px] outline-none placeholder:text-muted placeholder:opacity-85",
          @canvas? && "flex-1"
        ]}
      >{@field_value}</textarea>
      <div
        data-part="ai-composer-actions"
        class={["flex items-center gap-1", @canvas? && "flex-none"]}
      >
        <.composer_clip :if={!@canvas?} upload={@upload} />
        <.icon_button
          :if={@mention}
          icon="huge-at"
          label={@mention_label}
          variant="ghost"
          size="sm"
          phx-click={@on_mention}
        />
        <button
          :for={{label, icon} <- @chips}
          type="button"
          data-part="ai-composer-chip"
          class={@chip_class}
        >
          <.icon name={icon} size="sm" />{label}
        </button>
        {render_slot(@chip)}
        <.icon_button
          :if={@canvas? and @mic}
          icon="huge-mic"
          label="Microfone"
          variant="ghost"
          size="sm"
          phx-click={@on_mic}
        />
        <%= cond do %>
          <% @streaming -> %>
            <button
              type="button"
              data-part="ai-composer-send"
              class={["ml-auto", @send_class]}
              aria-label="Parar"
              phx-click={@on_stop}
              phx-target={@target}
            >
              <.icon name="huge-pause" size="md" />
            </button>
          <% @canvas? -> %>
            <.button
              canvas
              appearance="primary"
              type="submit"
              class="ml-auto"
              aria-label={@send_label}
            >
              {@send_label}<.icon name="huge-arrow-up" />
            </.button>
          <% true -> %>
            <button
              type="submit"
              data-part="ai-composer-send"
              class={[
                "ml-auto",
                @send_class,
                @loop && "animate-[mo-pulse_2s_ease-in-out_infinite]"
              ]}
              aria-label="Enviar"
            >
              <.icon name="huge-arrow-up" size="md" />
            </button>
        <% end %>
      </div>
    </form>
    """
  end

  attr :upload, :any, default: nil

  defp composer_clip(%{upload: nil} = assigns) do
    ~H"""
    <.icon_button icon="huge-attach" label="Anexar" variant="ghost" size="sm" />
    """
  end

  defp composer_clip(assigns) do
    assigns = assign(assigns, :cls, Button.canvas_classes("sm", "ghost", true))

    ~H"""
    <label data-part="ai-composer-attach" class={@cls} aria-label="Anexar">
      <.icon name="huge-attach" />
      <.live_file_input upload={@upload} class="hidden" />
    </label>
    """
  end

  defp context_chip(%{label: label} = item), do: {label, item[:icon] || "table"}

  defp context_chip(item) do
    k = key(item) |> to_string()

    case @context_known[k] do
      nil -> {k, "table"}
      known -> known
    end
  end

  defp file_chip(%{name: name} = file), do: {name, format_size(file[:size])}

  defp format_size(nil), do: nil
  defp format_size(size) when is_binary(size), do: size
  defp format_size(size) when size < 1024, do: "#{size} B"
  defp format_size(size) when size < 1_048_576, do: "#{Float.round(size / 1024, 1)} KB"
  defp format_size(size), do: "#{Float.round(size / 1_048_576, 1)} MB"

  # -- prompt_suggestions ------------------------------------------------------

  attr :items, :list,
    required: true,
    doc: "Maps `%{title, text, icon, tone, delay}`; a pill shows the `text`."

  attr :tilt, :boolean, default: true, doc: "Tilts the cards (decorative)."
  attr :variant, :string, default: "card", values: ~w(card pill grid)

  attr :columns, :integer,
    default: 2,
    values: [1, 2, 3, 4],
    doc: "Columns of the `card` and `grid` variants."

  attr :on_pick, :any,
    default: nil,
    doc: "Event name (payload `%{value, title}`) or `JS` command."

  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  @columns %{1 => "grid-cols-1", 2 => "grid-cols-2", 3 => "grid-cols-3", 4 => "grid-cols-4"}

  @prompt "flex cursor-pointer items-start gap-2.5 rounded-lg border p-3 text-left text-sm text-ink-2 transition-[background,border-color] duration-[.12s]"

  @doc "The starting suggestions: cards, pills or a grey grid."
  def prompt_suggestions(%{variant: "pill"} = assigns) do
    assigns = assign(assigns, :chip_class, @chip)

    ~H"""
    <div
      data-part="prompt-suggestions"
      class={["flex flex-wrap items-center gap-2.5", @class]}
      {@rest}
    >
      <button
        :for={item <- @items}
        type="button"
        data-part="prompt-suggestion"
        class={[
          "inline-flex h-[30px] cursor-pointer items-center gap-1.5 rounded-full border border-line-strong bg-panel px-[11px] text-[13px] font-medium text-ink-2 hover:bg-hover"
        ]}
        phx-click={@on_pick}
        phx-value-value={item[:text]}
        phx-value-title={item[:title]}
        phx-target={@target}
      >
        {item[:text]}
      </button>
    </div>
    """
  end

  def prompt_suggestions(assigns) do
    grid? = assigns.variant == "grid"

    entries =
      assigns.items
      |> Enum.with_index()
      |> Enum.map(fn {item, index} ->
        {item, prompt_class(index, assigns.tilt and not grid?, grid?), item[:delay]}
      end)

    assigns = assign(assigns, entries: entries, grid?: grid?, cols: @columns[assigns.columns])

    ~H"""
    <div
      data-part="prompt-suggestions"
      class={["grid gap-2.5", @cols, @class]}
      {@rest}
    >
      <button
        :for={{item, item_class, delay} <- @entries}
        type="button"
        data-part="prompt-suggestion"
        class={item_class}
        {sa(delay && "--dl:#{delay}")}
        phx-click={@on_pick}
        phx-value-value={item[:text]}
        phx-value-title={item[:title]}
        phx-target={@target}
      >
        <.icon :if={item[:icon]} name={item[:icon]} size="md" boxed tone={item[:tone]} />
        <%= if @grid? and item[:title] do %>
          <span data-part="prompt-suggestion-text" class="flex flex-col gap-0.5">
            <span
              data-part="prompt-suggestion-title"
              class="font-mono text-xs leading-4 tracking-[.06em] text-muted uppercase"
            >{item[
              :title
            ]}</span>
            <span>{item[:text]}</span>
          </span>
        <% else %>
          <span>{item[:text]}</span>
        <% end %>
      </button>
    </div>
    """
  end

  defp prompt_class(index, tilt?, grid?) do
    [
      @prompt,
      if(grid?,
        do: "border-transparent bg-sunken",
        else: "border-line bg-panel hover:border-line-strong hover:bg-hover"
      ),
      tilt? && if(rem(index, 2) == 0, do: "-rotate-[0.6deg]", else: "rotate-[0.6deg]")
    ]
  end

  # -- conversation_list -------------------------------------------------------

  attr :conversations, :list,
    required: true,
    doc: "Maps `%{id, title, status, day, pending, content, href, navigate, patch, style}`."

  attr :active, :any, default: nil, doc: "The `id` of the open conversation."
  attr :current, :any, default: nil, doc: "The same as `active`."
  attr :search, :string, default: ""
  attr :group_by, :atom, default: :day, values: [:day]
  attr :variant, :string, default: "card", values: ~w(card rail)
  attr :title, :string, default: "Assistente"
  attr :shortcut, :string, default: "⌘ J"
  attr :new_label, :string, default: "Nova conversa"
  attr :on_new, :any, default: nil
  attr :on_search, :any, default: nil
  attr :on_select, :any, default: nil
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :item, doc: "The content of an item, in place of the title and status." do
    attr :conversation, :map
  end

  @nav_item "flex h-[34px] w-full cursor-pointer items-center gap-[11px] rounded-md border-0 px-2.5 text-left text-[13.5px] font-normal no-underline [&_svg]:size-[19px] "
  @nav_heading "flex items-center gap-1 px-2.5 pb-1.5 text-[12.5px] font-medium text-muted"

  @doc "The conversations of the assistant, by day, with a button for a new one and a search."
  def conversation_list(assigns) do
    groups =
      assigns.conversations
      |> filter_conversations(assigns.search)
      |> Enum.chunk_by(& &1[:day])
      |> Enum.map(fn [first | _] = list -> {first[:day], list} end)

    assigns =
      assign(assigns,
        groups: groups,
        active: if(is_nil(assigns.active), do: assigns.current, else: assigns.active),
        nav_item: @nav_item,
        nav_heading: @nav_heading,
        panel: @panel
      )

    ~H"""
    <div
      data-part="conversation-list"
      class={[
        "border border-line bg-panel p-2",
        if(@variant == "rail", do: "flex h-full flex-col rounded-none", else: "rounded-lg"),
        @class
      ]}
      {@rest}
    >
      <div :if={@variant == "rail"} data-part="conversation-heading" class={[@nav_heading, "pt-1.5"]}>
        {@title}
      </div>
      <div :if={@on_new || @on_search} data-part="conversation-list-tools" class="px-1 pt-1 pb-2">
        <.button
          :if={@on_new}
          canvas
          class="w-full"
          phx-click={@on_new}
          phx-target={@target}
        >
          <.icon name="huge-plus" />{@new_label}
          <.kbd :if={@shortcut not in [nil, ""]} class="ml-auto">{@shortcut}</.kbd>
        </.button>
        <form
          :if={@on_search}
          data-part="conversation-list-search"
          phx-change={@on_search}
          phx-target={@target}
          class="mt-1.5"
        >
          <.input type="search" name="search" value={@search} placeholder="Buscar" autocomplete="off" />
        </form>
      </div>
      <%= for {day, list} <- @groups do %>
        <div :if={day} data-part="conversation-heading" class={[@nav_heading, "pt-3.5"]}>{day}</div>
        <a
          :for={conv <- list}
          data-part="conversation-item"
          class={[
            @nav_item,
            if(conv[:id] == @active && @active != nil,
              do: "bg-selected text-ink [&_svg]:text-accent-content",
              else: "bg-transparent text-ink-2 hover:bg-hover hover:text-ink"
            )
          ]}
          aria-current={conv[:id] == @active && @active != nil && "true"}
          href={conv[:href] || "#"}
          data-phx-link={conv_link_type(conv)}
          data-phx-link-state={conv_link_type(conv) && "push"}
          phx-click={!conv_link_type(conv) && !conv[:href] && @on_select}
          phx-value-id={conv[:id]}
          phx-target={@target}
          {sa(conv[:style])}
        >
          <.icon name="huge-message" size="md" />
          <%= if @item != [] do %>
            {render_slot(@item, conv)}
          <% else %>
            <span data-part="conversation-title" class="truncate">{conv[:title]}</span>
            <span
              :if={conv[:status]}
              data-part="conversation-status"
              class="text-xs leading-4 whitespace-nowrap text-muted"
            >
              {conv[:status]}
            </span>
          <% end %>
          <span
            :if={conv[:pending]}
            data-part="conversation-pending"
            class="ml-auto inline-block size-[7px] flex-none rounded-full bg-accent-500"
            title="Ação pendente"
          ></span>
        </a>
      <% end %>
    </div>
    """
  end

  defp conv_link_type(%{navigate: nav}) when is_binary(nav), do: "redirect"
  defp conv_link_type(%{patch: patch}) when is_binary(patch), do: "patch"
  defp conv_link_type(_), do: nil

  defp filter_conversations(list, search) when search in [nil, ""], do: list

  defp filter_conversations(list, search) do
    needle = String.downcase(search)

    Enum.filter(list, fn conv ->
      String.contains?(String.downcase("#{conv[:title]} #{conv[:content]}"), needle)
    end)
  end

  # -- ai_chat -----------------------------------------------------------------

  defp chat_variant(%{variant: "page", compact: true}), do: "page-compact"
  defp chat_variant(%{variant: variant}), do: variant

  attr :id, :string, required: true
  attr :messages, :any, default: [], doc: "A list of message maps or a stream of them."
  attr :user, :any, default: nil
  attr :streaming, :boolean, default: false
  attr :context, :list, default: []
  attr :mention, :boolean, default: false
  attr :mention_label, :string, default: "Mencionar"

  attr :variant, :string,
    default: "card",
    values: ~w(card default canvas bare page),
    doc:
      "`card` (or `default`): a bordered panel; `canvas`: a flat sunken box; `bare`: no box; `page`: a raised rounded box."

  attr :compact, :boolean,
    default: false,
    doc: "12px of padding in the scroll area (instead of 18px), for a small box."

  attr :draft, :string, default: nil
  attr :greeting, :string, default: nil

  attr :start, :boolean,
    default: true,
    doc: "Shows the greeting and suggestions (or `:empty`) while a list has no messages."

  attr :footnote, :string, default: nil
  attr :composer, :boolean, default: true
  attr :placeholder, :string, default: @default_placeholder
  attr :on_send, :any, default: nil
  attr :on_change, :any, default: nil
  attr :on_stop, :any, default: nil
  attr :on_approve, :any, default: nil
  attr :on_reject, :any, default: nil
  attr :on_undo, :any, default: nil
  attr :on_pick, :any, default: nil
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block, doc: "Extra content after the messages."
  slot :empty, doc: "Shown above the messages in place of the greeting and suggestions."
  slot :header, doc: "The title and subtitle of the conversation, in the header of the `card`."

  slot :suggestion, doc: "A starting card; the content is its text." do
    attr :title, :string
    attr :prompt, :string
  end

  @chat_variants %{
    "card" => "flex flex-col #{@panel}",
    "default" => "flex flex-col #{@panel}",
    "canvas" => "flex flex-col rounded-[16px] bg-sunken text-[13px]",
    "bare" => "flex flex-col",
    "page" =>
      "flex min-h-full flex-col gap-1.5 rounded-[16px] bg-panel p-3.5 text-[13px] shadow-[0_0_0_1px_var(--lu-line),var(--lu-shadow-sm)]",
    # a compact box has the one padding of its scroll area and the height of its content
    "page-compact" =>
      "flex flex-col gap-1.5 rounded-[16px] bg-panel text-[13px] shadow-[0_0_0_1px_var(--lu-line),var(--lu-shadow-sm)]"
  }

  @doc "The whole conversation: greeting and suggestions, the messages and the field to ask."
  def ai_chat(assigns) do
    stream? = match?(%LiveStream{}, assigns.messages)

    messages =
      if stream?,
        do: assigns.messages,
        else: Enum.map(assigns.messages, &{"#{assigns.id}-msg-#{&1[:id]}", &1})

    blank? = !stream? and messages == []

    assigns =
      assign(assigns,
        root_class: @chat_variants[chat_variant(assigns)],
        stream?: stream?,
        entries: messages,
        has_messages: stream? or messages != [],
        show_start: blank? and assigns.start,
        user_name: user_name(assigns.user),
        greeting_name: assigns.greeting == nil && user_name(assigns.user) |> first_name()
      )

    ~H"""
    <div id={@id} data-part="ai-chat" class={[@root_class, @class]} {@rest}>
      <div
        :if={@variant in ["card", "default"] and @header != []}
        data-part="ai-chat-header"
        class="flex flex-wrap items-center gap-2.5 border-b border-line px-3.5 py-3"
      >
        {render_slot(@header)}
      </div>
      <div
        data-part="ai-chat-scroll"
        class={[
          "flex flex-1 flex-col gap-[18px] overflow-auto",
          if(@compact, do: "p-3", else: "p-[18px]")
        ]}
      >
        <%= if @show_start do %>
          <%= if @empty != [] do %>
            {render_slot(@empty)}
          <% else %>
            <.ai_greeting name={@greeting_name || nil} greeting={@greeting} />
            <.chat_suggestions
              :if={@suggestion != []}
              suggestion={@suggestion}
              on_pick={@on_pick}
              target={@target}
            />
          <% end %>
        <% end %>
        <div
          :if={@has_messages}
          id={"#{@id}-messages"}
          data-part="ai-chat-messages"
          phx-update={@stream? && "stream"}
          class="flex flex-col gap-[18px]"
        >
          <.chat_message
            :for={{dom_id, msg} <- @entries}
            id={dom_id}
            msg={msg}
            user={@user_name}
            on_approve={@on_approve}
            on_reject={@on_reject}
            on_undo={@on_undo}
            target={@target}
          />
        </div>
        {render_slot(@inner_block)}
      </div>
      <div :if={@composer} data-part="ai-chat-footer" class="p-3">
        <.ai_composer
          id={"#{@id}-composer"}
          value={@draft}
          context={@context}
          mention={@mention}
          mention_label={@mention_label}
          streaming={@streaming}
          on_stop={@on_stop}
          placeholder={@placeholder}
          target={@target}
          phx-submit={@on_send}
          phx-change={@on_change}
          phx-target={@target}
        />
        <p
          :if={@footnote}
          data-part="ai-chat-footnote"
          class="mx-1 mt-2 mb-0 text-xs leading-4 text-muted"
        >
          {@footnote}
        </p>
      </div>
    </div>
    """
  end

  defp user_name(nil), do: nil
  defp user_name(%{name: name}), do: name
  defp user_name(name) when is_binary(name), do: name
  defp user_name(_), do: nil

  defp first_name(nil), do: nil
  defp first_name(name), do: name |> String.split(" ", parts: 2) |> hd()

  attr :suggestion, :list, required: true
  attr :on_pick, :any, default: nil
  attr :target, :any, default: nil

  defp chat_suggestions(assigns) do
    assigns = assign(assigns, :prompt, @prompt)

    ~H"""
    <div data-part="prompt-suggestions" class="grid grid-cols-2 gap-2.5">
      <button
        :for={s <- @suggestion}
        type="button"
        data-part="prompt-suggestion"
        class={[@prompt, "border-line bg-panel hover:border-line-strong hover:bg-hover"]}
        phx-click={@on_pick}
        phx-value-value={s[:prompt]}
        phx-value-title={s[:title]}
        phx-target={@target}
      >
        <span data-part="prompt-suggestion-text" class="flex flex-col gap-0.5">
          <b :if={s[:title]}>{s[:title]}</b>
          <span>{render_slot(s)}</span>
        </span>
      </button>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :msg, :map, required: true
  attr :user, :string, default: nil
  attr :on_approve, :any, default: nil
  attr :on_reject, :any, default: nil
  attr :on_undo, :any, default: nil
  attr :target, :any, default: nil

  defp chat_message(assigns) do
    msg = assigns.msg

    assigns =
      assign(assigns,
        role: key(msg[:role] || "assistant") |> to_string(),
        paragraphs: paragraphs(msg[:text]),
        trace: msg[:trace],
        proposal: msg[:proposal]
      )

    ~H"""
    <.ai_message
      id={@id}
      role={@role}
      name={@msg[:name] || (@role == "user" && @user) || nil}
      streaming={@msg[:streaming] || false}
      status={key(@msg[:status] || "ok") |> to_string()}
    >
      <:trace :if={@trace}>
        <.ai_tool_trace
          tools={@trace[:tools] || []}
          duration_ms={@trace[:duration_ms]}
          running={@trace[:running] || false}
        />
      </:trace>
      <div :for={p <- @paragraphs}>{p}</div>
      <.ai_proposal
        :if={@proposal}
        id={to_string(@proposal[:id])}
        title={@proposal[:title]}
        status={@proposal[:status] || "pending"}
        note={@proposal[:note]}
        editable={@proposal[:editable] || false}
        on_approve={@on_approve}
        on_reject={@on_reject}
        on_undo={@on_undo}
        target={@target}
      >
        <:change :for={c <- @proposal[:changes] || []} label={c[:label]} from={c[:from]} to={c[:to]}>
          {c[:text]}
        </:change>
      </.ai_proposal>
    </.ai_message>
    """
  end

  defp paragraphs(nil), do: []

  defp paragraphs(text) do
    text
    |> String.split(~r/\n{2,}/, trim: true)
    |> Enum.map(&inline_md(&1, "b", nil))
  end
end
