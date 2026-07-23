// Extracts the viewer's RSVP events into per-local-date timeline entries,
// keyed by ISO date (YYYY-MM-DD). Each event's hour span is resolved in its
// OWN timezone via `intl` so the amber event boxes line up with the local hour
// axis of the picker/grid. An event whose end wraps past midnight gets +24h so
// [startHour, endHour) stays a half-open interval.
//
// Callers map their Relay-generated event node (whichever query it came from)
// to the plain `rawEvent` record, so AvailabilityPage (weekly grid) and
// PkEventsAvailabilityDay (inline picker) render identical event windows from
// one implementation.

type rawEvent = {
  id: string,
  title: option<string>,
  startDate: option<Util.Datetime.t>,
  endDate: option<Util.Datetime.t>,
  timezone: option<string>,
}

let byDate = (
  intl: ReactIntl.Intl.t,
  events: array<rawEvent>,
): Js.Dict.t<array<TimeWindowPicker.existingEvent>> =>
  events->Array.reduce(Js.Dict.empty(), (acc, node) => {
    switch (node.startDate, node.endDate) {
    | (Some(startDt), Some(endDt)) =>
      let tz = node.timezone->Option.getOr("Asia/Tokyo")
      let startDate = startDt->Util.Datetime.toDate
      let endDate = endDt->Util.Datetime.toDate
      let opts = ReactIntl.dateTimeFormatOptions(
        ~year=#numeric,
        ~month=#"2-digit",
        ~day=#"2-digit",
        ~hour=#"2-digit",
        ~hour12=false,
        ~timeZone=tz,
        (),
      )
      let parts = intl->ReactIntl.Intl.formatDateWithOptionsToParts(startDate, opts)
      let getVal = t =>
        parts
        ->Array.find(p => p.ReactIntl.type_ === t)
        ->Option.map(p => p.ReactIntl.value)
        ->Option.getOr("0")
      let isoDate = getVal("year") ++ "-" ++ getVal("month") ++ "-" ++ getVal("day")
      let startHour = getVal("hour")->Int.fromString->Option.getOr(0)->Float.fromInt
      let endHour =
        intl
        ->ReactIntl.Intl.formatDateWithOptionsToParts(endDate, opts)
        ->Array.find(p => p.ReactIntl.type_ === "hour")
        ->Option.map(p => p.ReactIntl.value)
        ->Option.getOr("0")
        ->Int.fromString
        ->Option.getOr(0)
        ->Float.fromInt
      let ev: TimeWindowPicker.existingEvent = {
        id: node.id,
        title: node.title->Option.getOr(""),
        startHour,
        endHour: endHour <= startHour ? endHour +. 24.0 : endHour,
      }
      let existing = acc->Js.Dict.get(isoDate)->Option.getOr([])
      acc->Js.Dict.set(isoDate, Belt.Array.concat(existing, [ev]))
      acc
    | _ => acc
    }
  })
