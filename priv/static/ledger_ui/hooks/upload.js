// <.upload>: sets `data-over` (the `over` state) of the drop area while files are dragged over it.
// (Dropping itself is LiveView's `phx-drop-target`.)
export default {
  mounted() {
    this.depth = 0
    this.onEnter = (e) => { if (this.hasFiles(e)) { this.depth++; this.paint(true) } }
    this.onLeave = () => { this.depth = Math.max(0, this.depth - 1); if (!this.depth) this.paint(false) }
    this.onDrop = () => { this.depth = 0; this.paint(false) }
    this.el.addEventListener("dragenter", this.onEnter)
    this.el.addEventListener("dragleave", this.onLeave)
    this.el.addEventListener("drop", this.onDrop)
  },
  destroyed() {
    this.el.removeEventListener("dragenter", this.onEnter)
    this.el.removeEventListener("dragleave", this.onLeave)
    this.el.removeEventListener("drop", this.onDrop)
  },
  hasFiles(e) { return e.dataTransfer && [...(e.dataTransfer.types || [])].includes("Files") },
  paint(on) {
    const z = this.el.querySelector("[data-part=upload-drop], [data-part=upload-zone]")
    if (z) on ? z.setAttribute("data-over", "") : z.removeAttribute("data-over")
  },
}
