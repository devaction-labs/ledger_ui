defmodule LedgerUI.LinkAttrs do
  @moduledoc """
  The attributes `Phoenix.Component.link/1` puts on its `<a>`, computed ahead of the template.

  A component that writes `<.link {@rest}>` sends the whole opening tag again whenever only its
  body changes (a function component called with a spread is never "unchanged"). A component that
  computes these attributes in its body (`resolve/1`, settled on `:rest`) and writes
  `<a data-part=".." class=".." {@rest}>` itself sends only the body. The result is the same set of
  attributes as `<.link>` renders for the same input (the order may differ; the DOM is the same).

  `test/ledger_ui/link_attrs_test.exs` renders both and compares them, so a change in a future
  Phoenix LiveView (a new attribute on `link/1`) fails there instead of drifting silently.

  The destination checks are those of `link/1` (`navigate`/`patch` must be a local path, `href` a
  safe URL).
  """

  @link_keys [:navigate, :patch, :href, :replace, :method, :csrf_token]

  @doc """
  Turns the link attributes (`navigate`, `patch`, `href`, `replace`, `method`, `csrf_token`) found in
  `attrs` (a map or a keyword) into the final attributes of the `<a>`, and keeps every other key.

  `own` names the attributes the component writes itself on the `<a>` (`"data-part"`, `"class"`,
  `"aria-disabled"`...): as with `<.link data-part=".." {@rest}>`, the component's value wins over
  the caller's, so the caller's is left out of the result (otherwise the tag would carry both).
  """
  @spec resolve(map() | keyword(), [String.t()]) :: map()
  def resolve(attrs, own \\ []) do
    attrs = Map.new(attrs)
    rest = attrs |> Map.drop(@link_keys) |> Map.reject(fn {k, _} -> to_string(k) in own end)
    Map.merge(rest, link(attrs[:navigate], attrs[:patch], attrs[:href], attrs))
  end

  defp link(to, _patch, _href, attrs) when is_binary(to) do
    Phoenix.LiveView.Utils.valid_live_navigation_destination!(to, "<.link navigate>")
    %{:href => to, "data-phx-link" => "redirect", "data-phx-link-state" => state(attrs)}
  end

  defp link(_nav, to, _href, attrs) when is_binary(to) do
    Phoenix.LiveView.Utils.valid_live_navigation_destination!(to, "<.link patch>")
    %{:href => to, "data-phx-link" => "patch", "data-phx-link-state" => state(attrs)}
  end

  defp link(_nav, _patch, href, attrs) when href != "#" and not is_nil(href) do
    href = Phoenix.LiveView.Utils.valid_destination!(href, "<.link>")
    method = Map.get(attrs, :method, "get")

    if method == "get" do
      %{href: href}
    else
      %{
        :href => href,
        "data-method" => method,
        "data-csrf" => csrf_token(Map.get(attrs, :csrf_token, true), href),
        "data-to" => href
      }
    end
  end

  defp link(_nav, _patch, _href, _attrs), do: %{href: "#"}

  defp state(attrs), do: if(Map.get(attrs, :replace, false), do: "replace", else: "push")

  defp csrf_token(true, href), do: Plug.CSRFProtection.get_csrf_token_for(href)
  defp csrf_token(false, _href), do: nil
  defp csrf_token(csrf, _href) when is_binary(csrf), do: csrf
end
