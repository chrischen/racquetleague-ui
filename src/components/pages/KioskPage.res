// The kiosk renders outside the app shell, so pull in the global stylesheet
// directly like other full-screen pages (e.g. EventManagerPage).
%%raw("import '../../global/static.css'")

@genType @react.component
let make = () => {
  <WaitForMessages> {() => <Kiosk />} </WaitForMessages>
}
