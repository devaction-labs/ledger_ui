defmodule LedgerUI.ContentACases do
  @moduledoc false
  # Wrappers that call the components the way a LiveView template does (`<.comp attr={@x}>`), so
  # `__changed__` follows the attrs of the wrapper. Used by `test/ledger_ui/perf/content_a_test.exs`
  # (diffs) and, with a base worktree, to compare the HTML before and after (`cases/0`).
  use Phoenix.Component
  use LedgerUI

  # -- kpi_card --------------------------------------------------------------------------------

  def t_kpi(assigns) do
    ~H"""
    <.kpi_card
      id={@id}
      label={@label}
      value={@value}
      prefix={@prefix}
      unit={@unit}
      delta={@delta}
      compare={@compare}
      trend={@trend}
      delta_tone={@delta_tone}
      spark={@spark}
      spark_variant={@spark_variant}
      value_tone={@value_tone}
      footer_layout={@footer_layout}
      variant={@variant}
      layout={@layout}
      progress={@progress}
      caption={@caption}
      icon_tone={@icon_tone}
      open_label={@open_label}
      class={@class}
      aria-label={@aria}
    >
      <:icon :if={@icon?}><.icon name="plus" /></:icon>
      <:footer :if={@footer?}>footer</:footer>
    </.kpi_card>
    """
  end

  @kpi %{
    id: "k1",
    label: "Revenue",
    value: "$1,200",
    prefix: nil,
    unit: nil,
    delta: "+4%",
    compare: "vs Sep",
    trend: "up",
    delta_tone: nil,
    spark: [3, 1, 2],
    spark_variant: "dot",
    value_tone: nil,
    footer_layout: "row",
    variant: "badge",
    layout: "inline",
    progress: nil,
    caption: nil,
    icon_tone: "acc",
    open_label: nil,
    class: nil,
    aria: "kpi",
    icon?: true,
    footer?: false
  }
  def d_kpi, do: @kpi

  @kpi_alt [
    class: "extra",
    delta_tone: "error",
    trend: "down",
    variant: "canvas",
    layout: "stack",
    icon?: false,
    footer?: true,
    spark: [1, 2, 3, 4],
    spark_variant: "corner",
    progress: 40,
    footer_layout: "stack",
    value_tone: "warning",
    icon_tone: "pos",
    delta: "-9%",
    compare: "vs Oct",
    open_label: "Open",
    id: "k2",
    label: "Cost",
    value: "$9",
    aria: "other"
  ]
  def d_kpi_alt, do: @kpi_alt

  # -- alert -----------------------------------------------------------------------------------

  def t_alert(assigns) do
    ~H"""
    <.alert
      id={@id}
      color={@color}
      variant={@variant}
      shape={@shape}
      accent={@accent}
      description={@description}
      dismissible={@dismissible}
      on_dismiss={@on_dismiss}
      target={@target}
      loop={@loop}
      class={@class}
      title={@title}
      data-x={@x}
    >
      {@body}
    </.alert>
    """
  end

  @alert %{
    id: "a1",
    color: "neutral",
    variant: "canvas",
    shape: "rounded",
    accent: nil,
    description: "desc",
    dismissible: false,
    on_dismiss: nil,
    target: nil,
    loop: false,
    class: nil,
    title: "Title",
    x: "1",
    body: "Body"
  }
  def d_alert, do: @alert

  @alert_alt [
    color: "warning",
    variant: "soft",
    shape: "pill",
    accent: "left",
    dismissible: true,
    class: "extra",
    loop: true,
    id: "a2",
    description: "other desc",
    title: "Other",
    x: "2"
  ]
  def d_alert_alt, do: @alert_alt

  # -- avatar ----------------------------------------------------------------------------------

  def t_avatar(assigns) do
    ~H"""
    <.avatar
      src={@src}
      alt={@alt}
      initials={@initials}
      name={@name}
      icon={@icon}
      kind={@kind}
      size={@size}
      shape={@shape}
      tint={@tint}
      background={@background}
      color={@color}
      variant={@variant}
      status={@status}
      status_position={@status_position}
      ping={@ping}
      ring={@ring}
      speak={@speak}
      ring_color={@ring_color}
      gradient={@gradient}
      style={@style}
      class={@class}
    />
    """
  end

  @avatar %{
    src: nil,
    alt: nil,
    initials: nil,
    name: "Ana Souza",
    icon: nil,
    kind: nil,
    size: "sm",
    shape: "circle",
    tint: nil,
    background: nil,
    color: "neutral",
    variant: "solid",
    status: "online",
    status_position: nil,
    ping: false,
    ring: false,
    speak: false,
    ring_color: nil,
    gradient: nil,
    style: nil,
    class: nil
  }
  def d_avatar, do: @avatar

  @avatar_alt [
    src: "/a.png",
    initials: "zz",
    name: "Bia Lima",
    icon: "user",
    kind: "customer",
    size: "lg",
    shape: "square",
    tint: "#336699",
    background: "#112233",
    color: "primary",
    variant: "soft",
    status: "busy",
    status_position: "top-left",
    ping: true,
    ring: 2,
    speak: true,
    gradient: "purple-indigo",
    style: "margin:1px",
    class: "extra"
  ]
  def d_avatar_alt, do: @avatar_alt

  @avatar_src Map.put(@avatar, :src, "/a.png")
  def d_avatar_src, do: @avatar_src
  @avatar_src_alt [src: "/b.png", alt: "Alt", name: "Bia Lima"]
  def d_avatar_src_alt, do: @avatar_src_alt

  def t_avatar_group(assigns) do
    ~H"""
    <.avatar_group
      pulse={@pulse}
      overlap={@overlap}
      more={@more}
      hidden={@hidden}
      id={@id}
      size={@size}
      spread={@spread}
      label={@label}
      class={@class}
    >
      <.avatar name={@first} size="xs" />
    </.avatar_group>
    """
  end

  @avatar_group %{
    pulse: false,
    overlap: "2",
    more: 2,
    hidden: nil,
    id: "ag",
    size: "xs",
    spread: false,
    label: nil,
    class: nil,
    first: "Ana"
  }
  def d_avatar_group, do: @avatar_group

  @avatar_group_alt [
    pulse: true,
    overlap: "3",
    more: 5,
    hidden: [%{name: "Carla"}, %{name: "Davi"}],
    id: "ag2",
    size: "md",
    spread: true,
    label: "Team",
    class: "extra",
    first: "Beto"
  ]
  def d_avatar_group_alt, do: @avatar_group_alt

  # -- chip ------------------------------------------------------------------------------------

  def t_chip(assigns) do
    ~H"""
    <.chip
      selected={@selected}
      dashed={@dashed}
      tone={@tone}
      size={@size}
      shape={@shape}
      icon={@icon}
      count={@count}
      avatar={@avatar}
      avatar_color={@avatar_color}
      on_remove={@on_remove}
      remove_patch={@remove_patch}
      id={@id}
      target={@target}
      class={@class}
      label={@label}
    />
    """
  end

  def t_chip_click(assigns) do
    ~H"""
    <.chip
      selected={@selected}
      id={@id}
      phx-click={@click}
      label={@label}
      on_remove={@on_remove}
      target={@target}
      avatar={@avatar}
    />
    """
  end

  @chip %{
    selected: nil,
    dashed: false,
    tone: nil,
    size: "md",
    shape: "rounded",
    icon: nil,
    count: nil,
    avatar: nil,
    avatar_color: nil,
    on_remove: nil,
    remove_patch: nil,
    id: "c1",
    target: nil,
    class: nil,
    label: "Late"
  }
  def d_chip, do: @chip

  @chip_alt [
    selected: true,
    dashed: true,
    tone: "acc",
    size: "lg",
    shape: "pill",
    icon: "plus",
    count: 12,
    avatar: "Ana Souza",
    on_remove: "remove",
    remove_patch: "/x",
    id: "c2",
    class: "extra",
    label: "Other"
  ]
  def d_chip_alt, do: @chip_alt

  @chip_click %{
    selected: nil,
    id: "c1",
    click: "go",
    label: "Late",
    on_remove: "remove",
    target: nil,
    avatar: nil
  }
  def d_chip_click, do: @chip_click

  @chip_click_alt [
    selected: true,
    click: "other",
    label: "Other",
    on_remove: "other",
    target: "#t",
    avatar: "Ana"
  ]
  def d_chip_click_alt, do: @chip_click_alt

  # -- drawer ----------------------------------------------------------------------------------

  def t_drawer(assigns) do
    ~H"""
    <.drawer
      id={@id}
      open={@open}
      layout={@layout}
      side={@side}
      placement={@placement}
      size={@size}
      width={@width}
      variant={@variant}
      description={@description}
      close_button={@close_button}
      floating={@floating}
      overlay={@overlay}
      lock_scroll={@lock_scroll}
      prevent_close={@prevent_close}
      on_open={@on_open}
      on_close={@on_close}
      target={@target}
      class={@class}
      panel_class={@panel_class}
      body_class={@body_class}
      inline={@inline}
      title={@title}
    >
      <:header :if={@header?}>Head</:header>
      <:footer :if={@footer?}>Foot</:footer>
      <:back :if={@back?}>Back</:back>
      <:actions :if={@actions?}>Act</:actions>
      {@body}
    </.drawer>
    """
  end

  @drawer %{
    id: "d1",
    open: true,
    layout: nil,
    side: "left",
    placement: nil,
    size: nil,
    width: nil,
    variant: nil,
    description: "desc",
    close_button: true,
    floating: false,
    overlay: true,
    lock_scroll: false,
    prevent_close: false,
    on_open: nil,
    on_close: nil,
    target: nil,
    class: nil,
    panel_class: nil,
    body_class: nil,
    inline: false,
    title: "Title",
    header?: false,
    footer?: false,
    back?: false,
    actions?: false,
    body: "Body"
  }
  def d_drawer, do: @drawer

  @drawer_alt [
    open: false,
    side: "right",
    placement: "bottom",
    size: "lg",
    width: 640,
    variant: "flush",
    description: "other",
    close_button: false,
    overlay: false,
    lock_scroll: true,
    prevent_close: true,
    on_open: "o",
    on_close: "c",
    target: "#t",
    class: "extra",
    panel_class: "pc",
    body_class: "bc",
    inline: true,
    title: "Other",
    header?: true,
    footer?: true,
    back?: true,
    actions?: true,
    id: "d2"
  ]
  def d_drawer_alt, do: @drawer_alt

  @drawer_bare Map.merge(@drawer, %{title: nil, description: nil})
  def d_drawer_bare, do: @drawer_bare

  @drawer_bare_alt [
    floating: true,
    variant: "flush",
    header?: true,
    footer?: true,
    back?: true,
    actions?: true,
    title: "Now titled",
    placement: "bottom",
    side: "right"
  ]
  def d_drawer_bare_alt, do: @drawer_bare_alt

  @drawer_page Map.merge(@drawer, %{layout: "page"})
  def d_drawer_page, do: @drawer_page

  @drawer_page_alt [
    open: false,
    size: "auto",
    width: 640,
    class: "extra",
    body_class: "bc",
    id: "d2",
    on_close: "c",
    target: "#t",
    title: "Other",
    header?: true,
    footer?: true,
    description: "other",
    close_button: false
  ]
  def d_drawer_page_alt, do: @drawer_page_alt

  def t_sheet_header(assigns) do
    ~H"""
    <.sheet_header
      id={@id}
      drawer={@drawer}
      title={@title}
      description={@description}
      close_button={@close_button}
      class={@class}
      style={@style}
    />
    """
  end

  @sheet_header %{
    id: "s-title",
    drawer: nil,
    title: "T",
    description: nil,
    close_button: true,
    class: nil,
    style: nil
  }
  def d_sheet_header, do: @sheet_header

  @sheet_header_alt [drawer: "d1", title: "Other", description: "d", class: "x", style: "a:b"]
  def d_sheet_header_alt, do: @sheet_header_alt

  def t_sheet_parts(assigns) do
    ~H"""
    <.sheet_body class={@class}>{@body}</.sheet_body>
    <.sheet_footer class={@class}>{@body}</.sheet_footer>
    """
  end

  @sheet_parts %{class: nil, body: "x"}
  def d_sheet_parts, do: @sheet_parts
  @sheet_parts_alt [class: "extra"]
  def d_sheet_parts_alt, do: @sheet_parts_alt

  # -- accordion -------------------------------------------------------------------------------

  def t_accordion(assigns) do
    ~H"""
    <.accordion id={@id} variant={@variant} color={@color} multiple={@multiple} class={@class}>
      <:item title="One">{@body}</:item>
      <.accordion_item
        id={@item_id}
        title={@title}
        open={@open}
        on_open={@on_open}
        on_close={@on_close}
        target={@target}
        class={@item_class}
        trigger_class={@trigger_class}
        toggle_label={@toggle_label}
      >
        <:header :if={@header?}>Head</:header>
        {@body}
      </.accordion_item>
    </.accordion>
    """
  end

  @accordion %{
    id: "acc",
    variant: "primary",
    color: "primary",
    multiple: false,
    class: nil,
    item_id: "acc-i",
    title: "Title",
    open: false,
    on_open: nil,
    on_close: nil,
    target: nil,
    item_class: nil,
    trigger_class: nil,
    toggle_label: "Toggle",
    header?: false,
    body: "Body"
  }
  def d_accordion, do: @accordion

  @accordion_alt [
    variant: "advanced",
    color: "success",
    multiple: true,
    class: "extra",
    item_id: "acc-j",
    title: "Other",
    open: true,
    on_open: "o",
    on_close: "c",
    target: "#t",
    item_class: "ic",
    trigger_class: "tc",
    header?: true
  ]
  def d_accordion_alt, do: @accordion_alt

  @accordion_head Map.merge(@accordion, %{header?: true})
  def d_accordion_head, do: @accordion_head
  @accordion_head_alt [toggle_label: "Switch", header?: false, open: true, id: "acc2"]
  def d_accordion_head_alt, do: @accordion_head_alt

  # -- input_group -----------------------------------------------------------------------------

  def t_input_group(assigns) do
    ~H"""
    <.input_group
      id={@id}
      shape={@shape}
      size={@size}
      variant={@variant}
      label={@label}
      label_class={@label_class}
      help={@help}
      errors={@errors}
      state={@state}
      wrapper_class={@wrapper_class}
      class={@class}
      data-x={@x}
    >
      <.input_group_addon class={@addon_class} data-y={@x}>
        {@addon}
      </.input_group_addon>
      <input name="amount" />
    </.input_group>
    """
  end

  @input_group %{
    id: "ig",
    shape: "rounded",
    size: "md",
    variant: "outlined",
    label: "Price",
    label_class: nil,
    help: "help",
    errors: [],
    state: nil,
    wrapper_class: nil,
    class: nil,
    x: "1",
    addon_class: nil,
    addon: "$"
  }
  def d_input_group, do: @input_group

  @input_group_alt [
    id: "ig2",
    shape: "pill",
    size: "lg",
    variant: "filled",
    label: "Cost",
    label_class: "lc",
    help: "other help",
    errors: ["must be positive"],
    state: "success",
    wrapper_class: "wc",
    class: "extra",
    x: "2",
    addon_class: "ac",
    addon: "R$"
  ]
  def d_input_group_alt, do: @input_group_alt

  @input_group_bare Map.merge(@input_group, %{label: nil, help: nil, id: nil})
  def d_input_group_bare, do: @input_group_bare
  @input_group_bare_alt [state: "error", variant: "filled", size: "sm", class: "extra", id: "x"]
  def d_input_group_bare_alt, do: @input_group_bare_alt

  # -- aura, cover, container, divider -----------------------------------------------------------

  def t_aura(assigns) do
    ~H"""
    <.aura
      mode={@mode}
      motion={@motion}
      tone={@tone}
      width={@width}
      radius={@radius}
      shadow={@shadow}
      class={@class}
    >
      {@body}
    </.aura>
    """
  end

  @aura %{
    mode: "spin",
    motion: nil,
    tone: "accent",
    width: "default",
    radius: "default",
    shadow: false,
    class: nil,
    body: "x"
  }
  def d_aura, do: @aura

  @aura_alt [
    mode: "glow",
    motion: "dual",
    tone: "ai",
    width: "lg",
    radius: "pill",
    shadow: true,
    class: "extra"
  ]
  def d_aura_alt, do: @aura_alt

  def t_cover(assigns) do
    ~H"""
    <.cover
      tone={@tone}
      height={@height}
      src={@src}
      title={@title}
      subtitle={@subtitle}
      class={@class}
    >
      <:avatar :if={@avatar?}><.avatar name="Ana" /></:avatar>
      {@body}
    </.cover>
    """
  end

  @cover %{
    tone: "accent",
    height: 180,
    src: nil,
    title: "Title",
    subtitle: "sub",
    class: nil,
    avatar?: true,
    body: "x"
  }
  def d_cover, do: @cover

  @cover_alt [
    tone: "neutral",
    height: 220,
    src: "/c.png",
    title: "Other",
    subtitle: "other",
    class: "extra",
    avatar?: false
  ]
  def d_cover_alt, do: @cover_alt

  def t_container(assigns) do
    ~H"""
    <.container size={@size} class={@class}>{@body}</.container>
    """
  end

  @container %{size: nil, class: nil, body: "x"}
  def d_container, do: @container
  @container_alt [size: "prose", class: "extra"]
  def d_container_alt, do: @container_alt

  def t_divider(assigns) do
    ~H"""
    <.divider orientation={@orientation} align={@align} class={@class} style={@style} label={@label} />
    """
  end

  @divider %{orientation: "horizontal", align: "center", class: nil, style: nil, label: "or"}
  def d_divider, do: @divider
  @divider_alt [align: "left", class: "extra", style: "margin:1px", label: "and"]
  def d_divider_alt, do: @divider_alt

  @divider_vertical Map.merge(@divider, %{orientation: "vertical", label: nil})
  def d_divider_vertical, do: @divider_vertical
  @divider_vertical_alt [class: "h-6", style: "height:30px", label: "x"]
  def d_divider_vertical_alt, do: @divider_vertical_alt

  # -- carousel, cash_timer ---------------------------------------------------------------------

  def t_carousel(assigns) do
    ~H"""
    <.carousel
      id={@id}
      index={@index}
      effect={@effect}
      direction={@direction}
      navigation={@navigation}
      pagination={@pagination}
      slides={@slides}
      autoplay={@autoplay}
      loop={@loop}
      demo={@demo}
      gap={@gap}
      zoom={@zoom}
      on_change={@on_change}
      target={@target}
      label={@label}
      class={@class}
      data-x={@x}
    >
      <.carousel_slide class={@slide_class}>{@body}</.carousel_slide>
      <:thumb :if={@thumb?}>t</:thumb>
    </.carousel>
    """
  end

  @carousel %{
    id: "car",
    index: 0,
    effect: "slide",
    direction: "horizontal",
    navigation: false,
    pagination: "bullets",
    slides: 3,
    autoplay: nil,
    loop: false,
    demo: false,
    gap: nil,
    zoom: nil,
    on_change: nil,
    target: nil,
    label: nil,
    class: nil,
    x: "1",
    slide_class: nil,
    thumb?: false,
    body: "s"
  }
  def d_carousel, do: @carousel

  @carousel_alt [
    index: 1,
    effect: "fade",
    direction: "vertical",
    navigation: "outside",
    pagination: "fraction",
    slides: 5,
    autoplay: 3000,
    loop: true,
    demo: true,
    gap: 8,
    zoom: 2,
    on_change: "chg",
    target: "#t",
    label: "Gallery",
    class: "extra",
    x: "2",
    slide_class: "sc",
    thumb?: true,
    id: "car2"
  ]
  def d_carousel_alt, do: @carousel_alt

  def t_cash_timer(assigns) do
    ~H"""
    <.cash_timer
      id={@id}
      state={@state}
      title={@title}
      subtitle={@subtitle}
      elapsed={@elapsed}
      running={@running}
      amount={@amount}
      difference={@difference}
      class={@class}
    >
      <:stat :if={@stat?} label="Sales">10</:stat>
    </.cash_timer>
    """
  end

  @cash_timer %{
    id: "ct",
    state: "open",
    title: "Register 1",
    subtitle: nil,
    elapsed: 3600,
    running: true,
    amount: "$10",
    difference: nil,
    class: nil,
    stat?: false
  }
  def d_cash_timer, do: @cash_timer

  @cash_timer_alt [
    state: "alert",
    title: "Register 2",
    subtitle: "morning",
    elapsed: 7200,
    running: false,
    amount: "$20",
    difference: "-$1",
    class: "extra",
    stat?: true,
    id: "ct2"
  ]
  def d_cash_timer_alt, do: @cash_timer_alt

  # -- collapse, description_list, code_block ---------------------------------------------------

  def t_collapse(assigns) do
    ~H"""
    <.collapse
      id={@id}
      open={@open}
      on_open={@on_open}
      on_close={@on_close}
      target={@target}
      chevron={@chevron}
      variant={@variant}
      panel_class={@panel_class}
      chevron_class={@chevron_class}
      class={@class}
      data-x={@x}
    >
      <:trigger class={@trigger_class}>{@trigger}</:trigger>
      {@body}
    </.collapse>
    """
  end

  @collapse %{
    id: "co",
    open: false,
    on_open: nil,
    on_close: nil,
    target: nil,
    chevron: "down",
    variant: "canvas",
    panel_class: nil,
    chevron_class: nil,
    class: nil,
    x: "1",
    trigger_class: nil,
    trigger: "More",
    body: "Body"
  }
  def d_collapse, do: @collapse

  @collapse_alt [
    open: true,
    on_open: "o",
    on_close: "c",
    target: "#t",
    chevron: "right",
    variant: "framed",
    panel_class: "pc",
    chevron_class: "cc",
    class: "extra",
    x: "2",
    trigger_class: "tc",
    id: "co2"
  ]
  def d_collapse_alt, do: @collapse_alt

  def t_collapse_text(assigns) do
    ~H"""
    <.collapse_text
      id={@id}
      lines={@lines}
      open={@open}
      more={@more}
      less={@less}
      class={@class}
      text_class={@text_class}
    >
      {@body}
    </.collapse_text>
    """
  end

  @collapse_text %{
    id: "ct",
    lines: 2,
    open: false,
    more: "More",
    less: "Less",
    class: nil,
    text_class: nil,
    body: "Long text"
  }
  def d_collapse_text, do: @collapse_text

  @collapse_text_alt [
    lines: 4,
    open: true,
    more: "Show",
    less: "Hide",
    class: "extra",
    text_class: "tc",
    id: "ct2"
  ]
  def d_collapse_text_alt, do: @collapse_text_alt

  def t_description_list(assigns) do
    ~H"""
    <.description_list
      cols={@cols}
      layout={@layout}
      divider={@divider}
      variant={@variant}
      empty={@empty}
      class={@class}
      style={@style}
    >
      <:item label={@label}>{@value}</:item>
      <:item label="Second">two</:item>
      <:item label="Third">three</:item>
      <:item :if={@extra?} label="Fourth">four</:item>
    </.description_list>
    """
  end

  @description_list %{
    cols: 2,
    layout: "inline",
    divider: "all",
    variant: nil,
    empty: "-",
    class: nil,
    style: nil,
    label: "Name",
    value: "Ana",
    extra?: false
  }
  def d_description_list, do: @description_list

  @description_list_alt [
    cols: 3,
    layout: "stacked",
    divider: "between",
    variant: "stacked",
    class: "extra",
    style: "gap:1px",
    label: "Other",
    value: "Bia",
    extra?: true
  ]
  def d_description_list_alt, do: @description_list_alt

  def t_code_block(assigns) do
    ~H"""
    <.code_block
      id={@id}
      code={@code}
      language={@language}
      title={@title}
      copy={@copy}
      line_numbers={@line_numbers}
      max_height={@max_height}
      size={@size}
      variant={@variant}
      class={@class}
    />
    """
  end

  @code_block %{
    id: "cb",
    code: "def a, do: 1",
    language: "elixir",
    title: nil,
    copy: false,
    line_numbers: false,
    max_height: nil,
    size: "default",
    variant: "default",
    class: nil
  }
  def d_code_block, do: @code_block

  @code_block_alt [
    code: "def b, do: 2",
    language: "js",
    title: "mix.exs",
    copy: true,
    line_numbers: true,
    max_height: 200,
    size: "sm",
    variant: "destructive",
    class: "extra",
    id: "cb2"
  ]
  def d_code_block_alt, do: @code_block_alt

  @code_block_copy Map.merge(@code_block, %{copy: true})
  def d_code_block_copy, do: @code_block_copy
  @code_block_copy_alt [title: "mix.exs", copy: false]
  def d_code_block_copy_alt, do: @code_block_copy_alt

  # -- image_input, placement_stage, clipboard ---------------------------------------------------

  def t_image_input(assigns) do
    ~H"""
    <.image_input
      id={@id}
      name={@name}
      value={@value}
      size={@size}
      shape={@shape}
      initials={@initials}
      hover={@hover}
      loop={@loop}
      progress={@progress}
      class={@class}
    />
    """
  end

  @image_input %{
    id: "ii",
    name: "avatar",
    value: nil,
    size: nil,
    shape: "circle",
    initials: nil,
    hover: false,
    loop: nil,
    progress: 10,
    class: nil
  }
  def d_image_input, do: @image_input

  @image_input_alt [
    id: "ii2",
    name: "pic",
    value: "/p.png",
    size: "lg",
    shape: "rounded",
    initials: "AS",
    hover: true,
    loop: "ring",
    progress: 40,
    class: "extra"
  ]
  def d_image_input_alt, do: @image_input_alt

  def t_placement_stage(assigns) do
    ~H"""
    <.placement_stage
      id={@id}
      src={@src}
      alt={@alt}
      box={@box}
      disabled={@disabled}
      class={@class}
    />
    """
  end

  @placement_stage %{
    id: "ps",
    src: "/a.png",
    alt: "A",
    box: %{left: 10, bottom: 10, width: 20, height: 20},
    disabled: false,
    class: nil
  }
  def d_placement_stage, do: @placement_stage

  @placement_stage_alt [
    id: "ps2",
    src: "/b.png",
    alt: "B",
    box: %{left: 30, bottom: 20, width: 40, height: 10},
    disabled: true,
    class: "extra"
  ]
  def d_placement_stage_alt, do: @placement_stage_alt

  def t_clipboard(assigns) do
    ~H"""
    <.clipboard
      id={@id}
      value={@value}
      toast={@toast}
      copied={@copied}
      on_copy={@on_copy}
      target={@target}
      copied_label={@copied_label}
      icon={@icon}
      icon_only={@icon_only}
      color={@color}
      variant={@variant}
      size={@size}
      class={@class}
    >
      {@body}
    </.clipboard>
    """
  end

  @clipboard %{
    id: "cl",
    value: "abc",
    toast: :default,
    copied: false,
    on_copy: nil,
    target: nil,
    copied_label: nil,
    icon: false,
    icon_only: false,
    color: "primary",
    variant: "solid",
    size: "md",
    class: nil,
    body: "Copy"
  }
  def d_clipboard, do: @clipboard

  @clipboard_alt [
    value: "def",
    toast: "Done",
    on_copy: "copied",
    target: "#t",
    copied_label: "Copied!",
    icon: true,
    color: "neutral",
    variant: "soft",
    size: "lg",
    class: "extra",
    id: "cl2",
    body: "Other"
  ]
  def d_clipboard_alt, do: @clipboard_alt

  @clipboard_copied Map.merge(@clipboard, %{copied: true})
  def d_clipboard_copied, do: @clipboard_copied

  @clipboard_copied_alt [
    copied: false,
    size: "lg",
    class: "extra",
    icon: true,
    copied_label: "Done",
    body: "Other"
  ]
  def d_clipboard_copied_alt, do: @clipboard_copied_alt

  def t_clipboard_input(assigns) do
    ~H"""
    <.clipboard_input id={@id} value={@value} class={@class} label={@label} />
    """
  end

  @clipboard_input %{id: "ci", value: "v", class: nil, label: "Copy"}
  def d_clipboard_input, do: @clipboard_input
  @clipboard_input_alt [id: "ci2", value: "w", class: "extra", label: "Take"]
  def d_clipboard_input_alt, do: @clipboard_input_alt

  # -- calendar ---------------------------------------------------------------------------------

  def t_calendar(assigns) do
    ~H"""
    <.calendar
      id={@id}
      view={@view}
      variant={@variant}
      size={@size}
      loop={@loop}
      months_shown={@months_shown}
      date={@date}
      today={@today}
      selected={@selected}
      events={@events}
      week_start={@week_start}
      header={@header}
      card={@card}
      on_navigate={@on_navigate}
      on_view={@on_view}
      on_select={@on_select}
      on_event={@on_event}
      target={@target}
      class={@class}
      data-x={@x}
    />
    """
  end

  @calendar_events [
    %{date: ~D[2026-03-10], title: "Meeting", color: "info", start: "09:00", end: "10:00"},
    %{date: ~D[2026-03-12], title: "Lunch"}
  ]

  @calendar %{
    id: "cal",
    view: "month",
    variant: "full",
    size: "md",
    loop: nil,
    months_shown: 1,
    date: ~D[2026-03-15],
    today: ~D[2026-03-20],
    selected: nil,
    events: @calendar_events,
    week_start: 0,
    header: true,
    card: true,
    on_navigate: nil,
    on_view: nil,
    on_select: "pick",
    on_event: nil,
    target: nil,
    class: nil,
    x: "1"
  }
  def d_calendar, do: @calendar

  @calendar_alt [
    view: "week",
    selected: ~D[2026-03-12],
    events: [%{date: ~D[2026-03-11], title: "Other"}],
    week_start: 1,
    header: false,
    on_navigate: "nav",
    on_view: "view",
    on_select: nil,
    on_event: "ev",
    target: "#t",
    class: "extra",
    x: "2",
    date: ~D[2026-04-15],
    today: ~D[2026-04-20],
    id: "cal2"
  ]
  def d_calendar_alt, do: @calendar_alt

  @calendar_mini Map.merge(@calendar, %{variant: "mini", on_navigate: "nav"})
  def d_calendar_mini, do: @calendar_mini

  @calendar_mini_alt [
    size: "lg",
    months_shown: 2,
    card: false,
    loop: "pick",
    on_select: "sel",
    on_navigate: nil,
    header: false,
    class: "extra",
    selected: ~D[2026-03-12],
    week_start: 1,
    view: "week"
  ]
  def d_calendar_mini_alt, do: @calendar_mini_alt

  # -- charts -----------------------------------------------------------------------------------

  def t_line_chart(assigns) do
    ~H"""
    <.line_chart
      id={@id}
      labels={@labels}
      series={@series}
      head={@head}
      head_size={@head_size}
      sub={@sub}
      legend={@legend}
      class={@class}
      aria-label={@aria}
    >
      <:sub_content :if={@sub_content?}>rich</:sub_content>
    </.line_chart>
    """
  end

  @line_chart %{
    id: "lc",
    labels: ["a", "b", "c"],
    series: [%{name: "s", values: [1, 3, 2]}, %{name: "t", values: [2, 2, 2]}],
    head: "$10",
    head_size: "md",
    sub: "since",
    legend: nil,
    class: nil,
    aria: "chart",
    sub_content?: false
  }
  def d_line_chart, do: @line_chart

  @line_chart_alt [
    labels: ["x", "y", "z"],
    series: [%{name: "s", values: [4, 1, 3]}],
    head: "$20",
    head_size: "lg",
    sub: "other",
    class: "extra",
    aria: "other",
    id: "lc2"
  ]
  def d_line_chart_alt, do: @line_chart_alt

  @line_chart_nohead Map.merge(@line_chart, %{head: nil, sub: nil})
  def d_line_chart_nohead, do: @line_chart_nohead
  @line_chart_nohead_alt [head: "$5", sub: "x", sub_content?: true]
  def d_line_chart_nohead_alt, do: @line_chart_nohead_alt

  def t_donut(assigns) do
    ~H"""
    <.donut_chart
      id={@id}
      segments={@segments}
      center_label={@center_label}
      center_value={@center_value}
      center_upcase={@center_upcase}
      center_size={@center_size}
      layout={@layout}
      size={@size}
      thickness={@thickness}
      rows_style={@rows_style}
      loop={@loop}
      class={@class}
    />
    """
  end

  @donut %{
    id: "dn",
    segments: [
      %{name: "A", value: 60, color: "red", display: "$60"},
      %{name: "B", value: 40, color: "blue", display: "$40"}
    ],
    center_label: "Total",
    center_value: nil,
    center_upcase: false,
    center_size: "lg",
    layout: "stacked",
    size: 180,
    thickness: 14,
    rows_style: nil,
    loop: false,
    class: nil
  }
  def d_donut, do: @donut

  @donut_alt [
    segments: [%{name: "A", value: 10, color: "red", display: "$10"}],
    center_label: "Sum",
    center_value: "$99",
    center_upcase: true,
    center_size: "sm",
    layout: "side",
    size: 200,
    thickness: 20,
    rows_style: "canvas",
    loop: true,
    class: "extra",
    id: "dn2"
  ]
  def d_donut_alt, do: @donut_alt

  @donut_side Map.merge(@donut, %{layout: "side"})
  def d_donut_side, do: @donut_side

  @donut_side_alt [
    layout: "stacked",
    rows_style: "default",
    size: 160,
    class: "extra",
    loop: true,
    thickness: 10
  ]
  def d_donut_side_alt, do: @donut_side_alt

  def t_waterfall(assigns) do
    ~H"""
    <.waterfall_chart id={@id} steps={@steps} max={@max} ticks={@ticks} loop={@loop} class={@class} />
    """
  end

  @waterfall %{
    id: "wf",
    steps: [
      %{name: "Start", value: 10_000, label: "$10k", total: true},
      %{name: "Up", value: 5000, label: "+5k"},
      %{name: "Down", value: -3000, label: "-3k"}
    ],
    max: 30_000,
    ticks: 3,
    loop: false,
    class: nil
  }
  def d_waterfall, do: @waterfall

  @waterfall_alt [
    max: 20_000,
    ticks: 4,
    loop: true,
    class: "extra",
    id: "wf2",
    steps: [%{name: "Start", value: 8000, label: "$8k", total: true}]
  ]
  def d_waterfall_alt, do: @waterfall_alt

  def t_bar_chart(assigns) do
    ~H"""
    <.bar_chart
      values={@values}
      labels={@labels}
      titles={@titles}
      highlight={@highlight}
      shape={@shape}
      loop={@loop}
      y_axis={@y_axis}
      y_ticks={@y_ticks}
      y_grid={@y_grid}
      height={@height}
      width={@width}
      class={@class}
    />
    """
  end

  @bar_chart %{
    values: [10, 40, 25],
    labels: ["a", "b", "c"],
    titles: [],
    highlight: :last,
    shape: "round",
    loop: false,
    y_axis: true,
    y_ticks: nil,
    y_grid: false,
    height: nil,
    width: nil,
    class: nil
  }
  def d_bar_chart, do: @bar_chart

  @bar_chart_alt [
    values: [5, 50, 20],
    labels: ["x", "y", "z"],
    titles: ["t1", "t2", "t3"],
    highlight: 0,
    shape: "square",
    loop: true,
    y_axis: false,
    y_ticks: [0, 50, 100],
    y_grid: true,
    height: "120px",
    width: "300px",
    class: "extra"
  ]
  def d_bar_chart_alt, do: @bar_chart_alt

  @bar_chart_grid Map.merge(@bar_chart, %{y_grid: true})
  def d_bar_chart_grid, do: @bar_chart_grid
  @bar_chart_grid_alt [y_grid: false, y_axis: false, y_ticks: [0, 20, 40]]
  def d_bar_chart_grid_alt, do: @bar_chart_grid_alt

  def t_cohort(assigns) do
    ~H"""
    <.cohort_heatmap
      columns={@columns}
      rows={@rows}
      thresholds={@thresholds}
      suffix={@suffix}
      class={@class}
    />
    """
  end

  @cohort %{
    columns: ["M0", "M1"],
    rows: [%{label: "Jan", values: [100, 90]}],
    thresholds: [86, 90, 94, 100],
    suffix: "%",
    class: nil
  }
  def d_cohort, do: @cohort

  @cohort_alt [
    columns: ["M0", "M2"],
    rows: [%{label: "Feb", values: [100, 80]}],
    thresholds: [50, 60, 70, 80],
    suffix: " pts",
    class: "extra"
  ]
  def d_cohort_alt, do: @cohort_alt

  def t_heatmap(assigns) do
    ~H"""
    <.heatmap
      levels={@levels}
      columns={@columns}
      size={@size}
      shape={@shape}
      label={@label}
      titles={@titles}
      less={@less}
      more={@more}
      class={@class}
    />
    """
  end

  @heatmap %{
    levels: [0, 1, 2, 3, 4, 2],
    columns: 3,
    size: 12,
    shape: "round",
    label: "Activity",
    titles: nil,
    less: "Less",
    more: "More",
    class: nil
  }
  def d_heatmap, do: @heatmap

  @heatmap_alt [
    levels: [4, 3, 2, 1, 0, 0],
    columns: 2,
    size: 16,
    shape: "square",
    label: "Other",
    titles: ["a"],
    less: "-",
    more: "+",
    class: "extra"
  ]
  def d_heatmap_alt, do: @heatmap_alt

  def t_chart(assigns) do
    ~H"""
    <.chart id={@id} options={@options} class={@class} />
    """
  end

  @chart %{id: "ch", options: "{}", class: nil}
  def d_chart, do: @chart
  @chart_alt [id: "ch2", options: ~s({"a":1}), class: "extra"]
  def d_chart_alt, do: @chart_alt

  # -- color_picker, fab ------------------------------------------------------------------------

  def t_color_picker(assigns) do
    ~H"""
    <.color_picker
      id={@id}
      name={@name}
      value={@value}
      label={@label}
      help={@help}
      errors={@errors}
      alpha={@alpha}
      variant={@variant}
      swatch_size={@swatch_size}
      popover={@popover}
      disabled={@disabled}
      on_change={@on_change}
      target={@target}
      class={@class}
    />
    """
  end

  @color_picker %{
    id: "cp",
    name: "color",
    value: "#4C3FE0",
    label: nil,
    help: nil,
    errors: [],
    alpha: false,
    variant: "full",
    swatch_size: nil,
    popover: false,
    disabled: false,
    on_change: nil,
    target: nil,
    class: nil
  }
  def d_color_picker, do: @color_picker

  @color_picker_alt [
    id: "cp2",
    name: "other",
    value: "#112233",
    label: "Color",
    help: "pick",
    errors: ["bad"],
    alpha: true,
    variant: "compact",
    swatch_size: "lg",
    popover: true,
    disabled: true,
    on_change: "chg",
    target: "#t",
    class: "extra"
  ]
  def d_color_picker_alt, do: @color_picker_alt

  @color_picker_swatches Map.merge(@color_picker, %{variant: "swatches", swatch_size: "sm"})
  def d_color_picker_swatches, do: @color_picker_swatches
  @color_picker_swatches_alt [swatch_size: "lg", variant: "row", target: "#t", popover: true]
  def d_color_picker_swatches_alt, do: @color_picker_swatches_alt

  def t_fab(assigns) do
    ~H"""
    <.fab
      id={@id}
      label={@label}
      position={@position}
      color={@color}
      size={@size}
      variant={@variant}
      offset={@offset}
      retract={@retract}
      expanded={@expanded}
      static={@static}
      fixed={@fixed}
      loop={@loop}
      class={@class}
      style={@style}
      phx-click={@click}
    >
      <:icon :if={@icon?}><.icon name="plus" /></:icon>
      {@body}
    </.fab>
    """
  end

  @fab %{
    id: "fab",
    label: "Ask",
    position: "bottom-right",
    color: "assistant",
    size: "md",
    variant: "canvas",
    offset: nil,
    retract: "hover",
    expanded: false,
    static: false,
    fixed: true,
    loop: false,
    class: nil,
    style: nil,
    click: "go",
    icon?: false,
    body: ""
  }
  def d_fab, do: @fab

  @fab_alt [
    position: "top-left",
    offset: 20,
    static: true,
    fixed: false,
    class: "extra",
    style: "z-index:1",
    click: "other",
    icon?: true,
    id: "fab2"
  ]
  def d_fab_alt, do: @fab_alt

  @fab_pill Map.merge(@fab, %{variant: "pill"})
  def d_fab_pill, do: @fab_pill

  @fab_pill_alt [
    position: "bottom-left",
    color: "dark",
    size: "lg",
    offset: 10,
    retract: "auto",
    expanded: true,
    static: true,
    fixed: false,
    loop: true,
    class: "extra",
    style: "z-index:1",
    click: "other",
    icon?: true,
    label: "Help"
  ]
  def d_fab_pill_alt, do: @fab_pill_alt

  def t_fab_dial(assigns) do
    ~H"""
    <.fab_dial
      id={@id}
      label={@label}
      position={@position}
      variant={@variant}
      offset={@offset}
      open={@open}
      static={@static}
      fixed={@fixed}
      loop={@loop}
      class={@class}
      style={@style}
    >
      <:action label={@action} phx-click="a">x</:action>
    </.fab_dial>
    """
  end

  @fab_dial %{
    id: "fd",
    label: "Actions",
    position: "bottom-right",
    variant: "canvas",
    offset: nil,
    open: false,
    static: false,
    fixed: true,
    loop: false,
    class: nil,
    style: nil,
    action: "One"
  }
  def d_fab_dial, do: @fab_dial

  @fab_dial_alt [
    position: "top-left",
    variant: "pill",
    offset: 8,
    open: true,
    static: true,
    fixed: false,
    loop: true,
    class: "extra",
    style: "z-index:1",
    action: "Two",
    label: "Other",
    id: "fd2"
  ]
  def d_fab_dial_alt, do: @fab_dial_alt

  # -- bulk_bar, error pages, flow, auth --------------------------------------------------------

  def t_bulk_bar(assigns) do
    ~H"""
    <.bulk_bar
      id={@id}
      for={@for}
      count={@count}
      label={@label}
      total={@total}
      on_clear={@on_clear}
      on_select_all={@on_select_all}
      target={@target}
      variant={@variant}
      floating={@floating}
      canvas={@canvas}
      offset={@offset}
      progress={@progress}
      progress_max={@progress_max}
      class={@class}
    >
      <:action phx-click="a">{@action}</:action>
    </.bulk_bar>
    """
  end

  @bulk_bar %{
    id: "bb",
    for: nil,
    count: 3,
    label: "selected",
    total: 10,
    on_clear: "clear",
    on_select_all: "all",
    target: nil,
    variant: "inverse",
    floating: true,
    canvas: false,
    offset: nil,
    progress: 2,
    progress_max: 10,
    class: nil,
    action: "Delete"
  }
  def d_bulk_bar, do: @bulk_bar

  @bulk_bar_alt [
    count: 10,
    label: "chosen",
    on_clear: "clear2",
    target: "#t",
    variant: "soft",
    floating: false,
    canvas: true,
    offset: 12,
    progress: 4,
    progress_max: 20,
    class: "extra",
    id: "bb2"
  ]
  def d_bulk_bar_alt, do: @bulk_bar_alt

  @bulk_bar_inline Map.merge(@bulk_bar, %{variant: "inline", on_select_all: "all"})
  def d_bulk_bar_inline, do: @bulk_bar_inline

  @bulk_bar_inline_alt [
    total: 3,
    count: 10,
    progress: 5,
    progress_max: 20,
    class: "extra"
  ]
  def d_bulk_bar_inline_alt, do: @bulk_bar_inline_alt

  @bulk_bar_float Map.merge(@bulk_bar, %{variant: "float"})
  def d_bulk_bar_float, do: @bulk_bar_float
  @bulk_bar_float_alt [count: 5, class: "extra", action: "Archive"]
  def d_bulk_bar_float_alt, do: @bulk_bar_float_alt

  def t_error_page(assigns) do
    ~H"""
    <.error_page
      code={@code}
      tone={@tone}
      label={@label}
      title={@title}
      description={@description}
      id={@id}
      class={@class}
    />
    """
  end

  @error_page %{
    code: 404,
    tone: nil,
    label: nil,
    title: nil,
    description: nil,
    id: "ep",
    class: nil
  }
  def d_error_page, do: @error_page

  @error_page_alt [
    code: 500,
    tone: "warning",
    label: "Oops",
    title: "Broken",
    description: "Sorry",
    id: "ep2",
    class: "extra"
  ]
  def d_error_page_alt, do: @error_page_alt

  def t_error_state(assigns) do
    ~H"""
    <.error_state
      code={@code}
      tone={@tone}
      icon={@icon}
      compact={@compact}
      float={@float}
      title={@title}
      description={@description}
      id={@id}
      class={@class}
    />
    """
  end

  @error_state %{
    code: 404,
    tone: nil,
    icon: nil,
    compact: false,
    float: false,
    title: nil,
    description: nil,
    id: "es",
    class: nil
  }
  def d_error_state, do: @error_state

  @error_state_alt [
    code: 500,
    tone: "warning",
    icon: "alert",
    compact: true,
    float: true,
    title: "Broken",
    description: "Sorry",
    id: "es2",
    class: "extra"
  ]
  def d_error_state_alt, do: @error_state_alt

  def t_error_links(assigns) do
    ~H"""
    <.error_links title={@title} class={@class}>
      <:link href="/a">{@link}</:link>
    </.error_links>
    """
  end

  @error_links %{title: "Try", class: nil, link: "Home"}
  def d_error_links, do: @error_links
  @error_links_alt [title: "Or", class: "extra", link: "Back"]
  def d_error_links_alt, do: @error_links_alt

  def t_flow(assigns) do
    ~H"""
    <.flow
      id={@id}
      edges={@edges}
      steps={@steps}
      on_branch={@on_branch}
      on_move={@on_move}
      target={@target}
      node_width={@node_width}
      branch_label={@branch_label}
      class={@class}
      aria-label={@aria}
    >
      <:node id="a" title={@title}>one</:node>
      <:node id="b" title="B">two</:node>
    </.flow>
    """
  end

  @flow %{
    id: "fl",
    edges: [%{from: "a", to: "b"}],
    steps: [],
    on_branch: nil,
    on_move: nil,
    target: nil,
    node_width: 300,
    branch_label: nil,
    class: nil,
    aria: nil,
    title: "A"
  }
  def d_flow, do: @flow

  @flow_alt [
    steps: [%{key: "mail", title: "Mail", icon: "mail"}],
    on_branch: "branch",
    on_move: "move",
    target: "#t",
    node_width: 240,
    class: "extra",
    aria: "Flow",
    title: "Other",
    id: "fl2"
  ]
  def d_flow_alt, do: @flow_alt

  @flow_branch Map.merge(@flow, %{
                 steps: [%{key: "mail", title: "Mail", icon: "mail"}],
                 branch_label: "Path"
               })
  def d_flow_branch, do: @flow_branch

  @flow_branch_alt [
    steps: [],
    branch_label: "Route",
    on_branch: "b",
    on_move: "m",
    target: "#t",
    aria: "Flow"
  ]
  def d_flow_branch_alt, do: @flow_branch_alt

  def t_auth_split(assigns) do
    ~H"""
    <.auth_split
      title={@title}
      src={@src}
      variant={@variant}
      form_width={@form_width}
      class={@class}
      style={@style}
    >
      <:art :if={@art?}>art</:art>
      <:aside :if={@aside?}>aside</:aside>
      {@body}
    </.auth_split>
    """
  end

  @auth_split %{
    title: "Welcome",
    src: nil,
    variant: "card",
    form_width: nil,
    class: nil,
    style: nil,
    art?: false,
    aside?: false,
    body: "form"
  }
  def d_auth_split, do: @auth_split

  @auth_split_alt [
    title: "Hello",
    src: "/a.png",
    variant: "full",
    form_width: 400,
    class: "extra",
    style: "margin:1px",
    art?: true,
    aside?: true,
    body: "other"
  ]
  def d_auth_split_alt, do: @auth_split_alt

  def t_auth_page(assigns) do
    ~H"""
    <.auth_page on_submit={@on_submit} on_change={@on_change} class={@class}>{@body}</.auth_page>
    """
  end

  @auth_page %{on_submit: nil, on_change: nil, class: nil, body: "x"}
  def d_auth_page, do: @auth_page
  @auth_page_alt [on_submit: "save", on_change: "validate", class: "extra"]
  def d_auth_page_alt, do: @auth_page_alt

  def t_oauth_button(assigns) do
    ~H"""
    <.oauth_button provider={@provider} href={@href} block={@block} class={@class} data-x={@x}>
      {@body}
    </.oauth_button>
    """
  end

  @oauth_button %{provider: "google", href: nil, block: false, class: nil, x: "1", body: "Google"}
  def d_oauth_button, do: @oauth_button

  @oauth_button_alt [
    provider: "github",
    href: "/auth/github",
    block: true,
    class: "extra",
    x: "2",
    body: "GitHub"
  ]
  def d_oauth_button_alt, do: @oauth_button_alt

  def t_auth_submit(assigns) do
    ~H"""
    <.auth_submit loading={@loading} loading_label={@loading_label} type={@type} class={@class}>
      {@body}
    </.auth_submit>
    """
  end

  @auth_submit %{loading: true, loading_label: "Wait", type: "submit", class: nil, body: "Go"}
  def d_auth_submit, do: @auth_submit

  @auth_submit_alt [
    loading: false,
    loading_label: "Hold on",
    type: "button",
    class: "extra"
  ]
  def d_auth_submit_alt, do: @auth_submit_alt

  # -- ai ---------------------------------------------------------------------------------------

  def t_ai_insights(assigns) do
    ~H"""
    <.ai_insights
      insights={@insights}
      variant={@variant}
      count={@count}
      on_chat={@on_chat}
      target={@target}
      class={@class}
    />
    """
  end

  @ai_insights %{
    insights: [%{title: "Sales", text: "Up **4%**"}],
    variant: "card",
    count: 2,
    on_chat: "chat",
    target: nil,
    class: nil
  }
  def d_ai_insights, do: @ai_insights

  @ai_insights_alt [
    insights: [%{title: "Cost", text: "Down **9%**"}],
    variant: "list",
    count: 5,
    on_chat: "chat2",
    target: "#t",
    class: "extra"
  ]
  def d_ai_insights_alt, do: @ai_insights_alt

  def t_ai_promo(assigns) do
    ~H"""
    <.ai_promo
      count={@count}
      subtitle={@subtitle}
      variant={@variant}
      tone={@tone}
      on_click={@on_click}
      target={@target}
      class={@class}
    />
    """
  end

  @ai_promo %{
    count: 3,
    subtitle: nil,
    variant: "card",
    tone: "brand",
    on_click: nil,
    target: nil,
    class: nil
  }
  def d_ai_promo, do: @ai_promo

  @ai_promo_alt [
    count: 4,
    subtitle: "Ask me",
    class: "extra"
  ]
  def d_ai_promo_alt, do: @ai_promo_alt

  @ai_promo_rail Map.merge(@ai_promo, %{variant: "rail"})
  def d_ai_promo_rail, do: @ai_promo_rail
  @ai_promo_rail_alt [tone: "warm", subtitle: "Ask me", class: "extra", count: 9, on_click: "ask"]
  def d_ai_promo_rail_alt, do: @ai_promo_rail_alt

  def t_ai_greeting(assigns) do
    ~H"""
    <.ai_greeting
      name={@name}
      greeting={@greeting}
      tagline={@tagline}
      size={@size}
      tone={@tone}
      class={@class}
    />
    """
  end

  @ai_greeting %{
    name: "Ana",
    greeting: "Hello",
    tagline: "How can I help?",
    size: "lg",
    tone: "brand",
    class: nil
  }
  def d_ai_greeting, do: @ai_greeting

  @ai_greeting_alt [
    greeting: "Hi",
    tagline: "Ask",
    size: "sm",
    tone: "warm",
    class: "extra"
  ]
  def d_ai_greeting_alt, do: @ai_greeting_alt

  def t_ai_tool_trace(assigns) do
    ~H"""
    <.ai_tool_trace
      tools={@tools}
      running={@running}
      expanded={@expanded}
      duration_ms={@duration_ms}
      variant={@variant}
      summary={@summary}
      name_style={@name_style}
      class={@class}
    />
    """
  end

  @ai_tool_trace %{
    tools: [%{label: "query", title: "Orders", detail: "SELECT 1", ms: 12}],
    running: false,
    expanded: false,
    duration_ms: 1200,
    variant: "default",
    summary: true,
    name_style: "mono",
    class: nil
  }
  def d_ai_tool_trace, do: @ai_tool_trace

  @ai_tool_trace_alt [
    tools: [%{label: "query", title: "Items", detail: "SELECT 2", ms: 5}],
    running: true,
    expanded: true,
    duration_ms: 90,
    variant: "bare",
    name_style: "sans",
    class: "extra"
  ]
  def d_ai_tool_trace_alt, do: @ai_tool_trace_alt

  @ai_tool_trace_open Map.merge(@ai_tool_trace, %{expanded: true})
  def d_ai_tool_trace_open, do: @ai_tool_trace_open
  @ai_tool_trace_open_alt [summary: false, variant: "bare", expanded: false]
  def d_ai_tool_trace_open_alt, do: @ai_tool_trace_open_alt

  def t_ai_message(assigns) do
    ~H"""
    <.ai_message
      role={@role}
      variant={@variant}
      streaming={@streaming}
      status={@status}
      name={@name}
      class={@class}
    >
      {@body}
    </.ai_message>
    """
  end

  @ai_message %{
    role: "assistant",
    variant: "card",
    streaming: false,
    status: "ok",
    name: nil,
    class: nil,
    body: "Hello"
  }
  def d_ai_message, do: @ai_message

  @ai_message_alt [
    variant: "plain",
    streaming: true,
    status: "error",
    class: "extra",
    body: "Other"
  ]
  def d_ai_message_alt, do: @ai_message_alt

  @ai_message_user Map.merge(@ai_message, %{role: "user", name: "Ana Souza"})
  def d_ai_message_user, do: @ai_message_user
  @ai_message_user_alt [name: "Bia Lima", class: "extra", body: "Other"]
  def d_ai_message_user_alt, do: @ai_message_user_alt

  def t_ai_proposal(assigns) do
    ~H"""
    <.ai_proposal
      id={@id}
      title={@title}
      status={@status}
      layout={@layout}
      on_undo={@on_undo}
      on_approve={@on_approve}
      on_reject={@on_reject}
      target={@target}
      class={@class}
    >
      <:action :if={@action?}>retry</:action>
    </.ai_proposal>
    """
  end

  @ai_proposal %{
    id: "pr",
    title: "Create invoice",
    status: "approved",
    layout: "list",
    on_undo: nil,
    on_approve: "ok",
    on_reject: "no",
    target: nil,
    class: nil,
    action?: false
  }
  def d_ai_proposal, do: @ai_proposal

  @ai_proposal_alt [
    title: "Other",
    status: "pending",
    on_undo: "undo",
    class: "extra",
    id: "pr2"
  ]
  def d_ai_proposal_alt, do: @ai_proposal_alt

  @ai_proposal_failed Map.merge(@ai_proposal, %{status: "failed", action?: true})
  def d_ai_proposal_failed, do: @ai_proposal_failed
  @ai_proposal_failed_alt [action?: false, status: "pending"]
  def d_ai_proposal_failed_alt, do: @ai_proposal_failed_alt

  def t_ai_composer(assigns) do
    ~H"""
    <.ai_composer
      id={@id}
      variant={@variant}
      name={@name}
      value={@value}
      streaming={@streaming}
      target={@target}
      placeholder={@placeholder}
      class={@class}
    />
    """
  end

  @ai_composer %{
    id: "cmp",
    variant: "default",
    name: "message",
    value: "",
    streaming: false,
    target: nil,
    placeholder: "Ask",
    class: nil
  }
  def d_ai_composer, do: @ai_composer

  @ai_composer_alt [
    variant: "canvas",
    name: "msg",
    value: "hi",
    streaming: true,
    placeholder: "Type",
    class: "extra",
    id: "cmp2"
  ]
  def d_ai_composer_alt, do: @ai_composer_alt

  def t_prompt_suggestions(assigns) do
    ~H"""
    <.prompt_suggestions
      items={@items}
      tilt={@tilt}
      variant={@variant}
      columns={@columns}
      on_pick={@on_pick}
      target={@target}
      class={@class}
    />
    """
  end

  @prompt_suggestions %{
    items: [%{title: "One", prompt: "Do one"}, %{title: "Two", prompt: "Do two"}],
    tilt: false,
    variant: "card",
    columns: 2,
    on_pick: nil,
    target: nil,
    class: nil
  }
  def d_prompt_suggestions, do: @prompt_suggestions

  @prompt_suggestions_alt [
    items: [%{title: "Three", prompt: "Do three"}],
    tilt: true,
    variant: "grid",
    columns: 3,
    on_pick: "pick",
    target: "#t",
    class: "extra"
  ]
  def d_prompt_suggestions_alt, do: @prompt_suggestions_alt

  @prompt_suggestions_pill Map.merge(@prompt_suggestions, %{variant: "pill"})
  def d_prompt_suggestions_pill, do: @prompt_suggestions_pill

  @prompt_suggestions_pill_alt [
    class: "extra",
    on_pick: "pick",
    items: [%{title: "Three", prompt: "x"}]
  ]
  def d_prompt_suggestions_pill_alt, do: @prompt_suggestions_pill_alt

  def t_conversation_list(assigns) do
    ~H"""
    <.conversation_list
      conversations={@conversations}
      active={@active}
      current={@current}
      search={@search}
      variant={@variant}
      title={@title}
      new_label={@new_label}
      class={@class}
    />
    """
  end

  @conversation_list %{
    conversations: [
      %{id: "c1", title: "First", day: "Today"},
      %{id: "c2", title: "Second", day: "Today"}
    ],
    active: nil,
    current: nil,
    search: nil,
    variant: "rail",
    title: "Chats",
    new_label: "New",
    class: nil
  }
  def d_conversation_list, do: @conversation_list

  @conversation_list_alt [
    conversations: [%{id: "c3", title: "Third", day: "Yesterday"}],
    active: "c1",
    current: "c2",
    search: "Third",
    variant: "card",
    title: "Other",
    class: "extra"
  ]
  def d_conversation_list_alt, do: @conversation_list_alt

  def t_ai_chat(assigns) do
    ~H"""
    <.ai_chat
      id={@id}
      messages={@messages}
      user={@user}
      variant={@variant}
      compact={@compact}
      greeting={@greeting}
      start={@start}
      target={@target}
      class={@class}
    />
    """
  end

  @ai_chat %{
    id: "chat",
    messages: [],
    user: "Ana",
    variant: "page",
    compact: false,
    greeting: "Hey",
    start: true,
    target: nil,
    class: nil
  }
  def d_ai_chat, do: @ai_chat

  @ai_chat_alt [
    messages: [%{id: 3, role: "user", text: "Other"}, %{id: 4, role: "assistant", text: "Ok"}],
    variant: "card",
    compact: true,
    greeting: "Hi",
    start: false,
    target: "#t",
    class: "extra",
    id: "chat2"
  ]
  def d_ai_chat_alt, do: @ai_chat_alt

  @ai_chat_messages Map.merge(@ai_chat, %{
                      messages: [
                        %{id: 1, role: "user", text: "Hi"},
                        %{id: 2, role: "assistant", text: "Hello"}
                      ]
                    })
  def d_ai_chat_messages, do: @ai_chat_messages
  @ai_chat_messages_alt [user: "Bia", target: "#t", class: "extra"]
  def d_ai_chat_messages_alt, do: @ai_chat_messages_alt

  @ai_chat_compact Map.merge(@ai_chat, %{compact: true})
  def d_ai_chat_compact, do: @ai_chat_compact
  @ai_chat_compact_alt [compact: false, variant: "canvas"]
  def d_ai_chat_compact_alt, do: @ai_chat_compact_alt

  # -- the table ---------------------------------------------------------------------------------

  # {name, function, base assigns, alternative value of each attr}
  def sources do
    [
      {"kpi_card", &t_kpi/1, d_kpi(), d_kpi_alt()},
      {"alert", &t_alert/1, d_alert(), d_alert_alt()},
      {"avatar", &t_avatar/1, d_avatar(), d_avatar_alt()},
      {"avatar with a picture", &t_avatar/1, d_avatar_src(), d_avatar_src_alt()},
      {"avatar_group", &t_avatar_group/1, d_avatar_group(), d_avatar_group_alt()},
      {"chip", &t_chip/1, d_chip(), d_chip_alt()},
      {"chip with phx-click", &t_chip_click/1, d_chip_click(), d_chip_click_alt()},
      {"drawer", &t_drawer/1, d_drawer(), d_drawer_alt()},
      {"drawer without a header", &t_drawer/1, d_drawer_bare(), d_drawer_bare_alt()},
      {"drawer page", &t_drawer/1, d_drawer_page(), d_drawer_page_alt()},
      {"sheet_header", &t_sheet_header/1, d_sheet_header(), d_sheet_header_alt()},
      {"sheet_body, sheet_footer", &t_sheet_parts/1, d_sheet_parts(), d_sheet_parts_alt()},
      {"accordion", &t_accordion/1, d_accordion(), d_accordion_alt()},
      {"accordion with a header", &t_accordion/1, d_accordion_head(), d_accordion_head_alt()},
      {"input_group", &t_input_group/1, d_input_group(), d_input_group_alt()},
      {"input_group without a caption", &t_input_group/1, d_input_group_bare(),
       d_input_group_bare_alt()},
      {"aura", &t_aura/1, d_aura(), d_aura_alt()},
      {"cover", &t_cover/1, d_cover(), d_cover_alt()},
      {"container", &t_container/1, d_container(), d_container_alt()},
      {"divider", &t_divider/1, d_divider(), d_divider_alt()},
      {"divider vertical", &t_divider/1, d_divider_vertical(), d_divider_vertical_alt()},
      {"carousel", &t_carousel/1, d_carousel(), d_carousel_alt()},
      {"cash_timer", &t_cash_timer/1, d_cash_timer(), d_cash_timer_alt()},
      {"collapse", &t_collapse/1, d_collapse(), d_collapse_alt()},
      {"collapse_text", &t_collapse_text/1, d_collapse_text(), d_collapse_text_alt()},
      {"description_list", &t_description_list/1, d_description_list(), d_description_list_alt()},
      {"code_block", &t_code_block/1, d_code_block(), d_code_block_alt()},
      {"code_block with copy", &t_code_block/1, d_code_block_copy(), d_code_block_copy_alt()},
      {"image_input", &t_image_input/1, d_image_input(), d_image_input_alt()},
      {"placement_stage", &t_placement_stage/1, d_placement_stage(), d_placement_stage_alt()},
      {"clipboard", &t_clipboard/1, d_clipboard(), d_clipboard_alt()},
      {"clipboard copied", &t_clipboard/1, d_clipboard_copied(), d_clipboard_copied_alt()},
      {"clipboard_input", &t_clipboard_input/1, d_clipboard_input(), d_clipboard_input_alt()},
      {"calendar", &t_calendar/1, d_calendar(), d_calendar_alt()},
      {"calendar mini", &t_calendar/1, d_calendar_mini(), d_calendar_mini_alt()},
      {"line_chart", &t_line_chart/1, d_line_chart(), d_line_chart_alt()},
      {"line_chart without a head", &t_line_chart/1, d_line_chart_nohead(),
       d_line_chart_nohead_alt()},
      {"donut_chart", &t_donut/1, d_donut(), d_donut_alt()},
      {"donut_chart side", &t_donut/1, d_donut_side(), d_donut_side_alt()},
      {"waterfall_chart", &t_waterfall/1, d_waterfall(), d_waterfall_alt()},
      {"bar_chart", &t_bar_chart/1, d_bar_chart(), d_bar_chart_alt()},
      {"bar_chart with a grid", &t_bar_chart/1, d_bar_chart_grid(), d_bar_chart_grid_alt()},
      {"cohort_heatmap", &t_cohort/1, d_cohort(), d_cohort_alt()},
      {"heatmap", &t_heatmap/1, d_heatmap(), d_heatmap_alt()},
      {"chart", &t_chart/1, d_chart(), d_chart_alt()},
      {"color_picker", &t_color_picker/1, d_color_picker(), d_color_picker_alt()},
      {"color_picker swatches", &t_color_picker/1, d_color_picker_swatches(),
       d_color_picker_swatches_alt()},
      {"fab canvas", &t_fab/1, d_fab(), d_fab_alt()},
      {"fab pill", &t_fab/1, d_fab_pill(), d_fab_pill_alt()},
      {"fab_dial", &t_fab_dial/1, d_fab_dial(), d_fab_dial_alt()},
      {"bulk_bar", &t_bulk_bar/1, d_bulk_bar(), d_bulk_bar_alt()},
      {"bulk_bar inline", &t_bulk_bar/1, d_bulk_bar_inline(), d_bulk_bar_inline_alt()},
      {"bulk_bar float", &t_bulk_bar/1, d_bulk_bar_float(), d_bulk_bar_float_alt()},
      {"error_page", &t_error_page/1, d_error_page(), d_error_page_alt()},
      {"error_state", &t_error_state/1, d_error_state(), d_error_state_alt()},
      {"error_links", &t_error_links/1, d_error_links(), d_error_links_alt()},
      {"flow", &t_flow/1, d_flow(), d_flow_alt()},
      {"flow with branches", &t_flow/1, d_flow_branch(), d_flow_branch_alt()},
      {"auth_split", &t_auth_split/1, d_auth_split(), d_auth_split_alt()},
      {"auth_page", &t_auth_page/1, d_auth_page(), d_auth_page_alt()},
      {"oauth_button", &t_oauth_button/1, d_oauth_button(), d_oauth_button_alt()},
      {"auth_submit", &t_auth_submit/1, d_auth_submit(), d_auth_submit_alt()},
      {"ai_insights", &t_ai_insights/1, d_ai_insights(), d_ai_insights_alt()},
      {"ai_promo", &t_ai_promo/1, d_ai_promo(), d_ai_promo_alt()},
      {"ai_promo rail", &t_ai_promo/1, d_ai_promo_rail(), d_ai_promo_rail_alt()},
      {"ai_greeting", &t_ai_greeting/1, d_ai_greeting(), d_ai_greeting_alt()},
      {"ai_tool_trace", &t_ai_tool_trace/1, d_ai_tool_trace(), d_ai_tool_trace_alt()},
      {"ai_tool_trace open", &t_ai_tool_trace/1, d_ai_tool_trace_open(),
       d_ai_tool_trace_open_alt()},
      {"ai_message", &t_ai_message/1, d_ai_message(), d_ai_message_alt()},
      {"ai_message user", &t_ai_message/1, d_ai_message_user(), d_ai_message_user_alt()},
      {"ai_proposal", &t_ai_proposal/1, d_ai_proposal(), d_ai_proposal_alt()},
      {"ai_proposal failed", &t_ai_proposal/1, d_ai_proposal_failed(),
       d_ai_proposal_failed_alt()},
      {"ai_composer", &t_ai_composer/1, d_ai_composer(), d_ai_composer_alt()},
      {"prompt_suggestions", &t_prompt_suggestions/1, d_prompt_suggestions(),
       d_prompt_suggestions_alt()},
      {"prompt_suggestions pill", &t_prompt_suggestions/1, d_prompt_suggestions_pill(),
       d_prompt_suggestions_pill_alt()},
      {"conversation_list", &t_conversation_list/1, d_conversation_list(),
       d_conversation_list_alt()},
      {"ai_chat", &t_ai_chat/1, d_ai_chat(), d_ai_chat_alt()},
      {"ai_chat with messages", &t_ai_chat/1, d_ai_chat_messages(), d_ai_chat_messages_alt()},
      {"ai_chat compact", &t_ai_chat/1, d_ai_chat_compact(), d_ai_chat_compact_alt()}
    ]
  end

  # Every call the parity run renders: the base, each attr alone and all of them together.
  def html_cases do
    for {name, fun, base, alt} <- sources(),
        {label, assigns} <-
          [{"base", base}, {"all", Map.merge(base, Map.new(alt))}] ++
            for({k, v} <- alt, do: {"#{k}", Map.put(base, k, v)}) do
      {"#{name} / #{label}", fun, assigns}
    end
  end
end
