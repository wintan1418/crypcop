import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { score: Number }
  static targets = ["circle", "label"]

  connect() {
    this.animate()
  }

  animate() {
    const circumference = 2 * Math.PI * 40 // radius 40
    const target = (this.scoreValue / 100) * circumference

    if (this.hasCircleTarget) {
      this.circleTarget.style.strokeDasharray = `0 ${circumference}`
      requestAnimationFrame(() => {
        this.circleTarget.style.transition = "stroke-dasharray 1s ease-out"
        this.circleTarget.style.strokeDasharray = `${target} ${circumference}`
      })
    }

    if (this.hasLabelTarget) {
      let current = 0
      const step = Math.ceil(this.scoreValue / 30)
      const interval = setInterval(() => {
        current = Math.min(current + step, this.scoreValue)
        this.labelTarget.textContent = current
        if (current >= this.scoreValue) clearInterval(interval)
      }, 30)
    }
  }
}
