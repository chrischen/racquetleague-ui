// ReScript face of felicaReader.ts: a Sony RC-S300 read over WebUSB for
// FeliCa (Suica, PASMO, nanaco, …) card IDs. Chrome-family browsers only.

type device

type card = {
  idm: string, // 16 hex digits
  pmm: string,
  systemCode: Nullable.t<string>, // "0003" = transit IC
}

@module("./felicaReader") external isSupported: unit => bool = "isSupported"
@module("./felicaReader")
external grantedReaderRaw: unit => promise<Nullable.t<device>> = "grantedReader"
// Must be called from a user gesture (it opens the browser's device chooser).
@module("./felicaReader") external requestReader: unit => promise<device> = "requestReader"
@get external productName: device => Nullable.t<string> = "productName"

type abortController
type abortSignal
@new external makeAbortController: unit => abortController = "AbortController"
@get external signal: abortController => abortSignal = "signal"
@send external abort: abortController => unit = "abort"

@module("./felicaReader")
external watchCards: (device, card => unit, abortSignal) => promise<unit> = "watchCards"

let grantedReader = async () => (await grantedReaderRaw())->Nullable.toOption

let errorMessage = exn =>
  exn->Js.Exn.asJsExn->Option.flatMap(e => Js.Exn.message(e))->Option.getOr("reader error")

// "0123456789ABCDEF" -> "0123 4567 89AB CDEF"
let groupIdm = (idm: string) =>
  [0, 4, 8, 12]
  ->Array.map(i => idm->String.slice(~start=i, ~end=i + 4))
  ->Array.filter(s => s != "")
  ->Array.join(" ")

// What a polled system code usually means (polling asks for the card's
// primary system; multi-application cards report their first one).
let describeSystem = (code: option<string>) =>
  switch code {
  | Some("0003") => "Transit IC (Suica, PASMO, ICOCA, …)"
  | Some("FE00") => "Common area (Edy, nanaco, WAON, …)"
  | Some("88B4") => "FeliCa Lite-S"
  | Some("12FC") => "NFC Type 3 (NDEF)"
  | Some(other) => "System code " ++ other
  | None => "FeliCa"
  }

// Subscribe to a granted RC-S300 being plugged in; returns an unsubscribe.
@module("./felicaReader")
external onReaderConnected: (device => unit) => (unit => unit) = "onReaderConnected"
