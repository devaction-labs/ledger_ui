// LedgerUI.Treeview: opens/closes branches without a round trip, cascades the checkboxes (a branch
// (un)checks everything under it; a branch with only some children checked shows the dash), pushes
// on_toggle / on_select / on_check, and gives the rows their keyboard and ARIA behaviour. It reads
// `data-part` (tree-item, tree-children, tree-chevron, tree-check), never a class. The server render has none of
// this client state, so `updated` applies it again after every patch (the person's toggles
// survive; the server wins for a branch whose `expanded` it changed).
//
// Cost: the rows, their index and the visible list are cached; a MutationObserver (registered once in
// `mounted`) records what a patch changed, so `updated` only reapplies the client state to the rows it
// touched (a patch that touches no node costs O(1)). Our own writes are dropped with `takeRecords`.
const TREE = "[data-part=tree-item]";
const MAX_RECORDS = 5000; // beyond this a full pass is cheaper than mapping the records

export default {
  mounted() {
    this.open = new Map(); // row key -> open?, what the person left
    this.server = new Map(); // row key -> open? as last rendered by the server
    this.records = [];
    this.invalidate();
    this.onClick = (e) => this.click(e);
    this.onChange = (e) => this.change(e);
    this.onKey = (e) => this.key(e);
    this.el.addEventListener("click", this.onClick);
    this.el.addEventListener("change", this.onChange);
    this.el.addEventListener("keydown", this.onKey);
    this.observer = new MutationObserver((records) => this.collect(records));
    this.observer.observe(this.el, { childList: true, attributes: true, subtree: true });
    this.root = this.rootState();
    this.apply(null);
  },

  updated() {
    this.collect(this.observer.takeRecords());
    const records = this.records;
    this.records = [];
    const root = this.rootState();
    const rootChanged = root.chevrons !== this.root.chevrons;
    this.root = root;
    if (rootChanged || records.length > MAX_RECORDS) return this.apply(null);
    if (!records.length) return this.apply(new Set()); // nothing patched: only the server-listed branches
    this.invalidate();
    const touched = this.touched(records);
    this.apply(touched || null);
  },

  destroyed() {
    this.el.removeEventListener("click", this.onClick);
    this.el.removeEventListener("change", this.onChange);
    this.el.removeEventListener("keydown", this.onKey);
    if (this.observer) this.observer.disconnect();
    this.records = [];
  },

  // Mutations by the patch (ours are discarded right after we make them, see `settle`).
  collect(records) {
    if (this.records.length > MAX_RECORDS) return;
    for (const r of records) {
      if (r.type === "attributes" && r.target === this.el) continue; // the root's own attributes
      this.records.push(r);
    }
  },

  // Forget what we wrote ourselves so it is not mistaken for a patch.
  settle() {
    if (this.observer) this.observer.takeRecords();
  },

  rootState() {
    return { chevrons: this.el.dataset.chevrons };
  },

  invalidate() {
    this._rows = null;
    this._index = null;
    this._visible = null;
  },

  rows() {
    if (!this._rows) {
      this._rows = Array.from(this.el.querySelectorAll(TREE));
      this._index = null;
      this.anon = this._rows.some((r) => !r.id); // rows keyed by position
    }
    return this._rows;
  },

  index_of(row) {
    if (!this._index) {
      const rows = this.rows(); // may reset this._index, so read it before the Map is created
      this._index = new Map();
      rows.forEach((r, i) => this._index.set(r, i));
    }
    const i = this._index.get(row);
    return i === undefined ? -1 : i;
  },

  key_of(row) {
    return row.id || `tree-item-${this.index_of(row)}`;
  },

  // The rows a batch of records touched, or null when a full pass is needed (rows without id are
  // keyed by position, which an insert or a removal shifts).
  touched(records) {
    const set = new Set();
    const add = (node, deep, added) => {
      if (!node || node.nodeType !== 1 || node === this.el) return;
      if (node.matches(TREE)) {
        set.add(node);
        if (added && !node.id) this.anon = true;
      } else if (node.dataset.part === "tree-children") {
        const prev = node.previousElementSibling;
        if (prev && prev.matches(TREE)) set.add(prev);
      }
      const row = node.closest(TREE);
      if (row && this.el.contains(row)) set.add(row);
      if (deep) {
        node.querySelectorAll(TREE).forEach((r) => {
          set.add(r);
          if (!r.id) this.anon = true;
        });
      }
    };
    let structural = false;
    for (const r of records) {
      if (r.type === "childList") {
        if (r.addedNodes.length || r.removedNodes.length) structural = true;
        add(r.target, false);
        r.addedNodes.forEach((n) => add(n, true, true));
      } else add(r.target, false);
    }
    if (structural && this.anon) return null;
    return set;
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

  // Applies the client state to the rows in `only` (a Set) plus the branches the server lists, or to
  // every row when `only` is null.
  apply(only) {
    const first = !this.started;
    this.started = true;
    const listed = this.listed();
    // role, aria-selected/-expanded/-checked and the roving tabindex come from the server; make
    // sure exactly one row is in the tab order (the first when none is).
    if (!this.el.querySelector(`${TREE}[tabindex="0"]`)) {
      const head = this.el.querySelector(TREE);
      if (head) head.tabIndex = 0;
    }
    let todo;
    if (only) {
      todo = new Set(only);
      for (const id of listed) {
        const row = id && document.getElementById(id);
        if (row && this.el.contains(row) && row.matches(TREE)) todo.add(row);
      }
    } else todo = this.rows();
    const hideLead = this.el.dataset.chevrons === "false";
    todo.forEach((row) => {
      if (!row.isConnected) return;
      const input = this.box(row);
      if (input) input.indeterminate = input.hasAttribute("data-ind");
      if (hideLead) {
        const lead = row.firstElementChild;
        if (lead && (lead.dataset.part === "tree-chevron" || lead.dataset.part === "tree-spacer")) {
          lead.style.display = "none";
        }
      }

      const icon = this.chevron(row);
      const kids = this.kids(row);
      if (!icon && !kids) return;
      const key = this.key_of(row);
      const server = this.server_open(row);
      if (first || this.server.get(key) !== server || listed.has(row.id)) {
        if (listed.has(row.id)) this.open.set(key, true);
        else this.open.set(key, server);
      }
      this.server.set(key, server);
      this.show(row, this.open.get(key), server);
    });
    this.settle();
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
    this._visible = null;
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
    this.settle();
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
    const key = this.key_of(row);
    const branch = this.chevron(row) || this.kids(row);
    if (branch) {
      const open = !this.open.get(key);
      this.open.set(key, open);
      this.show(row, open, this.server_open(row));
      this.settle();
      this.emit("onToggle", row, { expanded: open });
    } else {
      // Only the rows that say they are selected need to change (the server renders the rest false).
      this.el.querySelectorAll(`${TREE}[aria-selected="true"]`).forEach((r) => {
        if (r !== row) r.setAttribute("aria-selected", "false");
      });
      row.setAttribute("aria-selected", "true");
      this.settle();
      this.emit("onSelect", row, {});
    }
  },

  emit(name, row, extra) {
    const handler = this.el.dataset[name];
    if (!handler) return;
    if (handler.startsWith("[")) return this.liveSocket.execJS(this.el, handler);
    const payload = { id: this.key_of(row), ...extra };
    const target = this.el.dataset.target;
    if (target) this.pushEventTo(target, handler, payload);
    else this.pushEvent(handler, payload);
  },

  visible() {
    if (!this._visible) {
      this._visible = this.rows().filter((r) => {
        for (let p = r.parentElement; p && p !== this.el; p = p.parentElement) {
          if (p.dataset.part === "tree-children" && p.hidden) return false;
        }
        return true;
      });
    }
    return this._visible;
  },

  key(e) {
    const row = e.target.closest && e.target.closest(TREE);
    if (!row || e.target.tagName === "INPUT") return;
    // A patch that has not reached `updated` yet may have changed the rows.
    this.collect(this.observer.takeRecords());
    if (this.records.length) this.invalidate();
    const list = this.visible();
    const i = list.indexOf(row);
    const focus = (r) => {
      if (!r) return;
      this.el.querySelectorAll(`${TREE}[tabindex="0"]`).forEach((x) => (x.tabIndex = -1));
      r.tabIndex = 0;
      this.settle();
      r.focus();
    };
    const key = this.key_of(row);
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
