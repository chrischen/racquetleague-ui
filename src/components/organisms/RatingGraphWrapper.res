%%raw("import { t } from '@lingui/macro'")

open Lingui.Util

// Reuse the same fragment as MatchHistoryList
module Fragment = %relay(`
  fragment RatingGraphWrapperFragment on Query
  @argumentDefinitions (
    after: { type: "String" }
    before: { type: "String" }
    first: { type: "Int", defaultValue: 100 }
    activitySlug: { type: "String!" }
    userId: { type: "ID" }
  )
  @refetchable(queryName: "RatingGraphWrapperRefetchQuery")
  {
    __id
    matches(after: $after, first: $first, before: $before, activitySlug: $activitySlug, userId: $userId)
    @connection(key: "RatingGraphWrapperFragment_matches") {
      __id
      edges {
        node {
          id
          createdAt
          playerMetadata
        }
      }
      pageInfo {
        hasNextPage
        hasPreviousPage
        endCursor
        startCursor
      }
    }
  }
`)

module PlayerRating = {
  type t = {
    mu: float,
    sigma: float,
    muDiff: option<float>,
    sigmaDiff: option<float>,
  }

  let decode = (json: Js.Json.t): option<t> => {
    try {
      let dict = json->Js.Json.decodeObject
      dict->Option.flatMap(d => {
        let mu = d->Js.Dict.get("mu")->Option.flatMap(v => Js.Json.decodeNumber(v))
        let sigma = d->Js.Dict.get("sigma")->Option.flatMap(v => Js.Json.decodeNumber(v))
        let muDiff = d->Js.Dict.get("muDiff")->Option.flatMap(v => Js.Json.decodeNumber(v))
        let sigmaDiff = d->Js.Dict.get("sigmaDiff")->Option.flatMap(v => Js.Json.decodeNumber(v))

        switch (mu, sigma) {
        | (Some(mu), Some(sigma)) => Some({mu, sigma, muDiff, sigmaDiff})
        | _ => None
        }
      })
    } catch {
    | _ => None
    }
  }
}

module PlayerMetadata = {
  type t = Js.Dict.t<PlayerRating.t>

  let decode = (jsonString: option<string>): option<t> => {
    jsonString->Option.flatMap(str => {
      try {
        let json = Js.Json.parseExn(str)
        json
        ->Js.Json.decodeObject
        ->Option.flatMap(dict => {
          let metadata = Js.Dict.empty()
          dict
          ->Js.Dict.entries
          ->Array.forEach(
            ((playerId, ratingJson)) => {
              PlayerRating.decode(ratingJson)->Option.forEach(
                rating => {
                  metadata->Js.Dict.set(playerId, rating)
                },
              )
            },
          )
          Some(metadata)
        })
      } catch {
      | _ => None
      }
    })
  }

  let get = (metadata: option<t>, playerId: string): option<PlayerRating.t> => {
    metadata->Option.flatMap(m => m->Js.Dict.get(playerId))
  }
}

// Transform match history data into rating history points
let transformToRatingHistory = (
  matches: array<RatingGraphWrapperFragment_graphql.Types.fragment_matches_edges_node>,
  userId: string,
): array<RatingGraph.ratingDataPoint> => {
  // Sort matches by date (oldest first) and accumulate rating history
  let sortedMatches = matches->Array.toSorted((a, b) => {
    let aDate = a.createdAt->Option.map(Util.Datetime.toDate)->Option.getOr(Js.Date.make())
    let bDate = b.createdAt->Option.map(Util.Datetime.toDate)->Option.getOr(Js.Date.make())
    Js.Date.getTime(aDate) > Js.Date.getTime(bDate) ? 1.0 : -1.0
  })

  sortedMatches->Array.filterMap(match => {
    let metadata = PlayerMetadata.decode(match.playerMetadata)
    let playerRating = PlayerMetadata.get(metadata, userId)
    let date = match.createdAt->Option.map(Util.Datetime.toDate)

    switch (playerRating, date) {
    | (Some(rating), Some(date)) =>
      // Format date and time as a string (e.g., "Jan 15, 3:30 PM")
      let dateStr = date->Js.Date.toLocaleString
      // Calculate the rating after this match (initial + diff)
      let finalMu = rating.mu +. rating.muDiff->Option.getOr(0.0)
      let finalSigma = rating.sigma +. rating.sigmaDiff->Option.getOr(0.0)
      // Ordinal rating is mu - 3*sigma (conservative estimate)
      let ordinal = finalMu -. finalSigma *. 3.0
      let dataPoint: RatingGraph.ratingDataPoint = {
        date: dateStr,
        rating: ordinal,
        uncertainty: finalSigma,
        upperBound: finalMu,
        lowerBound: ordinal,
      }
      Some(dataPoint)
    | _ => None
    }
  })
}

@genType @react.component
let make = (~matches, ~userId: string) => {
  let data = Fragment.use(matches)
  let matches = data.matches->Fragment.getConnectionNodes

  let ratingHistory = React.useMemo2(() => {
    transformToRatingHistory(matches, userId)
  }, (matches, userId))

  <WaitForMessages>
    {() => {
      // Don't render if no data
      if ratingHistory->Array.length == 0 {
        React.null
      } else {
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6 mb-6">
          <div className="mb-6">
            <h2 className="text-xl font-bold text-gray-900 mb-1"> {t`Rating History`} </h2>
            <p className="text-sm text-gray-600">
              {t`The shaded area represents rating uncertainty. Narrower bands indicate higher confidence.`}
            </p>
          </div>
          <RatingGraph data={ratingHistory} />
        </div>
      }
    }}
  </WaitForMessages>
}

@genType
let default = make
