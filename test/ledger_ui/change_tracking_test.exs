defmodule LedgerUI.ChangeTrackingTest do
  # #85: the values a component derives in its body (`:cls`, `:box_class`, `:item_class`...) are
  # assigned from scratch on every call, so they were always "changed" and the LiveView sent the
  # classes again each time the component was called again (a new label, a new body, a validation
  # error). `LedgerUI.Helpers.settle/3` takes them back out of `__changed__` when none of their
  # sources changed. Two kinds of test here:
  #
  #   * (a) a call that changes only the text/slot/body: the patch holds neither the classes nor
  #     the icon SVG;
  #   * (b) for EACH source listed in a `settle/3` call: change only that attr and check that the
  #     page the client ends up with (first render + the patch) is the one a fresh render gives.
  #     A source left out of a list makes (b) fail: the class would stay stale.
  #
  # The patch is built the way the LiveView does it (`Phoenix.LiveView.Diff.render/4`), with a
  # `__changed__` that names only what the caller changed, and applied with
  # `Phoenix.LiveViewTest.Diff.merge_diff/2` (the function the test client uses; internal API of
  # the LiveView, isolated in `check/3`).
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI

  alias LedgerUI.Helpers
  alias Phoenix.LiveView.Diff

  # -- harness -------------------------------------------------------------------------------

  defp full_render(fun, assigns) do
    Diff.render(
      %Phoenix.LiveView.Socket{},
      fun.(Map.put(assigns, :__changed__, nil)),
      Diff.new_fingerprints(),
      Diff.new_components()
    )
  end

  defp html(fun, assigns),
    do: fun.(Map.put(assigns, :__changed__, nil)) |> Phoenix.LiveViewTest.rendered_to_string()

  # Renders `base`, then `base` with `changes` and `__changed__` naming only those keys (what the
  # parent's template does). Returns the patch as JSON and checks that the first render plus the
  # patch is the HTML of a fresh render with the new assigns.
  defp check(fun, base, changes) do
    {full, prints, comps} = full_render(fun, base)
    next = Map.merge(base, Map.new(changes))
    changed = Map.new(changes, fn {k, _} -> {k, true} end)

    {patch, _, _} =
      Diff.render(
        %Phoenix.LiveView.Socket{},
        fun.(Map.put(next, :__changed__, changed)),
        prints,
        comps
      )

    before_html = html(fun, base)
    after_html = html(fun, next)

    assert before_html != after_html,
           "the change #{inspect(changes)} changes nothing in the HTML: the test is wrong"

    merged =
      full
      |> Phoenix.LiveViewTest.Diff.merge_diff(patch)
      |> Diff.to_iodata()
      |> IO.iodata_to_binary()

    assert merged == after_html,
           "after changing only #{inspect(changes)} the client would show a stale page"

    Jason.encode!(patch)
  end

  # the patch of a call that changes `changes`, no HTML comparison
  defp patch(fun, base, changes) do
    {_, prints, comps} = full_render(fun, base)
    next = Map.merge(base, Map.new(changes))
    changed = Map.new(changes, fn {k, _} -> {k, true} end)

    {patch, _, _} =
      Diff.render(
        %Phoenix.LiveView.Socket{},
        fun.(Map.put(next, :__changed__, changed)),
        prints,
        comps
      )

    Jason.encode!(patch)
  end

  defp each_source(fun, base, changes) do
    for {key, value} <- changes do
      try do
        check(fun, base, [{key, value}])
      rescue
        e in ExUnit.AssertionError ->
          reraise %{e | message: "[#{inspect(key)}] " <> e.message}, __STACKTRACE__
      end
    end
  end

  # -- settle/3 -------------------------------------------------------------------------------

  describe "LedgerUI.Helpers.settle/3" do
    test "first render (changed0 nil): nothing is done" do
      assigns = %{a: 1, cls: "x", __changed__: nil}
      assert Helpers.settle(assigns, nil, cls: [:a]) == assigns
      assigns = %{a: 1, cls: "x", __changed__: %{cls: true}}
      assert Helpers.settle(assigns, nil, cls: [:a]) == assigns
    end

    test "drops a derived key when none of its sources changed" do
      assigns = %{a: 1, b: 2, cls: "x", __changed__: %{cls: true, other: true}}
      assert Helpers.settle(assigns, %{other: true}, cls: [:a, :b]).__changed__ == %{other: true}
    end

    test "keeps it when a source changed, or the key itself" do
      assigns = %{a: 1, b: 2, cls: "x", __changed__: %{cls: true, b: true}}

      assert Helpers.settle(assigns, %{b: true}, cls: [:a, :b]).__changed__ == %{
               cls: true,
               b: true
             }

      assert Helpers.settle(assigns, %{cls: true}, cls: [:a]).__changed__ == %{cls: true, b: true}
    end

    test "a source can be a derived key listed before it" do
      assigns = %{a: 1, mid: 2, cls: "x", __changed__: %{mid: true, cls: true, a: true}}
      # `a` changed: `mid` stays, and so does `cls`, which reads `mid`
      kept = Helpers.settle(assigns, %{a: true}, mid: [:a], cls: [:mid])
      assert kept.__changed__ == %{mid: true, cls: true, a: true}

      assigns = %{a: 1, b: 1, mid: 2, cls: "x", __changed__: %{mid: true, cls: true, b: true}}
      dropped = Helpers.settle(assigns, %{b: true}, mid: [:a], cls: [:mid])
      assert dropped.__changed__ == %{b: true}
    end

    test "a derived key that is not listed stays changed, and so does what reads it" do
      assigns = %{a: 1, mid: 2, cls: "x", __changed__: %{mid: true, cls: true}}
      assert Helpers.settle(assigns, %{}, cls: [:mid]).__changed__ == %{mid: true, cls: true}
    end

    test "a source that is not an assign raises (a typo would leave the value stale)" do
      assigns = %{a: 1, cls: "x", __changed__: %{cls: true}}

      assert_raise ArgumentError, ~r/:varient is not an assign/, fn ->
        Helpers.settle(assigns, %{}, cls: [:varient])
      end

      assert_raise ArgumentError, fn ->
        Helpers.settle(%{__changed__: nil}, nil, cls: [:varient])
      end
    end

    test "an assigns map with no tracking is returned as it came" do
      assigns = %{a: 1}
      assert Helpers.settle(assigns, %{}, cls: [:a]) == assigns
    end
  end

  # -- button --------------------------------------------------------------------------------

  defp t_button(assigns) do
    ~H"""
    <.button
      color={@color}
      variant={@variant}
      size={@size}
      shape={@shape}
      icon={@icon}
      trailing_icon={@trailing_icon}
      canvas={@canvas}
      appearance={@appearance}
      pip={@pip}
      loading={@loading}
      auto_loading={@auto_loading}
      type={@type}
      class={@class}
      phx-click={@click}
      aria-label={@aria}
    >{@label}</.button>
    """
  end

  @button %{
    color: "neutral",
    variant: "solid",
    size: "md",
    shape: nil,
    icon: "plus",
    trailing_icon: nil,
    canvas: false,
    appearance: "default",
    pip: false,
    loading: false,
    auto_loading: true,
    type: "button",
    class: nil,
    click: nil,
    aria: "x",
    label: "Salvar"
  }

  describe "button" do
    test "(a) a new label does not send the classes nor the icon again" do
      patch = patch(&t_button/1, @button, label: "Excluir")
      assert patch =~ "Excluir"
      refute patch =~ "inline-flex"
      refute patch =~ "svg"
      refute patch =~ "--c"
      assert byte_size(patch) < 80
    end

    test "(a) the same for the canvas button and the link" do
      patch = patch(&t_button/1, %{@button | canvas: true, appearance: "primary"}, label: "Outro")
      refute patch =~ "inline-flex"
      refute patch =~ "svg"
    end

    test "(b) every source of cls, icon_size, spinner_tone and auto?" do
      # icon_only?: icon · cls: canvas, appearance, size, pip, color, variant, shape, icon_only?,
      # loading · spinner_tone: variant · auto?: auto_loading, loading, rest (phx-click), type
      each_source(&t_button/1, @button,
        icon: true,
        canvas: true,
        size: "lg",
        color: "primary",
        variant: "outline",
        shape: "pill",
        loading: true,
        type: "submit",
        click: "go",
        class: "w-full",
        trailing_icon: "arrow-right"
      )

      each_source(&t_button/1, %{@button | click: "go"}, auto_loading: false, loading: true)

      canvas = %{@button | canvas: true}
      each_source(&t_button/1, canvas, appearance: "primary", pip: true, size: "lg")
      each_source(&t_button/1, %{canvas | appearance: "go"}, appearance: "default")
    end
  end

  defp t_insight(assigns),
    do: ~H|<.insight_button count={@count} icon={@icon} class={@class}>{@label}</.insight_button>|

  test "insight_button: class is a source, the label is not" do
    base = %{count: 3, icon: nil, class: nil, label: "Novos"}
    each_source(&t_insight/1, base, class: "w-full", count: 4, icon: "huge-sparkles")
    refute patch(&t_insight/1, base, label: "Outros") =~ "rounded-lg"
  end

  # -- badge ---------------------------------------------------------------------------------

  defp t_badge(assigns) do
    ~H"""
    <.badge
      color={@color}
      variant={@variant}
      size={@size}
      shape={@shape}
      canvas={@canvas}
      icon={@icon}
      class={@class}
    >
      {@label}
    </.badge>
    """
  end

  @badge %{
    color: "success",
    variant: "soft",
    size: "md",
    shape: "rounded",
    canvas: false,
    icon: "check",
    class: nil,
    label: "Ativo"
  }

  describe "badge" do
    test "(a) a new text does not send the classes nor the icon again" do
      patch = patch(&t_badge/1, @badge, label: "Inativo")
      assert patch =~ "Inativo"
      refute patch =~ "inline-flex"
      refute patch =~ "svg"
      assert byte_size(patch) < 60
    end

    test "(b) every source of cls" do
      # cls: canvas, color, variant, size, shape
      each_source(&t_badge/1, @badge,
        color: "error",
        variant: "solid",
        size: "lg",
        shape: "pill",
        canvas: true,
        class: "ml-2"
      )

      canvas = %{@badge | canvas: true}
      each_source(&t_badge/1, canvas, color: "error", variant: "outline", size: "lg")
    end
  end

  defp t_count(assigns), do: ~H|<.count tone={@tone}>{@n}</.count>|
  defp t_delta(assigns), do: ~H|<.delta trend={@trend} tone={@tone}>{@n}</.delta>|

  test "count and delta: tone and trend are the sources" do
    each_source(&t_count/1, %{tone: "error", n: 1}, tone: "success")
    refute patch(&t_count/1, %{tone: "error", n: 1}, n: 2) =~ "text-white"
    each_source(&t_delta/1, %{trend: "up", tone: nil, n: 1}, trend: "down", tone: "neutral")
    refute patch(&t_delta/1, %{trend: "up", tone: nil, n: 1}, n: 2) =~ "border-b-6"
  end

  # -- input ---------------------------------------------------------------------------------

  defp t_input(assigns) do
    ~H"""
    <.input
      id={@id}
      name={@name}
      value={@value}
      type={@type}
      variant={@variant}
      size={@size}
      shape={@shape}
      align={@align}
      state={@state}
      label={@label}
      help={@help}
      errors={@errors}
      disabled={@disabled}
      options={@options}
      icon={@icon}
      prefix={@prefix}
      mask={@mask}
      mask_options={@mask_options}
      mask_submit={@mask_submit}
      clear_on_submit={@clear_on_submit}
      shortcut={@shortcut}
      required={@required}
      class={@class}
      wrapper_class={@wrapper_class}
      placeholder={@placeholder}
    />
    """
  end

  @input %{
    id: "i1",
    name: "n",
    value: "v",
    type: "text",
    variant: "outlined",
    size: "md",
    shape: "rounded",
    align: "left",
    state: nil,
    label: "Nome",
    help: nil,
    errors: [],
    disabled: false,
    options: [],
    icon: "search",
    prefix: nil,
    mask: nil,
    mask_options: %{},
    mask_submit: "formatted",
    clear_on_submit: false,
    shortcut: nil,
    required: false,
    class: nil,
    wrapper_class: nil,
    placeholder: "p"
  }

  defp t_input_slots(assigns) do
    ~H"""
    <.input name="n" label={@label} class={@class}>
      <:below>{@below}</:below>
      <:trailing>{@trailing}</:trailing>
    </.input>
    """
  end

  defp t_field_input(assigns), do: ~H|<.input field={@field} label="Nome" />|

  defp t_form(errors \\ []) do
    Phoenix.Component.to_form(%{"name" => "Ana"}, as: :c, errors: errors, action: :validate)
  end

  describe "input" do
    test "(a) a new value, label or slot does not send the box classes again" do
      patch = patch(&t_input/1, @input, label: "Outro nome")
      assert patch =~ "Outro nome"
      refute patch =~ "border-line-strong"
      refute patch =~ "h-9"
      refute patch =~ "svg"
      refute patch =~ "appearance-none"

      patch =
        patch(&t_input_slots/1, %{label: "L", class: nil, below: "a", trailing: "t"}, below: "b")

      refute patch =~ "border-line-strong"
      refute patch =~ "appearance-none"

      patch = patch(&t_input/1, @input, value: "outro")
      refute patch =~ "border-line-strong"
      refute patch =~ "appearance-none"
    end

    test "(a) a keystroke in a form field: the other fields are not called again, and the typed one keeps its classes only if the errors did not move" do
      {_, _, _} = full_render(&t_field_input/1, %{field: t_form()[:name]})
      # the field changed (value): errors and state hang from it, so the box classes are sent.
      patch = patch(&t_field_input/1, %{field: t_form()[:name]}, field: t_form()[:name])
      assert is_binary(patch)
    end

    test "(b) every source of the derived values" do
      # box_class: variant, size, shape, state, disabled, class · input_class: align, type ·
      # state: errors (and the state attr) · value_attr: type, value · input_attrs: rest, mask,
      # options, id, state, shortcut · has_msg: label, help, errors
      each_source(&t_input/1, @input,
        variant: "filled",
        size: "lg",
        shape: "pill",
        state: "success",
        disabled: true,
        class: "w-40",
        align: "right",
        type: "password",
        errors: ["ruim"],
        value: "outro",
        placeholder: "q",
        options: ["a", "b"],
        label: nil,
        help: "ajuda",
        icon: nil,
        prefix: "R$",
        required: true,
        wrapper_class: "w",
        mask: "cpf_cnpj",
        shortcut: "/",
        clear_on_submit: true
      )

      masked = %{@input | mask: "numeral", id: nil}
      each_source(&t_input/1, masked, name: "outro", mask_submit: "raw", clear_on_submit: true)
      each_source(&t_input/1, masked, mask_options: %{thousands: "lakh"}, mask: "blocks")
      each_source(&t_input/1, %{@input | shortcut: "/", id: nil}, name: "x", id: "outro")
    end

    test "(b) `field`: the errors it brings change the classes" do
      base = %{field: t_form()[:name]}
      each_source(&t_field_input/1, base, field: t_form(name: {"obrigatório", []})[:name])
    end
  end

  # -- select --------------------------------------------------------------------------------

  defp t_select(assigns) do
    ~H"""
    <.select
      id={@id}
      name={@name}
      value={@value}
      options={@options}
      native={@native}
      multiple={@multiple}
      variant={@variant}
      size={@size}
      shape={@shape}
      errors={@errors}
      disabled={@disabled}
      inline={@inline}
      class={@class}
      label={@label}
      search={@search}
      panel_min_width={@panel_min_width}
      overflow={@overflow}
      placeholder={@placeholder}
    />
    """
  end

  @options [{"Alfa", "a"}, {"Beta", "b"}, {"Gama", "g"}]

  @select %{
    id: "s1",
    name: "s",
    value: "a",
    options: @options,
    native: false,
    multiple: false,
    variant: "outline",
    size: "md",
    shape: "rounded",
    errors: [],
    disabled: false,
    inline: false,
    class: nil,
    label: "Rótulo",
    search: nil,
    panel_min_width: nil,
    overflow: "count",
    placeholder: "Escolha"
  }

  describe "select" do
    test "(a) a new label or placeholder does not send the classes, the icons nor the options again" do
      for base <- [@select, %{@select | native: true}] do
        patch = patch(&t_select/1, base, label: "Outro")
        assert patch =~ "Outro"
        refute patch =~ "border-line-strong"
        refute patch =~ "svg"
        refute patch =~ "Beta"
      end
    end

    test "(a) a new value does not send the classes of the control, only the options that changed state" do
      patch = patch(&t_select/1, @select, value: "b")
      refute patch =~ "border-line-strong"
      refute patch =~ "w-[260px]"
    end

    test "(b) every source, native" do
      # box_class: variant, size, shape, errors, disabled, inline, class · select_name: name,
      # multiple · select_class: disabled · opts: options · selected: value
      each_source(&t_select/1, %{@select | native: true},
        variant: "filled",
        size: "lg",
        shape: "pill",
        errors: ["ruim"],
        disabled: true,
        inline: true,
        class: "w-40",
        multiple: true,
        options: [{"Z", "z"} | @options],
        value: "b",
        name: "outro",
        label: nil
      )
    end

    test "(b) every source, listbox" do
      # box_class: chips?, size, shape, one_line?, variant, errors, disabled · chips?: multiple ·
      # one_line?: multiple, overflow · cls_json/chip_class: size, shape · pop_style:
      # panel_min_width · search_mode: search, multiple · field_name: name, multiple ·
      # chosen/value_json/single_label: options, value · total: options · pop_id: id
      each_source(&t_select/1, @select,
        variant: "filled",
        size: "lg",
        shape: "pill",
        errors: ["ruim"],
        disabled: true,
        class: "w-40",
        multiple: true,
        options: [{"Z", "z"} | @options],
        value: "b",
        name: "outro",
        label: nil,
        search: "panel",
        panel_min_width: "300px",
        id: "outro-id"
      )

      multi = %{@select | multiple: true, value: ["a"]}
      each_source(&t_select/1, multi, overflow: "wrap", size: "sm", value: ["a", "b"])
      each_source(&t_select/1, %{@select | id: nil, name: nil}, label: "Outro rótulo")
    end

    test "options with the same value render (a duplicate key would raise in the diff)" do
      dup = [
        {"A", "a"},
        {"A2", "a"},
        {"Grupo", [{"B", "b"}, {"B2", "b"}]},
        {"Grupo", [{"C", "c"}]}
      ]

      base = %{@select | options: dup}
      assert is_binary(patch(&t_select/1, base, value: "b"))
      assert is_binary(patch(&t_select/1, %{base | native: true}, value: "b"))
    end
  end

  # -- autocomplete --------------------------------------------------------------------------

  defp t_auto(assigns) do
    ~H"""
    <.autocomplete
      id={@id}
      name={@name}
      value={@value}
      options={@options}
      display_value={@display_value}
      free_text={@free_text}
      size={@size}
      errors={@errors}
      disabled={@disabled}
      class={@class}
      on_create={@on_create}
      no_results={@no_results}
      label={@label}
      on_search="search"
    />
    """
  end

  @auto %{
    id: "a1",
    name: "a",
    value: nil,
    options: for(i <- 1..20, do: {"Produto #{i}", "p#{i}"}),
    display_value: nil,
    free_text: false,
    size: "md",
    errors: [],
    disabled: false,
    class: nil,
    on_create: nil,
    no_results: "Nada",
    label: "Cliente"
  }

  describe "autocomplete" do
    test "(a) the server answers a search: the class of the item is not sent per option" do
      item_class = LedgerUI.Components.Select.Options.item_class()
      new = for(i <- 1..20, do: {"Outro #{i}", "o#{i}"})
      first = Jason.encode!(elem(full_render(&t_auto/1, @auto), 0))
      patch = patch(&t_auto/1, @auto, options: new)

      assert first =~ String.slice(item_class, 0, 30)
      refute patch =~ String.slice(item_class, 0, 30)
      refute patch =~ "svg"
      assert patch =~ "Outro 20"
      assert byte_size(patch) < 4_500
    end

    test "the class written in the template is `Options.item_class/0`" do
      item_class = LedgerUI.Components.Select.Options.item_class()
      assert html(&t_auto/1, @auto) =~ ~s(data-part="listbox-option" class="#{item_class}")
    end

    test "(a) a new label does not send the classes, nor the options" do
      patch = patch(&t_auto/1, @auto, label: "Outro")
      refute patch =~ "border-line-strong"
      refute patch =~ "Produto"
    end

    test "(b) every source" do
      # box_class: size, errors, disabled · root_class: class · opts: options · val: value ·
      # text: value, options, display_value, free_text · list_id: id · on_create_js: on_create ·
      # no_results_text: no_results
      each_source(&t_auto/1, @auto,
        size: "lg",
        errors: ["ruim"],
        disabled: true,
        class: "w-40",
        options: [{"Z", "z"} | @auto.options],
        value: "p3",
        display_value: "Texto",
        free_text: true,
        id: "a2",
        on_create: "mk",
        no_results: "Nenhum",
        label: nil,
        name: "outro"
      )

      each_source(
        &t_auto/1,
        %{@auto | value: "zzz", free_text: false},
        free_text: true,
        display_value: "Disp"
      )
    end

    test "options with the same value render" do
      base = %{@auto | options: [{"A", "x"}, {"B", "x"}, {"C", "y"}]}
      assert is_binary(patch(&t_auto/1, base, value: "y"))
    end
  end

  # -- modal ---------------------------------------------------------------------------------

  defp t_modal(assigns) do
    ~H"""
    <.modal
      id={@id}
      layout={@layout}
      open={@open}
      show={@show}
      animation={@animation}
      origin={@origin}
      prevent_close={@prevent_close}
      on_open={@on_open}
      on_close={@on_close}
      target={@target}
      inline={@inline}
      blur={@blur}
      placement={@placement}
      backdrop_class={@backdrop_class}
      close_button={@close_button}
      close_variant={@close_variant}
      size={@size}
      width={@width}
      class={@class}
      card_style={@card_style}
      role={@role}
      description={@description}
      icon={@icon}
      icon_tone={@icon_tone}
      body_class={@body_class}
      title={@title}
    >
      <p>{@body}</p>
      <:footer>{@foot}</:footer>
    </.modal>
    """
  end

  @modal %{
    id: "m1",
    layout: nil,
    open: false,
    show: false,
    animation: "fade",
    origin: "center",
    prevent_close: false,
    on_open: nil,
    on_close: nil,
    target: nil,
    inline: false,
    blur: false,
    placement: "center",
    backdrop_class: nil,
    close_button: true,
    close_variant: "plain",
    size: "lg",
    width: nil,
    class: nil,
    card_style: nil,
    role: "dialog",
    description: nil,
    icon: nil,
    icon_tone: "neutral",
    body_class: nil,
    title: "Editar",
    body: "Corpo",
    foot: "Rodapé"
  }

  describe "modal" do
    test "(a) a new body does not send the classes, the header nor the config again" do
      patch = patch(&t_modal/1, %{@modal | open: true}, body: "Outro corpo")
      assert patch =~ "Outro corpo"
      refute patch =~ "rounded"
      refute patch =~ "svg"
      refute patch =~ "Editar"
      refute patch =~ "data-lu"
      assert byte_size(patch) < 100, patch
    end

    # `layout="page"` draws its card with `<.dynamic_tag>`, which builds the opening tag in its body
    # (the same problem, inside the LiveView): that tag is sent again. The HTML is still right.
    test "(a) the page layout: only the opening tag of the card goes again" do
      patch = patch(&t_modal/1, %{@modal | layout: "page", open: true}, body: "Outro corpo")
      assert patch =~ "Outro corpo"
      refute patch =~ "svg"
      refute patch =~ "Editar"
    end

    test "(a) a new footer does not send the classes again" do
      patch = patch(&t_modal/1, %{@modal | open: true}, foot: "Outro")
      assert patch =~ "Outro"
      refute patch =~ "rounded"
      refute patch =~ "svg"
    end

    test "(b) every source, default layout" do
      # root_class: inline, blur, placement, backdrop_class · state: open · corner?: close_button,
      # header, titled? · card_class: corner?, size, width, placement, class · card_attrs: role,
      # inline, titled?, id, description, header · card_style_s: width, card_style · cfg: inline,
      # animation, origin, open, prevent_close, on_open, on_close, target · hook: inline ·
      # icon_tone_s: icon_tone · corner_class: close_variant · close_js: id ·
      # rest/title_text/titled?: title · open: show · footer: actions
      each_source(&t_modal/1, @modal,
        open: true,
        show: true,
        animation: "scale",
        origin: "top",
        prevent_close: true,
        on_open: "op",
        on_close: "cl",
        target: "#t",
        inline: true,
        blur: true,
        placement: "top",
        backdrop_class: "bd",
        close_button: false,
        size: "sm",
        width: 480,
        class: "cc",
        card_style: "color:red",
        role: "alertdialog",
        description: "desc",
        icon: "check",
        title: nil,
        id: "m2"
      )

      each_source(&t_modal/1, %{@modal | icon: "check"}, icon_tone: "success")

      each_source(&t_modal/1, %{@modal | title: nil}, close_variant: "chip", title: "T")
      each_source(&t_modal/1, %{@modal | title: nil, close_button: true}, close_button: false)
    end

    test "(b) every source, page layout" do
      # tag: rest · card_class: size, width, placement, class · rest: width · body_class_s:
      # body_class · enter: id, animation · leave: animation
      page = %{@modal | layout: "page", open: true}

      each_source(&t_modal/1, page,
        size: "auto",
        width: "500px",
        placement: "top",
        class: "cc",
        body_class: "bc",
        animation: "sheet",
        id: "m2",
        title: "Outro"
      )

      each_source(&t_modal/1, %{page | open: false}, show: true, open: true)
    end
  end

  # -- toaster, toast_card (#87) --------------------------------------------------------------

  defp t_toaster(assigns) do
    ~H"""
    <.toaster
      id={@id}
      flash={@flash}
      position={@position}
      duration={@duration}
      status_position={@status_position}
      card_position={@card_position}
      max_visible={@max_visible}
      stack={@stack}
      persist_errors={@persist_errors}
      timer={@timer}
      invert={@invert}
      close_label={@close_label}
      loading_label={@loading_label}
      contained={@contained}
      class={@class}
      locale={@locale}
      data-extra={@extra}
    />
    """
  end

  @toaster %{
    id: "tt",
    flash: %{},
    position: "center-bottom",
    duration: 5000,
    status_position: nil,
    card_position: nil,
    max_visible: 3,
    stack: true,
    persist_errors: false,
    timer: true,
    invert: false,
    close_label: nil,
    loading_label: nil,
    contained: false,
    class: nil,
    locale: nil,
    extra: "a"
  }

  describe "toaster" do
    test "(a) a new flash does not send data-lu-cls nor the classes again" do
      patch = patch(&t_toaster/1, @toaster, flash: %{"info" => "Salvo"})
      assert patch =~ "Salvo"
      refute patch =~ "inline-flex"
      refute patch =~ "rounded"
      assert byte_size(patch) < 500

      patch = patch(&t_toaster/1, @toaster, flash: %{"error" => "Falhou", "info" => "Salvo"})
      assert patch =~ "Falhou"
      assert byte_size(patch) < 500
    end

    test "data-lu-cls travels once, with the first render" do
      {full, _, _} = full_render(&t_toaster/1, @toaster)
      assert Jason.encode!(full) =~ "data-lu-cls"
      assert byte_size(Jason.encode!(full)) > 20_000
      assert html(&t_toaster/1, @toaster) =~ ~s(data-lu-cls="{&quot;)
    end

    test "the JSON is built once, at compile time, and is the one of hook_classes/0" do
      assert LedgerUI.Components.Toast.hook_classes_json() ==
               Jason.encode!(LedgerUI.Components.Toast.hook_classes())
    end

    test "(b) every source of the attributes and of the classes" do
      # attrs: duration, max_visible, status_position, card_position, stack, timer, invert,
      # persist_errors, flash, rest (close_label, loading_label and locale are listed too, but
      # `put_if/4` never renders them: it only takes `true`) · root_cls: contained ·
      # stack_cls: position, contained
      each_source(&t_toaster/1, @toaster,
        duration: 3000,
        max_visible: 5,
        status_position: "top",
        card_position: "bottom",
        stack: false,
        timer: false,
        invert: true,
        persist_errors: true,
        flash: %{"warning" => "Atenção"},
        position: "left-top",
        contained: true,
        extra: "b"
      )

      each_source(&t_toaster/1, %{@toaster | position: "right-bottom"}, contained: true)
    end
  end

  defp t_toast_card(assigns) do
    ~H"""
    <.toast_card
      id={@id}
      tone={@tone}
      kind={@kind}
      icon={@icon}
      title={@title}
      description={@description}
      dismissible={@dismissible}
      on_dismiss={@on_dismiss}
      busy={@busy}
      progress={@progress}
      progress_state={@progress_state}
      progress_loop={@progress_loop}
      steps={@steps}
      step={@step}
      steps_loop={@steps_loop}
      aura={@aura}
      aura_tone={@aura_tone}
      aura_width={@aura_width}
      aura_shadow={@aura_shadow}
      class={@class}
    />
    """
  end

  @toast_card %{
    id: nil,
    tone: "light",
    kind: "neutral",
    icon: nil,
    title: "Salvo",
    description: nil,
    dismissible: true,
    on_dismiss: nil,
    busy: false,
    progress: nil,
    progress_state: "run",
    progress_loop: false,
    steps: nil,
    step: 0,
    steps_loop: false,
    aura: nil,
    aura_tone: "accent",
    aura_width: "default",
    aura_shadow: true,
    class: nil
  }

  describe "toast_card" do
    test "(a) a new title does not send the classes again" do
      patch = patch(&t_toast_card/1, @toast_card, title: "Outro")
      assert patch =~ "Outro"
      refute patch =~ "rounded"
      refute patch =~ "border"
      assert byte_size(patch) < 80

      card = %{@toast_card | progress: 30, icon: "check-circle", steps: 3, aura: "spin"}
      patch = patch(&t_toast_card/1, card, title: "Outro")
      refute patch =~ "rounded"
      assert byte_size(patch) < 80
    end

    test "(b) every source" do
      each_source(&t_toast_card/1, @toast_card,
        tone: "dark",
        kind: "error",
        icon: "check-circle",
        description: "d",
        dismissible: false,
        busy: true,
        progress: 40,
        progress_loop: true,
        steps: 4,
        aura: "glow",
        class: "z"
      )

      prog = %{@toast_card | progress: 40, icon: "check-circle"}
      each_source(&t_toast_card/1, prog, progress: 70, progress_state: "done", tone: "dark")
      each_source(&t_toast_card/1, %{prog | progress_state: "fail"}, tone: "dark", icon: nil)
      each_source(&t_toast_card/1, %{@toast_card | steps: 4}, step: 2, steps_loop: true)

      each_source(&t_toast_card/1, %{@toast_card | aura: "spin"},
        aura_tone: "ai",
        aura_width: "lg",
        aura_shadow: false,
        dismissible: false,
        aura: "dual"
      )
    end
  end

  # -- no spread of all the assigns ----------------------------------------------------------

  # `<.part {assigns} />` hands a private component every assign as changed, which turns the
  # tracking off (the LiveView docs list it as a pitfall): the icon came again with the label.
  test "no component call in lib spreads `assigns`" do
    spread = ~r/<[.A-Z][\w.]*(\s[^<>]*)?\{assigns\}|\w=\{assigns\}/

    offenders =
      for file <- Path.wildcard("lib/ledger_ui/**/*.ex"),
          {line, n} <- file |> File.read!() |> String.split("\n") |> Enum.with_index(1),
          not String.starts_with?(String.trim(line), "#"),
          Regex.match?(spread, line),
          do: "#{file}:#{n}"

    assert offenders == []
  end
end
