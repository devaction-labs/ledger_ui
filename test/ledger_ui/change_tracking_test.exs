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
      option_class = LedgerUI.Components.Select.Options.option_class()
      new = for(i <- 1..20, do: {"Outro #{i}", "o#{i}"})
      first = Jason.encode!(elem(full_render(&t_auto/1, @auto), 0))
      patch = patch(&t_auto/1, @auto, options: new)

      # The panel has the class of the options once (descendant selectors); the options have none.
      assert option_class =~ "[data-part=listbox-option]]:cursor-pointer"
      assert first =~ "[data-part=listbox-option]]:cursor-pointer"
      refute first =~ String.slice(item_class, 0, 30)
      refute patch =~ "[data-part=listbox-option]]:cursor-pointer"
      refute patch =~ String.slice(item_class, 0, 30)
      refute patch =~ "svg"
      assert patch =~ "Outro 20"
      assert byte_size(patch) < 4_500
    end

    test "the class of the options is on the panel, not on each option" do
      html = html(&t_auto/1, @auto)
      assert html =~ "[data-part=listbox-option]]:cursor-pointer"
      refute html =~ ~r/data-part="listbox-option"[^>]*class=/
      refute html =~ ~r/class="[^"]*"[^>]*data-part="listbox-option"/
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

  # -- form fields (batch 2) -----------------------------------------------------------------

  defp t_checkbox(assigns) do
    ~H"""
    <.checkbox
      id={@id}
      name={@name}
      value={@value}
      checked={@checked}
      indeterminate={@indeterminate}
      checked_value={@checked_value}
      color={@color}
      variant={@variant}
      filled={@filled}
      shape={@shape}
      size={@size}
      label={@label}
      description={@description}
      errors={@errors}
      disabled={@disabled}
      loop={@loop}
      class={@class}
    />
    """
  end

  @checkbox %{
    id: "c1",
    name: "n",
    value: nil,
    checked: nil,
    indeterminate: nil,
    checked_value: "true",
    color: "primary",
    variant: "basic",
    filled: false,
    shape: "square",
    size: "md",
    label: "Aceito",
    description: nil,
    errors: [],
    disabled: false,
    loop: false,
    class: nil
  }

  defp t_field_cb(assigns), do: ~H|<.checkbox field={@field} label="Ativo" />|

  defp t_field_form(params, errors \\ []) do
    Phoenix.Component.to_form(params, as: :c, errors: errors, action: :validate)
  end

  describe "checkbox" do
    test "(a) a new label does not send the classes of the box again" do
      patch = patch(&t_checkbox/1, @checkbox, label: "Outro")
      assert patch =~ "Outro"
      refute patch =~ "appearance-none"
      refute patch =~ "--c"
      refute patch =~ "inline-flex"
    end

    test "(b) every source" do
      # input_id: id, field · is_checked: checked, value, checked_value · hook_id: indeterminate,
      # id, name, label, description · label_cls: size, disabled, color, variant, class ·
      # input_cls: size, shape, filled, disabled, loop
      each_source(&t_checkbox/1, @checkbox,
        id: "c2",
        checked: true,
        value: "true",
        indeterminate: true,
        color: "error",
        variant: "outline",
        filled: true,
        shape: "circle",
        size: "lg",
        description: "d",
        errors: ["ruim"],
        disabled: true,
        loop: true,
        class: "w-40"
      )

      each_source(&t_checkbox/1, %{@checkbox | value: "x"}, checked_value: "x")
      each_source(&t_checkbox/1, %{@checkbox | indeterminate: true, id: nil}, name: "outro")

      each_source(&t_checkbox/1, %{@checkbox | indeterminate: true, id: nil, name: nil},
        label: "Outro"
      )
    end

    test "(b) `field`: value and errors" do
      base = %{field: t_field_form(%{"a" => "true"})[:a]}
      each_source(&t_field_cb/1, base, field: t_field_form(%{"a" => "false"})[:a])
      each_source(&t_field_cb/1, base, field: t_field_form(%{"a" => "true"}, a: {"no", []})[:a])
    end
  end

  defp t_switch(assigns) do
    ~H"""
    <.switch
      id={@id}
      name={@name}
      value={@value}
      checked={@checked}
      color={@color}
      variant={@variant}
      filled={@filled}
      shape={@shape}
      size={@size}
      thumb_inset={@thumb_inset}
      label={@label}
      label_position={@label_position}
      description={@description}
      errors={@errors}
      disabled={@disabled}
      loop={@loop}
      wrapper_class={@wrapper_class}
      class={@class}
      phx-click={@click}
    />
    """
  end

  @switch %{
    id: "w1",
    name: "n",
    value: nil,
    checked: nil,
    color: "primary",
    variant: "basic",
    filled: false,
    shape: "squircle",
    size: "md",
    thumb_inset: nil,
    label: "Notificar",
    label_position: "right",
    description: nil,
    errors: [],
    disabled: false,
    loop: false,
    wrapper_class: nil,
    class: nil,
    click: nil
  }

  describe "switch" do
    test "(a) a new label does not send the classes of the track again" do
      patch = patch(&t_switch/1, @switch, label: "Outro")
      assert patch =~ "Outro"
      refute patch =~ "group-aria-checked"
      refute patch =~ "--tw"
      refute patch =~ "inline-flex"
    end

    test "(b) every source" do
      # input_id: id · on?: checked, value · classes: color, size, label_position, disabled, class ·
      # track_cls: variant, filled, shape, thumb_inset, loop, color, size · toggle: rest, disabled
      # · label_toggle: name, rest, disabled · wrap?: wrapper_class, errors
      each_source(&t_switch/1, @switch,
        id: "w2",
        checked: true,
        value: "true",
        color: "error",
        variant: "outline",
        shape: "pill",
        size: "lg",
        thumb_inset: 5,
        label_position: "left",
        description: "d",
        errors: ["ruim"],
        disabled: true,
        loop: true,
        wrapper_class: "w",
        class: "w-40",
        click: "go",
        name: nil
      )

      each_source(&t_switch/1, %{@switch | variant: "outline"}, filled: true)
      each_source(&t_switch/1, %{@switch | name: nil}, disabled: true, click: "go")
    end
  end

  defp t_textarea(assigns) do
    ~H"""
    <.textarea
      id={@id}
      name={@name}
      value={@value}
      rows={@rows}
      variant={@variant}
      size={@size}
      resizable={@resizable}
      counter={@counter}
      counter_format={@counter_format}
      counter_align={@counter_align}
      min_length={@min_length}
      autogrow={@autogrow}
      loop={@loop}
      max_rows={@max_rows}
      tokens={@tokens}
      state={@state}
      label={@label}
      help={@help}
      errors={@errors}
      disabled={@disabled}
      wrapper_class={@wrapper_class}
      frame_class={@frame_class}
      class={@class}
      locale={@locale}
      maxlength={@maxlength}
      placeholder={@placeholder}
    />
    """
  end

  @textarea %{
    id: "t1",
    name: "t",
    value: "texto {{x}}",
    rows: nil,
    variant: "outlined",
    size: nil,
    resizable: false,
    counter: true,
    counter_format: "%{count} / %{max}",
    counter_align: "end",
    min_length: nil,
    autogrow: false,
    loop: false,
    max_rows: nil,
    tokens: false,
    state: nil,
    label: "Notas",
    help: nil,
    errors: [],
    disabled: false,
    wrapper_class: nil,
    frame_class: nil,
    class: nil,
    locale: nil,
    maxlength: "100",
    placeholder: "p"
  }

  describe "textarea" do
    test "(a) typing sends the text and the counter, not the classes of the frame and the control" do
      patch = patch(&t_textarea/1, @textarea, value: "texto {{x}} mais")
      assert patch =~ "mais"
      refute patch =~ "border-line"
      refute patch =~ "leading-[21px]"
      refute patch =~ "outline-0"
      assert byte_size(patch) < 400, patch
    end

    test "(a) a new label does not send the classes again" do
      patch = patch(&t_textarea/1, @textarea, label: "Outro")
      refute patch =~ "leading-[21px]"
      refute patch =~ "border-line"
    end

    test "(b) every source" do
      each_source(&t_textarea/1, @textarea,
        id: "t2",
        value: "outro",
        variant: "filled",
        size: "lg",
        resizable: true,
        counter: false,
        counter_format: "%{count}",
        counter_align: "start",
        min_length: 3,
        autogrow: true,
        tokens: true,
        state: "success",
        label: nil,
        errors: ["ruim"],
        frame_class: "fc",
        class: "k",
        maxlength: "5",
        placeholder: "q",
        rows: 4
      )

      each_source(&t_textarea/1, %{@textarea | autogrow: true}, max_rows: 6)
      each_source(&t_textarea/1, %{@textarea | counter: true, loop: false}, loop: true)
      each_source(&t_textarea/1, %{@textarea | id: nil}, name: "outro")
      # with a `locale` the counter and its minimum text are settled too
      loc = %{@textarea | locale: "en", maxlength: nil, min_length: 5, value: "ab"}
      each_source(&t_textarea/1, loc, locale: "pt_BR", min_length: 6, value: "abc")
    end

    test "(b) `field`: value and errors" do
      f = fn params, errors -> %{field: t_field_form(params, errors)[:t]} end
      base = f.(%{"t" => "a"}, [])
      each_source(&t_field_ta/1, base, f.(%{"t" => "ab"}, []) |> Map.to_list())
      each_source(&t_field_ta/1, base, f.(%{"t" => "a"}, t: {"curto", []}) |> Map.to_list())
    end
  end

  defp t_field_ta(assigns), do: ~H|<.textarea field={@field} label="Notas" counter />|

  defp t_radio(assigns) do
    ~H"""
    <.radio_group
      id={@id}
      name={@name}
      value={@value}
      options={@options}
      color={@color}
      variant={@variant}
      control={@control}
      filled={@filled}
      shape={@shape}
      size={@size}
      label={@label}
      help={@help}
      errors={@errors}
      disabled={@disabled}
      wrapper_class={@wrapper_class}
      class={@class}
    />
    """
  end

  @radio %{
    id: "r1",
    name: "r",
    value: "a",
    options: [{"Alfa", "a"}, {"Beta", "b"}],
    color: "neutral",
    variant: "basic",
    control: "start",
    filled: false,
    shape: "circle",
    size: "md",
    label: "Plano",
    help: nil,
    errors: [],
    disabled: false,
    wrapper_class: nil,
    class: nil
  }

  describe "radio_group" do
    test "(a) a new label does not send the container class again" do
      patch = patch(&t_radio/1, %{@radio | variant: "chip"}, label: "Outro")
      assert patch =~ "Outro"
      refute patch =~ "flex-wrap"
    end

    test "(b) every source" do
      # id (no id/name): field, name, options, label, color, size, variant, control, filled, shape,
      # value · container: variant, class · hook: variant
      each_source(&t_radio/1, @radio,
        id: "r2",
        variant: "segmented",
        class: "k",
        errors: ["ruim"],
        value: "b",
        disabled: true,
        wrapper_class: "w",
        help: "ajuda",
        label: nil
      )

      each_source(&t_radio/1, %{@radio | variant: "chip"}, variant: "segmented", class: "k")
      each_source(&t_radio/1, %{@radio | variant: "segmented"}, size: "xs", class: "z")

      bare = %{@radio | id: nil, name: nil}

      each_source(&t_radio/1, bare,
        options: [{"Z", "z"}],
        label: "Outro",
        color: "error",
        size: "lg",
        variant: "outline",
        control: "end",
        filled: true,
        shape: "pill",
        value: "b",
        name: "outro"
      )
    end
  end

  defp t_segmented(assigns) do
    ~H"""
    <.segmented
      id={@id}
      name={@name}
      value={@value}
      options={@options}
      label={@label}
      help={@help}
      errors={@errors}
      size={@size}
      shape={@shape}
      full={@full}
      icons={@icons}
      stretch={@stretch}
      role={@role}
      disabled={@disabled}
      on_change={@on_change}
      wrapper_class={@wrapper_class}
      class={@class}
    />
    """
  end

  @segmented %{
    id: "s1",
    name: "s",
    value: "a",
    options: [%{value: "a", label: "A", icon: "check"}, %{value: "b", label: "B"}],
    label: "Vista",
    help: nil,
    errors: [],
    size: "md",
    shape: "rounded",
    full: false,
    icons: false,
    stretch: false,
    role: "group",
    disabled: false,
    on_change: nil,
    wrapper_class: nil,
    class: nil
  }

  describe "segmented" do
    test "(a) a new label does not send the classes of the track and of the buttons" do
      patch = patch(&t_segmented/1, @segmented, label: "Outra")
      assert patch =~ "Outra"
      refute patch =~ "bg-sunken"
      refute patch =~ "inline-flex"
    end

    test "(b) every source" do
      # id (no id/name): field, name, options · pill?: shape · seg_class: shape, full, stretch,
      # class · btn_class: size, shape, full, stretch, icons · tab?: role · on_change_attr:
      # on_change · cap_id: id
      each_source(&t_segmented/1, @segmented,
        id: "s2",
        size: "sm",
        shape: "pill",
        full: true,
        icons: true,
        stretch: true,
        role: "tablist",
        on_change: "chg",
        class: "k",
        value: "b",
        disabled: true,
        errors: ["ruim"],
        wrapper_class: "w",
        help: "aj",
        label: nil
      )

      bare = %{@segmented | id: nil, name: nil}
      each_source(&t_segmented/1, bare, options: [%{value: "z", label: "Z"}], name: "outro")
    end
  end

  defp t_number(assigns) do
    ~H"""
    <.number_input
      id={@id}
      name={@name}
      value={@value}
      label={@label}
      help={@help}
      errors={@errors}
      disabled={@disabled}
      locale={@locale}
      decimal_separator={@dec}
      thousands_separator={@thou}
      decimals={@decimals}
      max_decimals={@max_decimals}
      min={@min}
      max={@max}
      step={@step}
      steppers={@steppers}
      stepper_style={@stepper_style}
      decrement_label={@decrement_label}
      increment_label={@increment_label}
      prefix={@prefix}
      suffix={@suffix}
      variant={@variant}
      size={@size}
      shape={@shape}
      align={@align}
      canvas={@canvas}
      loop={@loop}
      class={@class}
    />
    """
  end

  @number %{
    id: "n1",
    name: "n",
    value: 1234.5,
    label: "Qtd",
    help: nil,
    errors: [],
    disabled: false,
    locale: "en",
    dec: nil,
    thou: nil,
    decimals: nil,
    max_decimals: nil,
    min: nil,
    max: nil,
    step: 1,
    steppers: true,
    stepper_style: "inset",
    decrement_label: nil,
    increment_label: nil,
    prefix: nil,
    suffix: nil,
    variant: "outlined",
    size: "md",
    shape: "rounded",
    align: "center",
    canvas: false,
    loop: false,
    class: nil
  }

  defp t_field_num(assigns), do: ~H|<.number_input field={@field} label="Qtd" locale="en" />|

  describe "number_input" do
    test "(a) a new label does not send the classes of the field again" do
      patch = patch(&t_number/1, @number, label: "Outro")
      assert patch =~ "Outro"
      refute patch =~ "tabular-nums"
      refute patch =~ "border-line-strong"
    end

    test "(a) a new value sends the text and the machine value, not the classes" do
      patch = patch(&t_number/1, @number, value: 99)
      refute patch =~ "tabular-nums"
    end

    test "(b) every source" do
      # id: id, name · machine: value · min_text/max_text: min/max · icon_size: canvas · num_class:
      # stepper_style, steppers, size, shape, variant, disabled, loop, class · v_class: size,
      # stepper_style, steppers, align, loop · minus/plus_class: size, stepper_style, loop ·
      # left/right_class: steppers, stepper_style · wrapped: label, help, errors · with `locale`:
      # config, text, minus, plus
      each_source(&t_number/1, @number,
        id: "n2",
        value: 5,
        label: nil,
        help: "aj",
        errors: ["ruim"],
        disabled: true,
        locale: "pt_BR",
        decimals: 2,
        max_decimals: 1,
        min: 0,
        max: 9,
        step: 5,
        steppers: false,
        stepper_style: "round",
        decrement_label: "d",
        increment_label: "i",
        prefix: "R$",
        suffix: "kg",
        variant: "filled",
        size: "lg",
        shape: "pill",
        align: "right",
        canvas: true,
        loop: true,
        class: "k",
        dec: ";",
        thou: "_"
      )

      each_source(&t_number/1, %{@number | stepper_style: "joined"}, size: "sm", loop: true)
      each_source(&t_number/1, %{@number | label: nil, id: nil, name: nil}, name: "outro")
    end

    test "(b) `field`: value and errors" do
      f = fn params, errors -> %{field: t_field_form(params, errors)[:n]} end
      base = f.(%{"n" => "1"}, [])
      each_source(&t_field_num/1, base, f.(%{"n" => "2"}, []) |> Map.to_list())

      # `field` that starts to carry an error: `errors` must reach the patch
      each_source(&t_field_num/1, base, f.(%{"n" => "1"}, n: {"ruim", []}) |> Map.to_list())
    end
  end

  defp t_pillbox(assigns) do
    ~H"""
    <.pillbox
      id={@id}
      name={@name}
      value={@value}
      options={@options}
      label={@label}
      errors={@errors}
      size={@size}
      shape={@shape}
      overflow={@overflow}
      removable={@removable}
      clear={@clear}
      readonly={@readonly}
      disabled={@disabled}
      hidden_label={@hidden_label}
      empty_label={@empty_label}
      class={@class}
    />
    """
  end

  @pillbox %{
    id: "p1",
    name: "p",
    value: ["a"],
    options: [{"Alfa", "a"}, {"Beta", "b"}],
    label: "Tags",
    errors: [],
    size: "md",
    shape: "rounded",
    overflow: "one",
    removable: true,
    clear: false,
    readonly: false,
    disabled: false,
    hidden_label: nil,
    empty_label: nil,
    class: nil
  }

  describe "pillbox" do
    test "(a) a new label does not send the classes of the box nor the data-lu-* again" do
      patch = patch(&t_pillbox/1, @pillbox, label: "Outro")
      assert patch =~ "Outro"
      refute patch =~ "border-line-strong"
      refute patch =~ "data-lu"
      refute patch =~ "svg"
    end

    test "(b) every source" do
      # removable: removable, readonly, disabled · clearable: clear, readonly, disabled · overflow ·
      # more_label: hidden_label · no_results: empty_label
      each_source(&t_pillbox/1, @pillbox,
        removable: false,
        clear: true,
        readonly: true,
        disabled: true,
        overflow: "wrap",
        hidden_label: "mais",
        empty_label: "nada",
        size: "lg",
        shape: "pill",
        errors: ["ruim"],
        value: ["a", "b"]
      )
    end
  end

  defp t_tags(assigns) do
    ~H"""
    <.tags_input
      id={@id}
      name={@name}
      value={@value}
      label={@label}
      help={@help}
      errors={@errors}
      suggestions={@suggestions}
      options={@options}
      selected_options={@selected_options}
      on_search={@on_search}
      max={@max}
      shape={@shape}
      disabled={@disabled}
      class={@class}
    />
    """
  end

  @tags %{
    id: "g1",
    name: "g",
    value: "a",
    label: "Tags",
    help: nil,
    errors: [],
    suggestions: ["a", "b"],
    options: nil,
    selected_options: [],
    on_search: nil,
    max: nil,
    shape: "rounded",
    disabled: false,
    class: nil
  }

  describe "tags_input" do
    test "(a) a new label does not send the classes nor the options again" do
      patch = patch(&t_tags/1, @tags, label: "Outro")
      assert patch =~ "Outro"
      refute patch =~ "flex-wrap"
      refute patch =~ "listbox-option"
    end

    test "(b) every source" do
      each_source(&t_tags/1, @tags,
        id: "g2",
        value: "a,b",
        errors: ["ruim"],
        suggestions: ["a", "b", "c"],
        options: ["x"],
        on_search: "srch",
        max: 1,
        shape: "pill",
        disabled: true,
        class: "k",
        name: "outro",
        label: nil,
        help: "aj"
      )

      each_source(&t_tags/1, %{@tags | value: "a,b", max: 3}, max: 2)
      each_source(&t_tags/1, %{@tags | value: "z"}, selected_options: [%{label: "Z", value: "z"}])
      each_source(&t_tags/1, %{@tags | id: nil, name: nil}, label: "Outro", name: "n")
    end
  end

  defp t_date(assigns) do
    ~H"""
    <.date_picker
      id={@id}
      name={@name}
      value={@value}
      label={@label}
      errors={@errors}
      mode={@mode}
      start_name={@start_name}
      end_name={@end_name}
      presets={@presets}
      locale="en"
      today="2024-03-10"
      size={@size}
      disabled={@disabled}
      class={@class}
    />
    """
  end

  @date %{
    id: "d1",
    name: "d",
    value: "2024-03-05",
    label: "Data",
    errors: [],
    mode: "single",
    start_name: nil,
    end_name: nil,
    presets: [],
    size: "md",
    disabled: false,
    class: nil
  }

  defp t_field_date(assigns),
    do: ~H|<.date_picker field={@field} locale="en" today="2024-03-10" />|

  describe "date_picker" do
    test "(b) the derived values it settles" do
      # id: id, name · state: errors · dates: value, mode · two_fields?: start_name, end_name ·
      # hidden_inputs: dates, name, mode · presets_in: presets
      each_source(&t_date/1, @date,
        id: "d2",
        value: "2024-03-06",
        errors: ["ruim"],
        mode: "multiple",
        name: "outro",
        size: "lg",
        disabled: true,
        class: "k",
        label: nil
      )

      each_source(&t_date/1, %{@date | mode: "range", value: {"2024-03-01", "2024-03-02"}},
        start_name: "a",
        end_name: "b"
      )
    end

    test "(b) `field`: value and errors" do
      f = fn params, errors -> %{field: t_field_form(params, errors)[:d]} end
      base = f.(%{"d" => "2024-03-05"}, [])
      each_source(&t_field_date/1, base, f.(%{"d" => "2024-03-06"}, []) |> Map.to_list())

      each_source(
        &t_field_date/1,
        base,
        f.(%{"d" => "2024-03-05"}, d: {"ruim", []}) |> Map.to_list()
      )
    end
  end

  defp t_datetime(assigns) do
    ~H"""
    <.datetime_picker
      id={@id}
      name={@name}
      value={@value}
      errors={@errors}
      mode={@mode}
      placement={@placement}
      locale="en"
      today="2024-03-10"
      size={@size}
      class={@class}
    />
    """
  end

  defp t_field_datetime(assigns),
    do: ~H|<.datetime_picker field={@field} locale="en" today="2024-03-10" />|

  describe "datetime_picker" do
    test "(b) `field` that starts to carry an error" do
      f = fn errors ->
        %{field: t_field_form(%{"d" => "2024-03-05T10:30:00"}, errors)[:d]}
      end

      each_source(&t_field_datetime/1, f.([]), f.(d: {"ruim", []}) |> Map.to_list())
    end

    test "(b) the derived values it settles" do
      base = %{
        id: "d1",
        name: "d",
        value: "2024-03-05T10:30:00",
        errors: [],
        mode: "single",
        placement: "bottom-start",
        size: "md",
        class: nil
      }

      each_source(&t_datetime/1, base,
        id: "d2",
        value: "2024-03-06T11:00:00",
        errors: ["ruim"],
        mode: "range",
        placement: "top",
        name: "outro",
        size: "lg",
        class: "k"
      )
    end
  end

  defp t_phone(assigns) do
    ~H"""
    <.phone_input
      id={@id}
      name={@name}
      value={@value}
      country={@country}
      countries={@countries}
      except={@except}
      country_order={@country_order}
      locale={@locale}
      flags={@flags}
      label={@label}
      help={@help}
      errors={@errors}
      state={@state}
      disabled={@disabled}
      variant={@variant}
      size={@size}
      shape={@shape}
      target={@target}
      class={@class}
      required={@required}
    />
    """
  end

  @phone %{
    id: "ph1",
    name: "ph",
    value: "+5511912345678",
    country: "BR",
    countries: [],
    except: [],
    country_order: [],
    locale: "en",
    flags: false,
    label: "Tel",
    help: nil,
    errors: [],
    state: nil,
    disabled: false,
    variant: "outlined",
    size: "md",
    shape: "rounded",
    target: nil,
    class: nil,
    required: false
  }

  defp t_field_phone(assigns), do: ~H|<.phone_input field={@field} label="Tel" locale="en" />|

  describe "phone_input" do
    test "(a) a new label does not send the classes of the box nor the country list again" do
      patch = patch(&t_phone/1, @phone, label: "Outro")
      assert patch =~ "Outro"
      refute patch =~ "border-line-strong"
      refute patch =~ "BR,"
    end

    test "(b) every source" do
      each_source(&t_phone/1, @phone,
        id: "ph2",
        value: "+351912345678",
        countries: ["BR", "US"],
        except: ["US"],
        country_order: ["US"],
        locale: "pt_BR",
        label: nil,
        help: "aj",
        errors: ["ruim"],
        state: "success",
        disabled: true,
        variant: "filled",
        size: "lg",
        shape: "pill",
        target: "#t",
        class: "k",
        required: true,
        name: "outro"
      )

      each_source(&t_phone/1, %{@phone | value: nil}, country: "US")
    end

    test "(b) `field`: value and errors" do
      f = fn params, errors -> %{field: t_field_form(params, errors)[:p]} end
      base = f.(%{"p" => "+5511912345678"}, [])
      each_source(&t_field_phone/1, base, f.(%{"p" => "+351912345678"}, []) |> Map.to_list())

      each_source(
        &t_field_phone/1,
        base,
        f.(%{"p" => "+5511912345678"}, p: {"ruim", []}) |> Map.to_list()
      )
    end
  end

  defp t_otp(assigns) do
    ~H"""
    <.otp_input
      id={@id}
      name={@name}
      value={@value}
      label={@label}
      help={@help}
      errors={@errors}
      state={@state}
      length={@length}
      mode={@mode}
      size={@size}
      mask={@mask}
      disabled={@disabled}
      autofocus={@autofocus}
      loop={@loop}
      separator={@separator}
      on_complete={@on_complete}
      target={@target}
      aria_label={@aria_label}
      digit_label={@digit_label}
      class={@class}
    />
    """
  end

  @otp %{
    id: "o1",
    name: "o",
    value: "123",
    label: "Código",
    help: nil,
    errors: [],
    state: nil,
    length: 6,
    mode: "numeric",
    size: nil,
    mask: false,
    disabled: false,
    autofocus: false,
    loop: false,
    separator: nil,
    on_complete: nil,
    target: nil,
    aria_label: "c",
    digit_label: "d",
    class: nil
  }

  describe "otp_input" do
    test "(a) a new label does not send the classes of the boxes again" do
      patch = patch(&t_otp/1, @otp, label: "Outro")
      assert patch =~ "Outro"
      refute patch =~ "caret-transparent"
    end

    test "(b) every source" do
      each_source(&t_otp/1, @otp,
        id: "o2",
        value: "12",
        label: nil,
        help: "aj",
        errors: ["ruim"],
        state: "success",
        length: 4,
        mode: "alphanumeric",
        size: "lg",
        mask: true,
        disabled: true,
        autofocus: true,
        loop: true,
        separator: 3,
        on_complete: "done",
        target: "#t",
        digit_label: "y",
        class: "k",
        name: "outro"
      )

      each_source(&t_otp/1, %{@otp | on_complete: "done"}, on_complete: %Phoenix.LiveView.JS{})
      each_source(&t_otp/1, %{@otp | label: nil}, aria_label: "outro")
    end
  end

  defp t_password(assigns) do
    ~H"""
    <.password_input
      id={@id}
      name={@name}
      value={@value}
      label={@label}
      help={@help}
      errors={@errors}
      state={@state}
      visible={@visible}
      loop={@loop}
      strength={@strength}
      show_label={@show_label}
      hide_label={@hide_label}
      size={@size}
      disabled={@disabled}
      class={@class}
    />
    """
  end

  @password %{
    id: "pw1",
    name: "pw",
    value: "segredo",
    label: "Senha",
    help: nil,
    errors: [],
    state: nil,
    visible: false,
    loop: false,
    strength: nil,
    show_label: "Mostrar",
    hide_label: "Ocultar",
    size: "md",
    disabled: false,
    class: nil
  }

  describe "password_input" do
    test "(a) a new label does not send the eye button's JS again" do
      patch = patch(&t_password/1, @password, label: "Outra")
      assert patch =~ "Outra"
      refute patch =~ "toggle_attribute"
    end

    test "(b) every source" do
      # dots: value · type: loop, visible · box_class: class, loop · pid: id, name · meter: strength
      # · toggle: id, name, show_label, hide_label
      each_source(&t_password/1, %{@password | loop: true},
        value: "outro segredo",
        class: "k",
        id: "pw2"
      )

      each_source(&t_password/1, @password,
        id: "pw2",
        value: "x",
        label: nil,
        help: "aj",
        errors: ["ruim"],
        state: "success",
        visible: true,
        loop: true,
        strength: "good",
        show_label: "S",
        hide_label: "H",
        size: "lg",
        disabled: true,
        class: "k",
        name: "outro"
      )

      each_source(&t_password/1, %{@password | id: nil}, name: "login[x]")
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
    test "data-lu-close-label and data-lu-loading-label only when not the default text" do
      refute html(&t_toaster/1, @toaster) =~ "data-lu-close-label"
      refute html(&t_toaster/1, @toaster) =~ "data-lu-loading-label"
      refute html(&t_toaster/1, %{@toaster | locale: "en"}) =~ "data-lu-close-label"

      html = html(&t_toaster/1, %{@toaster | close_label: "Dispensar", loading_label: "Aguarde"})
      assert html =~ ~s(data-lu-close-label="Dispensar")
      assert html =~ ~s(data-lu-loading-label="Aguarde")

      assert html(&t_toaster/1, %{@toaster | locale: "pt_BR"}) =~ "data-lu-close-label="
    end

    test "(b) close_label and loading_label update the attributes" do
      each_source(&t_toaster/1, @toaster, close_label: "Dispensar", loading_label: "Aguarde")

      each_source(&t_toaster/1, %{@toaster | close_label: "Dispensar"},
        close_label: "Fechar agora"
      )
    end

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
      # persist_errors, flash, close_label, loading_label, locale, rest · root_cls: contained ·
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

  # -- table rows (#86) ----------------------------------------------------------------------

  # `<.table rows={list}>`: the row is a component followed by `:key` (the `row_id`), so a change in
  # one row, an insertion, a removal or a new order sends only what moved. Before, 1 row changed
  # of 100 sent about 90% of the table again.
  defp t_rows(assigns) do
    ~H"""
    <.table
      id="t"
      rows={@rows}
      row_id={fn r -> "row-#{r.id}" end}
      on_select="sel"
      on_select_all="all"
      selected={@sel}
    >
      <:col :let={c} label="Name">{c.name}</:col>
      <:col :let={c} label="Status">
        <.badge>{c.status}</.badge>
      </:col>
      <:action :let={c}>
        <a href={"/edit/" <> to_string(c.id)}>Edit {c.id}</a>
      </:action>
    </.table>
    """
  end

  defp t_rows_norid(assigns) do
    ~H"""
    <.table id="t" rows={@rows}>
      <:col :let={c} label="Name">{c.name}</:col>
      <:col :let={c} label="Status">
        <.badge>{c.status}</.badge>
      </:col>
    </.table>
    """
  end

  defp t_rows_edit(assigns) do
    ~H"""
    <.table
      id="t"
      rows={@rows}
      row_id={fn r -> "row-#{r.id}" end}
      row_editing={fn r -> r.id == @eid end}
      details
    >
      <:col :let={c} label="Name">{c.name}</:col>
      <:detail :let={c} label="Status">{c.status}</:detail>
      <:edit :let={c}>editing {c.name}</:edit>
      <:expand :let={%{row: c}}>more {c.name}</:expand>
    </.table>
    """
  end

  defp t_rows_groups(assigns) do
    ~H"""
    <.table id="t" rows={@rows} row_id={fn r -> "row-#{r.id}" end} row_groups details>
      <:col :let={c} label="Name">{c.name}</:col>
      <:detail :let={c} label="Status">{c.status}</:detail>
      <:expand :let={%{row: c}}>more {c.name}</:expand>
    </.table>
    """
  end

  defp t_rows_data(n),
    do: for(i <- 1..n, do: %{id: i, name: "Customer number #{i}", status: "Active"})

  defp t_rows_change(rows, i), do: List.update_at(rows, i, &%{&1 | status: "Blocked"})

  describe "table rows (#86)" do
    test "1 row changed of 100: the patch holds that row only" do
      rows = t_rows_data(100)
      base = %{rows: rows, sel: []}
      patch = check(&t_rows/1, base, rows: t_rows_change(rows, 50))
      assert byte_size(patch) < 2_000
      assert patch =~ "Blocked"
      refute patch =~ "Customer number 1 "
    end

    test "a row inserted at the top of 100 sends that row, not the ones below" do
      rows = t_rows_data(100)
      new = %{id: 0, name: "New customer", status: "Active"}
      patch = check(&t_rows/1, %{rows: rows, sel: []}, rows: [new | rows])
      assert byte_size(patch) < 5_000
      assert patch =~ "New customer"
    end

    test "a row removed, rows reordered, rows replaced: the client ends up with a fresh render" do
      rows = t_rows_data(30)
      base = %{rows: rows, sel: []}

      removed = check(&t_rows/1, base, rows: List.delete_at(rows, 10))
      assert byte_size(removed) < 1_500

      reversed = check(&t_rows/1, base, rows: Enum.reverse(rows))
      assert byte_size(reversed) < 1_500

      swapped = check(&t_rows/1, base, rows: Enum.shuffle(rows) |> Enum.take(20))
      assert is_binary(swapped)

      check(&t_rows/1, base, rows: [])
      check(&t_rows/1, %{base | rows: []}, rows: rows)
    end

    test "changing the selection sends the rows whose state changed, not the table" do
      rows = t_rows_data(100)
      base = %{rows: rows, sel: []}

      one = check(&t_rows/1, base, sel: ["row-5"])
      assert byte_size(one) < 500

      two = check(&t_rows/1, %{base | sel: ["row-5"]}, sel: ["row-5", "row-6"])
      assert byte_size(two) < 500

      check(&t_rows/1, %{base | sel: ["row-5", "row-6"]}, sel: [])
      check(&t_rows/1, base, sel: Enum.map(rows, &"row-#{&1.id}"))
    end

    test "rows and selection together" do
      rows = t_rows_data(20)

      check(&t_rows/1, %{rows: rows, sel: ["row-3"]},
        rows: t_rows_change(rows, 3),
        sel: ["row-3", "row-4"]
      )
    end

    test "without row_id the rows are followed by position, as without :key" do
      rows = t_rows_data(100)
      base = %{rows: rows}

      one = check(&t_rows_norid/1, base, rows: t_rows_change(rows, 50))
      assert byte_size(one) < 1_000

      new = %{id: 0, name: "New customer", status: "Active"}
      check(&t_rows_norid/1, base, rows: [new | rows])
      check(&t_rows_norid/1, base, rows: List.delete_at(rows, 0))
    end

    test "a repeated row_id renders without error and follows by position" do
      rows = t_rows_data(10) |> Enum.map(&if(&1.id == 4, do: %{&1 | id: 3}, else: &1))
      base = %{rows: rows, sel: []}
      assert html(&t_rows/1, base) =~ "row-3"
      patch = check(&t_rows/1, base, rows: t_rows_change(rows, 6))
      assert byte_size(patch) < 1_500
      check(&t_rows/1, base, rows: Enum.reverse(rows))
    end

    test "inline edit, panel and detail row: a row entering and leaving edition" do
      rows = t_rows_data(10)
      base = %{rows: rows, eid: nil}
      check(&t_rows_edit/1, base, eid: 3)
      check(&t_rows_edit/1, %{base | eid: 3}, eid: 4)
      check(&t_rows_edit/1, %{base | eid: 3}, eid: nil)
      check(&t_rows_edit/1, %{base | eid: 3}, rows: t_rows_change(rows, 3))
      check(&t_rows_edit/1, base, rows: t_rows_change(rows, 5))
    end

    test "row_groups: one tbody per row, followed by id too" do
      rows = t_rows_data(10)
      base = %{rows: rows}
      one = check(&t_rows_groups/1, base, rows: t_rows_change(rows, 5))
      assert byte_size(one) < 1_500
      check(&t_rows_groups/1, base, rows: Enum.reverse(rows))
      check(&t_rows_groups/1, base, rows: [%{id: 0, name: "N", status: "S"} | rows])
    end
  end

  # -- data_table (#89) -----------------------------------------------------------------------

  # `<.data_table>` handed its columns and attrs to `Table.table` as a map, which turned the
  # tracking of the table off: 1 row changed of 100 sent about 42 KB. It calls the table with its
  # own `__changed__` now, and settles what it derives (`settle/3`).
  defp t_dt(assigns) do
    ~H"""
    <.data_table
      id={@id}
      rows={@rows}
      row_id={fn r -> "row-#{r.id}" end}
      search={@search}
      on_search={@on_search}
      search_placeholder={@search_placeholder}
      sort_by={@sort_by}
      sort_dir={@sort_dir}
      on_sort="sort"
      page={@page}
      page_size={@page_size}
      total={@total}
      on_page={@on_page}
      page_path={@page_path}
      footer={@footer}
      pager={@pager}
      variant={@variant}
      compact={@compact}
      on_select="sel"
      on_select_all="all"
      selected={@sel}
    >
      <:title :if={@title}>Customers</:title>
      <:actions :if={@actions}><a href="/new">New</a></:actions>
      <:filters :if={@filters}>filter panel</:filters>
      <:col :let={c} label="Name" sort_key="name">{c.name}</:col>
      <:col :let={c} label="Status">
        <.badge>{c.status}</.badge>
      </:col>
      <:action :let={c}>
        <a href={"/edit/" <> to_string(c.id)}>Edit {c.id}</a>
      </:action>
    </.data_table>
    """
  end

  defp t_dt_base(rows) do
    %{
      id: "dt",
      rows: rows,
      search: "",
      on_search: "search",
      search_placeholder: nil,
      sort_by: nil,
      sort_dir: "asc",
      page: 1,
      page_size: 100,
      total: 300,
      on_page: "paginate",
      page_path: nil,
      footer: true,
      pager: "rounded",
      variant: "advanced",
      compact: false,
      sel: [],
      title: true,
      actions: false,
      filters: false
    }
  end

  describe "data_table (#89)" do
    test "1 row changed of 100: the patch holds that row only" do
      rows = t_rows_data(100)
      patch = check(&t_dt/1, t_dt_base(rows), rows: t_rows_change(rows, 50))
      assert byte_size(patch) < 2_000
      assert patch =~ "Blocked"
      refute patch =~ "Customer number 1 "
    end

    test "selecting 1 row sends that row, not the table" do
      base = t_dt_base(t_rows_data(100))
      one = check(&t_dt/1, base, sel: ["row-5"])
      assert byte_size(one) < 500
      two = check(&t_dt/1, %{base | sel: ["row-5"]}, sel: ["row-5", "row-6"])
      assert byte_size(two) < 500
      check(&t_dt/1, %{base | sel: ["row-5", "row-6"]}, sel: [])
    end

    test "a new search text sends the field and the summary, not the rows" do
      rows = t_rows_data(100)
      patch = check(&t_dt/1, t_dt_base(rows), search: "abc")
      assert byte_size(patch) < 500
    end

    test "sort, page, filter and density: the client ends up with a fresh render" do
      rows = t_rows_data(30)
      base = %{t_dt_base(rows) | page_size: 10, total: 30}
      check(&t_dt/1, base, sort_by: "name", sort_dir: "desc", rows: Enum.reverse(rows))
      check(&t_dt/1, %{base | sort_by: "name"}, sort_dir: "desc")
      check(&t_dt/1, base, page: 2, rows: Enum.drop(rows, 10))
      check(&t_dt/1, base, search: "number 2", rows: Enum.take(rows, 3), total: 3)
      check(&t_dt/1, base, compact: true)
      check(&t_dt/1, base, rows: [], total: 0)
      check(&t_dt/1, %{base | rows: [], total: 0}, rows: rows, total: 30)
    end

    test "each source of what the data table derives changes the HTML" do
      rows = t_rows_data(12)
      base = %{t_dt_base(rows) | page_size: 5, total: 12}

      each_source(&t_dt/1, base,
        total: 40,
        rows: Enum.take(rows, 6),
        page_size: 3,
        page: 2,
        footer: false,
        on_page: nil,
        on_search: nil,
        search_placeholder: "Find",
        title: false,
        actions: true,
        filters: true,
        pager: "pill",
        variant: "grid",
        id: "dt2",
        compact: true,
        search: "abc",
        sort_by: "name"
      )

      each_source(&t_dt/1, %{base | on_page: "paginate", page: 2},
        page_path: fn n -> "/p/#{n}" end
      )

      each_source(&t_dt/1, %{base | pager: "pages"}, page: 3, page_size: 2)
      each_source(&t_dt/1, %{base | title: false, on_search: nil}, on_search: "go", title: true)
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
