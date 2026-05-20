%%raw("import { t } from '@lingui/macro'")

module Fragment = %relay(`
  fragment PaymentIndicator_payment on Payment {
    status
    currency
  }
`)

let getCurrencySymbol = (currency: string) => {
  switch currency->String.toLowerCase {
  | "usd" => "$"
  | "jpy" => "¥"
  | "eur" => "€"
  | "gbp" => "£"
  | "cny" => "¥"
  | "krw" => "₩"
  | "thb" => "฿"
  | "vnd" => "₫"
  | "sgd" => "S$"
  | "hkd" => "HK$"
  | "twd" => "NT$"
  | "aud" => "A$"
  | "cad" => "C$"
  | _ => currency->String.toUpperCase
  }
}

@react.component
let make = (~payment) => {
  open Lingui.UtilString
  let {status, currency} = Fragment.use(payment)
  <WaitForMessages>
    {() =>
      switch status {
      | 0 | 1 =>
        <span
          title={status == 1 ? t`Payment captured` : t`Payment authorized`}
          className="text-[10px] font-semibold text-green-500 dark:text-green-400 leading-none">
          {getCurrencySymbol(currency)->React.string}
        </span>
      | _ => React.null
      }}
  </WaitForMessages>
}
