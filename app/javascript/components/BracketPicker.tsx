import React, { useState } from "react"
import { Tournament } from "components/Tournament"
import { BasicBracket, COMPLETED_MASK } from "components/BasicBracket"
import { Team, Tournament as ITournament } from "objects/TournamentTypes"

export interface BracketPickerProps {
  tournament: ITournament
  teams: readonly Team[]
  gameDecisions: string
  gameMask: string
  betaUser?: boolean
  highlightEmpty?: boolean
  onPick: (gameDecisions: string, gameMask: string) => void
}

export const BracketPicker = ({
  tournament,
  teams,
  gameDecisions: initialDecisions,
  gameMask: initialMask,
  betaUser,
  highlightEmpty,
  onPick,
}: BracketPickerProps) => {
  const [gameDecisionsMask, setGameDecisionsMask] = useState<[bigint, bigint]>([
    BigInt(initialDecisions || 0),
    BigInt(initialMask || 0),
  ])

  const [gameDecisions, gameMask] = gameDecisionsMask

  const bracketState: BasicBracket = {
    name: "",
    gameDecisions,
    gameMask,
  }

  const handleSlotClick = (slotId: number, choice: number) => {
    const decision = choice - 1
    const position = BigInt(slotId)

    let [decisions, mask] = gameDecisionsMask

    if (decision === 0) {
      decisions &= ~(1n << position)
    } else {
      decisions |= 1n << position
    }

    mask |= 1n << position

    setGameDecisionsMask([decisions, mask])
    onPick(decisions.toString(), mask.toString())
  }

  const handleFillAll = () => {
    const [decisions] = gameDecisionsMask
    setGameDecisionsMask([decisions, COMPLETED_MASK])
    onPick(decisions.toString(), COMPLETED_MASK.toString())
  }

  return (
    <>
      {betaUser ? <div onClick={handleFillAll}>Fill all picks</div> : null}
      <Tournament
        tournament={tournament}
        teams={teams}
        bracket={bracketState}
        onSlotClick={handleSlotClick}
        highlightEmpty={highlightEmpty}
      />
    </>
  )
}
