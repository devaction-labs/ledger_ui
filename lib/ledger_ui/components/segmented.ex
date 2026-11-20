defmodule LedgerUI.Components.Segmented do
  @moduledoc """
  A segmented control: a row of toggle buttons where exactly one is chosen.

      <.segmented id="range" value={@range} on_change="set-range" options={~w(day month year)} />
      <.segmented field={@form[:view]} options={[{"List", "list"}, {"Board", "board"}]} />

      <.segmented id="view" value="board" options={[
        %{label: "Board", value: "board", icon: "kanban"},
        %{label: "All", value: "all", count: 128}
      ]} />

  Options are strings, `{label, value}` tuples or maps with `:label`, `:value`, `:icon`, `:count`
  and `:disabled`. It is a `role="group"` (see `role`) of buttons with `aria-pressed`. The choice is made in
  the browser (hook `LedgerUI.Segmented`, `priv/static/ledger_ui/hooks/segmented.js`): a new
  `value` from the server wins, a patch that does not change it leaves the person's choice
  alone, arrow keys/Home/End move the focus (one segment is in the Tab order).

  With a `name` (or `field`) the control submits through a hidden input that fires `input`, so a
  form's `phx-change` runs. `on_change` is an event name (pushed with
  `%{"id" => id, "value" => value}` to `target`) or a `%JS{}`.
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Select.Options

  @styles %{
    "size" => %{"sm" => "sm", "md" => nil, "lg" => "lg"},
    "shape" => %{"rounded" => nil, "pill" => nil}
  }
  @pill "border-radius:999px"

  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :any, default: nil
  attr :field, Phoenix.HTML.FormField, default: nil

  attr :options, :list,
    default: [],
    doc: "Strings, `{label, value}` tuples or maps; or write `<:option>` slots."

  attr :label, :string, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :size, :string, default: "md", values: ~w(sm md lg)
  attr :shape, :string, default: "rounded", values: ~w(rounded pill)
  attr :full, :boolean, default: false

  attr :stretch, :boolean,
    default: false,
    doc:
      "The canvas form of a full-width control: `width:100%` on the group, `flex:1` per button."

  attr :role, :string, default: "group", doc: "`group` (default) or what the surface needs."
  attr :disabled, :boolean, default: false
  attr :on_change, :any, default: nil
  attr :target, :any, default: nil
  attr :wrapper_class, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(form)

  slot :option,
    doc:
      "One segment, its content the label (instead of `options`). `value` defaults to the position; `selected` chooses it when `value` is not given." do
    attr :value, :any
    attr :label, :string
    attr :icon, :string
    attr :count, :any
    attr :disabled, :boolean
    attr :selected, :boolean
  end

  def segmented(assigns) do
    slots? = assigns.option != []

    assigns =
      Options.resolve(
        assigns,
        "segmented",
        if(slots?,
          do: Enum.map(assigns.option, &Map.take(&1, [:value, :label, :icon, :count])),
          else: assigns.options
        )
      )

    opts =
      if slots?,
        do: slot_options(assigns.option),
        else: assigns.options |> Options.normalize() |> Options.flatten()

    value =
      if slots? and is_nil(assigns.value),
        do: opts |> Enum.find(& &1.slot[:selected]) |> then(&(&1 && &1.value)),
        else: assigns.value |> Options.values() |> List.first()

    chosen = value && Enum.find(opts, &(&1.value == value))

    focusable =
      (chosen && chosen.value) || opts |> Enum.find(&(!&1.disabled)) |> then(&(&1 && &1.value))

    pill? = assigns.shape == "pill"

    assigns =
      assigns
      |> assign(:opts, opts)
      |> assign(:val, chosen && chosen.value)
      |> assign(:focusable, focusable)
      |> assign(:pill?, pill?)
      |> assign(:seg_style, join_style([pill? && @pill, assigns.stretch && "width:100%"]))
      |> assign(:pill_style, @pill)
      |> assign(
        :seg_class,
        cx(["lu-seg", @styles["size"][assigns.size], assigns.full && "block", assigns.class])
      )
      |> assign(:on_change_attr, on_change(assigns.on_change))
      |> assign(:cap_id, assigns.id <> "-label")

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
        class={@seg_class}
        {Options.style_attrs(@seg_style)}
        role={@role}
        aria-label={@label}
        aria-labelledby={@label && @cap_id}
        phx-hook="LedgerUI.Segmented"
        data-lu-on-change={@on_change_attr}
        data-lu-target={@target && to_string(@target)}
        data-lu-name={@name}
        {@rest}
      >
        <button
          :for={o <- @opts}
          type="button"
          class={o.value == @val && "on"}
          {Options.style_attrs(
            join_style([@pill? && o.value == @val && @pill_style, @stretch && "flex:1"])
          )}
          aria-pressed={to_string(o.value == @val)}
          tabindex={if o.value == @focusable, do: "0", else: "-1"}
          data-lu-value={o.value}
          disabled={@disabled || o.disabled}
        >
          <.icon :if={o.icon} name={o.icon} />
          <%= if o[:slot] do %>
            {render_slot(o.slot)}
          <% else %>
            {o.label}
          <% end %>
          <span
            :if={o.count}
            class="n"
          >{o.count}</span>
        </button>
        <input :if={@name} type="hidden" name={@name} value={@val || ""} data-lu-v />
      </div>
    </Options.shell>
    """
  end

  defp slot_options(slots) do
    for {s, i} <- Enum.with_index(slots) do
      %{
        label: s[:label] || "",
        value: Options.str(if(is_nil(s[:value]), do: i, else: s[:value])),
        disabled: s[:disabled] || false,
        icon: s[:icon],
        count: s[:count],
        data: %{},
        slot: s
      }
    end
  end

  defp join_style(parts) do
    case parts |> Enum.filter(&is_binary/1) |> Enum.join(";") do
      "" -> nil
      style -> style
    end
  end

  defp on_change(nil), do: nil
  defp on_change(name) when is_binary(name), do: name

  defp on_change(%Phoenix.LiveView.JS{} = js),
    do: Phoenix.json_library().encode!(js.ops)
end
