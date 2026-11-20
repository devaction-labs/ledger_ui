defmodule LedgerUI.Components.PasswordInput do
  @moduledoc """
  A password field with the eye button that shows what was typed.

      <.password_input name="password" placeholder="Enter password" />
      <.password_input field={@form[:password]} label="Senha" autocomplete="new-password" />

  It is an `input/1` of `type="password"` (it takes every attr of `input/1`) with a lock at the
  start and an eye at the end. The button flips the `type` between `password` and `text`, swaps
  the icon and the accessible name with `Phoenix.LiveView.JS`, so it needs no hook.
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Form
  alias LedgerUI.Components.Input

  @meter %{"weak" => 1, "fair" => 2, "good" => 3, "strong" => 4}

  attr :id, :string, default: nil, doc: "Defaults to the field id, then `name`."
  attr :show_label, :string, default: "Show the password"
  attr :hide_label, :string, default: "Hide the password"
  attr :class, :any, default: nil
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :name, :string, default: nil
  attr :value, :any, default: nil
  attr :label, :string, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :placeholder, :string, default: nil
  attr :disabled, :boolean, default: false
  attr :size, :string, default: "md", values: ~w(sm md lg)
  attr :variant, :string, default: "outlined", values: ~w(outlined filled plain)
  attr :state, :string, default: nil, values: [nil, "", "success", "error"]

  attr :strength, :string,
    default: nil,
    values: [nil, "weak", "fair", "good", "strong"],
    doc: "Draws the strength meter (1 to 4 bars) under the field; scoring the password is yours."

  attr :autocomplete, :string, default: nil
  attr :required, :boolean, default: nil
  attr :minlength, :integer, default: nil
  attr :maxlength, :integer, default: nil
  attr :form, :string, default: nil
  attr :rest, :global, include: ~w(label_hint layout wrapper_class shape align readonly)
  slot :below
  slot :label_aside

  @doc "Renders the field and the eye."
  def password_input(assigns) do
    assigns = Form.lu_assign_field(assigns)
    id = assigns.id || assigns.name || "password-input"
    # JS.toggle_attribute swaps between the two values on each click.
    toggle =
      %JS{}
      |> JS.toggle_attribute({"type", "password", "text"}, to: "##{id}")
      |> JS.toggle_attribute({"aria-label", assigns.show_label, assigns.hide_label})
      |> JS.toggle_attribute({"aria-pressed", "false", "true"})
      |> JS.toggle(to: "##{id}-eye", display: "inline-block")
      |> JS.toggle(to: "##{id}-eye-off", display: "inline-block")

    assigns =
      assigns
      |> assign(:pid, id)
      |> assign(:meter, @meter[assigns.strength])
      |> assign(:toggle, toggle)

    ~H"""
    <Input.input
      id={@pid}
      type="password"
      name={@name}
      value={@value}
      label={@label}
      help={@help}
      errors={@errors}
      placeholder={@placeholder}
      disabled={@disabled}
      size={@size}
      variant={@variant}
      state={@state}
      autocomplete={@autocomplete}
      required={@required}
      minlength={@minlength}
      maxlength={@maxlength}
      form={@form}
      class={@class}
      icon="lock"
      {@rest}
    >
      <:label_aside :if={@label_aside != []}>{render_slot(@label_aside)}</:label_aside>
      <:below :if={@below != [] or @meter}>
        <div :if={@meter} class={"lu-meterpw l#{@meter}"} style="margin-top:4px">
          <i></i><i></i><i></i><i></i>
        </div>
        {render_slot(@below)}
      </:below>
      <:trailing>
        <button
          type="button"
          data-part="password-toggle"
          class="-mr-1.5 grid size-7 cursor-pointer place-items-center rounded-[7px] border-0 bg-transparent text-muted hover:bg-hover hover:text-ink"
          aria-label={@show_label}
          aria-pressed="false"
          aria-controls={@pid}
          disabled={@disabled}
          phx-click={@toggle}
        >
          <.icon id={"#{@pid}-eye"} name="eye" />
          <.icon id={"#{@pid}-eye-off"} name="eye-off" style="display:none" />
        </button>
      </:trailing>
    </Input.input>
    """
  end
end
