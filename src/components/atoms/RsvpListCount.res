%%raw("import { t } from '@lingui/macro'")

@react.component
let make = (~count: int, ~max: option<int>=?) => {
  <>
    {" ("->React.string}
    {count->Int.toString->React.string}
    {max
    ->Option.map(max => `/${max->Int.toString}`)
    ->Option.getOr("")
    ->React.string}
    {")"->React.string}
  </>
}
