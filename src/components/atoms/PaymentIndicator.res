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
      // The currency symbol says the spot is secured; its colour says whether
      // money has moved. Neutral: 0 = legacy hold, 5 = card on file (nothing
      // collected yet). Green: 1 = charged. Red: 3 = the organizer's charge
      // was declined (the card is still on file).
      switch status {
      | 1 =>
        <span
          title={t`Payment charged`}
          className="text-[10px] font-semibold text-green-500 dark:text-green-400 leading-none">
          {getCurrencySymbol(currency)->React.string}
        </span>
      | 0 | 5 =>
        <span
          title={status == 5 ? t`Card on file` : t`Payment authorized`}
          className="text-[10px] font-semibold text-gray-400 dark:text-gray-500 leading-none">
          {getCurrencySymbol(currency)->React.string}
        </span>
      | 3 =>
        <span
          title={t`Charge failed`}
          className="text-[10px] font-semibold text-red-500 dark:text-red-400 leading-none">
          {getCurrencySymbol(currency)->React.string}
        </span>
      | _ => React.null
      }}
  </WaitForMessages>
}
