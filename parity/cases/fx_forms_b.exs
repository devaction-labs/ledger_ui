defmodule Parity.Cases.FxFormsB do
  @moduledoc false
  # Lote fx-forms-b: o lado original é `fx_forms_b.py` (marcação lu-* do bundle).
  use Phoenix.Component
  use LedgerUI
  import Parity.Common

  @sw ~w(#141514 #1f9282 #6a4fd8 #2d6fb7 #11773e #b07a2c #b72f48 #e57487 #e8b04a #76cbb9)
  @times ~w(12:00 12:30 13:00 13:30 14:00 14:30 15:00 15:30 16:00 16:30 17:00)

  attr :c, :string, required: true
  slot :inner_block, required: true

  defp box(assigns) do
    ~H"""
    <div style="display:flex;flex-direction:column;gap:6px">
      <span class="font-mono text-xs text-muted">{@c}</span>{render_slot(@inner_block)}
    </div>
    """
  end

  def cases do
    assigns = %{
      sw: @sw,
      times: @times,
      events: [
        %{date: ~D[2023-09-04], title: "a"},
        %{date: ~D[2023-09-11], title: "b"},
        %{date: ~D[2023-09-19], title: "c"},
        %{date: ~D[2023-09-25], title: "d"}
      ]
    }

    %{
      "fx-calendar-mini-sizes" => ~H"""
      <.row>
        <.box c="sm">
          <.calendar locale="pt_BR" id="a1" variant="mini" size="sm" card={false} outside_days date={~D[2023-09-19]} today={~D[2023-09-19]} selected={~D[2023-09-19]} />
        </.box>
        <.box c="md · range">
          <.calendar locale="pt_BR" id="a2" variant="mini" card={false} outside_days date={~D[2023-09-19]} today={~D[2023-09-19]} range={{~D[2023-09-12], ~D[2023-09-18]}} />
        </.box>
        <.box c="lg">
          <.calendar locale="pt_BR" id="a3" variant="mini" size="lg" card={false} outside_days date={~D[2023-09-19]} today={~D[2023-09-19]} selected={~D[2023-09-11]} />
        </.box>
      </.row>
      """,
      "fx-calendar-mini-dots" => ~H"""
      <.row>
        <.box c="dot">
          <.calendar locale="pt_BR" id="b1" variant="mini" card={false} outside_days date={~D[2023-09-19]} today={~D[2023-09-19]} selected={~D[2023-09-19]} events={@events} />
        </.box>
        <.box c="tint · sm">
          <.calendar locale="pt_BR" id="b2" variant="mini" size="sm" marks="tint" card={false} outside_days date={~D[2023-09-19]} today={~D[2023-09-19]} events={@events} />
        </.box>
      </.row>
      """,
      "fx-calendar-mini-week" => ~H"""
      <.calendar locale="pt_BR" id="c1" variant="mini" view="week" card={false} date={~D[2023-09-19]} today={~D[2023-09-19]} />
      """,
      "fx-time-list-bare" => ~H"""
      <.row>
        <.time_picker_panel variant="bare" times={@times} value="14:30" />
        <.time_picker_panel variant="bare" height={120} times={@times} value="14:30" />
      </.row>
      """,
      "fx-color-picker-row" => ~H"""
      <.colm>
        <.color_picker id="d1" variant="row" swatch_size="sm" value="#1F9282" swatches={@sw} />
        <.color_picker id="d2" variant="row" value="#1F9282" swatches={@sw} />
        <.color_picker id="d3" variant="row" swatch_size="lg" value="#1F9282" swatches={@sw} />
      </.colm>
      """,
      "fx-signature-typed" => ~H"""
      <.signature_pad id="e1" name="e1" mode="type" modes={["type"]} variant="classic" text="Ana Nogueira" height={140} footer={false} name_input={false} class="w-[300px]" wrapper_class="w-[300px]" />
      """,
      "fx-text-editor-compact" => ~H"""
      <.rich_text_editor id="f1" name="f1" density="compact" value="<p><b>Entrega:</b> após as 14h, portão lateral, falar com Rita</p>" toolbar={[~w(bold italic link list-bullet)]} class="max-w-[520px]" />
      """,
      "fx-view-switcher-stretch" => ~H"""
      <.view_switcher id="g1" value="list" stretch class="w-[330px]" views={[%{label: "Lista", value: "list"}, %{label: "Quadro", value: "board"}, %{label: "Agenda", value: "calendar"}]} />
      """,
      "fx-pagination-sides" => ~H"""
      <.pagination page={2} total_pages={44} size="sm" arrows_at="sides" />
      """
    }
  end
end
