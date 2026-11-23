defmodule LedgerUI.Components.Segmented do
  @moduledoc """
  A segmented control: a row of toggle buttons where exactly one is chosen.

      <.segmented id="range" value={@range} on_change="set-range" options={~w(day month year)} />
      <.segmented field={@form[:view]} options={[{"List", "list"}, {"Board", "board"}]} />

      <.segmented id="view" value="board" options={[
        %{label: "Board", value: "board", icon: "kanban"},
        %{label: "All", value: "all", count: 128}
      ]} />

  Options are strings, `{label, value}` tuples or maps with `:label`, `:value`, `:icon`, `:count`,
  `:disabled`, `:title` (the button's `title` and `aria-label`) and `:icon_only` (hides the text;
  an empty `label` with an `icon` does the same). It is a `role="group"` (see `role`) of buttons
  with `aria-pressed`, which is what the chosen look reads; with `role="tablist"` the buttons are
  `role="tab"` and carry `aria-selected` instead.

  `icons` is the icons-only control (the chart type of a report): square buttons (as tall as the
  `size`), a centred icon and no text; give each option an `icon` and a `title`:

      <.segmented id="chart" icons size="sm" role="tablist" label="Chart type" value="line" options={[
        %{value: "bar", icon: "download", title: "Bars"},
        %{value: "line", icon: "file", title: "Line"}
      ]} />

  The choice is made in
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

  @button "inline-flex items-center gap-1.5 border-0 bg-transparent font-medium text-muted transition-[color,background-color] duration-150 hover:text-ink focus-visible:outline-[3px] focus-visible:outline-focus disabled:cursor-not-allowed disabled:opacity-45 aria-pressed:bg-panel aria-pressed:text-ink aria-pressed:shadow-[var(--lu-shadow-xs),0_0_0_1px_var(--lu-line)] aria-selected:bg-panel aria-selected:text-ink aria-selected:shadow-[var(--lu-shadow-xs),0_0_0_1px_var(--lu-line)] not-disabled:cursor-pointer"

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
  def button_class(size, pill?, block?, stretch?, icons? \\ false) do
    [
      @button,
      if(size == "sm",
        do: [
          if(icons?,
            do: "size-6 justify-center p-0 text-[12.5px]",
            else: "h-6 px-[9px] text-[12.5px]"
          ),
          !pill? && "rounded-sm"
        ],
        else: [
          if(icons?,
            do: "size-7 justify-center p-0 text-[13.5px]",
            else: "h-7 px-3 text-[13.5px]"
          ),
          !pill? && "rounded-[7px]"
        ]
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

  attr :icons, :boolean,
    default: false,
    doc: "Icons-only control: square buttons (width = height of `size`), a centred icon, no text."

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
    attr :title, :string
    attr :icon_only, :boolean
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
      |> assign(:opts, Enum.map(opts, &decorate(&1, assigns.icons)))
      |> assign(:val, chosen && chosen.value)
      |> assign(:focusable, focusable)
      |> assign(:pill?, pill?)
      |> assign(:seg_class, [track_class(pill?, assigns.full, assigns.stretch), assigns.class])
      |> assign(
        :btn_class,
        button_class(assigns.size, pill?, assigns.full, assigns.stretch, assigns.icons)
      )
      |> assign(:tab?, assigns.role == "tablist")
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
          role={@tab? && "tab"}
          aria-pressed={!@tab? && to_string(o.value == @val)}
          aria-selected={@tab? && to_string(o.value == @val)}
          title={o.title}
          aria-label={o.aria}
          tabindex={if o.value == @focusable, do: "0", else: "-1"}
          data-lu-value={o.value}
          disabled={@disabled || o.disabled}
        >
          <.icon :if={o.icon} name={o.icon} />
          <%= cond do %>
            <% o.icon_only -> %>
            <% o[:slot] -> %>
              {render_slot(o.slot)}
            <% true -> %>
              {o.label}
          <% end %>
          <span :if={o.count} data-part="segmented-count" class={count_class()}>{o.count}</span>
        </button>
        <input :if={@name} type="hidden" name={@name} value={@val || ""} data-lu-v />
      </div>
    </Options.shell>
    """
  end

  # `title` (button `title` + `aria-label`) and `icon_only` (no text) of an option
  defp decorate(o, icons?) do
    data = o.data || %{}
    slot = o[:slot] || %{}
    title = slot[:title] || data[:title] || data["title"]
    only = slot[:icon_only] || data[:icon_only] || data["icon_only"] || false
    has_slot? = o[:slot] != nil

    icon_only? =
      o.icon != nil and
        (only == true or icons? or (not has_slot? and o.label == ""))

    aria = title || ((icon_only? and o.label != "") && o.label) || nil

    o |> Map.put(:title, title) |> Map.put(:icon_only, icon_only?) |> Map.put(:aria, aria)
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
