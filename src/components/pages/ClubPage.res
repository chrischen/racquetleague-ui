%%raw("import { t } from '@lingui/macro'")

module Query = %relay(`
  query ClubPageQuery(
    $slug: String!
    $after: String
    $first: Int
    $before: String
    $filters: EventFilters!
    $afterDate: Datetime
  ) {
    club(slug: $slug) {
      name
      shareLink
      ...ClubDetails_club
      ...ClubEventsListFragment
        @arguments(
          after: $after
          first: $first
          before: $before
          afterDate: $afterDate
        )
    }
    ...CalendarEventsFragment
      @arguments(
        after: $after
        first: $first
        before: $before
        filters: $filters
        afterDate: $afterDate
      )
  }
  `)
type loaderData = ClubPageQuery_graphql.queryRef
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

@send external select: Dom.element => unit = "select"
module ShareLink = {
  @react.component
  let make = (~link: string) => {
    // Import t macro for translations, consistent with the parent component
    open Lingui.Util

    let inputRef = React.useRef(Js.Nullable.null)

    let handleClickToSelect = (_event: ReactEvent.Mouse.t) => {
      inputRef.current
      ->Js.Nullable.toOption
      ->Option.forEach(inputElement => {
        inputElement->select
      })
    }

    <div className="my-4">
      <label htmlFor="share-club-link" className="block text-sm font-medium text-gray-700">
        {t`Shareable Link`}
      </label>
      <div className="mt-1">
        <input
          ref={inputRef->ReactDOM.Ref.domRef}
          type_="text"
          name="share-club-link"
          id="share-club-link"
          className="block w-full shadow-sm sm:text-sm focus:ring-indigo-500 focus:border-indigo-500 border-gray-300 rounded-md bg-gray-50 cursor-pointer"
          value=link
          readOnly=true
          onClick=handleClickToSelect
        />
      </div>
      <p className="mt-2 text-sm text-gray-500">
        {t`Click the link to select it for easy copying.`}
      </p>
    </div>
  }
}
@react.component
let make = () => {
  open Lingui.Util
  let data = useLoaderData()
  let query = Query.usePreloaded(~queryRef=data.data)
  let {i18n: {locale}} = Lingui.useLingui()
  let (isShareLinkOpen, setIsShareLinkOpen) = React.useState(() => false)

  let toggleShareLink = React.useCallback1(() => {
    setIsShareLinkOpen(prev => !prev)
  }, [setIsShareLinkOpen])

  <WaitForMessages>
    {_ => {
      query.club
      ->Option.map(club => <>
        <ClubEventsList
          events={club.fragmentRefs}
          header={<Layout.Container>
            <h1>
              <div className="text-base leading-6 text-gray-500"> {t`club`} </div>
              <div
                className="flex items-center mt-1 text-2xl font-semibold leading-6 text-gray-900">
                {club.name->Option.getOr("?")->React.string}
                <button className="ml-2" onClick={_ => toggleShareLink()}>
                  <Lucide.Share color="#6B7280" />
                </button>
              </div>
            </h1>
            {isShareLinkOpen
              ? <ShareLink
                  link={"https://www.pkuru.com/" ++ locale ++ club.shareLink->Option.getOr("")}
                />
              : React.null}
            <ClubDetails club={club.fragmentRefs} />
          </Layout.Container>}
        />
        // <EventsList
        //   events={query.fragmentRefs}
        //   header={<Layout.Container>
        //     <h1>
        //       <div className="text-base leading-6 text-gray-500"> {t`club`} </div>
        //       <div className="mt-1 text-2xl font-semibold leading-6 text-gray-900">
        //         {club.name->Option.getOr("?")->React.string}
        //       </div>
        //     </h1>
        //     <ClubDetails club={club.fragmentRefs} />
        //   </Layout.Container>}
        // />
      </>)
      ->Option.getOr(<Layout.Container> {t`club not found`} </Layout.Container>)
    }}
  </WaitForMessages>
}
