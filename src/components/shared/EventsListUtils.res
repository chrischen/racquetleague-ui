let dayMs = 86400000.

let getDayName = (i: int): string =>
  switch i {
  | 0 => "Sun"
  | 1 => "Mon"
  | 2 => "Tue"
  | 3 => "Wed"
  | 4 => "Thu"
  | 5 => "Fri"
  | 6 => "Sat"
  | _ => "?"
  }

let getMonthName = (i: int): string =>
  switch i {
  | 0 => "Jan"
  | 1 => "Feb"
  | 2 => "Mar"
  | 3 => "Apr"
  | 4 => "May"
  | 5 => "Jun"
  | 6 => "Jul"
  | 7 => "Aug"
  | 8 => "Sep"
  | 9 => "Oct"
  | 10 => "Nov"
  | 11 => "Dec"
  | _ => "?"
  }



let getFullDayName = (i: int): string =>
  switch i {
  | 0 => "Sunday"
  | 1 => "Monday"
  | 2 => "Tuesday"
  | 3 => "Wednesday"
  | 4 => "Thursday"
  | 5 => "Friday"
  | 6 => "Saturday"
  | _ => "?"
  }

type bucketSetup = {
  todayStartMs: float,
  dateFromOffset: float => Js.Date.t,
  weekendBucketKey: string,
  nextWeekStartOffset: int,
  nextWeekEndOffset: int,
}

let makeBucketSetup = (): bucketSetup => {
  let now = Js.Date.make()
  let nowMs = now->Js.Date.getTime
  let localOffsetMs = now->Js.Date.getTimezoneOffset *. 60000.
  let todayStartLocalMs = Math.floor((nowMs -. localOffsetMs) /. dayMs) *. dayMs
  let todayStartMs = todayStartLocalMs +. localOffsetMs
  let dateFromOffset = (days: float): Js.Date.t =>
    Js.Date.fromFloat(todayStartLocalMs +. days *. dayMs +. localOffsetMs)
  let dayOfWeekF = now->Js.Date.getDay
  let nextWeekStartOffset = if dayOfWeekF == 0. {
    1
  } else {
    8 - dayOfWeekF->Float.toInt
  }
  let nextWeekEndOffset = nextWeekStartOffset + 6
  let dayOfWeekI = dayOfWeekF->Float.toInt
  let daysToSat = 6 - dayOfWeekI
  let weekendBucketKey = if dayOfWeekI == 0 || dayOfWeekI == 6 {
    "today"
  } else if daysToSat == 1 {
    "tomorrow"
  } else {
    Int.toString(daysToSat)
  }
  {todayStartMs, dateFromOffset, weekendBucketKey, nextWeekStartOffset, nextWeekEndOffset}
}

let getBucketKey = (~setup: bucketSetup, eventMs: float): string => {
  let dayDiff = Math.floor((eventMs -. setup.todayStartMs) /. dayMs)
  if dayDiff == 0. {
    "today"
  } else if dayDiff == 1. {
    "tomorrow"
  } else {
    Int.toString(dayDiff->Float.toInt)
  }
}

// Pure version — labels must be provided by caller (from render context) via getBucketLabel below.
// Returns (isNextWeek, dayIndex, date) for use when building bucket metadata.
// dayIndex is 0=Sun..6=Sat. Callers must translate the day name and "Next" prefix.
// date is the raw Js.Date.t so callers can format it with ReactIntl.
let getBucketDateDetails = (~setup: bucketSetup, key: string): (bool, int, Js.Date.t) => {
  let n = key->Int.fromString->Option.getOr(0)
  let date = setup.dateFromOffset(n->Int.toFloat)
  let dayIndex = date->Js.Date.getDay->Float.toInt
  let isNextWeek = n >= setup.nextWeekStartOffset && n <= setup.nextWeekEndOffset
  (isNextWeek, dayIndex, date)
}

// Returns all bucket keys in chronological order (past → today → tomorrow → future).
// Always includes "today" and "tomorrow" in the output; callers should filterMap
// against their event dict to skip missing buckets.
let sortBucketKeys = (keys: array<string>): array<string> => {
  let otherKeys =
    keys
    ->Array.filter(k => k != "today" && k != "tomorrow")
    ->Array.toSorted((a, b) =>
      Float.fromInt(a->Int.fromString->Option.getOr(0) - b->Int.fromString->Option.getOr(0))
    )
  let pastKeys = otherKeys->Array.filter(k => k->Int.fromString->Option.getOr(0) < 0)
  let futureKeys = otherKeys->Array.filter(k => k->Int.fromString->Option.getOr(0) >= 2)
  [...pastKeys, "today", "tomorrow", ...futureKeys]
}

module Filter = {
  type t = ByDate(Js.Date.t) | ByAfter(string) | ByBefore(string) | ByAfterDate(Js.Date.t)
  let updateParams = (filter, params) =>
    switch filter {
    | ByAfter(cursor) =>
      params->Router.ImmSearchParams.set("after", cursor)->Router.ImmSearchParams.delete("before")
    | ByBefore(cursor) =>
      params->Router.ImmSearchParams.set("before", cursor)->Router.ImmSearchParams.delete("after")
    | ByDate(date) => params->Router.ImmSearchParams.set("selectedDate", date->Js.Date.toDateString)
    | ByAfterDate(date) =>
      params->Router.ImmSearchParams.set("afterDate", date->Js.Date.toISOString)
    }
}

let bucketEvents = (
  ~setup: bucketSetup,
  ~getStartDate: 'a => option<Util.Datetime.t>,
  ~filterByDate: option<Js.Date.t>,
  events: array<'a>,
): Js.Dict.t<array<'a>> => {
  let dict: Js.Dict.t<array<'a>> = Js.Dict.empty()
  events->Array.forEach(event => {
    getStartDate(event)->Option.forEach(startDate => {
      let eventMs = startDate->Util.Datetime.toDate->Js.Date.getTime
      let shouldInclude = switch filterByDate {
      | None => true
      | Some(f) => eventMs > f->Js.Date.getTime
      }
      if shouldInclude {
        let key = getBucketKey(~setup, eventMs)
        switch dict->Js.Dict.get(key) {
        | None => dict->Js.Dict.set(key, [event])
        | Some(existing) => dict->Js.Dict.set(key, [...existing, event])
        }
      }
    })
  })
  dict
}

let scrollToGroup: string => unit = %raw(`function(key) {
  var el = document.getElementById("bucket-" + key);
  if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' });
}`)
