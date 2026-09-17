%%raw("import { t } from '@lingui/macro'")

// Hosts the create-event form as a modal over whichever page is current. The
// `create` search param opens it (CreateEventLink builds those links), so the
// page stays the route and the URL still records the open modal for reload,
// back and sharing. No route loader runs for it, so the form's own message
// catalog is loaded here on first open.

let loadMessages = Lingui.loadMessages({
  en: Lingui.import("../../locales/src/components/pages/CreateEventPage.re/en"),
  ja: Lingui.import("../../locales/src/components/pages/CreateEventPage.re/ja"),
  th: Lingui.import("../../locales/src/components/pages/CreateEventPage.re/th"),
  zhTW: Lingui.import("../../locales/src/components/pages/CreateEventPage.re/zh-TW"),
  zhCN: Lingui.import("../../locales/src/components/pages/CreateEventPage.re/zh-CN"),
  ko: Lingui.import("../../locales/src/components/pages/CreateEventPage.re/ko"),
  vi: Lingui.import("../../locales/src/components/pages/CreateEventPage.re/vi"),
})

@react.component
let make = () => {
  open Lingui.Util
  let (params, setParams) = Router.useSearchParamsFuncWith()
  let navigateBack = Router.useNavigateDelta()
  let locale = React.useContext(LangProvider.LocaleContext.context)
  let isOpen = CreateEventLink.isOpen(params)

  // Opened by a navigation in this session, so closing can step back to the
  // page's own URL; arriving with it already open (a reload or a shared link)
  // leaves nothing to step back to, so closing strips the modal's params.
  let openedHere = React.useRef(false)
  let wasOpen = React.useRef(isOpen)
  React.useEffect(() => {
    if isOpen && !wasOpen.current {
      openedHere.current = true
    }
    if !isOpen {
      openedHere.current = false
    }
    wasOpen.current = isOpen
    None
  }, [isOpen])

  let (messagesReady, setMessagesReady) = React.useState(() => false)
  React.useEffect(() => {
    if isOpen && !messagesReady {
      Promise.all(loadMessages(locale.lang))
      ->Promise.thenResolve(_ => setMessagesReady(_ => true))
      ->ignore
    }
    None
  }, [isOpen, messagesReady])

  let close = () =>
    if openedHere.current {
      navigateBack(-1)
    } else {
      setParams(query => {
        CreateEventLink.strip(query)
        query
      }, {Router.replace: true})
    }

  let loading = <div className="p-6 text-sm text-gray-500 dark:text-gray-400"> {t`Loading...`} </div>

  if !isOpen {
    React.null
  } else {
    <RouteModal
      title={t`Create event`}
      eyebrow={t`New plan`}
      description={t`Describe the event to draft it, or fill in the details.`}
      onClose=close>
      {messagesReady
        ? <React.Suspense fallback=loading> <CreateEventPage.Body /> </React.Suspense>
        : loading}
    </RouteModal>
  }
}
