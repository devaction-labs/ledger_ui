defmodule LedgerUI.Perf.NotificationCenterDiffTest do
  # #99: the rows are components with `:key`, so a new notification or a read mark sends that row
  # only; and `items` accepts a stream (the counters then come from the caller).
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI

  import LedgerUI.DiffCase

  alias Phoenix.LiveView.LiveStream

  def t_nc(assigns) do
    ~H"""
    <.notification_center id="nc" items={@items} variant={@variant} unread={@unread} tabs={@tabs} />
    """
  end

  def t_nc_stream(assigns) do
    ~H"""
    <.notification_center
      id="nc"
      items={@streams.notifications}
      variant={@variant}
      unread={@unread}
      tabs={@tabs}
    />
    """
  end

  defp items(n, from \\ 1) do
    for i <- from..(from + n - 1) do
      %{
        id: i,
        title: "n#{i}",
        body: "corpo #{i}",
        read: false,
        group: "Hoje",
        at: "10:0#{rem(i, 10)}"
      }
    end
  end

  defp base(variant, items), do: %{items: items, variant: variant, unread: nil, tabs: nil}

  for variant <- ~w(canvas classic) do
    describe "#{variant}" do
      test "a new one on top, a read mark, one at the end, the first removed" do
        v = unquote(variant)
        list = items(20)
        top = check(&t_nc/1, base(v, list), items: [hd(items(1, 21)) | list])
        read = check(&t_nc/1, base(v, list), items: List.update_at(list, 9, &%{&1 | read: true}))
        bottom = check(&t_nc/1, base(v, list), items: list ++ items(1, 21))
        drop = check(&t_nc/1, base(v, list), items: tl(list))

        IO.puts(
          "MEASURE nc #{v}: top #{byte_size(top)} read #{byte_size(read)} bottom #{byte_size(bottom)} drop #{byte_size(drop)}"
        )

        # before: 5 910 / 5 164 B (canvas) and 6 441 / 368 B (classic). A new row weighs what its markup
        # weighs (the templates of its parts go along): that is the floor of the insert.
        assert byte_size(top) < 1400
        assert byte_size(read) < 500
      end

      test "each source" do
        v = unquote(variant)

        base = base(v, items(5))
        changes = [items: items(3), unread: 7, tabs: [%{id: "all", label: "Tudo"}]]
        # `tabs` only draws in the classic variant
        changes =
          Enum.filter(changes, fn {k, val} ->
            html(&t_nc/1, base) != html(&t_nc/1, Map.put(base, k, val))
          end)

        each_source(&t_nc/1, base, changes)
      end
    end
  end

  test "items without id and with repeated ids still render (positional keys)" do
    no_id = for i <- 1..3, do: %{title: "t#{i}"}
    dup = [%{id: 1, title: "a"}, %{id: 1, title: "b"}]
    check(&t_nc/1, base("canvas", no_id), items: [%{title: "novo"} | no_id])
    check(&t_nc/1, base("classic", dup), items: [%{id: 1, title: "c"} | dup])
  end

  describe "stream" do
    defp stream(items), do: LiveStream.new(:notifications, 0, items, [])

    defp stream_base(variant, items, extra \\ %{}) do
      Map.merge(
        %{
          streams: %{notifications: stream(items), __ref__: 0},
          variant: variant,
          unread: 3,
          tabs: [
            %{id: "all", label: "Tudo"},
            %{id: "unread", label: "Nao lidas"},
            %{id: "pedidos", label: "Pedidos", count: 2}
          ]
        },
        extra
      )
    end

    for variant <- ~w(canvas classic) do
      test "#{variant}: renders the rows in a stream container" do
        html = html(&t_nc_stream/1, stream_base(unquote(variant), items(3)))
        assert html =~ ~s(phx-update="stream")
        assert html =~ ~s(id="notifications-)
        assert html =~ "n3"
      end

      test "#{variant}: the counters change and the patch is the same as a fresh render" do
        v = unquote(variant)
        each_source(&t_nc_stream/1, stream_base(v, items(3)), unread: 9)
      end
    end

    test "unread is required" do
      assert_raise ArgumentError, ~r/needs `unread`/, fn ->
        html(&t_nc_stream/1, stream_base("canvas", items(2), %{unread: nil}))
      end
    end

    test "a tab with its own category needs its count" do
      tabs = [%{id: "all", label: "Tudo"}, %{id: "pedidos", label: "Pedidos"}]

      assert_raise ArgumentError, ~r/`count` of the tab "pedidos"/, fn ->
        html(&t_nc_stream/1, stream_base("classic", items(2), %{tabs: tabs}))
      end
    end
  end
end
