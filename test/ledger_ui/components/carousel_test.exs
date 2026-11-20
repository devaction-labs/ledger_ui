defmodule LedgerUI.Components.CarouselTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Carousel

  test "track, slides and the hook" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.carousel id="g">
        <.carousel_slide>one</.carousel_slide>
        <.carousel_slide class="w-10/12">two</.carousel_slide>
      </.carousel>
      """)

    assert html =~ ~s(phx-hook="LedgerUI.Carousel")
    assert html =~ "relative overflow-hidden rounded-[14px]"
    assert html =~ ~s(data-part="carousel-track")
    assert html =~ "]:w-[260px]"
    assert html =~ ~s(data-lu-effect="slide")
    assert html =~ "one"
    refute html =~ "data-index"
  end

  test "effect classes" do
    assigns = %{}
    assert rendered_to_string(~H|<.carousel id="g" effect="fade">
  <.carousel_slide>a</.carousel_slide>
</.carousel>|) =~ ~s(data-lu-effect="fade")
    assert rendered_to_string(~H|<.carousel id="g" effect="flip">
  <.carousel_slide>a</.carousel_slide>
</.carousel>|) =~ ~s(data-lu-effect="flip")
  end

  test "navigation renders previous before next, both controlling the track" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.carousel id="g" navigation prev_label="Anterior" next_label="Próximo">
  <.carousel_slide>a</.carousel_slide>
</.carousel>|
      )

    {prev, _} = :binary.match(html, "Anterior")
    {next, _} = :binary.match(html, "Próximo")
    assert prev < next
    assert html =~ ~s(aria-controls="g")
  end

  test "pagination: bullets, fraction and progress" do
    assigns = %{}
    html = rendered_to_string(~H|<.carousel id="g" pagination="bullets" slides={3}>
  <.carousel_slide>a</.carousel_slide>
</.carousel>|)
    assert html =~ ~s(id="g-dots")
    assert html =~ "aria-[current=true]:bg-ink"
    assert length(String.split(html, "role=\"button\"")) == 4
    assert html =~ ~s(aria-label="Go to slide 1")
    assert html =~ ~s(aria-current="true")
    assert html =~ ~s(role="region")
    assert html =~ ~s(aria-roledescription="carousel")
    html = rendered_to_string(~H|<.carousel id="g" pagination="fraction" slides={3} index={1}>
  <.carousel_slide>a</.carousel_slide>
</.carousel>|)
    assert html =~ "2/3"
    assert rendered_to_string(~H|<.carousel id="g" pagination="progress" slides={3}>
  <.carousel_slide>a</.carousel_slide>
</.carousel>|) =~ "data-carousel-bar"
  end

  test "thumbs row" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.carousel id="g" thumb_label="Ver">
        <.carousel_slide>a</.carousel_slide>
        <:thumb><b>t1</b></:thumb>
        <:thumb><b>t2</b></:thumb>
      </.carousel>
      """)

    assert html =~ ~s(id="g-thumbs")
    assert html =~ ~s(aria-label="Ver 2")
  end

  test "config that is not the default goes to data attributes" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.carousel id="g" index={2} autoplay={2000} loop gap={30} zoom={4} on_change="slid" label="Fotos">
  <.carousel_slide>a</.carousel_slide>
</.carousel>|
      )

    assert html =~ ~s(data-index="2")
    assert html =~ ~s(data-autoplay="2000")
    assert html =~ ~s(data-loop="true")
    assert html =~ ~s(data-gap="30")
    assert html =~ ~s(data-zoom="4")
    assert html =~ ~s(data-on-change="slid")
    assert html =~ ~s(aria-label="Fotos")
  end
end
