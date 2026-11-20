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
  file `priv/static/ledger_ui/hooks/ai_composer.js`).
  """
  use LedgerUI.Component

  alias Phoenix.LiveView.LiveStream

  @default_placeholder "Pergunte sobre pedidos, estoque, fiscal ou financeiro"

  @status_badges %{
    "pending" => {"warn", nil},
    "applying" => {"acc", "Aplicando"},
    "approved" => {"pos", "Aprovado"},
    "rejected" => {nil, "Recusado"},
    "failed" => {"neg", "Falhou"}
  }

  @context_known %{
    "pedidos" => {"Pedidos", "invoice"},
    "catalogo" => {"Catálogo", "package"},
    "clientes" => {"Clientes", "users"},
    "financeiro" => {"Financeiro", "wallet"},
    "fiscal" => {"Fiscal", "file"},
    "banco" => {"Banco", "bank"}
  }

  # -- helpers -----------------------------------------------------------------

  defp esc(text), do: text |> Phoenix.HTML.html_escape() |> elem(1)

  # `**bold**` -> <tag>bold</tag>; everything else is escaped.
  defp inline_md(nil, _tag), do: ""

  defp inline_md(text, tag) do
    iodata =
      ~r/\*\*(.+?)\*\*/
      |> Regex.split(to_string(text), include_captures: true)
      |> Enum.map(fn
        "**" <> rest = piece ->
          if String.ends_with?(rest, "**") and byte_size(rest) > 2,
            do: ["<", tag, ">", esc(binary_part(rest, 0, byte_size(rest) - 2)), "</", tag, ">"],
            else: esc(piece)

        piece ->
          esc(piece)
      end)

    # every piece of `iodata` is escaped above
    {:safe, iodata}
  end

  defp merge_style(base, extra) do
    [base, extra] |> Enum.reject(&(&1 in [nil, false, ""])) |> Enum.join(";")
  end

  # `style={nil}` would render `style=""`: pass the attribute through a map instead.
  defp sa(style) when style in [nil, false, ""], do: %{}
  defp sa(style), do: %{style: style}

  defp split_style(rest, base) do
    {style, rest} = Map.pop(rest, :style)
    {merge_style(base, style), rest}
  end

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
    <div data-part="ai-insights" class={cx([@class])} {@rest}>
      <.insight_item :for={insight <- @insights} insight={insight} />
    </div>
    """
  end

  def ai_insights(assigns) do
    ~H"""
    <section data-part="ai-insights" class={cx(["lu-card", @class])} {@rest}>
      <header class="lu-card-h">
        <h3 class="lu-card-t" style="margin:0">
          {@title}
          <span :if={@count} class="lu-badge lime"><.icon name="sparkles" />{@count} {@count_label}</span>
        </h3>
        <div :if={@on_chat} class="act">
          <button
            type="button"
            class="lu-btn icon sm"
            aria-label={@chat_label}
            phx-click={@on_chat}
            phx-target={@target}
          >
            <.icon name="message" />
          </button>
        </div>
      </header>
      <div class="lu-card-b" style="">
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
        text: inline_md(i[:text], "strong"),
        has_footer: i[:impact] != nil or i[:action] != nil
      )

    ~H"""
    <div class="lu-insight" {sa(@i[:style])}>
      <.icon name={@i[:icon]} />
      <div class="t">
        <b>{@i[:title]}</b>
        <p>{@text}</p>
        <div :if={@has_footer} class="f">
          <span :if={@i[:impact]} class={cx(["lu-badge", @i[:tone]])}>{@i[:impact]}</span>
          <a
            :if={@i[:action]}
            class="lu-btn link sm"
            href={@i[:href] || "#"}
            data-phx-link={@i[:navigate] && "redirect"}
          >
            {@i[:action]} <.icon name="arrow-right" size="sm" />
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

  @doc "Call to the assistant pinned on the sidebar, with insight count and main action."
  def ai_promo(%{variant: "rail"} = assigns) do
    assigns = assign(assigns, :sub, promo_subtitle(assigns))
    assigns = assign(assigns, :aura, if(assigns.tone == "warm", do: "t-warn", else: "t-ai"))
    {style, rest} = split_style(assigns.rest, "--r:16px;width:100%")
    assigns = assign(assigns, style: style, rest: rest)

    ~H"""
    <span data-part="ai-promo" class={cx(["lu-aura m-spin", @aura, @class])} style={@style} {@rest}>
      <div
        class="lu-promo"
        style="margin:0"
        role={@on_click && "button"}
        tabindex={@on_click && "0"}
        phx-click={@on_click}
        phx-target={@target}
      >
        <.icon name="sparkles" size="md" />
        <b>{@title}</b><span :if={@sub} class="lu-xs lu-muted">{@sub}</span>
      </div>
    </span>
    """
  end

  def ai_promo(assigns) do
    assigns = assign(assigns, :sub, promo_subtitle(assigns))

    ~H"""
    <div data-part="ai-promo" class={cx(["lu-promo", @class])} {@rest}>
      <div class="lu-row" style="flex-wrap:nowrap">
        <span class="ic"><.icon name="sparkles" size="md" /></span>
        <span class="lu-col" style="gap:0">
          <b>{@title}</b>
          <span :if={@sub} class="lu-xs lu-muted">{@sub}</span>
        </span>
      </div>
      <span :if={@text} class="lu-small lu-ink2">{@text}</span>
      <button
        :if={@action}
        type="button"
        class="lu-btn primary block"
        style="justify-content:space-between"
        phx-click={@on_click}
        phx-target={@target}
      >
        <span class="lu-row" style="gap:8px">
          <span class="lead" style="margin-left:-8px"><.icon name="sparkles" size="sm" /></span>{@action}
        </span>
        <.icon name="arrow-right" size="sm" />
      </button>
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

  @doc "The greeting of the assistant: the first line in a gradient and the question under it."
  def ai_greeting(assigns) do
    {style, rest} = split_style(assigns.rest, nil)

    assigns =
      assigns
      |> assign(:line, greeting_line(assigns))
      |> assign(:gradient, greeting_gradient(assigns.tone))
      |> assign(:px, %{"sm" => 30, "md" => 36, "lg" => 40}[assigns.size])
      |> assign(:style, style)
      |> assign(:rest, rest)

    ~H"""
    <div
      data-part="ai-greeting"
      class={cx(["lu-col", @class])}
      style={merge_style("gap:4px", @style)}
      {@rest}
    >
      <b style={"font-size:#{@px}px;line-height:1.15;letter-spacing:-.02em;background:#{@gradient};-webkit-background-clip:text;background-clip:text;color:transparent;width:fit-content"}>
        {@line}
      </b>
      <span class="lu-muted" style={"font-size:#{@px - 8}px;line-height:1.2"}>{@tagline}</span>
    </div>
    """
  end

  defp greeting_gradient("warm"),
    do: "linear-gradient(90deg,#ec4899,#f43f5e,#f97316,#d946ef)"

  defp greeting_gradient(_),
    do: "linear-gradient(90deg,var(--accent),var(--info),#8b5cf6,#ec4899)"

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

  attr :running, :boolean, default: false, doc: "The queries are still going on."
  attr :expanded, :boolean, default: false, doc: "Opens the list of queries."
  attr :duration_ms, :integer, default: nil, doc: "The total time, shown in seconds."
  attr :class, :any, default: nil
  attr :rest, :global

  @doc "What the assistant consulted: summary (count and time) and one row per query."
  def ai_tool_trace(assigns) do
    assigns =
      assigns
      |> assign(:count, length(assigns.tools))
      |> assign(:total, seconds(assigns.duration_ms))

    ~H"""
    <details data-part="ai-tool-trace" class={cx(["lu-trace", @class])} open={@expanded} {@rest}>
      <summary
        class="lu-row"
        style="list-style:none;padding:9px 12px;cursor:pointer;border-bottom:1px solid var(--line)"
      >
        <.icon name="tool" size="md" class="lu-muted" />
        <span class="lu-small">{tool_summary(@count, @running)}</span>
        <span class="lu-grow"></span>
        <span :if={@total} class="lu-xs lu-muted mono">{@total}</span>
      </summary>
      <div :for={tool <- @tools} class="lu-trace-i" {sa(tool[:failed] && "color:var(--neg)")}>
        <.icon name={tool_icon(tool)} size="md" />
        <span class="nm">{tool[:title] || tool[:label]}</span>
        <span class="lu-xs lu-muted">{tool[:detail]}</span>
        <span class="ms">{tool[:ms]}</span>
      </div>
    </details>
    """
  end

  defp tool_icon(%{failed: true}), do: "warn-circle"
  defp tool_icon(%{running: true}), do: "refresh"
  defp tool_icon(_), do: "check-circle"

  defp tool_summary(_count, true), do: "Em andamento"
  defp tool_summary(1, _), do: "Usou 1 ferramenta"
  defp tool_summary(count, _), do: "Usou #{count} ferramentas"

  # -- ai_message --------------------------------------------------------------

  attr :role, :string, default: "assistant", values: ~w(user assistant)

  attr :variant, :string,
    default: "card",
    values: ~w(card plain),
    doc: "`card` frames the assistant's content; `plain` is loose text beside the spark."

  attr :streaming, :boolean, default: false, doc: "Shows the typing dots after the content."
  attr :status, :string, default: "ok", values: ~w(ok error)
  attr :name, :string, default: nil, doc: "The user's name: its initials make the avatar."

  attr :actions, :list,
    default: [],
    doc: "Buttons under the content: `copy`, `useful`, `useless`, `regenerate`."

  attr :on_action, :any, default: nil, doc: "Event name (payload `%{action}`) or `JS` command."
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block, required: true
  slot :trace, doc: "The queries the assistant made, above the content."

  @actions %{
    "copy" => {"Copiar", "copy"},
    "useful" => {"Útil", "thumb-up"},
    "useless" => {"Não útil", "thumb-down"},
    "regenerate" => {"Gerar de novo", "refresh"}
  }

  @doc "A message of the conversation."
  def ai_message(%{role: "user"} = assigns) do
    assigns = assign(assigns, :initials, initials(assigns.name))

    ~H"""
    <div data-part="ai-message" class={cx(["lu-msg me", @class])} {@rest}>
      <span :if={@initials} class="lu-av sq" style="--s:30px">{@initials}</span>
      <div class="bubble">{render_slot(@inner_block)}</div>
    </div>
    """
  end

  def ai_message(assigns) do
    assigns =
      assign(assigns, :action_list, for(a <- assigns.actions, do: {key(a), @actions[key(a)]}))

    ~H"""
    <div
      data-part="ai-message"
      class={cx(["lu-msg", @class])}
      {@rest}
    >
      <span class="ai"><.icon name="sparkles" size="md" /></span>
      <div class="body">
        {render_slot(@trace)}
        <div :if={@status == "error"} style="color:var(--neg)">
          <.icon name="warn-circle" size="sm" /> {render_slot(@inner_block)}
        </div>
        <div
          :if={@status != "error" and @variant == "card"}
          class="lu-panel"
          style="padding:10px 12px"
        >
          {render_slot(@inner_block)}
        </div>
        {if @status != "error" and @variant == "plain", do: render_slot(@inner_block)}
        <span :if={@streaming} class="lu-dots" style="margin-top:4px"><i></i><i></i><i></i></span>
        <div :if={@action_list != []} class="acts">
          <button
            :for={{action, {label, icon}} <- @action_list}
            type="button"
            class="lu-btn icon ghost sm"
            aria-label={label}
            phx-click={@on_action}
            phx-value-action={action}
            phx-target={@target}
          >
            <.icon name={icon} />
          </button>
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

  @doc "An action the assistant proposes, which only happens when the user approves."
  def ai_proposal(assigns) do
    status = prop_status(assigns.status)
    {tone, label} = @status_badges[status] || @status_badges["pending"]

    assigns =
      assigns
      |> assign(:state, status)
      |> assign(:badge_tone, tone)
      |> assign(:badge_label, label || assigns.pending_label)
      |> assign(
        :footer?,
        status == "pending" or (status == "approved" and assigns.on_undo != nil) or
          (status == "failed" and assigns.action != [])
      )

    ~H"""
    <section
      id={@id}
      data-part="ai-proposal"
      class={cx(["lu-card", @class])}
      {@rest}
    >
      <header class="lu-card-h">
        <h3 class="lu-card-t" style="margin:0">
          {@heading} <span class={cx(["lu-badge", @badge_tone])}>{@badge_label}</span>
        </h3>
      </header>
      <div class="lu-card-b" style="">
        <div class="lu-col" style="gap:12px">
          <div class="lu-row">
            <span class="lu-ic lime"><.icon name="sparkles" size="md" /></span>
            <b>{@title}</b>
          </div>
          <div :if={@change != [] and @layout == "table"} class="lu-tablewrap">
            <table class="lu-table dense">
              <thead>
                <tr>
                  <th :for={h <- @headers}>{h}</th>
                </tr>
              </thead>
              <tbody>
                <tr :for={change <- @change}>
                  <td>{change[:label]}</td>
                  <%= if change[:from] || change[:to] do %>
                    <td><s class="lu-muted">{change[:from]}</s></td>
                    <td class="strong">{change[:to]}</td>
                  <% else %>
                    <td class="strong" colspan="2">{render_slot(change)}</td>
                  <% end %>
                </tr>
              </tbody>
            </table>
          </div>
          <div :if={@change != [] and @layout != "table"} class="lu-col" style="gap:6px">
            <div :for={change <- @change} class="lu-row" style="gap:8px">
              <span class="lu-small lu-muted" style="min-width:84px">{change[:label]}</span>
              <%= if change[:from] || change[:to] do %>
                <s class="lu-muted">{change[:from]}</s>
                <.icon :if={@layout == "list"} name="arrow-right" size="sm" />
                <b :if={@layout == "list"} style="color:var(--pos)">{change[:to]}</b>
                <span :if={@layout == "definition"} class="lu-badge pos">{change[:to]}</span>
              <% else %>
                <span>{render_slot(change)}</span>
              <% end %>
            </div>
          </div>
          <div :for={preview <- @preview} class="lu-col" style="gap:4px">
            <span class="lu-xs lu-muted">{preview[:label] || "Mensagem"}</span>
            <div class="lu-panel" style="padding:10px 12px">{render_slot(preview)}</div>
          </div>
          <div :for={impact <- @impact} class="lu-row">
            <span :if={@layout != "table"} class="lu-xs lu-muted">{impact[:label] || "Impacto"}</span>
            {render_slot(impact)}
          </div>
          <span :if={@note && @state != "pending"} class="lu-small lu-muted">{@note}</span>
        </div>
      </div>
      <div :if={@footer?} class="lu-card-f">
        <span :if={@pending_note && @state == "pending"} class="lu-xs lu-muted">{@pending_note}</span>
        <span class="lu-grow"></span>
        <%= if @state == "pending" do %>
          <button
            type="button"
            class="lu-btn ghost sm"
            phx-click={@on_reject}
            phx-value-id={@id}
            phx-target={@target}
          >
            Rejeitar
          </button>
          <button
            :if={@editable}
            type="button"
            class="lu-btn sm"
            phx-click={@on_edit}
            phx-value-id={@id}
            phx-target={@target}
          >
            <.icon name="edit" />Editar
          </button>
          <button
            type="button"
            class="lu-btn primary sm"
            phx-click={@on_approve}
            phx-value-id={@id}
            phx-target={@target}
          >
            <.icon name="check" />Aprovar
          </button>
        <% end %>
        <button
          :if={@state == "approved" and @on_undo}
          type="button"
          class="lu-btn ghost sm"
          phx-click={@on_undo}
          phx-value-id={@id}
          phx-target={@target}
        >
          <.icon name="refresh" />Desfazer
        </button>
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
  attr :streaming, :boolean, default: false
  attr :on_stop, :any, default: nil
  attr :target, :any, default: nil
  attr :placeholder, :string, default: @default_placeholder
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(autocomplete phx-submit phx-change phx-target)

  slot :chip, doc: "A custom chip, after the context ones."

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

    ~H"""
    <form
      id={@id}
      data-part="ai-composer"
      class={cx(["lu-composer", @class])}
      {sa(@canvas? && "flex-direction:row;align-items:center")}
      phx-hook={@hook}
      {@rest}
    >
      <div :if={@files != []} class="lu-row" style="gap:6px">
        <span :for={{file, size} <- @files} class="lu-chip" style="height:28px">
          <.icon name="file" size="sm" />{file}<span :if={size} class="n">{size}</span>
        </span>
      </div>
      <.composer_clip :if={@canvas?} upload={@upload} />
      <textarea
        name={@field_name}
        rows="2"
        placeholder={@placeholder}
        aria-label={@placeholder}
        enterkeyhint="send"
        {sa(@canvas? && "flex:1")}
      >{@field_value}</textarea>
      <div class="row" {sa(@canvas? && "flex:none")}>
        <.composer_clip :if={!@canvas?} upload={@upload} />
        <button
          :if={@mention}
          type="button"
          class="lu-btn icon ghost sm"
          aria-label={@mention_label}
          phx-click={@on_mention}
        >
          <.icon name="at" />
        </button>
        <button :for={{label, icon} <- @chips} type="button" class="lu-chip" style="height:28px">
          <.icon name={icon} size="sm" />{label}
        </button>
        {render_slot(@chip)}
        <button
          :if={@canvas? and @mic}
          type="button"
          class="lu-btn icon ghost sm"
          aria-label="Microfone"
          phx-click={@on_mic}
        >
          <.icon name="mic" />
        </button>
        <%= cond do %>
          <% @streaming -> %>
            <button
              type="button"
              class="send"
              aria-label="Parar"
              phx-click={@on_stop}
              phx-target={@target}
            >
              <.icon name="pause" size="md" />
            </button>
          <% @canvas? -> %>
            <button
              type="submit"
              class="lu-btn primary"
              style="margin-left:auto"
              aria-label={@send_label}
            >
              {@send_label}<.icon name="arrow-up" />
            </button>
          <% true -> %>
            <button type="submit" class="send" aria-label="Enviar">
              <.icon name="arrow-up" size="md" />
            </button>
        <% end %>
      </div>
    </form>
    """
  end

  attr :upload, :any, default: nil

  defp composer_clip(%{upload: nil} = assigns) do
    ~H"""
    <button type="button" class="lu-btn icon ghost sm" aria-label="Anexar"><.icon name="attach" /></button>
    """
  end

  defp composer_clip(assigns) do
    ~H"""
    <label class="lu-btn icon ghost sm" aria-label="Anexar" style="cursor:pointer">
      <.icon name="attach" />
      <.live_file_input upload={@upload} style="display:none" />
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

  attr :on_pick, :any,
    default: nil,
    doc: "Event name (payload `%{value, title}`) or `JS` command."

  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  @doc "The starting suggestions: cards, pills or a grey grid."
  def prompt_suggestions(%{variant: "pill"} = assigns) do
    ~H"""
    <div data-part="prompt-suggestions" class={cx(["lu-row", @class])} {@rest}>
      <button
        :for={item <- @items}
        type="button"
        class="lu-chip"
        style="border-radius:999px"
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
    {style, rest} = Map.pop(assigns.rest, :style)
    style = style || "--cols:2;gap:10px"
    grid? = assigns.variant == "grid"

    items =
      assigns.items
      |> Enum.with_index()
      |> Enum.map(fn {item, index} ->
        {item, prompt_style(item, index, assigns.tilt and not grid?, grid?)}
      end)

    assigns = assign(assigns, style: style, rest: rest, entries: items, grid?: grid?)

    ~H"""
    <div data-part="prompt-suggestions" class={cx(["lu-grid", @class])} style={@style} {@rest}>
      <button
        :for={{item, item_style} <- @entries}
        type="button"
        class="lu-prompt"
        {sa(item_style)}
        phx-click={@on_pick}
        phx-value-value={item[:text]}
        phx-value-title={item[:title]}
        phx-target={@target}
      >
        <span :if={item[:icon]} class={cx(["lu-ic", item[:tone]])}><.icon
          name={item[:icon]}
          size="md"
        /></span>
        <%= if @grid? and item[:title] do %>
          <span class="lu-col" style="gap:2px">
            <span class="lu-xs lu-muted mono" style="text-transform:uppercase;letter-spacing:.06em">{item[
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

  defp prompt_style(item, index, tilt?, grid?) do
    [
      grid? && "background:var(--bg-sunken);border-color:transparent",
      tilt? && "transform:rotate(#{if rem(index, 2) == 0, do: "-0.6", else: "0.6"}deg)",
      item[:delay] && "--dl:#{item[:delay]}"
    ]
    |> Enum.filter(& &1)
    |> Enum.join(";")
    |> case do
      "" -> nil
      style -> style
    end
  end

  # -- conversation_list -------------------------------------------------------

  attr :conversations, :list,
    required: true,
    doc: "Maps `%{id, title, status, day, pending, content, href, navigate, patch}`."

  attr :active, :any, default: nil
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

  @doc "The conversations of the assistant, by day, with a button for a new one and a search."
  def conversation_list(assigns) do
    {style, rest} = split_style(assigns.rest, "padding:8px")

    style =
      if assigns.variant == "rail",
        do: merge_style("display:flex;flex-direction:column;height:100%;border-radius:0", style),
        else: style

    groups =
      assigns.conversations
      |> filter_conversations(assigns.search)
      |> Enum.chunk_by(& &1[:day])
      |> Enum.map(fn [first | _] = list -> {first[:day], list} end)

    assigns = assign(assigns, style: style, rest: rest, groups: groups)

    ~H"""
    <div data-part="conversation-list" class={cx(["lu-panel", @class])} style={@style} {@rest}>
      <div :if={@variant == "rail"} class="lu-nav-h" style="padding-top:6px">{@title}</div>
      <div :if={@on_new || @on_search} style="padding:4px 4px 8px">
        <button
          :if={@on_new}
          type="button"
          class="lu-btn block"
          phx-click={@on_new}
          phx-target={@target}
        >
          <.icon name="plus" />{@new_label}<kbd
            :if={@shortcut not in [nil, ""]}
            class="lu-kbd"
            style="margin-left:auto"
          >{@shortcut}</kbd>
        </button>
        <form :if={@on_search} phx-change={@on_search} phx-target={@target} style="margin-top:6px">
          <label class="lu-input">
            <input
              type="search"
              name="search"
              value={@search}
              placeholder="Buscar"
              autocomplete="off"
            />
          </label>
        </form>
      </div>
      <%= for {day, list} <- @groups do %>
        <div :if={day} class="lu-nav-h">{day}</div>
        <a
          :for={conv <- list}
          class={cx(["lu-nav-item", {"on", conv[:id] == @active && @active != nil}])}
          href={conv[:href] || "#"}
          data-phx-link={conv_link_type(conv)}
          data-phx-link-state={conv_link_type(conv) && "push"}
          phx-click={!conv_link_type(conv) && !conv[:href] && @on_select}
          phx-value-id={conv[:id]}
          phx-target={@target}
          style="height:34px;font-size:13.5px;font-weight:400"
        >
          <.icon name="message" size="md" />
          <%= if @item != [] do %>
            {render_slot(@item, conv)}
          <% else %>
            <span style="overflow:hidden;text-overflow:ellipsis;white-space:nowrap">{conv[:title]}</span>
            <span :if={conv[:status]} class="lu-xs lu-muted" style="white-space:nowrap">{conv[:status]}</span>
          <% end %>
          <span
            :if={conv[:pending]}
            class="lu-dot"
            style="margin-left:auto;color:var(--teal-500)"
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

  attr :id, :string, required: true
  attr :messages, :any, default: [], doc: "A list of message maps or a stream of them."
  attr :user, :any, default: nil
  attr :streaming, :boolean, default: false
  attr :context, :list, default: []
  attr :mention, :boolean, default: false
  attr :mention_label, :string, default: "Mencionar"
  attr :variant, :string, default: "card", values: ~w(card bare page)
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

  @variants %{
    "card" => {"lu-panel", "display:flex;flex-direction:column"},
    "bare" => {nil, "display:flex;flex-direction:column"},
    "page" => {"lu-cv default", "display:flex;flex-direction:column;min-height:100%"}
  }

  @doc "The whole conversation: greeting and suggestions, the messages and the field to ask."
  def ai_chat(assigns) do
    {class, base_style} = @variants[assigns.variant]
    {style, rest} = split_style(assigns.rest, base_style)
    stream? = match?(%LiveStream{}, assigns.messages)

    messages =
      if stream?,
        do: assigns.messages,
        else: Enum.map(assigns.messages, &{"#{assigns.id}-msg-#{&1[:id]}", &1})

    blank? = !stream? and messages == []

    assigns =
      assign(assigns,
        root_class: class,
        style: style,
        rest: rest,
        stream?: stream?,
        entries: messages,
        has_messages: stream? or messages != [],
        show_start: blank? and assigns.start,
        user_name: user_name(assigns.user),
        greeting_name: assigns.greeting == nil && user_name(assigns.user) |> first_name()
      )

    ~H"""
    <div id={@id} data-part="ai-chat" class={cx([@root_class, @class])} style={@style} {@rest}>
      <div
        :if={@variant == "card" and @header != []}
        class="lu-row"
        style="padding:12px 14px;border-bottom:1px solid var(--line)"
      >
        {render_slot(@header)}
      </div>
      <div class="lu-col" style="flex:1;overflow:auto;padding:18px;gap:18px">
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
          phx-update={@stream? && "stream"}
          class="lu-col"
          style="gap:18px"
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
      <div :if={@composer} style="padding:12px">
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
        <p :if={@footnote} class="lu-xs lu-muted" style="margin:8px 4px 0">{@footnote}</p>
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
    ~H"""
    <div class="lu-grid" style="--cols:2;gap:10px">
      <button
        :for={s <- @suggestion}
        type="button"
        class="lu-prompt"
        phx-click={@on_pick}
        phx-value-value={s[:prompt]}
        phx-value-title={s[:title]}
        phx-target={@target}
      >
        <span class="lu-col" style="gap:2px">
          <b :if={s[:title]} class="ink">{s[:title]}</b>
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
    |> Enum.map(&inline_md(&1, "b"))
  end
end
