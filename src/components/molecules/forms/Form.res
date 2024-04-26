%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

module Input = {
  @react.component
  let make = (
    ~label: React.element,
    ~name: string,
    ~id: string,
    ~type_: option<string>="text",
    ~autoComplete: option<string>=?,
    ~placeholder: option<string>=?,
    ~onBlur: option<JsxEventU.Focus.t => unit>=?,
    ~register: option<JsxDOM.domProps>=?,
    ~value: option<string>=?,
    ~defaultValue: option<string>=?,
  ) => {
    <>
      <label htmlFor=name className="block text-sm font-medium leading-6 text-gray-900">
        {label}
      </label>
      <div className="mt-2">
        <div
          className="flex rounded-md shadow-sm ring-1 ring-inset ring-gray-300 focus-within:ring-2 focus-within:ring-inset focus-within:ring-indigo-600">
          <span className="flex select-none items-center pl-3 text-gray-500 sm:text-sm" />
          {switch register {
          | Some(register) =>
            <input
              {...register}
              type_
              name
              id
              ?autoComplete
              className="block flex-1 border-0 bg-transparent py-1.5 pl-1 text-gray-900 placeholder:text-gray-400 focus:ring-0 sm:text-sm sm:leading-6"
              ?placeholder
              ?onBlur
              ?value
              ?defaultValue
            />
          | None =>
            <input
              type_
              name
              id
              ?autoComplete
              className="block flex-1 border-0 bg-transparent py-1.5 pl-1 text-gray-900 placeholder:text-gray-400 focus:ring-0 sm:text-sm sm:leading-6"
              ?placeholder
              ?onBlur
              ?value
              ?defaultValue
            />
          }}
        </div>
      </div>
    </>
  }
}

module Select = {
  @react.component
  let make = (
    ~label: React.element,
    ~name: string,
    ~id: string,
    ~options: array<(string, string)>,
    // ~onBlur: option<JsxEventU.Focus.t => unit>=?,
    ~register: option<JsxDOM.domProps>=?,
    ~defaultValue: option<string>=?,
  ) => {
    <>
      <label htmlFor=name className="block text-sm font-medium leading-6 text-gray-900">
        {label}
      </label>
      {switch register {
      | Some(register) =>
        <select
          {...register}
          id
          name
          className="mt-2 block w-full rounded-md border-0 py-1.5 pl-3 pr-10 text-gray-900 ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-indigo-600 sm:text-sm sm:leading-6"
          ?defaultValue>
          {options
          ->Array.map(((name, value)) => <option value key=value> {name->React.string} </option>)
          ->React.array}
        </select>
      | None =>
        <select
          id
          name
          className="mt-2 block w-full rounded-md border-0 py-1.5 pl-3 pr-10 text-gray-900 ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-indigo-600 sm:text-sm sm:leading-6"
          ?defaultValue>
          {options
          ->Array.map(((name, value)) => <option value> {name->React.string} </option>)
          ->React.array}
        </select>
      }}
    </>
  }
}
module PhotoIcon = {
  @module("@heroicons/react/24/solid") @react.component
  external make: (~className: string=?, ~\"aria-hidden": string=?) => React.element = "PhotoIcon"
}
module TextArea = {
  @react.component
  let make = (
    ~label: React.element,
    ~name: option<string>=?,
    ~id: string,
    ~hint: option<React.element>=?,
    ~rows: option<int>=3,
    ~defaultValue: option<string>=?,
    ~disabled: option<bool>=?,
    ~register: option<JsxDOM.domProps>=?,
  ) => {
    <>
      <label htmlFor="about" className="block text-sm font-medium leading-6 text-gray-900">
        {label}
      </label>
      <div className="mt-2">
        {switch register {
        | Some(register) =>
          <textarea
            {...register}
            id
            ?name
            ?disabled
            rows
            className="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
            ?defaultValue
          />
        | None =>
          <textarea
            id
            ?name
            ?disabled
            rows
            className="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
            ?defaultValue
          />
        }}
      </div>
      {hint
      ->Option.map(hint => {
        <p className="mt-3 text-sm leading-6 text-gray-600"> {hint} </p>
      })
      ->Option.getOr(React.null)}
    </>
  }
}

module ImageUpload = {
  @react.component
  let make = () => {
    <>
      <label htmlFor="cover-photo" className="block text-sm font-medium leading-6 text-gray-900">
        {t`Cover photo`}
      </label>
      <div
        className="mt-2 flex justify-center rounded-lg border border-dashed border-gray-900/25 px-6 py-10">
        <div className="text-center">
          <PhotoIcon className="mx-auto h-12 w-12 text-gray-300" \"aria-hidden"="true" />
          <div className="mt-4 flex text-sm leading-6 text-gray-600">
            <label
              htmlFor="file-upload"
              className="relative cursor-pointer rounded-md bg-white font-semibold text-indigo-600 focus-within:outline-none focus-within:ring-2 focus-within:ring-indigo-600 focus-within:ring-offset-2 hover:text-indigo-500">
              <span> {t`Upload a file`} </span>
              <input id="file-upload" name="file-upload" type_="file" className="sr-only" />
            </label>
            <p className="pl-1"> {t`or drag and drop`} </p>
          </div>
          <p className="text-xs leading-5 text-gray-600"> {t`PNG, JPG, GIF up to 10MB`} </p>
        </div>
      </div>
    </>
  }
}

module Footer = {
  @react.component
  let make = (~onCancel: option<JsxEventU.Mouse.t => unit>=?) => {
    <div className="mt-6 flex items-center justify-end gap-x-6">
      {onCancel->Option.map(onCancel =>
        <button
          type_="button" onClick=onCancel className="text-sm font-semibold leading-6 text-gray-900">
          {t`Cancel`}
        </button>
      )->Option.getOr(React.null)}
      <button
        type_="submit"
        className="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600">
        {t`Save`}
      </button>
    </div>
  }
}
