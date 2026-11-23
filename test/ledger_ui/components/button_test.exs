defmodule LedgerUI.Components.ButtonTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Button

  test "defaults to the black solid button" do
    assigns = %{}
    html = rendered_to_string(~H|<.button>Save</.button>|)
    assert html =~ "[--c:var(--lu-ink)]"
    assert html =~ "bg-(--c) text-(--c-on)"
    assert html =~ "h-9 text-sm gap-2 px-3.5 rounded-md shadow-btn"
    assert html =~ ~s(type="button")
    assert html =~ ~s(data-part="button")
    refute html =~ "style="
    refute html =~ ~r/(^|[\s"])lu-/
  end

  test "color, variant, size, shape pick one utility per property" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.button color="primary" variant="soft" size="lg" shape="pill" class="x">Ok</.button>|
      )

    assert html =~ "[--c:var(--color-accent)]"
    assert html =~ "bg-(--c-soft) text-(--c-ink)"
    assert html =~ "h-11 text-[15px] gap-2 px-[18px] rounded-full"
    refute html =~ "rounded-[12px]"
    assert html =~ ~r/ x"/
  end

  test "every colour, variant and size renders" do
    for c <- LedgerUI.Components.Button.colors(),
        v <- LedgerUI.Components.Button.variants(),
        s <- LedgerUI.Components.Button.sizes() do
      assigns = %{c: c, v: v, s: s}

      assert rendered_to_string(~H|<.button color={@c} variant={@v} size={@s}>x</.button>|) =~
               "<button"
    end
  end

  test "current colour follows the text colour and icon is square" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.button color="current" variant="ghost" icon aria-label="m">x</.button>|
      )

    assert html =~ "[--c-ink:currentColor]"
    assert html =~ "w-9 px-0"
    assert html =~ ~s(aria-label="m")
  end

  test "an icon name without content is an icon-only square button; with content it is not" do
    assigns = %{}
    html = rendered_to_string(~H|<.button icon="huge-plus" aria-label="Add" />|)
    assert html =~ "w-9 px-0"
    assert html =~ ~s(data-icon="plus")

    html =
      rendered_to_string(
        ~H|<.button icon="huge-plus" trailing_icon="huge-arrow-right">Add</.button>|
      )

    refute html =~ "w-9"
    assert html =~ ~s(data-icon="plus")
    assert html =~ ~s(data-icon="arrow-right")
  end

  test "loading disables, marks busy and adds the spinner" do
    assigns = %{}
    html = rendered_to_string(~H|<.button loading loading_label="Saving">Save</.button>|)
    assert html =~ "disabled"
    assert html =~ ~s(aria-busy="true")
    assert html =~ "text-transparent!"
    assert html =~ "cursor-progress"
    assert html =~ "animate-[lu-spin_.7s_linear_infinite]"
    assert html =~ ~s(role="status")
    assert html =~ ~s(aria-label="Saving")
    # not inert: the spinner's role="status" has to be announced
    refute html =~ "inert"
  end

  test "pip adds the dot" do
    assigns = %{}
    html = rendered_to_string(~H|<.button icon pip aria-label="n">x</.button>|)
    assert html =~ "relative"
    assert html =~ "bg-neg shadow-[0_0_0_2px_var(--lu-bg-panel)]"
  end

  test "disabled and user style" do
    assigns = %{}
    html = rendered_to_string(~H|<.button disabled style="width:9px">x</.button>|)
    assert html =~ "disabled"
    assert html =~ "disabled:opacity-45"
    assert html =~ ~s(style="width:9px")
  end

  test "link when href, navigate or patch" do
    assigns = %{}
    html = rendered_to_string(~H|<.button href="/a" variant="outline">Go</.button>|)
    assert html =~ ~s(<a href="/a")
    assert html =~ "bg-transparent text-(--c-ink)"
    refute html =~ "<button"
  end

  test "rest attributes reach the button" do
    assigns = %{}
    html = rendered_to_string(~H|<.button phx-click="go" form="f" name="n" value="v">x</.button>|)
    assert html =~ ~s(phx-click="go")
    assert html =~ ~s(form="f")
  end

  test "canvas is the compact toolbar button" do
    assigns = %{}
    html = rendered_to_string(~H|<.button canvas size="lg">Ok</.button>|)
    assert html =~ "h-11"
    assert html =~ "border-line-strong bg-panel"
    refute html =~ "bg-(--c)"
  end

  test "button_group joins the buttons, corners only at the ends" do
    assigns = %{}
    html = rendered_to_string(~H|<.button_group>a</.button_group>|)
    assert html =~ ~s(data-part="button-group")
    assert html =~ ~s(role="group")
    assert html =~ "*:first:rounded-l-md *:last:rounded-r-md"
    html = rendered_to_string(~H|<.button_group shape="pill">a</.button_group>|)
    assert html =~ "*:first:rounded-l-full *:last:rounded-r-full"
  end

  test "canvas icon-only buttons (the old icon_button): variants and sizes" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.button canvas icon="plus" aria-label="Add" appearance="primary" size="sm" />|
      )

    assert html =~ "bg-inverse text-on-inverse"
    assert html =~ "h-[30px]"
    assert html =~ "w-[30px] px-0"
    assert html =~ ~s(aria-label="Add")
    assert html =~ ~s(data-icon="plus")

    assert rendered_to_string(~H|<.button canvas icon="x" aria-label="a" />|) =~ "w-9 px-0"

    html =
      rendered_to_string(
        ~H|<.button canvas icon="bell" aria-label="a" appearance="topbar" pip />|
      )

    assert html =~ "size-10"
    assert html =~ "button-pip"

    html =
      rendered_to_string(~H|<.button canvas icon="arrow-right" aria-label="a" appearance="go" />|)

    assert html =~ "bg-accent-500"
    assert html =~ "rounded-full"
  end

  test "insight_button" do
    assigns = %{}
    html = rendered_to_string(~H|<.insight_button count={3}>New AI insights</.insight_button>|)
    assert html =~ ~r|<span data-part="insight-button-count"[^>]*>3</span>|
    assert html =~ "New AI insights"
  end

  test "insight_button default is a plain button" do
    assigns = %{}
    html = rendered_to_string(~H|<.insight_button count={3}>New AI insights</.insight_button>|)
    assert html =~ ~r|<button data-part="insight-button" type="button"|
    refute html =~ "<a "
    refute html =~ "<svg"
  end

  test "insight_button renders links" do
    assigns = %{}

    html = rendered_to_string(~H|<.insight_button navigate="/x" count={2}>AI</.insight_button>|)
    assert html =~ ~r|<a [^>]*data-phx-link="redirect"|
    assert html =~ ~s|href="/x"|
    assert html =~ ~s|data-part="insight-button"|
    assert html =~ ~r|insight-button-count"[^>]*>2</span>|
    refute html =~ "type="
    refute html =~ "<button"

    html = rendered_to_string(~H|<.insight_button patch="/y">AI</.insight_button>|)
    assert html =~ ~s|data-phx-link="patch"|

    html = rendered_to_string(~H|<.insight_button href="/z">AI</.insight_button>|)
    assert html =~ ~r|<a [^>]*href="/z"|
    refute html =~ "data-phx-link"
  end

  test "insight_button icon replaces the count" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.insight_button icon="huge-sparkles" count={3} navigate="/x">AI</.insight_button>|
      )

    assert html =~ ~r|insight-button-icon"[^>]*><svg|
    refute html =~ "insight-button-count"
    refute html =~ ">3<"
  end

  describe "link look (#69)" do
    test "kit variant: accent text, no box, underline on hover, compact padding, focus ring" do
      assigns = %{}
      html = rendered_to_string(~H|<.button variant="link" size="sm">Clear all</.button>|)

      for c <-
            ~w(text-accent-content bg-transparent border-transparent hover:underline px-1 shadow-none) do
        assert html =~ c
      end

      assert html =~ "focus-visible:shadow-[0_0_0_3px_var(--lu-focus)]"
      refute html =~ "px-2.5"
      refute html =~ "shadow-btn"
    end

    test "works with every size and keeps the other colours' ink" do
      assigns = %{}

      for size <- ~w(xs sm md) do
        assigns = %{size: size}
        html = rendered_to_string(~H|<.button variant="link" size={@size}>x</.button>|)
        assert html =~ "px-1"
      end

      html = rendered_to_string(~H|<.button variant="link" color="error">x</.button>|)
      assert html =~ "text-(--c-ink)"
      refute html =~ "text-accent-content"
    end

    test "canvas appearance link" do
      assigns = %{}

      html =
        rendered_to_string(~H|<.button canvas appearance="link" size="sm">Clear all</.button>|)

      for c <-
            ~w(text-accent-content bg-transparent border-transparent hover:underline px-1 h-[30px]) do
        assert html =~ c
      end

      refute html =~ "px-2.5"
    end
  end

  describe "canvas appearances" do
    test "each look renders its classes" do
      for {look, cls} <- [
            {"accent", "bg-accent-600"},
            {"soft", "bg-sunken"},
            {"danger-soft", "bg-neg-soft"},
            {"topbar", "size-10"},
            {"go", "size-[30px]"}
          ] do
        assigns = %{look: look}

        html =
          rendered_to_string(~H|<.button canvas appearance={@look} icon="plus" aria-label="a" />|)

        assert html =~ cls
      end
    end

    test "string icon without content is square, with content is not" do
      assigns = %{}

      assert rendered_to_string(~H|<.button canvas size="sm" icon="plus" aria-label="a" />|) =~
               "w-[30px] px-0"

      html = rendered_to_string(~H|<.button canvas size="sm" icon="plus">Add</.button>|)
      assert html =~ "px-2.5"
      refute html =~ "w-[30px]"
    end

    test "topbar and go ignore size; go uses the md icon" do
      assigns = %{}

      html = rendered_to_string(~H|<.button canvas appearance="topbar" size="lg" icon="bell" />|)
      assert html =~ "size-10"
      refute html =~ "h-11"

      html = rendered_to_string(~H|<.button canvas appearance="go" icon="arrow-right" />|)
      assert html =~ "size-[30px]"

      assert html =~
               ~s(class="inline flex-none fill-none stroke-current stroke-[1.75] [stroke-linecap:round] [stroke-linejoin:round] align-middle size-4")
    end

    test "pip offset per look" do
      assigns = %{}

      html = rendered_to_string(~H|<.button canvas appearance="topbar" icon="bell" pip />|)
      assert html =~ "top-2 right-[9px]"

      html = rendered_to_string(~H|<.button canvas appearance="ghost" icon="bell" pip />|)
      assert html =~ "top-1.5 right-[7px]"
      assert html =~ "relative"
    end

    test "part overrides data-part" do
      assigns = %{}

      assert rendered_to_string(~H|<.button part="x" icon="bell" />|) =~ ~s(data-part="x")
    end

    test "part=\"icon-button\" and pip on the topbar look" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<.button canvas part="icon-button" icon="bell" aria-label="a" appearance="topbar" pip />|
        )

      assert html =~ ~s(data-part="icon-button")
      assert html =~ "button-pip"
      assert html =~ "top-2 right-[9px]"
    end
  end

  test "a button with phx-click carries the automatic loading classes and a hidden spinner" do
    assigns = %{}
    html = rendered_to_string(~H|<.button phx-click="save">Save</.button>|)
    assert html =~ "[&amp;.phx-click-loading]:pointer-events-none"
    assert html =~ "[&amp;.phx-click-loading]:text-transparent!"
    assert html =~ ~s(data-part="button-auto-spinner")
    assert html =~ "opacity-0"
    assert html =~ "[.phx-click-loading&gt;&amp;]:opacity-100"
    assert html =~ ~s(aria-hidden="true")
  end

  test "a submit button gets the automatic loading" do
    assigns = %{}
    html = rendered_to_string(~H|<.button type="submit">Save</.button>|)
    assert html =~ "[&amp;.phx-submit-loading]:pointer-events-none"
    assert html =~ ~s(data-part="button-auto-spinner")
  end

  test "auto_loading={false} opts out" do
    assigns = %{}
    html = rendered_to_string(~H|<.button phx-click="save" auto_loading={false}>Save</.button>|)
    refute html =~ "phx-click-loading"
    refute html =~ "button-auto-spinner"
  end

  test "a button without phx-click, a link and a manual loading are unchanged" do
    assigns = %{}
    refute rendered_to_string(~H|<.button>Save</.button>|) =~ "phx-click-loading"

    refute rendered_to_string(~H|<.button navigate="/x" phx-click="a">Go</.button>|) =~
             "phx-click-loading"

    html = rendered_to_string(~H|<.button phx-click="a" loading>Go</.button>|)
    refute html =~ "button-auto-spinner"
    assert html =~ ~s(data-part="button-spinner")
  end
end
