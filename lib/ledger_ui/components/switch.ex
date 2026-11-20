defmodule LedgerUI.Components.Switch do
  @moduledoc """
  A switch: a checkbox drawn as a track and thumb, for an effect that is immediate.

      <.switch name="notify" label="Notifications" color="primary" />
      <.switch field={@form[:public]} label="Public" variant="outline" color="success" filled />
      <.switch name="dense" size="sm" shape="pill" thumb_inset={4} checked />
      <.switch name="email" label="Email" label_position="left" wrapper_class="w-full justify-between" />

  With a `name` (or `field`) the switch holds a real, visually hidden checkbox (so the form,
  the keyboard and `phx-change` work) and, like `checkbox/1`, sends `unchecked_value` through a
  hidden input when off. The track and `aria-checked` flip in the browser with
  `Phoenix.LiveView.JS`, no round trip (`aria-checked` draws the on look); without a name the label itself is the click target.

  `shape` is `squircle` (the default look) or `pill`. `thumb_inset` (2..6 px) puts the thumb away
  from the edge: the higher, the smaller it is; left `nil` it is 3px. Extra
  HTML attributes go to the `<input>` (or to the label when there is no name).
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Checkbox
  alias LedgerUI.Color
  alias LedgerUI.Components.Form
  alias LedgerUI.Components.Radio.Choice
  alias LedgerUI.Components.Select.Options

  @colors ~w(neutral primary secondary info success warning error)

  # track width, height and radius of each size; the thumb is sized from them
  @sizes %{
    "sm" => "[--tw:30px] [--th:18px] text-[13px]",
    "md" => "[--tw:36px] [--th:22px] text-sm",
    "lg" => "[--tw:46px] [--th:28px] text-[15px]"
  }
  @radius %{"sm" => "[--r:6px]", "md" => "[--r:7px]", "lg" => "[--r:9px]"}
  @inset %{
    2 => "[--in:2px]",
    3 => "[--in:3px]",
    4 => "[--in:4px]",
    5 => "[--in:5px]",
    6 => "[--in:6px]"
  }

  @label "group relative inline-flex items-center gap-2.5 text-ink"

  @track "relative block h-(--th) w-(--tw) flex-none rounded-(--r) transition-[background-color] duration-150 after:absolute after:top-(--in) after:left-(--in) after:size-[calc(var(--th)-2*var(--in))] after:rounded-[calc(var(--r)-var(--in)+1px)] after:transition-transform after:duration-[180ms] after:ease-[cubic-bezier(.3,.7,.4,1)] after:content-[''] group-aria-checked:after:translate-x-[calc(var(--tw)-var(--th))]"

  @solid "bg-line-strong group-aria-checked:bg-(--c) after:bg-white after:shadow-[0_1px_2px_rgba(0,0,0,.25)]"

  @outline "bg-transparent shadow-[inset_0_0_0_1.5px_var(--lu-line-strong)] group-aria-checked:shadow-[inset_0_0_0_1.5px_var(--c)] after:bg-line-strong group-aria-checked:after:bg-(--c)"

  defp track_class(a) do
    radius = if a.shape == "pill", do: "[--r:999px]", else: @radius[a.size]

    [
      @track,
      if(a.variant == "outline",
        do: [@outline, a.filled && "group-aria-checked:bg-(--c-soft)"],
        else: @solid
      ),
      radius,
      @inset[a.thumb_inset || 3]
    ]
  end

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

    toggle = JS.toggle_attribute({"aria-checked", "true", "false"}, to: {:closest, "label"})

    assigns =
      assigns
      |> assign(:input_id, id)
      |> assign(:on?, on?)
      |> assign(:classes, [
        @label,
        Color.vars(assigns.color),
        @sizes[assigns.size],
        assigns.label_position == "left" && "flex-row-reverse",
        assigns.disabled && "cursor-not-allowed opacity-45",
        !assigns.disabled && "cursor-pointer",
        assigns.class
      ])
      |> assign(:track_cls, track_class(assigns))
      |> assign(:toggle, own_click? && !assigns.disabled && toggle)
      |> assign(
        :label_toggle,
        !assigns.name && own_click? && !assigns.disabled &&
          JS.toggle_attribute({"aria-checked", "true", "false"})
      )
      |> assign(:vh, Choice.vh())
      |> assign(:wrap?, assigns.wrapper_class != nil || assigns.errors != [])

    ~H"""
    <Form.field bare as="div" errors={@errors} class={@wrapper_class}>
      {switch_label(assigns)}
    </Form.field>
    """
  end

  defp switch_label(%{name: nil} = assigns) do
    ~H"""
    <label
      id={@input_id}
      data-part="switch"
      role="switch"
      aria-checked={to_string(@on?)}
      class={@classes}
      phx-click={@label_toggle || nil}
      {@rest}
    >
      <i data-part="switch-track" class={@track_cls}></i>
      <span
        :if={@inner_block != [] || @label || @description}
        data-part="switch-text"
        class={[Checkbox.text_class(), @label_class]}
      >
        <%= if @inner_block != [] do %>
          {render_slot(@inner_block)}
        <% else %>
          {@label}
        <% end %>
        <small
          :if={@description}
          data-part="switch-description"
          class="text-[13px] leading-5 text-muted"
        >{@description}</small>
      </span>
    </label>
    """
  end

  defp switch_label(assigns) do
    ~H"""
    <label data-part="switch" role="switch" aria-checked={to_string(@on?)} class={@classes}>
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
        class={@vh}
        data-part="switch-input"
        phx-click={@toggle || nil}
        {@rest}
      />
      <i data-part="switch-track" class={@track_cls}></i>
      <span
        :if={@inner_block != [] || @label || @description}
        data-part="switch-text"
        class={[Checkbox.text_class(), @label_class]}
      >
        <%= if @inner_block != [] do %>
          {render_slot(@inner_block)}
        <% else %>
          {@label}
        <% end %>
        <small
          :if={@description}
          data-part="switch-description"
          class="text-[13px] leading-5 text-muted"
        >{@description}</small>
      </span>
    </label>
    """
  end
end
