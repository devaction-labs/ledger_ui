defmodule LedgerUI.Components.TextEditor do
  @moduledoc """
  Rich text editor on a plain `contenteditable` (bold, italic, underline, strike, quote, code,
  headings, lists, sub/superscript, indent, text direction, size, font, colors, alignment, links
  and clean), plus its compact `variant="comment"` form for threads.

      <.text_editor field={@form[:body]} placeholder="Escreva..." />
      <.text_editor name="note" toolbar={[~w(bold italic underline), ~w(list-ordered list-bullet)]} />
      <.text_editor name="post" filled content_class="h-72" />

      <.text_editor name="comment" variant="comment" on_submit="comment"
        mentions={[%{handle: "juliana-moraes", label: "Juliana Moraes"}]}
        placeholder="Escreva um comentario" />

  The HTML is submitted through a hidden input named like the field, and each edit fires a
  bubbling `input` event, so `phx-change` runs. The HTML given to the editor is cleaned on the
  server by `sanitize/2` (and again in the browser, as is pasted HTML): only formatting tags and
  safe links stay. **Sanitize what you store as well.** A value sent by the server replaces the
  text; the same value echoed back does not touch it.

  `slash` opens a menu of blocks when "/" is typed at the start of a word; `variables` adds the
  placeholders of a template (`{cliente}` is drawn as a chip and goes to the server as plain
  text); the `:ai` slot is a button at the end of the toolbar (`on_ai` is pushed with the HTML and
  the selected text; answer with `insert_html/3`); `footer` draws a bar with a hint and the word
  count. In a comment, "@" opens the list of `mentions` (chips sent as `@handle`) and
  Ctrl/Cmd+Enter submits (`on_submit`).

  Three toolbar buttons are opt-in: `mark` (highlight), `variable` and `image`. `image` asks for
  the address and description, or, with `on_image`, pushes the event so the app can upload the
  file and answer with `insert_image/4`.

  The behaviour lives in the `LedgerUI.TextEditor` hook (`text_editor.js`); the editor needs a
  stable `id` (from `field` or `name`).

  `text_editor_content/1` shows saved HTML read-only, in the editor's type.
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Form
  import LedgerUI.Components.Input, only: [input: 1]
  import LedgerUI.Components.Button, only: [button: 1]
  import LedgerUI.Components.Typography, only: [kbd: 1]

  # --- look (Tailwind utilities only). The editable area keeps the browser's own type for
  # headings, lists, quotes and code (what the design shows), which Tailwind's reset removes.
  @root "overflow-hidden rounded-lg border border-line-strong bg-panel"
  @root_compact "overflow-hidden rounded-[12px] border border-line-strong bg-panel"
  @body_compact "min-h-[90px] px-3.5 py-3 text-sm leading-[22px] overflow-auto outline-0"
  @tool_compact "grid h-7 w-[30px] cursor-pointer place-items-center rounded-[7px] border-0 bg-transparent text-ink-2 " <>
                  "hover:bg-selected hover:text-ink aria-pressed:bg-selected aria-pressed:text-ink"
  @tool_loop "animate-[mo-tbon_6s_infinite] [animation-delay:var(--dl)]"
  @prose "[&_h1]:my-[.67em] [&_h1]:text-[2em] [&_h1]:font-bold [&_h2]:my-[.83em] [&_h2]:text-[1.5em] [&_h2]:font-bold " <>
           "[&_h3]:my-[1em] [&_h3]:text-[1.17em] [&_h3]:font-bold [&_h4]:my-[1.33em] [&_h4]:font-bold " <>
           "[&_h5]:my-[1.67em] [&_h5]:text-[.83em] [&_h5]:font-bold [&_h6]:my-[2.33em] [&_h6]:text-[.67em] [&_h6]:font-bold " <>
           "[&_p]:my-[1em] [&_ul]:my-[1em] [&_ul]:list-disc [&_ul]:pl-10 [&_ol]:my-[1em] [&_ol]:list-decimal [&_ol]:pl-10 " <>
           "[&_blockquote]:mx-10 [&_blockquote]:my-[1em] [&_pre]:my-[1em] [&_pre]:[font-family:monospace] [&_code]:[font-family:monospace] " <>
           "[&_sub]:static [&_sub]:align-sub [&_sub]:text-[smaller] [&_sub]:leading-[inherit] [&_sup]:static [&_sup]:align-super [&_sup]:text-[smaller] [&_sup]:leading-[inherit] " <>
           "[&_a]:text-accent-content [&_a]:underline [&_img]:inline"
  # the compact frame has no paragraph margins (the canvas draws a bare `div`)
  @prose_compact String.replace(@prose, "[&_p]:my-[1em] ", "[&_p]:my-0 ")
  @body "px-4 py-3.5 text-[14.5px] leading-[22px] overflow-auto outline-0"
  @placeholder "pointer-events-none absolute top-0 left-0 px-4 py-3.5 text-[14.5px] leading-[22px] text-muted"
  @toolbar "flex flex-wrap items-center gap-0.5 border-b border-line bg-tray p-1.5"
  @tool "grid size-[30px] cursor-pointer place-items-center rounded-[7px] border-0 bg-transparent text-ink-2 " <>
          "hover:bg-selected hover:text-ink aria-pressed:bg-selected aria-pressed:text-ink"
  @footer "flex items-center gap-2 border-t border-line py-2 pr-2 pl-3"
  @btn_icon "inline-flex size-[30px] cursor-pointer items-center justify-center rounded-[8px] border border-transparent bg-transparent text-ink-2 hover:bg-hover hover:text-ink " <>
              "focus-visible:shadow-[0_0_0_3px_var(--lu-focus)] focus-visible:outline-none disabled:cursor-not-allowed disabled:opacity-45 [&_svg]:size-4"
  @pop "fixed z-[60] min-w-[260px] rounded-lg border border-line bg-panel p-3.5 shadow-md"
  @menu "fixed z-[60] max-h-56 min-w-[220px] overflow-auto rounded-lg border border-line bg-panel p-[5px] shadow-md"
  @label "mb-1.5 flex items-center gap-1.5 text-[13px] font-medium text-ink"

  # drawn by the hook (sent in its config)
  @hook_classes %{
    mention: "rounded-[5px] bg-accent-soft px-1 font-medium text-accent-content",
    menu_label:
      "px-2.5 pt-2 pb-1 text-[11.5px] font-medium tracking-[.06em] text-muted uppercase",
    menu_item:
      "flex h-[34px] w-full cursor-pointer items-center gap-2.5 rounded-[8px] border-0 bg-transparent px-2.5 text-left text-sm text-ink-2 hover:bg-hover hover:text-ink aria-selected:bg-hover aria-selected:text-ink",
    menu_icon: "w-[22px] text-center text-xs text-muted",
    menu_hint: "ml-auto flex items-center gap-1 text-xs text-muted"
  }

  @default_toolbar [
    ~w(bold italic underline strike),
    ~w(blockquote code-block),
    ~w(header-1 header-2),
    ~w(list-ordered list-bullet),
    ~w(script-sub script-super),
    ~w(indent-minus1 indent-plus1),
    ~w(direction-rtl),
    ~w(size),
    ~w(header),
    ~w(color background),
    ~w(font),
    ~w(align),
    ~w(clean)
  ]

  @default_slash_items [
    %{label: "Text", key: "paragraph", hint: "Plain paragraph", icon: "¶"},
    %{label: "Heading 1", key: "h1", hint: "Big section title", icon: "H1"},
    %{label: "Heading 2", key: "h2", hint: "Medium section title", icon: "H2"},
    %{label: "Bulleted list", key: "bullet", hint: "A simple list", icon: "•"},
    %{label: "Numbered list", key: "ordered", hint: "A list with order", icon: "1."},
    %{label: "Quote", key: "quote", hint: "Highlight a passage", icon: "❝"},
    %{label: "Code block", key: "code", hint: "Monospaced text", icon: "</>"},
    %{label: "Divider", key: "divider", hint: "A horizontal rule", icon: "—"}
  ]

  # tool => {english name, kind, icon | glyph}
  @tools %{
    "bold" => {"Bold", :icon, "bold"},
    "italic" => {"Italic", :icon, "italic"},
    "underline" => {"Underline", :icon, "underline"},
    "strike" => {"Strike", :glyph, "S"},
    "blockquote" => {"Blockquote", :icon, "quote"},
    "code-block" => {"Code block", :icon, "code"},
    "code" => {"Code", :glyph, "<>"},
    "heading" => {"Heading", :icon, "heading"},
    "header-1" => {"Heading 1", :glyph, "H1"},
    "header-2" => {"Heading 2", :glyph, "H2"},
    "list-ordered" => {"Numbered list", :icon, "list-ol"},
    "list-bullet" => {"Bulleted list", :icon, "list"},
    "script-sub" => {"Subscript", :glyph, "x₂"},
    "script-super" => {"Superscript", :glyph, "x²"},
    "indent-minus1" => {"Decrease indent", :glyph, "⇤"},
    "indent-plus1" => {"Increase indent", :glyph, "⇥"},
    "direction-rtl" => {"Right to left", :glyph, "⇄"},
    "link" => {"Link", :icon, "link"},
    "image" => {"Image", :icon, "image"},
    "variable" => {"Variable", :glyph, "{}"},
    "mark" => {"Highlight", :glyph, "M"},
    "clean" => {"Clear formatting", :glyph, "Tₓ"}
  }

  @pickers %{
    "size" =>
      {"Size", [{"", "Size"}, {"1", "Small"}, {"3", "Normal"}, {"5", "Large"}, {"6", "Huge"}]},
    "header" =>
      {"Heading",
       [{"p", "Normal"}, {"h1", "Heading 1"}, {"h2", "Heading 2"}, {"h3", "Heading 3"}]},
    "font" =>
      {"Font", [{"", "Font"}, {"sans-serif", "Sans"}, {"serif", "Serif"}, {"monospace", "Mono"}]},
    "align" =>
      {"Alignment",
       [{"left", "Left"}, {"center", "Center"}, {"right", "Right"}, {"justify", "Justify"}]},
    "color" => {"Text color", :color},
    "background" => {"Background color", :color}
  }

  # ---------------------------------------------------------------------------------------------
  # <.text_editor>
  # ---------------------------------------------------------------------------------------------

  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :string, default: nil
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :label, :string, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :placeholder, :string, default: nil
  attr :toolbar, :list, default: @default_toolbar
  attr :filled, :boolean, default: false
  attr :content_class, :any, default: nil
  attr :link_label, :string, default: "Enter link:"
  attr :tool_labels, :map, default: %{}
  attr :on_image, :string, default: nil
  attr :images, :boolean, default: false
  attr :image_label, :string, default: "Image URL:"
  attr :image_alt_label, :string, default: "Description"
  attr :image_save_label, :string, default: "Insert"
  attr :save_label, :string, default: "Save"
  attr :disabled, :boolean, default: false
  attr :on_change, :string, default: nil
  attr :debounce, :integer, default: 300
  attr :target, :any, default: nil
  attr :variant, :string, default: "default", values: ~w(default comment)

  attr :density, :string,
    default: "comfortable",
    values: ~w(comfortable compact),
    doc:
      "`compact` is the canvas frame: 12px radius, 28px toolbar buttons with small icons, a 90px text area with 12/14px padding and 14px type."

  attr :loop, :boolean,
    default: false,
    doc: "The canvas demo animation: the toolbar buttons light up in turn (1.2s apart, every 6s)."

  attr :slash, :boolean, default: false
  attr :slash_items, :list, default: @default_slash_items
  attr :on_slash, :string, default: nil
  attr :slash_title, :string, default: "Insert"
  attr :variables, :list, default: []
  attr :variable_label, :string, default: "Variable"
  attr :variable_title, :string, default: "Insert variable"
  attr :mentions, :list, default: []
  attr :mention_title, :string, default: "Mention someone"
  attr :mention_button, :boolean, default: true
  attr :mention_label, :string, default: "Mention"
  attr :on_ai, :string, default: nil
  attr :on_submit, :string, default: nil
  attr :submit_label, :string, default: "Comment"
  attr :submit_key, :any, default: "Ctrl ↵"
  attr :submit_hint, :string, default: nil, doc: "Text after the shortcut (\"to send\")."
  attr :bar, :boolean, default: true
  attr :clear_on_submit, :boolean, default: true
  attr :footer, :boolean, default: false
  attr :hint, :string, default: nil
  attr :words_label, :string, default: "words"
  attr :class, :any, default: nil
  attr :rest, :global

  slot :actions, doc: "The buttons of a comment's bar, before the submit button (attach...)."
  slot :ai, doc: "The content of a button at the end of the toolbar that asks the assistant."
  slot :attachments, doc: "What a comment carries (files as chips), between the text and the bar."

  @doc "Renders a rich text editor."
  def text_editor(assigns) do
    assigns = Form.lu_assign_field(assigns)
    errors = assigns.errors
    id = assigns.id || (assigns.name && slug(assigns.name))
    if id == nil, do: raise(ArgumentError, "text_editor needs an id (or name or field)")

    comment? = assigns.variant == "comment"
    compact? = assigns.density == "compact"
    images? = assigns.images or assigns.on_image != nil or flat_tools(assigns.toolbar, "image")
    html = sanitize(assigns.value, images: images?)

    config = %{
      "slash" => assigns.slash,
      "slashItems" => Enum.map(assigns.slash_items, &stringify/1),
      "slashTitle" => assigns.slash_title,
      "variables" => assigns.variables,
      "variableLabel" => assigns.variable_label,
      "variableTitle" => assigns.variable_title,
      "mentions" => Enum.map(assigns.mentions, &stringify/1),
      "mentionTitle" => assigns.mention_title,
      "images" => images?,
      "debounce" => assigns.debounce,
      "clearOnSubmit" => assigns.clear_on_submit,
      "wordsLabel" => assigns.words_label,
      "classes" => stringify(@hook_classes)
    }

    assigns =
      assigns
      |> assign(:eid, id)
      |> assign(:html, html)
      |> assign(:comment, comment?)
      |> assign(:config, Jason.encode!(config))
      |> assign(
        :groups,
        if(comment?, do: [], else: assigns |> build_groups() |> style_tools(assigns))
      )
      |> assign(:root_class, [
        if(compact?, do: @root_compact, else: @root),
        assigns.class
      ])
      |> assign(
        :body_class,
        if(compact?,
          do: [@body_compact, @prose_compact, assigns.content_class],
          else: [
            @body,
            @prose,
            if(comment?, do: "min-h-16", else: "min-h-[110px]"),
            assigns.content_class
          ]
        )
      )
      |> assign(:label_id, assigns.label && id <> "-label")
      |> assign(:has_msg, assigns.label != nil or assigns.help != nil or errors != [])
      |> assign(
        :show_mention_btn,
        assigns.mention_button and assigns.mentions != [] and comment?
      )
      |> assign(:data_target, if(assigns.target, do: to_string(assigns.target)))
      |> assign(:invalid, errors != [])

    ~H"""
    <Form.field
      :if={@has_msg}
      as="div"
      label={@label}
      label_id={@label_id}
      help={@help}
      errors={@errors}
    >
      <.editor_box
        eid={@eid}
        name={@name}
        html={@html}
        comment={@comment}
        config={@config}
        groups={@groups}
        root_class={@root_class}
        body_class={@body_class}
        label_id={@label_id}
        show_mention_btn={@show_mention_btn}
        data_target={@data_target}
        invalid={@invalid}
        placeholder={@placeholder}
        disabled={@disabled}
        on_change={@on_change}
        on_image={@on_image}
        on_ai={@on_ai}
        on_slash={@on_slash}
        on_submit={@on_submit}
        submit_label={@submit_label}
        submit_key={@submit_key}
        submit_hint={@submit_hint}
        mention_label={@mention_label}
        bar={@bar}
        footer={@footer}
        hint={@hint}
        words_label={@words_label}
        link_label={@link_label}
        save_label={@save_label}
        image_label={@image_label}
        image_alt_label={@image_alt_label}
        image_save_label={@image_save_label}
        actions={@actions}
        ai={@ai}
        attachments={@attachments}
        rest={@rest}
      />
    </Form.field>
    <.editor_box
      :if={!@has_msg}
      eid={@eid}
      name={@name}
      html={@html}
      comment={@comment}
      config={@config}
      groups={@groups}
      root_class={@root_class}
      body_class={@body_class}
      label_id={@label_id}
      show_mention_btn={@show_mention_btn}
      data_target={@data_target}
      invalid={@invalid}
      placeholder={@placeholder}
      disabled={@disabled}
      on_change={@on_change}
      on_image={@on_image}
      on_ai={@on_ai}
      on_slash={@on_slash}
      on_submit={@on_submit}
      submit_label={@submit_label}
      submit_key={@submit_key}
      submit_hint={@submit_hint}
      mention_label={@mention_label}
      bar={@bar}
      footer={@footer}
      hint={@hint}
      words_label={@words_label}
      link_label={@link_label}
      save_label={@save_label}
      image_label={@image_label}
      image_alt_label={@image_alt_label}
      image_save_label={@image_save_label}
      actions={@actions}
      ai={@ai}
      attachments={@attachments}
      rest={@rest}
    />
    """
  end

  attr :eid, :string, required: true
  attr :name, :string, default: nil
  attr :html, :any, default: ""
  attr :comment, :boolean, default: false
  attr :config, :string, default: "{}"
  attr :groups, :list, default: []
  attr :root_class, :any, default: nil
  attr :body_class, :string, default: nil
  attr :label_id, :any, default: nil
  attr :show_mention_btn, :boolean, default: false
  attr :data_target, :any, default: nil
  attr :invalid, :boolean, default: false
  attr :placeholder, :string, default: nil
  attr :disabled, :boolean, default: false
  attr :on_change, :string, default: nil
  attr :on_image, :string, default: nil
  attr :on_ai, :string, default: nil
  attr :on_slash, :string, default: nil
  attr :on_submit, :string, default: nil
  attr :submit_label, :string, default: nil
  attr :submit_key, :any, default: nil
  attr :submit_hint, :string, default: nil
  attr :mention_label, :string, default: nil
  attr :bar, :boolean, default: true
  attr :footer, :boolean, default: false
  attr :hint, :string, default: nil
  attr :words_label, :string, default: nil
  attr :link_label, :string, default: nil
  attr :save_label, :string, default: nil
  attr :image_label, :string, default: nil
  attr :image_alt_label, :string, default: nil
  attr :image_save_label, :string, default: nil
  attr :actions, :list, default: []
  attr :ai, :list, default: []
  attr :attachments, :list, default: []
  attr :rest, :map, default: %{}

  defp editor_box(assigns) do
    assigns =
      assigns
      |> assign(:c_toolbar, @toolbar)
      |> assign(:c_ph, @placeholder)
      |> assign(:c_footer, @footer)
      |> assign(:c_icon, @btn_icon)
      |> assign(:c_pop, @pop)
      |> assign(:c_menu, @menu)
      |> assign(:c_label, @label)

    ~H"""
    <div
      data-part="text-editor"
      id={@eid}
      class={@root_class}
      phx-hook="LedgerUI.TextEditor"
      data-lu-variant={@comment && "comment"}
      data-lu-value={@html}
      data-lu-config={@config}
      data-lu-disabled={@disabled && "true"}
      data-lu-on-change={@on_change}
      data-lu-on-image={@on_image}
      data-lu-on-ai={@on_ai}
      data-lu-on-slash={@on_slash}
      data-lu-on-submit={@on_submit}
      data-lu-target={@data_target}
      data-lu-link-label={@link_label}
      data-lu-save-label={@save_label}
      data-lu-image-label={@image_label}
      data-lu-image-alt-label={@image_alt_label}
      data-lu-image-save-label={@image_save_label}
      {@rest}
    >
      <div
        :if={!@comment}
        data-part="text-editor-toolbar"
        class={@c_toolbar}
        role="toolbar"
        aria-label="Formatting"
      >
        <%= for {group, gi} <- Enum.with_index(@groups) do %>
          <span :if={gi > 0} class="mx-1 h-[18px] w-px bg-line-strong"></span>
          <%= for t <- group do %>
            <.tool tool={t} disabled={@disabled} />
          <% end %>
        <% end %>
        <.button
          :if={@ai != []}
          canvas
          size="sm"
          appearance="ghost"
          class="ml-auto"
          data-lu-tool="ai"
          disabled={@disabled}
        >
          <.icon name="sparkles" size="sm" />{render_slot(@ai)}
        </.button>
      </div>
      <div :if={@placeholder} class="relative">
        <div data-lu-ph aria-hidden="true" class={@c_ph} hidden={@html != ""}>
          {@placeholder}
        </div>
        <.editor_body
          eid={@eid}
          body_class={@body_class}
          comment={@comment}
          disabled={@disabled}
          label_id={@label_id}
          invalid={@invalid}
          html={@html}
        />
      </div>
      <.editor_body
        :if={!@placeholder}
        eid={@eid}
        body_class={@body_class}
        comment={@comment}
        disabled={@disabled}
        label_id={@label_id}
        invalid={@invalid}
        html={@html}
      />
      {render_slot(@attachments)}
      <div :if={@comment and @bar} data-part="text-editor-footer" class={@c_footer}>
        {render_slot(@actions)}
        <button
          :if={@show_mention_btn}
          type="button"
          class={@c_icon}
          aria-label={@mention_label}
          data-lu-tool="mention"
          disabled={@disabled}
        >
          <.icon name="at" />
        </button>
        <span class="min-w-0 flex-1"></span>
        <span :if={@submit_key} class="text-xs text-muted">
          <.kbd>{@submit_key}</.kbd>{@submit_hint && " " <> @submit_hint}
        </span>
        <.button canvas size="sm" appearance="primary" data-lu-tool="submit" disabled={@disabled}>
          {@submit_label}
        </.button>
      </div>
      <div :if={@footer} data-part="text-editor-footer" class={@c_footer} data-lu-footer>
        <span class="text-xs text-muted">{@hint}</span>
        <span class="min-w-0 flex-1"></span>
        <span class="text-xs text-muted"><span data-lu-words>0</span> {@words_label}</span>
      </div>
      <div id={@eid <> "-ui"} phx-update="ignore">
        <div class={@c_pop} data-lu-pop="link" hidden>
          <label class={@c_label}>{@link_label}</label>
          <.input size="sm" data-lu-pop-url autocomplete="off" />
          <.button canvas size="sm" appearance="primary" class="mt-2" data-lu-pop-save>
            {@save_label}
          </.button>
        </div>
        <div class={@c_pop} data-lu-pop="image" hidden>
          <label class={@c_label}>{@image_label}</label>
          <.input size="sm" data-lu-pop-src autocomplete="off" />
          <label class={[@c_label, "mt-2"]}>{@image_alt_label}</label>
          <.input size="sm" data-lu-pop-alt autocomplete="off" />
          <.button canvas size="sm" appearance="primary" class="mt-2" data-lu-pop-save>
            {@image_save_label}
          </.button>
        </div>
        <div class={@c_menu} data-lu-menu hidden></div>
      </div>
      <input :if={@name} type="hidden" name={@name} value={@html} data-lu-editor-value />
    </div>
    """
  end

  attr :eid, :string, required: true
  attr :body_class, :any, default: nil
  attr :comment, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :label_id, :any, default: nil
  attr :invalid, :boolean, default: false
  attr :html, :any, default: ""

  defp editor_body(assigns) do
    ~H"""
    <div
      id={@eid <> "-body"}
      class={@body_class}
      phx-update="ignore"
      contenteditable={if @disabled, do: "false", else: "true"}
      role="textbox"
      aria-multiline="true"
      aria-labelledby={@label_id}
      aria-invalid={@invalid && "true"}
      aria-disabled={@disabled && "true"}
      data-lu-body
    ><%= Phoenix.HTML.raw(@html) %></div>
    """
  end

  attr :tool, :map, required: true
  attr :disabled, :boolean, default: false

  defp tool(%{tool: %{kind: :icon}} = assigns) do
    ~H"""
    <button
      type="button"
      aria-label={@tool.label}
      aria-pressed="false"
      data-lu-tool={@tool.name}
      disabled={@disabled}
      class={@tool.cls}
      style={@tool.style}
    >
      <.icon name={@tool.icon} size={@tool.icon_size} />
    </button>
    """
  end

  defp tool(%{tool: %{kind: :glyph}} = assigns) do
    ~H"""
    <button
      type="button"
      aria-label={@tool.label}
      aria-pressed="false"
      data-lu-tool={@tool.name}
      disabled={@disabled}
      class={[@tool.cls, "text-[12px] font-semibold"]}
      style={@tool.style}
    >
      {@tool.glyph}
    </button>
    """
  end

  defp tool(%{tool: %{kind: :color}} = assigns) do
    ~H"""
    <input
      type="color"
      aria-label={@tool.label}
      data-lu-tool={@tool.name}
      disabled={@disabled}
      class="size-[30px] cursor-pointer border-0 bg-transparent p-0.5"
    />
    """
  end

  defp tool(%{tool: %{kind: :select}} = assigns) do
    ~H"""
    <select
      aria-label={@tool.label}
      data-lu-tool={@tool.name}
      disabled={@disabled}
      class="h-[30px] cursor-pointer rounded-[7px] border-0 bg-transparent text-[13px] text-ink-2"
    >
      <option :for={{v, l} <- @tool.options} value={v}>{l}</option>
    </select>
    """
  end

  defp tool(assigns) do
    ~H"""
    """
  end

  # Groups of renderable tools. Unknown names are dropped.
  defp build_groups(assigns) do
    labels = assigns.tool_labels

    for group <- assigns.toolbar,
        tools =
          group
          |> List.wrap()
          |> Enum.map(&tool_spec(to_string(&1), labels))
          |> Enum.reject(&is_nil/1),
        tools != [],
        do: tools
  end

  # compact / looping toolbars: the class (and the animation delay) of every button, in order
  defp style_tools(groups, assigns) do
    {groups, _} =
      Enum.map_reduce(groups, 0, fn group, i ->
        {tools, i} =
          Enum.map_reduce(group, i, fn t, i ->
            t =
              Map.merge(t, %{
                cls: [
                  if(assigns.density == "compact", do: @tool_compact, else: @tool),
                  assigns.loop && @tool_loop
                ],
                style: assigns.loop && "--dl:#{Float.round(i * 1.2, 1)}s",
                icon_size: if(assigns.density == "compact", do: "sm", else: "md")
              })

            {t, i + 1}
          end)

        {tools, i}
      end)

    groups
  end

  defp tool_spec(name, labels) do
    case {@tools[name], @pickers[name]} do
      {{label, :icon, icon}, _} ->
        %{name: name, label: labels[name] || label, kind: :icon, icon: icon}

      {{label, :glyph, glyph}, _} ->
        %{name: name, label: labels[name] || label, kind: :glyph, glyph: glyph}

      {_, {label, :color}} ->
        %{name: name, label: labels[name] || label, kind: :color}

      {_, {label, options}} ->
        %{name: name, label: labels[name] || label, kind: :select, options: options}

      _ ->
        nil
    end
  end

  defp flat_tools(toolbar, tool),
    do: toolbar |> List.flatten() |> Enum.any?(&(to_string(&1) == tool))

  defp stringify(map), do: Map.new(map, fn {k, v} -> {to_string(k), v} end)
  defp slug(text), do: text |> String.replace(~r/[^A-Za-z0-9_-]+/u, "-") |> String.trim("-")

  # ---------------------------------------------------------------------------------------------
  # Server helpers
  # ---------------------------------------------------------------------------------------------

  @doc """
  Pushes `html` (sanitized) to be inserted at the caret of the editor `id`, replacing the
  selection. Answer to `on_ai`, `on_slash` and similar events.
  """
  def insert_html(socket, id, html) do
    Phoenix.LiveView.push_event(socket, "lu:editor:insert", %{
      id: id,
      html: sanitize(html, images: true)
    })
  end

  @doc """
  Inserts an `<img>` at the caret of the editor `id` (answer to `on_image`). `src` must be
  `http(s)` or a path of your own host.
  """
  def insert_image(socket, id, src, alt \\ "", opts \\ []) do
    insert_html(
      socket,
      id,
      ~s(<img src="#{escape_attr(src)}" alt="#{escape_attr(String.slice(alt, 0, 300))}"#{size_attrs(opts)}>)
    )
  end

  defp size_attrs(opts) do
    for k <- [:width, :height], v = opts[k], is_integer(v), v in 1..4000, into: "" do
      ~s( #{k}="#{v}")
    end
  end

  # -- sanitizer ----------------------------------------------------------------------------

  @allowed_tags ~w(p div br span b strong i em u s strike del ins sub sup blockquote pre code
                   h1 h2 h3 h4 ul ol li a hr mark)
  @void ~w(br hr img)
  @style_props ~w(color background-color background font-size font-family font-weight font-style
                  text-align text-decoration padding-left margin-left direction)
  @tag_re ~r/<!--.*?-->|<\/?[a-zA-Z][a-zA-Z0-9]*(?:[^>"']|"[^"]*"|'[^']*')*>/s
  @tag_parts ~r/^<(\/?)([a-zA-Z][a-zA-Z0-9]*)(.*?)\/?>$/s
  @attr_re ~r/([a-zA-Z_:][-a-zA-Z0-9_:.]*)(?:\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s"'>]+)))?/

  @doc """
  Cleans the HTML of an editor: only formatting tags stay (`p div br span b strong i em u s strike
  del sub sup blockquote pre code h1-h4 ul ol li a hr mark`, plus `img` with `images: true`).

  Attributes are dropped except `href` of a link (`http(s)`, `mailto:`, `tel:`, a path or `#`),
  `src`/`alt`/`width`/`height` of an image (`http(s)` or a path of your own host, never `data:`,
  `javascript:` or `//host`; `alt` up to 300 characters, sizes 1 to 4000), `dir` and a `style`
  limited to a few typographic properties. Everything else is dropped, text is escaped.

      iex> LedgerUI.Components.TextEditor.sanitize(~S|<p onclick="x()">Hi <b>you</b><script>bad()</script></p>|)
      "<p>Hi <b>you</b>bad()</p>"
  """
  @spec sanitize(term(), keyword()) :: String.t()
  def sanitize(html, opts \\ [])
  def sanitize(nil, _opts), do: ""
  def sanitize({:safe, iodata}, opts), do: sanitize(IO.iodata_to_binary(iodata), opts)

  def sanitize(html, opts) when is_binary(html) do
    images? = Keyword.get(opts, :images, false)

    @tag_re
    |> Regex.split(html, include_captures: true)
    |> Enum.map_join(fn piece ->
      if String.starts_with?(piece, "<") and Regex.match?(@tag_re, piece) do
        clean_tag(piece, images?)
      else
        piece |> String.replace("<", "&lt;") |> String.replace(">", "&gt;")
      end
    end)
  end

  def sanitize(other, opts), do: other |> to_string() |> sanitize(opts)

  defp clean_tag("<!--" <> _, _), do: ""

  defp clean_tag(tag, images?) do
    case Regex.run(@tag_parts, tag) do
      [_, close, name, attrs] ->
        name = String.downcase(name)

        cond do
          name == "img" and images? and close == "" -> clean_img(attrs)
          name in @allowed_tags and close == "/" -> "</" <> name <> ">"
          name in @allowed_tags and name in @void -> "<" <> name <> ">"
          name in @allowed_tags -> "<" <> name <> clean_attrs(name, attrs) <> ">"
          true -> ""
        end

      _ ->
        ""
    end
  end

  # An image without a safe `src` is dropped altogether.
  defp clean_img(attrs) do
    cleaned = clean_attrs("img", attrs)
    if String.contains?(cleaned, " src="), do: "<img" <> cleaned <> ">", else: ""
  end

  defp clean_attrs(name, attrs) do
    @attr_re
    |> Regex.scan(attrs)
    |> Enum.map(fn [_ | parts] ->
      [key | vals] = parts
      {String.downcase(key), vals |> Enum.find("", &(&1 != "")) |> String.trim()}
    end)
    |> Enum.uniq_by(&elem(&1, 0))
    |> Enum.map_join(&clean_attr(name, &1))
    |> then(fn s ->
      if name == "a" and String.contains?(s, "href="),
        do: s <> ~s( rel="noopener noreferrer"),
        else: s
    end)
  end

  defp clean_attr("a", {"href", v}) do
    if Regex.match?(~r{^(https?://|mailto:|tel:|/(?!/)|#)}i, v),
      do: ~s( href="#{escape_attr(v)}"),
      else: ""
  end

  defp clean_attr("img", {"src", v}) do
    if Regex.match?(~r{^(https?://|/(?!/))}i, v), do: ~s( src="#{escape_attr(v)}"), else: ""
  end

  defp clean_attr("img", {"alt", v}), do: ~s( alt="#{escape_attr(String.slice(v, 0, 300))}")

  defp clean_attr("img", {k, v}) when k in ["width", "height"] do
    case Integer.parse(v) do
      {n, ""} when n in 1..4000 -> ~s( #{k}="#{n}")
      _ -> ""
    end
  end

  defp clean_attr(_, {"dir", v}) when v in ["rtl", "ltr"], do: ~s( dir="#{v}")

  defp clean_attr(name, {"style", v}) when name != "img" do
    case clean_style(v) do
      "" -> ""
      s -> ~s( style="#{escape_attr(s)}")
    end
  end

  defp clean_attr(_, _), do: ""

  defp clean_style(style) do
    style
    |> String.split(";", trim: true)
    |> Enum.flat_map(fn decl ->
      with [prop, val] <- String.split(decl, ":", parts: 2),
           prop = prop |> String.trim() |> String.downcase(),
           val = String.trim(val),
           true <- prop in @style_props,
           true <- Regex.match?(~r/^[#\w\s,.%()'"-]+$/, val),
           false <- Regex.match?(~r/url\s*\(|expression|javascript|@import/i, val) do
        ["#{prop}:#{val}"]
      else
        _ -> []
      end
    end)
    |> Enum.join(";")
  end

  defp escape_attr(v) do
    v |> to_string() |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
  end

  # ---------------------------------------------------------------------------------------------
  # <.text_editor_content>
  # ---------------------------------------------------------------------------------------------

  attr :value, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block

  @doc """
  Shows saved rich text, read-only, in the editor's type. `value` is escaped unless it is already
  marked safe (`{:safe, html}` / `Phoenix.HTML.raw/1`): pass safe HTML only after `sanitize/2`.
  The inner block wins.
  """
  def text_editor_content(assigns) do
    assigns = assign(assigns, :prose, @prose)

    ~H"""
    <div
      data-part="text-editor-content"
      class={["text-[14px] leading-[22px]", @prose, @class]}
      {@rest}
    >
      <%= if @inner_block != [] do %>
        {render_slot(@inner_block)}
      <% else %>
        {@value}
      <% end %>
    </div>
    """
  end

  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :string, default: nil
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :label, :string, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :placeholder, :string, default: nil

  attr :toolbar, :list,
    default: [
      ["bold", "italic", "underline", "strike"],
      ["blockquote", "code-block"],
      ["header-1", "header-2"],
      ["list-ordered", "list-bullet"],
      ["script-sub", "script-super"],
      ["indent-minus1", "indent-plus1"],
      ["direction-rtl"],
      ["size"],
      ["header"],
      ["color", "background"],
      ["font"],
      ["align"],
      ["clean"]
    ]

  attr :filled, :boolean, default: false
  attr :content_class, :any, default: nil
  attr :link_label, :string, default: "Enter link:"
  attr :tool_labels, :map, default: %{}
  attr :on_image, :string, default: nil
  attr :images, :boolean, default: false
  attr :image_label, :string, default: "Image URL:"
  attr :image_alt_label, :string, default: "Description"
  attr :image_save_label, :string, default: "Insert"
  attr :save_label, :string, default: "Save"
  attr :disabled, :boolean, default: false
  attr :on_change, :string, default: nil
  attr :debounce, :integer, default: 300
  attr :target, :any, default: nil
  attr :variant, :string, default: "default", values: ["default", "comment"]
  attr :density, :string, default: "comfortable", values: ["comfortable", "compact"]
  attr :loop, :boolean, default: false
  attr :slash, :boolean, default: false

  attr :slash_items, :list,
    default: [
      %{label: "Text", key: "paragraph", hint: "Plain paragraph", icon: "¶"},
      %{label: "Heading 1", key: "h1", hint: "Big section title", icon: "H1"},
      %{label: "Heading 2", key: "h2", hint: "Medium section title", icon: "H2"},
      %{label: "Bulleted list", key: "bullet", hint: "A simple list", icon: "•"},
      %{label: "Numbered list", key: "ordered", hint: "A list with order", icon: "1."},
      %{label: "Quote", key: "quote", hint: "Highlight a passage", icon: "❝"},
      %{label: "Code block", key: "code", hint: "Monospaced text", icon: "</>"},
      %{label: "Divider", key: "divider", hint: "A horizontal rule", icon: "—"}
    ]

  attr :on_slash, :string, default: nil
  attr :slash_title, :string, default: "Insert"
  attr :variables, :list, default: []
  attr :variable_label, :string, default: "Variable"
  attr :variable_title, :string, default: "Insert variable"
  attr :mentions, :list, default: []
  attr :mention_title, :string, default: "Mention someone"
  attr :mention_button, :boolean, default: true
  attr :mention_label, :string, default: "Mention"
  attr :on_ai, :string, default: nil
  attr :on_submit, :string, default: nil
  attr :submit_label, :string, default: "Comment"
  attr :submit_key, :any, default: "Ctrl ↵"
  attr :submit_hint, :string, default: nil, doc: "Text after the shortcut (\"to send\")."
  attr :bar, :boolean, default: true
  attr :clear_on_submit, :boolean, default: true
  attr :footer, :boolean, default: false
  attr :hint, :string, default: nil
  attr :words_label, :string, default: "words"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :actions, doc: "The buttons of a comment's bar, before the submit button (attach...)."
  slot :ai, doc: "The content of a button at the end of the toolbar that asks the assistant."
  slot :attachments, doc: "What a comment carries (files as chips), between the text and the bar."

  @doc "Same as `text_editor/1` (same attributes and slots), under the name the design vitrine uses."
  def rich_text_editor(assigns), do: text_editor(assigns)

  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :string, default: nil
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :label, :string, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :placeholder, :string, default: nil

  attr :toolbar, :list,
    default: [
      ["bold", "italic", "underline", "strike"],
      ["blockquote", "code-block"],
      ["header-1", "header-2"],
      ["list-ordered", "list-bullet"],
      ["script-sub", "script-super"],
      ["indent-minus1", "indent-plus1"],
      ["direction-rtl"],
      ["size"],
      ["header"],
      ["color", "background"],
      ["font"],
      ["align"],
      ["clean"]
    ]

  attr :filled, :boolean, default: false
  attr :content_class, :any, default: nil
  attr :link_label, :string, default: "Enter link:"
  attr :tool_labels, :map, default: %{}
  attr :on_image, :string, default: nil
  attr :images, :boolean, default: false
  attr :image_label, :string, default: "Image URL:"
  attr :image_alt_label, :string, default: "Description"
  attr :image_save_label, :string, default: "Insert"
  attr :save_label, :string, default: "Save"
  attr :disabled, :boolean, default: false
  attr :on_change, :string, default: nil
  attr :debounce, :integer, default: 300
  attr :target, :any, default: nil
  attr :variant, :string, default: "comment", values: ["default", "comment"]
  attr :density, :string, default: "comfortable", values: ["comfortable", "compact"]
  attr :loop, :boolean, default: false
  attr :slash, :boolean, default: false

  attr :slash_items, :list,
    default: [
      %{label: "Text", key: "paragraph", hint: "Plain paragraph", icon: "¶"},
      %{label: "Heading 1", key: "h1", hint: "Big section title", icon: "H1"},
      %{label: "Heading 2", key: "h2", hint: "Medium section title", icon: "H2"},
      %{label: "Bulleted list", key: "bullet", hint: "A simple list", icon: "•"},
      %{label: "Numbered list", key: "ordered", hint: "A list with order", icon: "1."},
      %{label: "Quote", key: "quote", hint: "Highlight a passage", icon: "❝"},
      %{label: "Code block", key: "code", hint: "Monospaced text", icon: "</>"},
      %{label: "Divider", key: "divider", hint: "A horizontal rule", icon: "—"}
    ]

  attr :on_slash, :string, default: nil
  attr :slash_title, :string, default: "Insert"
  attr :variables, :list, default: []
  attr :variable_label, :string, default: "Variable"
  attr :variable_title, :string, default: "Insert variable"
  attr :mentions, :list, default: []
  attr :mention_title, :string, default: "Mention someone"
  attr :mention_button, :boolean, default: true
  attr :mention_label, :string, default: "Mention"
  attr :on_ai, :string, default: nil
  attr :on_submit, :string, default: nil
  attr :submit_label, :string, default: "Comment"
  attr :submit_key, :any, default: "Ctrl ↵"
  attr :submit_hint, :string, default: nil, doc: "Text after the shortcut (\"to send\")."
  attr :bar, :boolean, default: true
  attr :clear_on_submit, :boolean, default: true
  attr :footer, :boolean, default: false
  attr :hint, :string, default: nil
  attr :words_label, :string, default: "words"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :actions, doc: "The buttons of a comment's bar, before the submit button (attach...)."
  slot :ai, doc: "The content of a button at the end of the toolbar that asks the assistant."
  slot :attachments, doc: "What a comment carries (files as chips), between the text and the bar."

  @doc "Same as `text_editor/1` (same attributes and slots), under the name the design vitrine uses."
  def comment_editor(assigns), do: text_editor(assigns)
end
