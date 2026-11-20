defmodule LedgerUI.Components.PillSelect do
  @moduledoc """
  A quick filter of chips where the chosen ones take the accent: one choice by default, several
  with `multiple`.

      <.pill_select field={@form[:canal]} options={["Todos", "Balcão", "Online"]} />
      <.pill_select field={@form[:categorias]} multiple options={~w(Tintas Básico Ferramentas)} />
      <.pill_select name="canal" value="todos" options={[
        %{label: "Todos", value: "todos", count: 128},
        %{label: "Balcão", value: "balcao", count: 64}
      ]} />

  Options are strings, `{label, value}` tuples or maps with `:label`, `:value`, `:count` and
  `:disabled`. Each pill is a `lu-chip` button (`aria-pressed`) and the choice is made in the
  browser by the `LedgerUI.PillSelect` hook; the values travel in hidden inputs (`name`, or
  `name[]` with `multiple`, preceded by an empty one so an emptied choice still reaches the
  server) that fire a bubbling `input` event, so the form's `phx-change` runs. Without a form,
  `on_change` is pushed on each click with `%{"id" => id, "value" => value}` to `target`.
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Select.Options

  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :any, default: nil
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :options, :list, required: true
  attr :multiple, :boolean, default: false
  attr :label, :string, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :disabled, :boolean, default: false
  attr :on_change, :string, default: nil
  attr :target, :any, default: nil
  attr :wrapper_class, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(form)

  def pill_select(assigns) do
    assigns = Options.resolve(assigns, "pill-select", assigns.options)
    opts = assigns.options |> Options.normalize() |> Options.flatten()
    selected = Options.values(assigns.value)
    selected = if assigns.multiple, do: selected, else: Enum.take(selected, 1)

    name =
      assigns.name &&
        if(assigns.multiple && !String.ends_with?(assigns.name, "[]"),
          do: assigns.name <> "[]",
          else: assigns.name
        )

    assigns =
      assigns
      |> assign(:opts, opts)
      |> assign(:selected, selected)
      |> assign(:field_name, name)
      |> assign(:row_class, cx(["lu-row", assigns.class]))

    ~H"""
    <Options.shell
      tag="div"
      label={@label}
      help={@help}
      errors={@errors}
      for={@id}
      bare={true}
      class={@wrapper_class}
    >
      <div
        id={@id}
        class={@row_class}
        role={@label && "group"}
        aria-labelledby={@label && @id <> "-label"}
        phx-hook="LedgerUI.PillSelect"
        data-lu-multiple={@multiple && ""}
        data-lu-on-change={@on_change}
        data-lu-target={@target && to_string(@target)}
        {@rest}
      >
        <button
          :for={o <- @opts}
          type="button"
          class={["lu-chip", @multiple && "acc", o.value in @selected && "on"]}
          data-lu-toggle=""
          data-lu-value={o.value != o.label && o.value}
          aria-pressed={to_string(o.value in @selected)}
          disabled={@disabled || o.disabled}
        >
          <.icon :if={@multiple && o.value in @selected} name="check" size="sm" />{o.label}<span
            :if={o.count}
            class="n"
          >{o.count}</span>
        </button>
        <input :if={@field_name && @multiple} type="hidden" name={@field_name} value="" />
        <input
          :for={v <- @selected}
          :if={@field_name && !@disabled}
          type="hidden"
          name={@field_name}
          value={v}
          data-lu-v
        />
        <input
          :if={@field_name && !@multiple && @selected == []}
          type="hidden"
          name={@field_name}
          value=""
          data-lu-v
        />
      </div>
    </Options.shell>
    """
  end
end
