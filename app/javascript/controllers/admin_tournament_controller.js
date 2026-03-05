import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "choice"]

  connect() {
    // Initialize controller
  }

  clear(event) {
    event.preventDefault()

    if (confirm("Are you sure you want to clear this game?")) {
      // Clear all radio buttons in this game group
      this.choiceTargets.forEach((radio) => {
        radio.checked = false
      })

      // Create hidden input for clear action
      const clearInput = document.createElement("input")
      clearInput.type = "hidden"
      clearInput.name = "choice"
      clearInput.value = "clear"

      // Add to form and submit
      this.formTarget.appendChild(clearInput)
      this.formTarget.requestSubmit()
    }
  }
}
