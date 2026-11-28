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
  `:disabled`. Each pill is a chip button (`aria-pressed` draws the chosen one) and the choice is made in the
  browser by the `LedgerUI.PillSelect` hook; the values travel in hidden inputs (`name`, or
  `name[]` with `multiple`, preceded by an empty one so an emptied choice still reaches the
  server) that fire a bubbling `input` event, so the form's `phx-change` runs. Without a form,
  `on_change` is pushed on each click with `%{"id" => id, "value" => value}` to `target`.

  `on_change` is an event name or a `%Phoenix.LiveView.JS{}` (as in `segmented`): the JS is run on each
  click, without the value (put it in the command, or read it from the hidden inputs).
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Chip
  alias LedgerUI.Components.Select.Options

  # classes of `<.icon size="sm">`, for the check the hook adds to a chosen pill
  @icon_class "inline flex-none fill-none stroke-current stroke-[1.75] [stroke-linecap:round] [stroke-linejoin:round] align-middle size-3.5"

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

  attr :on_change, :any,
    default: nil,
    doc:
      "An event name (pushed with `%{\"id\" => id, \"value\" => value}`) or a `%JS{}` to run on a click."

  attr :target, :any, default: nil

  attr :shape, :string,
    default: "rounded",
    values: ~w(rounded pill),
    doc: "`pill` makes the chips fully round."

  attr :wrapper_class, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(form)

  def pill_select(assigns) do
    changed0 = assigns.__changed__
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
      |> assign(:row_class, ["flex flex-wrap items-center gap-2.5", assigns.class])
      |> assign(:chip_class, pill_chip_class(assigns.multiple, assigns.shape))
      |> assign(:count_class, Chip.count_class())
      |> assign(:icon_class, @icon_class)
      |> assign(:on_change_attr, on_change(assigns.on_change))

    assigns =
      settle(assigns, changed0,
        opts: [:options],
        selected: [:value, :multiple],
        field_name: [:name, :multiple],
        row_class: [:class],
        chip_class: [:multiple, :shape],
        count_class: [],
        icon_class: [],
        on_change_attr: [:on_change]
      )

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
        data-part="pill-select"
        class={@row_class}
        role={@label && "group"}
        aria-labelledby={@label && @id <> "-label"}
        phx-hook="LedgerUI.PillSelect"
        data-lu-multiple={@multiple && ""}
        data-lu-icon-class={@multiple && @icon_class}
        data-lu-on-change={@on_change_attr}
        data-lu-target={@target && to_string(@target)}
        {@rest}
      >
        <button
          :for={o <- @opts}
          type="button"
          data-part="chip"
          class={@chip_class}
          data-lu-toggle=""
          data-lu-value={o.value != o.label && o.value}
          aria-pressed={to_string(o.value in @selected)}
          disabled={@disabled || o.disabled}
        >
          <.icon :if={@multiple && o.value in @selected} name="check" size="sm" />{o.label}<span
            :if={o.count}
            data-part="chip-count"
            class={@count_class}
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

  defp pill_chip_class(multiple, shape) do
    tokens =
      Chip.chip_class(if(multiple, do: "acc"), false)
      |> List.flatten()
      |> Enum.filter(&is_binary/1)
      |> Enum.flat_map(&String.split/1)
      |> Enum.reject(&String.starts_with?(&1, "rounded"))

    [Enum.join(tokens, " "), if(shape == "pill", do: "rounded-full", else: "rounded-sm")]
  end

  defp on_change(nil), do: nil
  defp on_change(name) when is_binary(name), do: name
  defp on_change(%Phoenix.LiveView.JS{} = js), do: LedgerUI.Helpers.js_json(js)

  defp on_change(other) do
    raise ArgumentError,
          "pill_select: `on_change` is an event name or a %Phoenix.LiveView.JS{}, got: #{inspect(other)}"
  end
end
