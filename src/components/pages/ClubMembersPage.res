%%raw("import { t } from '@lingui/macro'")

module Query = %relay(`
  query ClubMembersPageQuery(
    $slug: String!
  ) {
    club(slug: $slug) {
      id
      name
      slug
      viewerMembership {
        isOwner
      }
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

module SetMembershipAdminMutation = %relay(`
  mutation ClubMembersPageSetMembershipAdminMutation(
    $input: SetMembershipAdminInput!
  ) {
    setMembershipAdmin(input: $input) {
      errors { message }
      membership { id isAdmin }
    }
  }
`)

module MemberItem = {
  @react.component
  let make = (
    ~membership: MembersQuery.Types.response_clubMembers_edges_node,
    ~viewerIsAdmin: bool,
    ~viewerIsOwner: bool,
    ~onRemove: unit => unit,
    ~onApprove: unit => unit,
    ~onSetAdmin: bool => unit,
    ~isSettingAdmin: bool,
  ) => {
    let t = Lingui.Util.t
    let ts = Lingui.UtilString.t
    let isAdmin = membership.isAdmin->Option.getOr(false)
    let isOwner = membership.isOwner->Option.getOr(false)
    let isPending = switch membership.status {
    | Some(Pending) => true
    | _ => false
    }

    switch membership.user {
    | Some(member) =>
      if isPending {
        <div className="flex items-center justify-between py-4 px-6">
          <div className="flex items-center space-x-4">
            <img
              className="h-10 w-10 rounded-full"
              src={member.picture->Option.getOr("/default-avatar.png")}
              alt={member.fullName->Option.getOr("Member")}
            />
            <div>
              <h3 className="text-sm font-medium text-gray-900 dark:text-gray-100">
                {member.fullName->Option.getOr("Unknown Member")->React.string}
              </h3>
              {switch member.lineUsername {
              | Some(username) =>
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  {`@${username}`->React.string}
                </p>
              | None => React.null
              }}
            </div>
          </div>
          <div className="flex items-center gap-2">
            <span
              className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 dark:bg-yellow-900/30 text-yellow-800 dark:text-yellow-200">
              {t`Pending`}
            </span>
            {viewerIsAdmin
              ? <>
                  <Button.Button color=#indigo onClick={_ => onApprove()}>
                    {t`Approve`}
                  </Button.Button>
                  <ConfirmButton
                    button={<Button.Button color=#red> {t`Remove`} </Button.Button>}
                    title={t`Remove member?`}
                    description={(
                      ts`Are you sure you want to remove ${member.fullName->Option.getOr(
                        "this member",
                      )} from the club?`
                    )->React.string}
                    onConfirmed={_ => onRemove()}
                  />
                </>
              : React.null}
          </div>
        </div>
      } else {
        // Promoting and demoting is owner-only on the server (setMembershipAdmin),
        // and an owner's own row can never be changed, so the toggle only renders
        // for the owner looking at a non-owner member.
        let adminToggle = if viewerIsOwner && !isOwner {
          if isAdmin {
            <Button.Button outline=true disabled=isSettingAdmin onClick={_ => onSetAdmin(false)}>
              {t`Remove admin`}
            </Button.Button>
          } else {
            <Button.Button color=#indigo disabled=isSettingAdmin onClick={_ => onSetAdmin(true)}>
              {t`Make admin`}
            </Button.Button>
          }
        } else {
          React.null
        }
        let removeButton = if viewerIsAdmin && !isOwner {
          <ConfirmButton
            button={<Button.Button color=#red> {t`Remove`} </Button.Button>}
            title={t`Remove member?`}
            description={(
              ts`Are you sure you want to remove ${member.fullName->Option.getOr(
                "this member",
              )} from the club?`
            )->React.string}
            onConfirmed={_ => onRemove()}
          />
        } else {
          React.null
        }
        let hasActions = (viewerIsOwner || viewerIsAdmin) && !isOwner

        <SwipeAction
          className="border-b border-gray-200 dark:border-[#2a2b30]"
          rightActions={hasActions
            ? <div className="flex gap-2"> {adminToggle} {removeButton} </div>
            : React.null}
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
                <h3 className="text-sm font-medium text-gray-900 dark:text-gray-100">
                  {member.fullName->Option.getOr("Unknown Member")->React.string}
                </h3>
                {switch member.lineUsername {
                | Some(username) =>
                  <p className="text-sm text-gray-500 dark:text-gray-400">
                    {`@${username}`->React.string}
                  </p>
                | None => React.null
                }}
              </div>
            </div>
            <div className="flex items-center gap-2">
              {isOwner
                ? <span
                    className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-purple-100 dark:bg-purple-900/30 text-purple-800 dark:text-purple-200">
                    {t`Owner`}
                  </span>
                : React.null}
              {isAdmin && !isOwner
                ? <span
                    className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 dark:bg-blue-900/30 text-blue-800 dark:text-blue-200">
                    {t`Admin`}
                  </span>
                : React.null}
            </div>
          </div>
        </SwipeAction>
      }
    | None => React.null
    }
  }
}

module ClubMembersData = {
  @react.component
  let make = (~clubId, ~viewerIsAdmin: bool, ~viewerIsOwner: bool) => {
    let t = Lingui.Util.t;
    let data = MembersQuery.use(
      ~variables={
        clubId,
        first: 20,
      },
    )

    let (removeMutation, _isRemoveInFlight) = RemoveUserFromClubMutation.use()
    let (updateStatusMutation, _isUpdateInFlight) = UpdateMembershipStatusMutation.use()
    let (setAdminMutation, isSetAdminInFlight) = SetMembershipAdminMutation.use()

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

    // The payload carries the membership id and its new isAdmin, so Relay
    // updates the badge and the toggle label from the store without a refetch.
    let handleSetAdmin = (membershipId: string, isAdmin: bool) => {
      setAdminMutation(
        ~variables={
          input: {
            membershipId,
            isAdmin,
          },
        },
        ~onCompleted=({setMembershipAdmin}, _errors) => {
          switch setMembershipAdmin.errors {
          | None | Some([]) => ()
          | Some(errors) =>
            errors->Array.forEach(e =>
              Js.Console.error("Failed to update admin status: " ++ e.message)
            )
          }
        },
      )->RescriptRelay.Disposable.ignore
    }

    <div className="bg-white dark:bg-[#1e1f23] shadow overflow-hidden sm:rounded-md">
      <div className="px-4 py-5 sm:p-6">
        <div className="">
          {switch data.clubMembers.edges {
          | None | Some([]) =>
            <div className="py-8 text-center text-gray-500 dark:text-gray-400">
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
                    viewerIsOwner={viewerIsOwner}
                    onRemove={() => {
                      switch membership.user {
                      | Some(user) => handleRemoveUser(user.id)
                      | None => ()
                      }
                    }}
                    onApprove={() => handleApproveUser(membership.id)}
                    onSetAdmin={isAdmin => handleSetAdmin(membership.id, isAdmin)}
                    isSettingAdmin={isSetAdminInFlight}
                  />
                })
                ->React.array

              <>
                {pendingMembers->Array.length > 0
                  ? <div className="mb-6">
                      <h4 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-2"> {t`Pending`} </h4>
                      <div
                        className="divide-y divide-gray-200 dark:divide-[#2a2b30] rounded-md border border-gray-200 dark:border-[#2a2b30] overflow-hidden">
                        {renderMembers(pendingMembers)}
                      </div>
                    </div>
                  : React.null}
                {otherMembers->Array.length > 0
                  ? <div
                      className={pendingMembers->Array.length > 0
                        ? "pt-4 border-t border-gray-200 dark:border-[#2a2b30]"
                        : ""}>
                      <div
                        className="divide-y divide-gray-200 dark:divide-[#2a2b30] rounded-md border border-gray-200 dark:border-[#2a2b30] overflow-hidden">
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
        let viewerIsOwner =
          club.viewerMembership->Option.flatMap(m => m.isOwner)->Option.getOr(false)

        <Layout.Container>
          <h1>
            <div className="text-base leading-6 text-gray-500 dark:text-gray-400">
              <LangProvider.Router.Link to={"/clubs/" ++ club.slug->Option.getOr("")}>
                {club.name->Option.getOr("?")->React.string}
              </LangProvider.Router.Link>
            </div>
            <div className="mt-1 text-2xl font-semibold leading-6 text-gray-900 dark:text-white">
              {t`Members`}
            </div>
          </h1>
          <div className="mt-8">
            <React.Suspense fallback={<div> {t`Loading members...`} </div>}>
              <ClubMembersData
                clubId={club.id}
                viewerIsAdmin={viewerIsAdmin}
                viewerIsOwner={viewerIsOwner}
              />
            </React.Suspense>
          </div>
        </Layout.Container>
      })
      ->Option.getOr(<Layout.Container> {t`club not found`} </Layout.Container>)
    }}
  </WaitForMessages>
}
