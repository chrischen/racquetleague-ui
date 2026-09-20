%%raw("import { t } from '@lingui/macro'")

let ts = Lingui.UtilString.t

/** A player's DUPR ratings as DUPR reports them.

 Doubles leads because that is what pkuru plays and what the rest of the app
 gates on; singles is secondary and often absent. DUPR writes "NR" for a
 format it has not rated, and an unreliable rating is marked provisional
 rather than hidden — it still counts. */
@react.component
let make = (
  ~doubles: option<float>,
  ~singles: option<float>=?,
  ~doublesReliable: bool=true,
  ~singlesReliable: bool=true,
  ~compact: bool=false,
) => {
  let unrated = ts`NR`
  let format = (v: option<float>) =>
    switch v {
    | Some(v) => v->Float.toFixed(~digits=2)
    | None => unrated
    }
  let provisional = (shown: bool, reliable: bool) =>
    shown && !reliable
      ? <span className="ml-1 text-[10px] font-medium uppercase tracking-wide text-amber-600 dark:text-amber-400">
          {(ts`provisional`)->React.string}
        </span>
      : React.null

  <div className={compact ? "flex items-baseline gap-3" : "flex items-baseline gap-4"}>
    <div className="flex items-baseline">
      <span
        className={(
          compact ? "text-lg" : "text-2xl"
        ) ++ " font-bold tabular-nums text-gray-900 dark:text-gray-100"}>
        {format(doubles)->React.string}
      </span>
      <span className="ml-1.5 text-xs uppercase tracking-wide text-gray-500 dark:text-gray-400">
        {(ts`doubles`)->React.string}
      </span>
      {provisional(doubles->Option.isSome, doublesReliable)}
    </div>
    {switch singles {
    | None => React.null
    | Some(_) =>
      <div className="flex items-baseline">
        <span className="text-sm font-semibold tabular-nums text-gray-600 dark:text-gray-300">
          {format(singles)->React.string}
        </span>
        <span className="ml-1.5 text-xs uppercase tracking-wide text-gray-500 dark:text-gray-400">
          {(ts`singles`)->React.string}
        </span>
        {provisional(singles->Option.isSome, singlesReliable)}
      </div>
    }}
  </div>
}
