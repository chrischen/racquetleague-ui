// The report renders outside the app shell, so pull in the global stylesheet
// directly like other full-screen pages (e.g. MatchmakingLabPage, KioskPage).
%%raw("import '../../global/static.css'")
%%raw("import { t } from '@lingui/macro'")

module ML = MatchmakingLab

let t = Lingui.Util.t

@genType @react.component
let make = () => {
  <WaitForMessages>
    {() => <>
      // Slim chrome above the article: a way back to the app, and the
      // language switcher. Lives in the page rather than the organism so the
      // article itself stays renderable without router or Relay context.
      <div
        style={ReactDOM.Style.make(~background=ML.paper, ~padding="14px 16px 0", ())}>
        <div
          className="flex items-center justify-between"
          style={ReactDOM.Style.make(~maxWidth="760px", ~margin="0 auto", ())}>
          <LangProvider.Router.Link to="/">
            <span
              style={ReactDOM.Style.make(
                ~fontFamily=ML.monoFont,
                ~fontSize="12px",
                ~letterSpacing="0.06em",
                ~fontWeight="600",
                ~color=ML.ink,
                ~border="1px solid " ++ ML.rule,
                ~padding="6px 12px",
                ~display="inline-block",
                (),
              )}>
              {t`← Back to Pkuru.com`}
            </span>
          </LangProvider.Router.Link>
          <LangSwitch />
        </div>
      </div>
      <MatchmakingReport />
    </>}
  </WaitForMessages>
}
