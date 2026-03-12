import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["show", "edit"]

  edit() {
    this.showTarget.classList.add("hidden")
    this.editTarget.classList.remove("hidden")
    this.editTarget.querySelector("input[type=text]")?.focus()
  }

  cancel() {
    this.editTarget.classList.add("hidden")
    this.showTarget.classList.remove("hidden")
  }
}
