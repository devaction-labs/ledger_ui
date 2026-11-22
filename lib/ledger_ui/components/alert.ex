defmodule LedgerUI.Components.Alert do
  @moduledoc """
  Persistent inline notice with colour, variant, shape, accent stripe, actions and a close button.
  Styled only with Tailwind utilities (the colour enters as `--c`/`--c-on`/`--c-soft`/`--c-ink`, see
  `LedgerUI.Color`).

      <.alert color="warning" variant="soft" title="Certificate expires in 12 days"
              description="Renew it to keep issuing.">
        <:icon><.icon name="alert" /></:icon>
        <:action><.button color="warning" variant="soft" size="xs">Renew</.button></:action>
      </.alert>

      <.alert id="saved" color="success" dismissible on_dismiss="hide_notice">Changes saved.</.alert>

  `loop` plays the canvas loop of the alert entering (`mo-alin`, CSS only).

  `title` is the bold line and `description` the line under it; any other content goes in the
  inner block (a `<b>` inside it is bold too). The close button hides the alert in the browser (no
  round trip) and, with `on_dismiss`, tells the server (`%{"id" => id}`). `dismiss_alert/1` does the
  same for a button placed by hand: `<button phx-click={dismiss_alert()}>Later</button>`.
  """
  use LedgerUI.Component

  @colors ~w(neutral primary secondary info success warning error dark)
  @variants ~w(canvas solid outline soft bordered)

  # one utility per property: the variant decides background, text and border colour
  @variant_cls %{
    "canvas" => "border-line bg-panel text-ink [&>svg]:text-(--c-ink)",
    "solid" => "border-transparent bg-(--c) text-(--c-on)",
    "outline" => "border-[color-mix(in_oklab,var(--c)_55%,transparent)] text-(--c-ink)",
    "soft" => "border-transparent bg-(--c-soft) text-(--c-ink)",
    "bordered" =>
      "border-[color-mix(in_oklab,var(--c)_35%,transparent)] bg-(--c-soft) text-(--c-ink)"
  }

  # the line under the title is a quieter ink on the tinted variants
  @quiet ~w(outline soft bordered)

  @accent %{
    nil => nil,
    "" => "shadow-[inset_0_3px_0_var(--c)]",
    true => "shadow-[inset_0_3px_0_var(--c)]",
    "top" => "shadow-[inset_0_3px_0_var(--c)]",
    "left" => "shadow-[inset_3px_0_0_var(--c)]",
    "right" => "shadow-[inset_-3px_0_0_var(--c)]"
  }

  # `border-0` of the preflight is undone by the native 1px 6px of the original button
  @close "cursor-pointer border-0 bg-transparent px-1.5 py-px text-inherit opacity-70"

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
    doc: "The line under the title (`title=\"...\"`)."

  attr :dismissible, :boolean, default: false
  attr :on_dismiss, :any, default: nil, doc: "Event name or `%JS{}` run when the alert is closed."
  attr :target, :any, default: nil, doc: "`phx-target` of `on_dismiss`."
  attr :close_label, :string, default: nil
  attr :open, :boolean, default: true

  attr :loop, :boolean,
    default: false,
    doc: "The canvas loop (`mo-alin`): the alert slides in, stays, leaves, forever (demos)."

  attr :class, :any, default: nil
  attr :rest, :global

  slot :action, doc: "Controls after the content."

  slot :icon, doc: "Icon before the content." do
    attr :boxed, :boolean
  end

  slot :inner_block

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def alert(assigns) do
    assigns = I18n.texts(assigns, close_label: "common.close")

    # `title` is a global HTML attribute, so it arrives in `rest`: here it is the bold line
    {title, rest} = Map.pop(assigns.rest, :title)
    pill? = assigns.shape == "pill"

    assigns =
      assigns
      |> assign(:rest, rest)
      |> assign(:title_text, title)
      |> assign(
        :classes,
        cx([
          "flex gap-3 border text-sm leading-5 [&_b]:font-semibold",
          if(pill?,
            do: "items-center rounded-full px-[18px] py-2.5",
            else: "items-start rounded-lg px-3.5 py-3"
          ),
          assigns.color && LedgerUI.Color.vars(assigns.color),
          assigns.variant && @variant_cls[assigns.variant],
          !assigns.variant && "border-transparent",
          assigns.color && @accent[assigns.accent],
          assigns.loop &&
            "animate-[mo-alin_6s_cubic-bezier(.2,.8,.2,1)_infinite] motion-reduce:animate-none"
        ])
      )
      |> assign(:quiet?, assigns.variant in @quiet)
      |> assign(:attrs, Map.put_new(rest, :role, "alert"))
      |> assign(:close_cls, @close)
      |> assign(:dismiss_js, dismiss_js(assigns))

    ~H"""
    <div id={@id} data-part="alert" class={[@classes, @class]} hidden={!@open} {@attrs}>
      <%= for icon <- @icon do %>
        <span
          :if={icon[:boxed]}
          data-part="alert-icon"
          class="inline-grid size-8 flex-none place-items-center rounded-md bg-sunken text-ink-2"
        >{render_slot(icon)}</span>
        <%= if !icon[:boxed] do %>
          {render_slot(icon)}
        <% end %>
      <% end %>
      <div
        :if={@title_text || @description}
        data-part="alert-text"
        class="flex min-w-0 flex-1 flex-col gap-0.5"
      >
        <b :if={@title_text} data-part="alert-title">{@title_text}</b><span
          :if={@description}
          data-part="alert-description"
          class={@quiet? && "text-ink-2"}
        >{@description}</span>
      </div>
      {render_slot(@inner_block)}
      {render_slot(@action)}
      <button
        :if={@dismissible}
        type="button"
        data-part="alert-close"
        class={@close_cls}
        aria-label={@close_label}
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
      to: {:closest, "[data-part=alert]"},
      transition: {"transition-opacity duration-200", "opacity-100", "opacity-0"},
      time: 200
    )
  end
end
