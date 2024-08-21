%%raw("import { t, plural } from '@lingui/macro'")
open Rating
open Lingui.Util
type sort = Rating | MatchCount
@react.component
let make = (
  ~players: array<Player.t<rsvpNode>>,
  ~selected: Set.t<string>,
  ~playing: Set.t<string>,
  ~disabled: Set.t<string>,
  ~session: Session.t,
  ~onClick: Player.t<'a> => unit,
  ~onRemove: Player.t<'a> => unit,
  ~onEnable: Player.t<'a> => unit,
) => {
  let (sort, setSort) = React.useState(() => Rating)

  let players = switch sort {
  | MatchCount => players->Players.sortByPlayCountAsc(session)
  | Rating => players->Players.sortByOrdinalDesc
  }
  <FramerMotion.Div className="bg-gray-100">
    <table className="mt-6 w-full whitespace-nowrap text-left">
      <colgroup>
        <col className="w-full sm:w-4/12" />
        <col className="lg:w-4/12" />
        <col className="lg:w-2/12" />
        <col className="lg:w-1/12" />
        <col className="lg:w-1/12" />
        <col className="lg:w-1/12" />
      </colgroup>
      <thead className="border-b border-black/10 text-sm leading-6 text-black">
        <tr>
          <th scope="col" className="py-2 pl-4 pr-8 font-semibold sm:pl-6 lg:pl-8">
            <UiAction className="group inline-flex" onClick={_ => setSort(_ => Rating)}>
              {t`Player`}
              {sort == Rating
                ? <span
                    className="ml-2 flex-none rounded bg-gray-100 text-gray-900 group-hover:bg-gray-200">
                    <HeroIcons.ChevronDownIcon className="w-5 h-5" />
                  </span>
                : React.null}
            </UiAction>
          </th>
          <th
            scope="col"
            className="py-2 pl-0 pr-4 text-right font-semibold table-cell sm:pr-6 lg:pr-8"
          />
          <th
            scope="col"
            className="py-2 pl-0 pr-4 text-right font-semibold table-cell sm:pr-6 lg:pr-8">
            <UiAction className="group inline-flex" onClick={_ => setSort(_ => MatchCount)}>
              {t`Match Count`}
              {sort == MatchCount
                ? <span
                    className="ml-2 flex-none rounded bg-gray-100 text-gray-900 group-hover:bg-gray-200">
                    <HeroIcons.ChevronUpIcon className="w-5 h-5" />
                  </span>
                : React.null}
            </UiAction>
          </th>
        </tr>
      </thead>
      <tbody className="divide-y divide-black/5">
        {switch players {
        | [] => t`no players yet`
        | players =>
          players
          ->Array.map(player => {
            let selected = selected->Set.has(player.id)
            let disabled = disabled->Set.has(player.id)
            <FramerMotion.Tr
              layout=true
              // className="mt-2 relative flex justify-between"
              style={originX: 0.05, originY: 0.05}
              key={player.id}
              initial={opacity: 0., scale: 1.15}
              animate={opacity: 1., scale: 1.}
              exit={opacity: 0., scale: 1.15}>
              <td className="py-2 pl-0 pr-8">
                <div className="flex items-center gap-x-4">
                  <div
                    className={Util.cx([
                      "text-sm w-full font-medium leading-6 text-gray-900",
                      !selected ? "opacity-50" : "",
                      disabled ? "line-through" : "",
                    ])}>
                    <UiAction onClick={_ => onClick(player)}>
                      {player.data
                      ->Option.flatMap(data =>
                        data.user->Option.map(
                          user => {
                            <EventRsvpUser user={user.fragmentRefs} />
                          },
                        )
                      )
                      ->Option.getOr(<>
                        {<RsvpUser user={name: player.name, picture: None} />}
                      </>)}
                    </UiAction>
                  </div>
                </div>
              </td>
              <td>
                {!selected
                  ? disabled
                      ? <UiAction onClick={_ => onEnable(player)}>
                          {"Enable"->React.string}
                        </UiAction>
                      : <UiAction onClick={_ => onRemove(player)}>
                          {"Remove"->React.string}
                        </UiAction>
                  : React.null}
              </td>
              <td
                className="py-2 pl-0 pr-4 text-right text-sm leading-6 text-gray-400 table-cell sm:pr-6 lg:pr-8">
                <div className="flex items-center justify-end gap-x-2">
                  <div
                    className={Util.cx([
                      playing->Set.has(player.id) ? "text-green-400 bg-green-400/10" : "hidden",
                      "flex-none rounded-full p-1",
                    ])}>
                    <div className="h-1.5 w-1.5 rounded-full bg-current" />
                  </div>
                  {Session.get(session, player.id).count->Int.toString->React.string}
                </div>
              </td>
            </FramerMotion.Tr>
          })
          ->React.array
        }}
      </tbody>
    </table>
  </FramerMotion.Div>
}
