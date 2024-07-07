// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Caml_obj from "rescript/lib/es6/caml_obj.js";
import * as Core__Option from "@rescript/core/src/Core__Option.re.mjs";
import * as JsxRuntime from "react/jsx-runtime";
import * as Solid from "@heroicons/react/24/solid";

import { t } from '@lingui/macro'
;

function Form$PrefixedInput(props) {
  var defaultValue = props.defaultValue;
  var value = props.value;
  var register = props.register;
  var onBlur = props.onBlur;
  var placeholder = props.placeholder;
  var autoComplete = props.autoComplete;
  var __type_ = props.type_;
  var id = props.id;
  var name = props.name;
  var className = props.className;
  var type_ = __type_ !== undefined ? __type_ : "text";
  var tmp;
  if (register !== undefined) {
    var newrecord = Caml_obj.obj_dup(register);
    tmp = JsxRuntime.jsx("input", (newrecord.onBlur = onBlur, newrecord.value = value, newrecord.type = type_, newrecord.placeholder = placeholder, newrecord.autoComplete = autoComplete, newrecord.id = id, newrecord.className = Core__Option.getOr(className, "block flex-1 border-0 bg-transparent py-1.5 pl-1 text-gray-900 placeholder:text-gray-400 focus:ring-0 sm:text-sm sm:leading-6"), newrecord.defaultValue = defaultValue, newrecord));
  } else {
    tmp = JsxRuntime.jsx("input", {
          defaultValue: defaultValue,
          className: Core__Option.getOr(className, "block flex-1 border-0 bg-transparent py-1.5 pl-1 text-gray-900 placeholder:text-gray-400 focus:ring-0 sm:text-sm sm:leading-6"),
          id: id,
          autoComplete: autoComplete,
          name: name,
          placeholder: placeholder,
          type: type_,
          value: value,
          onBlur: onBlur,
          onChange: props.onChange
        });
  }
  return JsxRuntime.jsxs(JsxRuntime.Fragment, {
              children: [
                JsxRuntime.jsx("label", {
                      children: props.label,
                      className: "block text-sm font-medium leading-6 text-gray-900",
                      htmlFor: name
                    }),
                JsxRuntime.jsx("div", {
                      children: JsxRuntime.jsxs("div", {
                            children: [
                              JsxRuntime.jsx("span", {
                                    children: props.prefix,
                                    className: "flex select-none items-center pl-3 text-gray-500 sm:text-sm"
                                  }),
                              tmp
                            ],
                            className: "flex rounded-md shadow-sm ring-1 ring-inset ring-gray-300 focus-within:ring-2 focus-within:ring-inset focus-within:ring-indigo-600 sm:max-w-md"
                          }),
                      className: "mt-2"
                    })
              ]
            });
}

var PrefixedInput = {
  make: Form$PrefixedInput
};

function Form$Input(props) {
  var defaultValue = props.defaultValue;
  var value = props.value;
  var register = props.register;
  var onBlur = props.onBlur;
  var placeholder = props.placeholder;
  var autoComplete = props.autoComplete;
  var __type_ = props.type_;
  var id = props.id;
  var name = props.name;
  var className = props.className;
  var type_ = __type_ !== undefined ? __type_ : "text";
  var tmp;
  if (register !== undefined) {
    var newrecord = Caml_obj.obj_dup(register);
    tmp = JsxRuntime.jsx("input", (newrecord.onBlur = onBlur, newrecord.value = value, newrecord.type = type_, newrecord.placeholder = placeholder, newrecord.autoComplete = autoComplete, newrecord.id = id, newrecord.className = Core__Option.getOr(className, "block flex-1 border-0 bg-transparent py-1.5 pl-1 text-gray-900 placeholder:text-gray-400 focus:ring-0 sm:text-sm sm:leading-6"), newrecord.defaultValue = defaultValue, newrecord));
  } else {
    tmp = JsxRuntime.jsx("input", {
          defaultValue: defaultValue,
          className: Core__Option.getOr(className, "block flex-1 border-0 bg-transparent py-1.5 pl-1 text-gray-900 placeholder:text-gray-400 focus:ring-0 sm:text-sm sm:leading-6"),
          id: id,
          autoComplete: autoComplete,
          name: name,
          placeholder: placeholder,
          type: type_,
          value: value,
          onBlur: onBlur,
          onChange: props.onChange
        });
  }
  return JsxRuntime.jsxs(JsxRuntime.Fragment, {
              children: [
                JsxRuntime.jsx("label", {
                      children: props.label,
                      className: "block text-sm font-medium leading-6 text-gray-900",
                      htmlFor: name
                    }),
                JsxRuntime.jsx("div", {
                      children: JsxRuntime.jsxs("div", {
                            children: [
                              JsxRuntime.jsx("span", {
                                    className: "flex select-none items-center pl-3 text-gray-500 sm:text-sm"
                                  }),
                              tmp
                            ],
                            className: "flex rounded-md shadow-sm ring-1 ring-inset ring-gray-300 focus-within:ring-2 focus-within:ring-inset focus-within:ring-indigo-600"
                          }),
                      className: "mt-2"
                    })
              ]
            });
}

var Input = {
  make: Form$Input
};

function Form$Select(props) {
  var defaultValue = props.defaultValue;
  var register = props.register;
  var options = props.options;
  var id = props.id;
  var name = props.name;
  var className = props.className;
  var tmp;
  if (register !== undefined) {
    var newrecord = Caml_obj.obj_dup(register);
    tmp = JsxRuntime.jsx("select", (newrecord.name = name, newrecord.id = id, newrecord.className = Core__Option.getOr(className, "mt-2 block w-full rounded-md border-0 py-1.5 pl-3 pr-10 text-gray-900 ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-indigo-600 sm:text-sm sm:leading-6"), newrecord.defaultValue = defaultValue, newrecord.children = options.map(function (param) {
                var value = param[1];
                return JsxRuntime.jsx("option", {
                            children: param[0],
                            value: value
                          }, value);
              }), newrecord));
  } else {
    tmp = JsxRuntime.jsx("select", {
          children: options.map(function (param) {
                return JsxRuntime.jsx("option", {
                            children: param[0],
                            value: param[1]
                          });
              }),
          defaultValue: defaultValue,
          className: Core__Option.getOr(className, "mt-2 block w-full rounded-md border-0 py-1.5 pl-3 pr-10 text-gray-900 ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-indigo-600 sm:text-sm sm:leading-6"),
          id: id,
          name: name
        });
  }
  return JsxRuntime.jsxs(JsxRuntime.Fragment, {
              children: [
                JsxRuntime.jsx("label", {
                      children: props.label,
                      className: "block text-sm font-medium leading-6 text-gray-900",
                      htmlFor: name
                    }),
                tmp
              ]
            });
}

var Select = {
  make: Form$Select
};

var PhotoIcon = {};

function Form$TextArea(props) {
  var register = props.register;
  var disabled = props.disabled;
  var defaultValue = props.defaultValue;
  var __rows = props.rows;
  var id = props.id;
  var name = props.name;
  var rows = __rows !== undefined ? __rows : 3;
  var tmp;
  if (register !== undefined) {
    var newrecord = Caml_obj.obj_dup(register);
    tmp = JsxRuntime.jsx("textarea", (newrecord.rows = rows, newrecord.name = name, newrecord.disabled = disabled, newrecord.id = id, newrecord.className = "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6", newrecord.defaultValue = defaultValue, newrecord));
  } else {
    tmp = JsxRuntime.jsx("textarea", {
          defaultValue: defaultValue,
          className: "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6",
          id: id,
          disabled: disabled,
          name: name,
          rows: rows,
          value: props.value
        });
  }
  return JsxRuntime.jsxs(JsxRuntime.Fragment, {
              children: [
                JsxRuntime.jsx("label", {
                      children: props.label,
                      className: "block text-sm font-medium leading-6 text-gray-900",
                      htmlFor: "about"
                    }),
                JsxRuntime.jsx("div", {
                      children: tmp,
                      className: "mt-2"
                    }),
                Core__Option.getOr(Core__Option.map(props.hint, (function (hint) {
                            return JsxRuntime.jsx("p", {
                                        children: hint,
                                        className: "mt-3 text-sm leading-6 text-gray-600"
                                      });
                          })), null)
              ]
            });
}

var TextArea = {
  make: Form$TextArea
};

function Form$ImageUpload(props) {
  return JsxRuntime.jsxs(JsxRuntime.Fragment, {
              children: [
                JsxRuntime.jsx("label", {
                      children: t`cover photo`,
                      className: "block text-sm font-medium leading-6 text-gray-900",
                      htmlFor: "cover-photo"
                    }),
                JsxRuntime.jsx("div", {
                      children: JsxRuntime.jsxs("div", {
                            children: [
                              JsxRuntime.jsx(Solid.PhotoIcon, {
                                    className: "mx-auto h-12 w-12 text-gray-300",
                                    "aria-hidden": "true"
                                  }),
                              JsxRuntime.jsxs("div", {
                                    children: [
                                      JsxRuntime.jsxs("label", {
                                            children: [
                                              JsxRuntime.jsx("span", {
                                                    children: t`Upload a file`
                                                  }),
                                              JsxRuntime.jsx("input", {
                                                    className: "sr-only",
                                                    id: "file-upload",
                                                    name: "file-upload",
                                                    type: "file"
                                                  })
                                            ],
                                            className: "relative cursor-pointer rounded-md bg-white font-semibold text-indigo-600 focus-within:outline-none focus-within:ring-2 focus-within:ring-indigo-600 focus-within:ring-offset-2 hover:text-indigo-500",
                                            htmlFor: "file-upload"
                                          }),
                                      JsxRuntime.jsx("p", {
                                            children: t`or drag and drop`,
                                            className: "pl-1"
                                          })
                                    ],
                                    className: "mt-4 flex text-sm leading-6 text-gray-600"
                                  }),
                              JsxRuntime.jsx("p", {
                                    children: t`PNG, JPG, GIF up to 10MB`,
                                    className: "text-xs leading-5 text-gray-600"
                                  })
                            ],
                            className: "text-center"
                          }),
                      className: "mt-2 flex justify-center rounded-lg border border-dashed border-gray-900/25 px-6 py-10"
                    })
              ]
            });
}

var ImageUpload = {
  make: Form$ImageUpload
};

function Form$Footer(props) {
  return JsxRuntime.jsxs("div", {
              children: [
                Core__Option.getOr(Core__Option.map(props.onCancel, (function (onCancel) {
                            return JsxRuntime.jsx("button", {
                                        children: t`cancel`,
                                        className: "text-sm font-semibold leading-6 text-gray-900",
                                        type: "button",
                                        onClick: onCancel
                                      });
                          })), null),
                JsxRuntime.jsx("button", {
                      children: t`save`,
                      className: "rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600",
                      type: "submit"
                    })
              ],
              className: "mt-6 flex items-center justify-end gap-x-6"
            });
}

var Footer = {
  make: Form$Footer
};

export {
  PrefixedInput ,
  Input ,
  Select ,
  PhotoIcon ,
  TextArea ,
  ImageUpload ,
  Footer ,
}
/*  Not a pure module */
