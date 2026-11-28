defmodule LedgerUI.Components.FieldBox do
  @moduledoc false
  # The look of a text-field box (`Input`'s) for the controls that draw their own box: the
  # select trigger, the tags field, the phone field. One utility per CSS property; `display`
  # and a free height are the two things `Input` does not offer.

  # height, horizontal padding, radius
  @sizes %{
    "sm" => {"h-9", "px-2.5", "rounded-md"},
    "md" => {"h-10", "px-3", "rounded-md"},
    "lg" => {"h-11", "px-3", "rounded-[14px]"}
  }

  @min_heights %{"sm" => "min-h-9", "md" => "min-h-10", "lg" => "min-h-11"}

  @doc """
  Class list of the box.

  Options: `:display` (`"flex"` or `"inline-flex"`), `:gap` (a `gap-*` class), `:free_height` (a box that grows with
  its content: a minimum height and a vertical padding instead of a fixed height).
  """
  def classes(variant, size, shape, state, disabled, opts \\ []) do
    {h, px, r} = @sizes[size || "md"]
    free? = Keyword.get(opts, :free_height, false)

    [
      Keyword.get(opts, :display, "flex"),
      "min-w-0 items-center border transition-[border-color,box-shadow] duration-150",
      Keyword.get(opts, :gap, "gap-2"),
      if(free?, do: [@min_heights[size || "md"], "py-[5px]"], else: h),
      if(shape == "pill", do: "rounded-full", else: r),
      cond do
        shape == "pill" -> "px-4"
        free? -> "px-2"
        variant == "plain" -> "pr-3 pl-0.5"
        true -> px
      end,
      colors(variant, state, disabled),
      focus(variant, state),
      disabled && "cursor-not-allowed"
    ]
  end

  @doc """
  The chip drawn inside a field, concentric to it: `rounded-sm` (8px) in a `rounded` field
  (`rounded-[9px]` in a `lg` one, r14) and `rounded-full` in a `pill` field. The chip inherits the shape
  of the field; it is never a fixed pill.
  """
  def chip_class(size, shape) do
    radius =
      cond do
        shape == "pill" -> "rounded-full"
        size == "lg" -> "rounded-[9px]"
        true -> "rounded-sm"
      end

    # whatever radius `Chip.chip_class/3` (or /4) brings is dropped: the field decides the radius
    tokens =
      LedgerUI.Components.Chip.chip_class(nil, false, "sm")
      |> List.flatten()
      |> Enum.filter(&is_binary/1)
      |> Enum.flat_map(&String.split/1)
      |> Enum.reject(&String.starts_with?(&1, "rounded"))

    [Enum.join(tokens, " "), radius]
  end

  defp colors(variant, state, disabled) do
    bg =
      cond do
        variant == "plain" -> "bg-transparent"
        variant == "filled" or disabled -> "bg-sunken"
        true -> "bg-panel"
      end

    border =
      cond do
        state == "error" ->
          "border-neg"

        state == "success" ->
          "border-pos"

        variant == "outlined" ->
          "border-line-strong not-focus-within:hover:border-[color-mix(in_oklab,var(--lu-line-strong)_60%,var(--lu-muted))]"

        true ->
          "border-transparent"
      end

    [bg, border, if(disabled, do: "text-muted", else: "text-ink")]
  end

  defp focus("plain", _state), do: "focus-within:shadow-none"

  defp focus(variant, state) do
    ring =
      if state == "error",
        do: "focus-within:shadow-[0_0_0_4px_var(--lu-neg)]",
        else: "focus-within:shadow-[0_0_0_4px_var(--lu-focus)]"

    [ring, (variant == "outlined" and state == nil) && "focus-within:border-ink-2"]
  end

  @doc "The bare `<input>` (or `<select>`) inside a box."
  def control_class,
    do: "h-full min-w-0 flex-1 appearance-none border-0 bg-transparent p-0 text-sm outline-0"
end
