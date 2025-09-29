# #!/bin/zsh
# This takes the component/entrypoint message bundles and merges them into the
# master PO file that is used by the translation management software.
# If components are updated, merge to update translations that need to be done.
msgcat --use-first -o src/locales/en.pot src/locales/en.pot src/locales/src/**/en.po
msgcat --use-first -o src/locales/ja.po src/locales/ja.po src/locales/src/**/ja.po
msgcat --use-first -o src/locales/th.po src/locales/th.po src/locales/src/**/th.po
msgcat --use-first -o src/locales/zh-TW.po src/locales/zh-TW.po src/locales/src/**/zh-TW.po
msgcat --use-first -o src/locales/zh-CN.po src/locales/zh-CN.po src/locales/src/**/zh-CN.po