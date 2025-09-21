%%raw("import { t } from '@lingui/macro'")

module Query = %relay(`
  query ClubPageQuery(
    $slug: String!
    $after: String
    $first: Int
    $before: String
    $afterDate: Datetime
    $token: String
  ) {
    club(slug: $slug) {
      id
      slug
      name
      shareLink
      viewerMembership { status }
      ...ClubDetails_club
      ...ClubEventsListFragment
        @arguments(
          after: $after
          first: $first
          before: $before
          afterDate: $afterDate
          token: $token
        )
    }
    viewer {
      user {
        ...EventItem_user
        id
      }
    }
  }
  `)

module JoinClubMutation = %relay(`
  mutation ClubPageJoinClubMutation(
    $connections: [ID!]!
    $input: JoinClubInput!
  ) {
    joinClub(input: $input) {
      errors { message }
      club {
        viewerMembership @appendNode(connections: $connections, edgeTypeName: "MembershipEdge") {
          status
        }
      }
    }
  }
`)

module RemoveUserFromClubMutation = %relay(`
  mutation ClubPageRemoveUserFromClubMutation(
    $input: RemoveUserFromClubInput!
  ) {
    removeUserFromClub(input: $input) {
      errors { message }
      membershipIds
      club {
        viewerMembership {
          status
        }
      }
    }
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
  let (commitJoinClub, isJoinInFlight) = JoinClubMutation.use()
  let (commitRemoveUser, isRemoveInFlight) = RemoveUserFromClubMutation.use()

  let toggleShareLink = React.useCallback1(() => {
    setIsShareLinkOpen(prev => !prev)
  }, [setIsShareLinkOpen])

  <WaitForMessages>
    {_ => {
      query.club
      ->Option.map(club => {
        // Build connection id for club members list (used when joining)
        let membersConnectionId = RescriptRelay.ConnectionHandler.getConnectionID(
          RescriptRelay.makeDataId("client:root"),
          "ClubMembersPageMembersQuery_clubMembers",
          (),
        )

        let handleJoinClub = () => {
          commitJoinClub(
            ~variables={
              connections: [membersConnectionId],
              input: {clubId: club.id},
            },
            ~onCompleted=({joinClub}, _errors) => {
              switch joinClub.errors {
              | None | Some([]) => ()
              | Some(errors) => errors->Array.forEach(e => Js.Console.error(e.message))
              }
            },
          )->RescriptRelay.Disposable.ignore
        }

        let handleCancelRequest = () => {
          // We need the viewer's user ID to remove them from the club
          switch query.viewer->Option.flatMap(v => v.user) {
          | Some(user) =>
            commitRemoveUser(
              ~variables={
                input: {clubId: club.id, userId: user.id},
              },
              ~onCompleted=({removeUserFromClub}, _errors) => {
                switch removeUserFromClub.errors {
                | None | Some([]) => // Successfully removed - the membership should no longer exist
                  // The UI will update on the next render since viewerMembership will be null
                  ()
                | Some(errors) => errors->Array.forEach(e => Js.Console.error(e.message))
                }
              },
            )->RescriptRelay.Disposable.ignore
          | None => ()
          }
        }

        <ClubEventsList
          events={club.fragmentRefs}
          viewer={query.viewer}
          header={<Layout.Container>
            <h1>
              <div className="text-base leading-6 text-gray-500"> {t`club`} </div>
              <div
                className="flex items-center mt-1 text-2xl font-semibold leading-6 text-gray-900">
                <span className="flex items-center">
                  {club.name->Option.getOr("?")->React.string}
                  <button className="ml-2" onClick={_ => toggleShareLink()}>
                    <Lucide.Share color="#6B7280" />
                  </button>
                </span>
              </div>
            </h1>
            {switch query.viewer->Option.flatMap(v => v.user) {
            | Some(_u) => {
                let status =
                  query.club
                  ->Option.flatMap(c => c.viewerMembership)
                  ->Option.flatMap(m => m.status)

                switch status {
                | Some(Active) => React.null
                | Some(Pending) =>
                  <div className="mt-3">
                    <Button.Button
                      color=#red disabled={isRemoveInFlight} onClick={_ => handleCancelRequest()}>
                      {t`Cancel Request`}
                    </Button.Button>
                  </div>
                | Some(Rejected) | Some(FutureAddedValue(_)) | None =>
                  <div className="mt-3">
                    <Button.Button
                      color=#indigo disabled={isJoinInFlight} onClick={_ => handleJoinClub()}>
                      {t`Request to join`}
                    </Button.Button>
                  </div>
                }
              }
            | None => React.null
            }}
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
      })
      ->Option.getOr(<Layout.Container> {t`club not found`} </Layout.Container>)
    }}
  </WaitForMessages>
}
