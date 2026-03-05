import { Controller } from "@hotwired/stimulus"
import { COMPLETED_MASK } from "components/BasicBracket"

export default class extends Controller {
  static targets = ["gameDecisions", "gameMask"]

  declare gameDecisionsTarget: HTMLInputElement
  declare gameMaskTarget: HTMLInputElement

  handlePick(event: Event) {
    const { gameDecisions, gameMask } = (event as CustomEvent).detail
    this.gameDecisionsTarget.value = gameDecisions
    this.gameMaskTarget.value = gameMask
  }

  submit(event: Event) {
    const mask = BigInt(this.gameMaskTarget.value || "0")

    if (mask !== COMPLETED_MASK) {
      event.preventDefault()

      // Set highlightEmpty on the picker controller's element
      const picker = this.element.querySelector("[data-controller='bracket-picker']")
      if (picker) {
        picker.setAttribute("data-bracket-picker-highlight-empty-value", "true")
      }

      // Show error via flash-style toast
      this.showError("Bracket is not complete")
    }
  }

  private showError(message: string) {
    document.getElementById("bracket-form-error")?.remove()

    const toast = document.createElement("div")
    toast.id = "bracket-form-error"
    toast.className = "toast"

    const alert = document.createElement("div")
    alert.className = "alert alert-error shadow-lg"

    const span = document.createElement("span")
    span.textContent = message

    alert.appendChild(span)
    toast.appendChild(alert)
    document.body.appendChild(toast)

    setTimeout(() => {
      toast.classList.add("opacity-0", "transition-opacity", "duration-300")
      setTimeout(() => toast.remove(), 300)
    }, 4000)
  }
}
