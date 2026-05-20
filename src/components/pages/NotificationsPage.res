%%raw("import { t } from '@lingui/macro'")

module Query = %relay(`
  query NotificationsPageQuery {
    viewer {
      inbox(first: 50) {
        edges {
          node {
            id
            topic
            payload
            createdAt
            isRead
          }
        }
      }
    }
  }
`)

module MarkAllReadMutation = %relay(`
  mutation NotificationsPageMarkAllReadMutation {
    markAllInboxRead {
      viewerMetadata {
        id
        unreadInboxCount
      }
    }
  }
`)

@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<NotificationsPageQuery_graphql.queryRef> =
  "useLoaderData"

module InboxList = {
  @react.component
  let make = (~queryRef: NotificationsPageQuery_graphql.queryRef) => {
    let ts = Lingui.UtilString.t
    let {viewer} = Query.usePreloaded(~queryRef)
    let allEdges =
      viewer
      ->Option.flatMap(v => v.inbox)
      ->Option.map(inbox => inbox.edges->Option.getOr([]))
      ->Option.getOr([])

    let (commitMarkAll, _) = MarkAllReadMutation.use()

    React.useEffect0(() => {
      let _ = commitMarkAll(~variables=())
      None
    })

    let (dismissed, setDismissed) = React.useState((): array<string> => [])

    let visibleEdges = allEdges->Array.filter(edge =>
      switch edge->Option.flatMap(e => e.node) {
      | Some(n) => !(dismissed->Array.some(d => d == n.id))
      | None => false
      }
    )

    let dismiss = (id: string) => setDismissed(prev => Array.concat(prev, [id]))

    if visibleEdges->Array.length == 0 {
      <div
        className="border border-dashed border-gray-200 dark:border-[#3a3b40] rounded-lg py-16 flex flex-col items-center justify-center text-center">
        <div
          className="w-12 h-12 rounded-full bg-gray-100 dark:bg-[#2a2b30] flex items-center justify-center mb-3">
          <Lucide.Bell className="w-[18px] h-[18px] text-gray-400 dark:text-gray-500" />
        </div>
        <h3 className="text-sm font-medium text-gray-900 dark:text-gray-100">
          {(ts`Nothing here yet`)->React.string}
        </h3>
        <p className="text-xs text-gray-500 dark:text-gray-400 mt-1 font-mono">
          {(ts`You're all caught up`)->React.string}
        </p>
      </div>
    } else {
      <div
        className="border border-gray-200 dark:border-[#2a2b30] rounded-lg overflow-hidden divide-y divide-gray-100 dark:divide-[#2a2b30] bg-white dark:bg-[#1e1f23]">
        {visibleEdges
        ->Array.filterMap(edge =>
          edge
          ->Option.flatMap(e => e.node)
          ->Option.map(n =>
            <NotificationRow
              key=n.id
              topic=n.topic
              payload=n.payload
              createdAt=n.createdAt
              onDismiss={() => dismiss(n.id)}
            />
          )
        )
        ->React.array}
      </div>
    }
  }
}

@react.component
let make = () => {
  let ts = Lingui.UtilString.t
  let query = useLoaderData()

  <WaitForMessages>
    {() =>
      <div className="flex-1 overflow-y-auto bg-white dark:bg-[#222326]">
        <div className="max-w-3xl mx-auto px-4 md:px-6 py-6 pb-24 md:pb-10">
          <div className="mb-5">
            <div
              className="font-mono text-[10px] tracking-wider text-gray-400 dark:text-gray-500 uppercase mb-1">
              {(ts`Inbox`)->React.string}
            </div>
            <h1 className="text-2xl font-semibold text-gray-900 dark:text-gray-100 leading-tight">
              {(ts`Notifications`)->React.string}
            </h1>
          </div>
          <React.Suspense
            fallback={<div
              className="border border-dashed border-gray-200 dark:border-[#3a3b40] rounded-lg py-16 flex flex-col items-center justify-center">
              <Lucide.Bell className="w-[18px] h-[18px] text-gray-400 dark:text-gray-500 mb-3" />
            </div>}>
            <InboxList queryRef=query.data />
          </React.Suspense>
        </div>
      </div>}
  </WaitForMessages>
}
