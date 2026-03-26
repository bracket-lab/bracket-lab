import { Controller } from "@hotwired/stimulus"
import { Chart, DoughnutController, ArcElement, Tooltip } from "chart.js"

Chart.register(DoughnutController, ArcElement, Tooltip)

export default class extends Controller {
  static values = {
    distribution: Object,
    sixthPlus: Number,
  }

  declare distributionValue: Record<string, number>
  declare sixthPlusValue: number

  static targets = ["canvas"]
  declare canvasTarget: HTMLCanvasElement

  connect() {
    this.renderChart()
  }

  private renderChart() {
    const labels = ["1st", "2nd", "3rd", "4th", "5th", "6th+"]
    const colors = ["#fbbf24", "#9ca3af", "#cd7c2f", "#60a5fa", "#a78bfa", "#4b5563"]
    const data = [
      this.distributionValue["1"] || 0,
      this.distributionValue["2"] || 0,
      this.distributionValue["3"] || 0,
      this.distributionValue["4"] || 0,
      this.distributionValue["5"] || 0,
      this.sixthPlusValue,
    ]

    new Chart(this.canvasTarget, {
      type: "doughnut",
      data: {
        labels,
        datasets: [{ data, backgroundColor: colors, borderWidth: 0 }],
      },
      options: {
        cutout: "65%",
        responsive: true,
        maintainAspectRatio: true,
        plugins: {
          tooltip: {
            callbacks: {
              label: (ctx) => {
                const total = data.reduce((a, b) => a + b, 0)
                const pct = total > 0 ? ((ctx.parsed / total) * 100).toFixed(1) : "0"
                return `${ctx.label}: ${ctx.parsed} (${pct}%)`
              },
            },
          },
        },
      },
    })
  }
}
