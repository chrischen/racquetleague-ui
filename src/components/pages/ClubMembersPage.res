%%raw("import { t } from '@lingui/macro'")

module Query = %relay(`
  query ClubMembersPageQuery(
    $slug: String!
  ) {
    club(slug: $slug) {
      id
      name
      slug
    }
    viewer {
      user {
        id
      }
      adminClubs(first: 100) {
        edges {
          node {
            id
          }
        }
      }
    }
  }
`)

module MembersQuery = %relay(`
  query ClubMembersPageMembersQuery(
    $clubId: ID!
    $after: String
    $first: Int = 20
  ) {
    __id
    clubMembers(input: { clubId: $clubId }, after: $after, first: $first) @connection(key: "ClubMembersPageMembersQuery_clubMembers") {
      __id
      edges {
        node {
          id
          isAdmin
          isOwner
          status
          joinDate
          user {
            id
            fullName
            picture
            lineUsername
          }
        }
      }
      pageInfo {
        hasNextPage
        hasPreviousPage
        startCursor
        endCursor
      }
    }
  }
`)

module RemoveUserFromClubMutation = %relay(`
  mutation ClubMembersPageRemoveUserFromClubMutation(
    $connections: [ID!]!
    $input: RemoveUserFromClubInput!
  ) {
    removeUserFromClub(input: $input) {
      errors {
        message
      }
      membershipIds
        @deleteEdge(connections: $connections)
    }
  }
`)

module UpdateMembershipStatusMutation = %relay(`
  mutation ClubMembersPageUpdateMembershipStatusMutation(
    $input: UpdateMembershipStatusInput!
  ) {
    updateMembershipStatus(input: $input) {
      errors { message }
      membership { id status }
    }
  }
`)

module MemberItem = {
  @react.component
  let make = (
    ~membership: MembersQuery.Types.response_clubMembers_edges_node,
    ~viewerIsAdmin: bool,
    ~onRemove: unit => unit,
    ~onApprove: unit => unit,
  ) => {
    open Lingui.Util
    let ts = Lingui.UtilString.t
    let isAdmin = membership.isAdmin->Option.getOr(false)
    let isOwner = membership.isOwner->Option.getOr(false)

    switch membership.user {
    | Some(member) =>
      <SwipeAction
        className="cursor-pointer border-b border-gray-200"
        rightActions={
          // Only show remove action if viewer is admin and member is not owner
          viewerIsAdmin && !isOwner
            ? <ConfirmButton
                button={<Button.Button color=#red> {t`Remove`} </Button.Button>}
                title={t`Remove member?`}
                description={(
                  ts`Are you sure you want to remove ${member.fullName->Option.getOr(
                    "this member",
                  )} from the club?`
                )->React.string}
                onConfirmed={_ => onRemove()}
              />
            : React.null
        }
        partialThreshold=120
        fullThreshold=260
        hoverPartialSide="right">
        <div className="flex items-center justify-between py-4 px-6">
          <div className="flex items-center space-x-4">
            <img
              className="h-10 w-10 rounded-full"
              src={member.picture->Option.getOr("/default-avatar.png")}
              alt={member.fullName->Option.getOr("Member")}
            />
            <div>
              <h3 className="text-sm font-medium text-gray-900">
                {member.fullName->Option.getOr("Unknown Member")->React.string}
              </h3>
              {switch member.lineUsername {
              | Some(username) =>
                <p className="text-sm text-gray-500"> {`@${username}`->React.string} </p>
              | None => React.null
              }}
            </div>
          </div>
          <div className="flex items-center space-x-2">
            {switch membership.status {
            | Some(Pending) if viewerIsAdmin && !isOwner =>
              <Button.Button color=#indigo onClick={_ => onApprove()}> {t`Approve`} </Button.Button>
            | _ => React.null
            }}
            {isOwner
              ? <span
                  className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-purple-100 text-purple-800">
                  {"Owner"->React.string}
                </span>
              : React.null}
            {isAdmin && !isOwner
              ? <span
                  className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                  {"Admin"->React.string}
                </span>
              : React.null}
          </div>
        </div>
      </SwipeAction>
    | None => React.null
    }
  }
}

module ClubMembersData = {
  @react.component
  let make = (~clubId, ~viewerIsAdmin: bool) => {
    open Lingui.Util
    let data = MembersQuery.use(
      ~variables={
        clubId,
        first: 20,
      },
    )

    let (removeMutation, _isRemoveInFlight) = RemoveUserFromClubMutation.use()
    let (updateStatusMutation, _isUpdateInFlight) = UpdateMembershipStatusMutation.use()

    let handleRemoveUser = (userId: string) => {
      // Get the connection ID for the club members list
      let membersConnectionId = data.clubMembers.__id

      removeMutation(
        ~variables={
          connections: [membersConnectionId],
          input: {
            clubId,
            userId,
          },
        },
        ~onCompleted=({removeUserFromClub}, _errors) => {
          switch removeUserFromClub.errors {
          | None
          | Some([]) => // Success - the member should be automatically removed from the UI via Relay
            ()
          | Some(errors) =>
            // Handle errors - you might want to show a toast notification
            errors->Array.forEach(error => {
              Js.Console.error("Failed to remove user: " ++ error.message)
            })
          }
        },
      )->RescriptRelay.Disposable.ignore
    }

    let handleApproveUser = (membershipId: string) => {
      updateStatusMutation(
        ~variables={
          input: {
            membershipId,
            status: Active,
          },
        },
        ~onCompleted=({updateMembershipStatus}, _errors) => {
          switch updateMembershipStatus.errors {
          | None | Some([]) => ()
          | Some(errors) =>
            errors->Array.forEach(e => Js.Console.error("Failed to approve user: " ++ e.message))
          }
        },
      )->RescriptRelay.Disposable.ignore
    }

    <div className="bg-white shadow overflow-hidden sm:rounded-md">
      <div className="px-4 py-5 sm:p-6">
        <div className="">
          {switch data.clubMembers.edges {
          | None | Some([]) =>
            <div className="py-8 text-center text-gray-500">
              <p className="text-sm"> {t`No members found`} </p>
            </div>
          | Some(edges) => {
              // Flatten memberships
              let memberships =
                edges
                ->Array.filterMap(edge => edge)
                ->Array.filterMap(edge => edge.node)

              // Partition into pending vs others
              let pendingMembers = memberships->Array.filter(m =>
                switch m.status {
                | Some(Pending) => true
                | _ => false
                }
              )
              let otherMembers = memberships->Array.filter(m =>
                switch m.status {
                | Some(Pending) => false
                | _ => true
                }
              )

              let renderMembers = members =>
                members
                ->Array.map(membership => {
                  <MemberItem
                    key={membership.id}
                    membership={membership}
                    viewerIsAdmin={viewerIsAdmin}
                    onRemove={() => {
                      switch membership.user {
                      | Some(user) => handleRemoveUser(user.id)
                      | None => ()
                      }
                    }}
                    onApprove={() => handleApproveUser(membership.id)}
                  />
                })
                ->React.array

              <>
                {pendingMembers->Array.length > 0
                  ? <div className="mb-6">
                      <h4 className="text-sm font-semibold text-gray-700 mb-2"> {t`Pending`} </h4>
                      <div
                        className="divide-y divide-gray-200 rounded-md border border-gray-200 overflow-hidden">
                        {renderMembers(pendingMembers)}
                      </div>
                    </div>
                  : React.null}
                {otherMembers->Array.length > 0
                  ? <div
                      className={pendingMembers->Array.length > 0
                        ? "pt-4 border-t border-gray-200"
                        : ""}>
                      <div
                        className="divide-y divide-gray-200 rounded-md border border-gray-200 overflow-hidden">
                        {renderMembers(otherMembers)}
                      </div>
                    </div>
                  : React.null}
              </>
            }
          }}
        </div>
      </div>
    </div>
  }
}

type loaderData = ClubMembersPageQuery_graphql.queryRef

@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

@react.component
let make = () => {
  open Lingui.Util
  let data = useLoaderData()
  let query = Query.usePreloaded(~queryRef=data.data)

  <WaitForMessages>
    {_ => {
      query.club
      ->Option.map(club => {
        // Check if current club is in viewer's admin clubs
        let viewerIsAdmin =
          query.viewer
          ->Option.flatMap(viewer => viewer.adminClubs.edges)
          ->Option.map(edges =>
            edges
            ->Array.filterMap(edge => edge)
            ->Array.filterMap(edge => edge.node)
            ->Array.some(adminClub => adminClub.id == club.id)
          )
          ->Option.getOr(false)

        <Layout.Container>
          <h1>
            <div className="text-base leading-6 text-gray-500">
              <LangProvider.Router.Link to={"/clubs/" ++ club.slug->Option.getOr("")}>
                {club.name->Option.getOr("?")->React.string}
              </LangProvider.Router.Link>
            </div>
            <div className="mt-1 text-2xl font-semibold leading-6 text-gray-900">
              {t`Members`}
            </div>
          </h1>
          <div className="mt-8">
            <React.Suspense fallback={<div> {"Loading members..."->React.string} </div>}>
              <ClubMembersData clubId={club.id} viewerIsAdmin={viewerIsAdmin} />
            </React.Suspense>
          </div>
        </Layout.Container>
      })
      ->Option.getOr(<Layout.Container> {t`club not found`} </Layout.Container>)
    }}
  </WaitForMessages>
}
