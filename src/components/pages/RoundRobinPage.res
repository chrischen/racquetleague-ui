%%raw("import { t } from '@lingui/macro'")

@genType @react.component
let make = () => {
  <WaitForMessages> {() => <RoundRobin />} </WaitForMessages>
}
