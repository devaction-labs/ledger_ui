defmodule LedgerUI.Variants do
  @moduledoc false
  # The colour-variant class strings that `LedgerUI.Components.Badge` and `LedgerUI.Components.Tag`
  # share (the colour enters as `--c`/`--c-on`/`--c-soft`/`--c-ink`, see `LedgerUI.Color`). Only the
  # strings that are character for character the same in both components live here: `outline`,
  # `bordered` (other class order) and `flat` differ per component and stay there.

  @solid "border-transparent bg-(--c) text-(--c-on)"
  @soft "border-transparent bg-(--c-soft) text-(--c-ink)"

  def solid, do: @solid
  def soft, do: @soft
end
