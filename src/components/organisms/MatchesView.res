%%raw("import { t, plural } from '@lingui/macro'")
open Lingui.Util

module PlayerView = {
  @react.component
  let make = (
    ~player: Rating.Player.t<Rating.rsvpNode>,
    ~minRating,
    ~maxRating,
    ~status,
    ~sessionState: option<Session.t>=?,
  ) => {
    let playCount = sessionState->Option.map(session => (session->Session.get(player.id)).count)

    // <div className="rounded-lg bg-white shadow p-8">
    switch player.data {
    | Some(data) =>
      data.user
      ->Option.map(user => {
        <EventMatchRsvpUser
          key={user.id}
          highlight={status}
          user={user.fragmentRefs}
          ratingPercent={(player.rating.mu -. minRating) /. (maxRating -. minRating) *. 100.}
          player
          ?playCount
        />
      })
      ->Option.getOr(React.null)
    | None =>
      <MatchRsvpUser
        key={player.id}
        highlight={status}
        user={Rating.makeGuest(player.name)}
        ratingPercent={(player.rating.mu -. minRating) /. (maxRating -. minRating) *. 100.}
        player
        ?playCount
      />
    }
  }
  // </div>
}

module Queue = {
  @react.component
  let make = (
    ~players: array<Rating.player<Rating.rsvpNode>>,
    ~breakPlayers: Set.t<string>,
    ~consumedPlayers: Set.t<string>,
    ~queue: Set.t<string>,
    ~togglePlayer: Rating.player<Rating.rsvpNode> => unit,
    ~onToggleSelectedPlayer: Rating.player<Rating.rsvpNode> => unit,
    ~selectedPlayers: Set.t<string>,
    ~onGoToCheckin: unit => unit,
    ~sessionState: Session.t,
  ) => {
    // let maxRating =
    //   players->Array.reduce(0., (acc, next) => next.rating.mu > acc ? next.rating.mu : acc)
    // let minRating =
    //   players->Array.reduce(maxRating, (acc, next) => next.rating.mu < acc ? next.rating.mu : acc)
    let handleLongPress = React.useCallback(
      (
        event: ReactEvent.Synthetic.t,
        context: option<UseLongPress.meta<Rating.player<Rating.rsvpNode>>>,
      ) => {
        context
        ->Option.flatMap(ctx =>
          ctx.context->Option.map(
            ctx => {
              onToggleSelectedPlayer(ctx)
            },
          )
        )
        ->ignore
        ()
      },
      [selectedPlayers->Set.size],
    )

    let options: UseLongPress.options<Rating.player<Rating.rsvpNode>> = {
      // onStart: handleLongPress,
      threshold: 300,
      cancelOnMovement: true, // or Js.Any.fromInt(25) for pixel threshold
      captureEvent: true,
      // detect: #both,
    }
    let bind = UseLongPress.use(Some(handleLongPress), Some(options))
    let maxRating = 1.0
    let minRating = 0.0

    <div className={Util.cx(["grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-3"])}>
      {players
      ->Array.map(player => {
        let h = bind(Some(player))
        let status = switch (
          queue->Set.has(player.id),
          breakPlayers->Set.has(player.id),
          consumedPlayers->Set.has(player.id),
        ) {
        | (true, _, _) => MatchRsvpUser.Queued
        | (_, _, true) => MatchRsvpUser.Playing
        | (_, true, _) => MatchRsvpUser.Break
        | _ => Available
        }
        <FramerMotion.Div
          key=player.id
          // className={Util.cx([
          //   selectedPlayers->Set.has(player.id) ? "animate-bounce delay-150 duration-300" : "",
          // ])}
          onMouseDown={h.onMouseDown}
          onMouseUp={h.onMouseUp}
          onPointerUp={h.onPointerUp}
          onPointerMove={h.onPointerMove}
          onPointerLeave={h.onPointerLeave}
          onPointerDown={h.onPointerDown}
          onTouchStart={h.onTouchStart}
          onTouchEnd={h.onTouchEnd}
          onTouchMove={h.onTouchMove}
          style={ShakeAnimate.getRandomTransformOrigin()}
          variants={ShakeAnimate.variants}
          animate={selectedPlayers->Set.has(player.id)
            ? ShakeAnimate.variants["start"]
            : ShakeAnimate.variants["reset"]}>
          <UiAction
            onClick={e => {
              togglePlayer(player)
            }}>
            <PlayerView status={status} key={player.id} player minRating maxRating sessionState />
          </UiAction>
        </FramerMotion.Div>
      })
      ->React.array}
      <UiAction onClick={_ => onGoToCheckin()}>
        <div
          className="flex flex-col items-center justify-center p-4 rounded-lg shadow-md bg-white hover:bg-gray-50 border border-gray-200 cursor-pointer text-gray-700 h-full focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2">
          <HeroIcons.UserPlusOutline className="h-8 w-8 text-indigo-600 mb-2" />
          <span className="text-sm font-semibold text-center"> {t`Add/Remove Players`} </span>
        </div>
      </UiAction>
    </div>
  }
}

module ActionBar = {
  @react.component
  let make = (~children: React.element) => {
    <div
      className="fixed bottom-0 bg-white w-full flex h-[64px] -ml-3 p-3 justify-between items-center">
      {children}
    </div>
  }
}
module CheckinActionBar = {
  @react.component
  let make = (~mainActionText: string, ~onMainAction, ~disabled: bool=false) => {
    <>
      <UiAction
        onClick={e => disabled ? () : onMainAction(e)}
        className="w-full h-[64px] bg-indigo-600 text-lg font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 flex items-center justify-center">
        {mainActionText->React.string}
      </UiAction>
    </>
  }
}
module MatchesActionBar = {
  @react.component
  let make = (
    ~selectAll: unit => unit,
    ~selectedAll: bool,
    ~mainActionText: string,
    ~onMainAction,
    ~hasMatches: bool,
    ~disabled: bool=false,
  ) => {
    <>
      <div /> // Empty div to push button to the right
      {!hasMatches
        ? <UiAction
            onClick={_ => selectAll()}
            className="bg-indigo-600 px-3.5 py-2.5 text-lg font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 rounded-md inline-flex items-center">
            <HeroIcons.Users \"aria-hidden"="true" className="h-5 w-5 mr-2" />
            {selectedAll ? t`Unqueue All` : t`Queue All`}
          </UiAction>
        : <UiAction
            onClick={e => disabled ? () : onMainAction(e)}
            className="bg-indigo-600 px-3.5 py-2.5 text-lg font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 rounded-md">
            {mainActionText->React.string}
          </UiAction>}
    </>
  }
}
module QueueActionBar = {
  @react.component
  let make = (
    ~selectAll: unit => unit,
    ~selectedAll: bool,
    ~breakCount: int,
    ~mainActionText: string,
    ~onChangeBreakCount: int => unit,
    ~onMainAction,
    ~onSelectedPlayersAction,
    ~selectedPlayersCount: int,
    ~onClearSelectedPlayers: unit => unit,
    ~disabled: bool=false,
  ) => {
    let ts = Lingui.UtilString.t
    let selectedPlayersText = Lingui.Util.plural(
      selectedPlayersCount,
      {
        one: ts`${selectedPlayersCount->Int.toString} player selected`,
        other: ts`${selectedPlayersCount->Int.toString} players selected`,
      },
    )
    <>
      <div className="flex items-center">
        <div className={Util.cx(["hidden sm:block", "mr-4"])}>
          <UiAction
            onClick={_ => onChangeBreakCount(breakCount - 1)}
            className="rounded-md bg-white px-2.5 py-1.5 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50">
            {"-"->React.string}
          </UiAction>
          {(" " ++ breakCount->Int.toString ++ " ")->React.string}
          <UiAction
            onClick={_ => onChangeBreakCount(breakCount + 1)}
            className="rounded-md bg-white px-2.5 py-1.5 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50">
            {"+"->React.string}
          </UiAction>
          {" "->React.string}
          {t`# of courts`}
        </div>
        {selectedPlayersCount > 0
          ? <UiAction
              onClick={_ => onClearSelectedPlayers()}
              className="mr-2 p-1 rounded-full hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-indigo-500"
              // ariaLabel={ts`Clear selection`}
            >
              <HeroIcons.XMarkIcon className="h-5 w-5 text-gray-600" />
            </UiAction>
          : React.null}
        {selectedPlayersCount > 0
          ? <div className="mr-2 text-sm font-semibold text-gray-700">
              <UiAction onClick={onSelectedPlayersAction}> {selectedPlayersText} </UiAction>
            </div>
          : React.null}
      </div>
      {selectedPlayersCount < 4
        ? <UiAction
            onClick={_ => selectAll()}
            className="bg-indigo-600 px-3.5 py-2.5 text-lg font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 rounded-md inline-flex items-center">
            <HeroIcons.Users \"aria-hidden"="true" className="h-5 w-5 mr-2" />
            {selectedAll ? t`Unqueue All` : t`Queue All`}
          </UiAction>
        : <UiAction
            onClick={e => disabled ? () : onMainAction(e)}
            className="bg-indigo-600 px-3.5 py-2.5 text-lg font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 rounded-md">
            {mainActionText->React.string}
          </UiAction>}
    </>
  }
}
type view = Checkin | Matches | Queue
@react.component
let make = (
  ~view: view,
  ~setView: (view => view) => unit,
  ~players: array<Rating.player<Rating.rsvpNode>>,
  ~availablePlayers: array<Rating.player<Rating.rsvpNode>>,
  ~playersCache: Rating.PlayersCache.t<Rating.rsvpNode>,
  ~checkin: React.element,
  ~queue: Set.t<string>,
  ~breakPlayers: Set.t<string>,
  ~consumedPlayers: Set.t<string>,
  ~togglePlayer: Rating.player<Rating.rsvpNode> => unit,
  ~setQueue: array<string> => unit,
  ~setRequiredPlayers: (option<Set.t<string>> => option<Set.t<string>>) => unit,
  ~matches: array<Rating.matchEntity<Rating.rsvpNode>>,
  ~setMatches: (
    array<Rating.matchEntity<Rating.rsvpNode>> => array<Rating.matchEntity<Rating.rsvpNode>>
  ) => unit,
  // ~activity,
  ~minRating,
  ~maxRating,
  ~handleMatchCanceled,
  ~handleMatchUpdated,
  ~handleMatchesComplete,
  ~onClose,
  ~selectAll: unit => unit,
  ~breakCount: int,
  ~onChangeBreakCount: int => unit,
  ~matchSelector: React.element,
  ~selectedPlayersActions: array<Rating.player<Rating.rsvpNode>> => React.element,
  ~sessionState: Session.t,
) => {
  let ts = Lingui.UtilString.t
  // let (view, setView) = React.useState(() => Matches)
  let (showMatchSelector, setShowMatchSelector) = React.useState(() => false)
  let (submitDisabled, setSubmitDisabled) = React.useState(() => false)
  let (showSelectedActions, setShowSelectedActions) = React.useState(() => false)
  let (selectedPlayers, setSelectedPlayers) = React.useState(() => Set.make())
  // let selectedPlayers = React.useRef(Set.make())

  <div id="FairPlay" className="w-full h-full fixed top-0 left-0 bg-black p-3">
    <div className="flex h-[34px] justify-between items-center">
      <UiAction
        className="inline-flex items-center gap-x-2 rounded-md bg-indigo-600 px-3.5 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
        onClick=onClose>
        <HeroIcons.Cog6Tooth className="-ml-0.5 h-5 w-5" />
      </UiAction>
      <UiAction
        className={Util.cx([
          "ml-3 inline-flex flex-grow items-center gap-x-2 rounded-md px-3.5 py-2.5 text-sm font-semibold text-white shadow-sm focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600",
          view == Queue
            ? "bg-indigo-600 border-solid border-white border-2"
            : "bg-black border-solid border-indigo-600 border-2",
        ])}
        onClick={_ => setView(_ => Queue)}>
        <HeroIcons.Users \"aria-hidden"="true" className="-ml-0.5 h-5 w-5" />
        {t`Queue`}
      </UiAction>
      <UiAction
        className={Util.cx([
          "ml-3 inline-flex flex-grow items-center gap-x-2 rounded-md px-3.5 py-2.5 text-sm font-semibold text-white shadow-sm focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600",
          view == Matches
            ? "bg-indigo-600 border-solid border-white border-2"
            : "bg-black border-solid border-indigo-600 border-2",
        ])}
        onClick={_ => setView(_ => Matches)}>
        <HeroIcons.TableCells \"aria-hidden"="true" className="-ml-0.5 h-5 w-5" />
        {t`Matches`}
      </UiAction>
      <input
        className="w-10"
        onClick={e => e->JsxEventU.Mouse.target->Form.Input.select}
        readOnly=true
        value={matches
        ->Array.mapWithIndex(({match: (team1, team2)}, i) => {
          let team1 =
            team1
            ->Array.map(p => p.name)
            ->Array.join(" " ++ ts([`and`], []) ++ " ")
          let team2 =
            team2
            ->Array.map(p => p.name)
            ->Array.join(" " ++ ts([`and`], []) ++ " ")

          ts`Court ${(i + 1)->Int.toString}: ${team1} versus ${team2}`
        })
        ->Array.join(", ")}
      />
    </div>
    <div
      className="w-full h-[calc(100vh-(56px+152px))] sm:h-[calc(100vh-(56px+92px))] fixed top-[56px] left-0 overflow-scroll px-3">
      <main role="main" className="w-full h-full">
        {switch view {
        | Checkin => checkin
        | Queue =>
          <Queue
            players
            breakPlayers
            consumedPlayers
            queue
            // onToggleSelectedPlayer={player => {
            //   setSelectedPlayers(selectedPlayers => {
            //     let newSet = Set.fromArray(selectedPlayers->Set.values->Array.fromIterator)
            //     selectedPlayers->Set.has(player.id)
            //       ? newSet->Set.delete(player.id)->ignore
            //       : newSet->Set.add(player.id)->ignore
            //     newSet
            //   })
            // }}
            onToggleSelectedPlayer={player => {
              ()
              // switch consumedPlayers->Set.has(player.id) {
              // | true => setView(_ => Matches)
              // | false => togglePlayer(player)
              // }
            }}
            selectedPlayers
            togglePlayer={player => {
              switch consumedPlayers->Set.has(player.id) {
              | true => setView(_ => Matches)
              | false => togglePlayer(player)
              }
            }}
            onGoToCheckin={() => setView(_ => Checkin)}
            sessionState
          />
        | Matches =>
          <DndKit.DndContext onDragEnd={_ => ()}>
            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-3">
              <MultipleContainers
                minimal=true
                renderContainer={(children, matchId) => {
                  // let team1 = children->Array.get(0)->Option.getOr(React.null)
                  // let team2 = children->Array.get(1)->Option.getOr(React.null)
                  let matchEntity = matches->Array.get(matchId)

                  {
                    matchEntity
                    ->Option.map(({match}) =>
                      <SortableSubmitMatch
                        key={match->Rating.Match.toStableId}
                        match
                        minRating
                        maxRating
                        onDelete={() => handleMatchCanceled(matchId->Int.toString)}
                        onUpdated={match => match->handleMatchUpdated(matchId->Int.toString)}>
                        {children}
                      </SortableSubmitMatch>
                    )
                    ->Option.getOr(React.null)
                  }
                }}
                items={matches->Array.map(m => m.match)->Rating.Matches.toDndItems}
                setItems={updateFn => {
                  setMatches(matches => {
                    let matchesOnly = matches->Array.map(m => m.match)
                    let items = matchesOnly->Rating.Matches.toDndItems
                    let updatedMatches = updateFn(items)->Rating.Matches.fromDndItems(playersCache)
                    // Preserve IDs when updating
                    matches->Array.mapWithIndex((matchEntity, i) => {
                      let newMatch = updatedMatches->Array.getUnsafe(i)
                      {Rating.id: matchEntity.id, match: newMatch}
                    })
                  })
                }}
                deleteContainer={i => handleMatchCanceled(i)}
                renderValue={value => {
                  let value = switch value->String.split(":") {
                  | [ids, id] =>
                    switch ids->String.split(".") {
                    | [matchId, _] => Some((matchId, id))
                    | _ => None
                    }
                  | _ => None
                  }
                  let player = value->Option.flatMap(((matchId, value)) =>
                    playersCache
                    ->Rating.PlayersCache.get(value)
                    ->Option.flatMap(player =>
                      matchId->Int.fromString->Option.map(matchId => (matchId, player))
                    )
                  )
                  player
                  ->Option.map(((matchId, player)) =>
                    <UiAction
                      onClick={_ => {
                        let matchEntity = matches->Array.get(matchId)
                        matchEntity
                        ->Option.map(({match}) => {
                          let matchPlayers =
                            match
                            ->Rating.Match.players
                            ->Array.map(player => player.id)
                            ->Array.filter(p => p != player.id)
                          let replacements =
                            players
                            ->Array.map(player => player.id)
                            ->Set.fromArray
                            ->Util.JsSet.difference(consumedPlayers)
                          let newQueue =
                            matchPlayers->Array.concat(replacements->Set.values->Array.fromIterator)
                          setRequiredPlayers(
                            _ => {
                              Some(matchPlayers->Set.fromArray)
                            },
                          )
                          setQueue(newQueue)
                        })
                        ->ignore

                        setShowMatchSelector(_ => true)
                      }}>
                      <SubmitMatch.PlayerView player minRating maxRating />
                    </UiAction>
                  )
                  ->Option.getOr(React.null)
                }}
              />
            </div>
          </DndKit.DndContext>
        }}
      </main>
    </div>
    {switch view {
    | Matches =>
      // Render MatchesActionBar when view is Matches
      <ActionBar>
        <MatchesActionBar
          disabled={submitDisabled}
          selectedAll={queue->Set.size == availablePlayers->Array.length}
          selectAll={_ => {
            setView(_ => Queue)
            selectAll()
          }}
          mainActionText={ts`SUBMIT RESULTS`}
          hasMatches={matches->Array.length > 0}
          onMainAction={_ => {
            // Call handleMatchesComplete and potentially switch view
            setSubmitDisabled(_ => true)
            handleMatchesComplete()
            ->Promise.then(_ => {
              // Optional: Switch view after successful completion?
              // setView(_ => Queue) // Example: Go back to Queue
              setSubmitDisabled(_ => false)
              Promise.resolve()
            })
            ->Promise.catch(err => {
              Js.log2("Error submitting matches:", err)
              // Handle error display if needed
              setSubmitDisabled(_ => false)
              Promise.resolve()
            })
            ->ignore
          }}
        />
      </ActionBar>
    | Queue =>
      <ActionBar>
        <QueueActionBar
          selectedAll={queue->Set.size == availablePlayers->Array.length}
          selectAll={_ => {
            setView(_ => Queue)
            selectAll()
          }}
          breakCount
          onChangeBreakCount
          mainActionText={ts`CHOOSE MATCH`}
          onMainAction={_ => setShowMatchSelector(s => !s)}
          selectedPlayersCount={queue->Set.size}
          onSelectedPlayersAction={_ => {
            setShowSelectedActions(s => !s)
          }}
          onClearSelectedPlayers={_ => {
            // setSelectedPlayers(_ => Set.make())
            setQueue([])
          }}
        />
      </ActionBar>
    | Checkin =>
      <ActionBar>
        <CheckinActionBar
          mainActionText={ts`START SESSION`} onMainAction={_ => setView(_ => Queue)}
        />
      </ActionBar>
    }}
    <ModalDrawer
      title={ts`Choose Match`}
      open_=showMatchSelector
      setOpen={v => {
        // Switch to Matches view after closing match selector
        setRequiredPlayers(_ => {
          None
        })
        setShowMatchSelector(v)
      }}>
      {matchSelector}
    </ModalDrawer>
    <ModalDrawer
      title={ts`Actions`}
      open_=showSelectedActions
      setOpen={v => {
        setShowSelectedActions(v)
      }}>
      // {selectedPlayersActions(players->Array.filter(p => selectedPlayers->Set.has(p.id)))}
      {selectedPlayersActions(players->Array.filter(p => queue->Set.has(p.id)))}
    </ModalDrawer>
  </div>
}
