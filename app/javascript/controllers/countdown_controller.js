import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { since: String }

  connect() {
    this.update()
    this.interval = setInterval(() => this.update(), 10000)
  }

  disconnect() {
    clearInterval(this.interval)
  }

  update() {
    const since = new Date(this.sinceValue)
    const now = new Date()
    const seconds = Math.floor((now - since) / 1000)

    if (seconds < 60) {
      this.element.textContent = `${seconds}s ago`
    } else if (seconds < 3600) {
      this.element.textContent = `${Math.floor(seconds / 60)}m ago`
    } else if (seconds < 86400) {
      this.element.textContent = `${Math.floor(seconds / 3600)}h ago`
    } else {
      this.element.textContent = `${Math.floor(seconds / 86400)}d ago`
    }
  }
}
