// LedgerUI.Treeview: opens/closes branches without a round trip, cascades the checkboxes (a branch
// (un)checks everything under it; a branch with only some children checked shows the dash), pushes
// on_toggle / on_select / on_check, and gives the rows their keyboard and ARIA behaviour. It reads
// `data-part` (tree-item, tree-children, tree-chevron, tree-check), never a class. The server render has none of
// this client state, so `updated` applies it again after every patch (the person's toggles
// survive; the server wins for a branch whose `expanded` it changed).
export default {
  mounted() {
    this.open = new Map(); // row key -> open?, what the person left
    this.server = new Map(); // row key -> open? as last rendered by the server
    this.onClick = (e) => this.click(e);
    this.onChange = (e) => this.change(e);
    this.onKey = (e) => this.key(e);
    this.el.addEventListener("click", this.onClick);
    this.el.addEventListener("change", this.onChange);
    this.el.addEventListener("keydown", this.onKey);
    this.apply(true);
  },

  updated() {
    this.apply(false);
  },

  destroyed() {
    this.el.removeEventListener("click", this.onClick);
    this.el.removeEventListener("change", this.onChange);
    this.el.removeEventListener("keydown", this.onKey);
  },

  rows() {
    return Array.from(this.el.querySelectorAll("[data-part=tree-item]"));
  },

  key_of(row, index) {
    return row.id || `tree-item-${index}`;
  },

  kids(row) {
    const next = row.nextElementSibling;
    return next && next.dataset.part === "tree-children" ? next : null;
  },

  chevron(row) {
    return row.querySelector(":scope > [data-part=tree-chevron] > svg");
  },

  box(row) {
    return row.querySelector(":scope > [data-part=tree-check] > input[type=checkbox]");
  },

  // Is the branch open as the server drew it? (down chevron, or children not hidden)
  server_open(row) {
    const icon = this.chevron(row);
    return icon ? icon.dataset.icon === "chevron-down" : false;
  },

  apply(first) {
    const listed = this.listed();
    // role, aria-selected/-expanded/-checked and the roving tabindex come from the server; make
    // sure exactly one row is in the tab order (the first when none is).
    const all = this.rows();
    if (!all.some((r) => r.tabIndex === 0) && all[0]) all[0].tabIndex = 0;
    all.forEach((row, i) => {
      const input = this.box(row);
      if (input) input.indeterminate = input.hasAttribute("data-ind");
      if (this.el.dataset.chevrons === "false") {
        const lead = row.firstElementChild;
        if (lead && (lead.dataset.part === "tree-chevron" || lead.dataset.part === "tree-spacer")) {
          lead.style.display = "none";
        }
      }

      const icon = this.chevron(row);
      const kids = this.kids(row);
      if (!icon && !kids) return;
      const key = this.key_of(row, i);
      const server = this.server_open(row);
      if (first || this.server.get(key) !== server || listed.has(row.id)) {
        if (listed.has(row.id)) this.open.set(key, true);
        else this.open.set(key, server);
      }
      this.server.set(key, server);
      this.show(row, this.open.get(key), server);
    });
  },

  listed() {
    try {
      return new Set(JSON.parse(this.el.dataset.expanded || "[]"));
    } catch (_e) {
      return new Set();
    }
  },

  show(row, open, serverOpen) {
    const kids = this.kids(row);
    if (kids) kids.hidden = !open;
    row.setAttribute("aria-expanded", open ? "true" : "false");
    const icon = this.chevron(row);
    if (icon) {
      icon.style.transition = "transform .15s";
      icon.style.transform = open === serverOpen ? "" : open ? "rotate(90deg)" : "rotate(-90deg)";
    }
  },

  click(e) {
    const row = e.target.closest("[data-part=tree-item]");
    if (!row || !this.el.contains(row)) return;
    if (e.target.closest("[data-part=tree-check]")) return; // the box acts on `change`
    this.activate(row);
  },

  // A checkbox changed: the rows below follow it, the branches above sum their children up.
  change(e) {
    const input = e.target;
    if (!input.matches || !input.matches("[data-part=tree-check-input]")) return;
    const row = input.closest("[data-part=tree-item]");
    if (!row) return;
    this.mark(input, input.checked, false);
    const group = this.kids(row);
    if (group) {
      group.querySelectorAll("[data-part=tree-check-input]").forEach((box) => this.mark(box, input.checked, false));
    }
    this.sum(row);
    this.emit("onCheck", row, { checked: input.checked });
  },

  // The branches that hold `row`, from the nearest: checked when all their boxes are, mixed when some.
  sum(row) {
    for (let group = row.parentElement; group && group !== this.el; group = group.parentElement) {
      if (group.dataset.part !== "tree-children") continue;
      const parent = group.previousElementSibling;
      const box = parent && this.box(parent);
      if (!box) continue;
      const kids = Array.from(group.querySelectorAll("[data-part=tree-check-input]"));
      const on = kids.filter((k) => k.checked && !k.indeterminate).length;
      const some = kids.some((k) => k.checked || k.indeterminate);
      if (on === kids.length) this.mark(box, true, false);
      else this.mark(box, false, some);
    }
  },

  mark(box, checked, mixed) {
    box.checked = checked;
    box.indeterminate = mixed;
    if (mixed) box.setAttribute("data-ind", "1");
    else box.removeAttribute("data-ind");
    const row = box.closest("[data-part=tree-item]");
    if (row) row.setAttribute("aria-checked", mixed ? "mixed" : checked ? "true" : "false");
  },

  activate(row) {
    const rows = this.rows();
    const i = rows.indexOf(row);
    const key = this.key_of(row, i);
    const branch = this.chevron(row) || this.kids(row);
    if (branch) {
      const open = !this.open.get(key);
      this.open.set(key, open);
      this.show(row, open, this.server_open(row));
      this.emit("onToggle", row, { expanded: open });
    } else {
      rows.forEach((r) => r.setAttribute("aria-selected", r === row ? "true" : "false"));
      this.emit("onSelect", row, {});
    }
  },

  emit(name, row, extra) {
    const handler = this.el.dataset[name];
    if (!handler) return;
    if (handler.startsWith("[")) return this.liveSocket.execJS(this.el, handler);
    const payload = { id: this.key_of(row, this.rows().indexOf(row)), ...extra };
    const target = this.el.dataset.target;
    if (target) this.pushEventTo(target, handler, payload);
    else this.pushEvent(handler, payload);
  },

  visible() {
    return this.rows().filter((r) => {
      for (let p = r.parentElement; p && p !== this.el; p = p.parentElement) {
        if (p.dataset.part === "tree-children" && p.hidden) return false;
      }
      return true;
    });
  },

  key(e) {
    const row = e.target.closest && e.target.closest("[data-part=tree-item]");
    if (!row || e.target.tagName === "INPUT") return;
    const list = this.visible();
    const i = list.indexOf(row);
    const focus = (r) => {
      if (!r) return;
      list.forEach((x) => (x.tabIndex = -1));
      r.tabIndex = 0;
      r.focus();
    };
    const key = this.key_of(row, this.rows().indexOf(row));
    const branch = this.chevron(row) || this.kids(row);
    if (e.key === "ArrowDown") focus(list[i + 1]);
    else if (e.key === "ArrowUp") focus(list[i - 1]);
    else if (e.key === "ArrowRight" && branch && !this.open.get(key)) this.activate(row);
    else if (e.key === "ArrowLeft" && branch && this.open.get(key)) this.activate(row);
    else if (e.key === "Enter" || e.key === " ") this.activate(row);
    else return;
    e.preventDefault();
  },
};
