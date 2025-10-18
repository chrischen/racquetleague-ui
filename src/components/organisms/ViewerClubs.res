%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

module Fragment = %relay(`
  fragment ViewerClubs_viewer on Viewer {
    clubs(first: 100) {
      edges {
        node {
          id
          name
          slug
          defaultActivity {
            slug
          }
        }
      }
    }
  }
`)

// Helper function to generate initials from club name
let getClubInitials = (name: string) => {
  // Check if the name contains CJK (Chinese, Japanese, Korean) characters
  let hasCJK = %re("/[\u4E00-\u9FFF\u3040-\u309F\u30A0-\u30FF\uAC00-\uD7AF]/u")->Js.Re.test_(name)

  if hasCJK {
    // For CJK characters, take first 2 characters
    name->String.substring(~start=0, ~end=Js.Math.min_int(2, String.length(name)))
  } else {
    // For Latin characters, get initials from words
    name
    ->String.trim
    ->String.split(" ")
    ->Array.filterMap(word => {
      let trimmed = word->String.trim
      if String.length(trimmed) > 0 {
        Some(String.charAt(trimmed, 0)->String.toUpperCase)
      } else {
        None
      }
    })
    ->Array.slice(~start=0, ~end=3) // Take up to 3 initials
    ->Array.join("")
  }
}

// Helper function to generate a color based on club name
let getClubColor = (name: string) => {
  // Simple hash function to generate consistent colors
  let hash =
    name
    ->String.split("")
    ->Array.reduce(0, (acc, char) => {
      let code = char->String.charCodeAt(0)->Int.fromFloat
      acc * 31 + code
    })

  let colors = [
    "bg-blue-500",
    "bg-purple-500",
    "bg-pink-500",
    "bg-red-500",
    "bg-orange-500",
    "bg-yellow-500",
    "bg-green-500",
    "bg-teal-500",
    "bg-cyan-500",
    "bg-indigo-500",
  ]

  let index = mod(hash, Array.length(colors))
  colors->Array.get(index)->Option.getOr("bg-gray-500")
}

type club = {
  id: string,
  name: string,
  slug: string,
}

@react.component
let make = (
  ~viewer: RescriptRelay.fragmentRefs<[> #ViewerClubs_viewer]>,
  ~activitySlug: option<string>=?,
) => {
  let data = Fragment.use(viewer)

  let clubs =
    data.clubs.edges
    ->Option.getOr([])
    ->Array.filterMap(edge => edge)
    ->Array.filterMap(edge => edge.node)
    ->Array.filter(club => {
      // If activitySlug is provided, filter by defaultActivity
      switch activitySlug {
      | None => true // Show all clubs if no activity filter
      | Some(filterSlug) =>
        club.defaultActivity
        ->Option.flatMap(activity => activity.slug)
        ->Option.map(slug => slug == filterSlug)
        ->Option.getOr(false) // Exclude clubs without matching activity
      }
    })
    ->Array.map(club => {
      id: club.id,
      name: club.name->Option.getOr("Unknown"),
      slug: club.slug->Option.getOr(""),
    })

  if Array.length(clubs) == 0 {
    React.null
  } else {
    <div className="mb-4">
      <h2 className="text-sm font-semibold text-gray-700 mb-3"> {t`my clubs`} </h2>
      <div
        className="flex overflow-x-auto gap-3 pb-2 -mx-1 px-1 scrollbar-thin scrollbar-thumb-gray-300 scrollbar-track-gray-100">
        {clubs
        ->Array.map(club => {
          let initials = getClubInitials(club.name)
          let colorClass = getClubColor(club.name)

          <a
            key={club.id}
            href={`/clubs/${club.slug}`}
            className="flex flex-col items-center min-w-[80px] group">
            <div
              className={`w-16 h-16 rounded-full ${colorClass} flex items-center justify-center text-white font-bold text-lg shadow-md group-hover:shadow-lg transition-shadow mb-2`}>
              {initials->React.string}
            </div>
            <span
              className="text-xs text-center text-gray-700 font-medium line-clamp-2 w-full px-1 group-hover:text-blue-600 transition-colors">
              {club.name->React.string}
            </span>
          </a>
        })
        ->React.array}
      </div>
    </div>
  }
}
