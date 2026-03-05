import React from "react"
import classNames from "classnames"

import { Game } from "./Game"
import { BasicBracket } from "components/BasicBracket"
import { Team } from "objects/TournamentTypes"

export const Region = ({
  teams,
  gameSlots,
  index,
  region,
  roundNumber,
  bracket,
  onSlotClick,
  highlightEmpty,
}: {
  teams: readonly Team[]
  gameSlots: number[]
  index: number
  region: string
  roundNumber: number
  bracket: BasicBracket
  onSlotClick: (gameSlot: number, decision: number) => void
  highlightEmpty?: boolean
}) => {
  return (
    <div className="region-component">
      {roundNumber === 1 ? (
        <div className={classNames("region-label", `region${index}`)}>{region}</div>
      ) : null}
      {gameSlots.map((slot, i) => (
        <Game
          teams={teams}
          key={i}
          index={i + 1}
          slot={slot}
          regionIndex={index}
          roundNumber={roundNumber}
          bracket={bracket}
          onSlotClick={onSlotClick}
          highlightEmpty={highlightEmpty}
        />
      ))}
    </div>
  )
}
