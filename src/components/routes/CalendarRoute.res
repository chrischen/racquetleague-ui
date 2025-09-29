@genType
let \"Component" = Calendar.make

let loadMessages = Lingui.loadMessages({
  en: Lingui.import("../../locales/src/components/organisms/Calendar.re/en"),
  ja: Lingui.import("../../locales/src/components/organisms/Calendar.re/ja"),
  th: Lingui.import("../../locales/src/components/organisms/Calendar.re/th"),
  zhTW: Lingui.import("../../locales/src/components/organisms/Calendar.re/zh-TW"),
  zhCN: Lingui.import("../../locales/src/components/organisms/Calendar.re/zh-CN"),
})
