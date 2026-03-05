import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["userCheckbox", "eliminatedCheckbox", "listRow"]

  connect() {
    // Initialize the filter state based on the checkboxes
    if (this.userCheckboxTarget.checked || this.elimChecked()) {
      this.filterBrackets()
    }
  }

  toggle() {
    this.filterBrackets()
  }

  elimChecked() {
    return this.hasEliminatedCheckboxTarget && this.eliminatedCheckboxTarget.checked
  }

  filterBrackets() {
    const showOnlyUserBrackets = this.userCheckboxTarget.checked
    const hideEliminatedBrackets = this.elimChecked()

    const currentUserId = this.element.dataset.currentUserId

    this.listRowTargets.forEach((row) => {
      const bracketUserId = row.dataset.userId
      const isEliminated = row.dataset.eliminated === "true"

      if (
        (showOnlyUserBrackets && bracketUserId !== currentUserId) ||
        (hideEliminatedBrackets && isEliminated)
      ) {
        row.classList.add("hidden")
      } else {
        row.classList.remove("hidden")
      }
    })
  }
}
