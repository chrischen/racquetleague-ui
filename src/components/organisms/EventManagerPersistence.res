// EventManager Local Persistence Module
// Handles TinyBase synchronization for EventManager matches
// Stores match data with full player objects (ratings change per round)

open Rating

// Initialize TinyBase store at module level for event state
let eventStore = TinyBase.createStore()

// Create IndexedDB persister for the event store
let eventPersister = TinyBase.createIndexedDbPersister(eventStore, "pkuru-fairplay")

// Initialize persistence on module load
let _ =
  eventPersister
  ->TinyBase.startAutoLoad(Js.Json.null)
  ->Promise.then(_ => {
    eventPersister->TinyBase.startAutoSave
  })

// Load the current round index for an event from TinyBase
let loadCurrentRound = (eventId: string): int => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  eventsTable
  ->Js.Dict.get(eventId)
  ->Option.flatMap(row => row->Js.Dict.get("currentRound"))
  ->Option.flatMap(v => v->Js.Json.decodeNumber)
  ->Option.map(Float.toInt)
  ->Option.getOr(0)
}

// Save the current round index for an event to TinyBase
let saveCurrentRound = (eventId: string, currentRound: int) => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  let existingRow = eventsTable->Js.Dict.get(eventId)->Option.getOr(Js.Dict.empty())
  existingRow->Js.Dict.set("currentRound", currentRound->Int.toFloat->Js.Json.number)
  eventStore->TinyBase.setRow("eventState", eventId, existingRow)
}

// Clear all event-related data from TinyBase
let clearEventData = (eventId: string) => {
  // Clear eventState
  eventStore->TinyBase.delRow("eventState", eventId)

  // Clear all matches for this event
  let matchesTable = eventStore->TinyBase.getTable("matches")
  let matchIdsToDelete =
    matchesTable
    ->Js.Dict.entries
    ->Array.filterMap(((matchId, matchRow)) => {
      switch matchRow->Js.Dict.get("eventId")->Option.map(v => v->Obj.magic) {
      | Some(mEventId: string) if mEventId == eventId => Some(matchId)
      | _ => None
      }
    })

  matchIdsToDelete->Array.forEach(matchId => {
    eventStore->TinyBase.delRow("matches", matchId)
  })
}

// Load the court count for an event from TinyBase
let loadCourtCount = (eventId: string): int => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  eventsTable
  ->Js.Dict.get(eventId)
  ->Option.flatMap(row => row->Js.Dict.get("courtCount"))
  ->Option.flatMap(v => v->Js.Json.decodeNumber)
  ->Option.map(Float.toInt)
  ->Option.getOr(3) // Default to 3 courts
}

// Save the court count for an event to TinyBase
let saveCourtCount = (eventId: string, courtCount: int) => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  let existingRow = eventsTable->Js.Dict.get(eventId)->Option.getOr(Js.Dict.empty())
  existingRow->Js.Dict.set("courtCount", courtCount->Int.toFloat->Js.Json.number)
  eventStore->TinyBase.setRow("eventState", eventId, existingRow)
}

// Load checked-in player IDs for an event from TinyBase
let loadCheckedInPlayerIds = (eventId: string): array<string> => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  eventsTable
  ->Js.Dict.get(eventId)
  ->Option.flatMap(row => row->Js.Dict.get("checkedInPlayerIds"))
  ->Option.flatMap(v => v->Js.Json.decodeString)
  ->Option.flatMap(str =>
    try {
      str->Js.Json.parseExn->Js.Json.decodeArray
    } catch {
    | Js.Exn.Error(e) => {
        Js.log3(
          "[EventManagerPersistence] Failed to parse checkedInPlayerIds JSON for event:",
          eventId,
          e,
        )
        None
      }
    | _ => {
        Js.log2(
          "[EventManagerPersistence] Unknown error parsing checkedInPlayerIds JSON for event:",
          eventId,
        )
        None
      }
    }
  )
  ->Option.map(arr => arr->Array.filterMap(item => item->Js.Json.decodeString))
  ->Option.getOr([])
}

// Save checked-in player IDs for an event to TinyBase
let saveCheckedInPlayerIds = (eventId: string, playerIds: array<string>) => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  let existingRow = eventsTable->Js.Dict.get(eventId)->Option.getOr(Js.Dict.empty())
  let playerIdsJson = playerIds->Js.Json.stringifyAny->Option.getOr("[]")
  existingRow->Js.Dict.set("checkedInPlayerIds", playerIdsJson->Js.Json.string)
  eventStore->TinyBase.setRow("eventState", eventId, existingRow)
}

// Helper function to hydrate a player with GraphQL RSVP data
let hydratePlayerWithRsvpData = (
  player: Player.t<Js.Json.t>,
  rsvpMap: Js.Dict.t<'rsvpNode>,
): Player.t<'rsvpNode> => {
  switch rsvpMap->Js.Dict.get(player.id) {
  | Some(rsvp) => {...player, data: Some(rsvp)}
  | None => {...player, data: None} // Guest players or players without RSVP data
  }
}

// Load raw match data from TinyBase for a specific event
// Returns array of tuples: (matchId, team1Players, team2Players, roundIndex, score)
// Players are hydrated with RSVP data from the provided rsvpMap
let loadMatchesFromDb = (eventId: string, rsvpMap: Js.Dict.t<'rsvpNode>): array<(
  string,
  array<player<'rsvpNode>>,
  array<player<'rsvpNode>>,
  int,
  option<(float, float)>,
  Js.Date.t,
)> => {
  let matchesTable = eventStore->TinyBase.getTable("matches")

  // Load all matches for this event
  let results =
    matchesTable
    ->Js.Dict.entries
    ->Array.filterMap(((matchId, matchRow)) => {
      // Check if this match belongs to the current event
      switch matchRow->Js.Dict.get("eventId")->Option.map(v => v->Obj.magic) {
      | Some(mEventId: string) if mEventId == eventId => {
          // Extract match data - players are stored as JSON array string
          let team1Players =
            matchRow
            ->Js.Dict.get("team1Players")
            ->Option.flatMap(v => v->Js.Json.decodeString)
            ->Option.flatMap(str =>
              try {
                str->Js.Json.parseExn->Js.Json.decodeArray
              } catch {
              | Js.Exn.Error(e) => {
                  Js.log3(
                    "[EventManagerPersistence] Failed to parse team1Players JSON for match:",
                    matchId,
                    e,
                  )
                  None
                }
              | _ => {
                  Js.log2(
                    "[EventManagerPersistence] Unknown error parsing team1Players JSON for match:",
                    matchId,
                  )
                  None
                }
              }
            )
            ->Option.map(arr =>
              arr->Array.filterMap(
                playerJson => {
                  switch playerJson->Json.Decode.decode(Player.decodePlayer()) {
                  | Ok(player) => Some(hydratePlayerWithRsvpData(player, rsvpMap))
                  | Error(msg) => {
                      Js.log3(
                        "[EventManagerPersistence] Failed to decode team1 player for match:",
                        matchId,
                        msg,
                      )
                      None
                    }
                  }
                },
              )
            )
            ->Option.getOr([])

          let team2Players =
            matchRow
            ->Js.Dict.get("team2Players")
            ->Option.flatMap(v => v->Js.Json.decodeString)
            ->Option.flatMap(str =>
              try {
                str->Js.Json.parseExn->Js.Json.decodeArray
              } catch {
              | Js.Exn.Error(e) => {
                  Js.log3(
                    "[EventManagerPersistence] Failed to parse team2Players JSON for match:",
                    matchId,
                    e,
                  )
                  None
                }
              | _ => {
                  Js.log2(
                    "[EventManagerPersistence] Unknown error parsing team2Players JSON for match:",
                    matchId,
                  )
                  None
                }
              }
            )
            ->Option.map(arr =>
              arr->Array.filterMap(
                playerJson => {
                  switch playerJson->Json.Decode.decode(Player.decodePlayer()) {
                  | Ok(player) => Some(hydratePlayerWithRsvpData(player, rsvpMap))
                  | Error(msg) => {
                      Js.log3(
                        "[EventManagerPersistence] Failed to decode team2 player for match:",
                        matchId,
                        msg,
                      )
                      None
                    }
                  }
                },
              )
            )
            ->Option.getOr([])

          let roundIndex =
            matchRow
            ->Js.Dict.get("roundIndex")
            ->Option.flatMap(v => v->Js.Json.decodeNumber)
            ->Option.map(Float.toInt)
            ->Option.getOr(0)

          // Extract score if present
          let score = switch matchRow
          ->Js.Dict.get("hasScore")
          ->Option.flatMap(v => v->Js.Json.decodeBoolean) {
          | Some(true) => {
              let team1Score =
                matchRow
                ->Js.Dict.get("team1Score")
                ->Option.flatMap(v => v->Js.Json.decodeNumber)
              let team2Score =
                matchRow
                ->Js.Dict.get("team2Score")
                ->Option.flatMap(v => v->Js.Json.decodeNumber)

              switch (team1Score, team2Score) {
              | (Some(s1), Some(s2)) => Some((s1, s2))
              | _ => None
              }
            }
          | _ => None
          }

          // Extract createdAt timestamp
          Js.log("CreatedAt raw value:")
          let createdAt =
            matchRow
            ->Js.Dict.get("createdAt")
            ->Option.flatMap(v => v->Js.Json.decodeNumber)
            ->Option.map(ts => Js.Date.fromFloat(ts))
            ->Option.getOr(Js.Date.make())
          Js.log(createdAt)

          Some((matchId, team1Players, team2Players, roundIndex, score, createdAt))
        }
      | _ => None
      }
    })
  results
}

// Load player seed adjustments for an event from TinyBase
// Load rating adjustment history for an event
let loadRatingAdjustmentHistory = (eventId: string): array<RatingAdjustment.t> => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  eventsTable
  ->Js.Dict.get(eventId)
  ->Option.flatMap(row => row->Js.Dict.get("ratingAdjustmentHistory"))
  ->Option.flatMap(v => v->Js.Json.decodeString)
  ->Option.flatMap(str =>
    try {
      str->Js.Json.parseExn->Js.Json.decodeArray
    } catch {
    | Js.Exn.Error(e) => {
        Js.log3(
          "[EventManagerPersistence] Failed to parse ratingAdjustmentHistory JSON for event:",
          eventId,
          e,
        )
        None
      }
    | _ => {
        Js.log2(
          "[EventManagerPersistence] Unknown error parsing ratingAdjustmentHistory JSON for event:",
          eventId,
        )
        None
      }
    }
  )
  ->Option.map(arr => arr->Array.filterMap(RatingAdjustment.fromJson))
  ->Option.getOr([])
}

// Legacy: Load old playerSeedAdjustments dict and convert to history format
let loadPlayerSeedAdjustments = (eventId: string): Js.Dict.t<float> => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  eventsTable
  ->Js.Dict.get(eventId)
  ->Option.flatMap(row => row->Js.Dict.get("playerSeedAdjustments"))
  ->Option.flatMap(v => v->Js.Json.decodeString)
  ->Option.flatMap(str =>
    try {
      str->Js.Json.parseExn->Js.Json.decodeObject
    } catch {
    | Js.Exn.Error(e) => {
        Js.log3(
          "[EventManagerPersistence] Failed to parse playerSeedAdjustments JSON for event:",
          eventId,
          e,
        )
        None
      }
    | _ => {
        Js.log2(
          "[EventManagerPersistence] Unknown error parsing playerSeedAdjustments JSON for event:",
          eventId,
        )
        None
      }
    }
  )
  ->Option.map(dict => {
    // Convert JSON values to floats
    let result = Js.Dict.empty()
    dict
    ->Js.Dict.entries
    ->Array.forEach(((playerId, jsonValue)) => {
      switch jsonValue->Js.Json.decodeNumber {
      | Some(adjustment) => result->Js.Dict.set(playerId, adjustment)
      | None => ()
      }
    })
    result
  })
  ->Option.getOr(Js.Dict.empty())
}

// Save player seed adjustments for an event to TinyBase
// Takes a dictionary mapping player IDs to mu adjustments
let savePlayerSeedAdjustments = (eventId: string, adjustments: Js.Dict.t<float>) => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  let existingRow = eventsTable->Js.Dict.get(eventId)->Option.getOr(Js.Dict.empty())

  // Convert float dict to JSON object
  let adjustmentsJson = Js.Dict.empty()
  adjustments
  ->Js.Dict.entries
  ->Array.forEach(((playerId, adjustment)) => {
    adjustmentsJson->Js.Dict.set(playerId, adjustment->Js.Json.number)
  })

  let adjustmentsStr = adjustmentsJson->Js.Json.object_->Js.Json.stringifyAny->Option.getOr("{}")
  existingRow->Js.Dict.set("playerSeedAdjustments", adjustmentsStr->Js.Json.string)
  eventStore->TinyBase.setRow("eventState", eventId, existingRow)
}

// Save rating adjustment history for an event to TinyBase
let saveRatingAdjustmentHistory = (eventId: string, history: array<RatingAdjustment.t>) => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  let existingRow = eventsTable->Js.Dict.get(eventId)->Option.getOr(Js.Dict.empty())

  let historyJson = history->Array.map(RatingAdjustment.toJson)->Js.Json.array
  let historyStr = historyJson->Js.Json.stringifyAny->Option.getOr("[]")
  existingRow->Js.Dict.set("ratingAdjustmentHistory", historyStr->Js.Json.string)
  eventStore->TinyBase.setRow("eventState", eventId, existingRow)
}

// Load teams for an event from TinyBase
let loadTeams = (eventId: string): array<array<Player.t<'a>>> => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  eventsTable
  ->Js.Dict.get(eventId)
  ->Option.flatMap(row => row->Js.Dict.get("teams"))
  ->Option.flatMap(v => v->Js.Json.decodeString)
  ->Option.flatMap(str =>
    try {
      str
      ->Js.Json.parseExn
      ->Js.Json.decodeArray
      ->Option.map(teamsJson =>
        teamsJson->Array.filterMap(
          teamJson =>
            teamJson
            ->Js.Json.decodeArray
            ->Option.map(playerJsons => playerJsons->Array.filterMap(Player.fromJson)),
        )
      )
    } catch {
    | _ => None
    }
  )
  ->Option.getOr([])
}

// Save teams for an event to TinyBase
let saveTeams = (eventId: string, teams: array<array<Player.t<'a>>>) => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  let existingRow = eventsTable->Js.Dict.get(eventId)->Option.getOr(Js.Dict.empty())

  let teamsJson = teams->Array.map(team => team->Array.map(Player.toJson)->Js.Json.array)
  let teamsStr = teamsJson->Js.Json.array->Js.Json.stringifyAny->Option.getOr("[]")
  existingRow->Js.Dict.set("teams", teamsStr->Js.Json.string)
  eventStore->TinyBase.setRow("eventState", eventId, existingRow)
}

// Load anti-teams for an event from TinyBase
let loadAntiTeams = (eventId: string): array<array<Player.t<'a>>> => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  eventsTable
  ->Js.Dict.get(eventId)
  ->Option.flatMap(row => row->Js.Dict.get("antiTeams"))
  ->Option.flatMap(v => v->Js.Json.decodeString)
  ->Option.flatMap(str =>
    try {
      str
      ->Js.Json.parseExn
      ->Js.Json.decodeArray
      ->Option.map(teamsJson =>
        teamsJson->Array.filterMap(
          teamJson =>
            teamJson
            ->Js.Json.decodeArray
            ->Option.map(playerJsons => playerJsons->Array.filterMap(Player.fromJson)),
        )
      )
    } catch {
    | _ => None
    }
  )
  ->Option.getOr([])
}

// Save anti-teams for an event to TinyBase
let saveAntiTeams = (eventId: string, antiTeams: array<array<Player.t<'a>>>) => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  let existingRow = eventsTable->Js.Dict.get(eventId)->Option.getOr(Js.Dict.empty())

  let antiTeamsJson = antiTeams->Array.map(team => team->Array.map(Player.toJson)->Js.Json.array)
  let antiTeamsStr = antiTeamsJson->Js.Json.array->Js.Json.stringifyAny->Option.getOr("[]")
  existingRow->Js.Dict.set("antiTeams", antiTeamsStr->Js.Json.string)
  eventStore->TinyBase.setRow("eventState", eventId, existingRow)
}

// Type for player data overrides (subset of player data that can be edited)
type playerOverride = {
  playerId: string,
  name: option<string>,
  gender: option<Gender.t>,
  paid: option<bool>,
}

// Load player data overrides for an event from TinyBase
// Returns a dictionary mapping player IDs to their overrides
let loadPlayerOverrides = (eventId: string): Js.Dict.t<playerOverride> => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  eventsTable
  ->Js.Dict.get(eventId)
  ->Option.flatMap(row => row->Js.Dict.get("playerOverrides"))
  ->Option.flatMap(v => v->Js.Json.decodeString)
  ->Option.flatMap(str =>
    try {
      str->Js.Json.parseExn->Js.Json.decodeObject
    } catch {
    | Js.Exn.Error(e) => {
        Js.log3(
          "[EventManagerPersistence] Failed to parse playerOverrides JSON for event:",
          eventId,
          e,
        )
        None
      }
    | _ => {
        Js.log2(
          "[EventManagerPersistence] Unknown error parsing playerOverrides JSON for event:",
          eventId,
        )
        None
      }
    }
  )
  ->Option.map(dict => {
    let result = Js.Dict.empty()
    dict
    ->Js.Dict.entries
    ->Array.forEach(((playerId, overrideJson)) => {
      switch overrideJson->Js.Json.decodeObject {
      | Some(overrideObj) => {
          let override: playerOverride = {
            playerId,
            name: overrideObj->Js.Dict.get("name")->Option.flatMap(v => v->Js.Json.decodeString),
            gender: overrideObj
            ->Js.Dict.get("gender")
            ->Option.flatMap(v => v->Js.Json.decodeNumber)
            ->Option.map(n => Gender.fromInt(n->Float.toInt)),
            paid: overrideObj->Js.Dict.get("paid")->Option.flatMap(v => v->Js.Json.decodeBoolean),
          }
          result->Js.Dict.set(playerId, override)
        }
      | None => ()
      }
    })
    result
  })
  ->Option.getOr(Js.Dict.empty())
}

// Save a single player override for an event to TinyBase
let savePlayerOverride = (
  eventId: string,
  playerId: string,
  name: string,
  gender: Gender.t,
  paid: bool,
) => {
  // Load existing overrides
  let existingOverrides = loadPlayerOverrides(eventId)

  // Create new override
  let newOverride: playerOverride = {
    playerId,
    name: Some(name),
    gender: Some(gender),
    paid: Some(paid),
  }

  // Update overrides dict
  let overrideObj = Js.Dict.empty()
  newOverride.name->Option.forEach(n => overrideObj->Js.Dict.set("name", n->Js.Json.string))
  newOverride.gender->Option.forEach(g =>
    overrideObj->Js.Dict.set("gender", g->Gender.toInt->Int.toFloat->Js.Json.number)
  )
  newOverride.paid->Option.forEach(p => overrideObj->Js.Dict.set("paid", p->Js.Json.boolean))

  existingOverrides->Js.Dict.set(playerId, newOverride)

  // Convert to JSON and save
  let overridesJson = Js.Dict.empty()
  existingOverrides
  ->Js.Dict.entries
  ->Array.forEach(((pId, override)) => {
    let obj = Js.Dict.empty()
    override.name->Option.forEach(n => obj->Js.Dict.set("name", n->Js.Json.string))
    override.gender->Option.forEach(g =>
      obj->Js.Dict.set("gender", g->Gender.toInt->Int.toFloat->Js.Json.number)
    )
    override.paid->Option.forEach(p => obj->Js.Dict.set("paid", p->Js.Json.boolean))
    overridesJson->Js.Dict.set(pId, obj->Js.Json.object_)
  })

  let overridesStr = overridesJson->Js.Json.object_->Js.Json.stringifyAny->Option.getOr("{}")

  let eventsTable = eventStore->TinyBase.getTable("eventState")
  let existingRow = eventsTable->Js.Dict.get(eventId)->Option.getOr(Js.Dict.empty())
  existingRow->Js.Dict.set("playerOverrides", overridesStr->Js.Json.string)
  eventStore->TinyBase.setRow("eventState", eventId, existingRow)
}

// Load guest players for an event from TinyBase
let loadGuestPlayers = (eventId: string): array<Player.t<'a>> => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  eventsTable
  ->Js.Dict.get(eventId)
  ->Option.flatMap(row => row->Js.Dict.get("guestPlayers"))
  ->Option.flatMap(v => v->Js.Json.decodeString)
  ->Option.flatMap(str =>
    try {
      str->Js.Json.parseExn->Js.Json.decodeArray
    } catch {
    | Js.Exn.Error(e) => {
        Js.log3(
          "[EventManagerPersistence] Failed to parse guestPlayers JSON for event:",
          eventId,
          e,
        )
        None
      }
    | _ => {
        Js.log2(
          "[EventManagerPersistence] Unknown error parsing guestPlayers JSON for event:",
          eventId,
        )
        None
      }
    }
  )
  ->Option.flatMap(arr =>
    arr->Array.map(Player.fromJson)->Array.every(Option.isSome)
      ? Some(arr->Array.filterMap(Player.fromJson))
      : None
  )
  ->Option.getOr([])
}

// Save guest players for an event to TinyBase
let saveGuestPlayers = (eventId: string, guestPlayers: array<Player.t<'a>>) => {
  let guestPlayersJson = guestPlayers->Array.map(Player.toJson)
  let guestPlayersStr = guestPlayersJson->Js.Json.stringifyAny->Option.getOr("[]")

  let eventsTable = eventStore->TinyBase.getTable("eventState")
  let existingRow = eventsTable->Js.Dict.get(eventId)->Option.getOr(Js.Dict.empty())
  existingRow->Js.Dict.set("guestPlayers", guestPlayersStr->Js.Json.string)
  eventStore->TinyBase.setRow("eventState", eventId, existingRow)
}

// Sync rounds to TinyBase - saves all match data with player IDs and scores
let syncRoundsToDb = (eventId: string, rounds: array<array<completedMatchEntity<'a>>>) => {
  // First, delete all existing matches for this event
  let matchesTable = eventStore->TinyBase.getTable("matches")
  let matchIdsToDelete =
    matchesTable
    ->Js.Dict.entries
    ->Array.filterMap(((matchId, matchRow)) => {
      switch matchRow->Js.Dict.get("eventId")->Option.map(v => v->Obj.magic) {
      | Some(mEventId: string) if mEventId == eventId => Some(matchId)
      | _ => None
      }
    })

  matchIdsToDelete->Array.forEach(matchId => {
    eventStore->TinyBase.delRow("matches", matchId)
  })

  // Add all matches from all rounds
  rounds->Array.forEachWithIndex((roundMatches, roundIndex) => {
    roundMatches->Array.forEach(matchEntity => {
      let matchId = matchEntity.id
      let (team1, team2) = matchEntity.match

      // Create match row
      let matchRowData = Js.Dict.empty()
      matchRowData->Js.Dict.set("eventId", eventId->Js.Json.string)
      matchRowData->Js.Dict.set("roundIndex", roundIndex->Int.toFloat->Js.Json.number)
      matchRowData->Js.Dict.set("createdAt", matchEntity.createdAt->Js.Date.getTime->Js.Json.number)

      // Store full player objects as JSON strings (TinyBase only supports primitives)
      let team1Json = team1->Array.map(Player.toJson)
      let team2Json = team2->Array.map(Player.toJson)

      let team1PlayersJson = team1Json->Js.Json.stringifyAny->Option.getOr("[]")
      let team2PlayersJson = team2Json->Js.Json.stringifyAny->Option.getOr("[]")

      matchRowData->Js.Dict.set("team1Players", team1PlayersJson->Js.Json.string)
      matchRowData->Js.Dict.set("team2Players", team2PlayersJson->Js.Json.string)

      // Store score if present
      switch matchEntity.score {
      | Some((team1Score, team2Score)) => {
          matchRowData->Js.Dict.set("hasScore", true->Js.Json.boolean)
          matchRowData->Js.Dict.set("team1Score", team1Score->Js.Json.number)
          matchRowData->Js.Dict.set("team2Score", team2Score->Js.Json.number)
        }
      | None => matchRowData->Js.Dict.set("hasScore", false->Js.Json.boolean)
      }

      eventStore->TinyBase.setRow("matches", matchId, matchRowData)
    })
  })
}
