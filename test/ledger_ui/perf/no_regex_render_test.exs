defmodule LedgerUI.Perf.NoRegexRenderTest do
  # #94 (C2 and the `~r` that ran at render time in these components): the replacements give what the
  # regexes gave, and the phone list is not folded (NFD) on every render.
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]
  alias LedgerUI.Components.{ColorPicker, NumberInput, PhoneInput}

  describe "NumberInput.machine/1" do
    test "reads what the regex read" do
      for v <- [
            "12",
            "-12",
            "1.5",
            "-1.5",
            " 3 ",
            "0.0",
            "007",
            "1.",
            ".5",
            "-",
            "",
            "1.2.3",
            "1,5",
            "a1",
            "1a",
            "--1",
            "1 2",
            "٣",
            "1e3",
            "+1"
          ] do
        want = if Regex.match?(~r/^-?\d+(\.\d+)?$/, String.trim(v)), do: String.trim(v), else: nil
        assert NumberInput.machine(v) == want, "machine(#{inspect(v)})"
      end
    end
  end

  describe "ColorPicker.normalize/1" do
    test "reads what the regexes read" do
      for v <- [
            "#4c3fe0",
            "4C3FE0",
            "#fff",
            "FFF",
            "#4c3fe0aa",
            "#12345",
            "1234567",
            "#ggg",
            "",
            "#",
            " #abc ",
            "zzzzzz",
            "#ABCDEF12",
            "abcd"
          ] do
        hex = v |> String.trim() |> String.trim_leading("#") |> String.upcase()

        want =
          cond do
            Regex.match?(~r/^[0-9A-F]{3}$/, hex) ->
              "#" <> (hex |> String.graphemes() |> Enum.map_join(&(&1 <> &1)))

            Regex.match?(~r/^([0-9A-F]{6}|[0-9A-F]{8})$/, hex) ->
              "#" <> hex

            true ->
              nil
          end

        assert ColorPicker.normalize(v) == want, "normalize(#{inspect(v)})"
      end
    end
  end

  describe "ids from a name" do
    test "otp_input and phone_input squash each run of other characters into one dash" do
      for name <- ["code", "f[code]", "a b", "x__y", "é!ü1", "user[code][0]"] do
        id = name |> String.replace(~r/[^A-Za-z0-9_-]+/u, "-") |> String.trim("-")
        assigns = %{n: name}
        assert rendered_to_string(~H|<.otp_input name={@n} />|) =~ ~s(id="#{id}")
        assert rendered_to_string(~H|<.phone_input name={@n} />|) =~ ~s(id="#{id}-wrap")
      end
    end

    test "password_input keeps a valid id and cleans an invalid one" do
      for {name, id} <- [
            {"pw", "pw"},
            {"login[password]", "lu-pw-login-password"},
            {"1abc", "lu-pw-1abc"},
            {"_x-y", "_x-y"},
            {"a b", "lu-pw-a-b"},
            {"[x]", "lu-pw-x"}
          ] do
        assigns = %{n: name}
        assert rendered_to_string(~H|<.password_input id={@n} />|) =~ ~s(id="#{id}")
      end
    end
  end

  describe "phone_input country list" do
    test "the order is the one the fold-and-sort gave" do
      fold = fn t ->
        t |> String.normalize(:nfd) |> String.replace(~r/\p{Mn}/u, "") |> String.downcase()
      end

      for pt? <- [true, false],
          order <- [[], ["US", "br"], ["PT", "JP", "XX"]],
          except <- [[], ["US"]],
          only <- [[], ["BR", "PT", "US", "CA", "JP"]] do
        old =
          PhoneInput.Format.all()
          |> Enum.filter(fn c -> c.iso not in except and (only == [] or c.iso in only) end)
          |> then(fn list ->
            first = order |> Enum.map(&String.upcase/1) |> Enum.with_index() |> Map.new()

            Enum.sort_by(list, fn c ->
              {Map.get(first, c.iso, map_size(first)), fold.(if pt?, do: c.pt, else: c.en)}
            end)
          end)

        assert PhoneInput.Format.offered(only, except, order, pt?) == old
      end
    end

    test "offered/4 does no Unicode folding" do
      :erlang.trace_pattern({:unicode, :characters_to_nfd_binary, 1}, true, [:global])
      :erlang.trace(self(), true, [:call])
      PhoneInput.Format.offered([], [], ["BR"], true)
      PhoneInput.Format.offered([], [], [], false)
      :erlang.trace(self(), false, [:call])
      :erlang.trace_pattern({:unicode, :characters_to_nfd_binary, 1}, false, [:global])
      refute_received {:trace, _, :call, {:unicode, :characters_to_nfd_binary, _}}
    end
  end
end
