%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t, plural } from '@lingui/macro'")
open Lingui.Util

module Fragment = %relay(`
  fragment EventFullNames_event on Event
  @argumentDefinitions (
    after: { type: "String" }
    before: { type: "String" }
    first: { type: "Int", defaultValue: 80 }
  )
  @refetchable(queryName: "EventFullNamesRefetchQuery")
  {
    __id
    rsvps(after: $after, first: $first, before: $before)
    @connection(key: "EventFullNames_event_rsvps")
    {
      edges {
        node {
          ...EventRsvp_rsvp
          user {
            id
            fullName
          }
        }
      }
      pageInfo {
        hasNextPage
        hasPreviousPage
        endCursor
      }
		}
  }
`)

//@genType
//let default = make
@react.component
let make = (~event) => {
  let {data} = Fragment.usePagination(event)
  let {__id} = Fragment.use(event)
  let rsvps = data.rsvps->Fragment.getConnectionNodes
  let (expanded, setExpanded) = React.useState(() => false)

  <div className="rounded-lg bg-gray-50 shadow-sm ring-1 ring-gray-900/5 flex flex-col">
    <dl className="flex flex-wrap">
      <div className="flex-auto pl-6 pt-3">
        <dt className="text-sm font-semibold leading-6 text-gray-900"> {t`guest list`} </dt>
      </div>
    </dl>
    <dl className={Util.cx([expanded ? "" : "hidden", "flex flex-wrap"])}>
      <div className="mt-4 w-full flex flex-col gap-x-4 border-t border-gray-900/5 px-6 pt-4">
        {<>
          <ul className="">
            {switch rsvps {
            | [] => t`no players yet`
            | rsvps =>
              rsvps
              ->Array.filterMap(edge => edge.user->Option.flatMap(user => user.fullName))
              ->Array.map(fullName => {
                <li> {fullName->React.string} </li>
              })
              ->React.array
            }}
          </ul>
        </>}
      </div>
    </dl>
    <UiAction
      className="p-3 w-full flex flex-col items-center hover:bg-gray-100"
      onClick={_ => setExpanded(expanded => !expanded)}>
      {expanded ? React.null : <HeroIcons.Users className="inline w-5 h-5" />}
      {expanded
        ? <HeroIcons.ChevronUpIcon className="inline w-5 h-5" />
        : <HeroIcons.ChevronDownIcon className="inline w-5 h-5" />}
    </UiAction>
  </div>
}
