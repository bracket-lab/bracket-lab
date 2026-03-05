import GameNode from "./GameNode"

const NUM_GAMES = 63

export default class TournamentTree {
  gameNodes: GameNode[]

  constructor(decisions: bigint, mask: bigint) {
    this.gameNodes = Array(NUM_GAMES + 1)
      .fill(null)
      .map((_, num) => {
        if (num === 0) return null
        const i = BigInt(num)

        const maskBit = 1n << i
        if ((BigInt(mask) & BigInt(maskBit)) !== 0n) {
          const decision = ((BigInt(decisions) >> BigInt(i)) & 1n) === 0n ? 0 : 1
          return new GameNode(this, num, decision)
        } else {
          return new GameNode(this, num, null)
        }
      })
  }
}
