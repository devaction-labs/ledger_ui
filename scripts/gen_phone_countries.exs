# Regenerates priv/static/ledger_ui/lib/phone_countries.js from LedgerUI.Components.PhoneInput.Format.
#
#     mix run scripts/gen_phone_countries.exs
root = Path.expand("..", __DIR__)

File.write!(
  Path.join(root, "priv/static/ledger_ui/lib/phone_countries.js"),
  LedgerUI.Components.PhoneInput.Format.js_module()
)
