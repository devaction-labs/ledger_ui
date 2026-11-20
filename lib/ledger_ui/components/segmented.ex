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
  and `:disabled`. It is a `role="group"` of buttons with `aria-pressed`. The choice is made in
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
  attr :options, :list, required: true
  attr :label, :string, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :size, :string, default: "md", values: ~w(sm md lg)
  attr :shape, :string, default: "rounded", values: ~w(rounded pill)
  attr :full, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :on_change, :any, default: nil
  attr :target, :any, default: nil
  attr :wrapper_class, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(form)

  def segmented(assigns) do
    assigns = Options.resolve(assigns, "segmented", assigns.options)
    opts = assigns.options |> Options.normalize() |> Options.flatten()
    value = assigns.value |> Options.values() |> List.first()
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
        {Options.style_attrs(@pill? && @pill_style)}
        role="group"
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
          {Options.style_attrs(@pill? && o.value == @val && @pill_style)}
          aria-pressed={to_string(o.value == @val)}
          tabindex={if o.value == @focusable, do: "0", else: "-1"}
          data-lu-value={o.value}
          disabled={@disabled || o.disabled}
        >
          <.icon :if={o.icon} name={o.icon} />{o.label}<span :if={o.count} class="n">{o.count}</span>
        </button>
        <input :if={@name} type="hidden" name={@name} value={@val || ""} data-lu-v />
      </div>
    </Options.shell>
    """
  end

  defp on_change(nil), do: nil
  defp on_change(name) when is_binary(name), do: name

  defp on_change(%Phoenix.LiveView.JS{} = js),
    do: Phoenix.json_library().encode!(js.ops)
end
