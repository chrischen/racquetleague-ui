%%raw("import { t } from '@lingui/macro'")

let ts = Lingui.UtilString.t

/** A small label saying where a rating came from, so a number on screen is
 never ambiguous between "earned here", "verified by DUPR" and "the player
 told us". Pairs with EffectiveRating, which decides which one is shown. */
@react.component
let make = (~source: EffectiveRating.source, ~reliable: bool=true, ~className: string="") => {
  let (label, tone) = switch source {
  | Pkuru => (ts`pkuru`, "bg-violet-100 text-violet-700 dark:bg-violet-900/40 dark:text-violet-300")
  | Dupr => ("DUPR", "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/40 dark:text-emerald-300")
  | Self => (ts`Self-rated`, "bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-400")
  }
  <span className={"inline-flex items-center gap-1 " ++ className}>
    <span
      className={"inline-flex items-center rounded px-1.5 py-0.5 text-[10px] font-semibold uppercase tracking-wide " ++
      tone}>
      {label->React.string}
    </span>
    {reliable
      ? React.null
      : <span
          className="inline-flex items-center rounded px-1.5 py-0.5 text-[10px] font-medium uppercase tracking-wide bg-amber-100 text-amber-700 dark:bg-amber-900/40 dark:text-amber-300">
          {(ts`provisional`)->React.string}
        </span>}
  </span>
}
