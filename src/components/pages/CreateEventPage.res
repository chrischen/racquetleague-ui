%%raw("import { t } from '@lingui/macro'")

@react.component
let make = () => {
  open Lingui.Util;
  let navigate = Router.useNavigate()
  open LangProvider.Router
  <Layout.Container>
    <Link to={"/events/create-bulk"}> {React.string("Create Bulk Events")} </Link>
    <Grid>
      <WaitForMessages>
        {() =>
          <FormSection
            title={t`event location`}
            description={t`choose the location where this event will be held.`}>
            <div className="mt-10 grid grid-cols-1 gap-x-6 gap-y-8">
              <AutocompleteLocation onSelected={location => navigate("./" ++ location, None)} />
            </div>
          </FormSection>}
      </WaitForMessages>
      <FramerMotion.AnimatePresence mode="wait">
        <Router.Outlet />
      </FramerMotion.AnimatePresence>
    </Grid>
  </Layout.Container>
}
