defmodule LedgerUI.Components.PhoneInput do
  @moduledoc """
  A phone number field with a country picker: a button at the left with the ISO code and the
  calling code (`BR +55`), and the number input. The number is written in the national format of
  the country as it is typed (`(11) 91234-5678`); what the form submits is the E.164 number
  (`+5511912345678`).

      <.phone_input field={@form[:phone]} label="Telefone" />
      <.phone_input name="phone" country="US" label="Phone number" />
      <.phone_input field={@form[:phone]} country="PT" country_order={~w(PT BR)} />
      <.phone_input field={@form[:phone]} countries={~w(BR PT AR UY)} clearable />
      <.phone_input name="phone" value="+5511912345678" size="lg" variant="filled" />

  `country` is the country the field starts with (`"BR"` by default); a `value` in E.164 selects
  its own country. The picker is a searchable list (by name in Portuguese or English, ISO code or
  calling code); `country_order` lists the countries shown first, `countries` limits the list and
  `except` removes some. ISO codes are shown instead of flag emoji unless `flags` is set.

  A hidden input with the field's name carries the E.164 number (empty while there are no
  digits) and fires a bubbling `input` event when it changes, so `phx-change` runs; the visible
  input has no name. `phx-debounce` and `phx-throttle` go to the hidden input.

  ## Formatting is not validation

  The format only helps reading. Validate on the server with
  `LedgerUI.Components.PhoneInput.Format.e164/2`:

      case LedgerUI.Components.PhoneInput.Format.e164(params["phone"], "BR") do
        {:ok, e164} -> e164
        {:error, reason} -> reason
      end

  The list is not in the HTML: the markup carries only the ISO codes the field offers, in order
  (`data-lu-countries`), and the hook builds the rows when it mounts from the country data shipped
  once in `priv/static/ledger_ui/lib/phone_countries.js` (generated from `Format` by
  `mix run scripts/gen_phone_countries.exs`). Without JS the field shows the selected country and
  takes the number.

  The behaviour lives in the `LedgerUI.PhoneInput` hook (`phone_input.js`), so the field needs a
  stable `id` (from `field` or `name`).
  """
  use LedgerUI.Component

  alias LedgerUI.Components.FieldBox
  alias LedgerUI.Components.Form
  alias LedgerUI.Components.PhoneInput.Format
  alias LedgerUI.Components.Select.Options

  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :any, default: nil
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :country, :string, default: "BR"
  attr :country_order, :list, default: []
  attr :countries, :list, default: []
  attr :except, :list, default: []

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`: the texts and the country names. Default: the process locale, the app config; the country names are Portuguese when none is set (the texts, English)."

  attr :flags, :boolean, default: false
  attr :label, :string, default: nil
  attr :label_class, :any, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :state, :string, default: nil, values: [nil, "", "success", "error"]
  attr :disabled, :boolean, default: false
  attr :variant, :string, default: "outlined", values: ~w(outlined filled)
  attr :size, :string, default: "md", values: ~w(sm md lg)
  attr :shape, :string, default: "rounded", values: ~w(rounded pill)
  attr :clearable, :boolean, default: false
  attr :clear_label, :string, default: nil
  attr :picker_label, :string, default: nil
  attr :search_placeholder, :string, default: nil
  attr :no_results, :string, default: nil
  attr :on_country_change, :string, default: nil
  attr :target, :any, default: nil
  attr :wrapper_class, :any, default: nil
  attr :class, :any, default: nil
  attr :style, :string, default: nil, doc: "Inline style of the box (e.g. a width)."
  attr :rest, :global, include: ~w(autocomplete autofocus form placeholder readonly required)

  @doc "Renders the phone input."
  def phone_input(assigns) do
    assigns =
      I18n.texts(assigns,
        clear_label: "common.clear",
        picker_label: "phone.country",
        search_placeholder: "common.search_ellipsis",
        no_results: "select.no_results"
      )

    assigns = Form.lu_assign_field(assigns)
    errors = assigns.errors
    id = assigns.id || (assigns.name && String.replace(assigns.name, ~r/[^A-Za-z0-9_-]+/u, "-"))
    if id == nil, do: raise(ArgumentError, "phone_input needs an id (or name or field)")

    pt? = I18n.locale(assigns.locale, "pt_BR") == "pt_BR"
    list = Format.offered(assigns.countries, assigns.except, assigns.country_order, pt?)
    {iso, digits} = Format.initial(assigns.value, assigns.country, list)
    selected = Enum.find(list, &(&1.iso == iso)) || List.first(list)

    shown = if digits == "", do: "", else: Format.format_national(digits, selected)
    e164 = if digits == "", do: "", else: "+" <> selected.dial <> digits

    rest = assigns.rest

    box_class = [
      FieldBox.classes(
        if(assigns.variant == "filled", do: "filled", else: "outlined"),
        assigns.size,
        assigns.shape,
        if(errors != [],
          do: "error",
          else: if(assigns.state in [nil, ""], do: nil, else: assigns.state)
        ),
        assigns.disabled
      ),
      assigns.class
    ]

    assigns =
      assigns
      |> assign(:pid, id)
      |> assign(:iso_list, Enum.map_join(list, ",", & &1.iso))
      |> assign(:selected, selected)
      |> assign(:shown, shown)
      |> assign(:e164, e164)
      |> assign(:pt, pt?)
      |> assign(:box_class, box_class)
      |> assign(:label_id, assigns.label && id <> "-label")
      |> assign(:required, rest[:required] in [true, "true", "required", ""])
      |> assign(:debounce, Map.take(rest, [:"phx-debounce", :"phx-throttle"]))
      |> assign(:input_rest, Map.drop(rest, [:"phx-debounce", :"phx-throttle"]))
      |> assign(:data_target, if(assigns.target, do: to_string(assigns.target)))
      |> assign(:invalid, errors != [] or assigns.state == "error")

    ~H"""
    <Form.field
      as="div"
      label={@label}
      label_class={@label_class}
      label_id={@label_id}
      help={@help}
      errors={@errors}
      state={@state}
      required={@required}
      class={@wrapper_class}
    >
      <div
        data-part="phone-input"
        id={@pid <> "-wrap"}
        phx-hook="LedgerUI.PhoneInput"
        data-lu-country={@selected.iso}
        data-lu-flags={@flags && "true"}
        data-lu-countries={@iso_list}
        data-lu-pt={@pt && "true"}
        data-lu-on-country-change={@on_country_change}
        data-lu-target={@data_target}
        data-lu-no-results={@no_results}
        data-lu-value={@e164}
        class="relative"
      >
        <span data-part="phone-box" class={@box_class} {if @style, do: %{style: @style}, else: %{}}>
          <span
            data-part="phone-picker"
            class={[
              "mr-0.5 flex cursor-pointer items-center self-stretch border-r border-line pr-2.5 text-[13.5px] text-muted",
              if(@flags, do: "gap-1", else: "gap-1.5")
            ]}
            data-lu-phone-picker
            role="button"
            tabindex={if @disabled, do: "-1", else: "0"}
            aria-haspopup="listbox"
            aria-expanded="false"
            aria-label={@picker_label}
            aria-disabled={@disabled && "true"}
          >
            <b class={if(@flags, do: "font-normal", else: "text-xs")} data-lu-phone-iso>{if @flags,
              do: @selected.flag,
              else: @selected.iso}</b><span data-lu-phone-dial>+{@selected.dial}</span>
          </span>
          <input
            id={@pid}
            data-part="phone-input-control"
            class={FieldBox.control_class()}
            type="tel"
            inputmode="tel"
            autocomplete="tel-national"
            value={@shown}
            disabled={@disabled}
            aria-labelledby={@label_id}
            aria-invalid={@invalid && "true"}
            data-lu-phone-number
            {@input_rest}
          />
          <button
            :if={@clearable}
            type="button"
            data-part="phone-clear"
            class="-mr-1.5 grid size-7 cursor-pointer place-items-center rounded-[7px] border-0 bg-transparent text-muted hover:bg-hover hover:text-ink"
            data-lu-phone-clear
            aria-label={@clear_label}
            hidden={@shown == ""}
            disabled={@disabled}
          >
            <.icon name="x" size="sm" />
          </button>
        </span>
        <input type="hidden" name={@name} value={@e164} data-lu-phone-value {@debounce} />
        <div
          id={@pid <> "-pop"}
          phx-update="ignore"
          data-part="phone-panel"
          class={[
            Options.panel_class("min-w-[max(100%,16rem)]"),
            "fixed m-0 max-h-72 overflow-auto"
          ]}
          popover="manual"
          data-lu-placement="bottom-start"
          data-lu-phone-pop
          hidden
        >
          <div
            data-part="phone-search"
            class="-mx-[5px] -mt-[5px] mb-[5px] flex h-9 items-center gap-2 border-b border-line px-2.5 text-muted"
          >
            <.icon name="search" size="sm" />
            <input
              type="text"
              class="min-w-0 flex-1 border-0 bg-transparent text-sm text-ink outline-0"
              data-lu-phone-search
              placeholder={@search_placeholder}
              autocomplete="off"
              aria-label={@search_placeholder}
            />
          </div>
          <div
            role="listbox"
            aria-label={@picker_label}
            data-lu-phone-list
            data-lu-row-class={Options.item_class()}
            data-lu-right-class={Options.right_class()}
          >
          </div>
          <div
            data-part="phone-empty"
            class={Options.group_label_class()}
            data-lu-phone-empty
            hidden
          >
            {@no_results}
          </div>
        </div>
      </div>
    </Form.field>
    """
  end
end

defmodule LedgerUI.Components.PhoneInput.Format do
  @moduledoc """
  Country data and number formatting for `LedgerUI.Components.PhoneInput`.

  `e164/2` reads a submitted number the way the field does and normalizes it to E.164. It
  rejects what cannot be a number but does not know which numbers a carrier issues; for that,
  check the E.164 string with a library that has number metadata.

      iex> LedgerUI.Components.PhoneInput.Format.e164("(11) 91234-5678", "BR")
      {:ok, "+5511912345678"}
      iex> LedgerUI.Components.PhoneInput.Format.e164("+351 912 345 678", "BR")
      {:ok, "+351912345678"}
      iex> LedgerUI.Components.PhoneInput.Format.e164("12", "BR")
      {:error, :too_short}
  """

  # ISO | calling code | trunk prefix | national formats (`;`, `#` = digit, ordered by length)
  #     | name pt | name en | area codes of a shared calling code | `*` = main country of the code
  @data """
  BR|55|0|(##) ####-####;(##) #####-####|Brasil|Brazil||*
  PT|351||### ### ###|Portugal|Portugal||*
  US|1|1|(###) ###-####|Estados Unidos|United States||*
  CA|1|1|(###) ###-####|Canadá|Canada|204,226,236,249,250,289,306,343,365,367,403,416,418,431,437,438,450,506,514,519,548,579,581,587,604,613,639,647,672,705,709,742,778,780,807,819,825,867,873,902,905|
  PR|1|1|(###) ###-####|Porto Rico|Puerto Rico|787,939|
  JM|1|1|(###) ###-####|Jamaica|Jamaica|876|
  DO|1|1|(###) ###-####|República Dominicana|Dominican Republic|809,829,849|
  BS|1|1|(###) ###-####|Bahamas|Bahamas|242|
  BB|1|1|(###) ###-####|Barbados|Barbados|246|
  TT|1|1|(###) ###-####|Trinidad e Tobago|Trinidad and Tobago|868|
  AR|54|0|## ####-####|Argentina|Argentina||*
  UY|598|0|## ### ###|Uruguai|Uruguay||*
  PY|595|0|### ######|Paraguai|Paraguay||*
  CL|56||# #### ####|Chile|Chile||*
  BO|591||# ### ####|Bolívia|Bolivia||*
  PE|51|0|### ### ###|Peru|Peru||*
  CO|57||### ### ####|Colômbia|Colombia||*
  VE|58|0|###-#######|Venezuela|Venezuela||*
  EC|593|0|## ### ####|Equador|Ecuador||*
  MX|52||## #### ####|México|Mexico||*
  CU|53||# ### ####|Cuba|Cuba||*
  CR|506||#### ####|Costa Rica|Costa Rica||*
  PA|507||#### ####|Panamá|Panama||*
  GT|502||#### ####|Guatemala|Guatemala||*
  HN|504||####-####|Honduras|Honduras||*
  SV|503||####-####|El Salvador|El Salvador||*
  NI|505||#### ####|Nicarágua|Nicaragua||*
  HT|509||## ## ####|Haiti|Haiti||*
  GB|44|0|#### ######|Reino Unido|United Kingdom||*
  GG|44|0|#### ######|Guernsey|Guernsey|7781,7839,7911|
  JE|44|0|#### ######|Jersey|Jersey|7509,7700,7797,7829,7937|
  IM|44|0|#### ######|Ilha de Man|Isle of Man|7624,7524,7924|
  IE|353|0|## ### ####|Irlanda|Ireland||*
  ES|34||### ## ## ##|Espanha|Spain||*
  FR|33|0|# ## ## ## ##|França|France||*
  DE|49|0|#### #######|Alemanha|Germany||*
  IT|39||### ### ####|Itália|Italy||*
  NL|31|0|# ########|Países Baixos|Netherlands||*
  BE|32|0|### ## ## ##|Bélgica|Belgium||*
  LU|352||### ### ###|Luxemburgo|Luxembourg||*
  CH|41|0|## ### ## ##|Suíça|Switzerland||*
  AT|43|0|### ######|Áustria|Austria||*
  SE|46|0|##-### ## ##|Suécia|Sweden||*
  NO|47||### ## ###|Noruega|Norway||*
  DK|45||## ## ## ##|Dinamarca|Denmark||*
  FI|358|0|## ### ####|Finlândia|Finland||*
  IS|354||### ####|Islândia|Iceland||*
  PL|48||### ### ###|Polônia|Poland||*
  CZ|420||### ### ###|Tchéquia|Czechia||*
  SK|421|0|### ### ###|Eslováquia|Slovakia||*
  HU|36|06|## ### ####|Hungria|Hungary||*
  RO|40|0|### ### ###|Romênia|Romania||*
  BG|359|0|## ### ####|Bulgária|Bulgaria||*
  GR|30||### ### ####|Grécia|Greece||*
  HR|385|0|## ### ####|Croácia|Croatia||*
  RS|381|0|## ### ####|Sérvia|Serbia||*
  UA|380|0|## ### ####|Ucrânia|Ukraine||*
  RU|7|8|(###) ###-##-##|Rússia|Russia||*
  KZ|7|8|(###) ###-##-##|Cazaquistão|Kazakhstan|6,7|
  TR|90|0|(###) ### ## ##|Turquia|Turkey||*
  IL|972|0|##-###-####|Israel|Israel||*
  AE|971|0|## ### ####|Emirados Árabes Unidos|United Arab Emirates||*
  SA|966|0|## ### ####|Arábia Saudita|Saudi Arabia||*
  QA|974||#### ####|Catar|Qatar||*
  EG|20|0|### ### ####|Egito|Egypt||*
  MA|212|0|##-#######|Marrocos|Morocco||*
  DZ|213|0|### ## ## ##|Argélia|Algeria||*
  TN|216||## ### ###|Tunísia|Tunisia||*
  NG|234|0|### ### ####|Nigéria|Nigeria||*
  GH|233|0|## ### ####|Gana|Ghana||*
  KE|254|0|### ######|Quênia|Kenya||*
  ZA|27|0|## ### ####|África do Sul|South Africa||*
  AO|244||### ### ###|Angola|Angola||*
  MZ|258||## ### ####|Moçambique|Mozambique||*
  CV|238||### ## ##|Cabo Verde|Cape Verde||*
  GW|245||### ####|Guiné-Bissau|Guinea-Bissau||*
  ST|239||### ####|São Tomé e Príncipe|Sao Tome and Principe||*
  TL|670||#### ####|Timor-Leste|Timor-Leste||*
  IN|91|0|#####-#####|Índia|India||*
  PK|92|0|### #######|Paquistão|Pakistan||*
  BD|880|0|####-######|Bangladesh|Bangladesh||*
  CN|86|0|### #### ####|China|China||*
  HK|852||#### ####|Hong Kong|Hong Kong||*
  TW|886|0|### ### ###|Taiwan|Taiwan||*
  JP|81|0|##-####-####|Japão|Japan||*
  KR|82|0|##-####-####|Coreia do Sul|South Korea||*
  ID|62|0|###-####-####|Indonésia|Indonesia||*
  MY|60|0|##-### ####|Malásia|Malaysia||*
  SG|65||#### ####|Singapura|Singapore||*
  TH|66|0|## ### ####|Tailândia|Thailand||*
  VN|84|0|## ### ## ##|Vietnã|Vietnam||*
  PH|63|0|### ### ####|Filipinas|Philippines||*
  AU|61|0|### ### ###|Austrália|Australia||*
  NZ|64|0|## ### ####|Nova Zelândia|New Zealand||*
  """

  @aliases %{
    "US" => "usa eua united states of america estados unidos da america",
    "GB" => "uk gb great britain inglaterra england",
    "AE" => "uae emirados",
    "KR" => "coreia korea",
    "CZ" => "republica tcheca czech republic"
  }

  @countries @data
             |> String.split("\n", trim: true)
             |> Enum.map(&String.trim/1)
             |> Enum.reject(&(&1 == ""))
             |> Enum.map(fn line ->
               [iso, dial, trunk, formats, pt, en, areas, main] = String.split(line, "|")

               flag =
                 for <<c <- iso>>, into: "", do: <<0x1F1E6 + c - ?A::utf8>>

               %{
                 iso: iso,
                 dial: dial,
                 trunk: trunk,
                 formats: String.split(formats, ";"),
                 pt: pt,
                 en: en,
                 areas: if(areas == "", do: [], else: String.split(areas, ",")),
                 main: main == "*",
                 flag: flag,
                 search:
                   [iso, pt, en, "+" <> dial, dial, @aliases[iso] || ""]
                   |> Enum.join(" ")
                   |> String.normalize(:nfd)
                   |> String.replace(~r/\p{Mn}/u, "")
                   |> String.downcase()
               }
             end)

  @by_iso Map.new(@countries, &{&1.iso, &1})

  @doc false
  # The source of `priv/static/ledger_ui/lib/phone_countries.js`: the country data the hook uses to
  # build the picker rows (the flag is computed there from the ISO code).
  def js_module do
    rows =
      Enum.map_join(@countries, ",\n", fn c ->
        "  " <>
          Jason.encode!(
            Jason.OrderedObject.new(
              iso: c.iso,
              dial: c.dial,
              trunk: c.trunk,
              formats: c.formats,
              pt: c.pt,
              en: c.en,
              areas: c.areas,
              main: c.main,
              search: c.search
            )
          )
      end)

    "// GENERATED by `mix run scripts/gen_phone_countries.exs` from LedgerUI.Components.PhoneInput.Format. Do not edit.\n" <>
      "// The country data of the phone_input hook, shipped once instead of once per field.\n" <>
      "export default [\n" <> rows <> "\n]\n"
  end

  @doc "All the countries known to the field."
  def all, do: @countries

  @doc "A country by ISO 3166-1 alpha-2 code, or `nil`."
  def get(iso) when is_binary(iso), do: @by_iso[String.upcase(iso)]
  def get(_), do: nil

  @doc false
  # The countries the picker offers, in order: `order` first, then the rest by name.
  def offered(countries, except, order, pt?) do
    except = MapSet.new(except, &String.upcase/1)
    only = if countries == [], do: nil, else: MapSet.new(countries, &String.upcase/1)

    list =
      Enum.filter(@countries, fn c ->
        not MapSet.member?(except, c.iso) and (only == nil or MapSet.member?(only, c.iso))
      end)

    first = order |> Enum.map(&String.upcase/1) |> Enum.with_index() |> Map.new()
    name = fn c -> c |> then(&if(pt?, do: &1.pt, else: &1.en)) |> fold() end

    Enum.sort_by(list, fn c -> {Map.get(first, c.iso, map_size(first)), name.(c)} end)
  end

  defp fold(text),
    do: text |> String.normalize(:nfd) |> String.replace(~r/\p{Mn}/u, "") |> String.downcase()

  @doc false
  # `{iso, national_digits}` for the first render, from `value` (E.164 or national) and the
  # starting `country`.
  def initial(value, country, list) do
    start = start_country(country, list)
    str = value |> to_string() |> String.trim()

    cond do
      str == "" ->
        {start.iso, ""}

      String.starts_with?(str, "+") ->
        case detect(digits(str), list) do
          {c, national} -> {c.iso, national}
          nil -> {start.iso, strip_trunk(digits(str), start)}
        end

      true ->
        {start.iso, strip_trunk(digits(str), start)}
    end
  end

  defp start_country(country, list) do
    Enum.find(list, &(&1.iso == String.upcase(to_string(country)))) || List.first(list) ||
      @by_iso["BR"]
  end

  defp digits(str), do: String.replace(str, ~r/\D/, "")

  defp strip_trunk(digits, %{trunk: ""}), do: digits

  defp strip_trunk(digits, %{trunk: trunk}) do
    if String.starts_with?(digits, trunk),
      do: String.replace_prefix(digits, trunk, ""),
      else: digits
  end

  @doc false
  # Finds the country of `digits` (calling code + number, no "+") among `list`:
  # the longest calling code wins; countries that share it are told apart by area code.
  def detect(digits, list) do
    candidates = Enum.filter(list, &String.starts_with?(digits, &1.dial))

    case candidates do
      [] ->
        nil

      _ ->
        longest = candidates |> Enum.map(&String.length(&1.dial)) |> Enum.max()
        same = Enum.filter(candidates, &(String.length(&1.dial) == longest))
        national = String.slice(digits, longest..-1//1)

        country =
          Enum.find(same, fn c -> Enum.any?(c.areas, &String.starts_with?(national, &1)) end) ||
            Enum.find(same, & &1.main) || hd(same)

        {country, strip_trunk(national, country)}
    end
  end

  @doc """
  Formats national `digits` in the pattern of `country` (a map from `all/0` or an ISO code).
  A separator only appears when a digit follows it, and extra digits are kept.

      iex> LedgerUI.Components.PhoneInput.Format.format_national("11912345678", "BR")
      "(11) 91234-5678"
      iex> LedgerUI.Components.PhoneInput.Format.format_national("119", "BR")
      "(11) 9"
  """
  def format_national(digits, iso) when is_binary(iso), do: format_national(digits, get(iso))

  def format_national(digits, %{formats: formats}) do
    len = String.length(digits)

    pattern =
      Enum.find(formats, List.last(formats), fn p ->
        p |> String.graphemes() |> Enum.count(&(&1 == "#")) >= len
      end)

    fill(String.graphemes(pattern), String.graphemes(digits), [], [])
  end

  # Pending literals are only written once the next digit arrives.
  defp fill(_pattern, [], _lits, acc), do: acc |> Enum.reverse() |> IO.iodata_to_binary()
  defp fill([], rest, _lits, acc), do: IO.iodata_to_binary(Enum.reverse(acc, rest))

  defp fill(["#" | p], [d | ds], lits, acc), do: fill(p, ds, [], [d | Enum.reverse(lits) ++ acc])
  defp fill([lit | p], ds, lits, acc), do: fill(p, ds, lits ++ [lit], acc)

  @doc """
  Reads a submitted number and normalizes it to E.164.

  A number starting with `+` (or `00`) carries its own country; any other is read as a national
  number of `default_country` (its trunk prefix is dropped). Returns `{:ok, "+5511912345678"}` or
  `{:error, reason}` with `:empty`, `:unknown_country`, `:too_short` or `:too_long`.
  """
  @spec e164(String.t() | nil, String.t()) :: {:ok, String.t()} | {:error, atom()}
  def e164(input, default_country \\ "BR") do
    str = input |> to_string() |> String.trim()
    all = @countries

    cond do
      digits(str) == "" ->
        {:error, :empty}

      String.starts_with?(str, "+") or String.starts_with?(str, "00") ->
        d = str |> String.replace_prefix("+", "") |> String.replace_prefix("00", "") |> digits()

        case detect(d, all) do
          nil -> {:error, :unknown_country}
          {country, national} -> check(country, national)
        end

      true ->
        country = get(default_country) || @by_iso["BR"]
        check(country, strip_trunk(digits(str), country))
    end
  end

  defp check(country, national) do
    len = String.length(national)

    cond do
      len < 4 -> {:error, :too_short}
      len + String.length(country.dial) > 15 -> {:error, :too_long}
      true -> {:ok, "+" <> country.dial <> national}
    end
  end
end
