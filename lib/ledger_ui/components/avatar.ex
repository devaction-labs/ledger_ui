defmodule LedgerUI.Components.Avatar do
  @moduledoc """
  Avatars: an image or initials in a circle, a square, a squircle or any mask shape, with a
  status dot, a gradient ring, and stacked in groups.

      <.avatar name="Ana Souza" color="auto" size="md" status="online" />
      <.avatar initials="jd" color="info" variant="soft" />
      <.avatar src="/images/jane.jpg" alt="Jane" gradient="sky-blue" size="lg" />
      <.avatar kind="assistant" size="md" />

      <.avatar_group more={3} size="sm">
        <.avatar :for={user <- @users} name={user.name} color="auto" size="sm" ring />
      </.avatar_group>

  `size` takes the names (`3xs` 16px, `2xs` 20px, `xs` 24px, `xs-plus` 26px, `sm` 30px,
  `md` 36px, `lg` 44px, `xl` 56px, `2xl` 72px, `sm-plus` 32px) or any number of pixels
  (`"40"`). The legacy palette of the canvas is available with `color` `t1`..`t5`
  (pastel tones), and `color="none"` leaves only the base `lu-av` face.
  """
  use LedgerUI.Component

  @sizes %{
    "3xs" => 16,
    "2xs" => 20,
    "xs" => 24,
    "xs-plus" => 26,
    "sm" => 30,
    "sm-plus" => 32,
    "md" => 36,
    "lg" => 44,
    "xl" => 56,
    "2xl" => 72
  }

  @colors ~w(neutral primary secondary info success warning error)
  @legacy ~w(t1 t2 t3 t4 t5 none)
  @shapes ~w(circle square rounded squircle reuleaux-triangle diamond hexagon hexagon-2 octagon star star-2 heart)
  @gradients ~w(sky-blue amber-orange pink-rose purple-orange green-fuchsia purple-indigo fuchsia-pink)
  @presence %{"online" => "on", "away" => "away", "busy" => "busy", "offline" => "off"}
  @tone_status %{"success" => "on", "warning" => "away", "error" => "busy", "neutral" => "off"}
  @positions %{
    "top-right" => "tr",
    "top-left" => "tl",
    "bottom-right" => nil,
    "bottom-left" => "bl"
  }
  @ring_classes %{1 => "ring1", 2 => "ring2", 4 => "ring4"}
  @kinds %{
    "company" => {"c-neutral v-soft", "building"},
    "customer" => {"c-primary v-soft", "user"},
    "supplier" => {"c-warning v-soft", "truck"},
    "assistant" => {"c-secondary v-soft", "sparkles"},
    "invite" => {"c-info v-soft", "plus"}
  }
  @overlaps %{"2" => nil, "3" => "ov3", "7" => "ov7", "auto" => "ova"}

  @doc false
  def size_px(size) when is_map_key(@sizes, size), do: @sizes[size]

  def size_px(size) when is_binary(size) do
    case Integer.parse(size) do
      {px, ""} -> px
      _ -> @sizes["sm"]
    end
  end

  def size_px(_), do: @sizes["sm"]

  attr :src, :string, default: nil
  attr :alt, :string, default: nil, doc: "The picture's text; the `name` when not given."
  attr :initials, :string, default: nil, doc: "Shown (upper-cased) when there is no `src`."

  attr :name, :string,
    default: nil,
    doc: "Gives the initials (first and last word) and `color=\"auto\"`."

  attr :icon, :string, default: nil, doc: "An icon drawn on the sunken face."

  attr :kind, :string,
    default: nil,
    values: [nil, "company", "customer", "supplier", "assistant", "invite"]

  attr :size, :string, default: "sm", doc: "A size name or a number of pixels."

  attr :shape, :string, default: "circle", values: @shapes
  attr :tint, :string, default: nil, doc: "CSS color for the initials' background (white text)."
  attr :background, :string, default: nil, doc: "Any CSS `background` for the face (white text)."

  attr :color, :string,
    default: "neutral",
    values: ["auto" | @colors] ++ @legacy

  attr :variant, :string, default: "solid", values: ~w(solid soft bordered skeleton)

  attr :status, :any,
    default: nil,
    doc: "Presence (`online`, `away`, `busy`, `offline`) or a tone; `nil`/`false` shows no dot."

  attr :status_position, :string,
    default: nil,
    values: [nil | Map.keys(@positions)]

  attr :ping, :boolean, default: false, doc: "Animates the status dot."
  attr :ring, :any, default: false, doc: "`true`, `1`, `2` or `4`."

  attr :ring_color, :string,
    default: nil,
    values: [
      nil,
      "white",
      "panel",
      "neutral",
      "primary",
      "secondary",
      "info",
      "success",
      "warning",
      "error"
    ]

  attr :face_class, :any, default: nil
  attr :gradient, :string, default: nil, values: [nil | @gradients]
  attr :style, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, doc: "Replaces the initials (an icon, a counter)."

  def avatar(assigns) do
    {mode_classes, icon, bg_style} = mode(assigns)
    px = size_px(assigns.size)
    text = text(assigns)

    style =
      Enum.join(
        Enum.reject(
          ["--s:#{px}px", bg_style, assigns.style],
          &(&1 in [nil, ""])
        ),
        ";"
      )

    assigns =
      assigns
      |> assign(:classes, cx(["lu-av", mode_classes, ring_class(assigns), assigns.class]))
      |> assign(:face, assigns.face_class)
      |> assign(:style_s, style)
      |> assign(:text, text)
      |> assign(:icon_name, icon || assigns.icon)
      |> assign_dot(dot(assigns))
      |> assign(:alt_s, assigns.alt || assigns.name || "avatar")

    ~H"""
    <span data-part="avatar" class={cx([@classes, !@src && @face])} style={@style_s} {@rest}>
      <img
        :if={@src}
        src={@src}
        alt={@alt_s}
        class={@face}
        style="width:100%;height:100%;object-fit:cover;border-radius:inherit"
      />
      <%= if !@src do %>
        <%= if @inner_block != [] do %>
          {render_slot(@inner_block)}
        <% else %>
          <.icon :if={@icon_name} name={@icon_name} size="md" />{if !@icon_name, do: @text}
        <% end %>
      <% end %>
      <span :if={@dot_attrs} {@dot_attrs}></span>
    </span>
    """
  end

  defp assign_dot(assigns, nil), do: assign(assigns, dot_attrs: nil)

  # `style={nil}` would render `style=""`, so the attrs go in a map.
  defp assign_dot(assigns, {class, nil}), do: assign(assigns, dot_attrs: %{class: class})

  defp assign_dot(assigns, {class, style}),
    do: assign(assigns, dot_attrs: %{class: class, style: style})

  # {classes, icon, style}
  defp mode(%{gradient: g}) when is_binary(g), do: {"grad g-#{g}", nil, nil}

  defp mode(%{kind: kind}) when is_map_key(@kinds, kind) do
    {classes, icon} = @kinds[kind]
    {classes, icon, nil}
  end

  defp mode(%{color: "none"} = a), do: {legacy_shape(a, nil), nil, custom_bg(a)}
  defp mode(%{color: "t" <> _ = c} = a), do: {legacy_shape(a, c), nil, custom_bg(a)}

  defp mode(a) do
    color = if a.color == "auto", do: auto_color(a.name || a.initials), else: a.color
    variant = a.variant

    cond do
      a.background || a.tint ->
        {cx([shape(a)]), nil, custom_bg(a)}

      true ->
        {cx(["c-#{color}", "v-#{variant}", shape(a)]), nil, nil}
    end
  end

  defp shape(a), do: "sh-#{a.shape}"

  defp legacy_shape(%{shape: "circle"}, tone), do: tone
  defp legacy_shape(%{shape: "square"}, tone), do: cx([tone, "sq"])
  defp legacy_shape(a, tone), do: cx([tone, shape(a)])

  defp custom_bg(%{background: bg}) when is_binary(bg), do: "background:#{bg};color:#fff"
  defp custom_bg(%{tint: tint}) when is_binary(tint), do: "background:#{tint};color:#fff"
  defp custom_bg(_), do: nil

  defp auto_color(nil), do: "neutral"

  defp auto_color(name),
    do: Enum.at(@colors, :erlang.phash2(name, length(@colors)))

  defp text(%{initials: i}) when is_binary(i), do: String.upcase(i)
  defp text(%{name: n}) when is_binary(n), do: initials_of(n)
  defp text(_), do: nil

  defp initials_of(name) do
    case String.split(name, ~r/\s+/, trim: true) do
      [] -> nil
      [one] -> String.upcase(String.first(one))
      words -> String.upcase(String.first(hd(words)) <> String.first(List.last(words)))
    end
  end

  defp ring_class(%{ring: r} = a) when r in [true, 1, 2, 4] do
    base = if r == true, do: "ring1", else: @ring_classes[r]

    ring_color =
      case a.ring_color do
        nil -> nil
        "white" -> "ringw"
        "panel" -> "ringp"
        tone -> "ring-#{tone}"
      end

    cx([ring_color || base])
  end

  defp ring_class(_), do: nil

  defp dot(%{status: s}) when s in [nil, false, ""], do: nil

  defp dot(%{status: s} = a) do
    {tone, style} =
      cond do
        is_map_key(@presence, s) -> {@presence[s], nil}
        is_map_key(@tone_status, s) -> {@tone_status[s], nil}
        true -> {"c-#{s}", "background:var(--c)"}
      end

    default_pos = if is_map_key(@presence, s), do: "bottom-right", else: "top-right"
    pos = a.status_position || default_pos

    {cx(["st", tone, a.ping && "m", @positions[pos]]), style}
  end

  attr :pulse, :boolean, default: false
  attr :overlap, :string, default: "2", values: ~w(2 3 7 auto)
  attr :more, :integer, default: nil, doc: ~s(Draws a "+N" avatar at the end.)

  attr :hidden, :list,
    default: nil,
    doc: "The people that did not fit (maps with `:name`, optional `:src`). Needs `id`."

  attr :id, :string, default: nil
  attr :size, :string, default: "xs"
  attr :spread, :boolean, default: false
  attr :ring_color, :string, default: "white", values: ~w(white panel)
  attr :label, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def avatar_group(assigns) do
    hidden = assigns.hidden
    more = if hidden, do: length(hidden), else: assigns.more

    assigns =
      assigns
      |> assign(
        :classes,
        cx([
          "lu-av-grp",
          @overlaps[assigns.overlap],
          assigns.spread && "spread",
          assigns.pulse && "mo-blink",
          assigns.class
        ])
      )
      |> assign(:more, more)
      |> assign(:more_label, more && "+#{more}")
      |> assign(
        :more_style,
        "--s:#{size_px(assigns.size)}px;background:var(--bg-selected);color:var(--ink-2)"
      )
      |> assign(:more_class, cx(["lu-av", assigns.ring_color == "panel" && "ringp"]))
      |> assign(:pop_id, assigns.id && "#{assigns.id}-more")
      |> assign(:role, assigns.label && "group")

    ~H"""
    <span
      id={@id}
      data-part="avatar-group"
      class={@classes}
      role={@role}
      aria-label={@label}
      tabindex={@spread && "0"}
      {@rest}
    >
      {render_slot(@inner_block)}
      <%= if @more && @hidden && @pop_id do %>
        <span style="position:relative;display:inline-flex">
          <button
            type="button"
            class={@more_class}
            style={@more_style}
            aria-haspopup="true"
            aria-expanded="false"
            aria-controls={@pop_id}
            phx-click={
              JS.toggle(to: "##{@pop_id}")
              |> JS.toggle_attribute({"aria-expanded", "true", "false"})
            }
          >{@more_label}</button>
          <span
            id={@pop_id}
            class="lu-card"
            style="display:none;position:absolute;top:100%;left:0;z-index:20;padding:8px;min-width:180px"
            phx-click-away={JS.hide(to: "##{@pop_id}")}
          >
            <span
              :for={person <- @hidden}
              class="lu-person"
              style="display:flex;align-items:center;gap:8px;padding:4px 0"
            >
              <.avatar name={person[:name]} src={person[:src]} color="auto" size="xs" />
              <span>{person[:name]}</span>
            </span>
          </span>
        </span>
      <% else %>
        <span :if={@more} class={@more_class} style={@more_style}>{@more_label}</span>
      <% end %>
    </span>
    """
  end
end
