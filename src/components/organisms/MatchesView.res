%%raw("import { t, plural } from '@lingui/macro'")
open Lingui.Util
@react.component
let make = (
  ~matches: array<Rating.match>,
  ~activity,
  ~minRating,
  ~maxRating,
  ~dequeueMatch,
  ~updatePlayCounts,
  ~updateSessionPlayerRatings
) => {
  <div className="w-full h-full absolute top-0 left-0 bg-black">
    <div className="flex h-[74px] justify-between items-center"> {t`Test`} </div>
    <div className="w-full h-[calc(100vh-74px)]">
      <main role="main" className="w-full h-full grid grid-cols-3 gap-3">
        {matches
        ->Array.mapWithIndex((match, i) =>
          <div className="flex flex-col bg-white rounded shadow px-4 pt-5 pb-4">
            <SubmitMatch
              key={i->Int.toString}
              match
              minRating
              maxRating
              activity
              // onSubmitted={() => {
              // updatePlayCounts(match)
              // dequeueMatch(i)
              // }}
              onDelete={() => dequeueMatch(i)}
              onComplete={match => {
                dequeueMatch(i)
                updatePlayCounts(match)

                let match = match->Rating.Match.rate
                updateSessionPlayerRatings(match->Array.flatMap(x => x))
              }}
            />
          </div>
        )
        ->React.array}
      </main>
    </div>
  </div>
}
