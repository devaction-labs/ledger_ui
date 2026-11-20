defmodule LedgerUI.Components.Chip do
  @moduledoc """
  The chip (`lu-chip`): a small tag for a quick filter, an applied filter or a selected person.

      <.chip>Hoje</.chip>
      <.chip selected={@pro?} phx-click="toggle" value="pro">Pro</.chip>
      <.chip selected={false} count={12}>Atrasados</.chip>
      <.chip dashed icon="plus">Filtro</.chip>
      <.chip label="Situação: Aprovação" on_remove={JS.hide(to: "#c1")} id="c1" />
      <.chip avatar="Marina Costa" on_remove="remove_person" id="p-1">Marina Costa</.chip>
      <.chip patch={~p"/extract?account=1"} label="Conta 1" />
      <.chip label="Aberta" remove_patch={~p"/tasks"} />

    * a plain chip is a `<span>`; with `selected` (`true`/`false`) it is a toggle button
      (`aria-pressed`, the `on` state is the inverse colour) that flips in the browser unless
      you give it a `phx-click`; `dashed` and `phx-click` make it a button too;
    * with `href`, `navigate` or `patch` it is a link and has no x;
    * `on_remove` (an event name, pushed with `%{"id" => id}` to `target`, or a `JS` command)
      adds the x button; `remove_patch` makes the x a `patch` link instead.
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Select.Options

  @rm_style "border:0;background:none;padding:0;display:inline-grid;cursor:pointer;color:inherit"

  attr :label, :string, default: nil
  attr :selected, :boolean, default: nil, doc: "`true`/`false` makes the chip a toggle."
  attr :dashed, :boolean, default: false
  attr :tone, :string, default: nil, values: [nil, "default", "acc"]
  attr :icon, :string, default: nil
  attr :count, :any, default: nil
  attr :avatar, :string, default: nil
  attr :avatar_color, :string, default: nil
  attr :avatar_src, :string, default: nil
  attr :on_remove, :any, default: nil
  attr :remove_patch, :string, default: nil
  attr :id, :string, default: nil
  attr :target, :any, default: nil
  attr :remove_label, :string, default: "Remove"
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch method download value disabled)
  slot :inner_block

  def chip(assigns) do
    rest = assigns.rest
    link? = Enum.any?([:href, :navigate, :patch], &Map.has_key?(rest, &1))
    toggle? = assigns.selected != nil
    button? = !link? && (toggle? || assigns.dashed || Map.has_key?(rest, :"phx-click"))

    assigns =
      assigns
      |> assign(:link?, link?)
      |> assign(:button?, button?)
      |> assign(:toggle?, toggle? && !link?)
      |> assign(
        :classes,
        cx([
          "lu-chip",
          assigns.tone == "acc" && "acc",
          assigns.selected && "on",
          assigns.dashed && "dashed",
          assigns.class
        ])
      )
      |> assign(
        :toggle_js,
        toggle? && !link? && !Map.has_key?(rest, :"phx-click") &&
          JS.toggle_class("on") |> JS.toggle_attribute({"aria-pressed", "true", "false"})
      )
      |> assign(:remove_js, remove_js(assigns))
      |> assign(:avatar_style, avatar_style(assigns))
      |> assign(:tone_class, assigns.avatar && Options.avatar_tone(assigns.avatar))
      |> assign(:initials, assigns.avatar && Options.initials(assigns.avatar))
      |> assign(:removable?, !link? && (assigns.on_remove != nil || assigns.remove_patch != nil))
      |> assign(:rm_style, @rm_style)

    ~H"""
    <%= cond do %>
      <% @link? -> %>
        <.link id={@id} class={@classes} {@rest}>{chip_body(assigns)}</.link>
      <% @button? -> %>
        <button
          id={@id}
          type="button"
          class={@classes}
          data-lu-toggle={@toggle? && ""}
          aria-pressed={@toggle? && to_string(@selected)}
          phx-click={@toggle_js || nil}
          {@rest}
        >
          {chip_body(assigns)}
        </button>
      <% true -> %>
        <span id={@id} class={@classes} {@rest}>{chip_body(assigns)}</span>
    <% end %>
    """
  end

  defp chip_body(assigns) do
    ~H"""
    <span :if={@avatar} class={cx(["lu-av", !@avatar_color && @tone_class])} style={@avatar_style}>
      <img
        :if={@avatar_src}
        src={@avatar_src}
        alt=""
        style="width:100%;height:100%;border-radius:inherit;object-fit:cover"
      />
      <%= if !@avatar_src do %>
        {@initials}
      <% end %>
    </span>
    <.icon :if={@icon} name={@icon} size="sm" />
    <%= if @inner_block != [] do %>
      {render_slot(@inner_block)}
    <% else %>
      {@label}
    <% end %>
    <span :if={@count} class="n">{@count}</span>
    <.link
      :if={@removable? && @remove_patch}
      patch={@remove_patch}
      aria-label={@remove_label}
      style={@rm_style}
    >
      <.icon name="x" size="sm" />
    </.link>
    <button
      :if={@removable? && !@remove_patch}
      type="button"
      aria-label={@remove_label}
      style={@rm_style}
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

  defp avatar_style(%{avatar: nil}), do: nil

  defp avatar_style(%{avatar_color: color}) when is_binary(color),
    do: "--s:24px;background:#{color};color:#fff"

  defp avatar_style(_), do: "--s:24px"
end
