import TournamentTree from "./TournamentTree"

type NullableSlot = number | null

export default class GameNode {
  tree: TournamentTree
  slot: number
  decision: number | null

  constructor(tree: TournamentTree, slot: number, decision: number | null) {
    this.tree = tree
    this.slot = slot
    this.decision = decision
  }

  firstTeamStartingSlot = (): NullableSlot => {
    if (this.isRoundOne()) {
      return this.leftPosition()
    } else {
      const leftGame = this.leftGame()
      return leftGame ? leftGame.winningTeamStartingSlot() : null
    }
  }

  secondTeamStartingSlot = (): NullableSlot => {
    if (this.isRoundOne()) {
      return this.rightPosition()
    } else {
      const rightGame = this.rightGame()
      return rightGame ? rightGame.winningTeamStartingSlot() : null
    }
  }

  winningTeamStartingSlot = (): NullableSlot => {
    if (this.decision === 0) {
      if (this.leftGame()) {
        return this.leftGame().winningTeamStartingSlot()
      } else {
        return this.leftPosition()
      }
    } else if (this.decision === 1) {
      if (this.rightGame()) {
        return this.rightGame().winningTeamStartingSlot()
      } else {
        return this.rightPosition()
      }
    } else {
      return null
    }
  }

  leftPosition = (): number => {
    return this.slot * 2
  }

  rightPosition = (): number => {
    return this.leftPosition() + 1
  }

  parentPosition = (): number => {
    return (this.slot % 2 === 0 ? this.slot : this.slot - 1) / 2
  }

  leftGame = (): GameNode => {
    return this.tree.gameNodes[this.leftPosition()]
  }

  rightGame = (): GameNode => {
    return this.tree.gameNodes[this.rightPosition()]
  }

  parentGame = (): GameNode => {
    return this.tree.gameNodes[this.parentPosition()]
  }

  isRoundOne = (): boolean => {
    return !this.leftGame() && !this.rightGame()
  }
}
