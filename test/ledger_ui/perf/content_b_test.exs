defmodule LedgerUI.Perf.ContentBTest do
  # #85 (A1/A6), the content components: the values a component derives in its body (classes,
  # attribute maps, ids) are settled with `LedgerUI.Helpers.settle/3`, so a call that changes only a
  # text or a slot does not send them again. Per component:
  #
  #   * (a) a new text/slot: the patch holds none of the classes;
  #   * (b) `each_source/3`: for EACH source listed in a `settle/3`, change only that attr and check
  #     that the first render plus the patch is the page a fresh render gives (a source left out of
  #     a list would leave a stale class).
  #
  # A global attribute (`rest`) is given as `data-x={@dx}` (a spread map would not be tracked).
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI

  import LedgerUI.DiffCase

  # -- card -------------------------------------------------------------------------------------

  defp t_card(assigns) do
    ~H"""
    <.card
      variant={@variant}
      size={@size}
      color={@color}
      gradient={@gradient}
      shape={@shape}
      padded={@padded}
      navigate={@navigate}
      patch={@patch}
      href={@href}
      canvas={@canvas}
      body={@body}
      class={@class}
      data-x={@dx}
      title={@title}
    >
      <:actions :if={@actions?}>act</:actions>
      <:bleed :if={@bleed?}>bleed</:bleed>
      {@txt}
    </.card>
    """
  end

  defp t_card_canvas(assigns), do: ~H|<.card canvas={@canvas}>x</.card>|

  @card %{
    variant: "tray",
    size: "md",
    color: "primary",
    gradient: "purple-indigo",
    shape: "rounded",
    padded: true,
    navigate: nil,
    patch: nil,
    href: nil,
    canvas: false,
    body: nil,
    class: nil,
    dx: "a",
    title: "T",
    actions?: false,
    bleed?: false,
    txt: "hello"
  }

  describe "card" do
    test "(a) a new text does not send the classes (surface, tray, composed)" do
      # (a link card is the `<.link>` component of Phoenix, which sends its attributes every time)
      for base <- [@card, %{@card | variant: "soft"}, %{@card | body: "inset"}] do
        patch = patch(&t_card/1, base, txt: "other")
        assert patch =~ "other"
        refute patch =~ "bg-"
        refute patch =~ "rounded"
        refute patch =~ "--card"
        refute patch =~ "shadow"
      end
    end

    test "(b) every source, tray and surface" do
      each_source(&t_card/1, @card,
        variant: "panel",
        shape: "xl",
        navigate: "/x",
        patch: "/p",
        href: "/h",
        class: "w-full",
        dx: "b",
        title: "Other",
        actions?: true
      )

      each_source(&t_card_canvas/1, %{canvas: false}, canvas: true)

      surface = %{@card | variant: "gradient"}

      each_source(&t_card/1, surface,
        color: "info",
        gradient: "sky-blue",
        size: "lg",
        padded: false
      )

      each_source(&t_card/1, %{surface | variant: "soft"}, color: "warning", size: "xs")

      each_source(&t_card/1, %{@card | variant: "soft", href: "/h"}, navigate: "/x", href: nil)
    end

    test "(b) every source, composed" do
      composed = %{@card | body: "inset"}

      each_source(&t_card/1, composed,
        variant: "muted",
        size: "lg",
        body: "separated",
        canvas: true,
        class: "w-full",
        dx: "b",
        title: "Other",
        actions?: true,
        bleed?: true,
        txt: ""
      )

      each_source(&t_card/1, %{composed | txt: ""}, txt: "now", bleed?: true)
      each_source(&t_card/1, %{composed | variant: "bogus"}, variant: "soft")
    end
  end

  defp t_card_parts(assigns) do
    ~H"""
    <div>
      <.card_heading size={@size} level={@level}>{@txt}</.card_heading>
      <.card_footer align={@align}>{@txt}</.card_footer>
    </div>
    """
  end

  test "card_heading and card_footer" do
    base = %{size: "base", level: 2, align: nil, txt: "a"}
    each_source(&t_card_parts/1, base, size: "lg", align: "end", level: 3)
    # (`card_heading` is a `<.dynamic_tag>`, which builds its attributes in its own body and so
    # sends them on every call; its derived class is settled all the same)
    assert patch(&t_card_parts/1, base, txt: "b") =~ "b"
  end

  # -- stat -------------------------------------------------------------------------------------

  defp t_stat(assigns) do
    ~H"""
    <.stat_group variant={@gvariant} card={@gcard} cols={@cols}>
      <.stat_item
        label={@label}
        value={@value}
        size={@size}
        delta={@delta}
        change={@change}
        trend={@trend}
        delta_tone={@delta_tone}
        change_tone={@change_tone}
        hint={@hint}
        note={@note}
        goal={@goal}
        meter={@meter}
        spark={@spark}
        sparkline={@sparkline}
        spark_tone={@spark_tone}
        sparkline_tone={@sparkline_tone}
      />
    </.stat_group>
    """
  end

  @stat %{
    gvariant: "default",
    gcard: true,
    cols: nil,
    label: "Receita",
    value: "9",
    size: "md",
    delta: nil,
    change: nil,
    trend: "up",
    delta_tone: nil,
    change_tone: nil,
    hint: nil,
    note: nil,
    goal: nil,
    meter: nil,
    spark: nil,
    sparkline: nil,
    spark_tone: "accent",
    sparkline_tone: nil
  }

  describe "stat" do
    test "(a) a new value or label does not send the classes" do
      base = %{@stat | delta: "1%", goal: 10, spark: [1, 3, 2]}
      patch = patch(&t_stat/1, base, value: "10", label: "Outro")
      refute patch =~ "inline-flex"
      refute patch =~ "group-data"
      refute patch =~ "M"
    end

    test "(b) every source of stat_item" do
      each_source(&t_stat/1, @stat,
        size: "sm",
        delta: "2%",
        change: "3%",
        hint: "h",
        note: "n",
        goal: 40,
        meter: 50,
        spark: [1, 2, 5],
        sparkline: [3, 1, 2]
      )

      with_delta = %{@stat | delta: "2%"}
      each_source(&t_stat/1, with_delta, trend: "down", delta_tone: "neg", change_tone: "neg")

      each_source(&t_stat/1, %{with_delta | spark: [1, 2, 3]},
        spark_tone: "pos",
        sparkline_tone: "muted"
      )
    end

    test "(b) every source of stat_group" do
      each_source(&t_stat/1, @stat, gvariant: "tile", gcard: false)
      each_source(&t_stat/1, %{@stat | gvariant: "tile"}, cols: 3)
    end
  end

  # -- progress ---------------------------------------------------------------------------------

  defp t_progress(assigns) do
    ~H"""
    <.progress
      value={@value}
      max={@max}
      color={@color}
      variant={@variant}
      size={@size}
      height={@height}
      active={@active}
      indeterminate={@indeterminate}
      shine={@shine}
      loop={@loop}
      label={@label}
      data-x={@dx}
    />
    """
  end

  @progress %{
    value: 30,
    max: 100,
    color: "neutral",
    variant: nil,
    size: nil,
    height: nil,
    active: false,
    indeterminate: false,
    shine: false,
    loop: false,
    label: nil,
    dx: "a"
  }

  describe "progress" do
    test "(a) a new value only sends the width, not the classes" do
      patch = patch(&t_progress/1, @progress, value: 60)
      refute patch =~ "rounded"
      refute patch =~ "--c"
      refute patch =~ "bg-"
    end

    test "(b) every source" do
      each_source(&t_progress/1, @progress,
        value: 50,
        max: 200,
        color: "success",
        variant: "gradient",
        size: "xl",
        height: "3",
        active: true,
        indeterminate: true,
        loop: true,
        label: "L",
        dx: "b"
      )

      each_source(&t_progress/1, %{@progress | indeterminate: true}, shine: true)
      each_source(&t_progress/1, %{@progress | size: "xl", label: "x"}, label: "y", size: "lg")

      each_source(&t_progress/1, %{@progress | label: "x"},
        value: 40,
        max: 10,
        indeterminate: true
      )
    end
  end

  defp t_stack(assigns) do
    ~H"""
    <.progress_stack max={@max} label={@label}>
      <:segment value={@a} label={@seg_label} color={@color} />
      <:segment value={20} />
    </.progress_stack>
    """
  end

  test "progress_stack" do
    base = %{max: 100, label: nil, a: 10, seg_label: "x", color: "1"}
    each_source(&t_stack/1, base, max: 50, label: "S", a: 30, seg_label: "y", color: "c3")
  end

  defp t_ring(assigns) do
    ~H"""
    <.progress_ring
      value={@value}
      max={@max}
      size={@size}
      color={@color}
      label={@label}
      class={@class}
    />
    """
  end

  test "progress_ring" do
    base = %{value: 30, max: 100, size: "md", color: "success", label: nil, class: nil}

    each_source(&t_ring/1, base,
      value: 60,
      max: 50,
      size: "lg",
      color: "info",
      label: "L",
      class: "c"
    )

    assert patch(&t_ring/1, base, label: "ok") =~ "ok"
  end

  # -- tag --------------------------------------------------------------------------------------

  defp t_tag(assigns) do
    ~H"""
    <.tag
      canvas={@canvas}
      color={@color}
      variant={@variant}
      shape={@shape}
      tint={@tint}
      tone={@tone}
      size={@size}
      dashed={@dashed}
      as={@as}
      static={@static}
      value={@value}
      class={@class}
      data-x={@dx}
    >
      {@txt}
    </.tag>
    """
  end

  defp t_tag_link(assigns), do: ~H|<.tag navigate={@navigate}>{@txt}</.tag>|

  @tag_base %{
    canvas: false,
    color: "neutral",
    variant: "soft",
    shape: "rounded",
    tint: nil,
    tone: "neutral",
    size: "md",
    dashed: false,
    as: "button",
    static: false,
    value: nil,
    class: nil,
    dx: "a",
    txt: "label"
  }

  describe "tag" do
    test "(a) a new text does not send the classes" do
      for base <- [@tag_base, %{@tag_base | canvas: true}] do
        patch = patch(&t_tag/1, base, txt: "other")
        assert patch =~ "other"
        refute patch =~ "inline-flex"
        refute patch =~ "border"
      end
    end

    test "(b) every source" do
      each_source(&t_tag/1, @tag_base,
        color: "primary",
        variant: "solid",
        shape: "pill",
        tint: "#ff0000",
        as: "span",
        static: true,
        value: "v",
        class: "w-full",
        dx: "b"
      )

      each_source(&t_tag_link/1, %{navigate: nil, txt: "a"}, navigate: "/x")

      each_source(&t_tag/1, %{@tag_base | canvas: true},
        tone: "acc",
        size: "sm",
        dashed: true,
        class: "w-full",
        dx: "b"
      )
    end
  end

  defp t_tag_group(assigns), do: ~H|<.tag_group class={@class}>{@txt}</.tag_group>|

  test "tag_group" do
    each_source(&t_tag_group/1, %{class: nil, txt: "a"}, class: "c")
    refute patch(&t_tag_group/1, %{class: nil, txt: "a"}, txt: "b") =~ "inline-flex"
  end

  # -- empty_state ------------------------------------------------------------------------------

  defp t_empty(assigns) do
    ~H"""
    <.empty_state variant={@variant} title={@title} tone={@tone} color={@color} icon="inbox">
      {@txt}
    </.empty_state>
    """
  end

  defp t_inline_empty(assigns) do
    ~H|<.inline_empty text={@txt} color={@color} />|
  end

  describe "empty_state" do
    test "(a) a new text does not send the classes, in every variant" do
      for variant <- ~w(canvas card inline plain table) do
        base = %{variant: variant, title: "T", tone: "default", color: "neutral", txt: "why"}
        patch = patch(&t_empty/1, base, txt: "other")
        assert patch =~ "other"
        refute patch =~ "flex"
        refute patch =~ "border"
      end

      patch = patch(&t_inline_empty/1, %{txt: "a", color: "neutral"}, txt: "b")
      refute patch =~ "border"
    end

    test "(b) every source" do
      base = %{variant: "canvas", title: "T", tone: "default", color: "neutral", txt: "why"}
      each_source(&t_empty/1, base, tone: "positive")
      each_source(&t_empty/1, %{base | variant: "card"}, tone: "gradient")
      each_source(&t_empty/1, %{base | variant: "inline"}, color: "success")
      each_source(&t_empty/1, %{base | variant: "plain"}, color: "error")
      each_source(&t_empty/1, %{base | variant: "table"}, color: "success")
      each_source(&t_inline_empty/1, %{txt: "a", color: "neutral"}, color: "error")
    end
  end

  # -- typography -------------------------------------------------------------------------------

  defp t_typography(assigns) do
    ~H"""
    <div>
      <.heading
        level={@level}
        display={@display}
        size={@hsize}
        color={@color}
        weight={@weight}
        style={@style}
        class={@class}
        data-x={@dx}
      >
        {@txt}
      </.heading>
      <.text
        as={@as}
        size={@size}
        weight={@weight}
        color={@color}
        mono={@mono}
        gradient={@gradient}
        decoration={@decoration}
        style={@style}
        class={@class}
        data-x={@dx}
      >
        {@txt}
      </.text>
      <.text_link
        href="/x"
        decoration_style={@dstyle}
        decoration_color={@dcolor}
        style={@style}
        class={@class}
        data-x={@dx}
      >{@txt}</.text_link>
      <.inline_code style={@style} class={@class} data-x={@dx}>{@txt}</.inline_code>
      <.kbd variant={@kvariant} style={@style} class={@class} data-x={@dx}>{@txt}</.kbd>
    </div>
    """
  end

  defp t_typo_static(assigns) do
    ~H"""
    <div>
      <.kbd variant={@kvariant} data-x={@dx}>{@txt}</.kbd>
      <.inline_code data-x={@dx}>{@txt}</.inline_code>
    </div>
    """
  end

  @typography %{
    level: nil,
    display: nil,
    hsize: nil,
    color: "default",
    weight: nil,
    style: nil,
    class: nil,
    dx: "a",
    as: "p",
    size: "inherit",
    mono: false,
    gradient: nil,
    decoration: nil,
    dstyle: "solid",
    dcolor: "current",
    kvariant: "raised",
    txt: "text"
  }

  describe "typography" do
    test "(a) a new text does not send the classes (kbd and inline_code)" do
      # `heading`, `text` and `text_link` are a `<.dynamic_tag>`/`<.link>`, which build their
      # attributes in their own body and send them on every call; their derived classes are
      # settled all the same (see (b)).
      patch = patch(&t_typo_static/1, %{kvariant: "raised", dx: "a", txt: "a"}, txt: "other")
      assert patch =~ "other"
      refute patch =~ "rounded"
      refute patch =~ "font-mono"
      refute patch =~ "border"
    end

    test "(b) every source of heading, text, text_link, inline_code and kbd" do
      each_source(&t_typography/1, @typography,
        level: 3,
        display: 2,
        hsize: "lg",
        color: "primary",
        weight: "bold",
        style: "color:red",
        class: "w-full",
        dx: "b",
        as: "span",
        size: "lg",
        mono: true,
        gradient: "sky-blue",
        decoration: "underline",
        dstyle: "dotted",
        dcolor: "primary",
        kvariant: "dark"
      )

      each_source(&t_typography/1, %{@typography | hsize: "title"}, color: "primary", level: 1)
    end
  end

  # -- popover ----------------------------------------------------------------------------------

  defp t_popover(assigns) do
    ~H"""
    <.popover
      id={@id}
      open={@open}
      placement={@placement}
      fallbacks={@fallbacks}
      offset={@offset}
      trigger_on={@trigger_on}
      arrow={@arrow}
      on_open={@on_open}
      on_close={@on_close}
      target={@target}
      label={@label}
      class={@class}
      width={@width}
    >
      <:trigger :let={a}><button {a}>Go</button></:trigger>
      <:title :if={@titled?}>Title</:title>
      {@txt}
    </.popover>
    """
  end

  @popover %{
    id: "p",
    open: false,
    placement: "right-start",
    fallbacks: ["bottom", "top"],
    offset: 12,
    trigger_on: "click",
    arrow: true,
    on_open: nil,
    on_close: nil,
    target: nil,
    label: nil,
    class: nil,
    width: "272px",
    titled?: false,
    txt: "body"
  }

  describe "popover" do
    test "(a) a new body does not send the classes nor the config" do
      patch = patch(&t_popover/1, @popover, txt: "other")
      assert patch =~ "other"
      refute patch =~ "shadow"
      refute patch =~ "data-lu"
      refute patch =~ "aria"
    end

    test "(b) every source" do
      each_source(&t_popover/1, @popover,
        id: "q",
        open: true,
        placement: "top",
        fallbacks: ["left"],
        offset: 4,
        trigger_on: "hover",
        arrow: false,
        on_open: "o",
        on_close: "c",
        target: "#t",
        label: "L",
        class: "w-full",
        width: "300px",
        titled?: true
      )

      each_source(&t_popover/1, %{@popover | width: nil}, width: "10px")
    end
  end

  # -- hero_card --------------------------------------------------------------------------------

  defp t_hero(assigns) do
    ~H"""
    <.hero_card
      id={@id}
      title={@title}
      size={@size}
      variant={@variant}
      animated={@animated}
      class={@class}
      eyebrow={@eyebrow}
      meta={@meta}
      meta_value="1"
      meter={@meter}
      steps={@steps}
      src={@src}
      picture={@picture}
      position={@position}
    >
      <:art :if={@art?}>art</:art>
      {@txt}
    </.hero_card>
    """
  end

  @hero %{
    id: nil,
    title: "T",
    size: "md",
    variant: "soft",
    animated: false,
    class: nil,
    eyebrow: "E",
    meta: nil,
    meter: nil,
    steps: [],
    src: nil,
    picture: nil,
    position: "center",
    art?: false,
    txt: "note"
  }

  describe "hero_card" do
    test "(a) a new title or body does not send the classes" do
      # (the title is a `<.dynamic_tag>`, which sends its own class every time)
      patch = patch(&t_hero/1, @hero, title: "Other", txt: "x")
      refute patch =~ "rounded-xl"
      refute patch =~ "relative isolate"
      refute patch =~ "flex-[0_1_60%]"
    end

    test "(b) every source" do
      each_source(&t_hero/1, @hero,
        id: "h",
        size: "lg",
        variant: "ai",
        animated: true,
        class: "w-full",
        meta: "M",
        meter: 40,
        steps: [%{label: "a", state: "current"}],
        src: "/a.png",
        picture: "none",
        art?: true
      )

      each_source(&t_hero/1, %{@hero | txt: ""}, txt: "now")
      each_source(&t_hero/1, %{@hero | src: "/a.png"}, src: nil, position: "top")
    end
  end

  # -- small modules ----------------------------------------------------------------------------

  defp t_glow(assigns), do: ~H|<.glow_text tone={@tone} class={@class}>{@txt}</.glow_text>|

  test "glow_text" do
    base = %{tone: "default", class: nil, txt: "a"}
    each_source(&t_glow/1, base, tone: "warm", class: "c")
    # (a `<.dynamic_tag>` sends its attributes on every call: nothing to assert about the patch)
    assert patch(&t_glow/1, base, txt: "b") =~ "b"
  end

  defp t_mask(assigns), do: ~H|<.mask label={@label} data-x={@dx} src="/a.png" />|

  test "mask" do
    each_source(&t_mask/1, %{label: nil, dx: "a"}, label: "L", dx: "b")
  end

  defp t_hotkey(assigns), do: ~H|<.hotkey id="h" keys="g" on_press={@on_press} />|

  test "hotkey" do
    each_source(&t_hotkey/1, %{on_press: "a"}, on_press: Phoenix.LiveView.JS.push("x"))
    each_source(&t_hotkey/1, %{on_press: Phoenix.LiveView.JS.push("x")}, on_press: "b")
  end

  defp t_persist(assigns), do: ~H|<.persist id="p" key="k" value={@value} />|

  test "persist" do
    each_source(&t_persist/1, %{value: %{"a" => 1}}, value: %{"a" => 2})
  end

  defp t_form_section(assigns) do
    ~H"""
    <.form_section
      id="f"
      title={@title}
      variant={@variant}
      layout={@layout}
      divider={@divider}
      columns={@columns}
      class={@class}
    >
      {@txt}
    </.form_section>
    """
  end

  test "form_section" do
    base = %{
      title: "T",
      variant: nil,
      layout: "stacked",
      divider: nil,
      columns: 2,
      class: nil,
      txt: "a"
    }

    each_source(&t_form_section/1, base,
      variant: "aside",
      layout: "aside",
      divider: false,
      columns: 3,
      class: "c"
    )

    each_source(&t_form_section/1, %{base | layout: "aside"},
      layout: "stacked",
      variant: "stacked"
    )

    refute patch(&t_form_section/1, base, txt: "b") =~ "grid"
  end

  defp t_mini(assigns) do
    ~H"""
    <.mini_card
      label={@label}
      surface={@surface}
      tone={@tone}
      class={@class}
      icon="user"
    />
    """
  end

  defp t_mini_link(assigns), do: ~H|<.mini_card label={@label} href={@href} />|

  test "mini_card" do
    base = %{label: "L", surface: "panel", tone: "neutral", class: nil, href: nil}
    base = Map.delete(base, :href)
    each_source(&t_mini/1, base, surface: "card", tone: "success", class: "c")
    each_source(&t_mini_link/1, %{href: nil, label: "L"}, href: "/x")
    refute patch(&t_mini/1, base, label: "M") =~ "rounded"
  end

  defp t_spinner(assigns) do
    ~H"""
    <.spinner
      color={@color}
      variant={@variant}
      size={@size}
      elastic={@elastic}
      label={@label}
      data-x={@dx}
    />
    """
  end

  test "spinner" do
    base = %{
      color: "neutral",
      variant: "canvas",
      size: "sm",
      elastic: false,
      label: "Wait",
      dx: "a"
    }

    each_source(&t_spinner/1, base,
      color: "primary",
      variant: "svg",
      size: "lg",
      elastic: true,
      label: "Go",
      dx: "b"
    )

    each_source(&t_spinner/1, %{base | label: nil}, label: "Now")
    each_source(&t_spinner/1, %{base | variant: "svg"}, variant: "grow")
  end

  defp t_logo(assigns) do
    ~H"""
    <.logo
      mark={@mark}
      size={@size}
      glyph={@glyph}
      tone={@tone}
      id={@id}
      word_size={@word_size}
      name={@name}
      wordmark={@wordmark}
      label={@label}
    />
    """
  end

  test "logo" do
    for mark <- ~w(chart hexagon) do
      base = %{
        mark: mark,
        size: 32,
        glyph: nil,
        tone: "accent",
        id: nil,
        word_size: nil,
        name: nil,
        wordmark: false,
        label: nil
      }

      specific = if mark == "chart", do: [glyph: 10], else: [id: "lg"]

      each_source(
        &t_logo/1,
        base,
        [size: 48, tone: "mono", name: "Acme", wordmark: true, label: "L"] ++ specific
      )

      each_source(&t_logo/1, %{base | wordmark: true}, word_size: 20)
    end
  end

  defp t_signature(assigns) do
    ~H"""
    <.signature_pad
      id={@id}
      name={@name}
      value={@value}
      mode={@mode}
      modes={@modes}
      text={@text}
      height={@height}
      target={@target}
      class={@class}
      locale="en"
    />
    """
  end

  test "signature_pad" do
    svg = ~s(<svg viewBox="0 0 10 10"><path d="M1 1L2 2"/></svg>)

    base = %{
      id: "s",
      name: "n",
      value: "",
      mode: "draw",
      modes: ["draw", "type"],
      text: "",
      height: 170,
      target: nil,
      class: nil
    }

    each_source(&t_signature/1, base,
      id: "t",
      name: "m",
      value: svg,
      mode: "type",
      modes: ["type"],
      height: 200,
      target: "#t",
      class: "c"
    )

    each_source(&t_signature/1, %{base | mode: "type"}, text: "Alex")
  end

  defp t_kanban(assigns) do
    ~H"""
    <.kanban
      id="k"
      event={@event}
      group={@group}
      disabled={@disabled}
      local={@local}
      fluid={@fluid}
      active={@active}
      class={@class}
      style={@style}
    >
      <.kanban_column
        id="c"
        list={@list}
        label={@label}
        count={@count}
        count_label={@count_label}
        over_limit={@over_limit}
        hint={@hint}
        active={@col_active}
        color={@color}
        limit={@limit}
        disabled={@disabled}
        class={@class}
      >
        <:empty :if={@empty?} title="E">e</:empty>
        <.kanban_card id="x" item={@item} risk={@risk} dense={@dense} grip={@grip} class={@class}>
          <:actions :if={@actions?}>a</:actions>
          {@label}
        </.kanban_card>
      </.kanban_column>
      <.kanban_lost label={@label} meta={@meta} list={@list} />
    </.kanban>
    """
  end

  test "kanban" do
    base = %{
      event: nil,
      group: nil,
      disabled: false,
      local: false,
      fluid: false,
      active: nil,
      class: nil,
      style: nil,
      list: nil,
      label: "Todo",
      count: 1,
      count_label: nil,
      over_limit: false,
      hint: "empty",
      col_active: false,
      color: nil,
      limit: nil,
      empty?: false,
      item: nil,
      risk: false,
      dense: false,
      grip: false,
      actions?: false,
      meta: nil
    }

    each_source(&t_kanban/1, base,
      event: "mv",
      group: "g",
      disabled: true,
      local: true,
      fluid: true,
      active: "c",
      class: "c",
      style: "--cols:3",
      list: "a",
      count: 3,
      count_label: "three",
      over_limit: true,
      col_active: true,
      color: "info",
      limit: 0,
      item: "1",
      risk: true,
      dense: true,
      grip: true,
      actions?: true,
      meta: "m"
    )

    each_source(&t_kanban/1, %{base | empty?: true}, hint: "always", count: 0)
    each_source(&t_kanban/1, %{base | count: 0}, empty?: true)
    patch = patch(&t_kanban/1, base, label: "Outro")
    refute patch =~ "rounded"
    refute patch =~ "grid"
  end

  defp t_illustration(assigns) do
    ~H"""
    <div>
      <.illustration name={@name} tone={@tone} color={@color} icon={@icon} />
      <.scene name="voyage" position={@position} />
    </div>
    """
  end

  test "illustration and scene" do
    base = %{name: "empty", tone: nil, color: nil, icon: nil, position: "xMidYMid"}

    each_source(&t_illustration/1, base,
      name: "success",
      tone: "success",
      color: "info",
      icon: "user",
      position: "xMinYMid"
    )

    each_source(&t_illustration/1, %{base | tone: "error"}, tone: nil)
  end

  defp t_pixel(assigns) do
    ~H"""
    <.pixel_card id={@id} title={@title} color={@color} loop={@loop} class={@class} href={@href} />
    """
  end

  test "pixel_card" do
    base = %{id: nil, title: "Ab", color: nil, loop: false, class: nil, href: nil}

    each_source(&t_pixel/1, base,
      id: "p",
      title: "Cd",
      color: "blue",
      loop: true,
      class: "c",
      href: "/x"
    )

    each_source(&t_pixel/1, %{base | id: "p"}, id: nil)
  end

  defp t_sparkline(assigns) do
    ~H|<.sparkline id={@id} values={@values} color={@color} variant={@variant} class={@class} />|
  end

  test "sparkline" do
    base = %{id: "s", values: [1, 3, 2], color: "neutral", variant: "inline", class: nil}

    each_source(&t_sparkline/1, base,
      id: "t",
      values: [2, 1, 5],
      color: "primary",
      variant: "corner",
      class: "c"
    )
  end

  defp t_skeleton(assigns) do
    ~H"""
    <div>
      <.skeleton variant={@variant} shape={@shape} class={@class} animation={@animation} />
      <.skeleton_group loop={@loop}>
        <:loaded :if={@loop}>L</:loaded>
        {@txt}
      </.skeleton_group>
    </div>
    """
  end

  test "skeleton" do
    base = %{variant: nil, shape: nil, class: nil, animation: "wave", loop: false, txt: "a"}

    each_source(&t_skeleton/1, base,
      variant: "lineone",
      shape: "pill",
      class: "h-8",
      animation: "pulse"
    )

    each_source(&t_skeleton/1, %{base | loop: true}, txt: "b")
    refute patch(&t_skeleton/1, %{base | loop: true}, txt: "b") =~ "animate"
  end

  defp t_editor(assigns) do
    ~H"""
    <.text_editor
      id={@id}
      name={@name}
      value={@value}
      label={@label}
      help={@help}
      variant={@variant}
      density={@density}
      images={@images}
      on_image={@on_image}
      toolbar={@toolbar}
      mentions={@mentions}
      mention_button={@mention_button}
      target={@target}
      class={@class}
      content_class={@content_class}
      locale="en"
    />
    """
  end

  test "text_editor" do
    base = %{
      id: "te",
      name: nil,
      value: "<p>a</p>",
      label: nil,
      help: nil,
      variant: "default",
      density: "default",
      images: false,
      on_image: nil,
      toolbar: [["bold"]],
      mentions: [],
      mention_button: false,
      target: nil,
      class: nil,
      content_class: nil
    }

    each_source(&t_editor/1, base,
      id: "tf",
      value: "<p>b</p>",
      label: "L",
      help: "h",
      variant: "comment",
      density: "compact",
      images: true,
      on_image: "img",
      toolbar: [["italic"]],
      target: "#t",
      class: "c",
      content_class: "cc"
    )

    each_source(&t_editor/1, %{base | variant: "comment", mention_button: true},
      mentions: [%{id: "1", name: "a"}]
    )

    each_source(&t_editor/1, %{base | mention_button: true, mentions: [%{id: "1", name: "a"}]},
      variant: "comment"
    )

    each_source(&t_editor/1, %{base | variant: "comment", mentions: [%{id: "1", name: "a"}]},
      mention_button: true
    )

    each_source(&t_editor/1, %{base | id: nil, name: "x y"}, name: "z")

    patch = patch(&t_editor/1, %{base | label: "L"}, label: "Other")
    refute patch =~ "rounded"
    refute patch =~ "slashItems"
  end

  defp t_tool(assigns) do
    ~H"""
    <.tool
      id="t"
      state={@state}
      variant={@variant}
      description={@description}
      input={@input}
      output={@output}
      open={true}
    />
    """
  end

  test "tool" do
    line = %{state: "done", variant: "line", description: nil, input: nil, output: nil}
    each_source(&t_tool/1, line, state: "error", input: "i", output: "o")
    panel = %{line | variant: "panel"}
    each_source(&t_tool/1, panel, state: "error", description: "d")
  end

  defp t_email(assigns) do
    ~H"""
    <div>
      <.email_p theme={@theme} muted={@muted}>{@txt}</.email_p>
      <.email_code value={@value} theme={@theme} />
      <.email_facts rows={@rows} theme={@theme} />
      <.email_steps steps={@steps} theme={@theme} />
      <.email_layout subject="S" title="T" theme={@theme} compact={@compact} locale="en">
        <:action :if={@action?} href="/x">Go</:action>
        <:body>b</:body>
      </.email_layout>
    </div>
    """
  end

  test "email" do
    base = %{
      theme: :auto,
      muted: false,
      value: "123",
      rows: [{"a", "b"}],
      steps: [{"a", true}],
      compact: false,
      action?: false,
      txt: "t"
    }

    each_source(&t_email/1, base,
      theme: :dark,
      muted: true,
      value: "456",
      rows: [{"c", "d"}],
      steps: [{"b", false}],
      compact: true,
      action?: true
    )

    refute patch(&t_email/1, base, txt: "u") =~ "font-family"
  end

  defp t_range(assigns) do
    ~H"""
    <.range
      name={@name}
      id={@id}
      value={@value}
      min={@min}
      max={@max}
      fill={@fill}
      orientation={@orientation}
      height={@height}
      marks={@marks}
      label={@label}
      show_value={@show_value}
      help={@help}
      steppers={@steppers}
      value_format={@value_format}
      color={@color}
      loop={@loop}
      class={@class}
      variant={@variant}
      size={@size}
      filled={@filled}
      start_name={@start_name}
      data-x={@dx}
      locale="en"
    />
    """
  end

  test "range" do
    base = %{
      name: "r",
      id: nil,
      value: 30,
      min: 0,
      max: 100,
      fill: nil,
      orientation: "horizontal",
      height: nil,
      marks: [],
      label: nil,
      show_value: false,
      help: nil,
      steppers: false,
      value_format: "%{value}",
      color: nil,
      loop: false,
      class: nil,
      variant: "canvas",
      size: "md",
      filled: true,
      start_name: nil,
      dx: "a"
    }

    each_source(&t_range/1, base,
      name: "q",
      id: "i",
      value: 60,
      max: 50,
      fill: "#abc",
      orientation: "vertical",
      marks: [0, 100],
      label: "L",
      show_value: true,
      help: "h",
      steppers: true,
      value_format: "%{value}%",
      color: "success",
      loop: true,
      class: "c",
      variant: "classic",
      size: "lg",
      filled: false,
      start_name: "a",
      dx: "b"
    )

    each_source(&t_range/1, %{base | orientation: "vertical"}, height: "200px")
    each_source(&t_range/1, %{base | min: 10}, min: 20)
  end

  defp t_rating(assigns) do
    ~H"""
    <.rating
      id={@id}
      name={@name}
      value={@value}
      max={@max}
      variant={@variant}
      size={@size}
      decimal={@decimal}
      interactive={@interactive}
      label={@label}
      help={@help}
      disabled={@disabled}
      on_change={@on_change}
      target={@target}
      class={@class}
      locale="en"
    />
    """
  end

  test "rating" do
    base = %{
      id: "b",
      name: nil,
      value: 3,
      max: 5,
      variant: "solid",
      size: "md",
      decimal: ",",
      interactive: nil,
      label: nil,
      help: nil,
      disabled: false,
      on_change: nil,
      target: nil,
      class: nil
    }

    each_source(&t_rating/1, base,
      id: "r",
      name: "n",
      value: 4.5,
      max: 6,
      variant: "outline",
      size: "lg",
      decimal: ".",
      interactive: true,
      label: "L",
      help: "h",
      disabled: true,
      on_change: "chg",
      class: "c"
    )

    each_source(&t_rating/1, %{base | interactive: true, id: "i"}, target: "#t", name: "n2")

    each_source(&t_rating/1, %{base | on_change: "x", id: "i"},
      on_change: Phoenix.LiveView.JS.push("y")
    )
  end

  defp t_rating_dist(assigns) do
    ~H|<.rating_distribution
  counts={@counts}
  average={@average}
  total={@total}
  decimal={@decimal}
  locale="en"
/>|
  end

  test "rating_distribution" do
    base = %{counts: [5, 3, 0, 1, 2], average: nil, total: nil, decimal: ","}

    each_source(&t_rating_dist/1, base,
      counts: [1, 1, 1, 1, 1],
      average: 4.2,
      total: 30,
      decimal: "."
    )
  end

  # -- modules found outside the briefing lists: scroll_area, trace, step_group, timeline, timer,
  # upload and shell ---------------------------------------------------------------------------

  defp t_scroll(assigns) do
    ~H"""
    <.scroll_area
      variant={@variant}
      orientation={@orientation}
      scrollbar={@scrollbar}
      focusable={@focusable}
      label={@label}
      id={@id}
      stick_bottom={@stick_bottom}
      class={@class}
    >
      {@txt}
    </.scroll_area>
    """
  end

  test "scroll_area" do
    base = %{
      variant: "plain",
      orientation: "vertical",
      scrollbar: "hover",
      focusable: false,
      label: nil,
      id: "sa",
      stick_bottom: false,
      class: nil,
      txt: "a"
    }

    each_source(&t_scroll/1, base,
      variant: "panel",
      orientation: "both",
      scrollbar: "always",
      focusable: true,
      id: "sb",
      stick_bottom: true,
      class: "c"
    )

    each_source(&t_scroll/1, %{base | focusable: true}, label: "L")
    refute patch(&t_scroll/1, %{base | variant: "panel"}, txt: "b") =~ "rounded-lg"

    preview = %{base | variant: "preview"}
    each_source(&t_scroll/1, preview, orientation: "both", scrollbar: "hidden", class: "c")
    each_source(&t_scroll/1, %{preview | orientation: "horizontal"}, orientation: "vertical")
  end

  defp t_trace(assigns) do
    ~H"""
    <.trace>
      <.trace_line
        title="T"
        status={@status}
        icon={@icon}
        depth={@depth}
        bar={@bar}
        data-x={@dx}
        style={@style}
      />
      <.trace_line title="L" href={@href} />
      <.trace_step title="S" status={@status}>{@txt}</.trace_step>
    </.trace>
    """
  end

  test "trace" do
    base = %{status: nil, icon: nil, depth: 0, bar: nil, dx: "a", style: nil, href: nil, txt: "a"}

    each_source(&t_trace/1, base,
      status: "error",
      icon: "user",
      depth: 2,
      bar: %{start: 1, width: 5},
      dx: "b",
      style: "color:red",
      href: "/x"
    )

    each_source(&t_trace/1, %{base | bar: %{start: 1, width: 5}}, bar: %{start: 5, width: 9})
    refute patch(&t_trace/1, base, txt: "b") =~ "border-t"
  end

  defp t_step_group(assigns) do
    ~H"""
    <div>
      <.step_group id={@id} title="T" current={@current} steps={@steps} />
      <.step_group_line n={1} tone={@tone}>l</.step_group_line>
    </div>
    """
  end

  test "step_group" do
    base = %{id: "sg", current: 1, steps: [%{title: "a"}, %{title: "b"}], tone: nil}

    each_source(&t_step_group/1, base,
      id: "sh",
      current: 2,
      steps: [%{title: "a"}],
      tone: "err"
    )
  end

  defp t_timeline(assigns) do
    ~H"""
    <div>
      <.timeline
        marker={@marker}
        size={@size}
        line_space={@line_space}
        density={@density}
        loop={@loop}
        class={@class}
        variant={@variant}
        rows={@rows}
        row_id={@row_id}
      >
        <:item :let={{id, r}}>
          <.timeline_item title={"T#{r}"} id={id} color={@color} ping={@ping} point_class={@pc} />
        </:item>
      </.timeline>
      <.timeline_event title="E" tone={@tone}>x</.timeline_event>
    </div>
    """
  end

  test "timeline" do
    base = %{
      marker: "icon",
      size: "md",
      line_space: false,
      density: "default",
      loop: false,
      class: nil,
      variant: "line",
      rows: [1],
      row_id: nil,
      color: "neutral",
      ping: false,
      pc: nil,
      tone: "default"
    }

    each_source(&t_timeline/1, base,
      marker: "dot",
      size: "lg",
      line_space: true,
      density: "compact",
      loop: true,
      class: "c",
      variant: "canvas",
      rows: [1, 2],
      row_id: fn r -> "r#{r}" end,
      color: "success",
      ping: true,
      pc: "pc",
      tone: "success"
    )
  end

  defp t_timer(assigns) do
    ~H"""
    <.timer
      id="t"
      elapsed={@elapsed}
      total={@total}
      seconds={@seconds}
      running={@running}
      direction={@direction}
      variant={@variant}
      size={@size}
      color={@color}
      format={@format}
      kicker={@kicker}
      kicker_paused={@kicker_paused}
      label={@label}
      stop_at_total={@stop}
      on_toggle={@on_toggle}
      on_tick={@on_tick}
      on_finish={@on_finish}
      target={@target}
      class={@class}
      demo={@demo}
      locale="en"
    >
      <:actions :if={@actions?}>a</:actions>
      <:caption :if={@caption?}>c</:caption>
    </.timer>
    """
  end

  test "timer" do
    base = %{
      elapsed: 30,
      total: 600,
      seconds: nil,
      running: true,
      direction: "up",
      variant: "ring",
      size: "md",
      color: nil,
      format: "auto",
      kicker: nil,
      kicker_paused: nil,
      label: nil,
      stop: false,
      on_toggle: nil,
      on_tick: nil,
      on_finish: nil,
      target: nil,
      class: nil,
      demo: false,
      actions?: false,
      caption?: false
    }

    each_source(&t_timer/1, base,
      elapsed: 90,
      total: 300,
      seconds: 120,
      running: false,
      direction: "down",
      variant: "mini",
      size: "lg",
      color: "success",
      format: "mm:ss",
      kicker: "k",
      label: "L",
      stop: true,
      on_toggle: "t",
      on_tick: "ti",
      on_finish: "f",
      target: "#t",
      class: "c",
      demo: true,
      actions?: true,
      caption?: true
    )

    each_source(&t_timer/1, %{base | running: false}, kicker_paused: "kp")
    each_source(&t_timer/1, %{base | demo: true}, direction: "down")
  end

  defp t_upload(assigns) do
    ~H"""
    <div>
      <.upload_drop
        error={@error}
        circle={@circle}
        for={@for}
        loop={@loop}
        class={@class}
        locale="en"
      />
      <.upload_zone
        variant={@zvariant}
        color={@color}
        shape={@shape}
        size={@size}
        for={@for}
        class={@class}
      >
        z
      </.upload_zone>
      <.upload_file
        name={@name}
        ext={@ext}
        state={@state}
        class={@class}
        target={@target}
        on_remove={@on_remove}
        locale="en"
      />
      <.upload_thumbs columns={@columns} />
      <.upload_button
        name="d"
        color={@color}
        variant={@bvariant}
        size={@size}
        icon={@icon}
        shape={@shape}
        disabled={@disabled}
        class={@class}
      >b</.upload_button>
    </div>
    """
  end

  test "upload parts" do
    base = %{
      error: false,
      circle: false,
      for: nil,
      loop: false,
      class: nil,
      zvariant: "canvas",
      color: "primary",
      shape: "rounded",
      size: nil,
      name: "a.xml",
      ext: nil,
      state: "progress",
      target: nil,
      columns: nil,
      bvariant: "solid",
      icon: false,
      disabled: false,
      on_remove: nil
    }

    each_source(&t_upload/1, base,
      error: true,
      circle: true,
      for: "x",
      loop: true,
      class: "c",
      zvariant: "glow",
      color: "success",
      shape: "pill",
      size: "xl",
      name: "b.pdf",
      ext: "ZIP",
      state: "error",
      columns: 3,
      bvariant: "outline",
      icon: true,
      disabled: true
    )

    each_source(&t_upload/1, %{base | state: "done", on_remove: "rm"}, target: "#t")
  end

  defp t_shell_links(assigns) do
    ~H"""
    <div>
      <.main_sidebar_link label="A" active={@active} current={@current} href={@href}>i</.main_sidebar_link>
      <.sidebar_nav_link active={@active} current={@current} href={@href} color={@color}>X</.sidebar_nav_link>
      <.sidebar_min_link label="M" active={@active} current={@current} href={@href}>i</.sidebar_min_link>
      <.horizontal_nav_link active={@active} current={@current} href={@href}>H</.horizontal_nav_link>
      <.rail_link label="R" active={@active} current={@current} href={@href}>i</.rail_link>
      <.rail_heading variant={@hvariant}>H</.rail_heading>
      <.rail_workspace name={@name} initials={@initials} />
    </div>
    """
  end

  test "shell links, rail_heading and rail_workspace" do
    base = %{
      active: false,
      current: "/x",
      href: "/x",
      color: "neutral",
      hvariant: "mono",
      name: "Acme",
      initials: nil
    }

    each_source(&t_shell_links/1, %{base | current: nil},
      active: true,
      current: "/x",
      href: "/y",
      hvariant: "sans",
      name: "Beta",
      initials: "ZZ"
    )

    each_source(&t_shell_links/1, %{base | current: "/q"},
      active: true,
      current: "/x",
      href: "/q"
    )

    each_source(&t_shell_links/1, base, color: "info", current: "/y", href: "/z")
  end

  defp t_shell_groups(assigns) do
    ~H"""
    <div>
      <.sidebar_nav_group
        label={@label}
        id={@id}
        name={@name}
        open={@open}
        current={@current}
      >
        <:item :for={i <- @items} navigate={i}>x</:item>
      </.sidebar_nav_group>
      <.rail_module id="m" label="L" open={@open} current={@current}>
        <:icon>i</:icon>
        <:item :for={i <- @items} navigate={i}>x</:item>
      </.rail_module>
      <.horizontal_nav_menu id="n" label="P" active={@act} current="/zzz">
        <:item :for={i <- @items} navigate={i}>x</:item>
      </.horizontal_nav_menu>
      <.tab_bar current={@current} match={@match}>
        <:tab :for={i <- @items} navigate={i} label="T">t</:tab>
      </.tab_bar>
    </div>
    """
  end

  test "shell groups and tab_bar" do
    base = %{
      label: "Starter",
      id: "g",
      name: "n",
      open: nil,
      current: "/a",
      items: ["/a", "/b"],
      act: false,
      match: nil
    }

    each_source(&t_shell_groups/1, base,
      label: "Other",
      id: "h",
      name: "n2",
      open: false,
      current: "/b",
      items: ["/c"],
      act: true
    )

    each_source(&t_shell_groups/1, %{base | current: "/a/1"}, match: "prefix")
  end

  defp t_shell_misc(assigns) do
    ~H"""
    <div>
      <.right_sidebar id="rs" on_open={@on_open} on_close={@on_close}>x</.right_sidebar>
      <.framed_sidebar id="fs" collapsed_width={@cw}>x</.framed_sidebar>
      <.monochrome_toggle on_change={@on_open} />
      <.sub_nav title={@title} loop={@loop}>
        <:group label="A">a</:group>
      </.sub_nav>
      <.page_header
        variant="page"
        title="T"
        density={@density}
        clock={@clock}
        bell={@bell}
        on_bell={@on_bell}
      />
      <.page_header title="T" density={@density} />
      <.header id="hd" search={@search} right_sidebar={@rs} />
    </div>
    """
  end

  test "shell: right_sidebar, framed_sidebar, monochrome_toggle, sub_nav, page_header, header" do
    base = %{
      on_open: nil,
      on_close: nil,
      cw: nil,
      title: "T",
      loop: false,
      density: "default",
      clock: false,
      bell: false,
      on_bell: nil,
      search: false,
      rs: nil
    }

    each_source(&t_shell_misc/1, base,
      on_open: "o",
      on_close: Phoenix.LiveView.JS.push("c"),
      cw: 50,
      title: "U",
      loop: true,
      density: "compact",
      clock: true,
      bell: true,
      search: true,
      rs: "rs"
    )

    each_source(&t_shell_misc/1, %{base | bell: true}, on_bell: "b")
  end

  defp t_shell(assigns) do
    ~H"""
    <.shell
      id="s"
      layout={@layout}
      min_height={@min_height}
      full={@full}
      float={@float}
      sidebar_open={@sidebar_open}
      header_blur={@header_blur}
      header_sticky={@header_sticky}
      main_class={@main_class}
      class={@class}
      on_toggle={@on_toggle}
      style={@style}
    >
      <:sidebar :if={@sidebar?}>m</:sidebar>
      <:tab_bar :if={@tab_bar?}>t</:tab_bar>
      {@txt}
    </.shell>
    """
  end

  test "shell" do
    base = %{
      layout: "sidebar",
      min_height: nil,
      full: false,
      float: false,
      sidebar_open: nil,
      header_blur: nil,
      header_sticky: nil,
      main_class: nil,
      class: nil,
      on_toggle: nil,
      style: nil,
      sidebar?: true,
      tab_bar?: false,
      txt: "a"
    }

    each_source(&t_shell/1, base,
      layout: "sideblock",
      min_height: "900px",
      full: true,
      float: true,
      sidebar_open: false,
      header_blur: false,
      header_sticky: false,
      main_class: "mc",
      class: "c",
      on_toggle: "t",
      style: "color:red",
      sidebar?: false,
      tab_bar?: true
    )

    each_source(&t_shell/1, %{base | on_toggle: "t"}, on_toggle: Phoenix.LiveView.JS.push("p"))
    patch = patch(&t_shell/1, base, txt: "b")
    refute patch =~ "group/shell"
  end

  test "the modules that take a text or a slot only do not send classes again (smoke: sizes)" do
    {json, _html} = first(&t_card/1, @card)
    assert byte_size(json) > 0
  end
end
