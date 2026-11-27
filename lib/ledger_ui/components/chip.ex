defmodule LedgerUI.Components.Chip do
  @moduledoc """
  The chip: a small tag for a quick filter, an applied filter or a selected person.

      <.chip>Hoje</.chip>
      <.chip selected={@pro?} phx-click="toggle" value="pro">Pro</.chip>
      <.chip selected={false} count={12}>Atrasados</.chip>
      <.chip dashed icon="plus">Filtro</.chip>
      <.chip label="Situação: Aprovação" on_remove={JS.hide(to: "#c1")} id="c1" />
      <.chip avatar="Marina Costa" on_remove="remove_person" id="p-1">Marina Costa</.chip>
      <.chip patch={~p"/extract?account=1"} label="Conta 1" />
      <.chip label="Aberta" remove_patch={~p"/tasks"} />

    * a plain chip is a `<span>`; with `selected` (`true`/`false`) it is a toggle button
      (`aria-pressed`, the chosen state is the inverse colour) that flips in the browser unless
      you give it a `phx-click`; `dashed` and `phx-click` make it a button too;
    * with `href`, `navigate` or `patch` it is a link and has no x;
    * `on_remove` (an event name, pushed with `%{"id" => id}` to `target`, or a `JS` command)
      adds the x button; `remove_patch` makes the x a `patch` link instead;
    * `size` is the height: `sm` 24px (chips inside a field), `md` 30px (default), `lg` 32px
      (`<.chip size="lg">`); padding, font and icon stay the same.
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Select.Options

  @base "group inline-flex cursor-pointer items-center gap-1.5 border border-line-strong bg-panel px-[11px] text-[13px] font-medium hover:bg-hover"

  # the chosen look reads `aria-pressed` (a toggle button) or `aria-current` (a link)
  @on "aria-pressed:border-inverse aria-pressed:bg-inverse aria-pressed:text-on-inverse aria-[current=true]:border-inverse aria-[current=true]:bg-inverse aria-[current=true]:text-on-inverse"
  @on_acc "aria-pressed:border-[color-mix(in_oklab,var(--color-accent)_45%,transparent)] aria-pressed:bg-accent-soft aria-pressed:text-accent-content aria-[current=true]:border-[color-mix(in_oklab,var(--color-accent)_45%,transparent)] aria-[current=true]:bg-accent-soft aria-[current=true]:text-accent-content"

  @sizes %{"sm" => "h-6", "md" => "h-[30px]", "lg" => "h-8"}

  @remove "inline-grid cursor-pointer border-0 bg-transparent p-0 text-inherit"

  @doc false
  # The class list of a chip. `size` is the height (`md` 30px, `sm` 24px for chips inside a field, `lg` 32px).
  def chip_class(tone, dashed, size \\ "md", shape \\ "rounded") do
    [
      @base,
      if(shape == "pill", do: "rounded-full", else: "rounded-md"),
      @sizes[size] || @sizes["md"],
      if(tone == "acc", do: @on_acc, else: @on),
      if(dashed, do: "border-dashed text-muted", else: "text-ink-2")
    ]
  end

  @doc false
  def count_class,
    do:
      "text-xs text-muted tabular-nums group-aria-pressed:text-inherit group-aria-pressed:opacity-70"

  @doc false
  def remove_class, do: @remove

  attr(:label, :string, default: nil)
  attr(:selected, :boolean, default: nil, doc: "`true`/`false` makes the chip a toggle.")
  attr(:dashed, :boolean, default: false)
  attr(:tone, :string, default: nil, values: [nil, "default", "acc"])
  attr(:size, :string, default: "md", values: ~w(sm md lg), doc: "Height: 24px, 30px or 32px.")

  attr(:shape, :string,
    default: "rounded",
    values: ~w(rounded pill),
    doc: "`rounded` (8px, default) or `pill` (fully round)."
  )

  attr(:icon, :string, default: nil)
  attr(:count, :any, default: nil)
  attr(:avatar, :string, default: nil)
  attr(:avatar_color, :string, default: nil)
  attr(:avatar_src, :string, default: nil)
  attr(:on_remove, :any, default: nil)
  attr(:remove_patch, :string, default: nil)
  attr(:id, :string, default: nil)
  attr(:target, :any, default: nil)
  attr(:remove_label, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(href navigate patch method download value disabled))
  slot(:inner_block)

  attr(:locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."
  )

  def chip(assigns) do
    changed0 = assigns.__changed__
    assigns = I18n.texts(assigns, remove_label: "common.remove")

    rest = assigns.rest
    link? = Enum.any?([:href, :navigate, :patch], &Map.has_key?(rest, &1))
    toggle? = assigns.selected != nil
    button? = !link? && (toggle? || assigns.dashed || Map.has_key?(rest, :"phx-click"))

    assigns =
      assigns
      |> assign(:link?, link?)
      |> assign(:button?, button?)
      |> assign(:toggle?, toggle? && !link?)
      |> assign(:classes, [
        chip_class(assigns.tone, assigns.dashed, assigns.size, assigns.shape),
        assigns.class
      ])
      |> assign(
        :toggle_js,
        toggle? && !link? && !Map.has_key?(rest, :"phx-click") &&
          JS.toggle_attribute({"aria-pressed", "true", "false"})
      )
      |> assign(:remove_js, remove_js(assigns))
      |> assign(:tone_class, assigns.avatar && Options.avatar_tone(assigns.avatar))
      |> assign(:initials, assigns.avatar && Options.initials(assigns.avatar))
      |> assign(:removable?, !link? && (assigns.on_remove != nil || assigns.remove_patch != nil))
      |> assign(:remove_cls, @remove)
      |> assign(:count_cls, count_class())

    # A new label or count must not send the classes again.
    assigns =
      settle(assigns, changed0,
        link?: [:rest],
        button?: [:rest, :selected, :dashed],
        toggle?: [:rest, :selected],
        classes: [:tone, :dashed, :size, :shape, :class],
        toggle_js: [:rest, :selected],
        remove_js: [:on_remove, :id, :target],
        tone_class: [:avatar],
        initials: [:avatar],
        removable?: [:rest, :on_remove, :remove_patch],
        remove_cls: [],
        count_cls: []
      )

    ~H"""
    <%= cond do %>
      <% @link? -> %>
        <.link
          id={@id}
          data-part="chip"
          class={@classes}
          aria-current={@selected && "true"}
          {@rest}
        ><.chip_body
          avatar={@avatar}
          avatar_color={@avatar_color}
          avatar_src={@avatar_src}
          count={@count}
          count_cls={@count_cls}
          icon={@icon}
          initials={@initials}
          inner_block={@inner_block}
          label={@label}
          remove_cls={@remove_cls}
          remove_js={@remove_js}
          remove_label={@remove_label}
          remove_patch={@remove_patch}
          removable?={@removable?}
          tone_class={@tone_class}
        /></.link>
      <% @button? -> %>
        <button
          id={@id}
          type="button"
          data-part="chip"
          class={@classes}
          data-lu-toggle={@toggle? && ""}
          aria-pressed={@toggle? && to_string(@selected)}
          phx-click={@toggle_js || nil}
          {@rest}
        >
          <.chip_body
            avatar={@avatar}
            avatar_color={@avatar_color}
            avatar_src={@avatar_src}
            count={@count}
            count_cls={@count_cls}
            icon={@icon}
            initials={@initials}
            inner_block={@inner_block}
            label={@label}
            remove_cls={@remove_cls}
            remove_js={@remove_js}
            remove_label={@remove_label}
            remove_patch={@remove_patch}
            removable?={@removable?}
            tone_class={@tone_class}
          />
        </button>
      <% true -> %>
        <span id={@id} data-part="chip" class={@classes} {@rest}><.chip_body
          avatar={@avatar}
          avatar_color={@avatar_color}
          avatar_src={@avatar_src}
          count={@count}
          count_cls={@count_cls}
          icon={@icon}
          initials={@initials}
          inner_block={@inner_block}
          label={@label}
          remove_cls={@remove_cls}
          remove_js={@remove_js}
          remove_label={@remove_label}
          remove_patch={@remove_patch}
          removable?={@removable?}
          tone_class={@tone_class}
        /></span>
    <% end %>
    """
  end

  defp chip_body(assigns) do
    ~H"""
    <Options.avatar
      :if={@avatar}
      tone={@tone_class}
      color={@avatar_color}
      src={@avatar_src}
      initials={@initials}
      size={24}
    />
    <.icon :if={@icon} name={@icon} size="sm" />
    <%= if @inner_block != [] do %>
      {render_slot(@inner_block)}
    <% else %>
      {@label}
    <% end %>
    <span :if={@count} data-part="chip-count" class={@count_cls}>{@count}</span>
    <.link
      :if={@removable? && @remove_patch}
      patch={@remove_patch}
      data-part="chip-remove"
      aria-label={@remove_label}
      class={@remove_cls}
    >
      <.icon name="x" size="sm" />
    </.link>
    <button
      :if={@removable? && !@remove_patch}
      type="button"
      data-part="chip-remove"
      aria-label={@remove_label}
      class={@remove_cls}
      phx-click={@remove_js}
    >
      <.icon name="x" size="sm" />
    </button>
    """
  end

  defp remove_js(%{on_remove: %JS{} = js}), do: js

  defp remove_js(%{on_remove: event} = assigns) when is_binary(event) do
    opts = [value: %{id: assigns.id}]
    opts = if assigns.target, do: Keyword.put(opts, :target, assigns.target), else: opts
    JS.push(event, opts)
  end

  defp remove_js(_), do: nil
end
