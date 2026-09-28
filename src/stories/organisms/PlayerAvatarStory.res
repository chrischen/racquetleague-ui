// Storybook support for PlayerAvatar.stories.tsx; the app never imports this.
// The avatar is small, so each preset lays several out side by side: the
// three sizes, the custom-size mode (a className, as the round views use it),
// and the four skill colour bands of the progress ring.
module Query = %relay(`
  query PlayerAvatarStoryQuery {
    user(id: "user-kenji") {
      ...PlayerAvatar_user
    }
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = PlayerAvatarStoryQuery_graphql.node->Obj.magic

let caption = text =>
  <span className="font-mono text-[10px] uppercase tracking-wider text-gray-500 dark:text-gray-400">
    {text->React.string}
  </span>

let cell = (~label, avatar) =>
  <div key=label className="flex flex-col items-center gap-2">
    avatar
    {caption(label)}
  </div>

@genType @react.component
let make = (~state: [#sizes | #initials | #skillBands]=#sizes, ~name="Kenji Watanabe") => {
  let data = Query.use(~variables=())
  let userFragmentRefs = switch state {
  | #initials => None
  | #sizes | #skillBands => data.user->Option.map(u => u.fragmentRefs)
  }
  <div className="flex flex-wrap items-end gap-8 font-sans">
    {switch state {
    | #sizes | #initials =>
      [
        cell(~label="small", <PlayerAvatar userFragmentRefs name skillLevel=82. size=#small />),
        cell(~label="medium", <PlayerAvatar userFragmentRefs name skillLevel=82. size=#medium />),
        cell(~label="large", <PlayerAvatar userFragmentRefs name skillLevel=82. size=#large />),
        cell(
          ~label="className w-20 h-20",
          <PlayerAvatar userFragmentRefs name skillLevel=82. className="w-20 h-20" />,
        ),
      ]->React.array
    | #skillBands =>
      [(12., "12 · red"), (38., "38 · amber"), (63., "63 · blue"), (91., "91 · green")]
      ->Array.map(((skillLevel, label)) =>
        cell(~label, <PlayerAvatar userFragmentRefs name skillLevel size=#large />)
      )
      ->React.array
    }}
  </div>
}
