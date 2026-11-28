defmodule LedgerUI.Components.PhoneInputTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.PhoneInput

  alias LedgerUI.Components.PhoneInput.Format

  doctest LedgerUI.Components.PhoneInput.Format

  test "starts in Brazil with a picker button, a number input and a hidden E.164 input" do
    assigns = %{}
    html = rendered_to_string(~H|<.phone_input name="phone" label="Telefone" />|)
    assert html =~ ~s(phx-hook="LedgerUI.PhoneInput")
    assert html =~ ~s(id="phone")
    assert html =~ ~s(data-lu-country="BR")
    assert html =~ ~r/<b class="text-xs" data-lu-phone-iso>BR<\/b>/
    assert html =~ "+55"
    assert html =~ ~s(type="tel")
    assert html =~ ~s(<input type="hidden" name="phone" value="")
    assert html =~ ~s(aria-haspopup="listbox")
    assert html =~ ~s(aria-label="Country")
    # the visible input has no name
    refute html =~ ~r/data-lu-phone-number[^>]*name=/
    refute html =~ ~r/name="phone"[^>]*data-lu-phone-number/
    assert html =~ "Telefone"
  end

  test "E.164 value selects its country and is shown in the national format" do
    assigns = %{}
    html = rendered_to_string(~H|<.phone_input name="p" value="+5511912345678" />|)
    assert html =~ ~s[value="(11) 91234-5678"]
    assert html =~ ~s(value="+5511912345678")

    html = rendered_to_string(~H|<.phone_input name="p" value="+351912345678" />|)
    assert html =~ ~s(data-lu-country="PT")
    assert html =~ ~s(value="912 345 678")

    html = rendered_to_string(~H|<.phone_input name="p" value="+17875551234" />|)
    assert html =~ ~s(data-lu-country="PR")

    html = rendered_to_string(~H|<.phone_input name="p" country="US" value="(415) 555-0100" />|)
    assert html =~ ~s(data-lu-country="US")
    assert html =~ ~s(value="+14155550100")
  end

  test "the HTML carries the offered ISO codes, not the rows" do
    assigns = %{}
    html = rendered_to_string(~H|<.phone_input name="p" country_order={~w(PT BR)} />|)
    [_, codes] = Regex.run(~r/data-lu-countries="([^"]*)"/, html)
    isos = String.split(codes, ",")
    assert Enum.take(isos, 2) == ~w(PT BR)
    assert length(isos) == length(Format.all())
    assert html =~ ~s(data-lu-pt="true")
    refute html =~ "data-lu-iso="
    refute html =~ "Estados Unidos"
    assert byte_size(html) < 8_000
    # the empty listbox is still there, with the classes the hook gives the rows
    assert html =~ ~s(role="listbox")
    assert html =~ "data-lu-phone-list"
    assert html =~ "data-lu-row-class="
    assert html =~ "data-lu-right-class="

    html = rendered_to_string(~H|<.phone_input name="p" locale="en" except={~w(KP BR)} />|)
    refute html =~ ~s(data-lu-pt)
    [_, codes] = Regex.run(~r/data-lu-countries="([^"]*)"/, html)
    refute "BR" in String.split(codes, ",")

    html = rendered_to_string(~H|<.phone_input name="p" countries={~w(BR PT AR UY)} />|)
    assert html =~ ~s(data-lu-countries="AR,BR,PT,UY")

    # a country that is not offered is replaced by the first one that is
    html = rendered_to_string(~H|<.phone_input name="p" country="US" countries={~w(PT BR)} />|)
    assert html =~ ~s(data-lu-country="BR")
  end

  test "the size does not grow with the list: six fields cost six small roots" do
    assigns = %{}
    one = rendered_to_string(~H|<.phone_input name="a" flags />|) |> byte_size()

    six =
      rendered_to_string(~H"""
      <.phone_input name="a" flags /><.phone_input name="b" flags /><.phone_input name="c" flags />
      <.phone_input name="d" flags /><.phone_input name="e" flags /><.phone_input name="f" flags />
      """)
      |> byte_size()

    assert one < 8_000
    assert six < 6 * one + 200
  end

  test "the shipped country data (phone_countries.js) is the Format data" do
    path = Path.expand("../../../priv/static/ledger_ui/lib/phone_countries.js", __DIR__)
    assert File.read!(path) == Format.js_module()
  end

  test "flags, clearable, variant, size, shape, state, errors and slot texts" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.phone_input
        name="p"
        flags
        clearable
        variant="filled"
        size="lg"
        shape="pill"
        state="success"
        clear_label="Limpar"
        picker_label="Pais"
        search_placeholder="Buscar"
        no_results="Nada para %{query}"
      />
      """)

    assert html =~ "🇧🇷"
    assert html =~ "data-lu-phone-clear"
    assert html =~ ~s(aria-label="Limpar")
    assert html =~ "h-11"
    assert html =~ "rounded-full"
    assert html =~ "border-pos"
    assert html =~ ~s(aria-label="Pais")
    assert html =~ ~s(placeholder="Buscar")
    assert html =~ "Nada para %{query}"

    html = rendered_to_string(~H|<.phone_input name="p" errors={["Invalido"]} disabled />|)
    assert html =~ "border-neg"
    assert html =~ "cursor-not-allowed"
    assert html =~ "Invalido"
    assert html =~ ~s(aria-invalid="true")
  end

  test "on_country_change, target and debounce go to the hook / hidden input" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.phone_input name="p" on_country_change="country" target="#f" phx-debounce="300" />|
      )

    assert html =~ ~s(data-lu-on-country-change="country")
    assert html =~ ~s(data-lu-target="#f")
    assert html =~ ~r/type="hidden"[^>]*phx-debounce="300"/
  end

  test "field supplies id, name and value" do
    form = to_form(%{"phone" => "+5575998123344"}, as: :c)
    assigns = %{f: form[:phone]}
    html = rendered_to_string(~H|<.phone_input field={@f} />|)
    assert html =~ ~s(id="c_phone")
    assert html =~ ~s(name="c[phone]")
    assert html =~ ~s[value="(75) 99812-3344"]
  end

  test "Format.e164 normalizes and rejects" do
    assert Format.e164("(75) 99812-3344", "BR") == {:ok, "+5575998123344"}
    assert Format.e164("075 99812-3344", "BR") == {:ok, "+5575998123344"}
    assert Format.e164("+55 75 99812-3344", "US") == {:ok, "+5575998123344"}
    assert Format.e164("0055 75 99812 3344", "US") == {:ok, "+5575998123344"}
    assert Format.e164("(415) 555-0100", "US") == {:ok, "+14155550100"}
    assert Format.e164("+1 876 555 0100", "BR") |> elem(1) == "+18765550100"
    assert Format.e164("", "BR") == {:error, :empty}
    assert Format.e164(nil, "BR") == {:error, :empty}
    assert Format.e164("123", "BR") == {:error, :too_short}
    assert Format.e164("+999 123456", "BR") == {:error, :unknown_country}
    assert Format.e164("+55 " <> String.duplicate("9", 14), "BR") == {:error, :too_long}
  end

  test "Format.detect tells countries that share a calling code apart" do
    all = Format.all()
    assert {%{iso: "JM"}, "8765550100"} = Format.detect("18765550100", all)
    assert {%{iso: "CA"}, "4165550100"} = Format.detect("14165550100", all)
    assert {%{iso: "US"}, _} = Format.detect("12125550100", all)
    assert {%{iso: "GG"}, _} = Format.detect("447911123456", all)
    assert {%{iso: "GB"}, _} = Format.detect("442071234567", all)
    assert Format.detect("999123", all) == nil
  end

  test "Format.format_national keeps separators until a digit follows" do
    assert Format.format_national("119", "BR") == "(11) 9"
    assert Format.format_national("1", "BR") == "(1"
    assert Format.format_national("1191234", "BR") == "(11) 9123-4"
    assert Format.format_national("1133334444", "BR") == "(11) 3333-4444"
    assert Format.format_national("11912345678", "BR") == "(11) 91234-5678"
    assert Format.format_national("119123456789", "BR") == "(11) 91234-56789"
    assert Format.format_national("", "BR") == ""
  end

  test "style goes to the box" do
    assigns = %{}
    html = rendered_to_string(~H|<.phone_input name="p" style="width:280px" />|)
    assert html =~ ~r/data-part="phone-box" class="[^"]*" style="width:280px"/
    html = rendered_to_string(~H|<.phone_input name="p" />|)
    refute html =~ ~r/data-part="phone-box" class="[^"]*" style=/
  end

  test "the country list is a top-layer panel" do
    assigns = %{}
    html = rendered_to_string(~H|<.phone_input id="ph" name="ph" />|)
    assert html =~ ~s(popover="manual")
    assert html =~ ~s(data-lu-placement="bottom-start")
    refute html =~ "absolute top-"
  end
end
