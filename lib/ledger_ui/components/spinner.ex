defmodule LedgerUI.Components.Spinner do
  @moduledoc """
  Short loading indicator: five designs, five sizes and the system colours. Styled only with
  Tailwind utilities (the colour enters as `--c`, see `LedgerUI.Color`).

      <.spinner color="primary" variant="soft" size="md" label="Saving" />

  With a `label` (default `"Loading"`) it is `role="status"` and `aria-label`led; pass
  `label={nil}` for a purely decorative one. `white` and `current` (the surrounding text colour)
  are for spinners inside filled buttons.
  """
  use LedgerUI.Component

  # `--s` is the diameter; the ring thickness is a fraction of it
  @sizes %{
    "xs" => "[--s:12px]",
    "sm" => "[--s:16px]",
    "md" => "[--s:20px]",
    "lg" => "[--s:28px]",
    "xl" => "[--s:40px]"
  }

  @base "inline-block size-(--s) flex-none text-(--c)"

  # the animation is one utility per variant: `elastic` swaps the easing inside it
  defp variant_cls("border", elastic?),
    do: [
      "rounded-full border-solid border-[color-mix(in_oklab,currentColor_18%,transparent)] border-t-current",
      "border-[length:calc(var(--s)*.12_+_.5px)]",
      if(elastic?,
        do: "animate-[lu-spin_.7s_cubic-bezier(.68,-.55,.27,1.55)_infinite]",
        else: "animate-[lu-spin_.7s_linear_infinite]"
      )
    ]

  defp variant_cls("canvas", elastic?),
    do: [
      "rounded-full bg-[conic-gradient(from_0deg,transparent_0_20%,currentColor)]",
      "[mask:radial-gradient(farthest-side,transparent_calc(100%_-_3px),#000_calc(100%_-_2.5px))]",
      if(elastic?,
        do: "animate-[lu-spin_.8s_cubic-bezier(.68,-.55,.27,1.55)_infinite]",
        else: "animate-[lu-spin_.8s_linear_infinite]"
      )
    ]

  defp variant_cls("soft", elastic?),
    do: [
      "rounded-full border-solid border-[color-mix(in_oklab,currentColor_28%,transparent)] border-r-current",
      "border-[length:calc(var(--s)*.14)]",
      if(elastic?,
        do: "animate-[lu-spin_1s_cubic-bezier(.68,-.55,.27,1.55)_infinite]",
        else: "animate-[lu-spin_1s_ease-in-out_infinite]"
      )
    ]

  defp variant_cls("grow", elastic?),
    do: [
      "rounded-full bg-current",
      if(elastic?,
        do: "animate-[lu-grow_.9s_cubic-bezier(.68,-.55,.27,1.55)_infinite]",
        else: "animate-[lu-grow_.9s_ease-in-out_infinite]"
      )
    ]

  defp variant_cls("svg", _elastic?),
    do: "[&>svg]:size-full [&>svg]:animate-[lu-spin_1.2s_linear_infinite]"

  @svg ~s(<svg data-part="spinner-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><path d="M12 3a9 9 0 1 1-9 9"/></svg>)

  @doc false
  # The class list of a spinner (also used by the toast hook, which draws spinners in JS).
  def classes(color, variant, size, elastic? \\ false) do
    cx([@base, LedgerUI.Color.vars(color), @sizes[size], variant_cls(variant, elastic?)])
  end

  attr :color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary info success warning error white current)

  attr :variant, :string, default: "canvas", values: ~w(canvas border soft grow svg)
  attr :size, :string, default: "sm", values: ~w(xs sm md lg xl)
  attr :elastic, :boolean, default: false, doc: "An elastic easing instead of the default one."
  attr :label, :any, default: :default, doc: "Accessible name; `nil` for a decorative spinner."
  attr :class, :any, default: nil
  attr :rest, :global

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def spinner(assigns) do
    assigns = I18n.texts(assigns, [label: "common.loading"], :default)

    assigns =
      assigns
      |> assign(:classes, classes(assigns.color, assigns.variant, assigns.size, assigns.elastic))
      |> assign(:attrs, attrs(assigns))
      |> assign(:svg, if(assigns.variant == "svg", do: {:safe, @svg}))

    ~H"""
    <span data-part="spinner" class={[@classes, @class]} {@attrs}>{@svg}</span>
    """
  end

  defp attrs(a) do
    if a.label,
      do: Map.merge(a.rest, %{:role => "status", :"aria-label" => a.label}),
      else: a.rest
  end
end
