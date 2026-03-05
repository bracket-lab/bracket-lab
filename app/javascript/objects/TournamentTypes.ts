type Tournament64 = {
  readonly id: string
  readonly policy: {
    readonly update: boolean
  }
  readonly rounds: ReadonlyArray<{
    readonly name: string
    readonly number: number
    readonly startDate: any
    readonly endDate: any
    readonly regions: ReadonlyArray<string> | null
  }>
  readonly tipOff: any
  readonly gameDecisions: string
  readonly gameMask: string
  readonly started: boolean
}

export type Team = {
  readonly id: string
  readonly startingSlot: number
  readonly seed: number
  readonly name: string
  readonly stillPlaying: boolean
}

export type Bracket = {
  id: string
  name: string
  gameDecisions: string
  policy: {
    destroy: boolean
  }
}

export interface Tournament {
  id: Tournament64["id"]
  policy: Tournament64["policy"]
  rounds: Tournament64["rounds"]
  tipOff: Tournament64["tipOff"]
  gameDecisions: bigint
  gameMask: bigint
  started: boolean
}
