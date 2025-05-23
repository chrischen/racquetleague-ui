// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Lingui from "../../locales/Lingui.re.mjs";
import * as Core__Option from "@rescript/core/src/Core__Option.re.mjs";
import * as LangProvider from "./LangProvider.re.mjs";
import * as LocaleDetector from "../../lib/LocaleDetector.re.mjs";
import * as Json$JsonCombinators from "@glennsl/rescript-json-combinators/src/Json.re.mjs";
import * as DetectLocale from "@lingui/detect-locale";
import * as Json_Decode$JsonCombinators from "@glennsl/rescript-json-combinators/src/Json_Decode.re.mjs";

function parse(json) {
  var decoder = Json_Decode$JsonCombinators.object(function (field) {
        return {
                lang: field.optional("lang", Json_Decode$JsonCombinators.string),
                locale: field.optional("locale", Json_Decode$JsonCombinators.string)
              };
      });
  try {
    return Json$JsonCombinators.decode(json, decoder);
  }
  catch (exn){
    return {
            TAG: "Error",
            _0: "An unexpected error occurred when checking the id."
          };
  }
}

var RouteParams = {
  parse: parse
};

var LoaderArgs = {};

async function loader(param) {
  var lang = Core__Option.getOr(param.params.lang, "en");
  var locale = lang === "ja" ? "jp" : "us";
  var tmp;
  if (import.meta.env.SSR) {
    var tmp$1 = lang === "ja" ? LocaleDetector.jaFallback : LocaleDetector.enFallback;
    tmp = DetectLocale.detect(DetectLocale.fromNavigator({
              language: lang
            }), tmp$1);
  } else {
    var tmp$2 = lang === "ja" ? LocaleDetector.jaFallback : LocaleDetector.enFallback;
    tmp = DetectLocale.detect(DetectLocale.fromNavigator(window.navigator), tmp$2).toLowerCase();
  }
  var detectedLocale = tmp;
  Lingui.i18n.activate(lang);
  var detectedLang = (function (__x) {
        return Core__Option.flatMap(__x, LangProvider.parseLang);
      })(detectedLocale);
  return {
          locale: locale,
          detectedLocale: (function (__x) {
                return Core__Option.flatMap(__x, LangProvider.parseLocale);
              })(detectedLocale),
          detectedLang: detectedLang,
          lang: lang,
          timezone: "Asia/Tokyo"
        };
}

var Component = LangProvider.make;

export {
  RouteParams ,
  LoaderArgs ,
  loader ,
  Component ,
}
/* Lingui Not a pure module */
