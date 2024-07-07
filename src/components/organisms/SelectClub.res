%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")

// type data<'a> = Promise('a) | Empty

module Fragment = %relay(`
  fragment SelectClub_query on Query 
  @argumentDefinitions (
    after: { type: "String" }
    before: { type: "String" }
    first: { type: "Int", defaultValue: 20 }
  )
  @refetchable(queryName: "SelectClubRefetchQuery")
  {
    ...CreateClubForm_activities
    viewer {
      __id
      adminClubs(after: $after, first: $first, before: $before)
      @connection(key: "SelectClub_adminClubs") {
        edges {
          node {
            id
            name
          }
        }
      }
    }
  }
`)

@module("../layouts/appContext")
external sessionContext: React.Context.t<UserProvider.session> = "SessionContext"

@react.component
let make = (~clubs) => {
  open Lingui.Util
  let navigate = Router.useNavigate()
  let data = Fragment.use(clubs)
  let clubs =
    data.viewer
    ->Option.map(viewer => viewer.adminClubs->Fragment.getConnectionNodes)
    ->Option.getOr([])

  let (showCreateclub, setShowCreateclub) = React.useState(() => false)

  <WaitForMessages>
    {() =>
      <Layout.Container>
        <Grid>
          <FormSection
            title={t`select club`} description={t`choose the club where this event will be held.`}>
            <div className="mt-10 grid grid-cols-1 gap-x-6 gap-y-8">
              <ul>
                {clubs
                ->Array.map(node =>
                  <li key={node.id}>
                    <Router.NavLink
                      to={node.id->Util.encodeURIComponent}
                      className={({isActive}) => isActive ? "font-extrabold" : ""}>
                      {node.name->Option.getOr("?")->React.string}
                    </Router.NavLink>
                  </li>
                )
                ->React.array}
              </ul>
              <a href="#" onClick={_ => setShowCreateclub(prev => !prev)}>
                {(showCreateclub ? "- " : "+ ")->React.string}
                {t`add new club`}
              </a>
              <FramerMotion.AnimatePresence mode="sync">
                {showCreateclub
                  ? <FramerMotion.Div
                      className=""
                      style={opacity: 1., y: 0.}
                      initial={opacity: 0., scale: 1., y: -50.}
                      animate={opacity: 1., scale: 1., y: 0.00}
                      exit={opacity: 0., scale: 1., y: -50.}>
                      <CreateClubForm
                        connectionId=?{data.viewer->Option.map(v => v.__id)}
                        query={data.fragmentRefs}
                        onCancel={_ => setShowCreateclub(_ => false)}
                        onCreated={club => {
                          setShowCreateclub(_ => false)
                          navigate(Util.encodeURIComponent(club.id), None)
                        }}
                      />
                    </FramerMotion.Div>
                  : React.null}
              </FramerMotion.AnimatePresence>
            </div>
          </FormSection>
          <FramerMotion.AnimatePresence mode="wait">
            <Router.Outlet />
          </FramerMotion.AnimatePresence>
        </Grid>
      </Layout.Container>}
  </WaitForMessages>
}
