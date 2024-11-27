%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")

@genType
let \"Component" = DefaultLayoutContentPage.make

let loadMessages = Lingui.loadMessages({
  ja: Lingui.import("../../locales/src/components/pages/DefaultLayoutContentPage.re/ja"),
  en: Lingui.import("../../locales/src/components/pages/DefaultLayoutContentPage.re/en"),
})
