// Storybook support for AutocompleteUser.stories.tsx; the app never imports
// this. The component runs its own query (the club's members), so the story
// hands that operation and its variables to `parameters.relay`.

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The component's own operation, for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = AutocompleteUserQuery_graphql.node->Obj.magic

/** The club whose members the story searches. */
@genType
let clubId = "club-shibuya"

/** The variables the component passes; `parameters.relay.variables` must match. */
@genType
let variables = {"clubId": clubId, "first": 20}

@genType @react.component
let make = (
  ~withClose=false,
  ~placeholder: option<string>=?,
  ~onSelected: option<string => unit>=?,
  ~onClose=() => (),
) =>
  <div className="max-w-sm pb-56 font-sans">
    <AutocompleteUser
      clubId
      ?placeholder
      onSelected={user => onSelected->Option.forEach(f => f(user.id))}
      onClose=?{withClose ? Some(onClose) : None}
    />
  </div>
