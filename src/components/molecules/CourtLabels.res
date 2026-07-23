// Display-string builders for court metadata (surface mix, price, duration).
// Kept out of the pure TimeWindow model so that stays UI/i18n-free and
// unit-testable in bare Node.
//
// This module is deliberately i18n-free too: lingui catalogs are compiled per
// entry and loaded dynamically through the React tree, so every `t` macro call
// MUST live inside a React render function. Callers therefore pass in
// render-scoped translators and this module only owns the branching/joining
// logic.

// "3 indoor · 1 outdoor" / "2 indoor" / None. `indoor`/`outdoor` receive the
// count (already stringified) and return the localized part.
let surfaceMix = (
  summary: TimeWindow.courtAvailabilitySummary,
  ~indoor: string => string,
  ~outdoor: string => string,
): option<string> => {
  let parts: array<string> = []
  if summary.indoorCount > 0 {
    parts->Array.push(indoor(summary.indoorCount->Int.toString))
  }
  if summary.outdoorCount > 0 {
    parts->Array.push(outdoor(summary.outdoorCount->Int.toString))
  }
  parts->Array.length > 0 ? Some(parts->Array.join(" · ")) : None
}

// "¥500–¥1200" / "¥800" / None. Prices are whole yen; the currency symbol
// itself isn't translated, so no translator is needed here.
let priceRange = (summary: TimeWindow.courtAvailabilitySummary): option<string> =>
  switch (summary.priceLow, summary.priceHigh) {
  | (Some(low), Some(high)) =>
    Some(
      low == high
        ? "¥" ++ low->Int.toString
        : "¥" ++ low->Int.toString ++ "–¥" ++ high->Int.toString,
    )
  | _ => None
  }

// Compact duration: "2h 30m" / "2h" / "45m", built from the caller's localized
// templates (translators can reorder or replace the unit suffixes, e.g.
// "2時間30分"). The hour/minute counts arrive already stringified.
let duration = (
  hours: float,
  ~minutesOnly: string => string,
  ~hoursOnly: string => string,
  ~hoursMinutes: (string, string) => string,
): string => {
  let h = hours->Js.Math.floor_int
  let m = Js.Math.round((hours -. h->Float.fromInt) *. 60.0)->Float.toInt
  let hs = h->Int.toString
  let ms = m->Int.toString
  if h == 0 {
    minutesOnly(ms)
  } else if m == 0 {
    hoursOnly(hs)
  } else {
    hoursMinutes(hs, ms)
  }
}
