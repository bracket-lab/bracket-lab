import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "output"]

  connect() {
    this.count()
  }

  count() {
    const lines = this.inputTarget.value.split("\n").filter(line => line.trim() !== "").length
    this.outputTarget.textContent = `${lines} of 64 teams`
  }
}
