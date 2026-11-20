// LedgerUI.Treeview: opens/closes branches without a round trip, pushes on_toggle / on_select /
// on_check, and gives the rows their keyboard and ARIA behaviour. The server render has none of
// this client state, so `updated` applies it again after every patch (the person's toggles
// survive; the server wins for a branch whose `expanded` it changed).
export default {
  mounted() {
    this.open = new Map(); // row key -> open?, what the person left
    this.server = new Map(); // row key -> open? as last rendered by the server
    this.onClick = (e) => this.click(e);
    this.onKey = (e) => this.key(e);
    this.el.addEventListener("click", this.onClick);
    this.el.addEventListener("keydown", this.onKey);
    this.apply(true);
  },

  updated() {
    this.apply(false);
  },

  destroyed() {
    this.el.removeEventListener("click", this.onClick);
    this.el.removeEventListener("keydown", this.onKey);
  },

  rows() {
    return Array.from(this.el.querySelectorAll(".lu-tree-i"));
  },

  key_of(row, index) {
    return row.id || `tree-item-${index}`;
  },

  kids(row) {
    const next = row.nextElementSibling;
    return next && next.classList.contains("lu-tree-kids") ? next : null;
  },

  chevron(row) {
    return row.querySelector(":scope > span > svg.tw, :scope > svg.tw");
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
      const input = row.querySelector("input[type=checkbox]");
      if (input) input.indeterminate = input.hasAttribute("data-ind");
      if (this.el.dataset.chevrons === "false") {
        const lead = row.firstElementChild;
        if (lead && lead.tagName === "SPAN" && (lead.querySelector(".tw") || lead.style.width === "16px")) {
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
    if (kids) kids.style.display = open ? "" : "none";
    row.setAttribute("aria-expanded", open ? "true" : "false");
    const icon = this.chevron(row);
    if (icon) {
      icon.style.transition = "transform .15s";
      icon.style.transform = open === serverOpen ? "" : open ? "rotate(90deg)" : "rotate(-90deg)";
    }
  },

  click(e) {
    const row = e.target.closest(".lu-tree-i");
    if (!row || !this.el.contains(row)) return;
    const box = e.target.closest("label.lu-check");
    if (box) {
      const input = box.querySelector("input");
      this.emit("onCheck", row, { checked: !!(input && input.checked) });
      return;
    }
    this.activate(row);
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
      rows.forEach((r) => {
        r.classList.toggle("on", r === row);
        r.setAttribute("aria-selected", r === row ? "true" : "false");
      });
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
        if (p.classList.contains("lu-tree-kids") && p.style.display === "none") return false;
      }
      return true;
    });
  },

  key(e) {
    const row = e.target.closest && e.target.closest(".lu-tree-i");
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
