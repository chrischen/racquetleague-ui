%%raw("import { t } from '@lingui/macro'")

// The skill-level pills shared by the create-event form and a location club's
// availability editor. A tag set is either ["all level"] or one or more
// specific levels; `toggle` keeps it that way.
let allLevel = "all level"
let levelTags = Array.concat([allLevel], EventTags.specificLevels)

let toggle = (tags: array<string>, tag: string): array<string> =>
  if tags->Array.includes(tag) {
    // Deselect; fall back to "all level" when nothing is left.
    let rest = tags->Array.filter(t => t != tag)
    rest->Array.length == 0 ? [allLevel] : rest
  } else if tag == allLevel {
    // "All level" replaces every specific level.
    tags->Array.filter(t => !(EventTags.specificLevels->Array.includes(t)))->Array.concat([tag])
  } else {
    // A specific level replaces "all level".
    tags->Array.filter(t => t != allLevel)->Array.concat([tag])
  }

// Design tokens (Magic Patterns "MinimumLevelPills").
let legendClass = "text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400"
let pillClass = active =>
  Util.cx([
    "h-9 rounded-full border px-3.5 text-xs font-semibold transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a]",
    active
      ? "border-gray-900 bg-gray-900 text-white dark:border-gray-100 dark:bg-gray-100 dark:text-gray-900"
      : "border-gray-200 bg-white text-gray-600 hover:border-gray-400 dark:border-[#45464d] dark:bg-[#1e1f23] dark:text-gray-300 dark:hover:border-gray-500",
  ])

@react.component
let make = (
  ~selected: array<string>,
  ~onChange: array<string> => unit,
  ~legend: option<React.element>=?,
) => {
  let ts = Lingui.UtilString.t
  <fieldset>
    {switch legend {
    | Some(legend) => <legend className=legendClass> {legend} </legend>
    | None => React.null
    }}
    <div className="mt-2 flex flex-wrap gap-2">
      {levelTags
      ->Array.map(tag => {
        let active = selected->Array.includes(tag)
        <button
          key=tag
          type_="button"
          ariaPressed={active ? #"true" : #"false"}
          onClick={_ => onChange(toggle(selected, tag))}
          className={pillClass(active)}>
          {(tag == allLevel ? ts`All levels` : tag)->React.string}
        </button>
      })
      ->React.array}
    </div>
  </fieldset>
}
