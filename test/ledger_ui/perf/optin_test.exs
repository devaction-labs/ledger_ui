defmodule LedgerUI.Perf.OptinTest do
  # Opt-in light modes (#A5, #A7): `command_palette defer_items` and `tip_host`/`tip`.
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.CommandPalette
  import LedgerUI.Components.Tooltip
  import LedgerUI.Components.Button, only: [button: 1]

  @icons ~w(cart plus search user settings home bell star check trash)

  defp items(n) do
    for i <- 1..n do
      %{
        group: "Group #{div(i, 10)}",
        scope: if(rem(i, 2) == 0, do: "pages", else: "actions"),
        label: "Item number #{i}",
        sub: "Sub #{i}",
        icon: Enum.at(@icons, rem(i, length(@icons))),
        navigate: "/items/#{i}",
        keys: ["G", "#{i}"],
        keywords: "kw#{i}"
      }
    end
  end

  # a navigation index: label, group, scope, icon (6 distinct) and a link
  defp plain_items(n) do
    for i <- 1..n do
      %{
        group: "Group #{div(i, 14)}",
        scope: "pages",
        label: "Item number #{i}",
        icon: Enum.at(~w(cart plus search user settings home), rem(i, 6)),
        navigate: "/items/#{i}"
      }
    end
  end

  defp palette(extra \\ %{}) do
    assigns =
      Map.merge(%{items: items(40), extra: %{}, scopes: ["All", "pages", "actions"]}, extra)

    rendered_to_string(~H"""
    <.command_palette id="p" items={@items} scopes={@scopes} {@extra} />
    """)
  end

  defp payload(html) do
    [_, json] =
      Regex.run(
        ~r/<script type="application\/json" data-part="palette-items">(.*?)<\/script>/s,
        html
      )

    Jason.decode!(json)
  end

  describe "command_palette defer_items" do
    test "the default keeps the HTML: false is the same as omitting it" do
      assigns = %{items: items(5)}

      a = rendered_to_string(~H|<.command_palette id="p" items={@items} />|)
      b = rendered_to_string(~H|<.command_palette id="p" items={@items} defer_items={false} />|)
      assert a == b
      assert a =~ ~s(data-part="palette-item")
      refute a =~ "palette-data"
      refute a =~ "phx-update"
    end

    test "40 items, closed: the payload is under 10 KB (54 KB to 116 KB by default)" do
      plain = %{items: plain_items(40), scopes: ["All", "pages"]}
      normal = palette(plain)
      deferred = palette(Map.put(plain, :extra, %{defer_items: true}))

      assert byte_size(normal) > 50_000
      assert byte_size(deferred) < 10_000

      # rich items (sub, keys, keywords, 10 icons): the JSON grows, the rows stay out
      rich = palette(%{extra: %{defer_items: true}})
      assert byte_size(rich) < 25_000
      assert byte_size(palette()) > 3 * byte_size(rich)

      IO.puts(
        "palette 40 plain items: default #{byte_size(normal)} B, defer_items #{byte_size(deferred)} B; " <>
          "40 rich items: default #{byte_size(palette())} B, defer_items #{byte_size(rich)} B"
      )
    end

    test "no row is rendered: the rows come from the JSON and one template per distinct icon" do
      html = palette(%{extra: %{defer_items: true}})

      refute html =~ ~s(data-part="palette-item")
      refute html =~ ~s(data-part="palette-label")
      assert html =~ ~s(data-part="palette-list")
      assert html =~ ~s(phx-update="ignore")
      assert html =~ ~s(data-part="palette-data")
      # the dialog, the input, the scopes and the roles stay on the server
      assert html =~ ~s(role="dialog")
      assert html =~ ~s(role="listbox")
      assert html =~ ~s(data-part="palette-scope")

      assert length(Regex.scan(~r/<template [^>]*data-lu-icon=/, html)) == length(@icons)

      %{"r" => rows} = payload(html)
      assert length(rows) == 40
      [first | _] = rows
      assert first["l"] == "Item number 1"
      assert first["n"] == "/items/1"
      assert first["sc"] == "actions"
      assert first["kw"] == "kw1"
      assert first["k"] == ["G", "1"]
      assert first["g"] == "Group 0"
      # the heading only comes before the first row of each group
      assert Enum.count(rows, & &1["g"]) == 5
      # no repeated class strings per item: they are sent once (only those of the parts in use)
      assert html =~ ~s(data-lu-c-item=)
      assert html =~ ~s(data-lu-c-kbd=)
      refute html =~ ~s(data-lu-c-count=)
      refute html =~ ~s(data-lu-c-avatar=)
      assert length(Regex.scan(~r/h-\[34px\]/, html)) == 1
    end

    test "link kinds, avatar, count, style, value and the assistant row" do
      assigns = %{
        items: [
          %{label: "A", patch: "/a", count: 3},
          %{label: "B", href: "https://x.y", avatar: %{initials: "BB", tint: "#fff"}},
          %{label: "C", value: "cv", style: "color:red", icon: "plus", sub: "s"},
          %{label: "D"}
        ]
      }

      html =
        rendered_to_string(~H"""
        <.command_palette
          id="p"
          items={@items}
          assistant={%{label: "Ask %{query}", sub: "AI"}}
          defer_items
        />
        """)

      %{"r" => [a, b, c, d], "a" => asst} = payload(html)
      assert a == %{"l" => "A", "p" => "/a", "c" => 3}
      assert b == %{"l" => "B", "h" => "https://x.y", "a" => ["BB", "#fff"]}
      assert c == %{"l" => "C", "v" => "cv", "st" => "color:red", "i" => "plus", "s" => "s"}
      assert d == %{"l" => "D"}
      assert asst == %{"l" => "Ask %{query}", "s" => "AI", "i" => "sparkles"}
      # the assistant icon has its template too
      assert html =~ ~s(data-lu-icon="sparkles")
      assert html =~ ~s(data-lu-c-count=)
      assert html =~ ~s(data-lu-c-avatar=)
      refute html =~ ~s(data-lu-assistant=")
    end

    test "the item_icon slot, inline and bare keep the server rendering" do
      assigns = %{items: items(3)}

      with_slot =
        rendered_to_string(~H"""
        <.command_palette id="p" items={@items} defer_items>
          <:item_icon :let={i}>{i.label}</:item_icon>
        </.command_palette>
        """)

      assert with_slot =~ ~s(data-part="palette-item")
      refute with_slot =~ "palette-data"

      for extra <- [%{inline: true}, %{bare: true}] do
        html = palette(%{items: items(3), extra: Map.put(extra, :defer_items, true)})
        assert html == palette(%{items: items(3), extra: extra})
        assert html =~ ~s(data-part="palette-item")
      end
    end

    test "the labels are escaped in the attribute" do
      assigns = %{items: [%{label: ~s(<b>"x" & 'y'</b>)}]}
      html = rendered_to_string(~H|<.command_palette id="p" items={@items} defer_items />|)
      refute html =~ "<b>"
      assert %{"r" => [%{"l" => ~s(<b>"x" & 'y'</b>)}]} = payload(html)
    end
  end

  describe "tip_host / tip" do
    defp tips(n, opts \\ "") do
      assigns = %{n: n, opts: opts}

      rendered_to_string(~H"""
      <.tip_host id="tips">
        <.tip :for={i <- 1..@n} text={"Hint #{i}"}>
          <.button size="sm">B{i}</.button>
        </.tip>
      </.tip_host>
      """)
    end

    test "the light tip is a span with data-lu-tip: no hook, no hint in the DOM" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tip text="Save"><.button>Save</.button></.tip>
        """)

      assert html =~ ~s(data-lu-tip="Save")
      assert html =~ ~s(class="relative inline-flex")
      refute html =~ "phx-hook"
      refute html =~ "role=\"tooltip\""
      refute html =~ "data-lu-tip-"
    end

    test "only the non-default options are rendered" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tip text="x" placement="bottom-end" color="error" arrow={false} delay={150}>t</.tip>
        """)

      assert html =~ ~s(data-lu-tip-placement="bottom-end")
      assert html =~ ~s(data-lu-tip-color="error")
      assert html =~ ~s(data-lu-tip-arrow="false")
      assert html =~ ~s(data-lu-tip-delay="150")
    end

    test "tip_host carries the one hook and the classes of every colour, once" do
      assigns = %{}
      html = rendered_to_string(~H|<.tip_host id="tips">x</.tip_host>|)

      assert html =~ ~s(phx-hook="LedgerUI.Tip")
      assert html =~ ~s(id="tips")
      assert html =~ "data-lu-float-class="
      assert html =~ ~s(class="contents")

      [_, json] = Regex.run(~r/data-lu-tip-classes="([^"]*)"/, html)
      classes = json |> unescape() |> Jason.decode!()

      assert Enum.sort(Map.keys(classes)) ==
               Enum.sort(~w(neutral light dark primary secondary info success warning error))

      assert classes["neutral"] =~ "bg-ink"
      assert classes["success"] =~ "--c"
    end

    test "the bubble classes are the ones of the text tooltip (same look)" do
      assigns = %{}

      heavy =
        rendered_to_string(~H"""
        <.tooltip id="t" text="Hint" color="success"><.button>B</.button></.tooltip>
        """)

      [_, tip_cls] = Regex.run(~r/data-part="tooltip-tip" class="([^"]*)"/, heavy)

      host = rendered_to_string(~H|<.tip_host id="tips">x</.tip_host>|)
      [_, json] = Regex.run(~r/data-lu-tip-classes="([^"]*)"/, host)
      classes = json |> unescape() |> Jason.decode!()
      assert classes["success"] == unescape(tip_cls)

      [_, fl] = Regex.run(~r/data-part="tooltip-float"[^>]* class="([^"]*)"/, heavy)
      [_, hostfl] = Regex.run(~r/data-lu-float-class="([^"]*)"/, host)
      assert fl == hostfl
    end

    test "100 light tips add under 20 KB to their triggers (about 160 KB as tooltip/1)" do
      assigns = %{n: 100}
      light = tips(100)

      heavy =
        rendered_to_string(~H"""
        <.tooltip :for={i <- 1..@n} id={"t#{i}"} text={"Hint #{i}"}>
          <.button size="sm">B{i}</.button>
        </.tooltip>
        """)

      bare =
        rendered_to_string(~H"""
        <.button :for={i <- 1..@n} size="sm">B{i}</.button>
        """)

      IO.puts(
        "100 tips: tooltip/1 #{byte_size(heavy)} B, tip/1 #{byte_size(light)} B, only the buttons #{byte_size(bare)} B"
      )

      # what the tips add around the buttons (the buttons are the same in the three)
      assert byte_size(light) - byte_size(bare) < 20_000
      assert byte_size(heavy) - byte_size(bare) > 100_000
    end

    test "the tip adds ~100 B around the trigger" do
      assigns = %{}
      with_tip = rendered_to_string(~H|<.tip text="Hint 1"><.button size="sm">B</.button></.tip>|)
      bare = rendered_to_string(~H|<.button size="sm">B</.button>|)
      assert byte_size(with_tip) - byte_size(bare) < 150
    end
  end

  defp unescape(s) do
    s
    |> String.replace("&quot;", "\"")
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("&#39;", "'")
    |> String.replace("&amp;", "&")
  end
end
