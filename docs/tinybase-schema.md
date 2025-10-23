# TinyBase Relational Schema for Matches

## Overview

The match data in the AiTetsu component is now properly modeled using TinyBase's relational capabilities instead of storing JSON blobs. This allows for better querying, data integrity, and leverages TinyBase's reactive features.

## Schema Design

### Tables

#### 1. `matches`

Primary table for match records.

**Columns:**

- `matchId` (Primary Key): `${eventId}-match-${Js.Date.now()->Float.toString}` (timestamp-based for uniqueness)
- `eventId` (Foreign Key): Links to event
- `createdAt`: Timestamp when match was created

**Note:** Match IDs use `Js.Date.now()` converted to string to ensure uniqueness when matches are added.

**Example:**

```javascript
{
  "event-123-match-1704067200000.123": {
    "eventId": "event-123",
    "createdAt": 1704067200000.123
  }
}
```

#### 2. `teams`

Stores teams for each match (2 teams per match).

**Columns:**

- `teamId` (Primary Key): `${matchId}-team-${teamStableId}` where `teamStableId` is derived from player IDs
- `matchId` (Foreign Key): References `matches.matchId`
- `teamIndex`: 0 or 1 (for team1 and team2)
- `playerIds`: JSON-stringified array of player IDs (TinyBase only supports primitives)

**Note:** Teams use stable IDs based on player composition to maintain referential integrity across match updates.

**Example:**

```javascript
{
  "event-123-match-1704067200000.123-team-user-abc_user-def": {
    "matchId": "event-123-match-1704067200000.123",
    "teamIndex": 0,
    "playerIds": "[\"user-abc\", \"user-def\"]"
  }
}
```

#### 3. `players`

Stores global player data (not tied to specific matches).

**Columns:**

- `playerId` (Primary Key): User ID from GraphQL (used directly as row key)
- `intId`: Integer ID for display purposes
- `name`: Player name
- `ratingMu`: Rating μ (mean skill level)
- `ratingSigma`: Rating σ (uncertainty)
- `genderInt`: Gender as integer (0=Male, 1=Female)
- `paid`: Boolean indicating payment status

**Note:** Players are stored globally and reused across all matches and events. The `data` field (GraphQL fragment reference) is NOT persisted - it is hydrated from GraphQL after loading from TinyBase.

**Example:**

```javascript
{
  "User_abc": {
    "intId": 1,
    "name": "John Doe",
    "ratingMu": 25.0,
    "ratingSigma": 8.333,
    "genderInt": 1,
    "paid": false
  }
}
```

## Relationships

```
matches (1) ──< teams (2)
teams (1) ──< players (N, via playerIds JSON array)
```

- One **match** has two **teams** (referenced by matchId)
- Each **team** has multiple **players** (typically 2 for doubles, stored as JSON array in playerIds column)
- **Players** are stored globally in a separate table and reused across matches
- All matches for an event are linked via `eventId` foreign key
- Team IDs incorporate player composition for stability across updates

## Data Flow

### Writing Matches

When `setMatches` is called, it performs a complete rebuild of all matches for the event:

1. **Delete Phase** (for all matches in the event):

   - Find all matches with matching `eventId`
   - For each match, find and delete all teams (by `matchId`)
   - Delete the match row
   - Players remain in the global `players` table (they're reused)

2. **Insert Phase**:

   ```rescript
   newMatches->Array.forEachWithIndex((match, matchIndex) => {
     // Generate timestamp-based unique ID
     let matchId = `${eventId}-match-${Js.Date.now()}-${Js.Math.random()}`

     // Create match row
     let matchRowData = Js.Dict.empty()
     matchRowData->Js.Dict.set("eventId", eventId->Js.Json.string)
     matchRowData->Js.Dict.set("createdAt", Js.Date.now()->Js.Json.number)
     matchesStore->TinyBase.setRow("matches", matchId, matchRowData)

     // Create team rows
     let (team1, team2) = match
     [team1, team2]->Array.forEachWithIndex((team, teamIndex) => {
       let teamStableId = team->Team.toStableId
       let teamId = `${matchId}-team-${teamStableId}`

       let teamRowData = Js.Dict.empty()
       teamRowData->Js.Dict.set("matchId", matchId->Js.Json.string)
       teamRowData->Js.Dict.set("teamIndex", teamIndex->Int.toFloat->Js.Json.number)
       teamRowData->Js.Dict.set("playerIds",
         team->Array.map(p => p.id)->Js.Json.stringifyAny->Option.getOr("[]")->Js.Json.string
       )
       matchesStore->TinyBase.setRow("teams", teamId, teamRowData)

       // Create/update global player rows
       team->Array.forEach(player => {
         let existingPlayer = matchesStore->TinyBase.getRow("players", player.id)
         if existingPlayer->Js.Dict.keys->Array.length == 0 {
           let playerData = player->Player.toDb
           matchesStore->TinyBase.setRow("players", player.id, playerData)
         }
       })
     })
   })
   ```

### Reading Matches

The `matches` value is computed via `React.useMemo2` with dependencies on `matchesTableJson` and `data.rsvps`:

```rescript
let (matches: array<match>, matchIds: array<string>) = React.useMemo2(() => {
  // Create rsvpMap for hydrating player data
  let rsvpMap = data.rsvps
    ->Fragment.getConnectionNodes
    ->Array.filterMap(rsvp =>
      rsvp.user->Option.map(u => (u.id, rsvp))
    )
    ->Js.Dict.fromArray

  // Get tables once
  let teamsTable = matchesStore->TinyBase.getTable("teams")
  let playersTable = matchesStore->TinyBase.getTable("players")

  // Load and hydrate matches
  let matchesWithIds = matchesTableJson
    ->Js.Dict.entries
    ->Array.filterMap(((matchId, matchRow)) => {
      // Filter by eventId
      switch matchRow->Js.Dict.get("eventId")->Option.map(v => v->Obj.magic) {
      | Some(mEventId: string) if mEventId == eventId =>
        // Load from DB and hydrate with RSVP data
        Match.loadFromDb(matchRow, teamsTable, playersTable, matchId)
        ->Option.map(match => (hydrateMatchWithRsvpData(match, rsvpMap), matchId))
      | _ => None
      }
    })

  // Return both matches and IDs for deletion
  let matches = matchesWithIds->Array.map(((match, _)) => match)
  let ids = matchesWithIds->Array.map(((_, id)) => id)
  (matches, ids)
}, (matchesTableJson, data.rsvps))
```

### Direct Match Operations

**queueMatch** - Adds a single match without rebuilding entire list:

```rescript
let queueMatch = (match, ~dequeue=true) => {
  // Generate unique timestamp-based ID
  let matchId = `${eventId}-match-${Js.Date.now()->Float.toString}`

  // Create match, teams, and players directly in TinyBase
  // (same structure as setMatches insert phase)
}
```

**dequeueMatch** - Removes a single match by index:

```rescript
let dequeueMatch = index => {
  // Look up actual match ID from matchIds array
  let matchIdToDelete = matchIds->Array.get(index->Int.fromString->Option.getOr(0))

  // Delete teams for this match
  let teamsTable = matchesStore->TinyBase.getTable("teams")
  let teamIdsToDelete = /* filter teams by matchId */
  teamIdsToDelete->Array.forEach(teamId => {
    matchesStore->TinyBase.delRow("teams", teamId)
  })

  // Delete the match
  matchesStore->TinyBase.delRow("matches", matchIdToDelete)
}
```

### GraphQL Hydration

Player `data` field is NOT persisted to TinyBase. Instead, it's hydrated after loading:

```rescript
let hydratePlayerWithRsvpData = (player, rsvpMap) => {
  switch rsvpMap->Js.Dict.get(player.id) {
  | Some(rsvp) => {...player, data: Some(rsvp)}
  | None => {...player, data: None} // Guest players
  }
}
```

## Benefits

### 1. **Timestamp-Based Unique IDs**

- Match IDs use `Js.Date.now()` to ensure uniqueness
- Prevents ID collisions when matches are deleted and new ones added quickly
- Maintains referential integrity across rapid updates

### 2. **Efficient Single-Match Operations**

- `queueMatch`: Directly inserts one match without rebuilding entire list
- `dequeueMatch`: Directly deletes one match using matchIds lookup array
- No unnecessary rebuilds for single-item operations

### 3. **Global Player Storage**

- Players stored once and reused across all matches and events
- Reduces data duplication
- Easier to update player attributes globally

### 4. **GraphQL Data Hydration**

- Player `data` field (GraphQL fragment) not persisted to avoid serialization complexity
- Hydrated from RSVP data after loading from TinyBase
- Guest players have `data: None`

### 5. **Data Integrity**

- Foreign keys ensure referential integrity
- Cascade deletes for teams when matches are removed
- Type-safe data access through domain methods

### 6. **Granular Reactivity**

- Can subscribe to specific cells, rows, or tables
- React components re-render only when relevant data changes
- Use `useTable` hook for reactive updates

### 7. **Clean Separation of Concerns**

- Serialization logic lives in domain modules (`Rating.res`)
- Component code (`AiTetsu.res`) focuses on UI logic
- Type-safe transformations prevent runtime errors

## Future Enhancements

### Indexes

Add indexes for common queries:

```rescript
// Index matches by eventId for faster filtering
// Index teams by matchId for faster joins
```

### Relationships API

TinyBase supports a Relationships API for explicit foreign key definitions:

```rescript
let relationships = TinyBase.createRelationships(store)
relationships->addRelationship("teams", "matches", "matchId")
```

### Queries

Can use TinyBase queries for complex data retrieval:

```rescript
// Example: Get all players across all matches for an event
let query = TinyBase.createQueries(store)
query->setQueryDefinition(
  "eventPlayers",
  "matches",
  ({select, join, where}) => {
    select("matchId")
    join("teams", "matchId")
    where(getCell("matches", _, "eventId") == eventId)
  }
)
```

## Migration Notes

### Before (Index-Based Match IDs)

```rescript
// Match IDs based on array index: event-123-match-0, event-123-match-1, etc.
let matchId = `${eventId}-match-${matchIndex->Int.toString}`
```

**Problem:** When a match is deleted, indices shift, causing potential ID collisions and referential integrity issues.

### After (Timestamp-Based Match IDs)

```rescript
// Match IDs use timestamp: event-123-match-1704067200000.123
let matchId = `${eventId}-match-${Js.Date.now()->Float.toString}`
```

**Solution:** Timestamp-based IDs prevent collisions when matches are added in sequence.

### Key Differences

- **Before**: Index-based IDs `event-123-match-0`
- **After**: Timestamp-based IDs `event-123-match-1704067200000.123`
- **Before**: Single operations rebuilt entire match list
- **After**: Direct TinyBase operations for single match add/remove
- **Before**: Player data serialized with matches
- **After**: Players stored globally, data field hydrated from GraphQL

## Code Examples

### Match ID Generation

```rescript
// Generate unique timestamp-based match ID
let matchId = `${eventId}-match-${Js.Date.now()->Float.toString}`

// Example output: "event-123-match-1704067200000.123"
```

### Player Serialization (in Rating.res)

```rescript
// Player.toDb: Converts player to database row
// NOTE: data field is NOT persisted - it will be hydrated from GraphQL after loading
let toDb = (player: t<'a>): Js.Dict.t<Js.Json.t> => {
  let row = Js.Dict.empty()
  row->Js.Dict.set("playerId", player.id->Js.Json.string)
  row->Js.Dict.set("intId", player.intId->Int.toFloat->Js.Json.number)
  row->Js.Dict.set("name", player.name->Js.Json.string)
  row->Js.Dict.set("ratingMu", player.rating.mu->Js.Json.number)
  row->Js.Dict.set("ratingSigma", player.rating.sigma->Js.Json.number)
  row->Js.Dict.set("genderInt", player.gender->Gender.toInt->Int.toFloat->Js.Json.number)
  row->Js.Dict.set("paid", player.paid->Js.Json.boolean)
  row
}

// Player.fromDb: Reconstructs player from database row
// NOTE: data field is set to None - it will be hydrated from GraphQL after loading
let fromDb = (row: Js.Dict.t<Js.Json.t>): option<t<'a>> => {
  // Extract and validate all required fields
  switch (playerId, intId, name, mu, sigma, genderInt) {
  | (Some(playerId), Some(intId), Some(name), Some(mu), Some(sigma), Some(genderInt)) =>
    Some({
      data: None, // Will be hydrated from GraphQL
      id: playerId,
      intId: intId->Float.toInt,
      name: name,
      rating: {mu: mu, sigma: sigma},
      ratingOrdinal: rating->Rating.ordinal,
      paid: paid->Option.getOr(false),
      gender: Gender.fromInt(genderInt->Float.toInt),
    })
  | _ => None
  }
}
```

### Team Structure

```rescript
// Team.toStableId: Generate stable ID from player IDs
let toStableId = (team: array<Player.t<'a>>): string => {
  team
  ->Array.map(p => p.id)
  ->Array.toSorted(String.compare)
  ->Array.join("_")
}

// Example: ["user-abc", "user-def"] -> "user-abc_user-def"
```

### Match Loading (in Rating.res)

```rescript
// Match.loadFromDb: Reconstructs match from TinyBase tables
let loadFromDb = (
  _matchRow: Js.Dict.t<Js.Json.t>,
  teamsTable: Js.Dict.t<Js.Dict.t<Js.Json.t>>,
  playersTable: Js.Dict.t<Js.Dict.t<Js.Json.t>>,
  matchId: string,
): option<Match.t<Js.Json.t>> => {
  // Find teams for this match
  let teams =
    teamsTable
    ->Js.Dict.entries
    ->Array.filterMap(((_, teamRow)) => {
      switch teamRow->Js.Dict.get("matchId")->Option.map(v => v->Obj.magic) {
      | Some(mId: string) if mId == matchId =>
        // Parse playerIds JSON array
        let playerIds =
          teamRow
          ->Js.Dict.get("playerIds")
          ->Option.flatMap(v => v->Obj.magic->Js.Json.stringifyAny)
          ->Option.flatMap(str => {
            try Some(str->Js.Json.parseExn) catch {
            | _ => None
            }
          })
          ->Option.flatMap(json => json->Json.Decode.decode(Json.Decode.array(Json.Decode.string)))
          ->Option.map(Result.toOption)
          ->Option.flatMap(x => x)
          ->Option.getOr([])

        // Load players from global players table
        let players =
          playerIds
          ->Array.filterMap(playerId => {
            playersTable->Js.Dict.get(playerId)->Option.flatMap(Player.fromDb)
          })

        Some(players)
      | _ => None
      }
    })
    ->Array.toSorted((a, b) => {
      // Sort by teamIndex if available
      Float.compare(
        a->Js.Dict.get("teamIndex")->Option.getOr(0.0->Js.Json.number)->Obj.magic,
        b->Js.Dict.get("teamIndex")->Option.getOr(0.0->Js.Json.number)->Obj.magic,
      )
    })

  // Return match as tuple of two teams
  switch teams {
  | [team1, team2] => Some((team1, team2))
  | _ => None
  }
}
```

### Usage in AiTetsu.res

#### Writing Matches (setMatches - Bulk Update)

```rescript
let setMatches = (updater: array<match> => array<match>) => {
  let newMatches = updater(matches)

  // Delete all existing matches for this event
  let currentMatchesTable = matchesStore->TinyBase.getTable("matches")
  let matchIdsToDelete =
    currentMatchesTable
    ->Js.Dict.entries
    ->Array.filterMap(((matchId, row)) => {
      switch row->Js.Dict.get("eventId")->Option.map(v => v->Obj.magic) {
      | Some(evId: string) if evId == eventId => Some(matchId)
      | _ => None
      }
    })

  // Cascade delete: teams then matches
  matchIdsToDelete->Array.forEach(matchId => {
    let teamsTable = matchesStore->TinyBase.getTable("teams")
    let teamIdsToDelete =
      teamsTable
      ->Js.Dict.entries
      ->Array.filterMap(((teamId, teamRow)) => {
        switch teamRow->Js.Dict.get("matchId")->Option.map(v => v->Obj.magic) {
        | Some(mId: string) if mId == matchId => Some(teamId)
        | _ => None
        }
      })
    teamIdsToDelete->Array.forEach(teamId => {
      matchesStore->TinyBase.delRow("teams", teamId)
    })
    matchesStore->TinyBase.delRow("matches", matchId)
  })

  // Insert new matches with timestamp-based IDs
  newMatches->Array.forEachWithIndex((match, matchIndex) => {
    let matchId = `${eventId}-match-${matchIndex->Int.toString}`
    // ... insert logic
  })
}
```

#### Adding Single Match (queueMatch)

```rescript
let queueMatch = (match, ~dequeue=true) => {
  // Generate unique timestamp-based ID
  let matchId = `${eventId}-match-${Js.Date.now()->Float.toString}`

  // Create match row
  let matchRowData = Js.Dict.empty()
  matchRowData->Js.Dict.set("eventId", eventId->Js.Json.string)
  matchRowData->Js.Dict.set("createdAt", Js.Date.now()->Js.Json.number)
  matchesStore->TinyBase.setRow("matches", matchId, matchRowData)

  // Create teams and players...
}
```

#### Removing Single Match (dequeueMatch)

```rescript
let dequeueMatch = index => {
  // Look up actual match ID from matchIds array
  let matchIdToDelete = matchIds->Array.get(index->Int.fromString->Option.getOr(0))

  switch matchIdToDelete {
  | Some(matchIdToDelete) =>
    // Find and delete teams
    let teamsTable = matchesStore->TinyBase.getTable("teams")
    let teamIdsToDelete =
      teamsTable
      ->Js.Dict.entries
      ->Array.filterMap(((teamId, teamRow)) => {
        switch teamRow->Js.Dict.get("matchId")->Option.map(v => v->Obj.magic) {
        | Some(mId: string) if mId == matchIdToDelete => Some(teamId)
        | _ => None
        }
      })

    teamIdsToDelete->Array.forEach(teamId => {
      matchesStore->TinyBase.delRow("teams", teamId)
    })

    // Delete the match
    matchesStore->TinyBase.delRow("matches", matchIdToDelete)
  | None => ()
  }
}
```

#### Reading Matches with Hydration

```rescript
let (matches: array<match>, matchIds: array<string>) = React.useMemo2(() => {
  // Create rsvpMap for O(1) lookup
  let rsvpMap =
    data.rsvps
    ->Fragment.getConnectionNodes
    ->Array.filterMap(rsvp =>
      rsvp.user->Option.map(u => u.id)->Option.map(userId => (userId, rsvp))
    )
    ->Js.Dict.fromArray

  // Get tables
  let teamsTable = matchesStore->TinyBase.getTable("teams")
  let playersTable = matchesStore->TinyBase.getTable("players")

  // Load and hydrate matches
  let matchesWithIds =
    matchesTableJson
    ->Js.Dict.entries
    ->Array.filterMap(((matchId, matchRow)) => {
      switch matchRow->Js.Dict.get("eventId")->Option.map(v => v->Obj.magic) {
      | Some(mEventId: string) if mEventId == eventId =>
        Match.loadFromDb(matchRow, teamsTable, playersTable, matchId)
        ->Option.map(match => (hydrateMatchWithRsvpData(match, rsvpMap), matchId))
      | _ => None
      }
    })

  // Return both matches and IDs
  let matches = matchesWithIds->Array.map(((match, _)) => match)
  let ids = matchesWithIds->Array.map(((_, id)) => id)
  (matches, ids)
}, (matchesTableJson, data.rsvps))
```

## Performance Considerations

- **Read Performance**: Requires loading 3 tables (matches, teams, players) with filtering and JSON parsing
- **Write Performance (setMatches)**: Cascade delete then multiple inserts (bulk operation for drag-and-drop)
- **Write Performance (queueMatch/dequeueMatch)**: Single match operations without rebuilding entire list
- **Match ID Lookup**: `matchIds` array maps UI indices to actual TinyBase IDs for efficient deletion
- **Memory**: Uses more rows than single JSON blob, but enables better querying
- **Trade-off**: Better data modeling and operation efficiency at cost of slightly more complex structure

## Testing Recommendations

1. **Timestamp Uniqueness**: Verify match IDs are unique even with rapid add/delete operations
2. **Data Integrity**: Verify cascade deletes work correctly (teams deleted when match deleted)
3. **Event Isolation**: Ensure matches don't leak between events
4. **Player Reconstruction**: Verify all player fields are correctly stored/retrieved
5. **GraphQL Hydration**: Test that player `data` field is correctly hydrated from RSVP data
6. **Guest Players**: Verify guest players (data: None) work correctly
7. **Gender Handling**: Test Male/Female conversion to/from int
8. **React Reactivity**: Verify `useTable` hook triggers re-renders on updates
9. **Index Mapping**: Verify `matchIds` array correctly maps UI indices to TinyBase IDs
