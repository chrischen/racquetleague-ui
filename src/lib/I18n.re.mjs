// Generated by ReScript, PLEASE EDIT WITH CARE


function getBasePath(lang, pathname) {
  if (lang === "en") {
    return "/" + pathname.replace(new RegExp("^/(" + lang + "/?|)"), "");
  } else {
    return "/" + pathname.replace(new RegExp("^/" + lang + "/?"), "");
  }
}

function getLangPath(lang) {
  if (lang === "en") {
    return "";
  } else {
    return "/" + lang;
  }
}

export {
  getBasePath ,
  getLangPath ,
}
/* No side effect */