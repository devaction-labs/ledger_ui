defmodule LedgerUI.Components.InputGroup do
  @moduledoc """
  Joins inputs, addons, selects and buttons into one row with shared borders.

      <.input_group>
        <.input_group_addon>R$</.input_group_addon>
        <.input name="amount" variant="plain" />
        <.input_group_addon>,00</.input_group_addon>
      </.input_group>

      <.input_group label="Price" size="sm" errors={["must be positive"]}>
        <.input_group_addon variant="filled">$</.input_group_addon>
        <.input name="amount" variant="plain" size="sm" state="error" />
      </.input_group>

  The row is a `role="group"` named by the caption (`aria-labelledby`; give each group an `id`
  when two share a label). With `errors` (or `state="error"`) every border of the row turns red,
  and the row gets `aria-invalid` and an `aria-describedby` that points at the messages.

  The group draws the shared border, so an `input/1` inside it takes `variant="plain"`.
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Form

  @heights %{"sm" => "h-8", "md" => "h-9", "lg" => "h-10"}

  # The row draws the border and the ring; every child is flush with it: no radius, a divider
  # on its left (the first one is pushed under the border) and the text input takes the rest.
  @row "items-stretch overflow-hidden border text-sm focus-within:shadow-[0_0_0_3px_var(--lu-focus)] [&>*]:rounded-none! [&>*]:border-y-0! [&>*]:border-r-0! [&>*]:border-l! [&>*]:border-solid! [&>*]:border-line! [&>:first-child]:-ml-px [&>[data-part=input]]:h-auto! [&>[data-part=input]]:min-w-[120px] [&>[data-part=input]]:flex-1 [&>[data-part=input]]:bg-transparent! [&>[data-part=input]]:px-3! [&>[data-part=input]]:shadow-none!"

  defp row_class(variant, shape, size, state, extra) do
    [
      if(extra == :block, do: "flex w-full", else: "inline-flex"),
      @row,
      @heights[size],
      if(shape == "pill", do: "rounded-full", else: "rounded-md"),
      if(variant == "filled", do: "bg-sunken", else: "bg-panel"),
      cond do
        state == "error" -> "border-neg focus-within:border-neg"
        state == "success" -> "border-pos focus-within:border-accent-500"
        variant == "filled" -> "border-transparent focus-within:border-accent-500"
        true -> "border-line-strong focus-within:border-accent-500"
      end
    ]
  end

  attr :id, :string, default: nil
  attr :shape, :string, default: "rounded", values: ~w(rounded pill)
  attr :size, :string, default: "md", values: ~w(sm md lg)
  attr :variant, :string, default: "outlined", values: ~w(outlined filled)
  attr :label, :string, default: nil
  attr :label_class, :any, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :state, :string, default: nil, values: [nil, "", "success", "error"]
  attr :wrapper_class, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "Renders the row; `label` adds a caption above it, `help` and `errors` a line below."
  def input_group(assigns) do
    changed0 = assigns.__changed__
    errors = Enum.map(assigns.errors, &Form.lu_translate_error/1)
    wrapped? = assigns.label != nil or assigns.help != nil or errors != []
    invalid? = errors != [] or assigns.state == "error"
    id = assigns.id || (assigns.label && "igrp-" <> slug(assigns.label))

    assigns =
      assigns
      |> assign(:msgs, errors)
      |> assign(:wrapped, wrapped?)
      |> assign(:invalid, invalid?)
      |> assign(:gid, id)
      |> assign(:label_id, assigns.label && id && id <> "-label")
      |> assign(:msg_id, wrapped? && id && id <> "-msg")
      |> assign(:row_class, [
        row_class(
          assigns.variant,
          assigns.shape,
          assigns.size,
          if(errors != [], do: "error", else: assigns.state),
          nil
        ),
        assigns.class
      ])

    # The messages (`msgs`) are translated with the process locale: they are sent every time.
    # A new label or message must not send the classes again.
    assigns =
      settle(assigns, changed0,
        wrapped: [:label, :help, :errors],
        invalid: [:errors, :state],
        gid: [:id, :label],
        label_id: [:id, :label],
        msg_id: [:id, :label, :help, :errors],
        row_class: [:variant, :shape, :size, :errors, :state, :class]
      )

    ~H"""
    <Form.field
      :if={@wrapped}
      as="div"
      label={@label}
      label_class={@label_class}
      label_id={@label_id}
      help={@help}
      errors={@msgs}
      state={@state}
      msg_id={@msg_id}
      class={@wrapper_class}
    >
      <.row
        wrapped
        gid={@gid}
        row_class={@row_class}
        label_id={@label_id}
        invalid={@invalid}
        msg_id={@msg_id}
        extra={@rest}
      >
        {render_slot(@inner_block)}
      </.row>
    </Form.field>
    <.row
      :if={!@wrapped}
      wrapped={false}
      gid={@gid}
      row_class={@row_class}
      label_id={nil}
      invalid={@invalid}
      msg_id={nil}
      extra={@rest}
    >
      {render_slot(@inner_block)}
    </.row>
    """
  end

  attr :wrapped, :boolean, default: true
  attr :gid, :string, default: nil
  attr :row_class, :any, required: true
  attr :label_id, :any, default: nil
  attr :invalid, :boolean, default: false
  attr :msg_id, :any, default: nil
  attr :extra, :map, default: %{}
  slot :inner_block, required: true

  defp row(assigns) do
    ~H"""
    <span
      data-part="input-group"
      id={@gid}
      role={@wrapped && "group"}
      class={@row_class}
      aria-labelledby={@label_id}
      aria-invalid={@wrapped && @invalid && "true"}
      aria-describedby={@wrapped && @invalid && @msg_id}
      {@extra}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  defp slug(text) do
    text
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, "-")
    |> String.trim("-")
  end

  attr :variant, :string, default: "outline", values: ~w(outline filled)
  attr :size, :string, default: "md", values: ~w(sm md lg)
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "A text or icon box at either end (or between the inputs) of an `input_group`."
  def input_group_addon(assigns) do
    changed0 = assigns.__changed__

    assigns =
      assigns
      |> assign(:classes, [
        "flex items-center bg-sunken px-3 text-sm whitespace-nowrap text-muted",
        assigns.class
      ])
      |> then(&settle(&1, changed0, classes: [:class]))

    ~H"""
    <span data-part="addon" class={@classes} {@rest}>{render_slot(@inner_block)}</span>
    """
  end
end
