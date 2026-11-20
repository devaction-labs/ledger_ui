defmodule LedgerShowcaseWeb.Templates.PaletteHook do
  @moduledoc """
  `on_mount` of the template pages: `?palette=crepusculo` becomes the assign `:palette`
  (`nil` when absent or unknown), which `Shell.frame/1` puts on the template root as
  `data-palette`. The page `<html>` gets the same attribute from the root layout script before
  the first paint (and from `localStorage["lu-palette"]`).
  """
  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView, only: [attach_hook: 4]

  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
     |> assign(:palette, nil)
     |> attach_hook(:palette, :handle_params, fn params, _uri, socket ->
       {:cont, assign(socket, :palette, palette(params["palette"]))}
     end)}
  end

  @doc "The palette id of a `?palette=` value, or `nil`."
  def palette(id) when is_binary(id) do
    if id in LedgerShowcase.Templates.palettes(), do: id
  end

  def palette(_), do: nil
end
