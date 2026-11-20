defmodule LedgerUI.Components.Alert do
  @moduledoc """
  Persistent inline notice with colour, variant, shape, accent stripe, actions and a close button.

      <.alert color="warning" variant="soft">
        <:icon><.icon name="alert" /></:icon>
        <div class="t"><b>Certificate expires in 12 days</b><span>Renew it to keep issuing.</span></div>
        <:action><button class="lu-b c-warning v-soft s-xs sh-rounded" type="button">Renew</button></:action>
      </.alert>

      <.alert id="saved" color="success" dismissible on_dismiss="hide_notice">Changes saved.</.alert>

  A short notice can use `title` and `description` instead:
  `<.alert color="warning" title="Certificate expires" description="Renew it." />`. The content is yours: write `<div class="t"><b>Title</b><span>Text</span></div>` for the
  title-plus-line layout. The close button hides the alert in the browser (no round trip) and, with
  `on_dismiss`, tells the server (`%{"id" => id}`). `dismiss_alert/1` does the same for a
  button placed by hand: `<button phx-click={dismiss_alert()}>Later</button>`.
  """
  use LedgerUI.Component

  @colors ~w(neutral primary secondary info success warning error dark)
  @variants ~w(canvas solid outline soft bordered)

  @accent %{
    nil => nil,
    "" => "accent",
    true => "accent",
    "top" => "accent",
    "left" => "acc-left",
    "right" => "acc-right"
  }

  @close_style "border:0;background:none;color:inherit;opacity:.7;cursor:pointer"

  attr :id, :string, default: nil
  attr :color, :string, default: "neutral", values: [nil | @colors]
  attr :variant, :string, default: "canvas", values: [nil | @variants]
  attr :shape, :string, default: "rounded", values: ~w(rounded pill)

  attr :accent, :any,
    default: nil,
    values: [nil, "", true, "top", "left", "right"],
    doc: "The colored stripe: `top` (or just `accent`), `left`, `right`."

  attr :description, :string,
    default: nil,
    doc:
      "The line under the title (`title=\"...\"`): written as `<div class=\"t\"><b>title</b><span>description</span></div>`."

  attr :dismissible, :boolean, default: false
  attr :on_dismiss, :any, default: nil, doc: "Event name or `%JS{}` run when the alert is closed."
  attr :target, :any, default: nil, doc: "`phx-target` of `on_dismiss`."
  attr :close_label, :string, default: "Close"
  attr :open, :boolean, default: true
  attr :class, :any, default: nil
  attr :rest, :global

  slot :action, doc: "Controls after the content."

  slot :icon, doc: "Icon before the content." do
    attr :boxed, :boolean
  end

  slot :inner_block

  def alert(assigns) do
    # `title` is a global HTML attribute, so it arrives in `rest`: here it is the bold line
    {title, rest} = Map.pop(assigns.rest, :title)

    assigns =
      assigns
      |> assign(:rest, rest)
      |> assign(:title_text, title)
      |> assign(
        :classes,
        cx([
          "lu-al",
          assigns.color && "c-" <> assigns.color,
          assigns.variant && "v-" <> assigns.variant,
          assigns.shape == "pill" && "sh-pill",
          @accent[assigns.accent],
          assigns.class
        ])
      )
      |> assign(:attrs, Map.put_new(rest, :role, "alert"))
      |> assign(:close_style, @close_style)
      |> assign(:dismiss_js, dismiss_js(assigns))

    ~H"""
    <div id={@id} data-part="alert" class={@classes} hidden={!@open} {@attrs}>
      <%= for icon <- @icon do %>
        <span :if={icon[:boxed]} class="lu-ic">{render_slot(icon)}</span>
        <%= if !icon[:boxed] do %>
          {render_slot(icon)}
        <% end %>
      <% end %>
      <div :if={@title_text || @description} class="t">
        <b :if={@title_text}>{@title_text}</b><span :if={@description}>{@description}</span>
      </div>
      {render_slot(@inner_block)}
      {render_slot(@action)}
      <button
        :if={@dismissible}
        type="button"
        class="x"
        aria-label={@close_label}
        style={@close_style}
        phx-click={@dismiss_js}
      >
        <.icon name="x" size="md" />
      </button>
    </div>
    """
  end

  defp dismiss_js(%{dismissible: false}), do: nil

  defp dismiss_js(%{on_dismiss: on_dismiss, id: id, target: target}) do
    hide = dismiss_alert()

    case on_dismiss do
      nil -> hide
      %JS{} = js -> JS.concat(hide, js)
      event when is_binary(event) -> JS.push(hide, event, value: %{id: id}, target: target)
    end
  end

  @doc """
  JS command that fades out and hides the alert around the element that runs it.

      <button phx-click={dismiss_alert()}>Remind me later</button>
  """
  @spec dismiss_alert(JS.t()) :: JS.t()
  def dismiss_alert(js \\ %JS{}) do
    JS.hide(js,
      to: {:closest, ".lu-al"},
      transition: {"transition-opacity duration-200", "opacity-100", "opacity-0"},
      time: 200
    )
  end
end
