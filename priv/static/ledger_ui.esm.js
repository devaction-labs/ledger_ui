// Ledger UI JS entry (ES module, hand-written, no build step).
//
//   import {Hooks as LedgerHooks, DOM as LedgerDOM} from "ledger_ui"
//
// The block between the GENERATED markers is rewritten by `elixir scripts/gen_hooks_index.exs`
// from the files in priv/static/ledger_ui/hooks/ (dropdown.js -> "LedgerUI.Dropdown").
// Everything outside the markers is edited by hand.

// GENERATED:IMPORTS:START
import HookActionMenu from "./ledger_ui/hooks/action_menu.js"
import HookAiComposer from "./ledger_ui/hooks/ai_composer.js"
import HookAppShell from "./ledger_ui/hooks/app_shell.js"
import HookAutocomplete from "./ledger_ui/hooks/autocomplete.js"
import HookAvatarMore from "./ledger_ui/hooks/avatar_more.js"
import HookCalendar from "./ledger_ui/hooks/calendar.js"
import HookCardTable from "./ledger_ui/hooks/card_table.js"
import HookCarousel from "./ledger_ui/hooks/carousel.js"
import HookChart from "./ledger_ui/hooks/chart.js"
import HookClipboard from "./ledger_ui/hooks/clipboard.js"
import HookClock from "./ledger_ui/hooks/clock.js"
import HookCodeBlock from "./ledger_ui/hooks/code_block.js"
import HookCollapse from "./ledger_ui/hooks/collapse.js"
import HookColorPicker from "./ledger_ui/hooks/color_picker.js"
import HookContextMenu from "./ledger_ui/hooks/context_menu.js"
import HookDatePicker from "./ledger_ui/hooks/date_picker.js"
import HookDatetimePicker from "./ledger_ui/hooks/datetime_picker.js"
import HookDonutChart from "./ledger_ui/hooks/donut_chart.js"
import HookDropdown from "./ledger_ui/hooks/dropdown.js"
import HookFab from "./ledger_ui/hooks/fab.js"
import HookFabDial from "./ledger_ui/hooks/fab_dial.js"
import HookFilterMenu from "./ledger_ui/hooks/filter_menu.js"
import HookFloat from "./ledger_ui/hooks/float.js"
import HookFlow from "./ledger_ui/hooks/flow.js"
import HookHotkey from "./ledger_ui/hooks/hotkey.js"
import HookImageInput from "./ledger_ui/hooks/image_input.js"
import HookIndeterminate from "./ledger_ui/hooks/indeterminate.js"
import HookInputMask from "./ledger_ui/hooks/input_mask.js"
import HookLandingNav from "./ledger_ui/hooks/landing_nav.js"
import HookLineChart from "./ledger_ui/hooks/line_chart.js"
import HookMonochromeToggle from "./ledger_ui/hooks/monochrome_toggle.js"
import HookNumberInput from "./ledger_ui/hooks/number_input.js"
import HookOtp from "./ledger_ui/hooks/otp.js"
import HookOverlay from "./ledger_ui/hooks/overlay.js"
import HookPersist from "./ledger_ui/hooks/persist.js"
import HookPhoneInput from "./ledger_ui/hooks/phone_input.js"
import HookPillSelect from "./ledger_ui/hooks/pill_select.js"
import HookPixelCard from "./ledger_ui/hooks/pixel_card.js"
import HookRange from "./ledger_ui/hooks/range.js"
import HookRating from "./ledger_ui/hooks/rating.js"
import HookRightSidebar from "./ledger_ui/hooks/right_sidebar.js"
import HookScrollBottom from "./ledger_ui/hooks/scroll_bottom.js"
import HookScrollspy from "./ledger_ui/hooks/scrollspy.js"
import HookSegmented from "./ledger_ui/hooks/segmented.js"
import HookSelect from "./ledger_ui/hooks/select.js"
import HookSidebar from "./ledger_ui/hooks/sidebar.js"
import HookSignaturePad from "./ledger_ui/hooks/signature_pad.js"
import HookSortable from "./ledger_ui/hooks/sortable.js"
import HookSticky from "./ledger_ui/hooks/sticky.js"
import HookTableCheckbox from "./ledger_ui/hooks/table_checkbox.js"
import HookTabs from "./ledger_ui/hooks/tabs.js"
import HookTagsInput from "./ledger_ui/hooks/tags_input.js"
import HookTextEditor from "./ledger_ui/hooks/text_editor.js"
import HookTextarea from "./ledger_ui/hooks/textarea.js"
import HookThemePicker from "./ledger_ui/hooks/theme_picker.js"
import HookThemeSwitch from "./ledger_ui/hooks/theme_switch.js"
import HookTimePicker from "./ledger_ui/hooks/time_picker.js"
import HookTimer from "./ledger_ui/hooks/timer.js"
import HookToaster from "./ledger_ui/hooks/toaster.js"
import HookTreeview from "./ledger_ui/hooks/treeview.js"
import HookUpload from "./ledger_ui/hooks/upload.js"
// GENERATED:IMPORTS:END

export const Hooks = {
// GENERATED:HOOKS:START
  "LedgerUI.ActionMenu": HookActionMenu,
  "LedgerUI.AiComposer": HookAiComposer,
  "LedgerUI.AppShell": HookAppShell,
  "LedgerUI.Autocomplete": HookAutocomplete,
  "LedgerUI.AvatarMore": HookAvatarMore,
  "LedgerUI.Calendar": HookCalendar,
  "LedgerUI.CardTable": HookCardTable,
  "LedgerUI.Carousel": HookCarousel,
  "LedgerUI.Chart": HookChart,
  "LedgerUI.Clipboard": HookClipboard,
  "LedgerUI.Clock": HookClock,
  "LedgerUI.CodeBlock": HookCodeBlock,
  "LedgerUI.Collapse": HookCollapse,
  "LedgerUI.ColorPicker": HookColorPicker,
  "LedgerUI.ContextMenu": HookContextMenu,
  "LedgerUI.DatePicker": HookDatePicker,
  "LedgerUI.DatetimePicker": HookDatetimePicker,
  "LedgerUI.DonutChart": HookDonutChart,
  "LedgerUI.Dropdown": HookDropdown,
  "LedgerUI.Fab": HookFab,
  "LedgerUI.FabDial": HookFabDial,
  "LedgerUI.FilterMenu": HookFilterMenu,
  "LedgerUI.Float": HookFloat,
  "LedgerUI.Flow": HookFlow,
  "LedgerUI.Hotkey": HookHotkey,
  "LedgerUI.ImageInput": HookImageInput,
  "LedgerUI.Indeterminate": HookIndeterminate,
  "LedgerUI.InputMask": HookInputMask,
  "LedgerUI.LandingNav": HookLandingNav,
  "LedgerUI.LineChart": HookLineChart,
  "LedgerUI.MonochromeToggle": HookMonochromeToggle,
  "LedgerUI.NumberInput": HookNumberInput,
  "LedgerUI.Otp": HookOtp,
  "LedgerUI.Overlay": HookOverlay,
  "LedgerUI.Persist": HookPersist,
  "LedgerUI.PhoneInput": HookPhoneInput,
  "LedgerUI.PillSelect": HookPillSelect,
  "LedgerUI.PixelCard": HookPixelCard,
  "LedgerUI.Range": HookRange,
  "LedgerUI.Rating": HookRating,
  "LedgerUI.RightSidebar": HookRightSidebar,
  "LedgerUI.ScrollBottom": HookScrollBottom,
  "LedgerUI.Scrollspy": HookScrollspy,
  "LedgerUI.Segmented": HookSegmented,
  "LedgerUI.Select": HookSelect,
  "LedgerUI.Sidebar": HookSidebar,
  "LedgerUI.SignaturePad": HookSignaturePad,
  "LedgerUI.Sortable": HookSortable,
  "LedgerUI.Sticky": HookSticky,
  "LedgerUI.TableCheckbox": HookTableCheckbox,
  "LedgerUI.Tabs": HookTabs,
  "LedgerUI.TagsInput": HookTagsInput,
  "LedgerUI.TextEditor": HookTextEditor,
  "LedgerUI.Textarea": HookTextarea,
  "LedgerUI.ThemePicker": HookThemePicker,
  "LedgerUI.ThemeSwitch": HookThemeSwitch,
  "LedgerUI.TimePicker": HookTimePicker,
  "LedgerUI.Timer": HookTimer,
  "LedgerUI.Toaster": HookToaster,
  "LedgerUI.Treeview": HookTreeview,
  "LedgerUI.Upload": HookUpload,
// GENERATED:HOOKS:END
}

// Resyncs a form control's derived UI after LiveView patched it: hooks listen to `lu:sync`.
function resyncAfterPatch(el) {
  queueMicrotask(() => el.dispatchEvent(new CustomEvent("lu:sync", {bubbles: true})))
}

export const DOM = {
  // `keep-<attr>` on an element preserves that attribute across LiveView patches, e.g.
  // <div keep-data-state data-state="open">. (`keep-hidden`, `keep-style`, `keep-class`
  // are handled below.)
  copyDataAttributes(from, to) {
    for (const attr of Array.from(from.attributes)) {
      if (!attr.name.startsWith("keep-")) continue
      const name = attr.name.slice(5)
      if (name === "style" || name === "hidden" || name === "class") continue
      if (from.hasAttribute(name)) to.setAttribute(name, from.getAttribute(name))
    }
  },

  // Preserves client-managed state during LiveView DOM patches:
  // - `keep-hidden`: the `hidden` property
  // - `keep-style`: inline style (positioning, transforms)
  // - `keep-class`: className (animation classes)
  // Overlays (`[data-state]`, `.open`) keep their state automatically.
  onBeforeElUpdated(from, to) {
    if (from.hasAttribute("keep-hidden")) to.hidden = from.hidden
    if (from.hasAttribute("keep-style")) {
      if (from.hasAttribute("style")) to.style.cssText = from.style.cssText
      else to.removeAttribute("style")
    }
    if (from.hasAttribute("keep-class")) to.className = from.className
    else if (from.hasAttribute("data-lu-overlay")) {
      if (from.classList.contains("open")) to.classList.add("open")
      else to.classList.remove("open")
      const state = from.getAttribute("data-state")
      if (state !== null) to.setAttribute("data-state", state)
    }
    this.copyDataAttributes(from, to)
    if (/^(OPTION|SELECT|INPUT|TEXTAREA)$/.test(from.nodeName)) resyncAfterPatch(from)
  },
}

// Server-side LedgerUI.open(socket, id) / close(socket, id).
if (typeof window !== "undefined") {
  const toggleOpen = (id, on) => {
    const el = document.getElementById(id)
    if (!el) return
    el.classList.toggle("open", on)
    for (const t of document.querySelectorAll(`[aria-controls="${CSS.escape(id)}"]`))
      t.setAttribute("aria-expanded", String(on))
  }
  window.addEventListener("phx:ledger:open", (e) => toggleOpen(e.detail.id, true))
  window.addEventListener("phx:ledger:close", (e) => toggleOpen(e.detail.id, false))
}

export default {Hooks, DOM}
