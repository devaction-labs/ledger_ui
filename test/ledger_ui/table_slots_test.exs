defmodule LedgerUI.TableSlotsTest do
  # Regression of 0.12.0 (#90): the slots of a row (`:col`, `:action`, `:expand`, `:detail`, `:edit`)
  # are drawn inside `trow/1` and come from a map (`ctx`), so a body that reads an assign of the
  # caller (`{@x}`) used to stay stale when only that assign changed. For `table`, `card_table` and
  # `data_table`, each slot with a body of `{@x}`, of `{r.name} {@x}`, and a change of `@x` alone
  # and together with `rows`: the patch applied must equal a fresh render (`LedgerUI.DiffCase`).
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI

  import LedgerUI.DiffCase

  @rows [%{id: 1, name: "a"}, %{id: 2, name: "b"}]
  @rows2 [%{id: 1, name: "a"}, %{id: 2, name: "b"}, %{id: 3, name: "c"}]

  # One assign per slot, so a failure names the slot.
  defp t_table(assigns) do
    ~H"""
    <.table
      id="t"
      rows={@rows}
      row_id={&"r-#{&1.id}"}
      details
      row_editing={fn r -> r.id == 2 end}
    >
      <:col :let={r} label="Name">{r.name}</:col>
      <:col :let={_r} label="Pure">{@col}</:col>
      <:col :let={r} label="Mixed">{r.name} {@mixed}</:col>
      <:col :let={r} label="Cond">{r.name}<b :if={@cond}>on</b></:col>
      <:action :let={_r}>{@action}</:action>
      <:detail :let={_r} label="D">{@detail}</:detail>
      <:edit :let={_r}>{@edit}</:edit>
      <:expand :let={_r}>{@expand}</:expand>
    </.table>
    """
  end

  defp t_card(assigns) do
    ~H"""
    <.card_table
      id="c"
      rows={@rows}
      row_id={&"r-#{&1.id}"}
      row_editing={fn r -> r.id == 2 end}
    >
      <:col :let={r} label="Name">{r.name}</:col>
      <:col :let={_r} label="Pure">{@col}</:col>
      <:col :let={r} label="Mixed">{r.name} {@mixed}</:col>
      <:col :let={r} label="Cond">{r.name}<b :if={@cond}>on</b></:col>
      <:action :let={_r}>{@action}</:action>
      <:detail :let={_r} label="D">{@detail}</:detail>
      <:edit :let={_r}>{@edit}</:edit>
      <:expand :let={_r}>{@expand}</:expand>
    </.card_table>
    """
  end

  defp t_data(assigns) do
    ~H"""
    <.data_table id="d" rows={@rows} row_id={&"r-#{&1.id}"}>
      <:col :let={r} label="Name">{r.name}</:col>
      <:col :let={_r} label="Pure">{@col}</:col>
      <:col :let={r} label="Mixed">{r.name} {@mixed}</:col>
      <:col :let={r} label="Cond">{r.name}<b :if={@cond}>on</b></:col>
      <:action :let={_r}>{@action}</:action>
      <:expand :let={_r}>{@expand}</:expand>
    </.data_table>
    """
  end

  @base %{
    rows: @rows,
    col: "c0",
    mixed: "m0",
    cond: false,
    action: "a0",
    detail: "d0",
    edit: "e0",
    expand: "x0"
  }

  @changes [
    col: "c1",
    mixed: "m1",
    cond: true,
    action: "a1",
    detail: "d1",
    edit: "e1",
    expand: "x1"
  ]

  @slots %{
    table: [:col, :mixed, :cond, :action, :detail, :edit, :expand],
    card_table: [:col, :mixed, :cond, :action, :detail, :edit, :expand],
    data_table: [:col, :mixed, :cond, :action, :expand]
  }

  defp fun(:table), do: &t_table/1
  defp fun(:card_table), do: &t_card/1
  defp fun(:data_table), do: &t_data/1

  for {kind, slots} <- @slots, slot <- slots do
    test "#{kind} :#{slot}: only the assign changes" do
      check(fun(unquote(kind)), @base, [{unquote(slot), @changes[unquote(slot)]}])
    end

    test "#{kind} :#{slot}: the assign and the rows change together" do
      check(fun(unquote(kind)), @base, [{unquote(slot), @changes[unquote(slot)]}, rows: @rows2])
    end
  end

  # With `rows={@streams.rows}` (the stream is the same struct in both renders; only `@x` changes).
  defp t_stream(assigns) do
    ~H"""
    <.table id="t" rows={@streams.rows} details>
      <:col :let={{_id, r}} label="Name">{r.name} {@col}</:col>
      <:action :let={{_id, _r}}>{@action}</:action>
      <:detail :let={{_id, _r}} label="D">{@detail}</:detail>
      <:expand :let={%{row: {_id, _r}}}>{@expand}</:expand>
    </.table>
    """
  end

  for slot <- [:col, :action, :detail, :expand] do
    test "table with a stream, :#{slot}" do
      stream = Phoenix.LiveView.LiveStream.new(:rows, 0, @rows, [])
      base = %{@base | rows: nil} |> Map.put(:streams, %{rows: stream, __ref__: 0})

      check(&t_stream/1, base, [{unquote(slot), @changes[unquote(slot)]}])
    end
  end
end
