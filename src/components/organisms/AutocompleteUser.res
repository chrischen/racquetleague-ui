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

let getInitials = (fullName: option<string>) => {
  switch fullName {
  | None | Some("") => "?"
  | Some(n) =>
    n
    ->String.split(" ")
    ->Array.slice(~start=0, ~end=2)
    ->Array.map(p => p->String.slice(~start=0, ~end=1)->String.toUpperCase)
    ->Array.join("")
  }
}

@react.component
let make = (
  ~clubId: string,
  ~onSelected: user => unit,
  ~onClose: unit => unit=?,
  ~placeholder: option<string>=?,
) => {
  let (searchQuery, setSearchQuery) = React.useState(() => "")
  let inputRef = React.useRef(Js.Nullable.null)

  let queryData = Query.use(
    ~variables={
      clubId,
      first: 20,
    },
  )

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

  let filteredUsers = React.useMemo(() => {
    if searchQuery->String.length == 0 {
      []
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
    onSelected(user)
    switch onClose {
    | Some(close) => close()
    | None => setSearchQuery(_ => "")
    }
  }

  let handleInputChange = evt => {
    let value = JsxEvent.Form.target(evt)["value"]
    setSearchQuery(_ => value)
  }

  let handleKeyDown = evt => {
    if JsxEvent.Keyboard.key(evt) == "Escape" {
      switch onClose {
      | Some(close) => close()
      | None => setSearchQuery(_ => "")
      }
    }
  }

  let handleBlur = _evt => {
    switch onClose {
    | Some(close) =>
      let _ = setTimeout(() => close(), 150)
    | None => ()
    }
  }

  <div className="relative">
    <div
      className="flex items-center gap-2 border border-gray-300 dark:border-[#4a4b50] rounded-lg px-3 py-2 bg-white dark:bg-[#1e1f23] shadow-sm focus-within:border-gray-400 dark:focus-within:border-gray-500 transition-colors">
      <Lucide.Search size=14 className="text-gray-400 flex-shrink-0" />
      <input
        ref={inputRef->ReactDOM.Ref.domRef}
        autoFocus=true
        type_="text"
        value={searchQuery}
        onChange={handleInputChange}
        onKeyDown={handleKeyDown}
        onBlur={handleBlur}
        placeholder={placeholder->Option.getOr("Search players...")}
        className="flex-1 bg-transparent text-sm text-gray-900 dark:text-gray-100 placeholder-gray-400 dark:placeholder-gray-500 focus:outline-none"
      />
      {onClose
      ->Option.map(close =>
        <button
          type_="button"
          onClick={_ => close()}
          className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 flex-shrink-0">
          <Lucide.X size=14 />
        </button>
      )
      ->Option.getOr(React.null)}
    </div>
    {searchQuery->String.length > 0
      ? <div
          className="absolute top-full left-0 right-0 mt-1 bg-white dark:bg-[#2a2b30] border border-gray-200 dark:border-[#3a3b40] rounded-lg shadow-lg z-50 py-1 max-h-48 overflow-y-auto">
          {filteredUsers->Array.length > 0
            ? filteredUsers
              ->Array.map(user => {
                let initials = getInitials(user.fullName)
                let displayName =
                  user.fullName->Option.getOr(user.lineUsername->Option.getOr("Unknown"))
                <div
                  key={user.id}
                  onClick={_ => handleSelect(user)}
                  className="flex items-center gap-2.5 px-3 py-2 cursor-pointer hover:bg-gray-50 dark:hover:bg-[#353640] transition-colors">
                  <div
                    className="w-6 h-6 rounded-full bg-gray-200 dark:bg-[#3a3b40] flex items-center justify-center text-[10px] font-medium text-gray-700 dark:text-gray-300 flex-shrink-0">
                    {initials->React.string}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="text-xs font-medium text-gray-900 dark:text-gray-100 truncate">
                      {displayName->React.string}
                    </div>
                  </div>
                  {user.lineUsername
                  ->Option.map(un =>
                    <div className="font-mono text-[10px] text-gray-500 dark:text-gray-400">
                      {("@" ++ un)->React.string}
                    </div>
                  )
                  ->Option.getOr(React.null)}
                </div>
              })
              ->React.array
            : <div className="px-3 py-4 text-center text-xs text-gray-500 dark:text-gray-400">
                {"No players found"->React.string}
              </div>}
        </div>
      : React.null}
  </div>
}
