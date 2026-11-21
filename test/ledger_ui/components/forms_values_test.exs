defmodule LedgerUI.Components.FormsValuesTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest

  import LedgerUI.Components.{
    ColorPicker,
    SignaturePad,
    NumberInput,
    Range,
    Rating,
    ImageInput,
    Upload
  }

  defp r(h), do: rendered_to_string(h)

  describe "color_picker" do
    test "hidden input carries upper-case hex; hook and swatches" do
      assigns = %{}
      html = r(~H|<.color_picker id="c" name="tag" value="#4c3fe0" />|)
      assert html =~ ~s(name="tag" value="#4C3FE0")
      assert html =~ ~s(phx-hook="LedgerUI.ColorPicker")
      assert html =~ ~s(data-part="color-picker-controls")
      assert html =~ ~r/aria-label="#2763E6"/
    end

    test "alpha adds the opacity slider; swatches variant with sizes and hex field" do
      assigns = %{}

      assert r(~H|<.color_picker id="c" name="t" alpha value="#11223380" />|) =~
               "data-alpha-track"

      html =
        r(~H|<.color_picker
  id="s"
  variant="swatches"
  hex_field
  swatch_size="lg"
  value="#0D8F91"
  presets={~w(#0D8F91 #2F5FD0)}
/>|)

      refute html =~ ~s(data-part="color-picker-controls")
      assert html =~ "size-[34px]"
      assert html =~ ~r/aria-pressed="true"[^>]*>/
      assert html =~ ~r/>\s*Hex\s*</
    end

    test "normalize/hsv" do
      assert normalize("#fff") == "#FFFFFF"
      assert normalize("zzz") == nil
      assert hsv("#FF0000") == {0, 100, 100, 100}
    end
  end

  describe "signature_pad" do
    test "stored svg is shown as paths only, hidden input keeps value" do
      assigns = %{}

      assigns = %{
        svg: ~s(<svg viewBox="0 0 300 170"><path d="M1 1 L5 5"/><script>x</script></svg>)
      }

      html = r(~H|<.signature_pad id="s" name="sig" value={@svg} locale="pt_BR" />|)
      assert html =~ ~s(d="M1 1 L5 5")
      refute html =~ "<script>"
      assert html =~ "Limpar"
      assert html =~ ~s(phx-update="ignore")
      assert html =~ ~s(name="sig")
    end

    test "modes switch, type mode and confirm" do
      assigns = %{}
      html = r(~H|<.signature_pad id="s" name="x" mode="type" text="Ana" confirm="OK" />|)
      assert html =~ ~r/data-part="signature-typed"[^>]*>Ana/
      assert html =~ ~s(data-part="signature-mode")
      assert html =~ "OK"
      html = r(~H|<.signature_pad id="s" modes={["draw"]} footer={false} />|)
      refute html =~ ~s(data-part="signature-mode")
      refute html =~ ~s(data-part="signature-clear")
    end
  end

  describe "number_input" do
    test "format_number" do
      assert format_number(1284.9, decimals: 2) == "1.284,90"
      assert format_number(0.75, decimals: 3) == "0,750"
      assert format_number(12.5, locale: "en", max_decimals: 2) == "12.5"
      assert format_number(1_234_567, locale: "en") == "1,234,567"
      assert format_number("-3.456", decimals: 2) == "-3,46"
      assert format_number(nil) == ""
    end

    test "hidden machine value, prefix/suffix, steppers, labels" do
      assigns = %{}

      html =
        r(~H|<.number_input
  id="n"
  name="price"
  value={1234.5}
  decimals={2}
  prefix="R$"
  suffix="un"
  steppers
  stepper_style="round"
  size="lg"
  label="Preço"
/>|)

      assert html =~ ~s(name="price" value="1234.5")
      assert html =~ ">1.234,50<"
      assert html =~ "gap-1.5 border-0"
      assert html =~ "h-11"
      assert html =~ ~s(aria-label="Diminuir")
      assert html =~ ~r/data-part="number-prefix" class="[^"]*">R\$/
      assert html =~ ~s(role="spinbutton")
      assert html =~ "Preço"
    end

    test "en locale, field" do
      form = Phoenix.Component.to_form(%{"q" => "1234.5"}, as: :t)
      assigns = %{form: form}
      html = r(~H|<.number_input field={@form[:q]} locale="en" steppers />|)
      assert html =~ ">1,234.5<"
      assert html =~ ~s(name="t[q]" value="1234.5")
      assert html =~ ~s(aria-label="Decrease")
    end
  end

  describe "range" do
    test "position, colors, sizes, vertical, nofill" do
      assigns = %{}
      html = r(~H|<.range
  id="a"
  name="v"
  value={25}
  max={50}
  color="info"
  size="sm"
  filled={false}
  variant="classic"
/>|)
      assert html =~ "[--c:var(--lu-info)]"
      assert html =~ "rounded-[6px]"
      assert html =~ "hidden"
      assert html =~ "--lu-sp:50%"
      assert html =~ ~s(name="v" value="25")
      assert html =~ ~s(role="slider")

      assert r(~H|<.range id="b" orientation="vertical" height="5rem" value={10} />|) =~
               "height:5rem"
    end

    test "pair, show_value format, marks, steppers" do
      assigns = %{}

      html =
        r(~H|<.range
  id="p"
  start_name="a"
  end_name="b"
  value={{20, 80}}
  show_value
  value_format="R$ %{value}"
  label="Preço"
  marks={[0, {50, "meio"}, 100]}
  steppers
/>|)

      assert html =~ "--lu-sp:80%;--lu-rlo:20%"
      assert html =~ ~s(name="a" value="20")
      assert html =~ ~s(name="b" value="80")
      assert html =~ "R$ 20 – 80"
      assert html =~ ">meio<"
      assert html =~ "left-(--lu-rlo)"
      assert html =~ ~s(aria-label="Decrease")
    end
  end

  describe "rating" do
    test "read-only: halves, number, count, accessible text" do
      assigns = %{}
      html = r(~H|<.rating value={4.5} show_value count={38} size="lg" variant="outline" />|)
      assert html =~ "size-6"
      assert html =~ "fill-none stroke-current"
      assert html =~ "[clip-path:inset(0_50%_0_0)]"
      assert html =~ ~r/>\s*4,5\s*</
      assert html =~ "(38)"
      assert html =~ ~s(aria-label="4,5 de 5 estrelas")
      refute html =~ ~s(type="radio")
    end

    test "interactive radios with name, checked and event" do
      assigns = %{}

      html =
        r(~H|<.rating id="r" name="grade" value={3} on_change="rate" label="Nota" max={4} />|)

      assert length(Regex.scan(~r/type="radio"/, html)) == 4
      assert html =~ ~r/value="3"[^>]*checked/ or html =~ ~r/checked[^>]*value="3"/
      assert html =~ ~s(phx-click="rate")
      assert html =~ ~s(role="radiogroup")
      assert html =~ "Nota"
    end

    test "distribution works out average and shares" do
      assigns = %{}
      html = r(~H|<.rating_distribution counts={%{5 => 1, 4 => 1}} unit="votos" />|)
      assert html =~ "4,5"
      assert html =~ "2 votos"
      assert html =~ "width:50%"
    end
  end

  describe "image_input" do
    test "static frame states" do
      assigns = %{}
      assert r(~H|<.image_input shape="circle" />|) =~ "rounded-full"
      html = r(~H|<.image_input size="sm" shape="rounded" initials="BP" hover progress={40} />|)
      assert html =~ "size-[56px]"
      assert html =~ "rounded-[14px]"
      assert html =~ ~s(data-state="has hover")
      assert html =~ ~s(data-part="image-input-overlay")
      assert html =~ "--lu-sp:40%"
    end

    test "with a name: file input, remove flag and revert button" do
      assigns = %{}
      html = r(~H|<.image_input name="avatar" value="/a.png" />|)
      assert html =~ ~s(type="file" name="avatar")
      assert html =~ ~s(name="avatar_remove")
      assert html =~ ~s(src="/a.png")
      assert html =~ ~s(phx-hook="LedgerUI.ImageInput")
    end
  end

  describe "upload parts" do
    test "drop, zone, file states and thumbs" do
      assigns = %{}
      assert r(~H|<.upload_drop over error hint="h" />|) =~ ~s(data-state="over")

      assert r(
               ~H|<.upload_zone variant="glow" color="mono" shape="pill" size="xl">X</.upload_zone>|
             ) =~ "rounded-full"

      html = r(~H|<.upload_file name="a.pdf" state="error" retry_label="Retry" status="bad" />|)
      assert html =~ "color-mix(in_oklab,var(--lu-neg)_40%,var(--lu-line))"
      assert html =~ ~r/>\s*PDF\s*</
      assert html =~ "Retry"
      assert r(~H|<.upload_thumbs columns={2} count={2} />|) =~ "--cols:2"
    end

    test "upload_button wraps a file input in a label" do
      assigns = %{}

      html =
        r(
          ~H|<.upload_button name="doc" variant="outline" size="sm" disabled>Attach</.upload_button>|
        )

      assert html =~ "<label"
      assert html =~ "h-[30px]"
      assert html =~ "pointer-events-none opacity-50"
      assert html =~ ~s(type="file" name="doc")
    end

    test "upload renders live_file_input, entries and errors from an UploadConfig" do
      entry = %Phoenix.LiveView.UploadEntry{
        ref: "0",
        client_name: "nfe.xml",
        client_size: 32_768,
        client_type: "text/xml",
        progress: 64,
        done?: false,
        valid?: true
      }

      config = %Phoenix.LiveView.UploadConfig{
        name: :docs,
        ref: "phx-upl",
        max_entries: 2,
        entries: [entry],
        errors: [{"phx-upl", :too_many_files}]
      }

      assigns = %{config: config}

      html =
        r(~H|<.upload
  upload={@config}
  on_cancel="cancel"
  hint="XML"
  drop_label="Arraste"
  browse_label="escolha"
/>|)

      assert html =~ ~s(type="file")
      assert html =~ ~s(phx-drop-target="phx-upl")
      assert html =~ "nfe.xml"
      assert html =~ "32 KB · 64%"
      assert html =~ ~s(phx-click="cancel")
      assert html =~ ~s(phx-value-ref="0")
      assert html =~ "Too many files"
      assert html =~ "<u>escolha</u>"
    end
  end
end
