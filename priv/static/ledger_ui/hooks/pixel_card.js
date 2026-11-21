// LedgerUI.PixelCard: draws the pixel matrix (a `span[data-part=pixel-card-grid]` of 28x20 `<i>`s, three
// random opacity patterns each) that the card lights up on hover/focus. The classes of the nodes drawn
// here come from the server (`data-lu-grid-class`, `data-lu-cell-class`: the stylesheet only has the
// utilities written in Elixir). A LiveView patch drops the matrix (the server markup has none), so
// `updated` draws it again.
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
    if (this.el.querySelector(':scope > [data-part="pixel-card-grid"]')) return;
    const grid = document.createElement("span");
    grid.setAttribute("data-part", "pixel-card-grid");
    grid.className = this.el.dataset.luGridClass || "";
    const cell = (this.el.dataset.luCellClass || "").replace(/"/g, "&quot;");
    grid.setAttribute("aria-hidden", "true");
    let seed = 7 + (hash(this.el.id) % 97) * 13;
    const rnd = () => {
      seed = (seed * 9301 + 49297) % 233280;
      return seed / 233280;
    };
    const pick = () => (rnd() < 0.45 ? 0 : (0.25 + rnd() * 0.75).toFixed(2));
    let html = "";
    for (let i = 0; i < COLS * ROWS; i++) {
      html += `<i class="${cell}" style="--o1:${pick()};--o2:${pick()};--o3:${pick()}"></i>`;
    }
    grid.innerHTML = html;
    this.el.insertBefore(grid, this.el.firstChild);
  },
};
