# Syncs back translations in the master compendium into the component/entrypoint message bundles.
find src/locales/src/components -name "en.pot" -type f -exec msgmerge --compendium src/locales/en.po /dev/null {} -o {} \;
find src/locales/src/components -name "ja.po" -type f -exec msgmerge --compendium src/locales/ja.po /dev/null {} -o {} \;
find src/locales/src/components -name "th.po" -type f -exec msgmerge --compendium src/locales/th.po /dev/null {} -o {} \;
find src/locales/src/components -name "zh-TW.po" -type f -exec msgmerge --compendium src/locales/zh-TW.po /dev/null {} -o {} \;
find src/locales/src/components -name "zh-CN.po" -type f -exec msgmerge --compendium src/locales/zh-CN.po /dev/null {} -o {} \;
