module Query = %relay(`
  query AutocompleteUserQuery(
    $clubId: ID!
    $first: Int = 200
  ) {
    clubMembers(input: { clubId: $clubId }, first: $first) {
      edges {
        node {
          id
          user {
            id
            fullName
            lineUsername
            picture
          }
        }
      }
    }
  }
`)

type user = {
  id: string,
  fullName: option<string>,
  lineUsername: option<string>,
  picture: option<string>,
}

@react.component
let make = (
  ~clubId: string,
  ~onSelected: user => unit,
  ~placeholder: option<string>=?,
  ~className: option<string>=?,
) => {
  let (searchQuery, setSearchQuery) = React.useState(() => "")
  let (isOpen, setIsOpen) = React.useState(() => false)
  let (_selectedUser, setSelectedUser) = React.useState(() => None)
  let inputRef = React.useRef(Js.Nullable.null)

  // Query for club members
  let queryData = Query.use(
    ~variables={
      clubId,
      first: 10,
    },
  )

  // Extract users from the query response
  let users = React.useMemo(() => {
    queryData.clubMembers.edges
    ->Option.map(edges =>
      edges
      ->Array.filterMap(edge => edge)
      ->Array.filterMap(edge => edge.node)
      ->Array.filterMap(
        membership =>
          membership.user->Option.map(
            u => {
              id: u.id,
              fullName: u.fullName,
              lineUsername: u.lineUsername,
              picture: u.picture,
            },
          ),
      )
    )
    ->Option.getOr([])
  }, [queryData])

  // Filter users based on search query
  let filteredUsers = React.useMemo(() => {
    if searchQuery->String.length == 0 {
      users
    } else {
      let query = searchQuery->String.toLowerCase
      users->Array.filter(user => {
        let fullName = user.fullName->Option.getOr("")->String.toLowerCase
        let lineUsername = user.lineUsername->Option.getOr("")->String.toLowerCase
        fullName->String.includes(query) || lineUsername->String.includes(query)
      })
    }
  }, (searchQuery, users))

  let handleSelect = user => {
    setSelectedUser(_ => Some(user))
    setSearchQuery(_ => user.fullName->Option.getOr(user.lineUsername->Option.getOr("Unknown")))
    setIsOpen(_ => false)
    onSelected(user)
  }

  let handleInputChange = evt => {
    let value = JsxEvent.Form.target(evt)["value"]
    setSearchQuery(_ => value)
    setIsOpen(_ => true)
    setSelectedUser(_ => None)
  }

  let handleInputFocus = _evt => {
    setIsOpen(_ => true)
  }

  let handleInputBlur = _evt => {
    // Delay closing to allow click on dropdown items
    let _ = setTimeout(() => setIsOpen(_ => false), 200)
  }

  <div className={className->Option.getOr("relative")}>
    <div className="relative">
      <input
        ref={inputRef->ReactDOM.Ref.domRef}
        type_="text"
        value={searchQuery}
        onChange={handleInputChange}
        onFocus={handleInputFocus}
        onBlur={handleInputBlur}
        placeholder={placeholder->Option.getOr("Search users...")}
        className="block w-full rounded-md border-0 py-1.5 pl-3 pr-10 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
      />
      <div className="pointer-events-none absolute inset-y-0 right-0 flex items-center pr-3">
        <Lucide.Search className="h-5 w-5 text-gray-400" \"aria-hidden"="true" />
      </div>
    </div>
    {isOpen && filteredUsers->Array.length > 0
      ? <div
          className="absolute z-10 mt-1 max-h-60 w-full overflow-auto rounded-md bg-white py-1 text-base shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none sm:text-sm">
          {filteredUsers
          ->Array.map(user => {
            <button
              key={user.id}
              type_="button"
              onClick={_ => handleSelect(user)}
              className="relative cursor-pointer select-none py-2 pl-3 pr-9 text-gray-900 hover:bg-indigo-600 hover:text-white w-full text-left">
              <div className="flex items-center space-x-3">
                <img
                  className="h-8 w-8 rounded-full flex-shrink-0"
                  src={user.picture->Option.getOr("/default-avatar.png")}
                  alt={user.fullName->Option.getOr("User")}
                />
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium truncate">
                    {user.fullName->Option.getOr("Unknown User")->React.string}
                  </p>
                  {user.lineUsername
                  ->Option.map(username =>
                    <p className="text-sm opacity-75 truncate"> {`@${username}`->React.string} </p>
                  )
                  ->Option.getOr(React.null)}
                </div>
              </div>
            </button>
          })
          ->React.array}
        </div>
      : React.null}
    {isOpen && searchQuery->String.length > 0 && filteredUsers->Array.length == 0
      ? <div
          className="absolute z-10 mt-1 w-full rounded-md bg-white py-3 text-center text-sm text-gray-500 shadow-lg ring-1 ring-black ring-opacity-5">
          {React.string("No users found")}
        </div>
      : React.null}
  </div>
}
