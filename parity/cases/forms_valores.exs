defmodule Parity.Cases.FormsValores do
  @moduledoc false
  # Formulários (data/hora, valores, editores, upload). The original side of each case
  # (`forms_valores.py`) is a snapshot of THIS file rendered with the pre-migration library
  # (lu-* classes) on the legacy stylesheet: see `forms_valores_snapshot.sh`.
  use Phoenix.Component
  use LedgerUI
  import Parity.Common

  @today ~D[2026-10-19]

  defp events do
    [
      %{date: ~D[2026-10-01], title: "Fechamento", color: "primary"},
      %{date: ~D[2026-10-08], title: "Renovação Orbit", color: "warning"},
      %{date: ~D[2026-10-15], title: "Board pack", color: "info"},
      %{date: ~D[2026-10-19], title: "Review IA", color: "secondary"},
      %{date: ~D[2026-10-19], title: "Pagamento", color: "success"},
      %{date: ~D[2026-10-27], title: "Churn review", color: "error"},
      %{date: ~D[2026-10-27], title: "Neutro"}
    ]
  end

  defp many do
    for t <- ~w(Um Dois Três Quatro Cinco), do: %{date: ~D[2026-10-12], title: t, color: "info"}
  end

  defp timed do
    [
      %{date: ~D[2026-10-19], title: "Daily", start: "09:00", end: "09:30"},
      %{
        date: ~D[2026-10-19],
        title: "Revisão do board pack",
        subtitle: "Orbit Cloud",
        start: "10:00",
        end: "11:30"
      },
      %{date: ~D[2026-10-20], title: "Almoço", start: "12:15"},
      %{date: ~D[2026-10-21], title: "Feriado", color: "success"},
      %{date: ~D[2026-10-22], title: "Retro", start: "16:00", end: "17:00"}
    ]
  end

  defp invoices do
    [
      %{date: ~D[2026-10-18], title: "Nordic Pay", subtitle: "INV-1043 · Pro", amount: "$3,400"},
      %{date: ~D[2026-10-19], title: "Orbit Cloud", subtitle: "INV-1051 · Pro", amount: 4200},
      %{date: ~D[2026-10-21], title: "Lumen GmbH + 2", subtitle: "3 faturas", amount: 5640.5},
      %{date: ~D[2026-10-22], title: "Acme", subtitle: "INV-1060", amount: 120, status: "overdue"}
    ]
  end

  def cases do
    img =
      "data:image/svg+xml;utf8," <>
        URI.encode(
          ~s(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10"><rect width="10" height="10" fill="#c26"/><circle cx="5" cy="5" r="3" fill="#fc3"/></svg>)
        )

    assigns = %{
      events: events(),
      many: many(),
      timed: timed(),
      invoices: invoices(),
      today: @today,
      img: img,
      sig:
        ~s(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 140"><path d="M30 92 C 50 40, 70 40, 66 88 C 64 110, 90 60, 110 66 C 130 72, 116 96, 140 88" fill="none" stroke="#000"/></svg>)
    }

    %{
      "calendar-month" => ~H"""
      <.calendar id="c1" date={~D[2026-10-01]} today={@today} locale="pt_BR" events={@events} />
      """,
      "calendar-month-handlers" => ~H"""
      <.calendar
        id="c2"
        date={~D[2026-10-01]}
        today={@today}
        locale="pt_BR"
        events={@events ++ @many}
        on_navigate="nav"
        on_view="view"
        on_select="sel"
        on_event="ev"
        selected={~D[2026-10-12]}
      />
      """,
      "calendar-month-more" => ~H"""
      <.calendar
        id="c3"
        date={~D[2026-10-01]}
        today={@today}
        events={@many ++ @events}
        max_events={2}
        week_start={1}
      />
      """,
      "calendar-month-noheader" => ~H"""
      <.calendar id="c4" date={~D[2026-10-01]} today={@today} events={@events} header={false} />
      """,
      "calendar-week" => ~H"""
      <.calendar
        id="c5"
        view="week"
        date={~D[2026-10-19]}
        today={@today}
        locale="pt_BR"
        events={@timed}
      />
      """,
      "calendar-week-handlers" => ~H"""
      <.calendar
        id="c6"
        view="week"
        date={~D[2026-10-19]}
        today={@today}
        events={@timed}
        show_weekends={false}
        day_start={9}
        day_end={14}
        on_navigate="nav"
        on_view="view"
        on_select="sel"
        on_event="ev"
      />
      """,
      "calendar-day" => ~H"""
      <.calendar id="c7" view="day" date={~D[2026-10-19]} today={@today} locale="pt_BR" events={@timed} />
      """,
      "calendar-mini-dot" => ~H"""
      <.calendar
        id="m1"
        variant="mini"
        date={~D[2026-10-01]}
        today={@today}
        events={@events}
        locale="pt_BR"
      />
      """,
      "calendar-mini-tint" => ~H"""
      <.calendar
        id="m2"
        variant="mini"
        date={~D[2026-10-01]}
        today={@today}
        events={@events}
        marks="tint"
        selected={~D[2026-10-12]}
      />
      """,
      "calendar-mini-range" => ~H"""
      <.calendar
        id="m3"
        variant="mini"
        date={~D[2026-10-01]}
        today={@today}
        range={[~D[2026-10-12], ~D[2026-10-18]]}
        outside_days={true}
        on_select="sel"
        on_navigate="nav"
        week_start={1}
      />
      """,
      "calendar-mini-multi" => ~H"""
      <.calendar
        id="m4"
        variant="mini"
        date={~D[2026-10-01]}
        today={@today}
        months_shown={2}
        events={@events}
        legend={[{"Fechamento", "primary"}, {"Atraso", "error"}]}
      />
      """,
      "calendar-mini-bare" => ~H"""
      <.calendar
        id="m5"
        variant="mini"
        date={~D[2026-10-01]}
        today={@today}
        card={false}
        events={@events}
        on_select="sel"
        interactive_marked_only={true}
      />
      """,
      "color-picker-full" => ~H"""
      <.color_picker id="cp1" name="c" value="#1F9282" />
      """,
      "color-picker-alpha" => ~H"""
      <.color_picker
        id="cp2"
        name="c"
        value="#E8B04A99"
        alpha
        label="Cor da etapa"
        help="Aceita transparência"
        locale="pt_BR"
      />
      """,
      "color-picker-popover" => ~H"""
      <.color_picker id="cp3" name="c" value="#6A4FD8" popover disabled swatch_size="md" />
      """,
      "color-picker-swatches" => ~H"""
      <.colm>
        <.color_picker id="cp4" name="a" variant="swatches" value="#4C3FE0" />
        <.color_picker id="cp5" name="b" variant="swatches" swatch_size="md" value="#18996E" hex_field />
        <.color_picker
          id="cp6"
          name="c"
          variant="swatches"
          swatch_size="lg"
          value="#EB3B2F"
          hex_field
          hex_label={nil}
          swatches={~w(#EB3B2F #F5A214 #18996E #2763E6)}
        />
        <.color_picker
          id="cp7"
          name="d"
          variant="swatches"
          swatch_size="sm"
          label="Cor"
          value="#606A78"
        />
      </.colm>
      """,
      "date-picker-basic" => ~H"""
      <.colm>
        <.date_picker
          id="d1"
          name="a"
          label="Vencimento"
          value={~D[2026-10-19]}
          locale="pt_BR"
          help="Dia do pagamento"
          today={@today}
        />
        <.date_picker id="d2" name="b" placeholder="Escolha" today={@today} />
        <.date_picker
          id="d3"
          name="c"
          label="Período"
          range
          value={{~D[2026-10-01], ~D[2026-10-15]}}
          today={@today}
        />
      </.colm>
      """,
      "date-picker-states" => ~H"""
      <.colm>
        <.date_picker id="d5" name="b" value={~D[2026-10-19]} disabled today={@today} />
        <.date_picker id="d6" name="c" value={~D[2026-10-19]} size="sm" today={@today} />
        <.date_picker
          id="d7"
          name="d"
          value={~D[2026-10-19]}
          size="lg"
          show_icon={false}
          today={@today}
        />
        <.date_picker
          id="d8"
          name="e"
          mode="multiple"
          value={[~D[2026-10-19], ~D[2026-10-21]]}
          today={@today}
        >
          <:trailing><.button size="sm" variant="ghost">OK</.button></:trailing>
        </.date_picker>
      </.colm>
      """,
      "date-picker-open" => ~H"""
      <div style="padding-bottom:340px">
        <.date_picker
          id="d9"
          name="a"
          label="Aberto"
          inline
          value={~D[2026-10-19]}
          today={@today}
          locale="pt_BR"
          min={~D[2026-10-05]}
          max={~D[2026-10-28]}
        />
      </div>
      """,
      "date-picker-open-range" => ~H"""
      <div style="padding-bottom:340px">
        <.date_picker
          id="d10"
          name="a"
          inline
          range
          value={{~D[2026-10-08], ~D[2026-10-21]}}
          today={@today}
          week_start={1}
          presets={[
            {"Este mês", "this_month"},
            {"Mês passado", "last_month"},
            {"Mesmo", {~D[2026-10-08], ~D[2026-10-21]}}
          ]}
        />
      </div>
      """,
      "date-picker-panel" => ~H"""
      <.row>
        <.date_picker_panel month={~D[2026-10-01]} today={@today} selected={~D[2026-10-12]} />
        <.date_picker_panel
          month={~D[2026-10-01]}
          today={@today}
          range={{~D[2026-10-12], ~D[2026-10-18]}}
          locale="pt_BR"
          presets={[
            {"Esta semana", {~D[2026-10-12], ~D[2026-10-18]}},
            {"Outra", {~D[2026-10-01], ~D[2026-10-02]}}
          ]}
        />
      </.row>
      """,
      "time-picker-basic" => ~H"""
      <.colm>
        <.time_picker id="t1" name="a" label="Horário" value="09:30" help="Fuso de Brasília" />
        <.time_picker id="t2" name="b" placeholder="Escolha..." time_24hr />
        <.time_picker id="t3" name="c" value="14:30" disabled locale="pt_BR" />
        <.time_picker id="t4" name="d" value="14:30">
          <:trailing><.button size="sm" variant="ghost">OK</.button></:trailing>
        </.time_picker>
      </.colm>
      """,
      "time-picker-list" => ~H"""
      <.row>
        <.time_picker
          id="t5"
          name="e"
          variant="list"
          label="Slots"
          value="14:30"
          min_time="14:00"
          max_time="16:00"
          minute_step={30}
        />
        <.time_picker_panel
          times={~w(08:30 09:00 09:30 10:00 10:30 11:00)}
          value="09:30"
          class="w-[140px]"
        />
      </.row>
      """,
      "datetime-picker-basic" => ~H"""
      <.colm>
        <.datetime_picker
          id="dt1"
          name="a"
          label="Agendar para"
          value="2026-10-21T14:30"
          locale="pt_BR"
          today={@today}
          help="Horário de Brasília"
          timezone="BRT (UTC−3)"
        />
        <.datetime_picker id="dt2" name="b" today={@today} variant="filled" size="sm" />
        <.datetime_picker
          id="dt3"
          name="c"
          mode="range"
          value={{"2026-10-08T09:00", "2026-10-21T17:00"}}
          today={@today}
          size="lg"
        />
        <.datetime_picker
          id="dt4"
          name="d"
          split
          date_label="Data"
          time_label="Hora"
          value="2026-10-21T14:30"
          today={@today}
        />
        <.datetime_picker id="dt5" name="e" value="2026-10-21T14:30" disabled today={@today} />
      </.colm>
      """,
      "datetime-picker-panel" => ~H"""
      <.row>
        <.datetime_picker_panel
          month={~D[2026-10-01]}
          today={@today}
          selected={~D[2026-10-21]}
          times={~w(12:00 13:00 14:00 15:00 16:00 17:00 18:00)}
          time="14:00"
          timezone="BRT (UTC−3)"
        />
        <.datetime_picker_panel
          month={~D[2026-10-01]}
          today={@today}
          locale="pt_BR"
          week_start={1}
          times={~w(09:00 09:30 10:00)}
        />
      </.row>
      """,
      "image-input-states" => ~H"""
      <.row>
        <.image_input shape="square" />
        <.image_input shape="circle" />
        <.image_input shape="wide" />
        <.image_input shape="rounded" size="lg" />
        <.image_input shape="circle" initials="AN" />
        <.image_input shape="circle" value={@img} />
        <.image_input shape="square" value={@img} hover />
        <.image_input shape="circle" hover />
        <.image_input shape="circle" progress={65} initials="AN" />
        <.image_input shape="circle" size="sm" />
        <.image_input shape="circle" size="xl" initials="OC" />
      </.row>
      """,
      "image-input-field" => ~H"""
      <.row>
        <.image_input name="avatar" value={@img} size="lg" />
        <.image_input name="logo" shape="rounded" />
        <.image_input name="doc" disabled shape="wide" value={@img} />
      </.row>
      """,
      "rating-readonly" => ~H"""
      <.colm>
        <.rating value={4} />
        <.rating value={3.5} show_value count={38} />
        <.rating value={2.2} variant="outline" size="lg" show_value />
        <.rating value={4.8} size="sm" variant="outline" count={12} />
        <.rating value={0} size="sm" />
        <.rating value={7} max={7} />
        <.rating value={3} loop />
      </.colm>
      """,
      "rating-interactive" => ~H"""
      <.colm>
        <.rating
          id="r1"
          name="grade"
          label="Como foi o atendimento?"
          value={4}
          help="Toque numa estrela"
        />
        <.rating id="r2" name="g2" value={2} variant="outline" size="lg" on_change="rate" />
        <.rating id="r3" name="g3" value={3} disabled show_value />
      </.colm>
      """,
      "rating-distribution" => ~H"""
      <.rating_distribution average={4.5} counts={[800, 310, 110, 40, 24]} />
      """,
      "range-colors" => ~H"""
      <.colm>
        <.range
          :for={c <- ~w(neutral primary secondary info success warning error)}
          name={"r-" <> c}
          value={40}
          color={c}
        />
        <.range
          :for={c <- ~w(neutral primary error)}
          name={"rc-" <> c}
          value={55}
          color={c}
          variant="classic"
        />
        <.range name="plain" value={70} />
        <.range name="fill" value={30} fill="#8b5cf6" />
      </.colm>
      """,
      "range-sizes" => ~H"""
      <.colm>
        <.range
          :for={{s, v} <- for(s <- ~w(sm md lg), v <- ~w(canvas classic), do: {s, v})}
          name={"s-#{s}-#{v}"}
          value={60}
          size={s}
          variant={v}
        />
        <.range name="nofill" value={60} filled={false} />
        <.range name="zero" value={0} />
        <.range name="full" value={100} />
      </.colm>
      """,
      "range-wrapped" => ~H"""
      <.colm>
        <.range
          name="d"
          label="Desconto"
          value={12}
          max={30}
          show_value
          value_format="%{value}%"
          help="Máximo de 30%"
        />
        <.range name="c" label="Comissão" value={35} marks={["0%", {25, "25%"}, 50]} />
        <.range name="q" label="Quantidade" value={40} steppers show_value value_format="%{value} un" />
        <.range
          start_name="from"
          end_name="to"
          label="Período"
          value={{25, 75}}
          show_value
          value_format="%{value}"
          marks={[0, 250, 500]}
          min={0}
          max={100}
        />
        <.range name="e" label="Desabilitado" value={10} disabled />
      </.colm>
      """,
      "range-vertical" => ~H"""
      <.row>
        <.range name="v1" value={70} orientation="vertical" />
        <.range name="v2" value={35} orientation="vertical" color="success" size="lg" />
        <.range
          name="v3"
          value={55}
          orientation="vertical"
          color="warning"
          variant="classic"
          height="84px"
        />
        <.range name="v4" value={55} orientation="vertical" size="sm" filled={false} />
      </.row>
      """,
      "signature-pad" => ~H"""
      <.colm>
        <.signature_pad id="sg1" name="s1" label="Assinatura" confirm="Confirmar" value={@sig} />
        <.signature_pad id="sg2" name="s2" mode="type" text="Ana Nogueira" locale="pt_BR" />
        <.signature_pad
          id="sg3"
          name="s3"
          modes={["draw"]}
          variant="classic"
          height={220}
          footer={false}
        />
        <.signature_pad id="sg4" name="s4" disabled confirm="OK" />
      </.colm>
      """,
      "due-calendar" => ~H"""
      <.due_calendar items={@invoices} today={@today} locale="pt_BR" currency="R$ " />
      """,
      "due-calendar-animated" => ~H"""
      <.due_calendar items={@invoices} today={@today} animated amount_width={100} />
      """
    }
  end
end
