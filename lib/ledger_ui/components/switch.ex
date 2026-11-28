defmodule LedgerUI.Components.Switch do
  @moduledoc """
  A switch: a checkbox drawn as a track and thumb, for an effect that is immediate.

      <.switch name="notify" label="Notifications" color="primary" />
      <.switch field={@form[:public]} label="Public" variant="outline" color="success" filled />
      <.switch name="dense" size="sm" shape="pill" thumb_inset={4} checked />
      <.switch name="email" label="Email" label_position="left" wrapper_class="w-full justify-between" />

  With a `name` (or `field`) the switch holds a real, visually hidden checkbox (so the form,
  the keyboard and `phx-change` work) and, like `checkbox/1`, sends `unchecked_value` through a
  hidden input when off. The checkbox carries `role="switch"` and the track follows its `:checked`
  state (`peer-checked:`), so it flips in the browser with no round trip and no JS; the label has no role.
  Without a name there is no checkbox: a `<button type="button" role="switch">` is the switch and the
  click target, and `aria-checked` flips with `Phoenix.LiveView.JS`.

  `shape` is `squircle` (the default look) or `pill`. `thumb_inset` (2..6 px) puts the thumb away
  from the edge: the higher, the smaller it is; left `nil` it is 3px. Extra
  HTML attributes go to the `<input>` (or to the button when there is no name).
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

  # Named: the checkbox is the `peer` of the track (`peer-checked:` draws the on look, no JS needed) and
  # the label has no role. Without a name there is no checkbox: a button is the switch and
  # `aria-checked` (flipped by `JS.toggle_attribute`) draws the on look through `group-aria-checked:`.
  @label "group relative inline-flex appearance-none items-center gap-2.5 border-0 bg-transparent p-0 text-left font-[inherit] text-ink"
  @label_peer "relative inline-flex items-center gap-2.5 text-ink"

  @track "[input:focus-visible+&]:outline-3 [input:focus-visible+&]:outline-(--lu-focus) relative block h-(--th) w-(--tw) flex-none rounded-(--r) transition-[background-color] duration-150 after:absolute after:top-(--in) after:left-(--in) after:size-[calc(var(--th)-2*var(--in))] after:rounded-[calc(var(--r)-var(--in)+1px)] after:transition-transform after:duration-[180ms] after:ease-[cubic-bezier(.3,.7,.4,1)] after:content-[''] group-focus-visible:outline-3 group-focus-visible:outline-(--lu-focus) group-aria-checked:after:translate-x-[calc(var(--tw)-var(--th))]"

  @solid "bg-line-strong group-aria-checked:bg-(--c) after:bg-white after:shadow-[0_1px_2px_rgba(0,0,0,.25)]"

  @outline "bg-transparent shadow-[inset_0_0_0_1.5px_var(--lu-line-strong)] group-aria-checked:shadow-[inset_0_0_0_1.5px_var(--c)] after:bg-line-strong group-aria-checked:after:bg-(--c)"

  @track_peer "[input:focus-visible+&]:outline-3 [input:focus-visible+&]:outline-(--lu-focus) relative block h-(--th) w-(--tw) flex-none rounded-(--r) transition-[background-color] duration-150 after:absolute after:top-(--in) after:left-(--in) after:size-[calc(var(--th)-2*var(--in))] after:rounded-[calc(var(--r)-var(--in)+1px)] after:transition-transform after:duration-[180ms] after:ease-[cubic-bezier(.3,.7,.4,1)] after:content-[''] peer-checked:after:translate-x-[calc(var(--tw)-var(--th))]"

  @solid_peer "bg-line-strong peer-checked:bg-(--c) after:bg-white after:shadow-[0_1px_2px_rgba(0,0,0,.25)]"

  @outline_peer "bg-transparent shadow-[inset_0_0_0_1.5px_var(--lu-line-strong)] peer-checked:shadow-[inset_0_0_0_1.5px_var(--c)] after:bg-line-strong peer-checked:after:bg-(--c)"

  @loop "animate-[lu-swtrack_3.6s_ease-in-out_infinite] after:animate-[lu-swthumb_3.6s_cubic-bezier(.3,.7,.4,1)_infinite]"
  @loop_outline "animate-[lu-swtrack-o_3.6s_ease-in-out_infinite] after:animate-[lu-swthumb-o_3.6s_cubic-bezier(.3,.7,.4,1)_infinite]"

  defp track_class(a) do
    radius = if a.shape == "pill", do: "[--r:999px]", else: @radius[a.size]

    [
      if(a.name, do: @track_peer, else: @track),
      if(a.variant == "outline",
        do:
          if(a.name,
            do: [@outline_peer, a.filled && "peer-checked:bg-(--c-soft)"],
            else: [@outline, a.filled && "group-aria-checked:bg-(--c-soft)"]
          ),
        else: if(a.name, do: @solid_peer, else: @solid)
      ),
      radius,
      @inset[a.thumb_inset || 3],
      a.loop && if(a.variant == "outline", do: @loop_outline, else: @loop)
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
  attr :color, :string, default: "primary", values: @colors
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

  attr :loop, :boolean,
    default: false,
    doc: "Demo animation (CSS only): the switch turns on and off by itself."

  attr :wrapper_class, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(form required)
  slot :inner_block

  def switch(assigns) do
    changed0 = assigns.__changed__
    {assigns, id} = Options.resolve_field(assigns)
    on? = Options.checked?(assigns)
    own_click? = !Map.has_key?(assigns.rest, :"phx-click")

    assigns =
      assigns
      |> assign(:input_id, id)
      |> assign(:on?, on?)
      |> assign(:classes, [
        if(assigns.name, do: @label_peer, else: @label),
        Color.vars(assigns.color),
        @sizes[assigns.size],
        assigns.label_position == "left" && "flex-row-reverse",
        assigns.disabled && "cursor-not-allowed opacity-45",
        !assigns.disabled && "cursor-pointer",
        assigns.class
      ])
      |> assign(:track_cls, track_class(assigns))
      |> assign(
        :label_toggle,
        !assigns.name && own_click? && !assigns.disabled &&
          JS.toggle_attribute({"aria-checked", "true", "false"})
      )
      |> assign(:vh, "peer " <> Choice.vh())
      |> assign(:wrap?, assigns.wrapper_class != nil || assigns.errors != [])

    assigns =
      settle(assigns, changed0,
        input_id: [:id, :field],
        on?: [:checked, :value, :checked_value],
        classes: [:name, :color, :size, :label_position, :disabled, :class],
        track_cls: [:name, :variant, :filled, :shape, :thumb_inset, :loop, :color, :size],
        label_toggle: [:name, :rest, :disabled],
        vh: [],
        wrap?: [:wrapper_class, :errors]
      )

    ~H"""
    <Form.field bare as="div" errors={@errors} class={@wrapper_class}>
      {switch_label(assigns)}
    </Form.field>
    """
  end

  defp switch_label(%{name: nil} = assigns) do
    ~H"""
    <button
      type="button"
      id={@input_id}
      data-part="switch"
      role="switch"
      aria-checked={to_string(@on?)}
      class={@classes}
      disabled={@disabled}
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
    </button>
    """
  end

  defp switch_label(assigns) do
    ~H"""
    <label data-part="switch" class={@classes}>
      <input
        :if={@hidden_input}
        type="hidden"
        name={@name}
        value={@unchecked_value}
        disabled={@disabled}
      />
      <input
        type="checkbox"
        role="switch"
        id={@input_id}
        name={@name}
        value={@checked_value}
        checked={@on?}
        disabled={@disabled}
        class={@vh}
        data-part="switch-input"
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
