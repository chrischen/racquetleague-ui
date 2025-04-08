%%raw("import { t, plural } from '@lingui/macro'")
open Lingui.Util

module PlayerView = {
  @react.component
  let make = (~player: Rating.player, ~minRating, ~maxRating, ~status) => {
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
        />
      })
      ->Option.getOr(React.null)
    | None =>
      <MatchRsvpUser
        key={player.id}
        highlight={status}
        user={Rating.makeGuest(player.name)}
        ratingPercent={(player.rating.mu -. minRating) /. (maxRating -. minRating) *. 100.}
      />
    }
  }
  // </div>
}

module Queue = {
  @react.component
  let make = (
    ~players: array<Rating.player>,
    ~breakPlayers: Set.t<string>,
    ~consumedPlayers: Set.t<string>,
    ~queue: Set.t<string>,
    ~togglePlayer: Rating.player => unit,
  ) => {
    // let maxRating =
    //   players->Array.reduce(0., (acc, next) => next.rating.mu > acc ? next.rating.mu : acc)
    // let minRating =
    //   players->Array.reduce(maxRating, (acc, next) => next.rating.mu < acc ? next.rating.mu : acc)
    let maxRating = 1.0
    let minRating = 0.0
    <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-3">
      {players
      ->Array.map(player => {
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
        <UiAction
          key=player.id
          onClick={_ => {
            togglePlayer(player)
          }}>
          <PlayerView status={status} key={player.id} player minRating maxRating />
        </UiAction>
      })
      ->React.array}
    </div>
  }
}

module ActionBar = {
  @react.component
  let make = (
    ~selectAll: unit => unit,
    ~selectedAll: bool,
    ~breakCount: int,
    ~onChangeBreakCount: int => unit,
    ~onChooseMatch,
  ) => {
    <div
      className="fixed bottom-0 bg-white w-full flex h-[64px] -ml-3 p-3 justify-between items-center">
      <div>
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
      <div className="-my-3 py-3 align-middle items-center inline-flex">
        <UiAction
          onClick={_ => selectAll()}
          className={Util.cx([
            "inline-flex rounded-md px-2.5 py-1.5 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300",
            selectedAll ? "bg-green-300" : "",
          ])}>
          <HeroIcons.Users \"aria-hidden"="true" className="-ml-0.5 h-5 w-5 mr-0.5" />
          {selectedAll ? t`Deselect All` : t`Select All`}
        </UiAction>
        <UiAction
          onClick={onChooseMatch}
          className="inline-block h-100vh align-top py-5 -mr-3 ml-3 bg-indigo-600 px-3.5 text-lg font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600">
          {">>>>>>>>>>> "->React.string}
          {t`CHOOSE MATCH`}
        </UiAction>
      </div>
    </div>
  }
}
type view = Checkin | Matches | Queue
@react.component
let make = (
  ~players: array<Rating.player>,
  ~availablePlayers: array<Rating.player>,
  ~playersCache: Rating.PlayersCache.t,
  ~checkin: React.element,
  ~queue: Set.t<string>,
  ~breakPlayers: Set.t<string>,
  ~consumedPlayers: Set.t<string>,
  ~togglePlayer: Rating.player => unit,
  ~matches: array<Rating.match>,
  ~setMatches: (array<Rating.match> => array<Rating.match>) => unit,
  // ~activity,
  ~minRating,
  ~maxRating,
  ~handleMatchCanceled,
  ~handleMatchComplete,
  ~onClose,
  ~selectAll: unit => unit,
  ~breakCount: int,
  ~onChangeBreakCount: int => unit,
  ~matchSelector: React.element,
) => {
  let ts = Lingui.UtilString.t
  let (view, setView) = React.useState(() => Matches)
  let (showMatchSelector, setShowMatchSelector) = React.useState(() => false)

  <div className="w-full h-full fixed top-0 left-0 bg-black p-3">
    <div className="flex h-[34px] justify-between items-center">
      <UiAction
        className="inline-flex items-center gap-x-2 rounded-md bg-indigo-600 px-3.5 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
        onClick=onClose>
        <HeroIcons.Cog6Tooth className="-ml-0.5 h-5 w-5" />
      </UiAction>
      <UiAction
        className={Util.cx([
          "ml-3 inline-flex items-center gap-x-2 rounded-md bg-indigo-600 px-3.5 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600",
          view == Checkin
            ? "bg-black border-solid border-white border-2"
            : "bg-indigo-600 hover:bg-indigo-500",
        ])}
        onClick={_ => setView(_ => Checkin)}>
        <HeroIcons.Users \"aria-hidden"="true" className="-ml-0.5 h-5 w-5" />
        {t`Checkin`}
      </UiAction>
      <UiAction
        className={Util.cx([
          "ml-3 inline-flex flex-grow items-center gap-x-2 rounded-md px-3.5 py-2.5 text-sm font-semibold text-white shadow-sm focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600",
          view == Queue
            ? "bg-black border-solid border-white border-2"
            : "bg-indigo-600 hover:bg-indigo-500",
        ])}
        onClick={_ => setView(_ => Queue)}>
        <HeroIcons.Users \"aria-hidden"="true" className="-ml-0.5 h-5 w-5" />
        {t`Queue`}
      </UiAction>
      <UiAction
        className={Util.cx([
          "ml-3 inline-flex flex-grow items-center gap-x-2 rounded-md px-3.5 py-2.5 text-sm font-semibold text-white shadow-sm focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600",
          view == Matches
            ? "bg-black border-solid border-white border-2"
            : "bg-indigo-600 hover:bg-indigo-500",
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
        ->Array.mapWithIndex(((team1, team2), i) => {
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
            togglePlayer={player => {
              switch consumedPlayers->Set.has(player.id) {
              | true => setView(_ => Matches)
              | false => togglePlayer(player)
              }
            }}
          />
        | Matches =>
          <DndKit.DndContext onDragEnd={_ => ()}>
            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-3">
              <MultipleContainers
                minimal=true
                renderContainer={(children, matchId) => {
                  // let team1 = children->Array.get(0)->Option.getOr(React.null)
                  // let team2 = children->Array.get(1)->Option.getOr(React.null)
                  let match = matches->Array.get(matchId)

                  {
                    match
                    ->Option.map(match =>
                      <SortableSubmitMatch
                        key={matchId->Int.toString}
                        match
                        minRating
                        maxRating
                        onDelete={() => handleMatchCanceled(matchId)}
                        onComplete={match => match->handleMatchComplete(matchId)}>
                        {children}
                      </SortableSubmitMatch>
                    )
                    ->Option.getOr(React.null)
                  }
                }}
                items={matches->Rating.Matches.toDndItems}
                setItems={updateFn => {
                  setMatches(matches => {
                    let items = matches->Rating.Matches.toDndItems
                    updateFn(items)->Rating.Matches.fromDndItems(playersCache)
                  })
                }}
                deleteContainer={i =>
                  i->Int.fromString->Option.map(i => handleMatchCanceled(i))->Option.getOr()}
                renderValue={value => {
                  let value = switch value->String.split(":") {
                  | [_, id] => Some(id)
                  | _ => None
                  }
                  let player =
                    value->Option.flatMap(value => playersCache->Rating.PlayersCache.get(value))
                  player
                  ->Option.map(player => <SubmitMatch.PlayerView player minRating maxRating />)
                  ->Option.getOr(React.null)
                }}
              />
            </div>
          </DndKit.DndContext>
        }}
      </main>
    </div>
    <ActionBar
      selectedAll={queue->Set.size == availablePlayers->Array.length}
      selectAll={_ => {
        setView(_ => Queue)
        selectAll()
      }}
      breakCount
      onChangeBreakCount
      onChooseMatch={_ => setShowMatchSelector(s => !s)}
    />
    <ModalDrawer
      title={ts`Choose Match`}
      open_=showMatchSelector
      setOpen={v => {
        // Switch to Matches view after closing match selector
        setView(_ => Matches)
        setShowMatchSelector(v)
      }}>
      {matchSelector}
    </ModalDrawer>
  </div>
}
