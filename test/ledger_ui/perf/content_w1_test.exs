defmodule LedgerUI.Perf.ContentW1Test do
  # #95: `settle/3` em tooltip e command_palette, e os itens de triagem de line_chart, status_toast,
  # pixel_card, bulk_bar, mask e modal. Cada fonte muda sozinha (`each_source/3`) e o diff aplicado
  # tem de dar o mesmo HTML de um render novo.
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI

  import LedgerUI.DiffCase

  Code.require_file("../../support/content_a_cases.exs", __DIR__)
  alias LedgerUI.ContentACases, as: C

  # -- tooltip ------------------------------------------------------------------------------

  def t_tip(assigns) do
    ~H"""
    <.tooltip
      id={@id}
      text={@text}
      color={@color}
      placement={@placement}
      delay={@delay}
      duration={@duration}
      follow_cursor={@follow_cursor}
      arrow={@arrow}
      interactive={@interactive}
      open={@open}
      on_open={@on_open}
      on_close={@on_close}
      target={@target}
      class={@class}
      tip_class={@tip_class}
      trigger={@trigger}
    >
      <button>{@body}</button>
      <:content :if={@content?}>conteudo</:content>
    </.tooltip>
    """
  end

  def t_tip_slot(assigns) do
    ~H"""
    <.tooltip id={@id} text={@text}>
      <:trigger :if={@slot?}><button>{@body}</button></:trigger>
      dica {@body}
    </.tooltip>
    """
  end

  defp tip_base do
    %{
      id: "tt",
      text: "dica",
      color: "neutral",
      placement: "top",
      delay: 0,
      duration: 300,
      follow_cursor: nil,
      arrow: true,
      interactive: nil,
      open: false,
      on_open: nil,
      on_close: nil,
      target: nil,
      class: nil,
      tip_class: nil,
      trigger: "hover",
      body: "AAA",
      content?: false
    }
  end

  describe "tooltip" do
    test "each source" do
      each_source(&t_tip/1, tip_base(),
        id: "tt2",
        text: "outra",
        color: "success",
        placement: "bottom",
        delay: 100,
        duration: 500,
        follow_cursor: "both",
        arrow: false,
        interactive: true,
        open: true,
        on_open: "abriu",
        on_close: "fechou",
        target: "#alvo",
        class: "w-full",
        tip_class: "font-bold",
        trigger: "click",
        body: "BBB",
        content?: true
      )

      each_source(&t_tip/1, %{tip_base() | content?: true}, content?: false)
      each_source(&t_tip_slot/1, %{id: "ts", text: "x", slot?: false, body: "A"}, slot?: true)

      each_source(&t_tip_slot/1, %{id: "ts", text: "x", slot?: true, body: "A"},
        body: "B",
        slot?: false
      )
    end

    test "o corpo e o texto do gatilho mudam: ate 500 B" do
      assert byte_size(check(&t_tip/1, tip_base(), body: "BBB")) <= 500

      assert byte_size(
               check(&t_tip_slot/1, %{id: "ts", text: "x", slot?: true, body: "A"}, body: "B")
             ) <= 500
    end
  end

  # -- command_palette ----------------------------------------------------------------------

  def t_palette(assigns) do
    ~H"""
    <.command_palette
      id={@id}
      open={@open}
      label={@label}
      placeholder={@placeholder}
      scopes={@scopes}
      scopes_label={@scopes_label}
      items={@items}
      empty={@empty}
      assistant={@assistant}
      assistant_mode={@assistant_mode}
      on_select={@on_select}
      on_assistant={@on_assistant}
      on_search={@on_search}
      debounce={@debounce}
      query={@query}
      on_open={@on_open}
      on_close={@on_close}
      target={@target}
      shortcut={@shortcut}
      variant={@variant}
      hints={@hints}
      highlight={@highlight}
      hint_navigate={@hint_navigate}
      hint_open={@hint_open}
      hint_new_tab={@hint_new_tab}
      hint_close={@hint_close}
      class={@class}
      list_style={@list_style}
      inline={@inline}
      bare={@bare}
      defer_items={@defer_items}
      locale={@locale}
    />
    """
  end

  defp items(n) do
    for i <- 1..n do
      base = %{
        group: if(i <= n / 2, do: "Ir para", else: "Acoes"),
        scope: if(rem(i, 2) == 0, do: "pages", else: "actions"),
        label: "Item #{i}",
        icon: "plus",
        value: "v#{i}",
        keys: ["G", "#{i}"]
      }

      if rem(i, 3) == 0, do: Map.put(base, :navigate, "/p/#{i}"), else: base
    end
  end

  defp palette_base(extra \\ %{}) do
    Map.merge(
      %{
        id: "pal",
        open: false,
        label: "Paleta",
        placeholder: "Buscar",
        scopes: [{"Tudo", "all"}, {"Paginas", "pages"}],
        scopes_label: "Escopos",
        items: items(10),
        empty: "Nada",
        assistant: %{label: "Perguntar: %{query}", sub: "IA"},
        assistant_mode: "no_match",
        on_select: "sel",
        on_assistant: "ass",
        on_search: nil,
        debounce: 200,
        query: "",
        on_open: nil,
        on_close: nil,
        target: nil,
        shortcut: "Mod+k",
        variant: "canvas",
        hints: true,
        highlight: "always",
        hint_navigate: "navegar",
        hint_open: "abrir",
        hint_new_tab: "aba",
        hint_close: "fechar",
        class: nil,
        list_style: nil,
        inline: false,
        bare: false,
        defer_items: false,
        locale: nil
      },
      extra
    )
  end

  @palette_alt [
    id: "pal2",
    open: true,
    label: "Outra",
    placeholder: "Procurar",
    scopes: [{"Tudo", "all"}],
    scopes_label: "Filtros",
    empty: "Vazio",
    assistant: %{label: "Outro: %{query}"},
    assistant_mode: "always",
    on_select: "sel2",
    on_assistant: "ass2",
    on_search: "busca",
    debounce: 300,
    query: "ab",
    on_open: "abriu",
    on_close: "fechou",
    target: "#t",
    shortcut: "Mod+j",
    variant: "classic",
    hints: false,
    highlight: "typed",
    hint_navigate: "nav",
    hint_open: "open",
    hint_new_tab: nil,
    hint_close: "esc",
    class: "extra",
    list_style: "max-height:100px",
    locale: "pt_BR"
  ]

  # `each_source/3` for the keys that change the HTML of this base (some do not: `open` in a static preview)
  defp each_effective(fun, base, changes) do
    changes =
      Enum.filter(changes, fn {k, v} -> html(fun, base) != html(fun, Map.put(base, k, v)) end)

    assert changes != []
    each_source(fun, base, changes)
  end

  describe "command_palette" do
    for {name, extra} <- [
          {"default", %{}},
          {"defer", %{defer_items: true}},
          {"inline", %{inline: true}},
          {"bare", %{bare: true}}
        ] do
      test "each source, #{name}" do
        each_effective(
          &t_palette/1,
          palette_base(unquote(Macro.escape(extra))),
          Keyword.delete(@palette_alt, :locale) ++ [items: items(4)]
        )
      end
    end

    test "locale sozinho (textos padrao)" do
      base =
        palette_base(%{
          label: nil,
          placeholder: nil,
          scopes_label: nil,
          empty: nil,
          hint_navigate: nil,
          hint_open: nil,
          hint_new_tab: nil,
          hint_close: nil
        })

      each_source(&t_palette/1, base, locale: "pt_BR")
    end

    test "placeholder muda: bem abaixo de 6 347 B" do
      size = byte_size(check(&t_palette/1, palette_base(), placeholder: "Outro"))
      IO.puts("MEASURE palette placeholder: #{size}")
      assert size < 200
      size = byte_size(check(&t_palette/1, palette_base(), query: "x"))
      IO.puts("MEASURE palette query: #{size}")
    end
  end

  # -- line_chart ---------------------------------------------------------------------------

  def t_line(assigns) do
    ~H"""
    <.line_chart id={@id} labels={@labels} series={@series} label={@label} head={@head} />
    """
  end

  describe "line_chart" do
    test "label muda: nao reenvia os dados nem a config" do
      base = %{
        id: "lc",
        labels: ["a", "b", "c"],
        series: [%{name: "s", values: [1, 3, 2]}],
        label: "Grafico",
        head: "$1"
      }

      size = byte_size(check(&t_line/1, base, label: "Outro"))
      IO.puts("MEASURE line_chart label: #{size}")
      assert size < 200
      each_source(&t_line/1, base, label: "x", head: "$2", id: "lc2", labels: ["x", "y", "z"])
    end
  end

  # -- status_toast -------------------------------------------------------------------------

  def t_status(assigns) do
    ~H"""
    <.status_toast state={@state} status={@status} percent={@percent} class={@class}>
      {@body}
      <:action :if={@slot?} on_click="x">{@body}</:action>
    </.status_toast>
    """
  end

  def t_status_title(assigns) do
    ~H"""
    <.status_toast state={@state} title={@body} />
    """
  end

  describe "status_toast" do
    test "corpo muda" do
      base = %{
        state: "run",
        status: nil,
        percent: nil,
        class: nil,
        act: nil,
        body: "A",
        slot?: false
      }

      size = byte_size(check(&t_status/1, base, body: "B"))
      IO.puts("MEASURE status_toast corpo: #{size}")
      assert size < 200

      each_source(&t_status/1, base,
        state: "ok",
        status: "err",
        percent: 40,
        class: "x",
        body: "B",
        slot?: true
      )

      for st <- ~w(queue ok err) do
        each_effective(&t_status/1, %{base | state: st}, percent: 10, status: "run", body: "Z")
      end

      each_source(&t_status_title/1, %{state: "run", body: "A"}, state: "ok", body: "B")
    end
  end

  # -- pixel_card ---------------------------------------------------------------------------

  def t_pixel(assigns) do
    ~H"""
    <.pixel_card
      id={@id}
      title={@title}
      description={@description}
      icon={@icon}
      color={@color}
      arrow={@arrow}
      lit={@lit}
      loop={@loop}
      class={@class}
      phx-click={@click}
    >
      {@body}
    </.pixel_card>
    """
  end

  describe "pixel_card" do
    test "title muda: nao reenvia a raiz" do
      base = %{
        id: "px1",
        title: "A",
        description: "d",
        icon: "plus",
        color: "red",
        arrow: true,
        lit: false,
        loop: false,
        class: nil,
        click: "pick",
        body: "corpo"
      }

      size = byte_size(check(&t_pixel/1, base, title: "B"))
      IO.puts("MEASURE pixel_card title: #{size}")
      assert size < 200

      each_source(&t_pixel/1, base,
        id: "px2",
        title: "B",
        description: "e",
        icon: "minus",
        color: "blue",
        arrow: false,
        lit: true,
        loop: true,
        class: "x",
        click: "other",
        body: "outro"
      )
    end
  end

  # -- bulk_bar -----------------------------------------------------------------------------

  describe "bulk_bar" do
    test "corpo do action muda: nao reenvia a classe do botao" do
      base = %{C.d_bulk_bar() | progress: nil, progress_max: nil}
      size = byte_size(check(&C.t_bulk_bar/1, base, action: "Apagar"))
      IO.puts("MEASURE bulk_bar action: #{size}")
      assert size < 300

      alt = Keyword.drop(C.d_bulk_bar_alt(), [:progress, :progress_max])
      each_source(&C.t_bulk_bar/1, base, [action: "Apagar"] ++ alt)
    end
  end

  # -- mask ---------------------------------------------------------------------------------

  def t_mask(assigns) do
    ~H"""
    <.mask shape={@shape} size={@size} label={@label} style={@style} class={@class}>{@body}</.mask>
    """
  end

  describe "mask" do
    test "corpo muda" do
      base = %{shape: "star", size: "64", label: nil, style: nil, class: nil, body: "AB"}
      size = byte_size(check(&t_mask/1, base, body: "CD"))
      IO.puts("MEASURE mask corpo: #{size}")
      assert size < 200

      each_source(&t_mask/1, base,
        shape: "heart",
        size: "32",
        label: "L",
        style: "background:red",
        class: "x",
        body: "ZZ"
      )
    end
  end

  # -- modal --------------------------------------------------------------------------------

  def t_modal(assigns) do
    ~H"""
    <.modal id="m" title={@title} description={@description} close_button={@close_button}>
      corpo
    </.modal>
    """
  end

  describe "modal" do
    test "title muda" do
      base = %{title: "A", description: nil, close_button: true}
      size = byte_size(check(&t_modal/1, base, title: "B"))
      IO.puts("MEASURE modal title: #{size}")

      # What stays is the class of the card and the aria of the dialog: a stateless component cannot know
      # whether the title was there before (it decides the corner close button), so they come with it.
      assert size < 450
      each_source(&t_modal/1, base, title: "B", description: "d", close_button: false)
      each_source(&t_modal/1, %{base | title: nil}, title: "B")
    end
  end

  # -- sem regex em render (#94) -----------------------------------------------------------

  describe "sem regex" do
    alias LedgerUI.Components.Toast

    # what the code did with `~r/<svg[^>]*>(.*)<\/svg>/s` and `~r/<(\w+)([^>]*?)\s*\/>/`
    defp svg_old(html) do
      case Regex.run(~r/<svg[^>]*>(.*)<\/svg>/s, html) do
        [_, inner] -> inner
        _ -> nil
      end
    end

    defp icon_html(name) do
      assigns = %{name: name}

      ~H|<.icon name={@name} size="md" />|
      |> Phoenix.HTML.Safe.to_iodata()
      |> IO.iodata_to_binary()
    end

    test "the shapes of every icon in a toast are what the regex gave" do
      for name <- LedgerUI.Components.Icon.names() do
        expected = svg_old(icon_html(name))
        got = Toast.normalize(icon: name)["icon_shapes"]
        assert got == if(expected in [nil, ""], do: nil, else: expected), "icon #{name}"
      end
    end

    test "the templates of the deferred palette are what the regexes gave" do
      names = Enum.take(Enum.sort(LedgerUI.Components.Icon.names()), 400)
      items = for n <- names, do: %{label: n, icon: n}
      base = palette_base(%{items: items, defer_items: true, assistant: nil})
      html = LedgerUI.DiffCase.html(&t_palette/1, base)

      for name <- names do
        old =
          case svg_old(icon_html(name)) do
            nil -> ""
            inner -> Regex.replace(~r/<(\w+)([^>]*?)\s*\/>/, inner, "<\\1\\2></\\1>")
          end

        [_, got] =
          Regex.run(~r/<template id="pal-ic-#{Regex.escape(name)}"[^>]*>(.*?)<\/template>/s, html)

        assert got == old, "icon #{name}"
      end
    end

    test "a path of this site with a control character is dropped from a toast action" do
      ok = Toast.normalize(action: %{label: "x", navigate: "/orders"})
      assert [%{"navigate" => "/orders"}] = ok["actions"]

      for bad <- ["/a\x00b", "/a\nb", "/a\x7fb", "/\x1f", "//host", "/a\\b", "https://x.y", "x"] do
        [action] = Toast.normalize(action: %{label: "x", patch: bad})["actions"]
        refute Map.has_key?(action, "patch"), inspect(bad)
      end
    end
  end
end
