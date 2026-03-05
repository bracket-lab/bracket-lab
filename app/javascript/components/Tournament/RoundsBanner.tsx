import React from "react"
import { Tournament } from "objects/TournamentTypes"

export const RoundsBanner = ({ tournament }: { tournament: Tournament }) => {
  const dateRangeString = (start: string, end: string) => {
    const startDate = new Date(start)
    const endDate = new Date(end)
    let dateStr = Intl.DateTimeFormat("en", { month: "short", day: "numeric" }).format(startDate)

    if (endDate > startDate) {
      const endStr = Intl.DateTimeFormat("en", { day: "numeric" }).format(endDate)
      dateStr += `-${endStr}`
    }

    return dateStr
  }

  const reverseRounds = Array.from(tournament.rounds).reverse()
  reverseRounds.shift()

  const rounds = Array.from(tournament.rounds).concat(reverseRounds)

  return (
    <table className="rounds-banner">
      <tbody>
        <tr>
          {rounds.map((r, i) => (
            <th className="header" key={i}>
              {r.name}
            </th>
          ))}
        </tr>
        <tr>
          {rounds.map((r, i) => (
            <td className="date-range" key={i}>
              {dateRangeString(r.startDate, r.endDate)}
            </td>
          ))}
        </tr>
      </tbody>
    </table>
  )
}
