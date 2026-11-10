import { Controller } from "@hotwired/stimulus"

// Submits the surrounding GET form whenever a filter changes, so the catalog
// Turbo Frame updates without pressing «Применить».
export default class extends Controller {
  static values = { delay: { type: Number, default: 300 } }

  submit() {
    this.element.requestSubmit()
  }

  // Debounced variant for text and number inputs: waits until typing stops.
  debounce() {
    clearTimeout(this.timeout)

    this.timeout = setTimeout(() => this.submit(), this.delayValue)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
