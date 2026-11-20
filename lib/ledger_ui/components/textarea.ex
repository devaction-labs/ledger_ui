defmodule LedgerUI.Components.Textarea do
  @moduledoc """
  Multi-line text field: `outlined`, `filled` or `plain`, fixed or resizable, with a live
  character counter, autogrow, `{{token}}` highlighting and optional header/footer bars.

      <.textarea field={@form[:bio]} label="Bio" variant="filled" resizable />
      <.textarea name="note" maxlength={200} counter autogrow max_rows={8} />
      <.textarea name="why" counter min_length={20} counter_format="%{count} de %{max}" />
      <.textarea name="msg" tokens value="A fatura {{fatura.numero}} esta atrasada." />

      <.textarea name="post" rows={5}>
        <:header><span class="lu-xs lu-muted">Variaveis</span></:header>
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

  @styles %{
    "variant" => %{"outlined" => nil, "filled" => "filled", "plain" => "plain"},
    "size" => %{"sm" => "s-sm", "md" => "s-md", "lg" => "s-lg", nil => nil},
    "state" => %{"success" => "ok", "error" => "err"}
  }

  @token ~r/\{\{[^{}]*\}\}/

  attr :field, Phoenix.HTML.FormField, default: nil
  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :any, default: nil

  attr :rows, :integer,
    default: 3,
    doc:
      "Lines shown. The design's field is 84px high (3 lines of 21px, `min-height`): more lines make it taller."

  attr :variant, :string, default: "outlined", values: ~w(outlined filled plain)
  attr :size, :string, default: nil, values: [nil, "sm", "md", "lg"]
  attr :resizable, :boolean, default: false
  attr :counter, :boolean, default: false
  attr :counter_format, :string, default: "%{count} / %{max}"
  attr :counter_align, :string, default: "end", values: ~w(end start)
  attr :min_length, :integer, default: nil
  attr :autogrow, :boolean, default: false
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

  slot :footer, doc: "Content below the text, laid out as a row (a `lu-cnt` goes to the end)."
  slot :header, doc: "Content above the text, laid out as a row."

  @doc "Renders a `<textarea>` inside the `lu-ta` frame, with its caption, help and errors."
  def textarea(assigns) do
    assigns = Form.lu_assign_field(assigns)
    errors = assigns.errors
    rest = assigns.rest
    id = assigns.id || (assigns.name && slug(assigns.name))
    hook? = assigns.counter or assigns.autogrow or assigns.tokens

    if hook? and id == nil,
      do: raise(ArgumentError, "textarea with counter/autogrow/tokens needs an id (or name)")

    text = if assigns.value == nil, do: "", else: to_string(assigns.value)
    max = to_int(rest[:maxlength])
    # With a counter `maxlength` is a soft limit: the counter warns and turns red past it
    # instead of the browser refusing the characters.
    rest = if assigns.counter, do: Map.delete(rest, :maxlength), else: rest
    count = String.length(text)

    frame_class =
      cx([
        "lu-ta",
        @styles["variant"][assigns.variant],
        @styles["size"][assigns.size],
        Form.lu_state_class(assigns.state, errors),
        assigns.frame_class
      ])

    ta_class =
      cx([
        "tx",
        assigns.tokens && "tk",
        assigns.autogrow && "grow",
        assigns.resizable && !assigns.autogrow && "rz"
      ])

    ta_attrs =
      rest
      |> Map.put_new(:"phx-focus", JS.add_class("focus", to: {:closest, ".lu-ta"}))
      |> Map.put_new(:"phx-blur", JS.remove_class("focus", to: {:closest, ".lu-ta"}))

    counter_text = counter_text(assigns, count, max)

    assigns =
      assigns
      |> assign(:tid, id)
      |> assign(:text, text)
      |> assign(:frame_class, frame_class)
      |> assign(:ta_class, ta_class)
      |> assign(:ta_attrs, ta_attrs)
      |> assign(:hook, hook?)
      |> assign(:max, max)
      |> assign(:count_text, counter_text)
      |> assign(:cnt_class, cx(["lu-cnt", counter_class(count, max)]))
      |> assign(:cnt_id, id && id <> "-cnt")
      |> assign(:label_id, assigns.label && id && id <> "-label")
      |> assign(:min_format, "%{count} / %{min} mín.")
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
        <div :if={@header != []} class="bar top">{render_slot(@header)}</div>
        <div :if={@tokens} class="tx-wrap">
          <div class="tx tx-mirror" aria-hidden="true" data-lu-mirror>
            <%= for {kind, part} <- @parts do %>
              <code :if={kind == :token}>{part}</code>
              <%= if kind == :text do %>
                {part}
              <% end %>
            <% end %>&#8203;
          </div>
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
            counter={@counter}
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
          counter={@counter}
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
        <div :if={@footer != []} class="bar">
          {render_slot(@footer)}
        </div>
      </div>
      <:below :if={@start?}>
        <div class="lu-helprow lu-ta-c start">
          <span id={@cnt_id} class={@cnt_class} style="margin-left:0" aria-live="off">{@count_text}</span>
        </div>
      </:below>
      <:aside :if={@end?}>
        <span id={@cnt_id} class={@cnt_class} aria-live="off">{@count_text}</span>
      </:aside>
    </Form.field>
    """
  end

  attr :tid, :string, default: nil
  attr :text, :string, default: ""
  attr :name, :string, default: nil
  attr :rows, :integer, default: 3
  attr :ta_class, :string, default: "tx"
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
      name={@name}
      rows={@rows}
      class={cx([@ta_class, @class])}
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

  defp grow_max(%{autogrow: true, max_rows: n}) when is_integer(n), do: n
  defp grow_max(_), do: nil

  defp counter_text(%{counter: false}, _count, _max), do: nil

  defp counter_text(%{counter_format: format, min_length: min}, count, max) do
    cond do
      max -> format |> replace("count", count) |> replace("max", max)
      min -> "%{count} / %{min} mín." |> replace("count", count) |> replace("min", min)
      true -> to_string(count)
    end
  end

  defp counter_class(_count, nil), do: nil
  defp counter_class(count, max) when count > max, do: "over"
  defp counter_class(count, max) when count * 10 >= max * 9, do: "warn"
  defp counter_class(_, _), do: nil

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
