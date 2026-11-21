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
  and `:disabled`. It is a `role="group"` (see `role`) of buttons with `aria-pressed`, which is what the chosen look reads. The choice is made in
  the browser (hook `LedgerUI.Segmented`, `priv/static/ledger_ui/hooks/segmented.js`): a new
  `value` from the server wins, a patch that does not change it leaves the person's choice
  alone, arrow keys/Home/End move the focus (one segment is in the Tab order).

  With a `name` (or `field`) the control submits through a hidden input that fires `input`, so a
  form's `phx-change` runs. `on_change` is an event name (pushed with
  `%{"id" => id, "value" => value}` to `target`) or a `%JS{}`.
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Select.Options

  @track "gap-0.5 bg-sunken p-[3px]"

  @button "inline-flex items-center gap-1.5 border-0 bg-transparent font-medium text-muted transition-[color,background-color] duration-150 hover:text-ink focus-visible:outline-[3px] focus-visible:outline-focus disabled:cursor-not-allowed disabled:opacity-45 aria-pressed:bg-panel aria-pressed:text-ink aria-pressed:shadow-[var(--lu-shadow-xs),0_0_0_1px_var(--lu-line)] not-disabled:cursor-pointer"

  @count "inline-grid h-[18px] min-w-[18px] place-items-center rounded-[5px] bg-selected px-1 text-[11.5px] text-ink-2 tabular-nums"

  @doc false
  # The track of a segmented control (`lg` has no look of its own: it is `md`).
  def track_class(pill?, block?, stretch?) do
    [
      block? && "flex",
      !block? && "inline-flex",
      @track,
      if(pill?, do: "rounded-full", else: "rounded-md"),
      stretch? && "w-full"
    ]
  end

  @doc false
  # One segment: height, padding, radius and text size follow `size`; the chosen one reads
  # `aria-pressed`.
  def button_class(size, pill?, block?, stretch?) do
    [
      @button,
      if(size == "sm",
        do: ["h-6 px-[9px] text-[12.5px]", !pill? && "rounded-sm"],
        else: ["h-7 px-3 text-[13.5px]", !pill? && "rounded-[7px]"]
      ),
      pill? && "rounded-full",
      (block? or stretch?) && "flex-1 justify-center"
    ]
  end

  @doc false
  def count_class, do: @count

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
      |> assign(:seg_class, [track_class(pill?, assigns.full, assigns.stretch), assigns.class])
      |> assign(:btn_class, button_class(assigns.size, pill?, assigns.full, assigns.stretch))
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
        data-part="segmented"
        class={@seg_class}
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
          data-part="segmented-item"
          class={@btn_class}
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
          <span :if={o.count} data-part="segmented-count" class={count_class()}>{o.count}</span>
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

  defp on_change(nil), do: nil
  defp on_change(name) when is_binary(name), do: name

  defp on_change(%Phoenix.LiveView.JS{} = js),
    do: Phoenix.json_library().encode!(js.ops)
end
