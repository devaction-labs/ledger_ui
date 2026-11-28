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
  (pastel tones), and `color="none"` leaves only the base face. `variant="mono"` is the dense
  table avatar: initials in the mono font on a ring. Styled only with Tailwind utilities.
  """
  use LedgerUI.Component

  alias LedgerUI.Color

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
    "bottom-right" => "br",
    "bottom-left" => "bl"
  }
  @kinds %{
    "company" => {"neutral", "building"},
    "customer" => {"primary", "user"},
    "supplier" => {"warning", "truck"},
    "assistant" => {"secondary", "sparkles"},
    "invite" => {"info", "plus"}
  }

  # The face: the size is the `--s` custom property (a name or any number of pixels).
  @face "relative inline-grid size-(--s) flex-none place-items-center overflow-visible tracking-[-.01em]"
  @text "font-semibold text-[length:calc(var(--s)*.36)]"

  @shape_classes %{
    "circle" => "rounded-full",
    "square" => "rounded-[14%]",
    "rounded" => "rounded-[28%]",
    "squircle" => "rounded-[38%]",
    "reuleaux-triangle" => "rounded-none [clip-path:polygon(50%_0,100%_86%,0_86%)]",
    "diamond" => "rounded-none [clip-path:polygon(50%_0,100%_50%,50%_100%,0_50%)]",
    "hexagon" => "rounded-none [clip-path:polygon(25%_4%,75%_4%,100%_50%,75%_96%,25%_96%,0_50%)]",
    "hexagon-2" =>
      "rounded-none [clip-path:polygon(50%_0,96%_25%,96%_75%,50%_100%,4%_75%,4%_25%)]",
    "octagon" =>
      "rounded-none [clip-path:polygon(30%_0,70%_0,100%_30%,100%_70%,70%_100%,30%_100%,0_70%,0_30%)]",
    "star" =>
      "rounded-none [clip-path:polygon(50%_0,61%_35%,98%_35%,68%_57%,79%_91%,50%_70%,21%_91%,32%_57%,2%_35%,39%_35%)]",
    "star-2" =>
      "rounded-none [clip-path:polygon(50%_0,60%_20%,82%_12%,80%_36%,100%_50%,80%_64%,82%_88%,60%_80%,50%_100%,40%_80%,18%_88%,20%_64%,0_50%,20%_36%,18%_12%,40%_20%)]",
    "heart" => "rounded-none [clip-path:path('M18_32_C-8_14_6_-6_18_8_C30_-6_44_14_18_32Z')]"
  }

  # `color` x `variant`: the colour enters as `--c`/`--c-on`/`--c-soft`/`--c-ink`.
  @variants %{
    "solid" => "bg-(--c) text-(--c-on)",
    "soft" => "bg-(--c-soft) text-(--c-ink)",
    "bordered" => "bg-panel text-(--c-ink) shadow-[inset_0_0_0_1.5px_var(--c)]",
    "skeleton" => "bg-sunken text-transparent animate-[mo-blink_1.6s_ease-in-out_infinite]"
  }

  @mono "bg-transparent font-mono font-medium text-[length:calc(var(--s)*.3)] text-muted shadow-[inset_0_0_0_1px_var(--lu-line-strong)]"
  @plain "bg-sunken text-ink-2"

  # The pastel palette of the canvas: `t1` follows the accent, the others are fixed hues.
  @legacy_tones %{
    "t1" => "bg-accent-100 text-accent-800",
    "t2" => "bg-[#fde3c7] text-[#7a3d0c] dark:bg-[#3a2410] dark:text-[#f6c99a]",
    "t3" => "bg-[#e3e6fb] text-[#2b3577] dark:bg-[#1d2346] dark:text-[#b9c3f5]",
    "t4" => "bg-[#fbe0e6] text-[#7f1f33] dark:bg-[#3a1820] dark:text-[#f3b3c0]",
    "t5" => "bg-[#e2f6c6] text-[#355a0c] dark:bg-[#1f2c10] dark:text-[#c4e78f]",
    "none" => @plain
  }

  @gradient_classes %{
    "sky-blue" => "[--g1:#0ea5e9] [--g2:#2563eb]",
    "amber-orange" => "[--g1:#f59e0b] [--g2:#f97316]",
    "pink-rose" => "[--g1:#ec4899] [--g2:#f43f5e]",
    "purple-orange" => "[--g1:#8b5cf6] [--g2:#f97316]",
    "green-fuchsia" => "[--g1:#22c55e] [--g2:#d946ef]",
    "purple-indigo" => "[--g1:#8b5cf6] [--g2:#4f46e5]",
    "fuchsia-pink" => "[--g1:#d946ef] [--g2:#ec4899]"
  }

  # The ring around the face (one `box-shadow`). `true`/1/2/4 are accent rings of 1, 2 and 4px.
  @ring_sizes %{
    true => "shadow-[0_0_0_1px_var(--lu-bg-page),0_0_0_2px_var(--lu-accent-500)]",
    1 => "shadow-[0_0_0_1px_var(--lu-bg-page),0_0_0_2px_var(--lu-accent-500)]",
    2 => "shadow-[0_0_0_2px_var(--lu-bg-page),0_0_0_4px_var(--lu-accent-500)]",
    4 => "shadow-[0_0_0_2px_var(--lu-bg-page),0_0_0_6px_var(--lu-accent-500)]"
  }
  # a plain `box-shadow` (not `shadow-*`, whose longer list would not interpolate with the keyframe)
  @speak "[box-shadow:0_0_0_2px_var(--lu-bg-page),0_0_0_4px_var(--lu-accent-500)] animate-[mo-speak_1.4s_ease-in-out_infinite]"
  @ring_colors %{
    "white" => "shadow-[0_0_0_2px_#fff]",
    "panel" => "shadow-[0_0_0_2px_var(--lu-bg-panel)]",
    "primary" => "shadow-[0_0_0_2px_var(--lu-bg-page),0_0_0_4px_var(--lu-accent-500)]",
    "secondary" => "shadow-[0_0_0_2px_var(--lu-bg-page),0_0_0_4px_#8b5cf6]",
    "info" => "shadow-[0_0_0_2px_var(--lu-bg-page),0_0_0_4px_var(--lu-info)]",
    "success" => "shadow-[0_0_0_2px_var(--lu-bg-page),0_0_0_4px_var(--lu-pos)]",
    "warning" => "shadow-[0_0_0_2px_var(--lu-bg-page),0_0_0_4px_#e8b04a]",
    "error" => "shadow-[0_0_0_2px_var(--lu-bg-page),0_0_0_4px_var(--lu-neg)]",
    "neutral" => "shadow-[0_0_0_2px_var(--lu-bg-page),0_0_0_4px_var(--lu-line-strong)]"
  }

  # The status dot: a tone and a corner.
  @dot "absolute size-[30%] min-h-[8px] min-w-[8px] rounded-full shadow-[0_0_0_2px_var(--lu-bg-panel)]"
  @dot_tones %{
    "on" => "bg-pos",
    "away" => "bg-[#e8b04a]",
    "off" => "bg-subtle",
    "busy" => "bg-neg"
  }
  @dot_corners %{
    "br" => "-right-px -bottom-px",
    "bl" => "-bottom-px -left-px",
    "tr" => "-right-px -top-px",
    "tl" => "-left-px -top-px"
  }

  # How the avatars of a group overlap (`--s` is each avatar's own size).
  @overlaps %{
    "2" =>
      "[&>[data-part=avatar]]:ml-[calc(var(--s)*-.28)] [&>[data-part=avatar]:first-child]:ml-0",
    "auto" =>
      "[&>[data-part=avatar]]:ml-[calc(var(--s)*-.28)] [&>[data-part=avatar]:first-child]:ml-0",
    "3" =>
      "[&>[data-part=avatar]]:ml-[calc(var(--s)*-.28)] [&>[data-part=avatar]:first-child]:ml-0 [&>[data-part=avatar]+[data-part=avatar]]:-ml-[3px]",
    "7" =>
      "[&>[data-part=avatar]]:ml-[calc(var(--s)*-.28)] [&>[data-part=avatar]:first-child]:ml-0 [&>[data-part=avatar]+[data-part=avatar]]:-ml-[7px]"
  }

  # A group's avatars get a panel-coloured gap, unless they have a shadow of their own (a ring).
  @group_gap "[&>[data-part=avatar]:not([data-lu-shadow])]:shadow-[0_0_0_2px_var(--lu-bg-panel)]"

  @spread "[&>[data-part=avatar]]:transition-[margin-left] [&>[data-part=avatar]]:duration-200 [&>[data-part=avatar]]:ease-[ease] motion-reduce:[&>[data-part=avatar]]:transition-none hover:[&>[data-part=avatar]+[data-part=avatar]]:ml-1 focus-within:[&>[data-part=avatar]+[data-part=avatar]]:ml-1 focus:[&>[data-part=avatar]+[data-part=avatar]]:ml-1 focus-visible:rounded-full focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-accent-500"

  @doc false
  def size_px(size) when is_map_key(@sizes, size), do: @sizes[size]

  def size_px(size) when is_integer(size) and size > 0, do: size

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
    doc:
      "Gives the initials (first and last word) and `color=\"auto\"` (a palette colour picked by the name, " <>
        "the same for the same name; with `variant=\"soft\"` it is the pastel tone)."

  attr :icon, :string, default: nil, doc: "An icon drawn on the sunken face."

  attr :kind, :string,
    default: nil,
    values: [nil, "company", "customer", "supplier", "assistant", "invite"]

  attr :size, :any,
    default: "sm",
    doc:
      "A size name or a number of pixels (`40`, `\"40\"`). Free-form: the names are a convenience, any pixel count works."

  attr :shape, :string, default: "circle", values: @shapes
  attr :tint, :string, default: nil, doc: "CSS color for the initials' background (white text)."
  attr :background, :string, default: nil, doc: "Any CSS `background` for the face (white text)."

  attr :color, :string,
    default: "neutral",
    values: ["auto" | @colors] ++ @legacy

  attr :variant, :string, default: "solid", values: ~w(solid soft bordered skeleton mono)

  attr :status, :any,
    default: nil,
    doc: "Presence (`online`, `away`, `busy`, `offline`) or a tone; `nil`/`false` shows no dot."

  attr :status_position, :string,
    default: nil,
    values: [nil | Map.keys(@positions)]

  attr :ping, :boolean, default: false, doc: "Animates the status dot."
  attr :ring, :any, default: false, doc: "`true`, `1`, `2` or `4`."

  attr :speak, :boolean,
    default: false,
    doc: "Speaking: a 2px page-colour gap, a 4px accent ring that pulses (`mo-speak`)."

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
    changed0 = assigns.__changed__
    {mode_classes, icon, bg_style} = mode(assigns)
    px = size_px(assigns.size)
    ring = if assigns.speak, do: @speak, else: ring_class(assigns)

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
      |> assign(
        :classes,
        cx([@face, assigns.variant != "mono" && @text, mode_classes, ring, assigns.class])
      )
      |> assign(:own_shadow, ring != nil or own_shadow?(assigns))
      |> assign(:style_s, style)
      |> assign(:text, text(assigns))
      |> assign(:icon_name, icon || assigns.icon)
      |> assign_dot(dot(assigns))
      |> assign(:alt_s, assigns.alt || assigns.name || "avatar")

    # A new name, picture or slot must not send the classes again. What `mode/1` and the shadow
    # read (the look of the face):
    look = [:variant, :gradient, :kind, :color, :shape, :name, :initials, :background, :tint]

    assigns =
      settle(assigns, changed0,
        classes: look ++ [:ring, :ring_color, :speak, :class],
        own_shadow: look ++ [:ring, :ring_color, :speak],
        style_s: look ++ [:size, :style],
        text: [:initials, :name],
        icon_name: [:variant, :gradient, :kind, :icon],
        dot_attrs: [:status, :status_position, :ping],
        alt_s: [:alt, :name]
      )

    ~H"""
    <span
      data-part="avatar"
      data-lu-shadow={@own_shadow && ""}
      class={cx([@classes, !@src && @face_class])}
      style={@style_s}
      {@rest}
    >
      <img
        :if={@src}
        data-part="avatar-image"
        src={@src}
        alt={@alt_s}
        class={["absolute inset-0 size-full rounded-[inherit] object-cover", @face_class]}
      />
      <%= if !@src do %>
        <%= if @inner_block != [] do %>
          {render_slot(@inner_block)}
        <% else %>
          <.icon :if={@icon_name} name={@icon_name} size="md" />{if !@icon_name, do: @text}
        <% end %>
      <% end %>
      <span :if={@dot_attrs} data-part="avatar-status" {@dot_attrs}></span>
    </span>
    """
  end

  defp assign_dot(assigns, nil), do: assign(assigns, dot_attrs: nil)
  defp assign_dot(assigns, class), do: assign(assigns, dot_attrs: %{class: class})

  # {classes, icon, style}
  defp mode(%{variant: "mono"} = a), do: {cx([@mono, legacy_shape(a)]), nil, custom_bg(a)}

  defp mode(%{gradient: g} = a) when is_binary(g),
    do: {cx(["text-white", grad(g), shape(a)]), nil, nil}

  defp mode(%{kind: kind} = a) when is_map_key(@kinds, kind) do
    {color, icon} = @kinds[kind]
    {cx([Color.vars(color), @variants["soft"], shape(a)]), icon, nil}
  end

  defp mode(%{color: "none"} = a),
    do: {cx([@legacy_tones["none"], legacy_shape(a)]), nil, custom_bg(a)}

  defp mode(%{color: "t" <> _ = c} = a),
    do: {cx([@legacy_tones[c] || @plain, legacy_shape(a)]), nil, custom_bg(a)}

  defp mode(a) do
    color = if a.color == "auto", do: auto_color(a.name || a.initials), else: a.color

    if a.background || a.tint do
      {cx([@plain, shape(a)]), nil, custom_bg(a)}
    else
      {cx([Color.vars(color), @variants[a.variant] || @variants["solid"], shape(a)]), nil, nil}
    end
  end

  defp grad(g),
    do: [
      "bg-[linear-gradient(135deg,var(--g1),var(--g2))]",
      @gradient_classes[g] || @gradient_classes["purple-indigo"]
    ]

  # The canvas's own tones keep its `sq` (30%) for the square.
  defp legacy_shape(%{shape: "square"}), do: "rounded-[30%]"
  defp legacy_shape(a), do: shape(a)

  defp shape(a), do: @shape_classes[a.shape] || @shape_classes["circle"]

  # The bordered look draws its own shadow (a ring, in the group, must not replace it).
  defp own_shadow?(%{variant: v, color: c, kind: k, gradient: g, background: bg, tint: t}) do
    v == "bordered" and is_nil(g) and is_nil(k) and is_nil(bg) and is_nil(t) and
      c not in ["none", "t1", "t2", "t3", "t4", "t5"]
  end

  defp own_shadow?(%{variant: "mono"}), do: true
  defp own_shadow?(_), do: false

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
    case a.ring_color do
      nil -> @ring_sizes[r]
      tone -> @ring_colors[tone] || @ring_sizes[r]
    end
  end

  defp ring_class(_), do: nil

  defp dot(%{status: s}) when s in [nil, false, ""], do: nil

  defp dot(%{status: s} = a) do
    tone =
      cond do
        is_map_key(@presence, s) -> @dot_tones[@presence[s]]
        is_map_key(@tone_status, s) -> @dot_tones[@tone_status[s]]
        s in @colors -> [Color.vars(s), "bg-(--c)"]
        true -> @dot_tones["off"]
      end

    default_pos = if is_map_key(@presence, s), do: "bottom-right", else: "top-right"
    corner = @dot_corners[@positions[a.status_position || default_pos]]

    cx([@dot, tone, corner, a.ping && "animate-[mo-blink_1.6s_ease-in-out_infinite]"])
  end

  attr :pulse, :boolean, default: false
  attr :overlap, :string, default: "2", values: ~w(2 3 7 auto)
  attr :more, :integer, default: nil, doc: ~s(Draws a "+N" avatar at the end.)

  attr :hidden, :list,
    default: nil,
    doc: "The people that did not fit (maps with `:name`, optional `:src`). Needs `id`."

  attr :id, :string, default: nil

  attr :size, :any,
    default: "xs",
    doc: "An avatar size name or a number of pixels (free-form, like `avatar` `size`)."

  attr :spread, :boolean, default: false
  attr :ring_color, :string, default: "white", values: ~w(white panel)
  attr :label, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def avatar_group(assigns) do
    changed0 = assigns.__changed__
    hidden = assigns.hidden
    more = if hidden, do: length(hidden), else: assigns.more

    assigns =
      assigns
      |> assign(
        :classes,
        cx([
          "inline-flex",
          @overlaps[assigns.overlap],
          @group_gap,
          assigns.spread && @spread,
          assigns.pulse && "animate-[mo-blink_1.4s_ease-in-out_infinite]",
          assigns.class
        ])
      )
      |> assign(:more, more)
      |> assign(:more_label, more && "+#{more}")
      |> assign(:more_style, "--s:#{size_px(assigns.size)}px")
      |> assign(
        :more_class,
        cx([
          @face,
          @text,
          "rounded-full bg-selected text-ink-2",
          "shadow-[0_0_0_2px_var(--lu-bg-panel)]"
        ])
      )
      |> assign(:more_face, cx([@face, @text, "rounded-full bg-selected text-ink-2"]))
      |> assign(:pop_id, assigns.id && "#{assigns.id}-more")
      |> assign(:role, assigns.label && "group")

    # A new person or label must not send the classes again.
    assigns =
      settle(assigns, changed0,
        classes: [:overlap, :spread, :pulse, :class],
        more: [:hidden],
        more_label: [:more],
        more_style: [:size],
        more_class: [],
        more_face: [],
        pop_id: [:id],
        role: [:label]
      )

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
        <span
          id={@pop_id <> "-wrap"}
          data-part="avatar-more-wrap"
          phx-hook="LedgerUI.AvatarMore"
          class="relative inline-flex"
        >
          <button
            type="button"
            data-part="avatar-more"
            class={@more_class}
            style={@more_style}
            aria-haspopup="true"
            aria-expanded="false"
            aria-controls={@pop_id}
          >{@more_label}</button>
          <span
            id={@pop_id}
            data-part="avatar-more-menu"
            hidden
            keep-hidden
            keep-style
            popover="manual"
            data-lu-placement="bottom-start"
            class="fixed m-0 min-w-[180px] rounded-xl border border-line bg-tray p-2"
          >
            <span
              :for={person <- @hidden}
              data-part="avatar-more-person"
              class="flex min-w-0 items-center gap-2 py-1"
            >
              <.avatar name={person[:name]} src={person[:src]} color="auto" size="xs" />
              <span>{person[:name]}</span>
            </span>
          </span>
        </span>
      <% else %>
        <span :if={@more} data-part="avatar" class={@more_face} style={@more_style}>{@more_label}</span>
      <% end %>
    </span>
    """
  end
end
