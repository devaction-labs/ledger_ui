defmodule LedgerUI.Components.FieldBox do
  @moduledoc false
  # The look of a text-field box (`Input`'s) for the controls that draw their own box: the
  # select trigger, the tags field, the phone field. One utility per CSS property; `display`
  # and a free height are the two things `Input` does not offer.

  # height, horizontal padding, radius
  @sizes %{
    "sm" => {"h-8", "px-2.5", "rounded-[8px]"},
    "md" => {"h-[38px]", "px-3", "rounded-md"},
    "lg" => {"h-11", "px-3", "rounded-[12px]"}
  }

  @min_heights %{"sm" => "min-h-8", "md" => "min-h-[38px]", "lg" => "min-h-11"}

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
        do: "focus-within:shadow-[0_0_0_3px_color-mix(in_oklab,var(--lu-neg)_25%,transparent)]",
        else: "focus-within:shadow-[0_0_0_3px_var(--lu-focus)]"

    [ring, (variant == "outlined" and state == nil) && "focus-within:border-accent-500"]
  end

  @doc "The bare `<input>` (or `<select>`) inside a box."
  def control_class,
    do: "h-full min-w-0 flex-1 appearance-none border-0 bg-transparent p-0 text-sm outline-0"
end
