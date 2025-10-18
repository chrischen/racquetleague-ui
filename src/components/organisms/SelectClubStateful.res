%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")

// type data<'a> = Promise('a) | Empty

module Fragment = %relay(`
  fragment SelectClubStateful_query on Query
  @argumentDefinitions(
    after: { type: "String" }
    before: { type: "String" }
    first: { type: "Int", defaultValue: 100 }
  )
  @refetchable(queryName: "SelectClubStatefulRefetchQuery") {
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

@react.component
let make = (
  ~clubs: array<CreateLocationEventForm_query_graphql.Types.fragment_viewer_adminClubs_edges_node>,
  ~onSelected: string => unit,
  ~value=None,
  ~connectionId=?,
  ~fragments,
) => {
  open Lingui.Util
  // let data = Fragment.use(clubs)
  // let clubs =
  //   data.viewer
  //   ->Option.map(viewer => viewer.adminClubs->Fragment.getConnectionNodes)
  //   ->Option.getOr([])

  let (showCreateclub, setShowCreateclub) = React.useState(() => false)
  // let (selected, setSelected) = React.useState(() => clubs->Array.get(0)->Option.map(c => c.id))

  let onSelect = id => {
    onSelected(id)
  }

  <WaitForMessages>
    {() =>
      <Grid>
        <FormSection
          title={t`select club`} description={t`choose the club where this event will be held.`}>
          <div className="mt-10 grid grid-cols-1 gap-x-6 gap-y-8">
            <ul>
              {clubs
              ->Array.map(node =>
                <li key={node.id}>
                  <UiAction
                    onClick={_ => onSelect(node.id)}
                    className={value->Option.map(s => s == node.id)->Option.getOr(false)
                      ? "font-extrabold"
                      : ""}>
                    {node.name->Option.getOr("?")->React.string}
                  </UiAction>
                </li>
              )
              ->React.array}
            </ul>
            <UiAction onClick={_ => setShowCreateclub(prev => !prev)}>
              {(showCreateclub ? "- " : "+ ")->React.string}
              {t`add new club`}
            </UiAction>
            <FramerMotion.AnimatePresence mode="sync">
              {showCreateclub
                ? <FramerMotion.Div
                    className=""
                    style={opacity: 1., y: 0.}
                    initial={opacity: 0., scale: 1., y: -50.}
                    animate={FramerMotion.opacity: 1., scale: 1., y: 0.00}
                    exit={opacity: 0., scale: 1., y: -50.}>
                    <CreateClubForm
                      ?connectionId
                      query={fragments}
                      onCancel={_ => setShowCreateclub(_ => false)}
                      onCreated={club => {
                        setShowCreateclub(_ => false)
                        onSelect(club.id)
                      }}
                      inline=true
                    />
                  </FramerMotion.Div>
                : React.null}
            </FramerMotion.AnimatePresence>
          </div>
        </FormSection>
      </Grid>}
  </WaitForMessages>
}
