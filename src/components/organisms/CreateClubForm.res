%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")

let ts = Lingui.UtilString.t

type data<'a> = Promise('a) | Empty

module ActivitiesFragment = %relay(`
  fragment CreateClubForm_activities on Query {
    activities {
      id
      name
      slug
    }
  }
`)
module Mutation = %relay(`
 mutation CreateClubFormMutation(
    $connections: [ID!]!
    $input: CreateClubInput!
  ) {
    createClub(input: $input) {
      club @appendNode(connections: $connections, edgeTypeName: "ClubEdge") {
        __typename
        id
        name
        slug
        defaultActivity {
          id
          name
          slug
        }
      }
      errors {
        message
      }
    }
  }
`)

@module("../layouts/appContext")
external sessionContext: React.Context.t<UserProvider.session> = "SessionContext"

@rhf
type inputs = {
  name: Zod.string_,
  slug: Zod.string_,
  activity: Zod.string_,
  description: Zod.optional<Zod.string_>,
}

type clubData = {
  name: string,
  slug: string,
  description: string,
  defaultActivity: string,
}

@react.component
let make = (~connectionId=?, ~query, ~onCancel, ~onCreated, ~inline: bool=false) => {
  open Lingui.Util
  let ts = Lingui.UtilString.t
  let td = Lingui.UtilString.dynamic

  let (commitMutationCreate, _) = Mutation.use()
  let {activities} = ActivitiesFragment.use(query)

  // Find pickleball activity, fallback to first activity if not found
  let defaultActivityId =
    activities
    ->Array.find(a =>
      a.slug
      ->Option.map(slug => slug == "pickleball")
      ->Option.getOr(false)
    )
    ->Option.map(a => a.id)
    ->Option.getOr(activities->Array.get(0)->Option.map(a => a.id)->Option.getOr(""))

  let (newClubData, setNewClubData) = React.useState(() => {
    name: "",
    slug: "",
    description: "",
    defaultActivity: defaultActivityId,
  })

  // Track whether slug has been manually edited
  let (slugManuallyEdited, setSlugManuallyEdited) = React.useState(() => false)

  let handleClubNameChange = name => {
    // Auto-generate slug from name if not manually edited
    setNewClubData(prev => {
      let newSlug = if !slugManuallyEdited {
        name
        ->Js.String2.toLowerCase
        ->Js.String2.replaceByRe(%re("/[^a-z0-9-]/g"), "-")
        ->Js.String2.replaceByRe(%re("/-+/g"), "-")
        ->Js.String2.replaceByRe(%re("/^-|-$/g"), "")
      } else {
        prev.slug
      }
      {...prev, name, slug: newSlug}
    })
  }

  let handleAddClub = () => {
    // Validate that both name and slug are present
    if newClubData.name->Js.String2.trim == "" || newClubData.slug->Js.String2.trim == "" {
      ()
    } else {
      let connections =
        connectionId
        ->Option.map(connectionId => [
          RescriptRelay.ConnectionHandler.getConnectionID(connectionId, "viewer_adminClubs", ()),
        ])
        ->Option.getOr([])

      commitMutationCreate(
        ~variables={
          input: {
            name: newClubData.name,
            slug: newClubData.slug,
            activity: newClubData.defaultActivity,
            description: newClubData.description,
          },
          connections,
        },
        ~onCompleted=(response, _errors) => {
          response.createClub.club
          ->Option.map(club => {
            setNewClubData(
              _ => {
                name: "",
                slug: "",
                description: "",
                defaultActivity: defaultActivityId,
              },
            )
            setSlugManuallyEdited(_ => false)
            onCreated(club)
          })
          ->ignore
        },
      )->RescriptRelay.Disposable.ignore
    }
  }

  let handleCancelAddClub = () => {
    setNewClubData(_ => {
      name: "",
      slug: "",
      description: "",
      defaultActivity: defaultActivityId,
    })
    setSlugManuallyEdited(_ => false)
    onCancel()
  }

  <div
    className="space-y-4 p-4 border-2 border-[#a3e635] rounded-lg bg-[#f7fee7] dark:bg-[#3f6212]/10 transition-colors">
    <div className="pt-1">
      <label
        htmlFor="clubName"
        className="block text-xs font-medium text-gray-700 dark:text-gray-400 mb-1.5">
        {t`Club Name`}
      </label>
      <input
        id="clubName"
        type_="text"
        value={newClubData.name}
        onChange={e => {
          let value = ReactEvent.Form.target(e)["value"]
          handleClubNameChange(value)
        }}
        onKeyDown={e => {
          switch ReactEvent.Keyboard.key(e) {
          | "Enter" => {
              ReactEvent.Keyboard.preventDefault(e)
              handleAddClub()
            }
          | "Escape" => handleCancelAddClub()
          | _ => ()
          }
        }}
        placeholder={ts`e.g., City Ballers Club`}
        className="block w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#a3e635] focus:border-[#a3e635] transition-colors bg-white dark:bg-[#222222] text-gray-900 dark:text-gray-100 placeholder:text-gray-400 dark:placeholder:text-gray-600"
        autoFocus={true}
      />
    </div>
    <div>
      <label
        htmlFor="clubDescription"
        className="block text-xs font-medium text-gray-700 dark:text-gray-400 mb-1.5">
        {t`Description`}
      </label>
      <textarea
        id="clubDescription"
        value={newClubData.description}
        onChange={e => {
          let value = ReactEvent.Form.target(e)["value"]
          setNewClubData(prev => {...prev, description: value})
        }}
        placeholder={ts`Brief description of the club...`}
        rows=3
        className="block w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#a3e635] focus:border-[#a3e635] transition-colors resize-none bg-white dark:bg-[#222222] text-gray-900 dark:text-gray-100 placeholder:text-gray-400 dark:placeholder:text-gray-600"
      />
    </div>
    <div>
      <label
        htmlFor="clubActivity"
        className="block text-xs font-medium text-gray-700 dark:text-gray-400 mb-1.5">
        {t`Default club activity`}
      </label>
      <select
        id="clubActivity"
        value={newClubData.defaultActivity}
        onChange={e => {
          let value = ReactEvent.Form.target(e)["value"]
          setNewClubData(prev => {...prev, defaultActivity: value})
        }}
        className="block w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#a3e635] focus:border-[#a3e635] transition-colors bg-white dark:bg-[#222222] text-gray-900 dark:text-gray-100">
        {activities
        ->Array.map(activity =>
          <option key={activity.id} value={activity.id}>
            {td(activity.name->Option.getOr("---"))->React.string}
          </option>
        )
        ->React.array}
      </select>
    </div>
    <div>
      <label
        htmlFor="clubSlug"
        className="block text-xs font-medium text-gray-700 dark:text-gray-400 mb-1.5">
        {t`Club URL`}
      </label>
      <div
        className="flex items-center border border-gray-300 dark:border-gray-700 rounded-lg bg-white dark:bg-[#222222] focus-within:ring-2 focus-within:ring-[#a3e635] focus-within:border-[#a3e635] transition-all">
        <span
          className="px-3 text-sm text-gray-500 dark:text-gray-400 whitespace-nowrap select-none">
          {"pkuru.com/clubs/"->React.string}
        </span>
        <input
          id="clubSlug"
          type_="text"
          value={newClubData.slug}
          onChange={e => {
            let value = ReactEvent.Form.target(e)["value"]
            let slug =
              value->Js.String2.toLowerCase->Js.String2.replaceByRe(%re("/[^a-z0-9-]/g"), "")
            setSlugManuallyEdited(_ => true)
            setNewClubData(prev => {...prev, slug})
          }}
          placeholder={ts`club-name`}
          className="flex-1 min-w-0 px-0 py-2 text-sm border-0 focus:outline-none focus:ring-0 bg-transparent text-gray-900 dark:text-gray-100 placeholder:text-gray-400 dark:placeholder:text-gray-600"
        />
      </div>
    </div>
    <div className="flex gap-2 pt-2">
      <button
        type_="button"
        onClick={_ => handleAddClub()}
        disabled={newClubData.name->Js.String2.trim->Js.String2.length == 0 ||
          newClubData.slug->Js.String2.trim->Js.String2.length == 0}
        className="flex items-center gap-1.5 px-4 py-2 bg-[#a3e635] text-gray-900 rounded-lg text-sm font-medium hover:bg-[#84cc16] disabled:bg-gray-200 dark:disabled:bg-gray-700 disabled:text-gray-400 dark:disabled:text-gray-500 disabled:cursor-not-allowed transition-colors">
        <HeroIcons.CheckIcon className="h-4 w-4" />
        {t`Create Club`}
      </button>
      <button
        type_="button"
        onClick={_ => handleCancelAddClub()}
        className="flex items-center gap-1.5 px-4 py-2 bg-white dark:bg-[#222222] text-gray-700 dark:text-gray-300 rounded-lg text-sm font-medium hover:bg-gray-50 dark:hover:bg-[#2a2a2a] border border-gray-300 dark:border-gray-700 transition-colors">
        <HeroIcons.XMarkIcon className="h-4 w-4" />
        {t`Cancel`}
      </button>
    </div>
  </div>
}

// let td = lingui.utilstring.td
// @live
// td({id: "badminton"})->ignore
// @live
// td({id: "table tennis"})->ignore
// @live
// td({id: "pickleball"})->ignore
// @live
// td({id: "futsal"})->ignore
// @live
// td({id: "basketball"})->ignore
// @live
// td({id: "volleyball"})->ignore
