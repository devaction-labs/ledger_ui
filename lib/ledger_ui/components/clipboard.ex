defmodule LedgerUI.Components.Clipboard do
  @moduledoc """
  Copy to clipboard: `clipboard/1`, a button that copies a text, and `clipboard_input/1`, a
  field with a copy button joined to it.

      <.clipboard id="copy-ref" value="LDG-2026-1043" icon>Copiar</.clipboard>
      <.clipboard id="copy-cmd" from="#cmd" icon_only variant="ghost" aria-label="Copiar comando" />
      <.clipboard_input id="api-key" value={@api_key} field_label="Chave de API" readonly />

  The buttons are `lu-b` buttons (`lu-b c-<color> v-<variant> s-<size>`). The hook
  `LedgerUI.Clipboard` (`priv/static/ledger_ui/hooks/clipboard.js`) does the copy
  (`navigator.clipboard`, with a `execCommand` fallback), then for two seconds:

    * turns the button into the copied state (`c-success v-soft`, `data-copied`) and shows
      `copied_label` in place of the label when given;
    * dispatches `ledger:toast` on `window` with `%{message, kind}` (`kind` is `"success"` or
      `"error"`) when a `toast` is set. Pass `toast={nil}` for none;
    * runs `on_copy`: an event name (pushed with `%{"id" => id}`, to `target` if given) or a
      `%JS{}`.

  `value` is the text to copy; `from` is a selector whose field value (or text) is copied instead.
  `copied` renders the button already in the copied state.
  """
  use LedgerUI.Component

  @colors ~w(neutral primary secondary info success warning error)
  @variants ~w(solid glow outline soft bordered flat ghost)
  @sizes ~w(xs sm md lg xl)

  @texts %{
    "en" => %{label: "Copy", toast: "Text Copied", error: "Error"},
    "pt_BR" => %{label: "Copiar", toast: "Texto copiado", error: "Erro ao copiar"}
  }

  attr :id, :string, required: true, doc: "Needed by the hook."
  attr :value, :string, default: nil, doc: "The text to copy."
  attr :from, :string, default: nil, doc: "Selector of the field or element whose text is copied."
  attr :locale, :string, default: "en", values: Map.keys(@texts)

  attr :toast, :any,
    default: :default,
    doc: "Shown after a copy; `nil` or `\"\"` for none. By default the locale's text."

  attr :error_toast, :string, default: nil
  attr :copied, :boolean, default: false, doc: "Renders the copied state."
  attr :on_copy, :any, default: nil, doc: "An event name or a `%JS{}`."
  attr :target, :any, default: nil
  attr :copied_label, :string, default: nil
  attr :icon, :boolean, default: false, doc: "A copy icon before the text (a check while copied)."
  attr :icon_only, :boolean, default: false, doc: "Just the icon; give it an `aria-label`."
  attr :color, :string, default: "primary", values: @colors
  attr :variant, :string, default: "solid", values: @variants
  attr :size, :string, default: "md", values: @sizes
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block

  def clipboard(%{copied: true} = assigns) do
    assigns =
      assigns
      |> assign(:classes, cx(["lu-b c-success v-soft", "s-" <> assigns.size, assigns.class]))
      |> assign(:default_label, @texts[assigns.locale].label)
      |> assign(:custom_label?, !empty_slot?(assigns.inner_block))

    ~H"""
    <button id={@id} data-part="clipboard" type="button" class={@classes} {@rest}>
      <.icon :if={@icon or @icon_only} name="check" size="sm" />
      <%= if !@icon_only do %>
        <%= if @copied_label do %>
          {@copied_label}
        <% else %>
          <%= if @custom_label? do %>
            {render_slot(@inner_block)}
          <% else %>
            {@default_label}
          <% end %>
        <% end %>
      <% end %>
    </button>
    """
  end

  def clipboard(assigns) do
    assigns =
      assigns
      |> assign(:classes, button_classes(assigns))
      |> assign(:default_label, @texts[assigns.locale].label)
      |> assign(:custom_label?, !empty_slot?(assigns.inner_block))
      |> assign(:toast_s, toast(assigns))
      |> assign(:error_s, error_toast(assigns))
      |> assign(:on_event, if(is_binary(assigns.on_copy), do: assigns.on_copy))
      |> assign(:on_js, if(is_struct(assigns.on_copy, JS), do: assigns.on_copy))

    ~H"""
    <button
      id={@id}
      data-part="clipboard"
      type="button"
      class={@classes}
      data-lu-copy={@value}
      data-lu-copy-from={@from}
      data-lu-toast={@toast_s}
      data-lu-error={@error_s}
      data-lu-copied-label={@copied_label}
      data-lu-on-copy={@on_event}
      data-lu-on-copy-js={@on_js}
      data-lu-target={@target}
      phx-hook="LedgerUI.Clipboard"
      {@rest}
    >
      <.icon :if={@icon or @icon_only} name="copy" size="sm" /><span
        :if={!@icon_only}
        class="lu-copy-label"
      ><%= if @custom_label? do %>
        {render_slot(@inner_block)}
      <% else %>
        {@default_label}
      <% end %></span>
    </button>
    """
  end

  defp empty_slot?(slot) do
    Enum.all?(slot, fn
      %{inner_block: %{static: [text]}} -> String.trim(text) == ""
      _ -> false
    end)
  end

  defp button_classes(a) do
    cx(["lu-b", "c-" <> a.color, "v-" <> a.variant, "s-" <> a.size, a.class])
  end

  defp error_toast(%{error_toast: e}) when is_binary(e), do: e
  defp error_toast(a), do: if(toast(a), do: @texts[a.locale].error)

  defp toast(%{toast: :default, locale: locale}), do: @texts[locale].toast
  defp toast(%{toast: t}) when t in [nil, ""], do: nil
  defp toast(%{toast: t}), do: t

  # ---------------------------------------------------------------------------------------------

  attr :id, :string, required: true, doc: "The id of the input; the button is `<id>-copy`."
  attr :name, :string, default: nil
  attr :value, :string, default: nil
  attr :placeholder, :string, default: nil
  attr :label, :string, default: nil, doc: "The button's text; by default the locale's."
  attr :field_label, :string, default: nil, doc: "The label above the field."
  attr :leading_icon, :string, default: nil, doc: "An icon at the start of the field."
  attr :copied_label, :string, default: nil
  attr :icon, :boolean, default: true, doc: "A copy icon before the label."
  attr :locale, :string, default: "en", values: Map.keys(@texts)
  attr :toast, :any, default: :default
  attr :error_toast, :string, default: nil
  attr :on_copy, :any, default: nil
  attr :target, :any, default: nil
  attr :class, :any, default: nil, doc: "Merged into the wrapper."
  attr :rest, :global, include: ~w(readonly disabled autocomplete form phx-debounce)

  def clipboard_input(assigns) do
    assigns =
      assigns
      |> assign(:classes, cx(["lu-field", assigns.class]))
      |> assign(:label_s, assigns.label || @texts[assigns.locale].label)
      |> assign(:button_id, assigns.id <> "-copy")
      |> assign(:selector, "#" <> assigns.id)

    ~H"""
    <label data-part="clipboard-input" class={@classes}>
      <span :if={@field_label} class="lu-label">{@field_label}</span>
      <span class="lu-input">
        <span :if={@leading_icon} class="addon sep"><.icon name={@leading_icon} size="md" /></span>
        <input
          id={@id}
          name={@name}
          value={@value}
          placeholder={@placeholder}
          style="font-family:var(--font-mono);font-size:13px"
          {@rest}
        />
        <.clipboard
          id={@button_id}
          from={@selector}
          color="neutral"
          variant="soft"
          size="sm"
          icon={@icon}
          locale={@locale}
          toast={@toast}
          error_toast={@error_toast}
          on_copy={@on_copy}
          target={@target}
          copied_label={@copied_label}
        >
          {@label_s}
        </.clipboard>
      </span>
    </label>
    """
  end
end
