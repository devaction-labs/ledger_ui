defmodule LedgerUI.Components.Rating do
  @moduledoc """
  A star rating: read-only, with a fractional value and the count of reviews, or interactive, as
  a group of native radios; and `rating_distribution/1`, the summary with the average and a bar
  per grade.

      <.rating value={4.5} />
      <.rating value={4.2} show_value count={38} />
      <.rating id="service" name="service" label="Como foi o atendimento?" value={@grade} on_change="rate" />
      <.rating field={@form[:grade]} label="Nota" />
      <.rating_distribution average={4.5} counts={[800, 310, 110, 40, 24]} />

  A fractional value is drawn in half stars (the nearest half). The read-only rating is one
  `role="img"` with the text `4,5 de 5 estrelas` (`aria_label` gives another).

  Interactive ratings are a `radiogroup` of `max` native radios (Tab enters the group, the arrow
  keys choose, the form submits `name`). `on_change` is an event name (pushed with
  `%{"id", "value"}`, to `target` when given) or a `%JS{}`. The `LedgerUI.Rating` hook
  (`priv/static/ledger_ui/hooks/rating.js`) previews the grade under the pointer.
  """
  use LedgerUI.Component

  import LedgerUI.Components.DatePicker, only: [field_assigns: 1]
  import LedgerUI.Components.NumberInput, only: [machine: 1]

  @path "M12 2.8l2.8 5.7 6.3.9-4.55 4.43 1.07 6.27L12 17.1l-5.62 3l1.07-6.27L2.9 9.4l6.3-.9z"

  @styles %{
    "variant" => %{"solid" => nil, "outline" => "outline"},
    "size" => %{"sm" => "s-sm", "md" => nil, "lg" => "s-lg"}
  }

  defp number(v) do
    case machine(v) do
      nil -> 0.0
      m -> if String.contains?(m, "."), do: String.to_float(m), else: String.to_integer(m) * 1.0
    end
  end

  # Per star: :on, :off or {:half}. Halves: the nearest 0.5.
  defp star_states(value, max) do
    q = Float.round(value * 2) / 2

    for i <- 1..max//1 do
      cond do
        q >= i -> :on
        q >= i - 0.5 -> :half
        true -> :off
      end
    end
  end

  defp decimal(value, sep) do
    value |> Float.round(1) |> :erlang.float_to_binary(decimals: 1) |> String.replace(".", sep)
  end

  attr :class, :string, default: nil
  attr :style, :string, default: nil
  attr :rest, :global

  defp star(assigns) do
    assigns = assign(assigns, :attrs, if(assigns.style, do: %{style: assigns.style}, else: %{}))

    ~H"""
    <svg
      class={@class}
      stroke-linejoin="round"
      stroke-width="1.5"
      viewBox="0 0 24 24"
      {@attrs}
      {@rest}
    >
      <path d={path()}></path>
    </svg>
    """
  end

  defp path, do: @path

  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :any
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :max, :integer, default: 5
  attr :variant, :string, default: "solid", values: ~w(solid outline)
  attr :size, :string, default: "md", values: ~w(sm md lg)
  attr :count, :integer, default: nil
  attr :show_value, :boolean, default: false
  attr :decimal, :string, default: ","
  attr :interactive, :boolean, default: nil
  attr :label, :string, default: nil
  attr :aria_label, :string, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :disabled, :boolean, default: false
  attr :on_change, :any, default: nil
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  @doc "Renders a rating."
  def rating(assigns) do
    assigns = assigns |> Map.new() |> field_assigns()
    value = number(assigns.value)

    interactive? =
      case assigns.interactive do
        nil -> assigns.field != nil or assigns.name != nil or assigns.on_change != nil
        v -> v
      end

    id = assigns.id || assigns.name || "rating"

    assigns =
      assigns
      |> assign(:id, id)
      |> assign(:interactive?, interactive?)
      |> assign(:stars, star_states(value, assigns.max))
      |> assign(:grade, round(value))
      |> assign(
        :aria_label_text,
        assigns.aria_label || "#{decimal(value, assigns.decimal)} de #{assigns.max} estrelas"
      )
      |> assign(:value_text, decimal(value, assigns.decimal))
      |> assign(
        :stars_class,
        cx([
          "lu-stars",
          @styles["variant"][assigns.variant],
          @styles["size"][assigns.size],
          assigns.class
        ])
      )
      |> assign(:target_attr, assigns.target && to_string(assigns.target))
      |> assign(:event, if(is_binary(assigns.on_change), do: assigns.on_change))
      |> assign(:js, if(match?(%Phoenix.LiveView.JS{}, assigns.on_change), do: assigns.on_change))
      |> assign(
        :root_attrs,
        if(assigns.disabled, do: %{style: "pointer-events:none;opacity:.6"}, else: %{})
      )
      |> assign(:wrapped, assigns.label != nil or assigns.help != nil or assigns.errors != [])

    ~H"""
    <div :if={@wrapped} class="lu-field">
      <span :if={@label} class="lu-label">{@label}</span>
      <.stars {assigns} />
      <span :for={e <- @errors} class="lu-help err">{e}</span>
      <span :if={@help} class="lu-help">{@help}</span>
    </div>
    <.stars :if={!@wrapped} {assigns} />
    """
  end

  defp stars(%{interactive?: true} = assigns) do
    ~H"""
    <span
      id={@id}
      data-part="rating"
      phx-hook="LedgerUI.Rating"
      class={@stars_class}
      role="radiogroup"
      aria-label={@label || @aria_label}
      {@root_attrs}
      {@rest}
    >
      <label
        :for={{_state, i} <- Enum.with_index(@stars, 1)}
        style="display:inline-flex;cursor:pointer"
      >
        <input
          type="radio"
          name={@name || @id}
          value={i}
          checked={i == @grade}
          disabled={@disabled}
          aria-label={"#{i}"}
          style="position:absolute;opacity:0;width:1px;height:1px;margin:0;pointer-events:none"
          phx-click={@event || @js}
          phx-target={@target_attr}
          phx-value-id={@id}
          phx-value-value={i}
        />
        <.star class={if i <= @grade, do: "on", else: "off"} />
      </label>
      <span :if={@show_value} class="num">{@value_text}</span>
      <span :if={@count} class="cnt">({@count})</span>
    </span>
    """
  end

  defp stars(assigns) do
    ~H"""
    <span
      id={@id}
      data-part="rating"
      class={@stars_class}
      role="img"
      aria-label={@aria_label_text}
      {@rest}
    >
      <%= for s <- @stars do %>
        <%= case s do %>
          <% :on -> %>
            <.star class="on" />
          <% :off -> %>
            <.star class="off" />
          <% :half -> %>
            <span style="display:inline-grid">
              <.star class="off" style="grid-area:1/1" />
              <.star class="on" style="grid-area:1/1;clip-path:inset(0 50% 0 0)" />
            </span>
        <% end %>
      <% end %>
      <span :if={@show_value} class="num">{@value_text}</span>
      <span :if={@count} class="cnt">({@count})</span>
    </span>
    """
  end

  # ---------------------------------------------------------------------------------------
  # <.rating_distribution>
  # ---------------------------------------------------------------------------------------

  attr :counts, :any,
    required: true,
    doc: "A list, best grade first, or a map `%{grade => count}`."

  attr :average, :any, default: nil
  attr :total, :integer, default: nil
  attr :unit, :string, default: "avaliações"
  attr :decimal, :string, default: ","
  attr :class, :any, default: nil
  attr :rest, :global

  @doc "The summary of a rating: the average, its stars, the total and a bar per grade."
  def rating_distribution(assigns) do
    rows = rows(assigns.counts)
    total = assigns.total || Enum.sum(Enum.map(rows, &elem(&1, 1)))

    average =
      if assigns.average do
        number(assigns.average)
      else
        if total == 0,
          do: 0.0,
          else: Enum.sum(Enum.map(rows, fn {g, c} -> g * c end)) / total
      end

    assigns =
      assigns
      |> assign(:avg_text, decimal(average, assigns.decimal))
      |> assign(:stars, star_states(average, 5))
      |> assign(:total_n, total)
      |> assign(
        :rows,
        for {g, c} <- rows do
          %{grade: g, count: c, pct: if(total == 0, do: 0, else: round(c / total * 100))}
        end
      )

    ~H"""
    <div data-part="rating-distribution" class={cx(["lu-row", @class])} {@rest}>
      <div class="lu-col" style="gap:4px">
        <b style="font-size:34px;letter-spacing:-.03em">{@avg_text}</b>
        <span class="lu-stars">
          <%= for s <- @stars do %>
            <%= case s do %>
              <% :on -> %>
                <.star class="on" />
              <% :off -> %>
                <.star class="off" />
              <% :half -> %>
                <span style="display:inline-grid">
                  <.star class="off" style="grid-area:1/1" />
                  <.star class="on" style="grid-area:1/1;clip-path:inset(0 50% 0 0)" />
                </span>
            <% end %>
          <% end %>
        </span>
        <span class="lu-xs lu-muted">{@total_n} {@unit}</span>
      </div>
      <div class="lu-rbreak" style="width:280px">
        <%= for r <- @rows do %>
          <span>{r.grade} ★</span>
          <div class="bar"><i style={"width:#{r.pct}%"}></i></div>
          <span>{r.count}</span>
        <% end %>
      </div>
    </div>
    """
  end

  # [{grade, count}] best grade first.
  defp rows(counts) when is_map(counts),
    do: counts |> Enum.sort_by(&elem(&1, 0), :desc) |> Enum.map(fn {g, c} -> {g, c} end)

  defp rows(counts) when is_list(counts) do
    n = length(counts)
    counts |> Enum.with_index() |> Enum.map(fn {c, i} -> {n - i, c} end)
  end
end
