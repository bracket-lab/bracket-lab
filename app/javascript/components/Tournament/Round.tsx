import React from "react"
import { range, chunk } from "lodash-es"
import classNames from "classnames"

import { Region } from "./Region"
import { Game } from "./Game"
import { Team, Tournament } from "objects/TournamentTypes"
import { BasicBracket } from "components/BasicBracket"

export const Round = ({
  teams,
  round,
  bracket,
  onSlotClick,
  highlightEmpty,
}: {
  teams: readonly Team[]
  round: Tournament["rounds"][0]
  bracket: BasicBracket
  onSlotClick: (slotId: number, choice: number) => void
  highlightEmpty?: boolean
}) => {
  const gameSlots = () => {
    const depthFor = range(1, 7).reverse().indexOf(round.number) + 1
    if (depthFor === 0) {
      return [1]
    } else {
      return range(Math.pow(2, depthFor - 1), Math.pow(2, depthFor))
    }
  }

  const gameSlotsByRegion = () => {
    const slots = gameSlots()
    const chunkSize = slots.length / round.regions.length
    return chunk(slots, chunkSize)
  }

  if (round.regions) {
    return (
      <div className={classNames("round", `round${round.number}`)}>
        {round.regions.map((r, i) => (
          <Region
            key={i}
            index={i + 1}
            teams={teams}
            region={r}
            gameSlots={gameSlotsByRegion()[i]}
            bracket={bracket}
            roundNumber={round.number}
            onSlotClick={onSlotClick}
            highlightEmpty={highlightEmpty}
          />
        ))}
      </div>
    )
  } else {
    return (
      <div className={classNames("round", `round${round.number}`)}>
        {gameSlots().map((slot, i) => (
          <Game
            key={i}
            index={i + 1}
            teams={teams}
            slot={slot}
            roundNumber={round.number}
            bracket={bracket}
            onSlotClick={onSlotClick}
            highlightEmpty={highlightEmpty}
          />
        ))}
      </div>
    )
  }
}
