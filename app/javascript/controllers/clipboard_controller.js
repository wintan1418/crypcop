import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source"]
  static values = { text: String }

  copy() {
    const text = this.hasTextValue ? this.textValue : this.sourceTarget.textContent.trim()
    navigator.clipboard.writeText(text).then(() => {
      const originalText = this.element.querySelector("[data-clipboard-label]")
      if (originalText) {
        const original = originalText.textContent
        originalText.textContent = "Copied!"
        setTimeout(() => { originalText.textContent = original }, 2000)
      }
    })
  }
}
