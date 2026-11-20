defmodule LedgerUI.VitrineApiHosts.OnlyHost do
  use LedgerUI, only: [:badge, progress: 1]

  def imported do
    for {mod, funs} <- __ENV__.functions,
        String.starts_with?(inspect(mod), "LedgerUI.Components."),
        f <- funs,
        do: f
  end
end

defmodule LedgerUI.VitrineApiHosts.ExceptHost do
  use LedgerUI, except: [:button, :input, :table, :header, :icon, :modal]

  def imported do
    for {mod, funs} <- __ENV__.functions,
        String.starts_with?(inspect(mod), "LedgerUI.Components."),
        f <- funs,
        do: f
  end
end

defmodule LedgerUI.VitrineApiHosts.Core do
  def button(_assigns), do: "core button"
end

defmodule LedgerUI.VitrineApiHosts.WithCoreComponents do
  import LedgerUI.VitrineApiHosts.Core
  use LedgerUI, except: [:button]
  def call, do: button(%{})
end

defmodule LedgerUI.VitrineApiTest do
  @moduledoc """
  The names, attrs and slots the design vitrine writes (`design/vitrine/sec/*.json`) beyond the
  names of the READMEs: aliases of the same component, and the alternative forms of attrs and slots.
  """
  use ExUnit.Case, async: true
  use LedgerUI
  import Phoenix.Component
  import Phoenix.LiveViewTest

  defp html(fun, assigns \\ %{}), do: fun.(assigns) |> rendered_to_string()

  describe "aliases" do
    test "an alias declares the attrs and slots of its target" do
      pairs = [
        {LedgerUI.Components.Progress, :progress_bar, :progress},
        {LedgerUI.Components.NumberInput, :number_stepper, :number_input},
        {LedgerUI.Components.Range, :range_slider, :range},
        {LedgerUI.Components.Radio, :radio_choice, :radio_group},
        {LedgerUI.Components.Cover, :cover_card, :cover},
        {LedgerUI.Components.Drawer, :sheet, :drawer},
        {LedgerUI.Components.MenuList, :menu, :menu_list},
        {LedgerUI.Components.Typography, :typography, :text},
        {LedgerUI.Components.CommandPalette, :command_palette_dialog, :command_palette},
        {LedgerUI.Components.DatetimePicker, :date_time_picker, :datetime_picker},
        {LedgerUI.Components.EmptyState, :empty_state_card, :empty_state},
        {LedgerUI.Components.TextEditor, :rich_text_editor, :text_editor},
        {LedgerUI.Components.TextEditor, :comment_editor, :text_editor},
        {LedgerUI.Components.AppShell, :icon_rail, :main_sidebar},
        {LedgerUI.Components.AppShell, :shell_floating, :app_shell}
      ]

      for {mod, alias_name, target} <- pairs do
        comps = mod.__components__()
        assert function_exported?(mod, alias_name, 1), "#{alias_name}/1 missing"
        a = comps[alias_name]
        t = comps[target]
        assert Enum.map(a.attrs, & &1.name) == Enum.map(t.attrs, & &1.name), "#{alias_name} attrs"
        assert Enum.map(a.slots, & &1.name) == Enum.map(t.slots, & &1.name), "#{alias_name} slots"
        assert Enum.map(a.attrs, & &1.type) == Enum.map(t.attrs, & &1.type)
      end
    end

    test "the aliases are imported by use LedgerUI and listed for the skill" do
      names =
        for %{functions: fs} <- LedgerUI.Docs.components(), f <- fs, do: f.name

      for n <-
            ~w(progress_bar number_stepper range_slider radio radio_choice cover_card sheet menu container
               typography icon_rail sub_nav command_palette_dialog comment_editor rich_text_editor
               date_time_picker empty_state_card inline_empty tree shell_floating)a do
        assert n in names, "#{n} is not documented"
      end
    end

    test "progress_bar, number_stepper and range_slider are the real components" do
      assert html(fn assigns ->
               _ = assigns
               ~H|<.progress_bar value={64} color="primary" />|
             end) ==
               html(fn assigns ->
                 _ = assigns
                 ~H|<.progress value={64} color="primary" />|
               end)

      assert html(fn assigns ->
               _ = assigns
               ~H|<.number_stepper id="q" name="q" value="12" steppers />|
             end) =~
               "LedgerUI.NumberInput"

      assert html(fn assigns ->
               _ = assigns
               ~H|<.range_slider name="v" value={50} color="primary" />|
             end) =~
               ~s(data-part="range")
    end

    test "cover_card and menu" do
      assert html(fn assigns ->
               _ = assigns
               ~H|<.cover_card title="Summer" />|
             end) =~ "Summer"

      html =
        html(fn assigns ->
          _ = assigns
          ~H|<.menu variant="solid">
  <:item active>Orders</:item>
</.menu>|
        end)

      assert html =~ ~s(data-part="menu-list")
      assert html =~ "[&amp;_a[data-state=on]]:bg-accent"
    end

    test "sheet is a bottom drawer" do
      html =
        html(fn assigns ->
          _ = assigns
          ~H|<.sheet id="s"><:title>Filters</:title>body</.sheet>|
        end)

      assert html =~ ~s(data-lu-side="bottom")
      assert html =~ "Filters"
      assert html =~ "drawer-grab"
    end

    test "container takes a size" do
      assert html(fn assigns ->
               _ = assigns
               ~H|<.container size="prose">x</.container>|
             end) =~
               "max-width:68ch"

      assert html(fn assigns ->
               _ = assigns
               ~H|<.container size="full">x</.container>|
             end) =~
               "lu-container-fluid"

      html =
        html(fn assigns ->
          _ = assigns
          ~H|<.container class="py-10">x</.container>|
        end)

      assert html =~ "lu-container-fixed py-10"
      refute html =~ "max-width"
    end

    test "typography is text, comment_editor is a comment text_editor" do
      assert html(fn assigns ->
               _ = assigns
               ~H|<.typography as="span">Hi</.typography>|
             end) =~ "Hi"

      assert html(fn assigns ->
               _ = assigns
               ~H|<.comment_editor id="c" name="c" />|
             end) =~
               ~s(data-lu-variant="comment")
    end

    test "empty_state_card, inline_empty" do
      assert html(fn assigns ->
               _ = assigns
               ~H|<.empty_state_card title="No orders" />|
             end) =~ "No orders"

      html =
        html(fn assigns ->
          _ = assigns
          ~H|<.inline_empty icon="inbox" text="No comments" />|
        end)

      assert html =~ "No comments"
      assert html =~ "border-dashed"
    end

    test "shell_floating adds float to the shell" do
      html =
        html(fn assigns ->
          _ = assigns
          ~H|<.shell_floating id="sh" class="x">c</.shell_floating>|
        end)

      assert html =~ "float"
      assert html =~ "lu-app"
      assert html =~ " x"
    end

    test "radio is one radio or a group" do
      one =
        html(fn assigns ->
          _ = assigns
          ~H|<.radio name="plan" value="pro" label="Pro" checked />|
        end)

      assert one =~ ~s(type="radio")
      assert one =~ "checked"
      assert one =~ "Pro"

      group =
        html(fn assigns ->
          _ = assigns
          ~H|<.radio name="plan" value="m" options={[{"Monthly", "m"}, {"Yearly", "y"}]} />|
        end)

      assert group =~ "Monthly"
      assert group =~ "Yearly"

      assert html(fn assigns ->
               _ = assigns
               ~H|<.radio_choice name="p" options={~w(a b)} />|
             end) =~
               ~s(data-part="radio")
    end

    test "icon_rail items take an icon and a name" do
      html =
        html(fn assigns ->
          _ = assigns
          ~H|<.icon_rail current={:cases}>
  <:item icon="home" label="Home" navigate="/" />
  <:item icon="inbox" label="Cases" name={:cases} navigate="/cases" />
</.icon_rail>|
        end)

      assert html =~ "lu-rail"
      assert html =~ ~s(aria-label="Cases")
      assert html =~ "lu-rail-btn on"
    end

    test "sub_nav has groups that open and close" do
      html =
        html(fn assigns ->
          _ = assigns
          ~H|<.sub_nav title="Cases">
  <:group label="Status">links</:group><:group label="Team" open={false}>t</:group>
</.sub_nav>|
        end)

      assert html =~ "lu-subnav"
      assert html =~ "<h4>Cases</h4>"
      assert html =~ ~s(aria-expanded="true")
      assert html =~ ~s(aria-expanded="false")
      assert html =~ "subnav-cases-0"
      assert html =~ "hidden"
    end

    test "tree is written as data" do
      items = [
        %{
          id: "fiscal",
          label: "Fiscal",
          icon: "folder",
          count: 12,
          expanded: true,
          children: [%{id: "nfe", label: "NF-e", icon: "file"}]
        },
        %{id: "fin", label: "Financeiro"}
      ]

      html =
        html(fn assigns -> ~H|<.tree id="t" items={@items} selected="nfe" />| end, %{items: items})

      assert html =~ ~s(role="tree")
      assert html =~ "Fiscal"
      assert html =~ "NF-e"
      assert html =~ ~s(aria-selected="true")
      assert html =~ ~s(aria-expanded="true")
    end
  end

  describe "use LedgerUI only: and except:" do
    test "only takes the names given" do
      assert Enum.sort(LedgerUI.VitrineApiHosts.OnlyHost.imported()) == [badge: 1, progress: 1]
    end

    test "except leaves the names out, all the others stay" do
      names = LedgerUI.VitrineApiHosts.ExceptHost.imported()

      for n <- ~w(button input table header icon modal)a, do: refute({n, 1} in names, "#{n}")
      assert {:card, 1} in names
      assert {:progress_bar, 1} in names
      assert {:show_toast, 1} in names
    end

    test "a module with the same name as a LedgerUI one is not ambiguous after except" do
      assert LedgerUI.VitrineApiHosts.WithCoreComponents.call() == "core button"
    end

    test "a name that is not a component raises" do
      assert_raise ArgumentError, ~r/not components or helpers/, fn ->
        Code.eval_string("defmodule Bad1 do\n use LedgerUI, only: [:nope]\nend")
      end

      assert_raise ArgumentError, ~r/not components or helpers/, fn ->
        Code.eval_string("defmodule Bad2 do\n use LedgerUI, except: [badge: 3]\nend")
      end

      assert_raise ArgumentError, ~r/unknown options/, fn ->
        Code.eval_string("defmodule Bad3 do\n use LedgerUI, nope: []\nend")
      end
    end

    test "the names that collide with Phoenix's CoreComponents are named in the moduledoc" do
      {:docs_v1, _, _, _, %{"en" => doc}, _, _} = Code.fetch_docs(LedgerUI)
      assert doc =~ "except: [:button, :input"
    end
  end

  describe "attrs" do
    test "logo name and context" do
      html =
        html(fn assigns ->
          _ = assigns
          ~H|<.logo name="Ledgerly" context="Orbit Cloud · Finance" />|
        end)

      assert html =~ "Ledgerly"
      assert html =~ "Orbit Cloud · Finance"
      assert html =~ ~s(aria-label="Ledgerly")
      refute html =~ "Ledger UI"

      assert html(fn assigns ->
               _ = assigns
               ~H|<.logo />|
             end) =~ ~s(aria-label="Ledger UI")

      assert html(fn assigns ->
               _ = assigns
               ~H|<.logo name="Acme" mark="hexagon" />|
             end) =~ "Acme"
    end

    test "alert title, description and a bare accent" do
      html =
        html(fn assigns ->
          _ = assigns
          ~H|<.alert color="warning" title="Expires" description="Renew it" accent />|
        end)

      assert html =~ ~s(data-part="alert-title">Expires</b>)
      assert html =~ ">Renew it</span>"
      assert html =~ "shadow-[inset_0_3px_0_var(--c)]"
      refute html =~ ~s(title="Expires")

      assert html(fn assigns ->
               _ = assigns
               ~H|<.alert accent="left">x</.alert>|
             end) =~ "shadow-[inset_3px_0_0_var(--c)]"
    end

    test "status_toast status, title and action" do
      html =
        html(fn assigns ->
          _ = assigns
          ~H|<.status_toast status="run" title="Importing" action="Cancel" />|
        end)

      assert html =~ ~r/data-part="status-toast-msg"[^>]*>Importing<\/span>/
      assert html =~ "text-[#c9c9ce]"
      assert html =~ ">Cancel</button>"
      assert html =~ "lu-st-fill"

      done =
        html(fn assigns ->
          _ = assigns
          ~H|<.status_toast status="ok" title="Done" action="Open" />|
        end)

      assert done =~ "bg-[#22c55e]"
      assert done =~ "bg-[#26262b]"

      # the inner block and the slot still work
      html =
        html(fn assigns ->
          _ = assigns
          ~H|<.status_toast state="ok">
  Saved
  <:action on_click="undo">Undo</:action>
</.status_toast>|
        end)

      assert html =~ "Saved"
      assert html =~ "Undo"
    end

    test "divider label" do
      html =
        html(fn assigns ->
          _ = assigns
          ~H|<.divider label="or continue with" />|
        end)

      assert html =~ "or continue with"
      assert html =~ ~s(class="m-0 h-px min-w-0 flex-1 border-0 bg-line")

      assert html(fn assigns ->
               _ = assigns
               ~H|<.divider label="x" align="left" />|
             end) =~ ">x<"

      assert html(fn assigns ->
               _ = assigns
               ~H|<.divider />|
             end) =~ "<hr"
    end

    test "tabs: the active tab, names optional" do
      html =
        html(fn assigns ->
          _ = assigns
          ~H|<.tabs id="t">
  <:tab>All</:tab><:tab active>Open</:tab><:tab>Paid</:tab>
</.tabs>|
        end)

      assert html =~ ~r/aria-selected="true"[^>]*>\s*Open|Open[^<]*<\/[a-z]+>/s
      [selected] = Regex.scan(~r/aria-selected="true"/, html)
      assert selected
      assert length(Regex.scan(~r/aria-selected="false"/, html)) == 2
    end

    test "modal: :title, :actions and show" do
      html =
        html(fn assigns ->
          _ = assigns
          ~H|<.modal id="m" show>
  <:title>Export <b>report</b></:title>body<:actions>Go</:actions>
</.modal>|
        end)

      assert html =~ "Export <b>report</b>"
      assert html =~ ~s(id="m-title")
      assert html =~ ~s(aria-labelledby="m-title")
      assert html =~ "modal-footer"
      assert html =~ "Go"
      assert html =~ ~s(data-lu-open="true")

      # the string form is unchanged
      assert html(fn assigns ->
               _ = assigns
               ~H|<.modal id="m" title="Plain">x</.modal>|
             end) =~
               ~r/<h3 id="m-title" data-part="modal-title"[^>]*>\s*Plain\s*<\/h3>/

      refute html(fn assigns ->
               _ = assigns
               ~H|<.modal id="m" title="Plain">x</.modal>|
             end) =~
               ~s(title="Plain")
    end

    test "drawer: :title and floating" do
      html =
        html(fn assigns ->
          _ = assigns
          ~H|<.drawer id="d" placement="right"><:title>Filters</:title>body</.drawer>|
        end)

      assert html =~ "Filters"
      assert html =~ ~s(aria-labelledby="d-title")
      assert html =~ "drawer-header"

      floating =
        html(fn assigns ->
          _ = assigns
          ~H|<.drawer id="d" floating>body</.drawer>|
        end)

      assert floating =~ "drawer-body"

      assert html(fn assigns ->
               _ = assigns
               ~H|<.drawer id="d" title="Plain">x</.drawer>|
             end) =~
               ~r/<h3 id="d-title" data-part="drawer-title"[^>]*>Plain<\/h3>/
    end

    test "tooltip: a :trigger slot and content=" do
      html =
        html(fn assigns ->
          _ = assigns

          ~H|<.tooltip id="t" placement="bottom"><:trigger><button>Go</button></:trigger>Export</.tooltip>|
        end)

      assert html =~ "<button>Go</button>"
      assert html =~ "Export"

      let =
        html(fn assigns ->
          ~H|<.tooltip id="t"><:trigger :let={t}><button {t}>Go</button></:trigger>Export</.tooltip>|
        end)

      assert let =~ ~s(aria-describedby="t-tip")
      assert html =~ ~s(data-lu-trigger="hover")

      html =
        html(fn assigns ->
          _ = assigns

          ~H|<.tooltip id="t" content="Initial" color="dark" trigger="click"><button>x</button></.tooltip>|
        end)

      assert html =~ "Initial"
      assert html =~ ~s(data-lu-trigger="click")
      assert html =~ "bg-[#171717]"
      refute html =~ ~s(content="Initial")
    end

    test "dropdown, action_menu and filter_menu take a :trigger" do
      assert html(fn assigns ->
               _ = assigns
               ~H|<.dropdown id="d">
  <:trigger>Actions</:trigger><.dropdown_item>Edit</.dropdown_item>
</.dropdown>|
             end) =~ "Actions"

      assert html(fn assigns ->
               _ = assigns
               ~H|<.action_menu id="a" label="Row">
  <:trigger>Open</:trigger><.action_menu_item>Edit</.action_menu_item>
</.action_menu>|
             end) =~ ~r/aria-controls="a-menu"[^>]*>\s*Open/

      assert html(fn assigns ->
               _ = assigns
               ~H|<.filter_menu id="f">
  <:trigger>Filtrar</:trigger>
</.filter_menu>|
             end) =~ "Filtrar"
    end

    test "context_menu: placement and :trigger" do
      html =
        html(fn assigns ->
          _ = assigns
          ~H|<.context_menu id="c" placement="top-start">
  <:trigger>
    <p>Right click</p>
  </:trigger><:item>Rename</:item>
</.context_menu>|
        end)

      assert html =~ ~s(data-placement="top-start")
      assert html =~ "Right click"
      assert html =~ "Rename"

      refute html(fn assigns ->
               _ = assigns
               ~H|<.context_menu id="c">x</.context_menu>|
             end) =~
               "data-lu-placement"
    end

    test "accordion: :item slots" do
      html =
        html(fn assigns ->
          _ = assigns
          ~H|<.accordion id="faq">
  <:item title="One" open>first</:item><:item title="Two">second</:item>
</.accordion>|
        end)

      assert html =~ ~s(id="faq-0")
      assert html =~ ~s(id="faq-1")
      assert html =~ "One"
      assert html =~ "second"
      assert html =~ ~s(data-state="open")
    end

    test "segmented: :option slots" do
      html =
        html(fn assigns ->
          _ = assigns
          ~H|<.segmented id="r">
  <:option>Day</:option><:option selected>Week</:option><:option>Month</:option>
</.segmented>|
        end)

      assert html =~ ~s(data-lu-value="1")
      assert html =~ "Day"
      assert html =~ "Month"
      assert [_] = Regex.scan(~r/aria-pressed="true"/, html)

      html =
        html(fn assigns ->
          _ = assigns
          ~H|<.segmented id="r" value="m">
  <:option value="d">Day</:option><:option value="m" icon="calendar">Month</:option>
</.segmented>|
        end)

      assert html =~
               ~r/class="on"[^>]*aria-pressed="true"[^>]*data-lu-value="m"|data-lu-value="m"/
    end

    test "icon_button takes the color, variant and shape of button" do
      html =
        html(fn assigns ->
          _ = assigns
          ~H|<.icon_button
  icon="trash"
  label="Delete"
  color="error"
  variant="outline"
  size="xs"
  shape="square"
/>|
        end)

      assert html =~ "[--c:var(--lu-neg)]"
      assert html =~ "h-[26px] text-xs gap-1 w-[26px] px-0 rounded-[7px]"
      assert html =~ "text-(--c-ink) border-[color-mix(in_oklab,var(--c)_55%,transparent)]"
      assert html =~ ~s(aria-label="Delete")

      # the form without them is unchanged
      assert html(fn assigns ->
               _ = assigns
               ~H|<.icon_button icon="trash" label="Delete" />|
             end) =~
               "border-line-strong bg-panel text-ink shadow-xs"

      assert html(fn assigns ->
               _ = assigns
               ~H|<.icon_button icon="x" label="Close" variant="ghost" />|
             end) =~
               "bg-transparent shadow-none text-ink-2"
    end

    test "bar_chart data and a highlight by label" do
      html =
        html(fn assigns ->
          _ = assigns
          ~H|<.bar_chart data={[{"Sep", 40}, {"Oct", 92}, {"Nov", 60}]} highlight="Oct" />|
        end)

      # the highlighted bar is the accent one
      assert html =~ ~r/bg-accent-500"[^>]*style="height:92%/
      assert html =~ ">Sep</span>"
      assert html =~ "height:40%"

      maps = [%{label: "a", value: 50}, %{label: "b", value: 100}]

      assert html(fn assigns -> ~H|<.bar_chart data={@maps} />| end, %{maps: maps}) =~
               "bg-accent-500"
    end

    test "calendar month, color_picker swatches, date_picker range, time_picker step, timer seconds" do
      assert html(fn assigns ->
               _ = assigns
               ~H|<.calendar id="c" month={~D[2026-10-01]} today={~D[2026-10-05]} />|
             end) =~ "October"

      assert html(fn assigns ->
               _ = assigns

               ~H|<.color_picker id="cp" name="c" value="#ff0000" swatches={~w(#ff0000 #00ff00)} />|
             end) =~ "#00ff00"

      assert html(fn assigns ->
               _ = assigns
               ~H|<.date_picker id="dp" name="d" range />|
             end) =~
               "&quot;mode&quot;:&quot;range&quot;"

      times =
        html(fn assigns ->
          _ = assigns

          ~H|<.time_picker id="tp" name="t" variant="list" step={30} min_time="09:00" max_time="11:00" />|
        end)

      assert times =~ "09:30"
      refute times =~ "09:15"

      assert html(fn assigns ->
               _ = assigns
               ~H|<.timer id="t" direction="down" seconds={600} elapsed={0} />|
             end) =~ "10:00"
    end

    test "password_input strength" do
      html =
        html(fn assigns ->
          _ = assigns
          ~H|<.password_input id="p" name="p" label="Pass" strength="good" help="Almost" />|
        end)

      assert html =~ ~s(data-level="3")
      assert html =~ "Almost"

      refute html(fn assigns ->
               _ = assigns
               ~H|<.password_input id="p" name="p" />|
             end) =~ "password-meter"
    end

    test "scrollspy target" do
      html =
        html(fn assigns ->
          _ = assigns
          ~H|<.scrollspy id="s" target="#doc">
  <:item href="#a">A</:item>
</.scrollspy>|
        end)

      assert html =~ ~s(data-target="#doc")
    end

    test "theme_picker current" do
      html =
        html(fn assigns ->
          _ = assigns

          ~H|<.theme_picker id="tp" variant="grid" themes={~w(ledger crepusculo)} current="crepusculo" />|
        end)

      assert html =~ ~r/lu-themebox on[^>]*data-lu-theme="crepusculo"/
    end

    test "step_group steps and current" do
      html =
        html(fn assigns ->
          _ = assigns

          ~H|<.step_group id="g" current={2} steps={[%{title: "Data"}, %{title: "Fiscal"}, %{title: "Done"}]} />|
        end)

      assert html =~ "bg-pos text-white"
      assert html =~ "animate-[lu-spin_.9s_linear_infinite]"
      assert html =~ "shadow-[inset_0_0_0_1.5px_var(--lu-line-strong)]"
      assert html =~ "Fiscal"

      explicit =
        html(fn assigns ->
          _ = assigns
          ~H|<.step_group steps={[%{title: "A", status: :failed}]} />|
        end)

      assert explicit =~ "bg-neg text-white"
    end

    test "trace spans" do
      spans = [
        %{title: "GET /", start: 0, width: 80, duration: "120ms"},
        %{title: "query", depth: 1, start: 10, width: 30, color: "var(--c2)", duration: "30ms"}
      ]

      html = html(fn assigns -> ~H|<.trace spans={@spans} />| end, %{spans: spans})
      assert html =~ "GET /"
      assert html =~ "120ms"
      assert html =~ "query"
    end

    test "timeline items" do
      items = [
        %{title: "Created", time: "09:00", color: "success"},
        %{title: "Paid", description: "R$ 10", variant: "outline"}
      ]

      html = html(fn assigns -> ~H|<.timeline items={@items} />| end, %{items: items})
      assert html =~ "Created"
      assert html =~ "09:00"
      assert html =~ "R$ 10"
    end

    test "ai_tool_trace steps, conversation_list current" do
      steps = [%{title: "Search", ms: "120ms"}]
      html = html(fn assigns -> ~H|<.ai_tool_trace steps={@steps} />| end, %{steps: steps})
      assert html =~ "Usou 1 ferramenta"
      assert html =~ "Search"

      convs = [%{id: "a", title: "One"}, %{id: "b", title: "Two"}]

      html =
        html(
          fn assigns -> ~H|<.conversation_list conversations={@convs} current="b" />| end,
          %{convs: convs}
        )

      assert html =~ ~r/aria-current="true"[^>]*>.*Two/s
      refute html =~ ~r/aria-current="true"[^>]*>[^<]*<[^>]*>[^<]*<[^>]*>One/s
    end

    test "sidebar: <:item> and <:view> slots, workspace and an atom current" do
      html =
        html(fn assigns ->
          _ = assigns

          ~H|<.sidebar id="sb" workspace={%{name: "Signetum", context: "Matriz"}} current={:overview}>
  <:item icon="grid" name={:overview} navigate="/">Overview</:item>
  <:item icon="user" badge={23} tone="neg">Churn</:item>
  <:view icon="folder">Board packs</:view>
</.sidebar>|
        end)

      assert html =~ "Signetum"
      assert html =~ "Matriz"
      assert html =~ "Overview"
      assert html =~ "Churn"
      assert html =~ "Board packs"
      assert html =~ "Views"
      assert html =~ ~r/lu-nav-item on[^>]*>.*Overview/s
    end

    test "treeview: tree_item icon attr and the icon slot" do
      html =
        html(fn assigns ->
          _ = assigns
          ~H|<.treeview id="t"><.tree_item label="Fiscal" icon="folder" count="12" /></.treeview>|
        end)

      assert html =~ "Fiscal"
      assert html =~ "<svg"

      html =
        html(fn assigns ->
          _ = assigns
          ~H|<.treeview id="t">
  <.tree_item label="A">
    <:icon><i class="mine"></i></:icon>
  </.tree_item>
</.treeview>|
        end)

      assert html =~ ~s(class="mine")
    end

    test "description_list variant and title, form_section variant, pagination variant, navbar canvas" do
      html =
        html(fn assigns ->
          _ = assigns
          ~H|<.description_list variant="inline">
  <:item title="Plan">Pro</:item>
</.description_list>|
        end)

      assert html =~ "flex flex-row justify-between"
      assert html =~ "Plan"

      assert html(fn assigns ->
               _ = assigns
               ~H|<.form_section title="A" variant="aside">x</.form_section>|
             end) =~
               "grid-cols-[220px_1fr]"

      assert html(fn assigns ->
               _ = assigns
               ~H|<.pagination page={1} total_pages={3} variant="pill" />|
             end) =~
               "bg-accent text-accent-foreground"

      assert html(fn assigns ->
               _ = assigns
               ~H|<.navbar variant="canvas">x</.navbar>|
             end) =~
               ~s(class="lu-topbar")
    end

    test "illustration color is the tone" do
      assert html(fn assigns ->
               _ = assigns
               ~H|<.illustration color="success" />|
             end) =~ "[--c-soft:var(--lu-pos-soft)]"

      assert html(fn assigns ->
               _ = assigns
               ~H|<.illustration tone="error" color="success" />|
             end) =~
               "[--c-soft:var(--lu-neg-soft)]"
    end
  end
end
