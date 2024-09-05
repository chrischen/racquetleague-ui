%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

module Fragment = %relay(`
  fragment NavViewer_viewer on Viewer {
    user {
      lineUsername
      picture
    }
  }
`)
// module Fragment2 = %relay(`
//   fragment NavViewer_query on Query {
//     viewer {
//       user {
//         lineUsername
//         picture
//       }
//     }
//   }
// `)

@genType @react.component
let make = (~viewer) => {
  open Dropdown;
  open Navbar;
  let {user} = Fragment.use(viewer)
  <WaitForMessages>
    {() =>
      user->Option.map(user =>
        <Dropdown>
          <DropdownButton \"as"={NavbarItem.make}>
            {user.lineUsername->Option.getOr("")->React.string}
            <Avatar src=?user.picture square=true />
          </DropdownButton>
          <DropdownMenu className="min-w-64" anchor="bottom end">
            <DropdownItem href="/events">
              // <HeroIcons.UserIcon />
              <DropdownLabel> {t`My Events`} </DropdownLabel>
            </DropdownItem>
            // <DropdownItem href="/settings">
            //   <HeroIcons.Cog6Tooth />
            //   <DropdownLabel> {t`Settings`} </DropdownLabel>
            // </DropdownItem>
            <DropdownDivider />
            // <DropdownItem href="/privacy-policy">
            //   // <ShieldCheckIcon />
            //   <DropdownLabel> {t`Privacy Policy`} </DropdownLabel>
            // </DropdownItem>
            // <DropdownItem href="/share-feedback">
            //   // <LightBulbIcon />
            //   <DropdownLabel> {t`Share Feedback`} </DropdownLabel>
            // </DropdownItem>
            // <DropdownDivider />
            <DropdownItem>
              // <ArrowRightStartOnRectangleIcon />
              <DropdownLabel>
                <LogoutLink />
              </DropdownLabel>
            </DropdownItem>
          </DropdownMenu>
        </Dropdown>
      )->Option.getOr(<LoginLink />)}
  </WaitForMessages>
}

@genType
let default = make
