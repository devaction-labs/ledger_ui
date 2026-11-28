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

  # colour of the filled bars at each level (the others are `bg-selected`)
  @levels %{
    1 => "bg-neg",
    2 => "bg-warn",
    3 => "bg-accent-500",
    4 => "bg-pos"
  }

  attr :level, :integer, required: true

  defp meter(assigns) do
    ~H"""
    <div
      data-part="password-meter"
      data-level={@level}
      class="mt-1 flex gap-1"
    >
      <i
        :for={n <- 1..4}
        data-part="password-meter-bar"
        class={[
          "h-1 flex-1 rounded-[2px]",
          if(n <= @level, do: levels()[@level], else: "bg-selected")
        ]}
      ></i>
    </div>
    """
  end

  defp levels, do: @levels

  # The ids are used in CSS selectors (`#id`): a name like `login[password]` would break them.
  defp safe_id(id) do
    if valid_id?(id) do
      id
    else
      "lu-pw-" <> (id |> squash_id() |> String.trim("-"))
    end
  end

  # `\A[A-Za-z_][A-Za-z0-9_-]*\z` without the regex (it ran on every render).
  defp valid_id?(<<c, rest::binary>>) when c in ?a..?z or c in ?A..?Z or c == ?_,
    do: id_tail?(rest)

  defp valid_id?(_), do: false

  defp id_tail?(<<c, rest::binary>>)
       when c in ?a..?z or c in ?A..?Z or c in ?0..?9 or c in [?_, ?-],
       do: id_tail?(rest)

  defp id_tail?(""), do: true
  defp id_tail?(_), do: false

  # `String.replace(name, ~r/[^A-Za-z0-9_-]+/, "-")` without the regex (it ran on every render): each
  # run of other bytes becomes one "-".
  defp squash_id(bin), do: squash_id(bin, "", false)
  defp squash_id("", acc, _), do: acc

  defp squash_id(<<c, rest::binary>>, acc, _)
       when c in ?a..?z or c in ?A..?Z or c in ?0..?9 or c in [?_, ?-],
       do: squash_id(rest, <<acc::binary, c>>, false)

  defp squash_id(<<_, rest::binary>>, acc, true), do: squash_id(rest, acc, true)
  defp squash_id(<<_, rest::binary>>, acc, false), do: squash_id(rest, <<acc::binary, ?->>, true)

  attr :id, :string,
    default: nil,
    doc:
      "Defaults to the field id, then `name`; characters that break a CSS selector are replaced."

  attr :show_label, :string, default: nil
  attr :hide_label, :string, default: nil
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

  attr :visible, :boolean,
    default: false,
    doc: "Starts with the text shown (the eye crossed out); the button hides it."

  attr :loop, :boolean,
    default: false,
    doc:
      "Demo animation (CSS only): the dots and the text of `value` swap by themselves. The field is `type=\"text\"` and the dots are drawn over it."

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
  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def password_input(assigns) do
    changed0 = assigns.__changed__
    assigns = I18n.texts(assigns, show_label: "password.show", hide_label: "password.hide")

    assigns = Form.lu_assign_field(assigns)
    id = safe_id(assigns.id || assigns.name || "password-input")
    # JS.toggle_attribute swaps between the two values on each click.
    toggle =
      %JS{}
      |> JS.toggle_attribute({"type", "password", "text"}, to: "##{id}")
      |> JS.toggle_attribute({"aria-label", assigns.show_label, assigns.hide_label})
      |> JS.toggle_attribute({"aria-pressed", "false", "true"})
      |> JS.toggle(to: "##{id}-eye", display: "inline-block")
      |> JS.toggle(to: "##{id}-eye-off", display: "inline-block")

    loop? = assigns.loop
    value = assigns.value

    assigns =
      assigns
      |> assign(:dots, String.duplicate("•", max(String.length(to_string(value || "")), 1)))
      |> assign(:type, if(loop? or assigns.visible, do: "text", else: "password"))
      |> assign(:box_class, [
        assigns.class,
        loop? && "[&_input]:animate-[lu-sw-b_5s_ease-in-out_infinite] [&_input]:opacity-0"
      ])
      |> assign(:pid, id)
      |> assign(:meter, @meter[assigns.strength])
      |> assign(:toggle, toggle)

    # The JS of the eye button is rebuilt on each call: it goes again only when the id or the two
    # labels change (the translated ones are tracked by `I18n.texts/2`).
    assigns =
      settle(assigns, changed0,
        dots: [:value, :field],
        type: [:loop, :visible],
        box_class: [:class, :loop],
        pid: [:id, :name, :field],
        meter: [:strength],
        toggle: [:id, :name, :field, :show_label, :hide_label]
      )

    ~H"""
    <Input.input
      id={@pid}
      type={@type}
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
      class={@box_class}
      icon="lock"
      {@rest}
    >
      <:leading :if={@loop}>
        <span class="relative -mr-2 w-0 self-stretch" aria-hidden="true" data-part="password-dots">
          <span class="absolute top-0 left-0 flex h-full items-center text-[18px] leading-none tracking-[3px] whitespace-nowrap text-ink animate-[lu-sw-a_5s_ease-in-out_infinite]">{@dots}</span>
        </span>
      </:leading>
      <:label_aside :if={@label_aside != []}>{render_slot(@label_aside)}</:label_aside>
      <:below :if={@below != [] or @meter}>
        <.meter :if={@meter} level={@meter} />
        {render_slot(@below)}
      </:below>
      <:trailing>
        <button
          type="button"
          data-part="password-toggle"
          class="-mr-1.5 grid size-7 cursor-pointer place-items-center rounded-[7px] border-0 bg-transparent text-muted hover:bg-hover hover:text-ink"
          aria-label={if @visible, do: @hide_label, else: @show_label}
          aria-pressed={to_string(@visible)}
          aria-controls={@pid}
          disabled={@disabled}
          phx-click={@toggle}
        >
          <.icon id={"#{@pid}-eye"} name="eye" size="md" style={@visible && "display:none"} />
          <.icon id={"#{@pid}-eye-off"} name="eye-off" size="md" style={!@visible && "display:none"} />
        </button>
      </:trailing>
    </Input.input>
    """
  end
end
