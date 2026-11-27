defmodule LedgerUI.Perf.NavTest do
  # #85 (A9, A10): what the selects, the menus and the pickers derive in their body is taken back
  # out of `__changed__` (`LedgerUI.Helpers.settle/3`) when no source changed, and the lists of
  # options / items send only the rows that changed. Two kinds of test:
  #
  #   * sizes of the diff of the scenarios of the issue (select / autocomplete options, sidebar,
  #     date picker);
  #   * `each_source/3` for each `settle/3`: change ONLY one source and check that the page the
  #     client ends up with (first render + patch) is the one a fresh render gives. A source left
  #     out of a list makes it fail (the derived value would be stale).
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI
  import LedgerUI.DiffCase

  # -- select / autocomplete (A9) ----------------------------------------------------------------

  defp t_auto(assigns) do
    ~H"""
    <.autocomplete
      id="a1"
      name="a"
      value={@value}
      options={@options}
      label="Cliente"
      on_search="search"
    />
    """
  end

  defp t_sel(assigns) do
    ~H"""
    <.select id="s1" name="s" value={@value} options={@options} label="Rotulo" search="auto" />
    """
  end

  defp t_sel_native(assigns) do
    ~H"""
    <.select id="s1" name="s" value={@value} options={@options} native />
    """
  end

  defp opts(prefix, n), do: for(i <- 1..n, do: {"#{prefix} #{i}", "#{String.first(prefix)}#{i}"})

  describe "autocomplete and select: options and value" do
    test "the server answers a search of 20 options with less than 3 KB (was 3.3 KB)" do
      patch =
        patch(&t_auto/1, %{value: nil, options: opts("Produto", 20)}, options: opts("Outro", 20))

      assert patch =~ "Outro 20"
      assert byte_size(patch) < 3_000, "patch: #{byte_size(patch)} B"
    end

    test "a search answer of the select (20 options) is smaller than 2.5 KB" do
      patch =
        patch(&t_sel/1, %{value: nil, options: opts("Produto", 20)}, options: opts("Outro", 20))

      assert byte_size(patch) < 2_500, "patch: #{byte_size(patch)} B"
    end

    test "picking another value of 1000 options sends the two rows that changed (was 60 KB)" do
      base = %{value: "P1", options: opts("Produto", 1000)}
      patch = patch(&t_sel/1, base, value: "P2")
      assert byte_size(patch) < 1_500, "patch: #{byte_size(patch)} B"
      refute patch =~ "Produto 500"
      native = patch(&t_sel_native/1, base, value: "P2")
      assert byte_size(native) < 1_500, "native patch: #{byte_size(native)} B"
    end

    test "the value of the autocomplete: only the rows that changed" do
      base = %{value: "P1", options: opts("Produto", 500)}
      assert byte_size(patch(&t_auto/1, base, value: "P2")) < 1_500
    end

    test "the rows of the rich branch (icon, hint, disabled) and of the plain one stay right" do
      rich = [
        {"A", "a"},
        %{label: "B", value: "b", hint: "dica"},
        %{label: "C", value: "c", disabled: true}
      ]

      plain = [{"A", "a"}, {"B", "b"}]
      each_source(&t_auto/1, %{value: "a", options: plain}, value: "b", options: rich)
      each_source(&t_auto/1, %{value: "a", options: rich}, value: "b", options: plain)
      each_source(&t_sel/1, %{value: "a", options: plain}, value: "b", options: rich)
      each_source(&t_sel/1, %{value: "a", options: rich}, value: "b", options: plain)
      each_source(&t_sel_native/1, %{value: "a", options: rich}, value: "b", options: plain)
    end
  end

  # -- sidebar (A10) -----------------------------------------------------------------------------

  defp t_sb(assigns) do
    ~H"""
    <.sidebar
      id="sb"
      nav={@nav}
      current={@current}
      format={@format}
      collapsed={@collapsed}
      variant={@variant}
      class={@class}
      persist={@persist}
      shortcut={@shortcut}
      collapsed_width={@collapsed_width}
      match={@match}
      brand={@brand}
      version={@version}
      user={@user}
      plan={@plan}
      footer={@footer}
    />
    """
  end

  defp sb_nav(n) do
    half = div(n, 2)

    [
      %{
        group: "Geral",
        items:
          for(
            i <- 1..half,
            do: %{label: "Item #{i}", icon: "home", navigate: "/p/#{i}", count: i}
          )
      },
      %{
        group: "Mais",
        items:
          for(i <- (half + 1)..n, do: %{label: "Item #{i}", icon: "user", navigate: "/p/#{i}"})
      },
      %{
        group: "Rodape",
        footer: true,
        items: [%{label: "Config", icon: "settings", navigate: "/config"}]
      }
    ]
  end

  defp sb do
    %{
      nav: sb_nav(20),
      current: "/p/3",
      format: "sections",
      collapsed: false,
      variant: "floating",
      class: nil,
      persist: true,
      shortcut: "b",
      collapsed_width: 60,
      match: "exact",
      brand: %{name: "Ledger", logo: "L"},
      version: nil,
      user: %{name: "Ana", email: "a@b"},
      plan: %{name: "Pro"},
      footer: nil
    }
  end

  describe "sidebar" do
    test "a new current page sends the two items that change state, not the menu (was 3.1 KB)" do
      for fmt <- ["sections", "tree", "nested"] do
        patch = patch(&t_sb/1, %{sb() | format: fmt}, current: "/p/15")
        assert byte_size(patch) < 2_200, "#{fmt}: #{byte_size(patch)} B"
        assert patch =~ ~s(aria-current)
        refute patch =~ "Item 7"
        refute patch =~ "uppercase", "#{fmt}: the heading of a group went again"
        refute patch =~ "w-[260px]", "#{fmt}: the classes of the root went again"
      end
    end

    test "collapsing the menu does not send the menu nor the classes of the items" do
      patch = patch(&t_sb/1, sb(), collapsed: true)
      refute patch =~ "Item 7"
      refute patch =~ "group/exp"
      assert byte_size(patch) < 600, "#{byte_size(patch)} B"
    end

    test "(b) every source of the root and of the body, for each format" do
      # sidebar/1: fmt: format · classes: fmt, variant, class · persist_attr: persist ·
      # shortcut_attr: shortcut · style_attrs: collapsed_width, rest.
      # sb_body: entries: nav, format, current, match · brand_map: brand, workspace ·
      # version_map: version · foot?: entries, footer_mode, plan, user, version_map
      for fmt <- ["sections", "tree", "nested", "rail"] do
        each_source(
          &t_sb/1,
          %{sb() | format: fmt, version: "v1", footer: "user", current: "/p/3/x"},
          current: "/p/15",
          match: "prefix",
          nav: sb_nav(10),
          brand: %{name: "Outra", sub: "x"},
          user: %{name: "Bia"},
          footer: "none",
          variant: "inset",
          class: "w-1",
          persist: false,
          shortcut: "k",
          collapsed_width: 80,
          collapsed: true
        )
      end

      for fmt <- ["sections", "tree", "nested", "rail"] do
        each_source(&t_sb/1, %{sb() | format: fmt, footer: "version", version: "v1"},
          version: %{version: "v2", build: "7"},
          footer: "none"
        )
      end

      each_source(&t_sb/1, %{sb() | format: "sections", footer: "user"}, plan: %{name: "Free"})
      each_source(&t_sb/1, %{sb() | format: "tree"}, format: "nested")

      each_source(&t_sb/1, %{sb() | format: nil},
        class: "x",
        variant: "sidebar",
        current: "/p/12"
      )
    end

    test "the group of the active item opens: the heading and the items stay right" do
      each_source(
        &t_sb/1,
        %{
          sb()
          | format: "tree",
            nav: [
              %{
                group: "G",
                collapsible: true,
                items: [%{label: "A", navigate: "/a"}, %{label: "B", navigate: "/b"}]
              }
            ],
            current: "/a"
        },
        current: "/b"
      )
    end

    test "the items with children and the disabled ones" do
      nav = [
        %{
          label: "Pai",
          navigate: "/pai",
          children: [
            %{label: "Filho", navigate: "/pai/a"},
            %{label: "Neto", navigate: "/pai/b", color: "blue"}
          ],
          collapsible: true
        },
        %{label: "Off", navigate: "/off", disabled: "em breve"},
        %{label: "Cor", navigate: "/cor", color: "blue", icon: "tag"}
      ]

      for fmt <- ["sections", "tree", "nested"] do
        each_source(&t_sb/1, %{sb() | format: fmt, nav: nav, current: "/"},
          current: "/pai/a",
          nav: tl(nav)
        )
      end
    end
  end

  # -- navbar --------------------------------------------------------------------------------------

  defp t_navbar(assigns) do
    ~H"""
    <.navbar variant={@variant} size={@size} id={@id} class={@class}>
      {@body}
      <:center>{@center}</:center>
      <:end>{@tail}</:end>
    </.navbar>
    """
  end

  defp t_nb_brand(assigns),
    do: ~H"<.navbar_brand name={@name} logo={@logo} src={@src} class={@class} />"

  defp t_nb_ws(assigns), do: ~H"<.navbar_workspace name={@name} logo={@logo} />"

  defp t_nb_crumbs(assigns),
    do: ~H"<.navbar_crumbs items={@items} variant={@variant} class={@class} />"

  defp t_nb_links(assigns), do: ~H"<.navbar_links items={@items} current={@current} />"
  defp t_nb_tabs(assigns), do: ~H"<.navbar_tabs items={@items} current={@current} />"

  defp t_nb_search(assigns) do
    ~H"""
    <.navbar_search
      value={@value}
      width={@width}
      size={@size}
      demo={@demo}
      loop={@loop}
      phx-click={@click}
    />
    """
  end

  defp t_nb_cluster(assigns),
    do: ~H"<.navbar_cluster shape={@shape} size={@size} class={@class}>x</.navbar_cluster>"

  defp t_nb_bell(assigns), do: ~H"<.navbar_bell count={3} tone={@tone} navigate={@navigate} />"

  defp t_nb_icon(assigns),
    do: ~H|<.navbar_icon name="bell" label="n" size={@size} navigate={@navigate} />|

  defp t_nb_bell_dot(assigns),
    do: ~H|<.navbar_bell dot={@dot} tone={@tone} size={@size} navigate={@navigate} />|

  defp t_nb_lang(assigns), do: ~H"<.navbar_lang locales={@locales} current={@current} />"

  defp t_nb_avatars(assigns),
    do: ~H"<.navbar_avatars users={@users} max={@max} total={@total} />"

  defp t_nb_user(assigns),
    do: ~H|<.navbar_user id="u" user={@user} variant={@variant} size={@size} />|

  defp t_nb_menu_head(assigns), do: ~H"<.navbar_menu_head user={@user} />"

  defp t_nb_menu_item(assigns),
    do: ~H"<.navbar_menu_item danger={@danger} navigate={@navigate}>Sair</.navbar_menu_item>"

  describe "navbar" do
    test "(b) every source" do
      each_source(
        &t_navbar/1,
        %{
          variant: "default",
          size: "md",
          id: "nb",
          class: nil,
          body: "x",
          center: "c",
          tail: "e"
        },
        variant: "float",
        size: "sm",
        class: "k",
        tail: "f"
      )

      each_source(&t_nb_brand/1, %{name: "App", logo: nil, src: nil, class: nil},
        name: "Outro",
        logo: "Z",
        src: "/x.png"
      )

      each_source(&t_nb_ws/1, %{name: "Acme", logo: nil}, name: "Beta", logo: "Q")

      each_source(
        &t_nb_crumbs/1,
        %{items: [%{label: "A", navigate: "/a"}, %{label: "B"}], variant: "canvas", class: nil},
        items: [%{label: "A", navigate: "/a"}, %{label: "B"}, %{label: "C"}],
        variant: "plain",
        class: "k"
      )

      items = [%{label: "X", navigate: "/x"}, %{label: "Y", href: "/y"}]
      each_source(&t_nb_links/1, %{items: items, current: "/x"}, current: "/y", items: tl(items))
      each_source(&t_nb_tabs/1, %{items: items, current: "/x"}, current: "/y", items: tl(items))

      each_source(
        &t_nb_search/1,
        %{value: "q", width: nil, size: "md", demo: nil, loop: false, click: nil},
        width: "200px",
        size: "sm",
        click: "go"
      )

      each_source(
        &t_nb_search/1,
        %{value: "q", width: nil, size: "md", demo: "typing", loop: false, click: nil},
        value: "qqqq",
        demo: nil
      )

      each_source(
        &t_nb_search/1,
        %{value: "q", width: nil, size: "md", demo: nil, loop: false, click: nil},
        loop: true
      )

      each_source(&t_nb_cluster/1, %{shape: "rounded", size: "md", class: nil},
        shape: "pill",
        size: "sm",
        class: "k"
      )

      each_source(&t_nb_bell/1, %{tone: "neg", navigate: nil}, tone: "warn", navigate: "/n")

      each_source(&t_nb_icon/1, %{size: "md", navigate: nil}, size: "sm", navigate: "/n")

      each_source(&t_nb_bell_dot/1, %{dot: true, tone: "neg", size: "md", navigate: nil},
        dot: false,
        tone: "warn",
        size: "sm",
        navigate: "/n"
      )

      each_source(&t_nb_lang/1, %{locales: ["pt", "en"], current: "en"},
        current: "pt",
        locales: ["pt", "en", "es"]
      )

      users = [%{name: "A"}, %{name: "B"}, %{name: "C"}]

      each_source(&t_nb_avatars/1, %{users: users, max: 2, total: nil},
        max: 3,
        total: 9,
        users: tl(users)
      )

      each_source(&t_nb_user/1, %{user: %{name: "Ana"}, variant: "avatar", size: nil},
        user: %{name: "Zed"},
        variant: "named",
        size: 40
      )

      each_source(&t_nb_menu_head/1, %{user: %{name: "Ana"}}, user: %{name: "Zed"})

      each_source(&t_nb_menu_item/1, %{danger: false, navigate: nil},
        danger: true,
        navigate: "/x"
      )
    end

    test "a new left side does not send the classes of the bar" do
      base = %{
        variant: "default",
        size: "md",
        id: "nb",
        class: nil,
        body: "x",
        center: "c",
        tail: "e"
      }

      patch = patch(&t_navbar/1, base, body: "outro")
      refute patch =~ "h-16"
    end
  end

  # -- landing_nav, breadcrumb, page_trail, pagination ---------------------------------------------

  defp t_ln(assigns) do
    ~H"""
    <.landing_nav
      id={@id}
      variant={@variant}
      responsive={@responsive}
      theme={@theme}
      align={@align}
      spy={@spy}
      sticky={@sticky}
      autohide={@autohide}
      class={@class}
    >
      <:link navigate="/a">{@label}</:link>
      <:link href="/b">B</:link>
      <:actions>x</:actions>
    </.landing_nav>
    """
  end

  defp t_ln_brand(assigns),
    do: ~H|<.landing_nav id="ln" brand={@brand}><:link navigate="/a">A</:link></.landing_nav>|

  defp t_ln_login(assigns),
    do:
      ~H|<.landing_login navigate={@navigate} href={@href} patch={@patch}>Entrar</.landing_login>|

  defp t_ln_cta(assigns),
    do: ~H|<.landing_cta navigate={@navigate} size={@size}>Go</.landing_cta>|

  defp t_ln_product(assigns),
    do: ~H|<.landing_product title="P" href={@href} accent={@accent} tone={@tone} />|

  defp t_ln_feature(assigns),
    do: ~H|<.landing_feature icon="home" title="F" navigate={@navigate} />|

  defp t_ln_side(assigns), do: ~H|<.landing_mega_side title="S" href={@href} link_label="Ver" />|

  defp t_ln_announce(assigns),
    do:
      ~H|<.landing_announcement id="an" navigate={@navigate} link_label="Ver">Novo</.landing_announcement>|

  defp t_ln_mega(assigns) do
    ~H"""
    <.landing_mega variant="cards" columns={@columns}>
      <.landing_feature icon="home" title="F" navigate="/f" />
    </.landing_mega>
    """
  end

  describe "landing_nav" do
    test "(b) every source" do
      base = %{
        id: "ln",
        variant: "default",
        responsive: false,
        theme: "auto",
        align: "start",
        spy: false,
        sticky: false,
        autohide: false,
        class: nil,
        label: "A"
      }

      each_source(&t_ln/1, base,
        id: "ln2",
        variant: "hero",
        responsive: true,
        align: "center",
        spy: true,
        sticky: true,
        class: "k"
      )

      each_source(&t_ln/1, %{base | variant: "hero"}, theme: "dark", variant: "mobile")
      each_source(&t_ln/1, %{base | sticky: true}, autohide: true)

      each_source(&t_ln_brand/1, %{brand: %{name: "Br", logo: "Z"}},
        brand: %{name: "Outra", navigate: "/", logo: "Q"}
      )

      each_source(&t_ln_login/1, %{navigate: nil, href: "/l", patch: nil},
        navigate: "/m",
        href: "/h",
        patch: "/q"
      )

      each_source(&t_ln_cta/1, %{navigate: "/g", size: "md"}, navigate: "/h", size: "lg")

      each_source(&t_ln_product/1, %{href: "/p", accent: "blue", tone: "default"},
        href: "/q",
        accent: "green",
        tone: "dark"
      )

      each_source(&t_ln_feature/1, %{navigate: "/f"}, navigate: "/g")
      each_source(&t_ln_side/1, %{href: "/s"}, href: "/t")
      each_source(&t_ln_announce/1, %{navigate: "/n"}, navigate: "/o")
      each_source(&t_ln_mega/1, %{columns: 2}, columns: 3)
    end
  end

  defp t_crumb(assigns) do
    ~H"""
    <.breadcrumb id={@id} variant={@variant} class={@class} max_items={@max_items} loop={@loop}>
      <:item navigate="/">Home</:item>
      <:item navigate="/a">A</:item>
      <:item navigate="/b">B</:item>
      <:item>Fim</:item>
    </.breadcrumb>
    """
  end

  describe "breadcrumb" do
    test "(b) every source" do
      each_source(
        &t_crumb/1,
        %{id: "bc", variant: "bordered", class: nil, max_items: nil, loop: false},
        id: "bd",
        variant: "pill",
        class: "k",
        max_items: 2,
        loop: true
      )
    end
  end

  defp t_trail(assigns) do
    ~H"""
    <.page_trail
      id="pt"
      trail={@trail}
      variant={@variant}
      recent={@recent}
      max={@max}
      max_pinned={@max_pinned}
      demo={@demo}
      state_storage={@state_storage}
      locale="pt_BR"
    />
    """
  end

  defp trail_item(p), do: %{path: p, href: p, label: String.upcase(p), icon: "home"}

  describe "page_trail" do
    test "(b) every source" do
      base = %{
        trail: %{
          current: "/a",
          pinned: [trail_item("/p")],
          recent: [trail_item("/a"), trail_item("/b")]
        },
        variant: "default",
        recent: 8,
        max: 5,
        max_pinned: 3,
        demo: false,
        state_storage: nil
      }

      each_source(&t_trail/1, base,
        trail: %{
          current: "/b",
          pinned: [],
          recent: [trail_item("/a"), trail_item("/b"), trail_item("/c")],
          state: %{x: 1}
        },
        variant: "compact",
        recent: 1,
        max: 1,
        max_pinned: 1,
        demo: true,
        state_storage: "local"
      )
    end
  end

  defp t_pg(assigns) do
    ~H"""
    <.pagination
      page={@page}
      total_pages={@total_pages}
      total_entries={@total_entries}
      page_size={@page_size}
      page_sizes={@page_sizes}
      on_page_size={@on_page_size}
      summary={@summary}
      siblings={@siblings}
      boundaries={@boundaries}
      navigate={@navigate}
      on_change={@on_change}
      target={@target}
      variant={@variant}
      size={@size}
      class={@class}
      locale="pt_BR"
      page_label={@page_label}
      prev_label={@prev_label}
      next_label={@next_label}
      page_size_label={@page_size_label}
    />
    """
  end

  describe "pagination" do
    test "(b) every source" do
      base = %{
        page: 5,
        total_pages: 20,
        total_entries: nil,
        page_size: nil,
        page_sizes: [],
        on_page_size: nil,
        summary: nil,
        siblings: 1,
        boundaries: 1,
        navigate: &"/p/#{&1}",
        on_change: nil,
        target: nil,
        variant: nil,
        size: "md",
        class: nil,
        page_label: "Pagina %{page}",
        prev_label: "Ant",
        next_label: "Prox",
        page_size_label: "%{size} por pagina"
      }

      for shape <- ["canvas", "classic"] do
        # the classic bar has no sizes
        each_source(&t_pg/1, %{base | variant: shape},
          page: 6,
          total_pages: 30,
          siblings: 2,
          boundaries: 2,
          navigate: &"/q/#{&1}",
          class: "k",
          page_label: "P %{page}",
          prev_label: "Voltar",
          next_label: "Avancar"
        )
      end

      each_source(&t_pg/1, %{base | variant: "compact"},
        page: 6,
        total_pages: 30,
        navigate: &"/q/#{&1}",
        class: "k",
        prev_label: "Voltar",
        next_label: "Avancar"
      )

      each_source(&t_pg/1, %{base | variant: "canvas"}, size: "sm")
      each_source(&t_pg/1, %{base | variant: "compact"}, size: "sm")
      each_source(&t_pg/1, %{base | variant: "classic"}, variant: "compact")

      sized = %{
        base
        | total_pages: nil,
          total_entries: 95,
          page_size: 10,
          page_sizes: [10, 20],
          on_page_size: "ps",
          summary: "%{first} a %{last}"
      }

      each_source(&t_pg/1, sized,
        total_entries: 200,
        page_size: 20,
        page_sizes: [10, 20, 50],
        summary: "%{first}-%{last}",
        page_size_label: "%{size} linhas",
        on_page_size: "ps2",
        target: "#t"
      )

      each_source(&t_pg/1, %{base | on_change: "pg", navigate: nil},
        target: "#t",
        on_change: "go"
      )
    end
  end

  # -- dropdown, menu_list, context_menu, filter_menu, view_switcher -------------------------------

  defp t_dd(assigns) do
    ~H"""
    <.dropdown
      id={@id}
      demo={@demo}
      anchor_class={@anchor_class}
      open={@open}
      row_mark={@row_mark}
      offset={@offset}
      hover={@hover}
      keep_submenus={@keep_submenus}
      close_on_select={@close_on_select}
      on_open={@on_open}
      on_close={@on_close}
      target={@target}
      control={@control}
      placement={@placement}
      color={@color}
      shape={@shape}
      highlight={@highlight}
      class={@class}
      menu_style={@menu_style}
      part={@part}
      label="Abrir"
    >
      <.dropdown_item>x</.dropdown_item>
    </.dropdown>
    """
  end

  defp t_dd_kebab(assigns) do
    ~H"""
    <.dropdown id="dd" toggle_icon={@toggle_icon} toggle_class={@toggle_class}>
      <.dropdown_item>x</.dropdown_item>
    </.dropdown>
    """
  end

  defp t_dd_action(assigns) do
    ~H"""
    <.dropdown id="dd" color="primary" label="Acoes">
      <:action navigate={@navigate} type={@type} class={@aclass}>Ir</:action>
      <.dropdown_item>x</.dropdown_item>
    </.dropdown>
    """
  end

  defp t_dd_item(assigns) do
    ~H"""
    <.dropdown_item
      danger={@danger}
      color={@color}
      variant={@variant}
      two_line={@two_line}
      selected={@selected}
      class={@class}
      shortcut={@shortcut}
      kbd={@kbd}
      disabled={@disabled}
      auto_loading={@auto_loading}
      navigate={@navigate}
    >
      Um
    </.dropdown_item>
    """
  end

  defp t_dd_misc(assigns) do
    ~H"""
    <.dropdown_separator class={@class} />
    <.dropdown_label class={@class}>R</.dropdown_label>
    <.menu_panel width={@width} highlight={@highlight} class={@class}>x</.menu_panel>
    <.dropdown_checkbox
      name="c"
      value="1"
      id={@id}
      checked={@checked}
      class={@class}
      disabled={@disabled}
    >
      Ck
    </.dropdown_checkbox>
    <.dropdown_radio name="r" value="2" class={@class}>Rd</.dropdown_radio>
    <.dropdown_submenu
      id="sm"
      label="Sub"
      class={@class}
      trigger_class={@trigger_class}
      disabled={@disabled}
      placement={@placement}
    >
      <.dropdown_item>In</.dropdown_item>
    </.dropdown_submenu>
    <.action_button
      icon="plus"
      label="x"
      danger={@danger}
      variant={@variant}
      size={@size}
      class={@class}
      navigate={@navigate}
    />
    """
  end

  defp t_dd_footer(assigns) do
    ~H"""
    <.dropdown_footer
      on_clear={@on_clear}
      on_apply={@on_apply}
      apply_count={@apply_count}
      apply_color={@apply_color}
      target={@target}
      clear_label={@clear_label}
      apply_label={@apply_label}
      locale="pt_BR"
    />
    """
  end

  describe "dropdown" do
    test "(b) every source" do
      base = %{
        id: "dd",
        demo: nil,
        anchor_class: nil,
        open: false,
        row_mark: false,
        offset: 4,
        hover: false,
        keep_submenus: false,
        close_on_select: true,
        on_open: "o",
        on_close: "c",
        target: nil,
        control: false,
        placement: "bottom-start",
        color: "neutral",
        shape: "rounded",
        highlight: false,
        class: nil,
        menu_style: nil,
        part: "dropdown"
      }

      each_source(&t_dd/1, base,
        id: "dd2",
        demo: "click",
        anchor_class: "k",
        open: true,
        row_mark: true,
        offset: 8,
        hover: true,
        keep_submenus: true,
        close_on_select: false,
        on_open: "o2",
        on_close: "c2",
        target: "#t",
        control: true,
        placement: "top",
        color: "primary",
        shape: "pill",
        class: "w-1",
        highlight: true,
        menu_style: "width:1px",
        part: "x"
      )

      each_source(&t_dd/1, %{base | demo: "loop"}, placement: "bottom-end")

      each_source(&t_dd_kebab/1, %{toggle_icon: "dots-vertical", toggle_class: nil},
        toggle_icon: "dots-horizontal",
        toggle_class: "k"
      )

      each_source(&t_dd_action/1, %{navigate: "/a", type: nil, aclass: nil},
        navigate: "/b",
        aclass: "k"
      )

      each_source(&t_dd_action/1, %{navigate: nil, type: nil, aclass: nil},
        type: "submit",
        aclass: "k"
      )

      each_source(
        &t_dd_item/1,
        %{
          danger: false,
          color: nil,
          variant: nil,
          two_line: false,
          selected: false,
          class: nil,
          shortcut: nil,
          kbd: nil,
          disabled: false,
          auto_loading: false,
          navigate: nil
        },
        danger: true,
        color: "primary",
        variant: "media",
        two_line: true,
        selected: true,
        class: "k",
        shortcut: "Ctrl K",
        kbd: "K",
        disabled: true,
        navigate: "/x"
      )

      each_source(
        &t_dd_misc/1,
        %{
          class: nil,
          width: nil,
          highlight: false,
          id: nil,
          checked: false,
          disabled: false,
          trigger_class: nil,
          placement: "right",
          danger: false,
          variant: "outline",
          size: "md",
          navigate: nil
        },
        class: "k",
        width: "w-40",
        highlight: true,
        id: "ck",
        checked: true,
        disabled: true,
        trigger_class: "t",
        placement: "left",
        danger: true,
        variant: "solid",
        size: "sm",
        navigate: "/x"
      )

      each_source(
        &t_dd_footer/1,
        %{
          on_clear: "c",
          on_apply: "a",
          apply_count: nil,
          apply_color: "primary",
          target: nil,
          clear_label: nil,
          apply_label: nil
        },
        on_clear: "c2",
        on_apply: nil,
        apply_count: 3,
        apply_color: "success",
        target: "#t",
        clear_label: "Zerar",
        apply_label: "Confirmar"
      )
    end
  end

  defp t_ml(assigns) do
    ~H"""
    <.menu_list
      id="ml"
      variant={@variant}
      color={@color}
      class={@class}
      demo={@demo}
      on_select={@on_select}
      target={@target}
    >
      <:item value="a" active>A</:item>
      <:item navigate="/b" count={4}>B</:item>
      <:item value="c" class="k">C</:item>
    </.menu_list>
    """
  end

  defp t_ml_static(assigns) do
    ~H"""
    <.menu_list id="ml2" variant="static" class={@class} rows={[%{id: 1}]}>
      <:row :let={r}>row {r.id}</:row>
    </.menu_list>
    """
  end

  defp t_menu_item(assigns) do
    ~H"""
    <.menu_item
      value={@value}
      on_select={@on_select}
      target={@target}
      variant={@variant}
      color={@color}
      active={@active}
      class={@class}
      navigate={@navigate}
    >
      Item
    </.menu_item>
    """
  end

  defp t_menu_row(assigns) do
    ~H"""
    <.menu_row title="T" class={@class} navigate={@navigate}>x</.menu_row>
    """
  end

  defp t_context(assigns) do
    ~H"""
    <.context_menu id="cm" placement={@placement} class={@class}>
      <:item kbd="K">Um</:item>
      <:item tone="danger">Dois</:item>
      <div>alvo</div>
    </.context_menu>
    """
  end

  describe "menu_list and context_menu" do
    test "(b) every source" do
      each_source(
        &t_ml/1,
        %{
          variant: "link",
          color: "primary",
          class: nil,
          demo: false,
          on_select: "s",
          target: nil
        },
        variant: "pill",
        color: "neutral",
        class: "k",
        demo: true,
        on_select: "s2",
        target: "#t"
      )

      each_source(&t_ml_static/1, %{class: nil}, class: "k")

      each_source(
        &t_menu_item/1,
        %{
          value: "v",
          on_select: "x",
          target: nil,
          variant: "link",
          color: nil,
          active: false,
          class: nil,
          navigate: nil
        },
        value: "w",
        on_select: "y",
        target: "#t",
        variant: "pill",
        color: "neutral",
        active: true,
        class: "k",
        navigate: "/x"
      )

      each_source(&t_menu_row/1, %{class: nil, navigate: nil}, class: "k", navigate: "/r")

      each_source(&t_context/1, %{placement: "bottom-start", class: nil},
        placement: "top",
        class: "k"
      )
    end

    test "a new text of an item does not send the classes of the list" do
      base = %{
        variant: "link",
        color: "primary",
        class: nil,
        demo: false,
        on_select: "s",
        target: nil
      }

      assert is_binary(patch(&t_ml/1, base, color: "neutral"))
    end
  end

  defp t_fm(assigns) do
    ~H"""
    <.filter_menu
      id="fm"
      groups={@groups}
      placement={@placement}
      label={@label}
      empty_label={@empty_label}
      locale={@locale}
    />
    """
  end

  defp t_vs(assigns) do
    ~H"""
    <.view_switcher
      id="vs"
      views={@views}
      value={@value}
      current={@current}
      options={@options}
      saved={@saved}
      saved_value={@saved_value}
      saved_label={@saved_label}
      on_change={@on_change}
      on_add={@on_add}
      on_saved={@on_saved}
      target={@target}
      loop={@loop}
      stretch={@stretch}
      columns={@columns}
      class={@class}
    />
    """
  end

  describe "filter_menu and view_switcher" do
    test "(b) every source" do
      groups = [%{name: "s", label: "S", options: [{"A", "a"}], value: "a", type: :single}]

      each_source(
        &t_fm/1,
        %{groups: groups, placement: "bottom-start", label: nil, empty_label: nil, locale: "en"},
        groups: [%{name: "m", label: "M", options: [{"A", "a"}, {"B", "b"}], value: ["a"]}],
        placement: "bottom-end",
        label: "Filtros",
        locale: "pt_BR"
      )

      each_source(
        &t_fm/1,
        %{groups: [], placement: "bottom-start", label: nil, empty_label: nil, locale: "en"},
        empty_label: "nada",
        label: "Filtros"
      )

      views = [%{label: "L", value: "l", count: 2}, %{label: "G", value: "g", navigate: "/g"}]

      base = %{
        views: views,
        value: "l",
        current: nil,
        options: [%{label: "N", value: "n", icon: "plus"}],
        saved: [%{label: "S1", value: "s1"}],
        saved_value: "s1",
        saved_label: "Salvas",
        on_change: "ch",
        on_add: "ad",
        on_saved: "sv",
        target: nil,
        loop: false,
        stretch: false,
        columns: 2,
        class: nil
      }

      each_source(&t_vs/1, base,
        views: tl(views),
        value: "g",
        options: [%{label: "M", value: "m"}],
        saved: [%{label: "S2", value: "s2"}],
        saved_value: "s2",
        on_change: "ch2",
        on_add: "ad2",
        on_saved: "sv2",
        target: "#t",
        loop: true,
        stretch: true,
        columns: 1,
        class: "k"
      )

      each_source(&t_vs/1, %{base | saved_value: nil}, saved_label: "Outras")
      each_source(&t_vs/1, %{base | value: nil, current: "l"}, current: "g")

      each_source(&t_vs/1, %{base | options: [], saved: []},
        options: [%{label: "N", value: "n"}],
        saved: [%{label: "S", value: "s"}]
      )
    end
  end

  # -- steps, treeview, scrollspy, tabs ------------------------------------------------------------

  defp t_steps(assigns) do
    ~H"""
    <.steps orientation={@orientation} size={@size} color={@color} class={@class}>
      <:step label={@label} state="done" />
      <:step label="B" current />
    </.steps>
    """
  end

  defp t_stepper(assigns) do
    ~H"""
    <.stepper
      current={@current}
      error={@error}
      variant={@variant}
      orientation={@orientation}
      size={@size}
      loop={@loop}
      color={@color}
      class={@class}
    >
      <:step :for={st <- @step} label={st.label} sub={st[:sub]} />
    </.stepper>
    """
  end

  describe "steps" do
    test "(b) every source" do
      each_source(
        &t_steps/1,
        %{orientation: "horizontal", size: "md", color: "neutral", class: nil, label: "A"},
        orientation: "vertical",
        size: "sm",
        color: "success",
        class: "k"
      )

      step = [%{label: "A"}, %{label: "B", sub: "s"}, %{label: "C"}]

      for variant <- ["canvas", "classic"] do
        base = %{
          step: step,
          current: 1,
          error: false,
          variant: variant,
          orientation: "horizontal",
          size: nil,
          loop: false,
          color: nil,
          class: nil
        }

        each_source(&t_stepper/1, base, step: tl(step), current: 2, error: true, class: "k")
      end

      canvas = %{
        step: step,
        current: 1,
        error: false,
        variant: "canvas",
        orientation: "horizontal",
        size: nil,
        loop: false,
        color: nil,
        class: nil
      }

      each_source(&t_stepper/1, canvas,
        orientation: "vertical",
        size: "sm",
        loop: true,
        color: "success"
      )
    end
  end

  defp t_tree_item(assigns) do
    ~H"""
    <.tree_item
      id={@id}
      label="A"
      expanded={@expanded}
      selected={@selected}
      branch={@branch}
      checked={@checked}
      depth={@depth}
      class={@class}
      icon={@icon}
    />
    """
  end

  defp t_treeview(assigns) do
    ~H"""
    <.treeview
      id="tv"
      expanded={@expanded}
      on_toggle={@on_toggle}
      on_select={@on_select}
      on_check={@on_check}
      target={@target}
      chevrons={@chevrons}
      class={@class}
    >
      <.tree_item id="a" label="A" />
    </.treeview>
    """
  end

  defp t_treeview_rows(assigns) do
    ~H"""
    <.treeview id="tv" rows={@rows} row_id={@row_id}>
      <:row :let={{id, r}}><.tree_item id={id} label={r.n} /></:row>
    </.treeview>
    """
  end

  defp t_tree_item_body(assigns) do
    ~H"""
    <.tree_item id="a" label="A" selected={@selected}>
      <.tree_item id="a1" label={@child} />
    </.tree_item>
    """
  end

  defp t_scrollspy(assigns) do
    ~H"""
    <.scrollspy id="ss" offset={@offset} demo={@demo} class={@class}>
      <:item href="#a" active>A</:item>
    </.scrollspy>
    """
  end

  describe "treeview and scrollspy" do
    test "(b) every source" do
      each_source(
        &t_tree_item/1,
        %{
          id: "a",
          expanded: false,
          selected: false,
          branch: false,
          checked: nil,
          depth: 0,
          class: nil,
          icon: "folder"
        },
        id: "b",
        expanded: true,
        selected: true,
        branch: true,
        checked: true,
        depth: 2,
        class: "k",
        icon: "file"
      )

      each_source(
        &t_tree_item/1,
        %{
          id: "a",
          expanded: false,
          selected: false,
          branch: false,
          checked: true,
          depth: 0,
          class: nil,
          icon: "folder"
        },
        checked: "mixed"
      )

      each_source(
        &t_treeview/1,
        %{
          expanded: [],
          on_toggle: nil,
          on_select: nil,
          on_check: nil,
          target: nil,
          chevrons: true,
          class: nil
        },
        expanded: ["a"],
        on_toggle: "t",
        on_select: "s",
        on_check: "c",
        target: "#x",
        chevrons: false,
        class: "k"
      )

      row_id = &"r#{&1.id}"

      each_source(&t_treeview_rows/1, %{rows: [%{id: 1, n: "x"}], row_id: row_id},
        rows: [%{id: 1, n: "x"}, %{id: 2, n: "y"}],
        row_id: &"q#{&1.id}"
      )

      each_source(&t_tree_item_body/1, %{selected: false, child: "A1"},
        selected: true,
        child: "A2"
      )

      each_source(&t_scrollspy/1, %{offset: 120, demo: false, class: nil},
        offset: 80,
        demo: true,
        class: "k"
      )
    end

    test "a new label of an item does not send the classes of the row" do
      patch = patch(&t_tree_item_body/1, %{selected: false, child: "A1"}, child: "Outro")
      assert patch =~ "Outro"
      refute patch =~ "rounded-[8px]"
    end
  end

  defp t_tabs(assigns) do
    ~H"""
    <.tabs
      id="t"
      selected={@selected}
      variant={@variant}
      color={@color}
      size={@size}
      shape={@shape}
      orientation={@orientation}
      loop={@loop}
      loop_widths={@loop_widths}
      soon_label={@soon_label}
      on_change={@on_change}
      target={@target}
      list_class={@list_class}
      panels_class={@panels_class}
      class={@class}
    >
      <:tab name="a" count={3}>{@text}</:tab>
      <:tab name="b" navigate="/b">B</:tab>
      <:tab name="c" soon>C</:tab>
      <:panel name="a">PA</:panel>
    </.tabs>
    """
  end

  describe "tabs" do
    test "(b) every source" do
      base = %{
        selected: "a",
        variant: "line",
        color: nil,
        size: "md",
        shape: "rounded",
        orientation: "horizontal",
        loop: false,
        loop_widths: [10, 20, 30],
        soon_label: "Em breve",
        on_change: nil,
        target: nil,
        list_class: nil,
        panels_class: nil,
        class: nil,
        text: "A"
      }

      each_source(&t_tabs/1, base,
        selected: "b",
        variant: "pill",
        size: "sm",
        orientation: "vertical",
        loop: true,
        soon_label: "Logo",
        on_change: "chg",
        target: "#t",
        list_class: "l",
        panels_class: "p",
        class: "k"
      )

      each_source(&t_tabs/1, %{base | variant: "pill"}, color: "neutral", shape: "pill")
      each_source(&t_tabs/1, %{base | loop: true}, loop_widths: [30, 20, 10])
      each_source(&t_tabs/1, %{base | variant: "classic"}, variant: "line")
    end
  end

  # -- notification_center, theme, palette, pill_select, time_picker ---------------------------------

  defp t_nc(assigns) do
    ~H"""
    <.notification_center
      id="nc"
      items={@items}
      variant={@variant}
      inline={@inline}
      unread={@unread}
      placement={@placement}
      arrow={@arrow}
      open={@open}
      on_read={@on_read}
      on_read_all={@on_read_all}
      on_change={@on_change}
      target={@target}
      size={@size}
      empty_tone={@empty_tone}
      empty_icon={@empty_icon}
      count_tone={@count_tone}
      all_href={@all_href}
      preferences_href={@preferences_href}
      tabs={@tabs}
    />
    """
  end

  describe "notification_center" do
    test "(b) every source" do
      items = [
        %{id: 1, title: "T", read: false, navigate: "/n"},
        %{id: 2, title: "U", read: true, href: "/h"},
        %{id: 3, title: "V", patch: "/p"},
        %{id: 4, title: "W"}
      ]

      base = %{
        items: items,
        variant: "canvas",
        inline: false,
        unread: nil,
        placement: "bottom-end",
        arrow: false,
        open: false,
        on_read: nil,
        on_read_all: nil,
        on_change: nil,
        target: nil,
        size: "md",
        empty_tone: "neutral",
        empty_icon: nil,
        count_tone: nil,
        all_href: nil,
        preferences_href: nil,
        tabs: [%{id: "all", label: "Todas"}, %{id: "unread", label: "Nao lidas"}]
      }

      for {variant, inline} <- [
            {"canvas", false},
            {"classic", false},
            {"canvas", true},
            {"classic", true}
          ] do
        each_source(&t_nc/1, %{base | variant: variant, inline: inline}, items: tl(items))
      end

      each_source(&t_nc/1, base, unread: 9)
      each_source(&t_nc/1, %{base | variant: "classic"}, unread: 9)

      each_source(&t_nc/1, %{base | variant: "classic", inline: true},
        all_href: "/all",
        preferences_href: "/pr"
      )

      each_source(&t_nc/1, base,
        placement: "top",
        arrow: true,
        open: true,
        on_read: "r",
        on_read_all: "ra",
        on_change: "ch",
        target: "#t",
        size: "sm",
        variant: "classic"
      )

      each_source(&t_nc/1, %{base | variant: "classic", inline: true},
        count_tone: "neg",
        tabs: [%{id: "all", label: "Tudo"}]
      )

      each_source(&t_nc/1, %{base | items: [], inline: true},
        empty_tone: "success",
        empty_icon: "bell"
      )

      each_source(&t_nc/1, %{base | items: [], variant: "classic", inline: true},
        empty_icon: "bell",
        items: items
      )
    end
  end

  defp t_tpicker(assigns) do
    ~H"""
    <.theme_picker
      id="tp"
      variant={@variant}
      themes={@themes}
      default={@default}
      current={@current}
      on_change={@on_change}
      placement={@placement}
      class={@class}
    />
    """
  end

  defp t_tswitch(assigns) do
    ~H"""
    <.theme_switch
      id="ts"
      variant={@variant}
      value={@value}
      system={@system}
      loop={@loop}
      size={@size}
      class={@class}
    />
    """
  end

  describe "theme_picker and theme_switch" do
    test "(b) every source" do
      for variant <- ["menu", "grid"] do
        base = %{
          variant: variant,
          themes: ~w(blue green),
          default: "blue",
          current: nil,
          on_change: nil,
          placement: "bottom-start",
          class: nil
        }

        each_source(&t_tpicker/1, base,
          themes: ~w(blue green red),
          default: "green",
          on_change: "ch",
          class: "k"
        )

        each_source(&t_tpicker/1, %{base | default: nil, current: "blue"}, current: "green")
      end

      each_source(
        &t_tpicker/1,
        %{
          variant: "menu",
          themes: ~w(blue),
          default: "blue",
          current: nil,
          on_change: nil,
          placement: "bottom-start",
          class: nil
        },
        placement: "bottom-end"
      )

      for variant <- ["switch", "cards", "segmented", "icons"] do
        base = %{
          variant: variant,
          value: "light",
          system: true,
          loop: false,
          size: "md",
          class: nil
        }

        each_source(&t_tswitch/1, base, value: "dark", class: "k")
        if variant in ["switch", "segmented"], do: each_source(&t_tswitch/1, base, loop: true)
        if variant != "switch", do: each_source(&t_tswitch/1, base, system: false)
      end

      each_source(
        &t_tswitch/1,
        %{
          variant: "segmented",
          value: "light",
          system: true,
          loop: false,
          size: "md",
          class: nil
        },
        size: "sm"
      )

      each_source(
        &t_tswitch/1,
        %{variant: "switch", value: "light", system: true, loop: false, size: "md", class: nil},
        size: "sm"
      )
    end
  end

  defp t_palette(assigns),
    do:
      ~H|<.palette variant={@variant} scale={@scale} steps={@steps} cols={@cols} colors={@colors} />|

  defp t_pill(assigns) do
    ~H"""
    <.pill_select
      id="ps"
      name={@name}
      options={@options}
      value={@value}
      multiple={@multiple}
      shape={@shape}
      class={@class}
    />
    """
  end

  describe "palette and pill_select" do
    test "(b) every source" do
      base = %{variant: "ramp", scale: "gray", steps: ~w(50 500), cols: 3, colors: []}
      each_source(&t_palette/1, base, scale: "accent", steps: ~w(50))
      each_source(&t_palette/1, %{base | variant: "chips"}, scale: "accent", steps: ~w(50))

      each_source(
        &t_palette/1,
        %{base | variant: "swatches", colors: [%{name: "a", color: "#fff"}]},
        cols: 4
      )

      base = %{
        name: "p",
        options: [{"A", "a"}, {"B", "b"}],
        value: "a",
        multiple: false,
        shape: "rounded",
        class: nil
      }

      each_source(&t_pill/1, base,
        name: "q",
        options: [{"A", "a"}, {"B", "b"}, {"C", "c"}],
        value: "b",
        multiple: true,
        shape: "pill",
        class: "k"
      )

      each_source(&t_pill/1, %{base | multiple: true, value: ["a"]}, name: "q", value: ["a", "b"])
    end
  end

  defp t_time(assigns) do
    ~H"""
    <.time_picker
      id={@id}
      name={@name}
      value={@value}
      variant={@variant}
      time_24hr={@time_24hr}
      min_time={@min_time}
      max_time={@max_time}
      step={@step}
      minute_step={@minute_step}
      default_hour={@default_hour}
      display_format={@display_format}
      labels={@labels}
      on_change={@on_change}
      target={@target}
      errors={@errors}
      locale="en"
    />
    """
  end

  defp t_time_panel(assigns),
    do:
      ~H|<.time_picker_panel variant={@variant} times={["09:00", "09:30"]} value={@value} height={100} />|

  describe "time_picker" do
    test "(b) every source" do
      base = %{
        id: "tm",
        name: "tm",
        value: "09:30",
        variant: "list",
        time_24hr: false,
        min_time: nil,
        max_time: nil,
        step: nil,
        minute_step: 30,
        default_hour: nil,
        display_format: nil,
        labels: %{},
        on_change: nil,
        target: nil,
        errors: []
      }

      each_source(&t_time/1, base,
        id: "tm2",
        name: "outro",
        value: "10:00",
        time_24hr: true,
        min_time: "08:00",
        max_time: "20:00",
        step: 15,
        minute_step: 60,
        errors: ["x"]
      )

      each_source(&t_time/1, %{base | variant: "input"},
        default_hour: 9,
        display_format: "H:i",
        labels: %{picker_time_dialog: "Hora"},
        on_change: "ch",
        target: "#t"
      )

      for variant <- ["panel", "bare"] do
        each_source(&t_time_panel/1, %{variant: variant, value: "09:00"}, value: "09:30")
      end
    end
  end

  # -- date_picker and datetime_picker (the locale / today derived values) -----------------------------

  defp t_date(assigns) do
    ~H"""
    <.date_picker
      id="dp"
      name="dp"
      label={@label}
      value={@value}
      mode={@mode}
      range={@range}
      errors={@errors}
      disabled={@disabled}
      placeholder={@placeholder}
      display_format={@display_format}
      range_separator={@range_separator}
      months={@months}
      weekdays={@weekdays}
      week_start={@week_start}
      min={@min}
      max={@max}
      disabled_dates={@disabled_dates}
      disabled_weekdays={@disabled_weekdays}
      presets={@presets}
      labels={@labels}
      inline={@inline}
      on_change={@on_change}
      target={@target}
      locale={@locale}
      today={@today}
    />
    """
  end

  defp date_base do
    %{
      label: "Data",
      value: "2024-03-05",
      mode: "single",
      range: false,
      errors: [],
      disabled: false,
      placeholder: nil,
      display_format: nil,
      range_separator: nil,
      months: nil,
      weekdays: nil,
      week_start: 0,
      min: nil,
      max: nil,
      disabled_dates: [],
      disabled_weekdays: [],
      presets: [],
      labels: %{},
      inline: false,
      on_change: nil,
      target: nil,
      locale: "en",
      today: "2024-03-10"
    }
  end

  defp t_date_cal(assigns) do
    ~H"""
    <.date_picker_calendar
      month={@month}
      today={@today}
      locale={@locale}
      selected={@selected}
      range={@range}
      min={@min}
      max={@max}
      disabled_dates={@disabled_dates}
      disabled_weekdays={@disabled_weekdays}
      week_start={@week_start}
      months={@months}
      weekdays={@weekdays}
      labels={@labels}
    />
    """
  end

  defp t_date_panel(assigns),
    do: ~H|<.date_picker_panel presets={@presets} today={@today} range={@range} />|

  describe "date_picker" do
    test "the locale and today go out of the diff when they did not change (was 4.5 KB per render)" do
      patch = patch(&t_date/1, date_base(), label: "Outro")
      assert patch =~ "Outro"
      refute patch =~ "weekStart"
      refute patch =~ "January"
      assert byte_size(patch) < 300, "patch: #{byte_size(patch)} B"
      {first, _} = first(&t_date/1, date_base())
      assert byte_size(first) > 4_000
    end

    test "(b) every source, with `locale` and `today`" do
      each_source(&t_date/1, date_base(),
        value: "2024-03-06",
        errors: ["ruim"],
        disabled: true,
        placeholder: "Escolha",
        display_format: "d/m/Y",
        months: ~w(a b c d e f g h i j k l),
        weekdays: ~w(a b c d e f g),
        week_start: 1,
        min: "2024-03-02",
        max: "2024-03-20",
        disabled_dates: ["2024-03-07"],
        disabled_weekdays: [0],
        labels: %{picker_date_dialog: "Escolher"},
        inline: true,
        on_change: "ch",
        target: "#t",
        locale: "pt_BR",
        today: "2024-04-11",
        mode: "multiple",
        label: nil
      )

      range = %{date_base() | mode: "range", value: {"2024-03-01", "2024-03-04"}}

      each_source(&t_date/1, range,
        range_separator: " a ",
        presets: [{"Hoje", "today"}],
        value: {"2024-03-02", "2024-03-09"}
      )

      each_source(&t_date/1, date_base(), range: true)
    end

    test "(b) the calendar and the panel" do
      cal = %{
        month: "2024-03-01",
        today: "2024-03-10",
        locale: "en",
        selected: "2024-03-05",
        range: nil,
        min: nil,
        max: nil,
        disabled_dates: [],
        disabled_weekdays: [],
        week_start: 0,
        months: nil,
        weekdays: nil,
        labels: %{}
      }

      each_source(&t_date_cal/1, cal,
        month: "2024-04-01",
        today: "2024-03-11",
        locale: "pt_BR",
        selected: "2024-03-06",
        range: {"2024-03-01", "2024-03-03"},
        min: "2024-03-02",
        max: "2024-03-20",
        disabled_dates: ["2024-03-12"],
        disabled_weekdays: [0],
        week_start: 1,
        months: ~w(a b c d e f g h i j k l),
        weekdays: ~w(a b c d e f g),
        labels: %{picker_previous: "Voltar"}
      )

      each_source(
        &t_date_panel/1,
        %{presets: [{"Hoje", "today"}], today: "2024-03-10", range: nil},
        presets: [{"Hoje", "today"}, {"Ontem", "yesterday"}],
        today: "2024-03-11",
        range: {"2024-03-01", "2024-03-02"}
      )
    end

    test "without `locale` / `today` the values that read them are drawn every time (still correct)" do
      base = %{date_base() | locale: nil, today: nil}

      each_source(&t_date/1, base,
        value: "2024-03-06",
        label: nil,
        errors: ["x"],
        mode: "multiple"
      )
    end
  end

  defp t_dt(assigns) do
    ~H"""
    <.datetime_picker
      id="dt"
      name="dt"
      value={@value}
      mode={@mode}
      errors={@errors}
      placeholder={@placeholder}
      time_format={@time_format}
      time_24hr={@time_24hr}
      minute_step={@minute_step}
      interval={@interval}
      time={@time}
      default_time={@default_time}
      default_hour={@default_hour}
      display_format={@display_format}
      range_separator={@range_separator}
      min={@min}
      max={@max}
      min_time={@min_time}
      max_time={@max_time}
      unavailable={@unavailable}
      week_start={@week_start}
      months={@months}
      weekdays={@weekdays}
      labels={@labels}
      layout={@layout}
      placement={@placement}
      split={@split}
      on_change={@on_change}
      target={@target}
      locale={@locale}
      today={@today}
    />
    """
  end

  defp dt_base do
    %{
      value: "2024-03-05T09:30",
      mode: "single",
      errors: [],
      placeholder: nil,
      time_format: "auto",
      time_24hr: false,
      minute_step: nil,
      interval: 30,
      time: "list",
      default_time: nil,
      default_hour: nil,
      display_format: nil,
      range_separator: " - ",
      min: nil,
      max: nil,
      min_time: nil,
      max_time: nil,
      unavailable: nil,
      week_start: 0,
      months: nil,
      weekdays: nil,
      labels: %{},
      layout: "default",
      placement: "bottom",
      split: false,
      on_change: nil,
      target: nil,
      locale: "en",
      today: "2024-03-10"
    }
  end

  describe "datetime_picker" do
    test "the locale and today go out of the diff when they did not change" do
      base = dt_base()
      patch = patch(&t_dt/1, base, errors: ["ruim"])
      refute patch =~ "weekStart"
      refute patch =~ "January"
      # what is left is the error message and the red box of the input
      assert byte_size(patch) < 1_400, "patch: #{byte_size(patch)} B"
    end

    test "(b) every source, with `locale` and `today`" do
      each_source(&t_dt/1, dt_base(),
        value: "2024-03-06T10:00",
        errors: ["ruim"],
        placeholder: "Escolha",
        time_format: "24",
        interval: 15,
        time: "input",
        display_format: "Y-m-d H:i",
        min: "2024-03-02",
        max: "2024-03-20",
        min_time: "08:00",
        max_time: "20:00",
        unavailable: "2024-03-12",
        week_start: 1,
        months: ~w(a b c d e f g h i j k l),
        weekdays: ~w(a b c d e f g),
        labels: %{datetime_dialog: "Escolher"},
        placement: "top",
        on_change: "ch",
        target: "#t",
        locale: "pt_BR",
        today: "2024-04-11",
        mode: "range",
        layout: "compact",
        default_time: "10:00",
        default_hour: 8,
        minute_step: 10
      )

      each_source(&t_dt/1, %{dt_base() | time_24hr: false, time_format: "auto"}, time_24hr: true)

      each_source(
        &t_dt/1,
        %{dt_base() | mode: "range", value: ["2024-03-05T09:30", "2024-03-06T10:00"]},
        range_separator: " a ",
        value: ["2024-03-07T09:00", "2024-03-08T10:00"]
      )
    end

    test "without `locale` / `today`" do
      each_source(&t_dt/1, %{dt_base() | locale: nil, today: nil},
        value: "2024-03-06T10:00",
        errors: ["x"],
        mode: "range"
      )
    end
  end

  # -- select and autocomplete: every source of the new derived values ---------------------------------

  defp t_sel_all(assigns) do
    ~H"""
    <.select
      id="s1"
      name="s"
      value={@value}
      options={@options}
      multiple={@multiple}
      search={@search}
      label="Rotulo"
    />
    """
  end

  describe "select and autocomplete (b)" do
    test "rows: options, value and multiple" do
      opts = [{"Alfa", "a"}, {"Beta", "b"}, {"Grupo", [{"Gama", "g"}]}]
      grouped = [{"Um", [{"Alfa", "a"}, {"Beta", "b"}]}, {"Dois", [{"Gama", "g"}]}]

      each_source(&t_sel_all/1, %{value: "a", options: opts, multiple: false, search: nil},
        value: "g",
        options: tl(opts),
        multiple: true,
        search: "auto"
      )

      each_source(&t_sel_all/1, %{value: ["a"], options: grouped, multiple: true, search: nil},
        value: ["a", "g"],
        options: tl(grouped)
      )
    end

    test "an option with a count, a hint or disabled goes to the rich rows" do
      rich = [
        %{label: "A", value: "a", count: 3},
        %{label: "B", value: "b", hint: "x"},
        %{label: "C", value: "c", disabled: true}
      ]

      plain = [{"A", "a"}, {"B", "b"}]

      each_source(&t_sel_all/1, %{value: "a", options: plain, multiple: false, search: nil},
        options: rich,
        value: "b"
      )

      each_source(&t_sel_all/1, %{value: "a", options: rich, multiple: false, search: nil},
        options: plain,
        value: "b"
      )
    end
  end

  # -- the body of a slot kept in a map that a child component draws ---------------------------------

  defp t_tabs_body(assigns) do
    ~H"""
    <.tabs id="t" selected="a">
      <:tab name="a" count={3}>{@text}</:tab>
      <:tab name="b" navigate="/b">{@text}</:tab>
      <:panel name="a">PA</:panel>
    </.tabs>
    """
  end

  describe "slot bodies" do
    test "tabs: a new text of the body of a tab reaches the client" do
      each_source(&t_tabs_body/1, %{text: "A"}, text: "Outro")
    end

    test "sidebar: a new text of the body of an item" do
      for fmt <- ["sections", "tree", "nested"] do
        each_source(&t_sb_slot/1, %{text: "A", format: fmt}, text: "Outro")
      end
    end

    test "breadcrumb, steps, menu_list, context_menu, segmented, accordion" do
      each_source(&t_slot_crumb/1, %{text: "A"}, text: "Outro")
      each_source(&t_slot_steps/1, %{text: "A"}, text: "Outro")
      each_source(&t_slot_stepper/1, %{text: "A"}, text: "Outro")
      each_source(&t_slot_ml/1, %{text: "A"}, text: "Outro")
      each_source(&t_slot_ctx/1, %{text: "A"}, text: "Outro")
      each_source(&t_slot_seg/1, %{text: "A"}, text: "Outro")
      each_source(&t_slot_acc/1, %{text: "A"}, text: "Outro")
    end

    test "checkbox_group and radio_group: the body of an option" do
      each_source(&t_slot_cg/1, %{text: "A"}, text: "Outro")
      each_source(&t_slot_cg_card/1, %{text: "A"}, text: "Outro")
      each_source(&t_slot_rg/1, %{text: "A"}, text: "Outro")
    end

    test "filter_menu: the content of a group" do
      for display <- ["submenu", "section"] do
        each_source(&t_slot_fm/1, %{text: "A", display: display}, text: "Outro")
      end
    end

    test "bulk_bar, step_group, flow" do
      each_source(&t_slot_bulk/1, %{text: "A"}, text: "Outro")
      each_source(&t_slot_sg/1, %{text: "A"}, text: "Outro")
      each_source(&t_slot_flow/1, %{text: "A"}, text: "Outro")
    end
  end

  defp t_sb_slot(assigns) do
    ~H"""
    <.sidebar id="sb" format={@format}>
      <:item navigate="/a" icon="home">{@text}</:item>
      <:item navigate="/b" icon="home">B</:item>
    </.sidebar>
    """
  end

  defp t_slot_crumb(assigns),
    do: ~H|<.breadcrumb>
  <:item navigate="/">{@text}</:item><:item>Fim</:item>
</.breadcrumb>|

  defp t_slot_steps(assigns),
    do: ~H|<.steps>
  <:step label="A">{@text}</:step><:step label="B" />
</.steps>|

  defp t_slot_stepper(assigns),
    do: ~H|<.stepper current={0}>
  <:step label="A">{@text}</:step><:step label="B" />
</.stepper>|

  defp t_slot_ml(assigns),
    do: ~H|<.menu_list id="m">
  <:item value="a">{@text}</:item><:item value="b">B</:item>
</.menu_list>|

  defp t_slot_ctx(assigns),
    do: ~H|<.context_menu id="c">
  <:item>{@text}</:item><:item>B</:item><div>x</div>
</.context_menu>|

  defp t_slot_seg(assigns),
    do: ~H|<.segmented id="sg">
  <:option value="a">{@text}</:option><:option value="b">B</:option>
</.segmented>|

  defp t_slot_acc(assigns),
    do: ~H|<.accordion id="ac">
  <:item title="T">{@text}</:item>
</.accordion>|

  defp t_slot_bulk(assigns),
    do: ~H|<.bulk_bar count={2} id="bb">
  <:action id="x">{@text}</:action>
</.bulk_bar>|

  defp t_slot_sg(assigns),
    do: ~H|<.step_group id="sg">
  <:step title="T" status={:done}>{@text}</:step>
</.step_group>|

  defp t_slot_flow(assigns),
    do: ~H|<.flow id="fl" edges={[]}>
  <:node id="n1" title="N">{@text}</:node>
</.flow>|

  defp t_slot_fm(assigns) do
    ~H"""
    <.filter_menu id="fm">
      <:group name="g" label="G" display={@display}>{@text}</:group>
    </.filter_menu>
    """
  end

  defp t_slot_cg(assigns),
    do: ~H|<.checkbox_group name="c">
  <:checkbox value="a">{@text}</:checkbox>
</.checkbox_group>|

  defp t_slot_cg_card(assigns),
    do: ~H|<.checkbox_group name="c" variant="card">
  <:checkbox value="a">{@text}</:checkbox>
</.checkbox_group>|

  defp t_slot_rg(assigns),
    do: ~H|<.radio_group name="r">
  <:radio value="a">{@text}</:radio>
</.radio_group>|
end
