import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["days", "hours", "minutes", "seconds"]

  connect() {
    // Get the target date from the data attribute
    this.targetDate = new Date(this.element.dataset.targetDate)
    this.updateCountdown()

    // Update every second
    this.timer = setInterval(() => {
      this.updateCountdown()
    }, 1000)
  }

  disconnect() {
    if (this.timer) {
      clearInterval(this.timer)
    }
  }

  updateCountdown() {
    const now = new Date()
    const diff = this.targetDate - now

    if (diff <= 0) {
      // Handle countdown completion
      clearInterval(this.timer)
      this.element.classList.add("completed")
      return
    }

    // Calculate time components
    const days = Math.floor(diff / (1000 * 60 * 60 * 24))
    const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))
    const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60))
    const seconds = Math.floor((diff % (1000 * 60)) / 1000)

    // Update the countdown spans
    this.daysTarget.style.setProperty("--value", days)
    this.hoursTarget.style.setProperty("--value", hours)
    this.minutesTarget.style.setProperty("--value", minutes)
    this.secondsTarget.style.setProperty("--value", seconds)
  }
}
