import { Controller } from "@hotwired/stimulus"
import React, { createElement } from "react"
import type { BracketPickerProps } from "components/BracketPicker"

export default class extends Controller {
  static values = {
    tournament: Object,
    teams: Array,
    gameDecisions: String,
    gameMask: String,
    betaUser: Boolean,
    highlightEmpty: Boolean,
  }

  declare tournamentValue: BracketPickerProps["tournament"]
  declare teamsValue: BracketPickerProps["teams"]
  declare gameDecisionsValue: string
  declare gameMaskValue: string
  declare betaUserValue: boolean
  declare highlightEmptyValue: boolean

  private root: { render(vnode: any): void; unmount(): void } | null = null
  private disconnected = false

  async connect() {
    this.disconnected = false

    try {
      const [{ createRoot }, { BracketPicker }] = await Promise.all([
        import("react-dom/client"),
        import("components/BracketPicker"),
      ])

      if (this.disconnected) return

      this.root = createRoot(this.element)
      this.renderPicker(BracketPicker)
    } catch (error) {
      console.error("Failed to load bracket picker:", error)
    }
  }

  disconnect() {
    this.disconnected = true
    this.root?.unmount()
    this.root = null
  }

  highlightEmptyValueChanged() {
    if (!this.root) return
    import("components/BracketPicker").then(({ BracketPicker }) => {
      this.renderPicker(BracketPicker)
    }).catch((error) => {
      console.error("Failed to re-render bracket picker:", error)
    })
  }

  private renderPicker(BracketPicker: React.FC<BracketPickerProps>) {
    this.root?.render(
      createElement(BracketPicker, {
        tournament: this.tournamentValue,
        teams: this.teamsValue,
        gameDecisions: this.gameDecisionsValue,
        gameMask: this.gameMaskValue,
        betaUser: this.betaUserValue,
        highlightEmpty: this.highlightEmptyValue,
        onPick: this.handlePick,
      })
    )
  }

  private handlePick = (gameDecisions: string, gameMask: string) => {
    this.dispatch("pick", {
      detail: { gameDecisions, gameMask },
      bubbles: true,
    })
  }
}
