defmodule LedgerUI.Components.TimePicker do
  @moduledoc """
  Time picker: an input with a clock icon that opens a scrollable list of times
  (`variant="input"`), or a list of fixed slots (`variant="list"`).

      <.time_picker field={@form[:opens_at]} placeholder="Choose time..." />
      <.time_picker name="alarm" time_24hr min_time="15:00" max_time="22:30" minute_step={15} />
      <.time_picker field={@form[:slot]} variant="list" min_time="14:00" max_time="14:45" minute_step={15} />

  The form gets `"HH:MM"` (24-hour) through a hidden input named like the field and every change
  fires a bubbling `input` event, so `phx-change` runs. The behaviour lives in the
  `LedgerUI.TimePicker` hook (`priv/static/ledger_ui/hooks/time_picker.js`).

  `time_picker_panel/1` renders only the popup surface (a popover with the list of times).
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Form
  import LedgerUI.Components.DatePicker, only: [field_assigns: 1, pop_class: 0]
  import LedgerUI.Components.Input, only: [input: 1]

  # the list of times, and one time button (the chosen one has `aria-checked`)
  @list "flex max-h-[220px] flex-col gap-0.5 overflow-auto p-1"
  @slot "h-8 cursor-pointer rounded-[8px] border-0 bg-transparent font-mono text-[13.5px] text-ink-2 hover:bg-hover aria-checked:bg-inverse aria-checked:text-on-inverse " <>
          "focus-visible:shadow-[0_0_0_3px_var(--lu-focus)] focus-visible:outline-none"

  @labels %{
    "en" => %{
      picker_time_dialog: "Choose time",
      picker_hour: "Hour",
      picker_minute: "Minute",
      picker_hour_up: "Increase hour",
      picker_hour_down: "Decrease hour",
      picker_minute_up: "Increase minute",
      picker_minute_down: "Decrease minute",
      picker_toggle_period: "Toggle AM/PM"
    },
    "pt_BR" => %{
      picker_time_dialog: "Escolher horário",
      picker_hour: "Hora",
      picker_minute: "Minuto",
      picker_hour_up: "Aumentar hora",
      picker_hour_down: "Diminuir hora",
      picker_minute_up: "Aumentar minuto",
      picker_minute_down: "Diminuir minuto",
      picker_toggle_period: "Alternar AM/PM"
    }
  }

  @doc false
  # Class strings of the list of times and of one time button (also drawn by `datetime_picker`'s hook).
  def list_class, do: @list
  @doc false
  def slot_class, do: @slot

  @doc false
  # Minutes since midnight of a `Time` or "HH:MM"; `nil` when not a time.
  def minutes(%Time{hour: h, minute: m}), do: h * 60 + m
  def minutes(%NaiveDateTime{hour: h, minute: m}), do: h * 60 + m

  def minutes(<<h::binary-size(2), ":", m::binary-size(2), _::binary>>) do
    with {hh, ""} when hh in 0..23 <- Integer.parse(h),
         {mm, ""} when mm in 0..59 <- Integer.parse(m) do
      hh * 60 + mm
    else
      _ -> nil
    end
  end

  def minutes(<<h::binary-size(1), ":", m::binary-size(2)>>), do: minutes("0" <> h <> ":" <> m)
  def minutes(_), do: nil

  @doc false
  def hhmm(nil), do: ""
  def hhmm(min), do: "#{pad(div(min, 60))}:#{pad(rem(min, 60))}"

  @doc false
  # "9:30 AM" / "09:30".
  def display(nil, _24h), do: ""
  def display(min, true), do: hhmm(min)

  def display(min, false) do
    h = div(min, 60)

    "#{if rem(h, 12) == 0, do: 12, else: rem(h, 12)}:#{pad(rem(min, 60))} #{if h < 12, do: "AM", else: "PM"}"
  end

  defp pad(n), do: n |> Integer.to_string() |> String.pad_leading(2, "0")

  # ---------------------------------------------------------------------------------------
  # <.time_picker_panel>
  # ---------------------------------------------------------------------------------------

  attr :times, :list, default: [], doc: "The `\"HH:MM\"` texts of the buttons."
  attr :value, :any, default: nil, doc: "The chosen time (`\"HH:MM\"`) highlighted."
  attr :class, :any, default: nil
  attr :rest, :global

  @doc "The popup surface: a popover with the list of times."
  def time_picker_panel(assigns) do
    assigns =
      assigns
      |> assign(:on, assigns.value && hhmm(minutes(assigns.value)))
      |> assign(:pop, pop_class())
      |> assign(:list, @list)
      |> assign(:slot_cls, @slot)

    ~H"""
    <div data-part="time-picker-panel" class={[@pop, "p-[5px]", @class]} {@rest}>
      <div data-part="time-picker-list" class={@list}>
        <button
          :for={t <- @times}
          data-part="time-picker-slot"
          class={@slot_cls}
          role="radio"
          aria-checked={to_string(t == @on)}
          type="button"
        >
          {t}
        </button>
      </div>
    </div>
    """
  end

  # ---------------------------------------------------------------------------------------
  # <.time_picker>
  # ---------------------------------------------------------------------------------------

  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :any
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :label, :string, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :placeholder, :string, default: nil
  attr :time_24hr, :boolean, default: false
  attr :min_time, :string, default: nil
  attr :max_time, :string, default: nil
  attr :minute_step, :integer, default: 5
  attr :step, :integer, default: nil, doc: "The same as `minute_step`; it wins when given."
  attr :hour_step, :integer, default: 1
  attr :default_hour, :integer, default: 12
  attr :display_format, :string, default: nil
  attr :locale, :string, default: "en", values: ~w(en pt_BR)
  attr :labels, :map, default: %{}
  attr :variant, :string, default: "input", values: ~w(input list)
  attr :show_icon, :boolean, default: true
  attr :disabled, :boolean, default: false
  attr :on_change, :string, default: nil
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :icon, doc: "Replaces the clock icon."
  slot :trailing, doc: "Buttons joined to the right of the input."

  @doc "Renders a time input."
  def time_picker(assigns) do
    assigns = assigns |> Map.new() |> field_assigns()
    lang = if assigns.locale == "pt_BR", do: "pt_BR", else: "en"
    value = minutes(assigns.value)
    id = assigns.id || assigns.name || "time-picker"
    lo = minutes(assigns.min_time) || 0
    hi = minutes(assigns.max_time) || 24 * 60 - 1
    step = max(assigns.step || assigns.minute_step, 1)

    config = %{
      variant: assigns.variant,
      h24: assigns.time_24hr,
      format: assigns.display_format,
      min: lo,
      max: hi,
      step: step,
      defaultHour: assigns.default_hour,
      labels:
        Map.new(Map.merge(@labels[lang], assigns.labels), fn {k, v} -> {to_string(k), v} end),
      onChange: assigns.on_change,
      target: if(assigns.target, do: to_string(assigns.target)),
      classes: %{slot: @slot}
    }

    assigns =
      assigns
      |> assign(:id, id)
      |> assign(:config, Jason.encode!(config))
      |> assign(:hhmm, hhmm(value))
      |> assign(:text, display(value, assigns.time_24hr))
      |> assign(:dialog_label, Map.merge(@labels[lang], assigns.labels).picker_time_dialog)
      |> assign(
        :slots,
        if(assigns.variant == "list", do: slots(lo, hi, step, assigns.time_24hr), else: [])
      )
      |> assign(:selected, value)

    assigns =
      assigns
      |> assign(:pop, pop_class())
      |> assign(:list, @list)
      |> assign(:slot_cls, @slot)
      |> assign(:state, if(assigns.errors != [], do: "error"))

    ~H"""
    <div
      id={@id <> "-picker"}
      data-part="time-picker"
      phx-hook="LedgerUI.TimePicker"
      data-lu-config={@config}
      class="relative flex min-w-0 flex-col gap-1.5"
      {@rest}
    >
      <Form.label :if={@label}>{@label}</Form.label>
      <input type="hidden" name={@name} value={@hhmm} disabled={@disabled} data-value />
      <%= if @variant == "input" do %>
        <.input
          id={@id}
          autocomplete="off"
          placeholder={@placeholder}
          value={@text}
          disabled={@disabled}
          state={@state}
          class={@class}
          icon={(@show_icon and @trailing == [] and @icon == []) && "clock"}
          aria-haspopup="dialog"
          aria-expanded="false"
          aria-controls={@id <> "-pop"}
        >
          <:leading :if={@show_icon and @trailing == [] and @icon != []}>
            {render_slot(@icon)}
          </:leading>
          <:trailing :if={@trailing != []}>{render_slot(@trailing)}</:trailing>
        </.input>
        <div
          id={@id <> "-pop"}
          role="dialog"
          aria-label={@dialog_label}
          hidden
          keep-hidden
          class="absolute top-full left-0 z-50 mt-1 w-[140px]"
        >
          <div data-part="time-picker-panel" class={[@pop, "p-[5px]"]}>
            <div data-part="time-picker-list" class={@list}></div>
          </div>
        </div>
      <% else %>
        <div
          data-part="time-picker-panel"
          class={@pop}
          role="radiogroup"
          aria-label={@label || @dialog_label}
        >
          <div data-part="time-picker-list" class={@list}>
            <button
              :for={{m, text} <- @slots}
              data-part="time-picker-slot"
              class={@slot_cls}
              type="button"
              role="radio"
              aria-checked={to_string(m == @selected)}
              data-value={hhmm(m)}
              disabled={@disabled}
            >
              {text}
            </button>
          </div>
        </div>
      <% end %>
      <Form.error :for={e <- @errors}>{e}</Form.error>
      <Form.help_text :if={@help}>{@help}</Form.help_text>
    </div>
    """
  end

  defp slots(lo, hi, step, h24), do: for(m <- lo..hi//step, do: {m, display(m, h24)})
end
