defmodule LedgerUI.Components.FormSection do
  @moduledoc """
  A group of fields under a small title, laid out in a grid.

      <.form_section title="Contato">
        <.input field={@form[:email]} label="E-mail" />
        <.input field={@form[:phone]} label="Telefone" />
      </.form_section>

      <.form_section title="Endereco" description="Usado na NF-e" layout="aside" columns={3}>
        <.input field={@form[:zip]} label="CEP" />
      </.form_section>

  `stacked` (default) puts the title over the fields and closes the section with a line
  (`divider={false}` drops it); `aside` puts the title and description in a column at the left.
  The fields go in `columns` columns (two by default). The `:action` slot sits at the right of a
  stacked title.
  """
  use LedgerUI.Component

  attr :title, :string, required: true
  attr :description, :string, default: nil
  attr :layout, :string, default: "stacked", values: ~w(stacked aside)

  attr :variant, :string,
    default: nil,
    values: [nil, "stacked", "aside"],
    doc: "The same as `layout`; it wins when given."

  attr :columns, :integer, default: 2, values: [1, 2, 3]
  attr :divider, :boolean, default: nil, doc: "On by default for `stacked`, off for `aside`."
  attr :id, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :action, doc: "At the right of a stacked title (a link, a toggle)."
  slot :inner_block, required: true

  @doc "Renders a form section; the inner block is its fields."
  def form_section(assigns) do
    assigns = assign(assigns, :layout, assigns.variant || assigns.layout)
    divider? = if assigns.divider == nil, do: assigns.layout == "stacked", else: assigns.divider

    assigns =
      assigns
      |> assign(
        :classes,
        cx(["lu-fsec", assigns.layout == "aside" && "aside", assigns.class])
      )
      |> assign(:attrs, with_style(assigns.rest, divider_style(divider?)))
      |> assign(:cols_style, "--cols:#{assigns.columns}")

    ~H"""
    <div data-part="form-section" id={@id} class={@classes} {@attrs}>
      <div :if={@action == []} class="h">
        <b>{@title}</b>
        <p :if={@description}>{@description}</p>
      </div>
      <div :if={@action != []} class="h" style="display:flex;align-items:flex-start;gap:12px">
        <div style="flex:1;min-width:0">
          <b>{@title}</b>
          <p :if={@description}>{@description}</p>
        </div>
        <div data-part="action">{render_slot(@action)}</div>
      </div>
      <div class="f" style={@cols_style}>{render_slot(@inner_block)}</div>
    </div>
    """
  end

  # `style={nil}` would render `style=""`, so it goes in a map only when there is one.
  defp with_style(rest, nil), do: rest
  defp with_style(rest, style), do: Map.put(rest, :style, style)

  defp divider_style(true), do: "padding-bottom:18px;border-bottom:1px solid var(--line)"
  defp divider_style(_), do: nil
end
