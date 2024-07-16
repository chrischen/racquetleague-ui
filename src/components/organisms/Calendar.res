%%raw("import { t } from '@lingui/macro'")


@react.component
let make = () => {
  Js.log("Render")
  let data = Events.useFragmentRefs();
  // <WaitForMessages>
  //   {_ => {
      Js.log("Loader data");
      Js.log(data);
      "CALENDAR"->React.string
  //   }}
  // </WaitForMessages>
}
