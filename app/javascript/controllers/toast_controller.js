import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["message"]

  connect() {
    this.messageTargets.forEach((message) => {
      setTimeout(() => {
        message.classList.add("opacity-0", "translate-x-full")
        setTimeout(() => message.remove(), 300)
      }, 5000)
    })
  }

  dismiss(event) {
    const message = event.currentTarget.closest("[data-toast-target='message']")
    message.classList.add("opacity-0", "translate-x-full")
    setTimeout(() => message.remove(), 300)
  }
}
