defmodule LedgerUI.Components.Scrollspy do
  @moduledoc """
  A list of links to the sections of the page that marks the section in view.

      <.scrollspy id="settings-nav" offset={96}>
        <:item href="#profile">Profile</:item>
        <:item href="#security">Security</:item>
      </.scrollspy>

  The hook `LedgerUI.Scrollspy` (`priv/static/ledger_ui/hooks/scrollspy.js`) watches the elements
  the links point at and moves `aria-current="true"` to the link of the
  section at the top of the view (`offset` pixels from the top, 120 by default). A click scrolls
  to the section smoothly (instantly with `prefers-reduced-motion`). The marked link turns `ink`
  and a 2px bar on the left edge slides to it: the hook writes `--spy-y` and `--spy-h` (the
  link's offset and height) on the nav and the bar follows them.

  The server renders `aria-current="true"` on an item given `active` (the initial
  state); the hook only updates it as the page scrolls.

  The root is a `<nav>`; wrap it in a grid yourself. `label: nil` omits the `aria-label`.
  `demo` is the animated mock (the marker walks over the links by itself: stagger them with
  `style="--dl:2s"`), which does not need the hook. Styled only with Tailwind utilities; the parts are
  `data-part="scrollspy"` and `"scrollspy-link"`.
  """

  use LedgerUI.Component

  attr :id, :string, required: true
  attr :label, :any, default: :default
  attr :offset, :integer, default: 120

  attr :target, :string,
    default: nil,
    doc:
      "A selector (`\"#doc\"`) of the element that scrolls the sections, when it is not the page."

  attr :demo, :boolean,
    default: false,
    doc: "The animated mock: the marker walks over the links, no hook needed."

  attr :class, :any, default: nil
  attr :rest, :global

  slot :item, required: true do
    attr :href, :string
    attr :active, :boolean
    attr :class, :any
    attr :style, :string
    attr :id, :string
  end

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def scrollspy(assigns) do
    assigns = I18n.texts(assigns, [label: "scrollspy.label"], :default)

    assigns =
      assigns
      |> assign(:offset_attr, if(assigns.offset != 120, do: assigns.offset))
      |> assign(:nav_class, nav_class(assigns))
      |> assign(:link_class, link_class(assigns.demo))

    ~H"""
    <nav
      id={@id}
      data-part="scrollspy"
      class={@nav_class}
      aria-label={@label}
      phx-hook={!@demo && "LedgerUI.Scrollspy"}
      data-offset={@offset_attr}
      data-target={@target}
      keep-style
      {@rest}
    >
      <a
        :for={item <- @item}
        data-part="scrollspy-link"
        class={[@link_class, drop_on(item[:class])]}
        {item_attrs(item)}
      >{render_slot(item)}</a>
    </nav>
    """
  end

  @nav "relative flex flex-col gap-0.5 border-l border-line before:absolute before:-left-px before:top-0 before:w-0.5 before:rounded-[2px] before:bg-ink before:content-['']"
  @nav_real "before:h-[var(--spy-h,32px)] before:[transform:translateY(var(--spy-y,0px))] before:transition-[transform,height] before:duration-200 before:ease-[cubic-bezier(.4,0,.2,1)] motion-reduce:before:transition-none"
  @nav_demo "before:h-8 before:animate-[mo-spybar_8s_cubic-bezier(.4,0,.2,1)_infinite]"

  defp nav_class(a), do: cx([@nav, if(a.demo, do: @nav_demo, else: @nav_real), a.class])

  @link "px-3 py-1.5 text-[13.5px] no-underline transition-[color,background] duration-150"
  @link_real "text-muted aria-[current=true]:font-medium aria-[current=true]:text-ink"
  @link_demo "text-muted animate-[mo-spya_8s_infinite] [animation-delay:var(--dl)]"

  defp link_class(demo?), do: [@link, if(demo?, do: @link_demo, else: @link_real)]

  # `active` (or the legacy class `on`) is the initial marker
  defp item_attrs(item) do
    attrs = Map.drop(item, [:__slot__, :inner_block, :active, :class])

    if item[:active] == true or on?(item[:class]),
      do: Map.put_new(attrs, :"aria-current", "true"),
      else: attrs
  end

  defp on?(class) when is_binary(class), do: "on" in String.split(class)
  defp on?(_), do: false

  defp drop_on(class) when is_binary(class),
    do: class |> String.split() |> List.delete("on") |> Enum.join(" ")

  defp drop_on(class), do: class
end
