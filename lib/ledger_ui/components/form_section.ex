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
      |> assign(:classes, [
        "grid gap-[18px]",
        if(assigns.layout == "aside", do: "grid-cols-[220px_1fr]"),
        divider? && "border-b border-line pb-[18px]",
        assigns.class
      ])
      |> assign(:cols_class, cols_class(assigns.columns))

    ~H"""
    <div data-part="form-section" id={@id} class={@classes} {@rest}>
      <div :if={@action == []} data-part="form-section-head">
        <b data-part="form-section-title" class="text-[15px]">{@title}</b>
        <p
          :if={@description}
          data-part="form-section-description"
          class="mt-1 mb-0 text-[13px] text-muted"
        >
          {@description}
        </p>
      </div>
      <div
        :if={@action != []}
        data-part="form-section-head"
        class="flex items-start gap-3"
      >
        <div class="min-w-0 flex-1">
          <b data-part="form-section-title" class="text-[15px]">{@title}</b>
          <p
            :if={@description}
            data-part="form-section-description"
            class="mt-1 mb-0 text-[13px] text-muted"
          >
            {@description}
          </p>
        </div>
        <div data-part="action">{render_slot(@action)}</div>
      </div>
      <div data-part="form-section-fields" class={["grid gap-x-3.5 gap-y-3", @cols_class]}>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  defp cols_class(1), do: "grid-cols-1"
  defp cols_class(3), do: "grid-cols-3"
  defp cols_class(_), do: "grid-cols-2"
end
