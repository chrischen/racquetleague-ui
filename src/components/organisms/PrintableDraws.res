%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

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
let make = (~rounds: array<round>, ~onClose: unit => unit) => {
  let ts = Lingui.UtilString.t

  let handlePrint = _ => {
    %raw(`window.print()`)
  }

  let currentDate = %raw(`new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' })`)

  <div
    className="print-root fixed inset-0 z-50 bg-slate-200 overflow-y-auto print:bg-white print:overflow-visible">
    // Screen-only Controls Header
    <div
      className="sticky top-0 z-10 bg-slate-800 text-white px-6 py-3 flex items-center justify-between shadow-md print:hidden">
      <div className="flex items-center gap-3">
        <Lucide.Printer className="w-5 h-5" />
        <h2 className="text-lg font-bold"> {(ts`Print Preview`)->React.string} </h2>
      </div>
      <div className="flex items-center gap-3">
        <button
          onClick={handlePrint}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors">
          <Lucide.Printer className="w-4 h-4" />
          {(ts`Print`)->React.string}
        </button>
        <button
          onClick={_ => onClose()}
          className="p-2 bg-slate-700 hover:bg-slate-600 rounded-lg transition-colors"
          ariaLabel="Close">
          <Lucide.X className="w-5 h-5" />
        </button>
      </div>
    </div>
    // Printable Document Container
    <div
      className="max-w-4xl mx-auto my-4 bg-white shadow-2xl print:shadow-none print:my-0 print:max-w-none">
      <div className="p-6 print:p-4">
        // Document Header
        <div className="flex items-baseline justify-between border-b-2 border-black pb-2 mb-4">
          <h1
            className="text-xl font-black text-black uppercase tracking-wider">
            {(ts`Tournament Draws`)->React.string}
          </h1>
          <p className="text-sm text-gray-600"> {currentDate->React.string} </p>
        </div>
        // Rounds
        <div className="space-y-4">
          {rounds
          ->Array.map(round => {
            <div key={Int.toString(round.roundNumber)} className="print:break-inside-avoid">
              // Round Header
              <div
                className="bg-black text-white px-2 py-0.5 mb-2 flex items-center justify-between">
                <h2 className="text-sm font-bold uppercase tracking-wider">
                  {t`Round ${Int.toString(round.roundNumber)}`}
                </h2>
                <span className="text-xs">
                  {(Int.toString(round.matches->Array.length) ++
                  " " ++
                  (round.matches->Array.length === 1 ? ts`match` : ts`matches`))->React.string}
                </span>
              </div>
              // Matches Grid
              <div className="grid grid-cols-2 gap-2 print:grid-cols-2">
                {round.matches
                ->Array.map(match => {
                  <div key={match.id} className="border border-black flex print:break-inside-avoid">
                    // Court # column
                    <div
                      className="border-r border-black px-1.5 py-1 flex items-center justify-center bg-gray-100">
                      <span
                        className="text-xs font-black uppercase whitespace-nowrap [writing-mode:vertical-rl] rotate-180">
                        {("C" ++ Int.toString(match.courtNumber))->React.string}
                      </span>
                    </div>
                    // Teams
                    <div className="flex-1 flex flex-col text-xs">
                      // Team 1
                      <div className="flex items-stretch border-b border-black">
                        <div className="flex-1 px-2 py-1 flex flex-col justify-center min-w-0">
                          {match.team1.players
                          ->Array.map(player =>
                            <div
                              key={player.id}
                              className="font-semibold text-black leading-tight truncate">
                              {player.name->React.string}
                              <span className="ml-1 font-mono font-normal text-gray-600">
                                {("#" ++ Int.toString(player.number))->React.string}
                              </span>
                            </div>
                          )
                          ->React.array}
                        </div>
                        // Score Box
                        <div
                          className="w-10 border-l border-black flex items-center justify-center flex-shrink-0"
                        />
                      </div>
                      // Team 2
                      <div className="flex items-stretch">
                        <div className="flex-1 px-2 py-1 flex flex-col justify-center min-w-0">
                          {match.team2.players
                          ->Array.map(player =>
                            <div
                              key={player.id}
                              className="font-semibold text-black leading-tight truncate">
                              {player.name->React.string}
                              <span className="ml-1 font-mono font-normal text-gray-600">
                                {("#" ++ Int.toString(player.number))->React.string}
                              </span>
                            </div>
                          )
                          ->React.array}
                        </div>
                        // Score Box
                        <div
                          className="w-10 border-l border-black flex items-center justify-center flex-shrink-0"
                        />
                      </div>
                    </div>
                  </div>
                })
                ->React.array}
              </div>
            </div>
          })
          ->React.array}
          {rounds->Array.length === 0
            ? <div className="text-center py-12 text-gray-500 font-medium">
                {(ts`No draws generated yet.`)->React.string}
              </div>
            : React.null}
        </div>
      </div>
    </div>
  </div>
}
