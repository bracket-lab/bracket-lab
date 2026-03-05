import React from "react"
import { Round } from "./Round"
import { Championship } from "./Championship"
import { RoundsBanner } from "./RoundsBanner"
import { Team, Tournament as ITournament } from "objects/TournamentTypes"
import { BasicBracket } from "components/BasicBracket"

export const Tournament = ({
  bracket,
  onSlotClick,
  highlightEmpty,
  tournament,
  teams,
}: {
  bracket: BasicBracket
  onSlotClick: (slotId: number, choice: number) => void
  highlightEmpty?: boolean
  tournament: ITournament
  teams: readonly Team[]
}) => {
  const { rounds } = tournament

  return (
    <div className="tournament-component">
      <div className="tournament-heading">
        <RoundsBanner tournament={tournament} />
      </div>
      <div className="tournament-body">
        {rounds.map((r) => (
          <Round
            key={r.number}
            teams={teams}
            round={r}
            bracket={bracket}
            onSlotClick={onSlotClick}
            highlightEmpty={highlightEmpty}
          />
        ))}
        <Championship bracket={bracket} highlightEmpty={highlightEmpty ?? false} teams={teams} />
      </div>
    </div>
  )
}
