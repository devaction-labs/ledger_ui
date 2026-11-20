defmodule LedgerShowcase.ParityHelperTest do
  use ExUnit.Case, async: true

  alias LedgerShowcase.Parity

  defp same?(expected, actual) do
    e = Parity.flatten(expected)
    a = Parity.flatten(actual)
    Parity.diff(e, a) |> Enum.reject(&Parity.extras_only?/1) == []
  end

  test "extra a11y/state attributes on our element are ignored" do
    ref = ~s(<button class="lu-btn">Go</button>)

    ours =
      ~s(<button class="lu-btn" role="menuitem" aria-expanded="false" aria-controls="m" tabindex="0" hidden popover inert data-lu-placement="top" data-state="closed">Go</button>)

    assert same?(ref, ours)
  end

  test "when the reference has the attribute, values must still match" do
    ref = ~s(<div role="tab" aria-selected="true">x</div>)

    assert same?(ref, ~s(<div role="tab" aria-selected="true">x</div>))
    refute same?(ref, ~s(<div role="tab" aria-selected="false">x</div>))
    refute same?(ref, ~s(<div role="button" aria-selected="true">x</div>))
  end

  test "attributes missing on our element are still reported" do
    refute same?(~s(<div role="tab">x</div>), ~s(<div>x</div>))
  end

  test "non-extra attributes, classes, tags and text are still compared" do
    refute same?(~s(<a class="x">a</a>), ~s(<a class="x" href="#">a</a>))
    refute same?(~s(<a class="x">a</a>), ~s(<a class="y">a</a>))
    refute same?(~s(<a class="x">a</a>), ~s(<span class="x">a</span>))
    refute same?(~s(<a class="x">a</a>), ~s(<a class="x">b</a>))
    refute same?(~s(<a data-foo="1">a</a>), ~s(<a data-foo="1" data-bar="2">a</a>))
  end
end
