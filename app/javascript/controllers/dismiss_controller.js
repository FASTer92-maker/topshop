import { Controller } from "@hotwired/stimulus"

// Removes its element from the page, e.g. a flash message close button.
export default class extends Controller {
  close() {
    this.element.remove()
  }
}
