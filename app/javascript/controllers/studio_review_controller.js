import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["frame", "stage", "slider", "label"]
  static values = { width: Number }
  connect() {
    this.fitMode = !this.widthValue
    this.observer = new ResizeObserver(() => { if (this.fitMode) this.applyWidth(this.stageTarget.clientWidth) })
    this.observer.observe(this.stageTarget)
    this.applyWidth(this.widthValue || this.stageTarget.clientWidth)
  }
  disconnect() { this.observer.disconnect() }
  applyWidth(width) {
    const maximum = Math.max(1920, this.stageTarget.clientWidth)
    const pixels = Math.round(Math.max(320, Math.min(maximum, width)))
    this.sliderTarget.max = maximum
    this.frameTarget.style.width = pixels + "px"
    this.sliderTarget.value = pixels
    this.labelTarget.textContent = pixels + " px"
  }
  fit() { this.fitMode = true; this.applyWidth(this.stageTarget.clientWidth) }
  preset(event) { this.fitMode = false; this.applyWidth(Number(event.currentTarget.dataset.width)) }
  resize() { this.fitMode = false; this.applyWidth(Number(this.sliderTarget.value)) }
  page(event) { event.target.form.requestSubmit() }
}
