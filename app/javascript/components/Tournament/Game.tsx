import React from "react"
import classNames from "classnames"

import TournamentTree from "objects/TournamentTree"
import { Team } from "objects/TournamentTypes"
import { BasicBracket } from "components/BasicBracket"

const GameSlot = ({
  gameSlot,
  team,
  decision,
  highlightEmpty,
  onSlotClick,
}: {
  gameSlot: number
  team: Team | null
  decision: number
  highlightEmpty: boolean
  onSlotClick: (gameSlot: number, decision: number) => void
}) => {
  const handleClick = () => {
    onSlotClick(gameSlot, decision)
  }

  const highlightClass = highlightEmpty && !team ? "empty-pick" : null

  if (team) {
    return (
      <p className={classNames("slot", `slot${decision}`)} onClick={handleClick}>
        <span className="seed">{team.seed}</span> {team.name}
      </p>
    )
  }
  return (
    <p className={classNames("slot", `slot${decision}`, highlightClass)} onClick={handleClick}>
      <span>&nbsp;</span>
    </p>
  )
}

export const Game = ({
  teams,
  bracket,
  index,
  slot,
  regionIndex,
  roundNumber,
  highlightEmpty,
  onSlotClick,
}: {
  teams: readonly Team[]
  bracket: BasicBracket
  index: number
  slot: number
  regionIndex?: number
  roundNumber: number
  highlightEmpty?: boolean
  onSlotClick: (gameSlot: number, decision: number) => void
}) => {
  const bracketTree = new TournamentTree(bracket.gameDecisions, bracket.gameMask)
  const pick = bracketTree.gameNodes[slot]

  const teamByStartingSlot = (startingSlot?: number): Team | null =>
    teams.find((team) => team.startingSlot === startingSlot) ?? null

  const renderTeam = (slot: number) => {
    const startingSlot = slot === 1 ? pick.firstTeamStartingSlot() : pick.secondTeamStartingSlot()
    const team = teamByStartingSlot(startingSlot)

    return (
      <GameSlot
        gameSlot={pick.slot}
        decision={slot}
        team={team}
        highlightEmpty={highlightEmpty ?? false}
        onSlotClick={onSlotClick}
      />
    )
  }

  let classes = ["match", `m${index}`, `round${roundNumber}`]
  if (regionIndex) {
    classes.push(`region${regionIndex}`)
  }

  return (
    <div className={classNames(classes)}>
      {renderTeam(1)}
      {renderTeam(2)}
    </div>
  )
}
