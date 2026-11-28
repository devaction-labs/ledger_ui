defmodule LedgerUI.HTMLNormalizerTest do
  use ExUnit.Case, async: true

  import LedgerUI.HTMLNormalizer

  test "attributes are sorted, valueless ones included" do
    a = ~s(<input type="text" name="q" disabled id="x">)
    b = ~s(<input id="x" disabled name="q" type="text">)

    assert normalize(a) == normalize(b)
    assert normalize(a) =~ ~s(<input disabled id="x" name="q" type="text">)
  end

  test "keys of the JSON in data-lu-* are sorted at every depth" do
    a =
      ~s(<div data-lu-config="{&quot;zz&quot;:1,&quot;aa&quot;:{&quot;y&quot;:[{&quot;b&quot;:1,&quot;a&quot;:2}],&quot;x&quot;:null}}" id="d"></div>)

    b =
      ~s(<div id="d" data-lu-config="{&quot;aa&quot;:{&quot;x&quot;:null,&quot;y&quot;:[{&quot;a&quot;:2,&quot;b&quot;:1}]},&quot;zz&quot;:1}"></div>)

    assert normalize(a) == normalize(b)

    assert normalize(a) =~
             ~s(data-lu-config="{&quot;aa&quot;:{&quot;x&quot;:null,&quot;y&quot;:[{&quot;a&quot;:2,&quot;b&quot;:1}]},&quot;zz&quot;:1}")
  end

  test "different values are still different" do
    refute normalize(~s(<i data-lu-config="{&quot;a&quot;:1}"></i>)) ==
             normalize(~s(<i data-lu-config="{&quot;a&quot;:2}"></i>))

    refute normalize(~s(<i a="1" b="2">)) == normalize(~s(<i a="1" b="3">))
  end

  test "a data-lu-* value that is not JSON is kept" do
    assert normalize(~s(<i data-lu-x="a b" id="1">)) == ~s(<i data-lu-x="a b" id="1">)
  end

  test "text and tags without attributes are not touched; self-closing tags keep the slash" do
    assert normalize("<p>a < b <b>x</b></p><br/>") == "<p>a < b <b>x</b></p><br/>"
    assert normalize(~s(<path d="M1" class="c"/>)) == ~s(<path class="c" d="M1"/>)
  end

  test "the random id of show_toast is replaced" do
    a = ~s(<button phx-click="x" id="toast-3721">toast-3721</button>)
    b = ~s(<button id="toast-3849" phx-click="x">toast-3849</button>)
    assert normalize(a) == normalize(b)
  end

  test "two renderings of a component with rest in another order are equal once normalized" do
    import Phoenix.Component
    import Phoenix.LiveViewTest
    assigns = %{}

    a =
      rendered_to_string(
        ~H|<LedgerUI.Components.Input.input id="i" name="n" data-a="1" data-b="2" />|
      )

    b =
      rendered_to_string(
        ~H|<LedgerUI.Components.Input.input id="i" name="n" data-b="2" data-a="1" />|
      )

    assert normalize(a) == normalize(b)
  end
end
