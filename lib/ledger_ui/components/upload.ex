defmodule LedgerUI.Components.Upload do
  @moduledoc """
  File uploads built on LiveView uploads: the drop panel with each file's progress, errors and
  cancel button (shown on finished entries too, so a sent file can be removed before submitting), and the styled "Choose File" button.

      # mount
      socket |> allow_upload(:photos, accept: ~w(.jpg .png), max_entries: 4)

      <.form for={@form} phx-change="validate" phx-submit="save">
        <.upload upload={@uploads.photos} on_cancel="cancel-upload" columns={2}
          hint="PDF, XML ou CSV · até 10 MB cada" />
      </.form>

      def handle_event("cancel-upload", %{"ref" => ref}, socket),
        do: {:noreply, cancel_upload(socket, :photos, ref)}

  `upload/1` renders `live_file_input` itself, so it must sit inside the form that has the
  `phx-change` LiveView uploads need. Dropping files on the panel works through `phx-drop-target`;
  while files are dragged over it LiveView puts the class `phx-drop-target-active` on the panel,
  and the drop area paints the `over` state from it (no hook).

  The pieces it is made of are public and stateless, for custom layouts and for the design
  gallery: `upload_drop/1` (the dashed drop area), `upload_zone/1` (the compact zone with the
  kit's variants), `upload_file/1` (a file card), `upload_thumbs/1` and `upload_button/1`.

  Deviation from the README: `upload_button/1` is a `<label>` around the file input (as the
  README says), so the design's `<button>` is not reproduced byte for byte; `variant` accepts the
  design's zone variants too (`solid glow outline soft bordered flat glass dim`).
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Button

  @zone_variants ~w(canvas pond solid glow outline soft bordered flat glass dim)
  @colors ~w(neutral primary secondary info success warning error mono white current)

  # `mono`, `white` and `current` share the neutral look of the zone and of the button
  @color_names %{
    "mono" => "neutral",
    "white" => "neutral",
    "current" => "neutral"
  }

  defp color_name(c), do: Map.get(@color_names, c, c)

  # The drop area: `data-state="over"` (the static `over` attr) or, while files are dragged over the
  # panel, LiveView's `phx-drop-target-active` class on the panel (an ancestor) paints the same state.
  @drop "flex flex-col items-center gap-1.5 border-[1.5px] border-dashed p-[26px] text-center " <>
          "data-[state=over]:border-accent-500 data-[state=over]:bg-accent-soft data-[state=over]:text-accent-content " <>
          "[.phx-drop-target-active_&]:border-accent-500 [.phx-drop-target-active_&]:bg-accent-soft [.phx-drop-target-active_&]:text-accent-content"

  # The compact zone: one measure per property, chosen by variant, shape and size in `zone_classes/4`
  @zone_base "flex items-center gap-1.5 text-center text-[var(--c-ink,var(--lu-ink))]"
  @zone_border_dashed "border-[color-mix(in_oklab,var(--c,var(--lu-ink))_45%,var(--lu-line-strong))]"
  @zone_looks %{
    "outline" => {"border-dashed", @zone_border_dashed, nil},
    "solid" => {"border-dashed", @zone_border_dashed, nil},
    "soft" => {"border-solid", "border-transparent", "bg-(--c-soft)"},
    "flat" => {"border-dashed", "border-transparent", "bg-sunken"},
    "bordered" => {"border-solid", @zone_border_dashed, nil},
    "glow" =>
      {"border-solid", @zone_border_dashed,
       "shadow-[0_0_0_4px_color-mix(in_oklab,var(--c,var(--lu-accent-500))_18%,transparent)]"},
    "glass" =>
      {"border-solid", "border-line",
       "bg-[color-mix(in_srgb,var(--lu-bg-panel)_60%,transparent)] backdrop-blur-[8px]"},
    "dim" => {"border-dashed", @zone_border_dashed, "bg-tray opacity-75"},
    "canvas" => {"border-solid", "border-line", "bg-page"},
    "pond" => {"border-dashed", @zone_border_dashed, "bg-tray"}
  }

  @file_card "flex items-center gap-3 rounded-[12px] border bg-panel px-3 py-2.5"
  @ghost_icon "inline-flex size-[30px] flex-none cursor-pointer items-center justify-center rounded-[8px] border border-transparent bg-transparent text-ink-2 " <>
                "transition-[background,border-color,box-shadow] duration-150 hover:bg-hover hover:text-ink focus-visible:shadow-[0_0_0_3px_var(--lu-focus)] focus-visible:outline-none [&_svg]:size-4"
  @thumb "block size-16 rounded-md bg-[linear-gradient(135deg,var(--lu-accent-200),var(--lu-accent-500))]"

  @doc false
  def zone_classes(variant, shape, size) do
    {style, color, extra} = @zone_looks[variant] || @zone_looks["outline"]

    [
      @zone_base,
      style,
      color,
      extra,
      cond do
        shape == "pill" -> "rounded-full"
        shape == "square" -> "rounded-[4px]"
        variant == "pond" -> "rounded-2xl"
        true -> "rounded-lg"
      end,
      if(variant == "pond", do: "border-2", else: "border-[1.5px]"),
      if(shape == "pill", do: "flex-row", else: "flex-col"),
      cond do
        size == "xl" -> "p-[34px] text-[15px]"
        shape == "pill" -> "px-5 py-3 text-[13px]"
        true -> "p-[18px] text-[13px]"
      end
    ]
  end

  @cols %{
    1 => "flex flex-col",
    2 => "grid grid-cols-[repeat(2,minmax(0,1fr))]",
    3 => "grid grid-cols-[repeat(3,minmax(0,1fr))]",
    4 => "grid grid-cols-[repeat(4,minmax(0,1fr))]"
  }

  # ---------------------------------------------------------------------------------------
  # Presentational parts
  # ---------------------------------------------------------------------------------------

  attr :drop_label, :string, default: nil
  attr :browse_label, :string, default: nil
  attr :hint, :string, default: nil
  attr :over, :boolean, default: false, doc: "Draws the drag-over state."
  attr :error, :boolean, default: false

  attr :loop, :boolean,
    default: false,
    doc: "The canvas demo animation: the area takes the drag-over look and lets go, every 5s."

  attr :circle, :boolean, default: false, doc: "A round area (the `circle` layout)."
  attr :for, :string, default: nil, doc: "Id of the file input: the area becomes its `<label>`."
  attr :icon_path, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :label, doc: "Replaces the text of the area."

  @doc "The dashed drop area: icon, label with the browse link, and a hint."
  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def upload_drop(assigns) do
    changed0 = assigns.__changed__
    assigns = I18n.texts(assigns, drop_label: "upload.drop", browse_label: "upload.browse")

    assigns =
      assign(assigns, :cls, [
        @drop,
        if(assigns.error,
          do: "border-neg bg-neg-soft text-neg",
          else: "border-line-strong bg-tray text-muted"
        ),
        if(assigns.circle,
          do: "aspect-square justify-center rounded-full",
          else: "rounded-lg"
        ),
        assigns.for && "cursor-pointer",
        assigns.loop && "animate-[lu-dragover_5s_ease-in-out_infinite]",
        assigns.class
      ])

    assigns = settle(assigns, changed0, cls: [:error, :circle, :for, :loop, :class])

    ~H"""
    <%= if @for do %>
      <label
        data-part="upload-drop"
        for={@for}
        class={@cls}
        data-state={@over && "over"}
        {@rest}
      >
        <.drop_body
          icon_path={@icon_path}
          label={@label}
          drop_label={@drop_label}
          browse_label={@browse_label}
          hint={@hint}
        />
      </label>
    <% else %>
      <div data-part="upload-drop" class={@cls} data-state={@over && "over"} {@rest}>
        <.drop_body
          icon_path={@icon_path}
          label={@label}
          drop_label={@drop_label}
          browse_label={@browse_label}
          hint={@hint}
        />
      </div>
    <% end %>
    """
  end

  defp drop_body(assigns) do
    ~H"""
    <%= if @icon_path do %>
      <svg class="size-[22px] flex-none" viewBox="0 0 24 24" aria-hidden="true">
        <path d={@icon_path} fill="none" stroke="currentColor" stroke-width="1.5" />
      </svg>
    <% else %>
      <.icon name="upload" size="lg" />
    <% end %>
    <b data-part="upload-drop-label" class="text-sm">
      <%= if @label != [] do %>
        {render_slot(@label)}
      <% else %>
        {@drop_label} <u>{@browse_label}</u>
      <% end %>
    </b>
    <span :if={@hint} data-part="upload-drop-hint" class="text-xs text-muted">{@hint}</span>
    """
  end

  attr :variant, :string, default: "canvas", values: @zone_variants
  attr :color, :string, default: "primary", values: @colors
  attr :shape, :string, default: "rounded", values: ~w(rounded pill square)
  attr :size, :string, default: nil, values: [nil, "md", "xl"]
  attr :for, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "The compact drop zone with the kit's variants, colors, shapes and sizes."
  def upload_zone(assigns) do
    changed0 = assigns.__changed__

    assigns =
      assigns
      |> assign(:cls, [
        zone_classes(assigns.variant, assigns.shape, assigns.size),
        LedgerUI.Color.vars(color_name(assigns.color)),
        assigns.for && "cursor-pointer",
        assigns.class
      ])

    assigns = settle(assigns, changed0, cls: [:variant, :shape, :size, :color, :for, :class])

    ~H"""
    <%= if @for do %>
      <label data-part="upload-zone" for={@for} class={@cls} {@rest}>
        <.icon name="upload" size="md" />
        <span>{render_slot(@inner_block)}</span>
      </label>
    <% else %>
      <div data-part="upload-zone" class={@cls} {@rest}>
        <.icon name="upload" size="md" />
        <span>{render_slot(@inner_block)}</span>
      </div>
    <% end %>
    """
  end

  attr :name, :string, required: true

  attr :ext, :string,
    default: nil,
    doc: "The badge text (`XML`); the extension of `name` by default."

  attr :status, :string, default: nil, doc: "The line under the name (free text, not an enum)."
  attr :progress, :integer, default: 0

  attr :loop, :boolean,
    default: false,
    doc: "The canvas demo animation: the progress bar fills from 0 to 100%, every 4s."

  attr :state, :string, default: "progress", values: ~w(progress done error)
  attr :remove_label, :string, default: nil
  attr :retry_label, :string, default: nil, doc: "On an error: a retry button with this text."
  attr :removable, :boolean, default: true

  attr :on_remove, :any,
    default: nil,
    doc:
      "An event name or a `%JS{}` for the remove button. It also shows next to the check on finished (`done`) cards."

  attr :on_retry, :any, default: nil
  attr :ref, :string, default: nil, doc: "Sent as `phx-value-ref` with the events."
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :preview, doc: "Replaces the extension badge (an image preview)."

  @doc "A file card: badge, name, status, progress bar and the remove (or retry) button."
  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def upload_file(assigns) do
    changed0 = assigns.__changed__
    assigns = I18n.texts(assigns, remove_label: "common.remove")

    ext =
      assigns.ext || assigns.name |> Path.extname() |> String.trim_leading(".") |> String.upcase()

    assigns =
      assigns
      |> assign(:ext_text, ext)
      |> assign(:cls, [
        @file_card,
        if(assigns.state == "error",
          do: "border-[color-mix(in_oklab,var(--lu-neg)_40%,var(--lu-line))]",
          else: "border-line"
        ),
        assigns.class
      ])
      |> assign(:ghost, @ghost_icon)
      |> assign(:retry, Button.classes("neutral", "outline", "xs", "rounded"))
      |> assign(:target_attr, assigns.target && to_string(assigns.target))

    assigns =
      settle(assigns, changed0,
        ext_text: [:ext, :name],
        cls: [:state, :class],
        ghost: [],
        retry: [],
        target_attr: [:target]
      )

    ~H"""
    <div data-part="upload-file" class={@cls} {@rest}>
      <%= if @preview != [] do %>
        {render_slot(@preview)}
      <% else %>
        <span
          data-part="upload-file-type"
          class="grid size-[34px] flex-none place-items-center rounded-[8px] bg-sunken font-mono text-[10px] font-bold text-muted"
        >
          {@ext_text}
        </span>
      <% end %>
      <div data-part="upload-file-info" class="flex min-w-0 flex-1 flex-col gap-1">
        <b data-part="upload-file-name" class="truncate text-[13.5px] font-medium">{@name}</b>
        <span
          data-part="upload-file-status"
          class={[
            "text-[12px] tabular-nums",
            if(@state == "error", do: "text-neg", else: "text-muted")
          ]}
        >{@status}</span>
        <div
          data-part="upload-file-bar"
          class={[
            "h-1 overflow-hidden rounded-[2px] bg-selected",
            @state == "done" && "hidden"
          ]}
        >
          <i
            data-part="upload-file-progress"
            class={[
              "block h-full rounded-[2px]",
              @loop && "animate-[lu-upfill_4s_cubic-bezier(.4,0,.2,1)_infinite]",
              if(@state == "error", do: "bg-neg", else: "bg-accent-500")
            ]}
            style={"width:#{@progress}%"}
          ></i>
        </div>
      </div>
      <%= cond do %>
        <% @state == "done" -> %>
          <span
            :if={!(@removable and @on_remove != nil)}
            data-part="upload-file-done"
            class="text-pos"
          >
            <.icon name="check-circle" />
          </span>
          <span :if={@removable and @on_remove != nil} class="flex items-center gap-1">
            <span data-part="upload-file-done" class="text-pos"><.icon name="check-circle" /></span>
            <button
              data-part="upload-file-remove"
              aria-label={@remove_label}
              class={@ghost}
              type="button"
              phx-click={@on_remove}
              phx-target={@target_attr}
              phx-value-ref={@ref}
            >
              <.icon name="x" />
            </button>
          </span>
        <% @state == "error" and @retry_label -> %>
          <button
            data-part="upload-file-retry"
            class={@retry}
            type="button"
            phx-click={@on_retry}
            phx-target={@target_attr}
            phx-value-ref={@ref}
          >
            {@retry_label}
          </button>
        <% @removable -> %>
          <button
            data-part="upload-file-remove"
            aria-label={@remove_label}
            class={@ghost}
            type="button"
            phx-click={@on_remove}
            phx-target={@target_attr}
            phx-value-ref={@ref}
          >
            <.icon name="x" />
          </button>
        <% true -> %>
      <% end %>
    </div>
    """
  end

  attr :count, :integer, default: 3
  attr :columns, :integer, default: nil, doc: "`--cols` (3 by default)."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, doc: "Your own tiles instead of `count` placeholders."

  @doc "The grid of 64px thumbnails."
  def upload_thumbs(assigns) do
    changed0 = assigns.__changed__

    assigns =
      assigns
      |> assign(
        :attrs,
        if(assigns.columns, do: %{style: "--cols:#{assigns.columns}"}, else: %{})
      )
      |> assign(:thumb, @thumb)

    assigns = settle(assigns, changed0, attrs: [:columns], thumb: [])

    ~H"""
    <div
      data-part="upload-thumbs"
      class={["grid grid-cols-[repeat(var(--cols,3),64px)] gap-2", @class]}
      {@attrs}
      {@rest}
    >
      <%= if @inner_block != [] do %>
        {render_slot(@inner_block)}
      <% else %>
        <i :for={_ <- 1..@count//1} data-part="upload-thumb" class={@thumb}></i>
      <% end %>
    </div>
    """
  end

  # ---------------------------------------------------------------------------------------
  # <.upload_button>
  # ---------------------------------------------------------------------------------------

  attr :upload, Phoenix.LiveView.UploadConfig, default: nil
  attr :name, :string, default: nil
  attr :multiple, :boolean, default: false
  attr :accept, :string, default: nil
  attr :disabled, :boolean, default: false
  attr :color, :string, default: "neutral", values: @colors

  attr :variant, :string,
    default: "solid",
    values: ~w(solid glow outline soft bordered flat glass ghost dim)

  attr :size, :string, default: nil, values: [nil, "", "xs", "sm", "md", "lg", "xl"]
  attr :shape, :string, default: "rounded", values: ~w(rounded pill square)
  attr :icon, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc """
  A button that opens the file chooser: a `<label>` with the button classes holding an invisible
  file input. With `upload` it renders `live_file_input`; otherwise a plain `<input type="file">`.

      <.upload_button upload={@uploads.avatar}>Choose File</.upload_button>
      <.upload_button name="doc" variant="outline" size="sm">Attach</.upload_button>
  """
  def upload_button(assigns) do
    changed0 = assigns.__changed__

    assigns =
      assign(assigns, :cls, [
        Button.classes(
          color_name(assigns.color),
          assigns.variant,
          if(assigns.size in [nil, ""], do: "md", else: assigns.size),
          if(assigns.icon, do: "square", else: assigns.shape)
        ),
        "relative cursor-pointer",
        assigns.disabled && "pointer-events-none opacity-50",
        assigns.class
      ])

    assigns =
      settle(assigns, changed0, cls: [:color, :variant, :size, :icon, :shape, :disabled, :class])

    ~H"""
    <label data-part="upload-button" class={@cls} {@rest}>
      {render_slot(@inner_block)}
      <%= if @upload do %>
        <.live_file_input
          upload={@upload}
          class="absolute inset-0 w-full cursor-pointer opacity-0"
          disabled={@disabled}
        />
      <% else %>
        <input
          type="file"
          name={@name}
          multiple={@multiple}
          accept={@accept}
          disabled={@disabled}
          class="absolute inset-0 w-full cursor-pointer opacity-0"
        />
      <% end %>
    </label>
    """
  end

  # ---------------------------------------------------------------------------------------
  # <.upload>
  # ---------------------------------------------------------------------------------------

  attr :upload, Phoenix.LiveView.UploadConfig, required: true
  attr :id, :string, default: nil
  attr :bordered, :boolean, default: false
  attr :filled, :boolean, default: false
  attr :columns, :integer, default: 1, values: [1, 2, 3, 4]
  attr :variant, :string, default: "canvas", values: @zone_variants
  attr :color, :string, default: "primary", values: @colors
  attr :shape, :string, default: "rounded", values: ~w(rounded pill square)
  attr :size, :string, default: nil, values: [nil, "md", "xl"]
  attr :layout, :string, default: "panel", values: ~w(panel circle thumbs)
  attr :hint, :string, default: nil
  attr :browse, :string, default: nil
  attr :icon_path, :string, default: nil
  attr :drop_class, :any, default: nil
  attr :on_cancel, :any, default: nil
  attr :target, :any, default: nil
  attr :previews, :boolean, default: true

  attr :error_texts, :map,
    default: nil,
    doc:
      "Texts of the upload errors (`:too_large`, `:too_many_files`, `:external_client_failure`, `:not_accepted`), over the locale ones."

  attr :browse_label, :string, default: nil
  attr :drop_label, :string, default: nil
  attr :remove_label, :string, default: nil
  attr :uploading_label, :string, default: nil
  attr :complete_label, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :label, doc: "Replaces the text of the drop panel."

  @doc "Renders the drop panel and the list of chosen files."
  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def upload(assigns) do
    changed0 = assigns.__changed__

    assigns =
      I18n.texts(assigns,
        browse_label: "upload.browse",
        drop_label: "upload.drop",
        remove_label: "common.remove",
        uploading_label: "upload.uploading",
        complete_label: "upload.complete"
      )

    up = assigns.upload
    id = assigns.id || "#{up.ref}-pond"
    texts = Map.merge(I18n.labels("upload_errors", assigns.locale), assigns.error_texts || %{})

    entries =
      for e <- up.entries do
        errs = Phoenix.Component.upload_errors(up, e)
        done? = e.done? or e.progress == 100

        %{
          entry: e,
          ref: e.ref,
          name: e.client_name,
          state: if(errs != [], do: "error", else: if(done?, do: "done", else: "progress")),
          progress: e.progress,
          status:
            cond do
              errs != [] -> error_text(hd(errs), texts, up)
              done? -> "#{format_size(e.client_size)} · #{assigns.complete_label}"
              true -> "#{format_size(e.client_size)} · #{e.progress}%"
            end,
          image?: assigns.previews and String.starts_with?(e.client_type || "", "image/")
        }
      end

    errors = for err <- Phoenix.Component.upload_errors(up), do: error_text(err, texts, up)
    zone? = assigns.variant != "canvas"

    assigns =
      assigns
      |> assign(:id, id)
      |> assign(:entries, entries)
      |> assign(:errors, errors)
      |> assign(:zone?, zone?)
      |> assign(:input_id, up.ref)
      |> assign(:target_attr, assigns.target && to_string(assigns.target))
      |> assign(
        :zone_variant,
        cond do
          assigns.bordered and assigns.variant == "pond" -> "bordered"
          assigns.filled and assigns.variant == "pond" -> "flat"
          true -> assigns.variant
        end
      )
      |> assign(:thumb, @thumb)
      |> assign(:retry, Button.classes("neutral", "outline", "xs", "rounded"))
      |> assign(:cols, @cols[assigns.columns])

    assigns =
      settle(assigns, changed0,
        id: [:id, :upload],
        entries: [:upload, :previews, :error_texts, :locale, :complete_label],
        errors: [:upload, :error_texts, :locale],
        zone?: [:variant],
        input_id: [:upload],
        target_attr: [:target],
        zone_variant: [:bordered, :filled, :variant],
        thumb: [],
        retry: [],
        cols: [:columns]
      )

    ~H"""
    <div
      id={@id}
      data-part="upload"
      phx-drop-target={@upload.ref}
      class={["flex flex-col gap-2", @class]}
      {@rest}
    >
      <.live_file_input upload={@upload} class="absolute size-px overflow-hidden opacity-0" />
      <%= cond do %>
        <% @layout == "thumbs" -> %>
          <.upload_thumbs columns={@columns}>
            <i
              :for={e <- @entries}
              data-part="upload-thumb"
              class={[@thumb, "relative overflow-hidden"]}
            >
              <.live_img_preview :if={e.image?} entry={e.entry} class="size-full object-cover" />
            </i>
            <label
              for={@input_id}
              data-part="upload-add"
              class="grid size-16 cursor-pointer place-items-center rounded-md border-[1.5px] border-dashed border-line-strong text-muted"
              aria-label={@browse_label}
            >
              <.icon name="plus" />
            </label>
          </.upload_thumbs>
        <% @zone? -> %>
          <.upload_zone
            for={@input_id}
            variant={@zone_variant}
            color={@color}
            shape={@shape}
            size={@size}
            class={@drop_class}
          >
            <%= if @label != [] do %>
              {render_slot(@label)}
            <% else %>
              {@drop_label} <u>{@browse_label}</u>
            <% end %>
          </.upload_zone>
        <% true -> %>
          <.upload_drop
            locale={@locale}
            for={@input_id}
            hint={@hint}
            drop_label={@drop_label}
            browse_label={@browse_label}
            icon_path={@icon_path}
            error={@errors != []}
            circle={@layout == "circle"}
            class={@drop_class}
          >
            <:label :if={@label != []}>{render_slot(@label)}</:label>
          </.upload_drop>
      <% end %>
      <span
        :if={@browse && @layout != "thumbs"}
        data-part="upload-browse"
        class={[@retry, "self-center"]}
      >
        <.icon name="upload" />{@browse}
      </span>
      <span :for={err <- @errors} data-part="upload-error" class="text-xs text-neg">{err}</span>
      <div
        :if={@layout != "thumbs" and @entries != []}
        data-part="upload-files"
        class={["gap-2", @cols]}
      >
        <.upload_file
          :for={e <- @entries}
          locale={@locale}
          name={e.name}
          state={e.state}
          status={e.status}
          progress={e.progress}
          ref={e.ref}
          on_remove={@on_cancel}
          removable={@on_cancel != nil}
          target={@target}
          remove_label={@remove_label}
        >
          <:preview :if={e.image?}>
            <.live_img_preview
              entry={e.entry}
              class="size-[34px] flex-none rounded-[8px] object-cover"
            />
          </:preview>
        </.upload_file>
      </div>
    </div>
    """
  end

  defp error_text(err, texts, up) do
    text = Map.get(texts, err, to_string(err))
    String.replace(text, "%{max}", to_string(up.max_entries))
  end

  @doc false
  def format_size(nil), do: ""
  def format_size(n) when n < 1024, do: "#{n} B"
  def format_size(n) when n < 1024 * 1024, do: "#{round(n / 1024)} KB"
  def format_size(n), do: "#{Float.round(n / 1024 / 1024, 1)} MB"
end
