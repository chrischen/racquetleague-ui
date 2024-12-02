let getBasePath = (lang, pathname) => {
  switch lang {
  | "en" => "/" ++ pathname->String.replaceRegExp(Js.Re.fromString("^/(" ++ lang ++ "/?|)"), "")
  | lang => "/" ++ pathname->String.replaceRegExp(Js.Re.fromString("^/" ++ lang ++ "/?"), "")
  }
}

let getLangPath = lang => lang == "en" ? "" : "/" ++ lang
