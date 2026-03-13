import { Controller } from "@hotwired/stimulus"
import * as Turbo from "@hotwired/turbo"

// Only activates in iOS standalone PWA mode.
// Android Chrome supports native pull-to-refresh in standalone mode.
const isIOSStandalone = (navigator as any).standalone === true

const DIST_THRESHOLD = 60
const DIST_MAX = 80
const DIST_RELOAD = 50

function resistance(distExtra: number): number {
  return Math.min(1, distExtra / (DIST_THRESHOLD * 2.5)) * Math.min(DIST_MAX, distExtra)
}

type PtrState = "pending" | "pulling" | "releasing" | "refreshing"

export default class extends Controller {
  private state: PtrState = "pending"
  private pullStartY = 0
  private distResisted = 0
  private indicator: HTMLElement | null = null
  private resetTimeout: ReturnType<typeof setTimeout> | null = null

  private handleTouchStart = this.onTouchStart.bind(this)
  private handleTouchMove = this.onTouchMove.bind(this)
  private handleTouchEnd = this.onTouchEnd.bind(this)
  private handleTouchCancel = this.onTouchCancel.bind(this)

  connect() {
    if (!isIOSStandalone) return

    document.documentElement.style.overscrollBehaviorY = "contain"
    document.body.style.overscrollBehaviorY = "contain"

    this.element.addEventListener("touchstart", this.handleTouchStart, { passive: true })
    this.element.addEventListener("touchmove", this.handleTouchMove, { passive: false })
    this.element.addEventListener("touchend", this.handleTouchEnd)
    this.element.addEventListener("touchcancel", this.handleTouchCancel)
  }

  disconnect() {
    if (!isIOSStandalone) return

    document.documentElement.style.overscrollBehaviorY = ""
    document.body.style.overscrollBehaviorY = ""

    this.element.removeEventListener("touchstart", this.handleTouchStart)
    this.element.removeEventListener("touchmove", this.handleTouchMove)
    this.element.removeEventListener("touchend", this.handleTouchEnd)
    this.element.removeEventListener("touchcancel", this.handleTouchCancel)

    if (this.resetTimeout !== null) {
      clearTimeout(this.resetTimeout)
      this.resetTimeout = null
    }

    this.removeIndicator()
  }

  private onTouchStart(e: TouchEvent) {
    if (this.state === "refreshing") return
    if (window.scrollY > 0) return

    this.pullStartY = e.touches[0].screenY
    this.state = "pending"
  }

  private onTouchMove(e: TouchEvent) {
    if (this.state === "refreshing" || this.pullStartY === 0) return

    const pullMoveY = e.touches[0].screenY
    const dist = pullMoveY - this.pullStartY

    if (dist <= 0) return

    if (window.scrollY > 0) {
      this.pullStartY = 0
      return
    }

    e.preventDefault()

    this.distResisted = resistance(dist)
    this.ensureIndicator()
    this.indicator!.style.minHeight = `${this.distResisted}px`

    if (this.distResisted >= DIST_THRESHOLD) {
      this.state = "releasing"
      this.updateIndicatorText("Release to refresh")
      this.indicator!.querySelector(".ptr-icon")?.classList.add("ptr-flip")
    } else {
      this.state = "pulling"
      this.updateIndicatorText("Pull to refresh")
      this.indicator!.querySelector(".ptr-icon")?.classList.remove("ptr-flip")
    }
  }

  private onTouchEnd() {
    if (this.state === "releasing" && this.distResisted >= DIST_THRESHOLD) {
      this.state = "refreshing"
      this.updateIndicatorText("Refreshing...")

      if (this.indicator) {
        this.indicator.style.minHeight = `${DIST_RELOAD}px`
      }

      Turbo.visit(location.href, { action: "replace" })
    } else {
      this.resetPull()
    }
  }

  private onTouchCancel() {
    this.resetPull()
  }

  private ensureIndicator() {
    if (this.indicator) return

    this.indicator = document.createElement("div")
    this.indicator.className = "ptr-container"
    this.indicator.innerHTML = `
      <div class="ptr-box">
        <div class="ptr-icon">&#8675;</div>
        <div class="ptr-text">Pull to refresh</div>
      </div>
    `
    document.body.insertBefore(this.indicator, document.body.firstChild)
  }

  private updateIndicatorText(text: string) {
    const el = this.indicator?.querySelector(".ptr-text")
    if (el) el.textContent = text
  }

  private removeIndicator() {
    if (this.indicator && this.indicator.parentNode) {
      this.indicator.parentNode.removeChild(this.indicator)
      this.indicator = null
    }
  }

  private resetPull() {
    if (this.resetTimeout !== null) {
      clearTimeout(this.resetTimeout)
      this.resetTimeout = null
    }
    if (this.indicator) {
      this.indicator.style.minHeight = "0px"
      this.resetTimeout = setTimeout(() => {
        this.removeIndicator()
        this.resetTimeout = null
      }, 300)
    }
    this.state = "pending"
    this.pullStartY = 0
    this.distResisted = 0
  }
}
