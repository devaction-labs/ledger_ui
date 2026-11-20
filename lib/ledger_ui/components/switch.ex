defmodule LedgerUI.Components.Switch do
  @moduledoc """
  A switch (`lu-sw`): a checkbox drawn as a track and thumb, for an effect that is immediate.

      <.switch name="notify" label="Notifications" color="primary" />
      <.switch field={@form[:public]} label="Public" variant="outline" color="success" filled />
      <.switch name="dense" size="sm" shape="pill" thumb_inset={4} checked />
      <.switch name="email" label="Email" label_position="left" wrapper_class="w-full justify-between" />

  With a `name` (or `field`) the switch holds a real, visually hidden checkbox (so the form,
  the keyboard and `phx-change` work) and, like `checkbox/1`, sends `unchecked_value` through a
  hidden input when off. The track and `aria-checked` flip in the browser with
  `Phoenix.LiveView.JS`, no round trip; without a name the label itself is the click target.

  `shape` is `squircle` (the default look) or `pill`. `thumb_inset` (2..6 px) puts the thumb away
  from the edge: the higher, the smaller it is; left `nil` it is the stylesheet's 3px. Extra
  HTML attributes go to the `<input>` (or to the label when there is no name).
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Radio.Choice
  alias LedgerUI.Components.Select.Options

  @styles %{
    "size" => %{"sm" => "s-sm", "md" => nil, "lg" => "s-lg"},
    "shape" => %{"pill" => "pill", "squircle" => nil},
    "inset" => %{2 => "in-2", 3 => "in-3", 4 => "in-4", 5 => "in-5", 6 => "in-6"}
  }
  @colors ~w(neutral primary secondary info success warning error)

  attr :field, Phoenix.HTML.FormField, default: nil
  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :any, default: nil
  attr :checked, :boolean, default: nil
  attr :checked_value, :string, default: "true"
  attr :unchecked_value, :string, default: "false"
  attr :hidden_input, :boolean, default: true
  attr :color, :string, default: "neutral", values: @colors
  attr :variant, :string, default: "basic", values: ~w(basic outline)
  attr :filled, :boolean, default: false
  attr :shape, :string, default: "squircle", values: ~w(pill squircle)
  attr :size, :string, default: "md", values: ~w(sm md lg)
  attr :thumb_inset, :integer, default: nil, values: [nil, 2, 3, 4, 5, 6]
  attr :label, :string, default: nil
  attr :label_position, :string, default: "right", values: ~w(right left)
  attr :label_class, :any, default: nil
  attr :description, :string, default: nil
  attr :errors, :list, default: []
  attr :disabled, :boolean, default: false
  attr :wrapper_class, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(form required)
  slot :inner_block

  def switch(assigns) do
    {assigns, id} = Options.resolve_field(assigns)
    on? = Options.checked?(assigns)
    own_click? = !Map.has_key?(assigns.rest, :"phx-click")

    toggle =
      JS.toggle_class("on", to: {:closest, "label"})
      |> JS.toggle_attribute({"aria-checked", "true", "false"}, to: {:closest, "label"})

    assigns =
      assigns
      |> assign(:input_id, id)
      |> assign(:on?, on?)
      |> assign(
        :classes,
        cx([
          "lu-sw",
          "c-" <> assigns.color,
          @styles["size"][assigns.size],
          @styles["shape"][assigns.shape],
          assigns.thumb_inset && @styles["inset"][assigns.thumb_inset],
          assigns.variant == "outline" && "outline",
          assigns.variant == "outline" && assigns.filled && "filled",
          assigns.disabled && "dis",
          assigns.label_position == "left" && "left",
          on? && "on",
          assigns.class
        ])
      )
      |> assign(:toggle, own_click? && !assigns.disabled && toggle)
      |> assign(
        :label_toggle,
        !assigns.name && own_click? && !assigns.disabled &&
          JS.toggle_class("on") |> JS.toggle_attribute({"aria-checked", "true", "false"})
      )
      |> assign(:vh, Choice.vh())
      |> assign(:wrap?, assigns.wrapper_class != nil || assigns.errors != [])

    ~H"""
    <%= if @wrap? do %>
      <div class={@wrapper_class}>
        {switch_label(assigns)}
        <span :for={e <- @errors} class="lu-help err">{e}</span>
      </div>
    <% else %>
      {switch_label(assigns)}
    <% end %>
    """
  end

  defp switch_label(%{name: nil} = assigns) do
    ~H"""
    <label
      id={@input_id}
      role="switch"
      aria-checked={to_string(@on?)}
      class={@classes}
      phx-click={@label_toggle || nil}
      {@rest}
    >
      <i></i>
      <span :if={@inner_block != [] || @label || @description} class={cx(["t", @label_class])}>
        <%= if @inner_block != [] do %>
          {render_slot(@inner_block)}
        <% else %>
          {@label}
        <% end %>
        <small :if={@description}>{@description}</small>
      </span>
    </label>
    """
  end

  defp switch_label(assigns) do
    ~H"""
    <label role="switch" aria-checked={to_string(@on?)} class={@classes}>
      <input
        :if={@hidden_input}
        type="hidden"
        name={@name}
        value={@unchecked_value}
        disabled={@disabled}
      />
      <input
        type="checkbox"
        id={@input_id}
        name={@name}
        value={@checked_value}
        checked={@on?}
        disabled={@disabled}
        style={@vh}
        phx-click={@toggle || nil}
        {@rest}
      />
      <i></i>
      <span :if={@inner_block != [] || @label || @description} class={cx(["t", @label_class])}>
        <%= if @inner_block != [] do %>
          {render_slot(@inner_block)}
        <% else %>
          {@label}
        <% end %>
        <small :if={@description}>{@description}</small>
      </span>
    </label>
    """
  end
end
