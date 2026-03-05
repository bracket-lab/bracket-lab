import React from "react"
import classNames from "classnames"

import TournamentTree from "objects/TournamentTree"
import { BasicBracket } from "components/BasicBracket"
import { Team } from "objects/TournamentTypes"

export const Championship = ({
  bracket,
  highlightEmpty,
  teams,
}: {
  bracket: BasicBracket
  highlightEmpty: boolean
  teams: readonly Team[]
}) => {
  const bracketTree = new TournamentTree(bracket.gameDecisions, bracket.gameMask)
  const pick = bracketTree.gameNodes[1]

  const teamByStartingSlot = (slot?: number): Team | null =>
    teams.find((team) => team.startingSlot === slot) ?? null

  const championName = () => {
    const startingSlot = pick.winningTeamStartingSlot()
    return startingSlot ? teamByStartingSlot(startingSlot)?.name : null
  }

  const highlightClass = highlightEmpty && !championName() ? "empty-pick" : null

  return (
    <div className="championship">
      <div className={classNames("champion-box", highlightClass)}>{championName()}</div>
      <div className="champion-label">CHAMPION</div>
    </div>
  )
}
