// Types for printable draws
type player = {
  id: string,
  number: int,
  name: string,
}

type team = {players: array<player>}

type printableMatch = {
  id: string,
  courtNumber: int,
  team1: team,
  team2: team,
}

type round = {
  roundNumber: int,
  matches: array<printableMatch>,
}

@react.component
let make: (~rounds: array<round>, ~onClose: unit => unit) => React.element
