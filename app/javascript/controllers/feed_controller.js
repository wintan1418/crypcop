import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["counter"]
  static values = { count: Number }

  connect() {
    this.countValue = 0
  }

  tokenAdded() {
    this.countValue++
    if (this.hasCounterTarget) {
      this.counterTarget.textContent = this.countValue
    }
  }
}
