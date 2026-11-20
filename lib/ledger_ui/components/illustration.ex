defmodule LedgerUI.Components.Illustration do
  @moduledoc """
  Light illustrations for empty states and result screens, drawn with the theme tokens (or
  inline SVG), so the package needs no static images.

      <.illustration name="empty" />
      <.illustration name="success" />
      <.empty_box class="h-28" />
      <.summit class="h-48 w-full" />
      <.scene name="voyage" />

    * `illustration/1`: a small card sketch with a round icon badge (`lu-ill`), in five states:
      `empty`, `success`, `error`, `search` and `offline`. `empty-inbox` is accepted for
      `empty`. `tone` and `icon` override the preset.
    * `empty_box/1`: a girl with a box, for an empty area.
    * `summit/1`: the landscape of `hero_card` and `auth_art` (`svg.lu-summit`), cropped to fill its box.
    * `scene/1`: portrait scenes (`voyage`, `lighthouse`, `balloons`, `aurora`) for the picture
      half of `auth_split`.

  An illustration always comes with a title and a sentence; never alone.
  """
  use LedgerUI.Component

  @presets %{
    "empty" => {"neutral", "inbox"},
    "empty-inbox" => {"neutral", "inbox"},
    "success" => {"success", "check-circle"},
    "error" => {"error", "x-circle"},
    "search" => {"info", "search"},
    "offline" => {"warning", "wifi"}
  }
  @tones ~w(primary neutral success error info warning)

  attr :name, :string, default: "empty", values: Map.keys(@presets)
  attr :tone, :string, default: nil, values: [nil | @tones], doc: "Overrides the preset's colour."
  attr :icon, :string, default: nil, doc: "Overrides the preset's icon."
  attr :class, :any, default: nil
  attr :rest, :global

  def illustration(assigns) do
    {tone, icon} = @presets[assigns.name]

    assigns =
      assigns
      |> assign(:tone_class, "c-" <> (assigns.tone || tone))
      |> assign(:icon_name, assigns.icon || icon)

    ~H"""
    <div data-part="illustration" class={cx(["lu-ill", @tone_class, @class])} {@rest}>
      <span class="a"></span><span class="b"></span><span class="c"></span><span class="d"><.icon
        name={@icon_name}
        size="md"
      /></span>
    </div>
    """
  end

  attr :class, :any, default: "h-36", doc: "Sets the size; the width follows the height."
  attr :rest, :global

  def empty_box(assigns) do
    ~H"""
    <svg
      data-part="empty-box"
      class={@class}
      viewBox="0 0 160 180"
      role="img"
      aria-label="Empty"
      {@rest}
    >
      <ellipse cx="80" cy="168" rx="52" ry="7" fill="var(--bg-sunken)" />
      <path
        d="M44 112h72l-6 50H50z"
        fill="var(--bg-selected)"
        stroke="var(--line-strong)"
        stroke-width="2"
        stroke-linejoin="round"
      />
      <path
        d="M38 100h84l-4 14H42z"
        fill="var(--bg-sunken)"
        stroke="var(--line-strong)"
        stroke-width="2"
        stroke-linejoin="round"
      />
      <path d="M62 124h36" stroke="var(--line-strong)" stroke-width="3" stroke-linecap="round" />
      <path d="M62 52c0-20 36-20 36 0v8H62z" fill="var(--ink)" />
      <circle cx="80" cy="66" r="15" fill="var(--bg-panel)" stroke="var(--ink)" stroke-width="2" />
      <circle cx="75" cy="66" r="1.6" fill="var(--ink)" />
      <circle cx="85" cy="66" r="1.6" fill="var(--ink)" />
      <path
        d="M76 72q4 3 8 0"
        fill="none"
        stroke="var(--ink)"
        stroke-width="1.6"
        stroke-linecap="round"
      />
      <path d="M66 84h28l4 18H62z" fill="var(--accent)" />
      <path
        d="M62 90l-12 14M98 90l12 14"
        stroke="var(--accent)"
        stroke-width="6"
        stroke-linecap="round"
      />
    </svg>
    """
  end

  attr :id, :string,
    default: "hs",
    doc: "Prefix of the SVG's gradient ids (`hs-sky`...); give each summit on a page its own."

  attr :tone, :string, default: "teal", doc: "Modifier of `lu-summit` (the palette)."
  attr :class, :any, default: nil
  attr :rest, :global

  @doc """
  The summit landscape of the design (`svg.lu-summit`): sky, sun, stars, three ridges and a dotted
  trail, painted with the `--hero-*` tokens (light and dark). It fills its box, cropping the sides.
  Decorative: `aria-hidden`. This is the only drawing of it: `hero_summit/1` and `auth_art/1` render it.
  """
  def summit(assigns) do
    ~H"""
    <svg
      data-part="summit"
      class={cx(["lu-summit", @tone, @class])}
      viewBox="0 0 520 300"
      preserveAspectRatio="xMidYMid slice"
      aria-hidden="true"
      {@rest}
    >
      <defs>
        <linearGradient id={"#{@id}-sky"} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stop-color="var(--hero-sky1)" />
          <stop offset="1" stop-color="var(--hero-sky2)" />
        </linearGradient>
        <linearGradient id={"#{@id}-m1"} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stop-color="var(--hero-m1a)" />
          <stop offset="1" stop-color="var(--hero-m1b)" />
        </linearGradient>
        <linearGradient id={"#{@id}-m2"} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stop-color="var(--hero-m2a)" />
          <stop offset="1" stop-color="var(--hero-m2b)" />
        </linearGradient>
        <linearGradient id={"#{@id}-m3"} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stop-color="var(--hero-m3a)" />
          <stop offset="1" stop-color="var(--hero-m3b)" />
        </linearGradient>
        <radialGradient id={"#{@id}-sun"} cx=".5" cy=".5" r=".5">
          <stop offset="0" stop-color="var(--hero-sun)" />
          <stop offset="1" stop-color="var(--hero-sun)" stop-opacity="0" />
        </radialGradient>
      </defs>
      <rect width="520" height="300" fill={"url(##{@id}-sky)"} />
      <circle class="sun" cx="350" cy="110" r="90" fill={"url(##{@id}-sun)"} />
      <circle class="sun-c" cx="350" cy="110" r="26" fill="var(--hero-sun)" opacity=".9" />
      <g class="st">
        <circle cx="90" cy="40" r="1.2" />
        <circle cx="160" cy="70" r="1" />
        <circle cx="430" cy="34" r="1.3" />
        <circle cx="470" cy="80" r="1" />
        <circle cx="250" cy="28" r="1" />
      </g>
      <path
        class="m3"
        d="M0 205 L70 150 L120 175 L190 110 L250 160 L310 120 L380 170 L450 125 L520 160 V300 H0 Z"
        fill={"url(##{@id}-m3)"}
      />
      <path
        class="m2"
        d="M0 235 L60 200 L130 225 L210 170 L270 210 L340 185 L420 225 L520 190 V300 H0 Z"
        fill={"url(##{@id}-m2)"}
      />
      <path
        class="m1"
        d="M0 268 L90 238 L170 258 L260 228 L350 262 L440 240 L520 258 V300 H0 Z"
        fill={"url(##{@id}-m1)"}
      />
      <path
        class="ln"
        d="M180 300 C 230 270, 300 268, 330 250 S 400 230, 430 238"
        fill="none"
        stroke="var(--hero-line)"
        stroke-width="1.5"
        stroke-dasharray="3 5"
        pathLength="1"
      />
    </svg>
    """
  end

  attr :name, :string, required: true, values: ~w(voyage lighthouse balloons aurora)

  attr :position, :string,
    default: "xMidYMid",
    doc:
      "Where the crop holds (`preserveAspectRatio`): `xMidYMax` keeps the bottom, `xMinYMid` the left."

  attr :label, :string, default: "", doc: "Read by screen readers; leave empty for decoration."
  attr :class, :any, default: "h-full w-full"
  attr :rest, :global

  def scene(assigns) do
    assigns = assign(assigns, :aspect, assigns.position <> " slice")

    ~H"""
    <svg
      data-part="scene"
      data-scene={@name}
      class={@class}
      viewBox="0 0 300 500"
      preserveAspectRatio={@aspect}
      role={if @label != "", do: "img"}
      aria-label={if @label != "", do: @label}
      aria-hidden={if @label == "", do: "true"}
      {@rest}
    >
      {scene_art(@name)}
    </svg>
    """
  end

  defp scene_art("voyage") do
    assigns = %{}

    ~H"""
    <rect width="300" height="500" fill="#bfe3f2" />
    <circle cx="220" cy="110" r="34" fill="#fff4cf" />
    <path d="M30 120q20-18 46-4q18-14 40 2z" fill="#fff" opacity=".9" />
    <rect y="300" width="300" height="200" fill="#2a7ea6" />
    <path d="M0 330q37-14 75 0t75 0 75 0 75 0v170H0z" fill="#226d92" />
    <path d="M70 340h160l-24 36H96z" fill="#7a4b2a" />
    <path d="M150 340V150" stroke="#4a2f1b" stroke-width="5" />
    <path d="M150 160q60 40 60 130h-60zM144 180q-46 30-46 110h46z" fill="#fff" />
    <path d="M0 470q30-60 70-40-20 20-10 40zM300 460q-30-70-70-50 24 20 14 50z" fill="#2f7a4d" />
    """
  end

  defp scene_art("lighthouse") do
    assigns = %{}

    ~H"""
    <rect width="300" height="500" fill="#2b2a5a" />
    <rect y="260" width="300" height="240" fill="#1c1b3d" />
    <circle cx="60" cy="90" r="2" fill="#fff" /><circle cx="230" cy="60" r="2" fill="#fff" /><circle
      cx="140"
      cy="130"
      r="1.6"
      fill="#fff"
    />
    <path d="M150 170 L-20 140 V200z M150 170 L320 140 V200z" fill="#ffe9a8" opacity=".35" />
    <path d="M0 400q80-60 180-40t120 10v130H0z" fill="#3a3a30" />
    <path d="M132 400 142 220h16l10 180z" fill="#f4f1ea" />
    <path d="M138 270h24l-1 18h-22zM135 330h30l-1 18h-28z" fill="#c9503f" />
    <rect x="136" y="196" width="28" height="24" fill="#ffe9a8" />
    <path d="M130 196h40l-20-22z" fill="#c9503f" />
    """
  end

  defp scene_art("balloons") do
    assigns = %{}

    ~H"""
    <rect width="300" height="500" fill="#ffe0c2" />
    <circle cx="80" cy="120" r="40" fill="#fff3d6" />
    <ellipse cx="110" cy="190" rx="34" ry="42" fill="#e5603f" />
    <ellipse cx="200" cy="130" rx="28" ry="36" fill="#1f9282" />
    <ellipse cx="230" cy="260" rx="24" ry="30" fill="#e8b04a" />
    <path d="M110 232v22M200 166v20M230 290v18" stroke="#6b4a2f" stroke-width="2" />
    <rect x="102" y="254" width="16" height="12" fill="#7a4b2a" /><rect
      x="192"
      y="186"
      width="16"
      height="12"
      fill="#7a4b2a"
    /><rect x="224" y="308" width="12" height="10" fill="#7a4b2a" />
    <path d="M0 400q90-70 180-30t120-20v150H0z" fill="#6fb36f" />
    <path d="M0 450q110-50 200-14t100-6v70H0z" fill="#3f8f55" />
    """
  end

  defp scene_art("aurora") do
    assigns = %{}

    ~H"""
    <rect width="300" height="500" fill="#0c1a2e" />
    <path d="M0 140q80-90 150-30t150-40v120q-80 40-150-10T0 250z" fill="#3ddc97" opacity=".35" />
    <path d="M0 190q90-70 160-20t140-30v80q-70 30-140-10T0 280z" fill="#7a6cf0" opacity=".3" />
    <circle cx="50" cy="60" r="1.6" fill="#fff" /><circle cx="210" cy="40" r="1.6" fill="#fff" /><circle
      cx="120"
      cy="90"
      r="1.2"
      fill="#fff"
    />
    <path d="M0 400 90 290l50 70 60-90 100 130v100H0z" fill="#e8eef5" />
    <path d="M0 450 70 380l60 50 70-60 100 90v40H0z" fill="#9db3c9" />
    <rect x="120" y="412" width="60" height="44" fill="#4a2f1b" /><path
      d="M112 414l38-26 38 26z"
      fill="#e8eef5"
    />
    <rect x="140" y="426" width="14" height="14" fill="#ffd36e" />
    """
  end
end
