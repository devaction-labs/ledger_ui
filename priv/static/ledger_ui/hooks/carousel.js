// LedgerUI.Carousel: arrows, pagination, autoplay, keyboard, swipe, effects and zoom for the track
// (`[data-part=carousel-track]`) rendered by `<.carousel>`. The server's slide is `data-index`; the
// person moves freely and their slide survives patches (the server wins only when it changes).
// The hook reads `data-lu-effect` / `data-lu-direction` and writes only `aria-*` (the bullets and thumbnails
// are styled by the server's utilities from `aria-current`) and the inline transforms of the slides.
const REDUCED = () => window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;

const STACKED = {
  fade: (d) => ({ opacity: d === 0 ? 1 : 0 }),
  flip: (d) => ({ transform: `rotateY(${d * 180}deg)`, opacity: d === 0 ? 1 : 0, backfaceVisibility: "hidden" }),
  cube: (d) => ({ transform: `rotateY(${d * 90}deg) translateZ(0)`, opacity: Math.abs(d) > 1 ? 0 : 1 }),
  cards: (d) => ({
    transform: `translate(${d * 8}%, ${Math.abs(d) * 4}%) scale(${1 - Math.abs(d) * 0.06}) rotate(${d * 3}deg)`,
    opacity: Math.abs(d) > 2 ? 0 : 1,
    zIndex: String(10 - Math.abs(d)),
  }),
  coverflow: (d) => ({
    transform: `translateX(${d * 55}%) rotateY(${-d * 40}deg) scale(${d === 0 ? 1 : 0.8})`,
    opacity: Math.abs(d) > 2 ? 0 : 1,
    zIndex: String(10 - Math.abs(d)),
  }),
  creative: (d) => ({ transform: `translateX(${d * 100}%) rotate(${d * 8}deg)`, opacity: Math.abs(d) > 1 ? 0 : 1 }),
};

export default {
  mounted() {
    this.k = this.num("index", 0);
    this.timer = null;
    this.setup();
    this.bind();
    this.go(this.k, false);
    this.autoplay();
    this.handleEvent("ledger:carousel", ({ id, index }) => {
      if (id === this.el.id) this.go(index, true);
    });
  },

  updated() {
    const server = this.num("index", 0);
    if (server !== this.lastServer) this.k = server;
    this.setup();
    this.go(this.k, false);
  },

  destroyed() {
    clearInterval(this.timer);
    this.unbind && this.unbind();
  },

  num(name, fallback) {
    const v = this.el.dataset[name];
    return v === undefined || v === "" ? fallback : parseInt(v, 10);
  },

  effect() {
    return this.el.dataset.luEffect || "slide";
  },

  vertical() {
    return this.el.dataset.luDirection === "vertical";
  },

  track() {
    return this.el.querySelector(':scope > [data-part="carousel-track"]');
  },

  slides() {
    return Array.from(this.track().children);
  },

  // Re-applied after every patch: the server render has none of these inline styles.
  setup() {
    this.lastServer = this.num("index", 0);
    const el = this.el;
    const tr = this.track();
    const gap = this.num("gap", null);
    // role="region", aria-roledescription, tabindex and the bullets' role/label are server-rendered.
    if (this.effect() === "slide") {
      tr.style.display = "flex";
      tr.style.flexDirection = this.vertical() ? "column" : "row";
      if (gap !== null) tr.style.gap = gap + "px";
      this.slides().forEach((s) => {
        s.style.flex = "0 0 100%";
        s.style.width = this.vertical() ? "" : "100%";
        s.style.opacity = "1";
      });
    } else {
      tr.style.display = "grid";
      el.style.perspective = "1200px";
      this.slides().forEach((s) => {
        s.style.gridArea = "1 / 1";
        s.style.width = "100%";
        s.style.transition = "transform .5s ease, opacity .5s ease";
      });
    }
  },

  go(index, notify) {
    const n = this.slides().length;
    if (n === 0) return;
    const loop = this.el.dataset.loop === "true";
    let k = index;
    if (loop) k = ((k % n) + n) % n;
    else k = Math.max(0, Math.min(n - 1, k));
    const changed = k !== this.k;
    this.k = k;
    const tr = this.track();
    if (this.effect() === "slide") {
      const gap = this.num("gap", 0);
      const size = this.vertical() ? tr.offsetHeight : tr.offsetWidth;
      const step = this.vertical() ? "Y" : "X";
      const px = -k * ((this.vertical() ? this.slides()[0].offsetHeight : size) + gap);
      tr.style.transition = REDUCED() ? "none" : "transform .45s cubic-bezier(.3,.7,.3,1)";
      tr.style.transform = `translate${step}(${px}px)`;
    } else {
      const fx = STACKED[this.effect()] || STACKED.fade;
      this.slides().forEach((s, i) => {
        s.style.transform = "";
        s.style.zIndex = "";
        Object.assign(s.style, fx(i - k));
        s.style.pointerEvents = i === k ? "auto" : "none";
      });
    }
    this.slides().forEach((s, i) => s.setAttribute("aria-hidden", i === k ? "false" : "true"));
    this.sync();
    if (notify && changed) this.notify();
  },

  sync() {
    const k = this.k;
    const n = this.slides().length;
    const root = this.el.parentNode;
    const dots = root.querySelector(`#${CSS.escape(this.el.id)}-dots`);
    if (dots) {
      Array.from(dots.children).forEach((d, i) => {
        d.setAttribute("aria-current", i === k ? "true" : "false");
      });
    }
    const thumbs = root.querySelector(`#${CSS.escape(this.el.id)}-thumbs`);
    if (thumbs) {
      Array.from(thumbs.children).forEach((t, i) => {
        t.setAttribute("aria-current", i === k ? "true" : "false");
      });
    }
    const frac = this.el.querySelector("[data-carousel-fraction]");
    if (frac) frac.textContent = `${k + 1}/${n}`;
    const bar = this.el.querySelector("[data-carousel-bar]");
    if (bar) bar.style.width = ((k + 1) / n) * 100 + "%";
  },

  // The index a bullet or thumbnail stands for, or null.
  pickIndex(target) {
    const id = CSS.escape(this.el.id);
    const holder = target.closest(`#${id}-dots > *, #${id}-thumbs > *`);
    if (!holder) return null;
    return Array.prototype.indexOf.call(holder.parentNode.children, holder);
  },

  notify() {
    const handler = this.el.dataset.onChange;
    if (!handler) return;
    if (handler.startsWith("[")) {
      this.liveSocket.execJS(this.el, handler);
    } else {
      const payload = { id: this.el.id, index: this.k };
      const target = this.el.dataset.target;
      if (target) this.pushEventTo(target, handler, payload);
      else this.pushEvent(handler, payload);
    }
  },

  autoplay() {
    clearInterval(this.timer);
    const ms = this.num("autoplay", 0);
    if (!ms || REDUCED()) return;
    this.timer = setInterval(() => {
      if (this.paused || document.hidden) return;
      const last = this.k >= this.slides().length - 1;
      this.go(last && this.el.dataset.loop !== "true" ? 0 : this.k + 1, true);
    }, ms);
  },

  bind() {
    const el = this.el;
    const root = el.parentNode;
    const onClick = (e) => {
      if (e.target.closest("[data-carousel-prev]") && el.contains(e.target)) return this.go(this.k - 1, true);
      if (e.target.closest("[data-carousel-next]") && el.contains(e.target)) return this.go(this.k + 1, true);
      const idx = this.pickIndex(e.target);
      if (idx !== null) this.go(idx, true);
    };
    const onKey = (e) => {
      const inside = el.contains(e.target) || this.pickIndex(e.target) !== null;
      if (!inside) return;
      if (e.key === "ArrowLeft" || (this.vertical() && e.key === "ArrowUp")) this.go(this.k - 1, true);
      else if (e.key === "ArrowRight" || (this.vertical() && e.key === "ArrowDown")) this.go(this.k + 1, true);
      else if ((e.key === "Enter" || e.key === " ") && this.pickIndex(e.target) !== null) {
        e.preventDefault();
        this.go(this.pickIndex(e.target), true);
      } else return;
      if (e.key.startsWith("Arrow")) e.preventDefault();
    };
    let x0 = null;
    const pos = (e) => (this.vertical() ? e.clientY : e.clientX);
    const down = (e) => (x0 = pos(e));
    const up = (e) => {
      if (x0 === null) return;
      const dx = pos(e) - x0;
      x0 = null;
      if (Math.abs(dx) > 40) this.go(this.k + (dx < 0 ? 1 : -1), true);
    };
    const enter = () => (this.paused = true);
    const leave = () => (this.paused = false);
    const dbl = () => {
      const ratio = this.num("zoom", 0);
      const child = this.slides()[this.k] && this.slides()[this.k].firstElementChild;
      if (!ratio || !child) return;
      const on = child.style.transform.startsWith("scale");
      child.style.transition = "transform .3s";
      child.style.transform = on ? "" : `scale(${ratio})`;
    };
    root.addEventListener("click", onClick);
    root.addEventListener("keydown", onKey);
    el.addEventListener("pointerdown", down);
    el.addEventListener("pointerup", up);
    el.addEventListener("pointerleave", () => (x0 = null));
    el.addEventListener("mouseenter", enter);
    el.addEventListener("mouseleave", leave);
    el.addEventListener("dblclick", dbl);
    this.unbind = () => {
      root.removeEventListener("click", onClick);
      root.removeEventListener("keydown", onKey);
      el.removeEventListener("pointerdown", down);
      el.removeEventListener("pointerup", up);
      el.removeEventListener("mouseenter", enter);
      el.removeEventListener("mouseleave", leave);
      el.removeEventListener("dblclick", dbl);
    };
  },
};
