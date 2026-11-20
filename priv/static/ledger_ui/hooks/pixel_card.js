// LedgerUI.PixelCard: draws the pixel matrix (`span.grid` of 28x20 `<i>`s, three random opacity
// patterns each) the `lu-px` stylesheet lights up on hover/focus. A LiveView patch drops the
// matrix (the server markup has none), so `updated` draws it again.
const COLS = 28;
const ROWS = 20;

function hash(str) {
  let h = 0;
  for (let i = 0; i < str.length; i++) h = (h * 31 + str.charCodeAt(i)) >>> 0;
  return h;
}

export default {
  mounted() {
    this.draw();
  },

  updated() {
    this.draw();
  },

  draw() {
    if (this.el.querySelector(":scope > .grid")) return;
    const grid = document.createElement("span");
    grid.className = "grid";
    grid.setAttribute("aria-hidden", "true");
    let seed = 7 + (hash(this.el.id) % 97) * 13;
    const rnd = () => {
      seed = (seed * 9301 + 49297) % 233280;
      return seed / 233280;
    };
    const pick = () => (rnd() < 0.45 ? 0 : (0.25 + rnd() * 0.75).toFixed(2));
    let html = "";
    for (let i = 0; i < COLS * ROWS; i++) {
      html += `<i style="--o1:${pick()};--o2:${pick()};--o3:${pick()}"></i>`;
    }
    grid.innerHTML = html;
    this.el.insertBefore(grid, this.el.firstChild);
  },
};
