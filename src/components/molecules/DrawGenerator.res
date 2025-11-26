%%raw("import { t } from '@lingui/macro'")

type strategyOption = {
  value: Rating.strategy,
  label: string,
  description: string,
}

@react.component
let make = (
  ~courtCount: int,
  ~checkedInPlayerCount: int,
  ~hasExistingDraws: bool,
  ~strategy: Rating.strategy,
  ~onStrategyChange: Rating.strategy => unit,
  ~onGenerateDraws: unit => unit,
  ~onCourtCountChange: int => unit,
  ~isInitiallyExpanded: bool=true,
  ~highlight: bool=false,
  ~futureRoundsHaveScores: bool=false,
) => {
  let ts = Lingui.UtilString.t
  let (isExpanded, setIsExpanded) = React.useState(() => isInitiallyExpanded)
  let (isHighlighting, setIsHighlighting) = React.useState(() => false)

  // Highlight effect when highlight prop is true and component is collapsed
  React.useEffect(() => {
    if highlight && !isExpanded {
      setIsHighlighting(_ => true)
      let timeoutId = setTimeout(() => {
        setIsHighlighting(_ => false)
      }, 2000)
      Some(() => clearTimeout(timeoutId))
    } else {
      // Clear highlighting when highlight becomes false or component is expanded
      let timeoutId = setTimeout(() => {
        setIsHighlighting(_ => false)
      }, 2000)
      Some(() => clearTimeout(timeoutId))
    }
  }, (highlight, isExpanded))

  let strategyOptions = [
    {
      value: Rating.CompetitivePlus,
      label: ts`Competitive`,
      description: ts`Players will be divided into similar skill level groups that round-robin with teams balanced by skill.`,
    },
    {
      value: Rating.Mixed,
      label: ts`Mixed`,
      description: ts`Round-Robin with teams balanced by skill.`,
    },
    {
      value: Rating.Random,
      label: ts`Round-Robin`,
      description: ts`Classic round-robin draws`,
    },
  ]
  let minPlayersRequired = courtCount * 4
  let canGenerate = checkedInPlayerCount >= minPlayersRequired

  let courtText = courtCount == 1 ? "court" : "courts"

  let selectedStrategy = strategyOptions->Array.find(opt => opt.value == strategy)

  let handleIncrement = () => {
    if courtCount < 10 {
      onCourtCountChange(courtCount + 1)
    }
  }

  let handleDecrement = () => {
    if courtCount > 1 {
      onCourtCountChange(courtCount - 1)
    }
  }

  <div className="my-8 relative">
    // Divider line
    <div className="absolute inset-0 flex items-center" ariaHidden={true}>
      <div className="w-full border-t-2 border-dashed border-slate-300" />
    </div>
    <div className="relative flex justify-center">
      <div className="bg-slate-50 px-4">
        <div
          className={"bg-white rounded-lg border shadow-sm max-w-3xl transition-all duration-300 " ++ (
            isHighlighting && !isExpanded
              ? hasExistingDraws
                  ? "border-orange-400 shadow-orange-200 shadow-lg animate-pulse"
                  : "border-blue-400 shadow-blue-200 shadow-lg animate-pulse"
              : "border-slate-200"
          )}>
          // Collapsed Header
          <button
            onClick={_ => setIsExpanded(prev => !prev)}
            className={"w-full p-4 flex items-center justify-between transition-colors rounded-lg " ++ (
              isHighlighting && !isExpanded
                ? hasExistingDraws
                    ? "bg-orange-50 hover:bg-orange-100"
                    : "bg-blue-50 hover:bg-blue-100"
                : "hover:bg-slate-50"
            )}>
            <div className="flex items-center gap-3">
              <div className="flex items-center gap-1">
                {hasExistingDraws
                  ? <Lucide.RotateCcw className="w-5 h-5 text-orange-600" />
                  : <Lucide.Shuffle className="w-5 h-5 text-blue-600" />}
                {hasExistingDraws
                  ? <Lucide.ArrowDown className="w-5 h-5 text-orange-600" />
                  : React.null}
              </div>
              <div className="text-left">
                <h3 className="text-sm font-semibold text-slate-900">
                  {(hasExistingDraws ? ts`Update Future Rounds` : ts`Generate Draws`)->React.string}
                </h3>
                <p className="text-xs text-slate-600">
                  {(courtCount->Int.toString ++
                  " " ++
                  courtText ++
                  " • " ++
                  selectedStrategy->Option.map(s => s.label)->Option.getOr("") ++
                  " " ++
                  (ts`strategy`))->React.string}
                </p>
              </div>
            </div>
            {isExpanded
              ? <Lucide.ChevronUp className="w-5 h-5 text-slate-400" />
              : <Lucide.ChevronDown className="w-5 h-5 text-slate-400" />}
          </button>
          // Expanded Content
          {isExpanded
            ? <div className="px-4 pb-4">
                <div className="pt-4 border-t border-slate-200">
                  // Main horizontal layout
                  <div className="flex flex-col md:flex-row items-center gap-4">
                    // Courts Control
                    <div className="flex items-center gap-2">
                      <span className="text-sm text-slate-600 font-medium">
                        {(ts`Courts:`)->React.string}
                      </span>
                      <button
                        onClick={_ => handleDecrement()}
                        disabled={courtCount <= 1}
                        className={courtCount <= 1
                          ? "p-1.5 rounded text-slate-300 cursor-not-allowed"
                          : "p-1.5 rounded text-slate-600 hover:bg-slate-100"}>
                        <Lucide.Minus className="w-4 h-4" />
                      </button>
                      <div className="w-12 text-center text-lg font-semibold text-slate-900">
                        {courtCount->Int.toString->React.string}
                      </div>
                      <button
                        onClick={_ => handleIncrement()}
                        disabled={courtCount >= 10}
                        className={courtCount >= 10
                          ? "p-1.5 rounded text-slate-300 cursor-not-allowed"
                          : "p-1.5 rounded text-slate-600 hover:bg-slate-100"}>
                        <Lucide.Plus className="w-4 h-4" />
                      </button>
                    </div>
                    // Divider
                    <div className="hidden md:block w-px h-8 bg-slate-200" />
                    // Strategy Buttons
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="text-sm text-slate-600 font-medium">
                        {(ts`Strategy:`)->React.string}
                      </span>
                      {strategyOptions
                      ->Array.map(option => {
                        <button
                          key={option.label}
                          onClick={_ => onStrategyChange(option.value)}
                          className={strategy == option.value
                            ? "px-3 py-1.5 text-sm font-medium rounded transition-colors bg-blue-600 text-white"
                            : "px-3 py-1.5 text-sm font-medium rounded transition-colors bg-slate-100 text-slate-700 hover:bg-slate-200"}>
                          {option.label->React.string}
                        </button>
                      })
                      ->React.array}
                    </div>
                    // Generate Button - only show if no existing draws
                    {!hasExistingDraws
                      ? <>
                          <div className="hidden md:block w-px h-8 bg-slate-200" />
                          <button
                            onClick={_ => onGenerateDraws()}
                            disabled={!canGenerate}
                            className={canGenerate
                              ? "px-4 py-1.5 rounded font-medium text-sm transition-colors flex items-center gap-2 bg-blue-600 text-white hover:bg-blue-700"
                              : "px-4 py-1.5 rounded font-medium text-sm transition-colors flex items-center gap-2 bg-slate-200 text-slate-400 cursor-not-allowed"}>
                            <Lucide.Shuffle className="w-4 h-4" />
                            {(ts`Generate`)->React.string}
                          </button>
                        </>
                      : React.null}
                  </div>
                  // Strategy Description
                  {selectedStrategy
                  ->Option.map(selected => {
                    <div className="mt-3 text-sm text-slate-600 italic text-center">
                      {selected.description->React.string}
                    </div>
                  })
                  ->Option.getOr(React.null)}
                  // Not enough players warning
                  {!canGenerate
                    ? <div
                        className="mt-3 text-xs text-amber-700 bg-amber-50 border border-amber-200 rounded px-3 py-2">
                        {(
                          ts`Need ${minPlayersRequired->Int.toString} players for ${courtCount->Int.toString} ${courtText}. Currently ${checkedInPlayerCount->Int.toString} checked in.`
                        )->React.string}
                      </div>
                    : React.null}
                  // Update Rounds Button - at the bottom when existing draws
                  {hasExistingDraws
                    ? <div className="mt-4 pt-4 border-t border-slate-200">
                        {futureRoundsHaveScores
                          ? <ConfirmButton
                              title={(ts`Regenerate Rounds?`)->React.string}
                              description={(
                                ts`Future rounds have scores entered. Regenerating will delete these scores. Are you sure?`
                              )->React.string}
                              onConfirmed={_ => onGenerateDraws()}
                              button={<button
                                disabled={!canGenerate}
                                className={canGenerate
                                  ? "w-full px-4 py-2.5 rounded-lg font-semibold text-sm transition-colors flex items-center justify-center gap-2 bg-orange-600 text-white hover:bg-orange-700"
                                  : "w-full px-4 py-2.5 rounded-lg font-semibold text-sm transition-colors flex items-center justify-center gap-2 bg-slate-200 text-slate-400 cursor-not-allowed"}>
                                <Lucide.RotateCcw className="w-4 h-4" />
                                {(ts`Update Rounds Below`)->React.string}
                                <Lucide.ArrowDown className="w-4 h-4" />
                              </button>}
                            />
                          : <button
                              onClick={_ => onGenerateDraws()}
                              disabled={!canGenerate}
                              className={canGenerate
                                ? "w-full px-4 py-2.5 rounded-lg font-semibold text-sm transition-colors flex items-center justify-center gap-2 bg-orange-600 text-white hover:bg-orange-700"
                                : "w-full px-4 py-2.5 rounded-lg font-semibold text-sm transition-colors flex items-center justify-center gap-2 bg-slate-200 text-slate-400 cursor-not-allowed"}>
                              <Lucide.RotateCcw className="w-4 h-4" />
                              {(ts`Update Rounds Below`)->React.string}
                              <Lucide.ArrowDown className="w-4 h-4" />
                            </button>}
                        <p className="text-xs text-orange-700 text-center mt-2">
                          {(
                            ts`This will delete all future rounds and generate new matches`
                          )->React.string}
                        </p>
                      </div>
                    : React.null}
                </div>
              </div>
            : React.null}
        </div>
      </div>
    </div>
  </div>
}
