defmodule LedgerUI.Components.Textarea do
  @moduledoc """
  Multi-line text field: `outlined`, `filled` or `plain`, fixed or resizable, with a live
  character counter, autogrow, `{{token}}` highlighting and optional header/footer bars.

      <.textarea field={@form[:bio]} label="Bio" variant="filled" resizable />
      <.textarea name="note" maxlength={200} counter autogrow max_rows={8} />
      <.textarea name="why" counter min_length={20} counter_format="%{count} de %{max}" />
      <.textarea name="msg" tokens value="A fatura {{fatura.numero}} esta atrasada." />

      <.textarea name="post" rows={5}>
        <:header><span class="text-xs text-muted">Variaveis</span></:header>
        <:footer><span>toolbar</span></:footer>
      </.textarea>

  With `counter`, `maxlength` is a soft limit: the counter warns from 90% and turns red past it,
  and the browser does not refuse the characters (validate on the server).

  The counter (`counter`), `autogrow` and `tokens` run in the `LedgerUI.Textarea` hook, which
  needs a stable `id` (it comes from `field`, or `name`). The counter updates while typing, without
  the server. A plain textarea needs no hook.
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Form

  # the text of the field: size, padding and the minimum height (3 lines of 21px)
  @text %{
    "sm" => "px-2.5 py-2 text-[13px]",
    "md" => "px-3 py-2.5 text-sm",
    "lg" => "px-3.5 py-3 text-[15px]"
  }
  @min_h %{"sm" => "min-h-16", "md" => "min-h-[84px]", "lg" => "min-h-[84px]"}

  @frame "flex min-w-0 flex-col rounded-md border has-disabled:cursor-not-allowed has-disabled:bg-sunken"

  @bar "flex items-center gap-1 px-2 py-1.5 text-muted"

  @counter_loop "animate-[lu-cntloop_6s_steps(30)_infinite] after:[counter-reset:n_var(--lu-n)] after:content-[counter(n)_var(--post)]"

  @counter "text-xs leading-5 text-muted tabular-nums data-[state=over]:font-semibold data-[state=over]:text-neg data-[state=warn]:text-warn"

  defp frame_class(variant, state) do
    bg =
      case variant do
        "filled" -> "bg-sunken"
        "plain" -> "bg-transparent"
        _ -> "bg-panel"
      end

    border =
      cond do
        state == "error" -> "border-neg"
        state == "success" -> "border-pos"
        variant == "outlined" -> "border-line-strong"
        true -> "border-transparent"
      end

    focus =
      cond do
        variant == "plain" ->
          "focus-within:shadow-none"

        state == "error" ->
          "focus-within:border-neg focus-within:shadow-[0_0_0_3px_color-mix(in_oklab,var(--lu-neg)_25%,transparent)]"

        true ->
          "focus-within:border-accent-500 focus-within:shadow-[0_0_0_3px_var(--lu-focus)]"
      end

    [@frame, bg, border, focus]
  end

  @token ~r/\{\{[^{}]*\}\}/

  attr :field, Phoenix.HTML.FormField, default: nil
  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :any, default: nil

  attr :rows, :integer,
    default: nil,
    doc:
      "Lines shown. Without it the field is the design's 84px (`min-height`); more lines make it taller."

  attr :variant, :string, default: "outlined", values: ~w(outlined filled plain)
  attr :size, :string, default: nil, values: [nil, "sm", "md", "lg"]
  attr :resizable, :boolean, default: false
  attr :counter, :boolean, default: false
  attr :counter_format, :string, default: "%{count} / %{max}"
  attr :counter_align, :string, default: "end", values: ~w(end start)
  attr :min_length, :integer, default: nil
  attr :autogrow, :boolean, default: false

  attr :loop, :boolean,
    default: false,
    doc:
      "Demo animation (CSS only, needs `counter`): the counter counts up (12, 168, 196, warning colours). `value` is not counted."

  attr :max_rows, :integer, default: nil
  attr :tokens, :boolean, default: false
  attr :state, :string, default: nil, values: [nil, "", "success", "error"]
  attr :label, :string, default: nil
  attr :label_class, :any, default: nil
  attr :label_hint, :string, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :disabled, :boolean, default: false
  attr :wrapper_class, :any, default: nil
  attr :frame_class, :any, default: nil
  attr :class, :any, default: nil

  attr :rest, :global,
    include:
      ~w(autocomplete autofocus cols form maxlength minlength placeholder readonly required wrap)

  slot :footer,
    doc: "Content below the text, laid out as a row (`ml-auto` sends an item to the end)."

  slot :header, doc: "Content above the text, laid out as a row."

  @doc "Renders a `<textarea>` inside its frame, with its caption, help and errors."
  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config; the minimum-length counter is Portuguese when none is set."

  def textarea(assigns) do
    assigns = Form.lu_assign_field(assigns)
    errors = assigns.errors
    rest = assigns.rest
    id = assigns.id || (assigns.name && slug(assigns.name))
    loop? = assigns.loop and assigns.counter
    hook? = (assigns.counter and not loop?) or assigns.autogrow or assigns.tokens

    if hook? and id == nil,
      do: raise(ArgumentError, "textarea with counter/autogrow/tokens needs an id (or name)")

    text = if assigns.value == nil, do: "", else: to_string(assigns.value)
    max = to_int(rest[:maxlength])
    # With a counter `maxlength` is a soft limit: the counter warns and turns red past it
    # instead of the browser refusing the characters.
    rest = if assigns.counter, do: Map.delete(rest, :maxlength), else: rest
    count = String.length(text)

    state = if errors != [], do: "error", else: assigns.state
    text_class = @text[assigns.size || "md"]

    frame_class = [frame_class(assigns.variant, state), assigns.frame_class]

    ta_class = [
      "m-0 block w-full flex-1 border-0 bg-transparent leading-[21px] outline-0 placeholder:text-muted placeholder:opacity-85 disabled:cursor-not-allowed disabled:text-muted",
      text_class,
      @min_h[assigns.size || "md"],
      if(assigns.tokens,
        do: "relative [grid-area:1/1] text-transparent caret-ink",
        else: "text-ink"
      ),
      cond do
        assigns.autogrow -> "resize-none overflow-hidden"
        assigns.resizable -> "resize-y"
        true -> "resize-none"
      end
    ]

    ta_attrs = rest

    counter_text =
      counter_text(assigns, count, max, I18n.tp("textarea.min_format", assigns.locale))

    assigns =
      assigns
      |> assign(:tid, id)
      |> assign(:text, text)
      |> assign(:frame_class, frame_class)
      |> assign(:ta_class, ta_class)
      |> assign(:ta_attrs, ta_attrs)
      |> assign(:hook, hook?)
      |> assign(:max, max)
      |> assign(:count_text, if(loop?, do: "", else: counter_text))
      |> assign(:cnt_state, counter_state(count, max))
      |> assign(:cnt_class, [@counter, loop? && @counter_loop])
      |> assign(:cnt_style, loop? && "--post:'#{loop_post(assigns.counter_format, max)}'")
      |> assign(:loop?, loop?)
      |> assign(:bar, @bar)
      |> assign(
        :mirror_class,
        "pointer-events-none relative min-h-0 min-w-0 overflow-hidden leading-[21px] wrap-anywhere whitespace-pre-wrap text-ink [&_code]:rounded-[4px] [&_code]:bg-sunken [&_code]:px-[3px] [&_code]:font-mono [&_code]:text-[12.5px] [&_code]:text-muted " <>
          text_class
      )
      |> assign(:cnt_id, id && id <> "-cnt")
      |> assign(:label_id, assigns.label && id && id <> "-label")
      |> assign(:min_format, I18n.tp("textarea.min_format", assigns.locale))
      |> assign(:parts, if(assigns.tokens, do: parts(text), else: []))
      |> assign(:grow_max, grow_max(assigns))
      |> assign(:start?, assigns.counter and assigns.counter_align == "start")
      |> assign(:end?, assigns.counter and assigns.counter_align == "end")

    ~H"""
    <Form.field
      as="div"
      label={@label}
      label_class={@label_class}
      label_hint={@label_hint}
      label_id={@label_id}
      help={@help}
      errors={@errors}
      state={@state}
      required={@rest[:required] in [true, "true", "required", ""]}
      class={@wrapper_class}
      bare
    >
      <div data-part="textarea" class={@frame_class}>
        <div
          :if={@header != []}
          data-part="textarea-header"
          class={[@bar, "border-b border-line"]}
        >
          {render_slot(@header)}
        </div>
        <div :if={@tokens} data-part="textarea-wrap" class="relative grid">
          <div
            data-part="textarea-mirror"
            class={["[grid-area:1/1]", @mirror_class]}
            aria-hidden="true"
            data-lu-mirror
            phx-no-format
          >{mirror(@parts)}</div>
          <.ta
            tid={@tid}
            text={@text}
            name={@name}
            rows={@rows}
            ta_class={@ta_class}
            ta_attrs={@ta_attrs}
            class={@class}
            disabled={@disabled}
            hook={@hook}
            counter={@counter and not @loop?}
            autogrow={@autogrow}
            tokens={@tokens}
            cnt_id={@cnt_id}
            min_length={@min_length}
            max={@max}
            counter_format={@counter_format}
            min_format={@min_format}
            grow_max={@grow_max}
            label_id={@label_id}
            errors={@errors}
            state={@state}
          />
        </div>
        <.ta
          :if={!@tokens}
          tid={@tid}
          text={@text}
          name={@name}
          rows={@rows}
          ta_class={@ta_class}
          ta_attrs={@ta_attrs}
          class={@class}
          disabled={@disabled}
          hook={@hook}
          counter={@counter and not @loop?}
          autogrow={@autogrow}
          tokens={@tokens}
          cnt_id={@cnt_id}
          min_length={@min_length}
          max={@max}
          counter_format={@counter_format}
          min_format={@min_format}
          grow_max={@grow_max}
          label_id={@label_id}
          errors={@errors}
          state={@state}
        />
        <div
          :if={@footer != []}
          data-part="textarea-footer"
          class={[@bar, "border-t border-line"]}
        >
          {render_slot(@footer)}
        </div>
      </div>
      <:below :if={@start?}>
        <div data-part="textarea-counter-row" class="flex items-baseline gap-2.5">
          <span
            id={@cnt_id}
            data-part="textarea-counter"
            data-state={@cnt_state}
            class={@cnt_class}
            style={@cnt_style}
            aria-live="off"
          >{@count_text}</span>
        </div>
      </:below>
      <:aside :if={@end?}>
        <span
          id={@cnt_id}
          data-part="textarea-counter"
          data-state={@cnt_state}
          class={[@cnt_class, "ml-auto"]}
          style={@cnt_style}
          aria-live="off"
        >{@count_text}</span>
      </:aside>
    </Form.field>
    """
  end

  attr :tid, :string, default: nil
  attr :text, :string, default: ""
  attr :name, :string, default: nil
  attr :rows, :integer, default: nil
  attr :ta_class, :any, default: nil
  attr :ta_attrs, :map, default: %{}
  attr :class, :any, default: nil
  attr :disabled, :boolean, default: false
  attr :hook, :boolean, default: false
  attr :counter, :boolean, default: false
  attr :autogrow, :boolean, default: false
  attr :tokens, :boolean, default: false
  attr :cnt_id, :string, default: nil
  attr :min_length, :integer, default: nil
  attr :max, :integer, default: nil
  attr :counter_format, :string, default: nil
  attr :min_format, :string, default: nil
  attr :grow_max, :integer, default: nil
  attr :label_id, :string, default: nil
  attr :errors, :list, default: []
  attr :state, :string, default: nil

  defp ta(assigns) do
    ~H"""
    <textarea
      id={@tid}
      data-part="textarea-control"
      name={@name}
      rows={@rows}
      class={[@ta_class, @class]}
      disabled={@disabled}
      aria-labelledby={@label_id}
      aria-invalid={(@errors != [] or @state == "error") && "true"}
      phx-hook={@hook && "LedgerUI.Textarea"}
      data-lu-counter={@counter && @cnt_id}
      data-lu-min={@min_length}
      data-lu-max={@max}
      data-lu-format={@counter && @counter_format}
      data-lu-min-format={@counter && @min_format}
      data-lu-autogrow={@autogrow && "true"}
      data-lu-max-rows={@autogrow && @grow_max}
      data-lu-tokens={@tokens && "true"}
      {@ta_attrs}
    >{Phoenix.HTML.Form.normalize_value("textarea", @text)}</textarea>
    """
  end

  # No whitespace between the pieces: the mirror keeps it (`whitespace-pre-wrap`).
  defp mirror(parts) do
    {:safe,
     [
       for {kind, part} <- parts do
         {:safe, esc} = Phoenix.HTML.html_escape(part)
         if kind == :token, do: ["<code>", esc, "</code>"], else: esc
       end,
       "&#8203;"
     ]}
  end

  defp grow_max(%{autogrow: true, max_rows: n}) when is_integer(n), do: n
  defp grow_max(_), do: nil

  # The text after the number of the counter drawn by CSS (`counter(n)` animated through `--lu-n`).
  defp loop_post(format, max) do
    format
    |> String.split("%{count}", parts: 2)
    |> List.last()
    |> String.replace("%{max}", to_string(max || 200))
    |> String.replace(~r/['"\\]/, "")
  end

  defp counter_text(%{counter: false}, _count, _max, _min_format), do: nil

  defp counter_text(%{counter_format: format, min_length: min}, count, max, min_format) do
    cond do
      max -> format |> replace("count", count) |> replace("max", max)
      min -> min_format |> replace("count", count) |> replace("min", min)
      true -> to_string(count)
    end
  end

  defp counter_state(_count, nil), do: nil
  defp counter_state(count, max) when count > max, do: "over"
  defp counter_state(count, max) when count * 10 >= max * 9, do: "warn"
  defp counter_state(_, _), do: nil

  defp replace(text, key, value), do: String.replace(text, "%{#{key}}", to_string(value))

  # Splits the text into `{:text, s}` / `{:token, s}` parts for the mirror behind the textarea.
  @doc false
  def parts(text) do
    tokens = Regex.scan(@token, text)
    texts = Regex.split(@token, text)

    texts
    |> Enum.zip(tokens ++ [nil])
    |> Enum.flat_map(fn
      {t, [tok]} -> [{:text, t}, {:token, tok}]
      {t, nil} -> [{:text, t}]
    end)
  end

  defp to_int(nil), do: nil
  defp to_int(n) when is_integer(n), do: n

  defp to_int(n) when is_binary(n) do
    case Integer.parse(n) do
      {i, _} -> i
      :error -> nil
    end
  end

  defp slug(text), do: text |> String.replace(~r/[^A-Za-z0-9_-]+/u, "-") |> String.trim("-")
end
