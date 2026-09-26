/* @variadic @val external cx: array<string> => string = "cx" */
@variadic @module("@linaria/core") external cx: array<string> => string = "cx"

type inlineScript = {
  @as("type")
  type_: string,
  innerHTML: string,
}
module Helmet = {
  @module("react-helmet-async") @react.component
  external make: (
    ~children: React.element,
    ~script: option<array<inlineScript>>=?,
  ) => React.element = "Helmet"
}

@live
module Datetime: {
  /** A date. */
  @gql.scalar
  type t

  let parse: Js.Json.t => t
  let serialize: t => Js.Json.t
  let fromDate: Date.t => t
  let toDate: t => Date.t
} = {
  type t = Date.t

  let fromDate = d => d
  let parse = d => d->Json.decode(Json.Decode.string)->Result.map(Date.fromString)->Result.getExn

  let serialize = d => Json.Encode.string(d->Date.toString)
  let toDate = d => d
}

// Event times are entered as wall-clock values in the event's IANA zone. These
// convert between that and absolute instants without a tz library, using Intl,
// which Node and every browser ship with full zone data. Plain JS via %raw, as
// TimeWindow.hourInTimeZone does: the formatToParts round trip is clearer
// there than through the Core Intl variants.
@live
module Timezone = {
  // The app's display convention when an event carries no zone.
  let fallback = "Asia/Tokyo"

  // The runtime's own zone — the browser's on the client.
  let browser: unit => string = %raw(`function () {
    try {
      return Intl.DateTimeFormat().resolvedOptions().timeZone || "Asia/Tokyo"
    } catch (e) {
      return "Asia/Tokyo"
    }
  }`)

  // Every IANA zone the runtime knows. Browser and Node lists can differ, so
  // only read this on the client when the result is rendered.
  let list: unit => array<string> = %raw(`function () {
    try {
      return Intl.supportedValuesOf("timeZone")
    } catch (e) {
      return ["Asia/Tokyo", "UTC"]
    }
  }`)

  // A zone Intl accepts, else the runtime's own: drafts and stored rows can
  // carry names like "JST" that are not IANA zones and would throw.
  let normalize: string => string = %raw(`function (tz) {
    try {
      new Intl.DateTimeFormat("en-US", { timeZone: tz })
      return tz
    } catch (e) {
      try {
        return Intl.DateTimeFormat().resolvedOptions().timeZone || "Asia/Tokyo"
      } catch (e2) {
        return "Asia/Tokyo"
      }
    }
  }`)

  // Wall-clock reading of an instant in a zone, as "yyyy-MM-ddTHH:mm".
  let toWallClock: (Date.t, string) => string = %raw(`function (date, tz) {
    var parts = new Intl.DateTimeFormat("en-US", {
      timeZone: normalize(tz), hourCycle: "h23",
      year: "numeric", month: "2-digit", day: "2-digit", hour: "2-digit", minute: "2-digit"
    }).formatToParts(date)
    var p = {}
    parts.forEach(function (x) { p[x.type] = x.value })
    var hour = p.hour === "24" ? "00" : p.hour
    return p.year + "-" + p.month + "-" + p.day + "T" + hour + ":" + p.minute
  }`)

  // The instant at which a zone's wall clock reads "yyyy-MM-ddTHH:mm". Treat
  // the value as UTC, measure the zone's offset there, and correct; near a DST
  // change the offset at the corrected instant can differ, so it is read once
  // more and kept only if that instant really reads as the requested time. A
  // wall time inside a spring-forward gap never does, and resolves forward.
  let fromWallClock: (string, string) => Date.t = %raw(`function (wallClock, tz) {
    var f = wallClock.split(/[-T:]/)
    if (f.length < 5) return new Date(NaN)
    tz = normalize(tz)
    var asUtc = Date.UTC(+f[0], +f[1] - 1, +f[2], +f[3], +f[4])
    var offsetAt = function (ts) {
      var parts = new Intl.DateTimeFormat("en-US", {
        timeZone: tz, hourCycle: "h23",
        year: "numeric", month: "2-digit", day: "2-digit",
        hour: "2-digit", minute: "2-digit", second: "2-digit"
      }).formatToParts(new Date(ts))
      var p = {}
      parts.forEach(function (x) { p[x.type] = x.value })
      var hour = p.hour === "24" ? 0 : +p.hour
      return Date.UTC(+p.year, +p.month - 1, +p.day, hour, +p.minute, +p.second) - ts
    }
    var offset = offsetAt(asUtc)
    var ts = asUtc - offset
    var offset2 = offsetAt(ts)
    if (offset2 !== offset) {
      var corrected = asUtc - offset2
      // Spring-forward always raises the offset, so the smaller of the two
      // offsets is the pre-change one and gives the instant just past the gap.
      ts = offsetAt(corrected) === offset2 ? corrected : asUtc - Math.min(offset, offset2)
    }
    return new Date(ts)
  }`)

  // Short zone label at an instant, e.g. "GMT+9" or "PDT"; the zone id itself
  // when Intl can't format it (unknown zone, invalid date).
  let shortName: (string, Date.t) => string = %raw(`function (tz, date) {
    try {
      var parts = new Intl.DateTimeFormat("en-US", { timeZone: tz, timeZoneName: "short" })
        .formatToParts(date)
      var part = parts.find(function (x) { return x.type === "timeZoneName" })
      return part ? part.value : tz
    } catch (e) {
      return tz
    }
  }`)
}

@module("react")
external startTransition: (unit => unit) => unit = "startTransition"

@val external encodeURIComponent: string => string = "encodeURIComponent"

@val external encodeURI: string => string = "encodeURI"

module NonEmptyArray = {
  type t<'a> = option<array<'a>>
  let map = (arr: t<'a>, f: 'a => 'b): t<'b> => arr->Option.map(Array.map(_, f))
  let mapWithIndex: (t<'a>, ('a, int) => 'b) => t<'b> = (arr, f) => arr->Option.map(Array.mapWithIndex(_, f))
  let toArray = (arr: t<'a>): array<'a> => arr->Option.getOr([])
  let fromArray = (arr: array<'a>): t<'a> => arr->Array.length == 0 ? None : Some(arr)
  let empty = None
  let pure = x => Some([x])
  let concat = (a: t<'a>, b: t<'a>): t<'a> =>
    switch (a, b) {
    | (Some(a), Some(b)) => Some(a->Array.concat(b))
    | _ => b
    }
  let flatMap = (arr: t<'a>, f: 'a => t<'b>): t<'b> =>
    switch arr {
    | Some(arr) =>
      switch arr
      ->Array.map(i => f(i))
      ->Array.reduce([], (acc, x) =>
        switch x {
        | Some(x) => acc->Array.concat(x)
        | None => acc
        }
      ) {
      | [] => None
      | arr => Some(arr)
      }
    | None => None
    }
  let toSet: t<'a> => Set.t<'a> = arr => arr->Option.getOr([])->Set.fromArray
  let filter: (t<'a>, 'a => bool) => t<'a> = (arr, f) =>
    switch arr {
    | Some(arr) =>
      (
        arr =>
          switch arr {
          | [] => None
          | arr => Some(arr)
          }
      )(arr->Array.filter(f))

    | None => None
    }
  let filterWithIndex: (t<'a>, ('a, int) => bool) => t<'a> = (arr, f) =>
    switch arr {
    | Some(arr) =>
      arr
      ->Array.filterWithIndex(f)
      ->(
        arr =>
          switch arr {
          | [] => None
          | arr => Some(arr)
          }
      )

    | None => None
    }
}

module JsSet = {
  type t<'a> = Set.t<'a>;

  @send
  external difference: (t<'a>, t<'a>) => t<'a> = "difference"
}

// Stand-in for the design's per-club brand color: stable per club id, so a club
// keeps the same dot in the sidebar and in the clubs listing.
module ClubDot = {
  let palette = [
    "bg-emerald-500",
    "bg-blue-500",
    "bg-violet-500",
    "bg-amber-500",
    "bg-rose-500",
    "bg-cyan-500",
    "bg-lime-500",
    "bg-fuchsia-500",
  ]

  let color = (id: string) => {
    let sum =
      id
      ->String.split("")
      ->Array.reduce(0, (acc, char) => acc + char->String.charCodeAt(0)->Float.toInt)
    palette->Array.get(mod(sum, palette->Array.length))->Option.getOr("bg-gray-400")
  }
}

module NonZeroInt: {
  type t = private option<int>;
  let make: int => t;
  let toOption: t => option<int>;
} = {
  type t = option<int>;
  let make = n =>
    if (n == 0) {
      None
    } else {
      Some(n)
    }
    let toOption = n => (n :> option<int>)
}

// The site an external link belongs to, named from its address:
// "toyosu.picklr.jp" -> "Picklr". The label before the public suffix,
// capitalised; the whole host when that fails.
let externalSource: string => string = %raw(`function (u) {
  var host;
  try { host = new URL(u).hostname.replace(/^www\./, ""); } catch (e) { return u; }
  var parts = host.split(".");
  var twoPart = /\.(co|com|ne|or|ac|go|net|org)\.[a-z]{2}$/.test(host);
  var label = parts[parts.length - (twoPart ? 3 : 2)] || host;
  return label.charAt(0).toUpperCase() + label.slice(1);
}`)
