%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")

@genType
let \"Component" = DefaultLayoutContentPage.make

let loadMessages = Lingui.loadMessages({
  en: Lingui.import("../../locales/src/components/pages/DefaultLayoutContentPage.re/en"),
  ja: Lingui.import("../../locales/src/components/pages/DefaultLayoutContentPage.re/ja"),
  th: Lingui.import("../../locales/src/components/pages/DefaultLayoutContentPage.re/th"),
  zhTW: Lingui.import("../../locales/src/components/pages/DefaultLayoutContentPage.re/zh-TW"),
  zhCN: Lingui.import("../../locales/src/components/pages/DefaultLayoutContentPage.re/zh-CN"),
})
