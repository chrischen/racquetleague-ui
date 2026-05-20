%%raw("import { t } from '@lingui/macro'")

module Fragment = %relay(`
  fragment NotificationsPreview_viewer on Viewer {
    inbox(first: 5) {
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
`)

module MarkAllReadMutation = %relay(`
  mutation NotificationsPreviewMarkAllReadMutation {
    markAllInboxRead {
      viewerMetadata {
        id
        unreadInboxCount
      }
    }
  }
`)

@val @scope("document")
external docAddEventListener: (string, 'a) => unit = "addEventListener"
@val @scope("document")
external docRemoveEventListener: (string, 'a) => unit = "removeEventListener"

let domContains: (Dom.element, Dom.node) => bool = %raw(`function(el, n) { return el.contains(n) }`)

@react.component
let make = (
  ~viewer: RescriptRelay.fragmentRefs<[> #NotificationsPreview_viewer]>,
  ~onClose: unit => unit,
  ~onViewAll: unit => unit,
) => {
  let ts = Lingui.UtilString.t
  let navigate = LangProvider.Router.useNavigate()
  let data = Fragment.use(viewer)
  let (commitMarkAll, _) = MarkAllReadMutation.use()
  let edges =
    data.inbox
    ->Option.map(inbox => inbox.edges->Option.getOr([]))
    ->Option.getOr([])

  React.useEffect0(() => {
    let _ = commitMarkAll(~variables=())
    None
  })

  let popoverRef: React.ref<Js.Nullable.t<Dom.element>> = React.useRef(Js.Nullable.null)

  React.useEffect1(() => {
    let handleClickOutside = (e: Dom.mouseEvent) => {
      let target: Dom.node = %raw(`e.target`)
      switch popoverRef.current->Js.Nullable.toOption {
      | None => ()
      | Some(el) =>
        if !domContains(el, target) {
          onClose()
        }
      }
    }
    let handleEscape = (e: Dom.keyboardEvent) => {
      let key: string = %raw(`e.key`)
      if key == "Escape" {
        onClose()
      }
    }
    let timeoutId = Js.Global.setTimeout(() => {
      docAddEventListener("mousedown", handleClickOutside)
      docAddEventListener("keydown", handleEscape)
    }, 0)
    Some(
      () => {
        Js.Global.clearTimeout(timeoutId)
        docRemoveEventListener("mousedown", handleClickOutside)
        docRemoveEventListener("keydown", handleEscape)
      },
    )
  }, [onClose])

  <FramerMotion.DivCss
    className="fixed left-3 right-3 top-[58px] md:left-auto md:right-0 md:top-full md:mt-2 md:absolute md:w-[360px] bg-white dark:bg-[#1e1f23] border border-gray-200 dark:border-[#3a3b40] rounded-lg shadow-2xl z-50 overflow-hidden"
    initial={{opacity: 0., scale: 0.96, y: -6.}}
    animate={{opacity: 1., scale: 1., y: 0.}}
    exit={{opacity: 0., scale: 0.96, y: -6.}}>
    <div ref={ReactDOM.Ref.domRef(popoverRef)} className="flex flex-col">
      // Header
      <div
        className="flex items-center gap-2 px-4 py-3 border-b border-gray-100 dark:border-[#2a2b30]">
        <Lucide.Bell className="w-3.5 h-3.5 text-gray-500 dark:text-gray-400" />
        <span className="text-sm font-semibold text-gray-900 dark:text-gray-100">
          {(ts`Notifications`)->React.string}
        </span>
      </div>
      // List
      {if edges->Array.length == 0 {
        <div className="py-10 flex flex-col items-center justify-center text-center px-6">
          <div
            className="w-10 h-10 rounded-full bg-gray-100 dark:bg-[#2a2b30] flex items-center justify-center mb-2">
            <Lucide.Bell className="w-3.5 h-3.5 text-gray-400 dark:text-gray-500" />
          </div>
          <p className="text-xs text-gray-500 dark:text-gray-400 font-mono">
            {(ts`No notifications`)->React.string}
          </p>
        </div>
      } else {
        <div
          className="max-h-[420px] overflow-y-auto divide-y divide-gray-100 dark:divide-[#2a2b30]">
          {edges
          ->Array.filterMap(edge =>
            edge
            ->Option.flatMap(e => e.node)
            ->Option.map(n =>
              <NotificationRow
                key=n.id
                topic=n.topic
                payload=n.payload
                createdAt=n.createdAt
                compact=true
                onNavigate={url => {
                  onClose()
                  navigate(url, None)
                }}
              />
            )
          )
          ->React.array}
        </div>
      }}
      // Footer
      <button
        onClick={_ => onViewAll()}
        className="w-full flex items-center justify-center gap-1.5 px-4 py-2.5 text-xs font-semibold text-gray-700 dark:text-gray-200 border-t border-gray-100 dark:border-[#2a2b30] hover:bg-gray-50 dark:hover:bg-[#2a2b30] transition-colors">
        {(ts`View all notifications`)->React.string}
        <Lucide.ArrowRight className="w-3 h-3" />
      </button>
    </div>
  </FramerMotion.DivCss>
}
