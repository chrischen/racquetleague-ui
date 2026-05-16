type paymentStatus =
  | Captured
  | Authorized
  | Paid

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
let make = (~status: paymentStatus, ~currency: option<string>=?) => {
  switch (status, currency) {
  | (Captured, Some(currency)) | (Authorized, Some(currency)) =>
    <span
      title={status == Captured ? "Payment captured" : "Payment authorized"}
      className="text-[10px] font-semibold text-green-500 dark:text-green-400 leading-none">
      {getCurrencySymbol(currency)->React.string}
    </span>
  | (Paid, _) =>
    <span
      title="Paid"
      className="text-[10px] font-semibold text-green-500 dark:text-green-400 leading-none">
      {"✓"->React.string}
    </span>
  | (Captured | Authorized, None) => React.null
  }
}
