defmodule LedgerUI.Components.Upload do
  @moduledoc """
  File uploads built on LiveView uploads: the drop panel with each file's progress, errors and
  cancel button, and the styled "Choose File" button.

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
  the `LedgerUI.Upload` hook (`priv/static/ledger_ui/hooks/upload.js`) only paints the `over`
  state while files are dragged over it.

  The pieces it is made of are public and stateless, for custom layouts and for the design
  gallery: `upload_drop/1` (the dashed drop area), `upload_zone/1` (the compact zone with the
  kit's variants), `upload_file/1` (a file card), `upload_thumbs/1` and `upload_button/1`.

  Deviation from the README: `upload_button/1` is a `<label>` around the file input (as the
  README says), so the design's `<button>` is not reproduced byte for byte; `variant` accepts the
  design's zone variants too (`solid glow outline soft bordered flat glass dim`).
  """
  use LedgerUI.Component

  @zone_variants ~w(canvas pond solid glow outline soft bordered flat glass dim)
  @colors ~w(neutral primary secondary info success warning error mono white current)

  @styles %{
    "color" => %{
      "neutral" => "c-neutral",
      "primary" => "c-primary",
      "secondary" => "c-secondary",
      "info" => "c-info",
      "success" => "c-success",
      "warning" => "c-warning",
      "error" => "c-error",
      "mono" => "c-neutral",
      "white" => "c-neutral",
      "current" => "c-neutral"
    },
    "shape" => %{"rounded" => nil, "pill" => "sh-pill", "square" => "sh-square"},
    "size" => %{"xs" => "s-xs", "sm" => "s-sm", "md" => "s-md", "lg" => "s-lg", "xl" => "s-xl"},
    "button_variant" => %{
      "solid" => "v-solid",
      "glow" => "v-glow",
      "outline" => "v-outline",
      "soft" => "v-soft",
      "bordered" => "v-bordered",
      "flat" => "v-flat",
      "glass" => "v-glass",
      "ghost" => "v-ghost",
      "dim" => "v-dim"
    }
  }

  @errors %{
    too_large: "File is too large",
    too_many_files: "Too many files",
    external_client_failure: "Upload failed",
    not_accepted: "File of invalid type"
  }

  # ---------------------------------------------------------------------------------------
  # Presentational parts
  # ---------------------------------------------------------------------------------------

  attr :drop_label, :string, default: "Drag & Drop your files or"
  attr :browse_label, :string, default: "Browse"
  attr :hint, :string, default: nil
  attr :over, :boolean, default: false, doc: "Draws the drag-over state."
  attr :error, :boolean, default: false
  attr :for, :string, default: nil, doc: "Id of the file input: the area becomes its `<label>`."
  attr :icon_path, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :label, doc: "Replaces the text of the area."

  @doc "The dashed drop area: icon, label with the browse link, and a hint."
  def upload_drop(assigns) do
    assigns =
      assigns
      |> assign(:cls, cx(["lu-drop", assigns.over && "over", assigns.class]))
      |> assign(
        :attrs,
        if(assigns.error,
          do: %{style: "border-color:var(--neg);color:var(--neg);background:var(--neg-soft)"},
          else: %{}
        )
      )

    ~H"""
    <%= if @for do %>
      <label data-part="upload-drop" for={@for} class={@cls} style="cursor:pointer" {@rest}>
        <.drop_body {assigns} />
      </label>
    <% else %>
      <div data-part="upload-drop" class={@cls} {@attrs} {@rest}>
        <.drop_body {assigns} />
      </div>
    <% end %>
    """
  end

  defp drop_body(assigns) do
    ~H"""
    <%= if @icon_path do %>
      <svg class="lu-i lg" viewBox="0 0 24 24" aria-hidden="true">
        <path d={@icon_path} fill="none" stroke="currentColor" stroke-width="1.5" />
      </svg>
    <% else %>
      <.icon name="upload" size="lg" />
    <% end %>
    <b style="font-size:14px">
      <%= if @label != [] do %>
        {render_slot(@label)}
      <% else %>
        {@drop_label} <u>{@browse_label}</u>
      <% end %>
    </b>
    <span :if={@hint} class="lu-xs lu-muted">{@hint}</span>
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

  @doc "The compact drop zone (`lu-upz`) with the kit's variants, colors, shapes and sizes."
  def upload_zone(assigns) do
    assigns =
      assign(
        assigns,
        :cls,
        cx([
          "lu-upz",
          @styles["color"][assigns.color],
          "v-#{assigns.variant}",
          @styles["shape"][assigns.shape],
          assigns.size == "xl" && "s-xl",
          assigns.class
        ])
      )

    ~H"""
    <%= if @for do %>
      <label data-part="upload-zone" for={@for} class={@cls} style="cursor:pointer" {@rest}>
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

  attr :status, :string, default: nil, doc: "The line under the name."
  attr :progress, :integer, default: 0
  attr :state, :string, default: "progress", values: ~w(progress done error)
  attr :remove_label, :string, default: "Remove"
  attr :retry_label, :string, default: nil, doc: "On an error: a retry button with this text."
  attr :removable, :boolean, default: true
  attr :on_remove, :any, default: nil, doc: "An event name or a `%JS{}` for the remove button."
  attr :on_retry, :any, default: nil
  attr :ref, :string, default: nil, doc: "Sent as `phx-value-ref` with the events."
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :preview, doc: "Replaces the extension badge (an image preview)."

  @doc "A file card: badge, name, status, progress bar and the remove (or retry) button."
  def upload_file(assigns) do
    ext =
      assigns.ext || assigns.name |> Path.extname() |> String.trim_leading(".") |> String.upcase()

    assigns =
      assigns
      |> assign(:ext_text, ext)
      |> assign(
        :cls,
        cx([
          "lu-file",
          assigns.state == "done" && "done",
          assigns.state == "error" && "err",
          assigns.class
        ])
      )
      |> assign(:target_attr, assigns.target && to_string(assigns.target))

    ~H"""
    <div data-part="upload-file" class={@cls} {@rest}>
      <%= if @preview != [] do %>
        {render_slot(@preview)}
      <% else %>
        <span class="ft">{@ext_text}</span>
      <% end %>
      <div class="meta">
        <b>{@name}</b>
        <span>{@status}</span>
        <div class="pb"><i style={"--sp:#{@progress}%"}></i></div>
      </div>
      <%= cond do %>
        <% @state == "done" -> %>
          <span style="color:var(--pos)"><.icon name="check-circle" /></span>
        <% @state == "error" and @retry_label -> %>
          <button
            class="lu-b c-neutral v-outline s-xs sh-rounded"
            type="button"
            phx-click={@on_retry}
            phx-target={@target_attr}
            phx-value-ref={@ref}
          >
            {@retry_label}
          </button>
        <% @removable -> %>
          <button
            aria-label={@remove_label}
            class="lu-btn icon ghost sm"
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
  attr :columns, :integer, default: nil, doc: "`--cols` (3 by default in the stylesheet)."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, doc: "Your own tiles instead of `count` placeholders."

  @doc "The grid of 64px thumbnails."
  def upload_thumbs(assigns) do
    assigns =
      assign(
        assigns,
        :attrs,
        if(assigns.columns, do: %{style: "--cols:#{assigns.columns}"}, else: %{})
      )

    ~H"""
    <div data-part="upload-thumbs" class={cx(["lu-thumbs", @class])} {@attrs} {@rest}>
      <%= if @inner_block != [] do %>
        {render_slot(@inner_block)}
      <% else %>
        <i :for={_ <- 1..@count//1}></i>
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
    assigns =
      assigns
      |> assign(
        :cls,
        cx([
          "lu-b",
          @styles["color"][assigns.color],
          @styles["button_variant"][assigns.variant],
          "s-#{assigns.size || "md"}",
          "sh-#{assigns.shape}",
          assigns.icon && "icon",
          assigns.class
        ])
      )
      |> assign(
        :label_attrs,
        %{
          style:
            "position:relative;cursor:pointer" <>
              if(assigns.disabled, do: ";pointer-events:none;opacity:.5", else: "")
        }
      )

    ~H"""
    <label
      data-part="upload-button"
      class={@cls}
      style="position:relative;cursor:pointer"
      {@label_attrs}
      {@rest}
    >
      {render_slot(@inner_block)}
      <%= if @upload do %>
        <.live_file_input
          upload={@upload}
          style="position:absolute;inset:0;opacity:0;width:100%;cursor:pointer"
          disabled={@disabled}
        />
      <% else %>
        <input
          type="file"
          name={@name}
          multiple={@multiple}
          accept={@accept}
          disabled={@disabled}
          style="position:absolute;inset:0;opacity:0;width:100%;cursor:pointer"
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
  attr :error_texts, :map, default: @errors
  attr :browse_label, :string, default: "Browse"
  attr :drop_label, :string, default: "Drag & Drop your files or"
  attr :remove_label, :string, default: "Remove"
  attr :uploading_label, :string, default: "Uploading"
  attr :complete_label, :string, default: "Upload complete"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :label, doc: "Replaces the text of the drop panel."

  @doc "Renders the drop panel and the list of chosen files."
  def upload(assigns) do
    up = assigns.upload
    id = assigns.id || "#{up.ref}-pond"
    texts = Map.merge(@errors, assigns.error_texts)

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
      |> assign(:grid_attrs, grid_attrs(assigns.columns))
      |> assign(
        :zone_variant,
        cond do
          assigns.bordered and assigns.variant == "pond" -> "bordered"
          assigns.filled and assigns.variant == "pond" -> "flat"
          true -> assigns.variant
        end
      )
      |> assign(
        :circle_attrs,
        if(assigns.layout == "circle",
          do: %{style: "border-radius:50%;aspect-ratio:1;justify-content:center"},
          else: %{}
        )
      )

    ~H"""
    <div
      id={@id}
      data-part="upload"
      phx-hook="LedgerUI.Upload"
      phx-drop-target={@upload.ref}
      class={cx(["lu-col", @class])}
      style="gap:8px"
      {@rest}
    >
      <.live_file_input
        upload={@upload}
        style="position:absolute;width:1px;height:1px;opacity:0;overflow:hidden"
      />
      <%= cond do %>
        <% @layout == "thumbs" -> %>
          <.upload_thumbs columns={@columns}>
            <i :for={e <- @entries} style="position:relative;overflow:hidden">
              <.live_img_preview
                :if={e.image?}
                entry={e.entry}
                style="width:100%;height:100%;object-fit:cover"
              />
            </i>
            <label
              for={@input_id}
              style="width:64px;height:64px;border-radius:10px;border:1.5px dashed var(--line-strong);display:grid;place-items:center;cursor:pointer;color:var(--muted)"
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
            keep-class
          >
            <%= if @label != [] do %>
              {render_slot(@label)}
            <% else %>
              {@drop_label} <u>{@browse_label}</u>
            <% end %>
          </.upload_zone>
        <% true -> %>
          <.upload_drop
            for={@input_id}
            hint={@hint}
            drop_label={@drop_label}
            browse_label={@browse_label}
            icon_path={@icon_path}
            error={@errors != []}
            class={@drop_class}
            keep-class
            {@circle_attrs}
          >
            <:label :if={@label != []}>{render_slot(@label)}</:label>
          </.upload_drop>
      <% end %>
      <span
        :if={@browse && @layout != "thumbs"}
        class="lu-b c-neutral v-outline s-xs sh-rounded"
        style="align-self:center"
      >
        <.icon name="upload" />{@browse}
      </span>
      <span :for={err <- @errors} class="lu-xs" style="color:var(--neg)">{err}</span>
      <div :if={@layout != "thumbs" and @entries != []} {@grid_attrs}>
        <.upload_file
          :for={e <- @entries}
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
              style="width:34px;height:34px;border-radius:8px;object-fit:cover;flex:none"
            />
          </:preview>
        </.upload_file>
      </div>
    </div>
    """
  end

  defp grid_attrs(1), do: %{class: "lu-col", style: "gap:8px"}

  defp grid_attrs(n),
    do: %{style: "display:grid;grid-template-columns:repeat(#{n},minmax(0,1fr));gap:8px"}

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
