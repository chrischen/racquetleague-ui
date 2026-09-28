// Storybook support for PlayerSettingsModal.stories.tsx; the app never imports this.
// The per-player dialog behind the gear on a check-in tile: rename a player and
// set their gender for mixed draws. Walk-ins (no account) can also be deleted.
// The registered player comes from the shared match roster, read through
// EventManager's fragment, so it carries a real RSVP node as in the app.
open StoryFixturesMatch

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = StoryFixturesMatchQuery_graphql.node->Obj.magic

@genType @react.component
let make = (
  ~state: [#registered | #guest | #longName]=#registered,
  ~onSave: option<(string, string) => unit>=?,
  ~onClose=() => (),
  ~onDelete: option<unit => unit>=?,
) => {
  let players = useManagerPlayers()
  let (player, onDelete) = switch state {
  | #registered => (players->at(yuki), None)
  | #longName => (players->at(maximilian), None)
  // EventManager passes onDelete only for guests.
  | #guest => (
      StoryFixturesSession.guests()->Array.getUnsafe(0),
      Some(() => onDelete->Option.forEach(f => f())),
    )
  }
  <PlayerSettingsModal
    // Remount when the preset changes, since the modal copies the player into state.
    key={player.id}
    player
    onSave={(p: Rating.Player.t<_>) =>
      onSave->Option.forEach(f =>
        f(
          p.name,
          switch p.gender {
          | Male => "male"
          | Female => "female"
          },
        )
      )}
    onClose
    ?onDelete
  />
}
