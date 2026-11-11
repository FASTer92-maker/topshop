import { Controller } from "@hotwired/stimulus"

// Product page picker: switching the colour shows the sizes of that colour,
// the chosen size tells how much is left, and «В корзину» refuses to send the
// form without a size. The real cart arrives in stage 12, so the submit always
// stops here for now.
export default class extends Controller {
  static targets = ["color", "size", "sizeGroup", "stock", "error"]
  static values = { error: String }

  connect() {
    this.showColor(this.selectedColor)
    this.showStock()
  }

  selectColor() {
    this.showColor(this.selectedColor)
    this.uncheckHiddenSizes()
    this.hideError()
    this.showStock()
  }

  selectSize() {
    this.hideError()
    this.showStock()
  }

  submit(event) {
    event.preventDefault()

    if (this.selectedSize) {
      this.hideError()
    } else {
      this.showError()
    }
  }

  get selectedColor() {
    return this.colorTargets.find((input) => input.checked)?.value
  }

  get selectedSize() {
    return this.sizeTargets.find((input) => input.checked && !input.disabled)
  }

  showColor(color) {
    this.sizeGroupTargets.forEach((group) => {
      group.classList.toggle("hidden", group.dataset.sizeColor !== color)
    })
  }

  // A size of another colour must not travel with the form.
  uncheckHiddenSizes() {
    this.sizeTargets.forEach((input) => {
      const group = input.closest("[data-variant-picker-target='sizeGroup']")

      if (group && group.classList.contains("hidden")) {
        input.checked = false
      }
    })
  }

  showStock() {
    this.stockTarget.textContent = this.selectedSize?.dataset.stockLabel || ""
  }

  showError() {
    this.errorTarget.textContent = this.errorValue
    this.errorTarget.classList.remove("hidden")
  }

  hideError() {
    this.errorTarget.textContent = ""
    this.errorTarget.classList.add("hidden")
  }
}
