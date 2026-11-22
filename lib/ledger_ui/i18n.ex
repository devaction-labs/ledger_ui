defmodule LedgerUI.I18n do
  @moduledoc """
  The single source of the kit's translations (`"en"` and `"pt_BR"`).

  Every visible default text, `aria-label`, `title`, placeholder, `sr-only` text, empty state,
  month and weekday name... of the components comes from here. An explicit attr from the caller
  (`label="Fechar"`) always wins over a translation.

  ## Which locale is used

  From the highest to the lowest precedence:

  1. the component's `locale` attr (`<.pagination locale="pt_BR" />`);
  2. the locale of the process (`LedgerUI.put_locale/1`, or `on_mount` below);
  3. the application config: `config :ledger_ui, locale: "pt_BR"`;
  4. `"en"`.

  `"pt"`, `"pt-BR"` and `"pt_br"` are the same as `"pt_BR"`; any other value is `"en"`.

  ## The process locale

  Set it once per request or per LiveView; everything rendered by that process follows it:

      # a plug of the router pipeline
      def set_locale(conn, _opts) do
        LedgerUI.put_locale(get_session(conn, :locale))
        conn
      end

      # a LiveView (the locale from the session) ...
      on_mount {LedgerUI.I18n, :default}
      # ... or a fixed one
      on_mount {LedgerUI.I18n, {:locale, "pt_BR"}}

  `:default` reads `"locale"` from the session (nothing is changed when it is absent), so put it
  there in your own plug (`put_session(conn, :locale, "pt_BR")`). The connected LiveView is another
  process than the one of the first (disconnected) render, so use `on_mount` for LiveViews.

  ## Texts that components receive

  A component that has no `locale` attr is not translated apart: it follows the process/app locale.
  The JS hooks never hard-code text: the components pass the translated strings as
  `data-lu-*` attributes.
  """

  @locales ~w(en pt_BR)
  @key :ledger_ui_locale

  @doc "The supported locales."
  @spec locales() :: [String.t()]
  def locales, do: @locales

  @doc """
  Normalizes a locale: `"pt_BR"`, `"pt-BR"`, `"pt"` and `:pt_BR` become `"pt_BR"`, anything else `"en"`.
  `nil` stays `nil`.
  """
  @spec normalize(term()) :: String.t() | nil
  def normalize(nil), do: nil
  def normalize(l) when is_atom(l), do: normalize(Atom.to_string(l))

  def normalize(l) when is_binary(l) do
    case l |> String.replace("-", "_") |> String.downcase() do
      "pt" <> _ -> "pt_BR"
      _ -> "en"
    end
  end

  def normalize(_), do: "en"

  @doc "Sets the locale of the current process (`nil` removes it: back to the app config)."
  @spec put_locale(term()) :: :ok
  def put_locale(nil) do
    Process.delete(@key)
    :ok
  end

  def put_locale(locale) do
    Process.put(@key, normalize(locale))
    :ok
  end

  @doc "The locale of the process, or `nil` when none was set."
  @spec get_locale() :: String.t() | nil
  def get_locale, do: Process.get(@key)

  @doc """
  The locale in effect: `override` (the component's attr) > process > `config :ledger_ui, locale:` >
  `fallback` (`"en"`; the few components whose default is Portuguese pass `"pt_BR"`).
  """
  @spec locale(term(), String.t()) :: String.t()
  def locale(override \\ nil, fallback \\ "en") do
    normalize(override) || get_locale() || normalize(Application.get_env(:ledger_ui, :locale)) ||
      fallback
  end

  @doc """
  The text of `key` in `locale` (see `locale/1`), with `%{name}` placeholders replaced by `bindings`
  (a keyword list or a map). A key missing in `"pt_BR"` falls back to English; an unknown key
  returns the key itself.
  """
  @spec t(String.t(), term(), keyword() | map()) :: String.t()
  def t(key, locale \\ nil, bindings \\ []) do
    loc = locale(locale)
    text = Map.get(messages(loc), key) || Map.get(messages("en"), key) || key
    interpolate(text, bindings)
  end

  @doc """
  Like `t/3` for the texts that are Portuguese by default (their pre-i18n default was Portuguese):
  with no locale set anywhere (attr, process, app config) the text is `"pt_BR"`, so existing apps keep
  rendering the same; any explicit locale (including `"en"`) is honored. In `texts/2` write `{:pt, key}`.
  """
  @spec tp(String.t(), term(), keyword() | map()) :: String.t()
  def tp(key, locale \\ nil, bindings \\ []) do
    t(key, locale(locale, "pt_BR"), bindings)
  end

  @doc """
  `text` unless it is the English text of `key`, then `nil`: for `data-lu-*` attributes read by a
  JS hook that keeps the English text as its own fallback (so the default HTML stays unchanged).
  """
  @spec non_default(String.t() | nil, String.t()) :: String.t() | nil
  def non_default(text, key) do
    if text == Map.get(messages("en"), key), do: nil, else: text
  end

  @doc "The list under `key` (month names, weekdays...)."
  @spec list(String.t(), term()) :: [String.t()]
  def list(key, locale \\ nil) do
    loc = locale(locale)
    Map.get(messages(loc), key) || Map.get(messages("en"), key) || []
  end

  @doc """
  The label map of a component (`"signature"`, `"calendar"`, `"picker"`, `"datetime"`, `"time"`,
  `"color"`): atom keys, English where `locale` lacks one. Callers merge their own `labels` over it.
  """
  @spec labels(String.t(), term()) :: map()
  def labels(group, locale \\ nil) do
    key = "labels." <> group
    Map.merge(Map.get(messages("en"), key, %{}), Map.get(messages(locale(locale)), key, %{}))
  end

  @doc """
  Fills the nil attrs of `assigns` with translations: `texts(assigns, clear_label: "bulk_bar.clear")`.
  An attr where `nil` means "none" uses `:default` as its default and `texts(assigns, mapping, :default)`.
  The locale is `assigns.locale` (when the component has the attr), else the process/app one. Values
  given by the caller are kept (also `""`).
  """
  @spec texts(map(), keyword(), nil | :default) :: map()
  def texts(assigns, mapping, sentinel \\ nil) do
    loc = Map.get(assigns, :locale)

    Enum.reduce(mapping, assigns, fn {attr, key}, acc ->
      if Map.get(acc, attr) == sentinel do
        acc |> Map.put(attr, text_for(key, loc)) |> track(attr)
      else
        acc
      end
    end)
  end

  defp text_for({:pt, key}, loc), do: tp(key, loc)
  defp text_for({:list, key}, loc), do: list(key, loc)
  defp text_for({:pt_list, key}, loc), do: list(key, locale(loc, "pt_BR"))
  defp text_for({:labels, group}, loc), do: labels(group, loc)
  defp text_for(key, loc), do: t(key, loc)

  # The filled text is not an attr the parent changed: re-render it when the `locale` attr does.
  defp track(%{__changed__: %{locale: _} = changed} = assigns, attr),
    do: %{assigns | __changed__: Map.put(changed, attr, true)}

  defp track(assigns, _attr), do: assigns

  defp messages("pt_BR"), do: LedgerUI.I18n.PtBR.messages()
  defp messages(_), do: LedgerUI.I18n.En.messages()

  defp interpolate(text, []), do: text
  defp interpolate(text, b) when b == %{}, do: text

  defp interpolate(text, bindings) do
    b = Map.new(bindings, fn {k, v} -> {to_string(k), v} end)

    Regex.replace(~r/%\{(\w+)\}/, text, fn whole, name ->
      case Map.fetch(b, name) do
        {:ok, v} -> to_string(v)
        :error -> whole
      end
    end)
  end

  @doc false
  def on_mount(:default, _params, session, socket) do
    case session do
      %{"locale" => l} when is_binary(l) or is_atom(l) -> put_locale(l)
      _ -> :ok
    end

    {:cont, socket}
  end

  def on_mount({:locale, locale}, _params, _session, socket) do
    put_locale(locale)
    {:cont, socket}
  end
end
