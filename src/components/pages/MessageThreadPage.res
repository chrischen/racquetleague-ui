%%raw("import { t } from '@lingui/macro'")

// The viewer's conversation with one person (`/messages/:userId`), where a
// message notification leads. The messages come from their own query rather
// than the notifications, so the whole conversation shows however many
// notifications arrived since.

module Query = %relay(`
  query MessageThreadPageQuery($withUserId: ID!) {
    user(id: $withUserId) {
      id
      lineUsername
      picture
    }
    viewer {
      directMessages(withUserId: $withUserId) {
        edges {
          node {
            id
            topic
            payload
            createdAt
          }
        }
      }
    }
  }
`)

type params = {userId: string}

@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<MessageThreadPageQuery_graphql.queryRef> =
  "useLoaderData"

module Thread = {
  @react.component
  let make = (~queryRef: MessageThreadPageQuery_graphql.queryRef, ~withUserId: string) => {
    let {viewer, user} = Query.usePreloaded(~queryRef)
    let person = user->Option.flatMap(u =>
      u.lineUsername->Option.map(name => {MessageThread.name, picture: u.picture})
    )
    let messages =
      viewer
      ->Option.flatMap(v => v.directMessages)
      ->Option.flatMap(c => c.edges)
      ->Option.getOr([])
      ->Array.filterMap(edge => edge->Option.flatMap(e => e.node))
      ->Array.filterMap(n =>
        DirectMessage.decode(~id=n.id, ~topic=n.topic, ~payload=n.payload, ~createdAt=n.createdAt)
      )
    // Keyed by person so moving between conversations starts afresh.
    <MessageThread key=withUserId withUserId person messages />
  }
}

@react.component
let make = () => {
  let ts = Lingui.UtilString.t
  let query = useLoaderData()
  let params: params = Router.useParams()

  <WaitForMessages>
    {() =>
      <div className="flex-1 overflow-y-auto bg-white dark:bg-[#222326]">
        <div className="max-w-3xl mx-auto px-4 md:px-6 py-6 pb-24 md:pb-10">
          <LangProvider.Router.Link
            to="/notifications"
            className="mb-4 inline-flex items-center gap-1.5 text-sm font-medium text-gray-500 transition-colors hover:text-gray-900 focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] dark:text-gray-400 dark:hover:text-gray-100">
            <Lucide.ArrowLeft size=15 \"aria-hidden"="true" />
            {(ts`Notifications`)->React.string}
          </LangProvider.Router.Link>
          <React.Suspense
            fallback={<div
              className="border border-dashed border-gray-200 dark:border-[#3a3b40] rounded-lg py-16 flex flex-col items-center justify-center">
              <Lucide.MessageCircle
                className="w-[18px] h-[18px] text-gray-400 dark:text-gray-500"
              />
            </div>}>
            <Thread queryRef=query.data withUserId=params.userId />
          </React.Suspense>
        </div>
      </div>}
  </WaitForMessages>
}
