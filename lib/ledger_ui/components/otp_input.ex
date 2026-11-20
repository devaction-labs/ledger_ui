defmodule LedgerUI.Components.OtpInput do
  @moduledoc """
  A one-time code made of single-character boxes.

      <.otp_input field={@form[:code]} label="Codigo de 6 digitos" />
      <.otp_input name="pin" length={4} mask autofocus />
      <.otp_input field={@form[:code]} separator={3} on_complete="verify" />
      <.otp_input name="invite" mode="alphanumeric" length={8} size="lg" />

  Typing fills a box and moves to the next, Backspace on an empty box goes back and empties the
  previous one, the arrows, Home and End move between boxes, and a paste or an autofill spreads
  its characters over the boxes. Characters the `mode` does not allow are dropped.

  The boxes have no `name`: a hidden input named like the field carries the joined code and fires
  a bubbling `input` event whenever it changes, so a surrounding `phx-change` receives
  `%{"name" => "482913"}` (a partial code while it is typed). A `value` the server sends later
  wins over the one in the browser (render `value=""` to clear a rejected code).

  `on_complete` is an event name or a `%JS{}`; it is sent to `target` (or the LiveView) each time
  the code changes while every box is filled, with `%{"id" => id, "name" => name, "value" => code}`.

  The behaviour lives in the `LedgerUI.Otp` hook (file `otp.js`), so the component needs a stable
  `id` (from `field` or `name`).
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Form

  @styles %{
    "size" => %{"sm" => "sm", "md" => "md", "lg" => "lg", nil => nil},
    "state" => %{"success" => "ok", "error" => "err"}
  }

  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :any, default: nil
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :label, :string, default: nil
  attr :label_class, :any, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :state, :string, default: nil, values: [nil, "", "success", "error"]
  attr :length, :integer, default: 6
  attr :mode, :string, default: "numeric", values: ~w(numeric alphanumeric)
  attr :size, :string, default: nil, values: [nil, "sm", "md", "lg"]
  attr :mask, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :autofocus, :boolean, default: false
  attr :separator, :any, default: nil
  attr :on_complete, :any, default: nil
  attr :target, :any, default: nil
  attr :aria_label, :string, default: "One-time code"
  attr :digit_label, :string, default: "Digit"
  attr :wrapper_class, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  @doc "Renders the boxes, with their caption, help and errors when given."
  def otp_input(assigns) do
    assigns = Form.lu_assign_field(assigns)
    errors = assigns.errors
    id = assigns.id || (assigns.name && String.replace(assigns.name, ~r/[^A-Za-z0-9_-]+/u, "-"))
    if id == nil, do: raise(ArgumentError, "otp_input needs an id (or name or field)")

    chars =
      assigns.value
      |> to_string()
      |> String.graphemes()
      |> Enum.take(assigns.length)

    code = Enum.join(chars)
    seps = separators(assigns.separator, assigns.length)

    boxes =
      for i <- 0..(assigns.length - 1)//1 do
        %{
          index: i,
          char: Enum.at(chars, i),
          sep_before: MapSet.member?(seps, i),
          label: "#{assigns.digit_label} #{i + 1}"
        }
      end

    {on_event, on_js} =
      case assigns.on_complete do
        nil -> {nil, nil}
        %JS{} = js -> {nil, js}
        event when is_binary(event) -> {event, nil}
      end

    assigns =
      assigns
      |> assign(:oid, id)
      |> assign(:code, code)
      |> assign(:boxes, boxes)
      |> assign(:label_id, assigns.label && id <> "-label")
      |> assign(:group_label, if(assigns.label, do: nil, else: assigns.aria_label))
      |> assign(
        :row_class,
        cx([
          "lu-otp2",
          @styles["size"][assigns.size],
          Form.lu_state_class(assigns.state, errors),
          assigns.disabled && "dis"
        ])
      )
      |> assign(:invalid, errors != [] or assigns.state == "error")
      |> assign(:on_event, on_event)
      |> assign(:on_js, on_js)
      |> assign(:input_type, if(assigns.mask, do: "password", else: "text"))
      |> assign(:inputmode, if(assigns.mode == "numeric", do: "numeric", else: "text"))
      |> assign(:data_target, target(assigns.target))

    ~H"""
    <Form.field
      as="div"
      label={@label}
      label_class={@label_class}
      label_id={@label_id}
      help={@help}
      errors={@errors}
      state={@state}
      class={@wrapper_class}
      bare
    >
      <div
        data-part="otp"
        id={@oid}
        role="group"
        class={@row_class}
        aria-label={@group_label}
        aria-labelledby={@label_id}
        aria-invalid={@invalid && "true"}
        phx-hook="LedgerUI.Otp"
        data-lu-length={@length}
        data-lu-mode={@mode}
        data-lu-value={@code}
        data-lu-autofocus={@autofocus && "true"}
        data-lu-on-complete={@on_event}
        data-lu-on-complete-js={@on_js}
        data-lu-target={@data_target}
        {@rest}
      >
        <%= for box <- @boxes do %>
          <span :if={box.sep_before} class="dash" aria-hidden="true"></span>
          <i data-lu-filled={box.char != nil && "true"}>
            <input
              type={@input_type}
              inputmode={@inputmode}
              autocomplete="one-time-code"
              aria-label={box.label}
              value={box.char}
              disabled={@disabled}
              class={@class}
              data-lu-otp-box
            />
          </i>
        <% end %>
        <input type="hidden" name={@name} value={@code} data-lu-otp-value />
      </div>
    </Form.field>
    """
  end

  # Positions (box indexes) that get a dash right before them.
  defp separators(nil, _), do: MapSet.new()
  defp separators(n, len) when is_integer(n), do: separators([n], len)

  defp separators(list, len) when is_list(list),
    do: list |> Enum.filter(&(is_integer(&1) and &1 > 0 and &1 < len)) |> MapSet.new()

  defp target(nil), do: nil
  defp target(%Phoenix.LiveComponent.CID{cid: cid}), do: to_string(cid)
  defp target(other), do: to_string(other)
end
