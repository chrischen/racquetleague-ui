%%raw("import { t } from '@lingui/macro'")

open Rating
open Lingui.Util

@react.component
let make = (
  ~player: Player.t<'a>,
  ~onSave: Player.t<'a> => unit,
  ~onClose: unit => unit,
  ~onDelete: option<unit => unit>=?,
) => {
  let (name, setName) = React.useState(() => player.name)
  let (gender, setGender) = React.useState(() => player.gender)

  // Check if this is a guest player (no data means it's a guest)
  let isGuest = player.data->Option.isNone

  let handleSave = () => {
    onSave({...player, name, gender})
    onClose()
  }

  <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
    <div className="bg-white rounded-xl shadow-2xl max-w-md w-full">
      // Header
      <div
        className="bg-white border-b border-slate-200 px-6 py-4 flex items-center justify-between rounded-t-xl">
        <div className="flex items-center gap-3">
          <Lucide.User className="w-6 h-6 text-blue-600" />
          <h2 className="text-xl font-bold text-slate-800"> {t`Player Settings`} </h2>
        </div>
        <button
          onClick={_ => onClose()}
          className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
          ariaLabel="Close">
          <Lucide.X className="w-5 h-5 text-slate-600" />
        </button>
      </div>
      // Content
      <div className="p-6 space-y-4">
        // Player Avatar & ID
        <div className="flex items-center gap-3 p-3 bg-slate-50 rounded-lg">
          <div className="w-12 h-12 rounded-full bg-slate-300 flex items-center justify-center">
            <Lucide.User className="w-6 h-6 text-slate-600" />
          </div>
          <div>
            <div className="text-sm font-semibold text-slate-800"> {t`Player ID`} </div>
            <div className="text-xs text-slate-500 font-mono">
              {`#${player.id}`->React.string}
            </div>
          </div>
        </div>
        // Name
        <div>
          <label className="block text-sm font-medium text-slate-700 mb-1"> {t`Name`} </label>
          <input
            type_="text"
            value={name}
            onChange={e => {
              let value = ReactEvent.Form.target(e)["value"]
              setName(_ => value)
            }}
            className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            placeholder="Player name"
          />
        </div>
        // Gender
        <div>
          <label className="block text-sm font-medium text-slate-700 mb-2"> {t`Gender`} </label>
          <div className="flex gap-2">
            <button
              type_="button"
              onClick={_ => setGender(_ => Gender.Male)}
              className={Util.cx([
                "flex-1 px-4 py-2 rounded-lg font-medium text-sm transition-colors",
                gender == Gender.Male
                  ? "bg-blue-600 text-white"
                  : "bg-slate-100 text-slate-700 hover:bg-slate-200",
              ])}>
              {t`Male`}
            </button>
            <button
              type_="button"
              onClick={_ => setGender(_ => Gender.Female)}
              className={Util.cx([
                "flex-1 px-4 py-2 rounded-lg font-medium text-sm transition-colors",
                gender == Gender.Female
                  ? "bg-blue-600 text-white"
                  : "bg-slate-100 text-slate-700 hover:bg-slate-200",
              ])}>
              {t`Female`}
            </button>
          </div>
        </div>
      </div>
      // Footer
      <div
        className="bg-slate-50 border-t border-slate-200 px-6 py-4 flex items-center gap-3 rounded-b-xl"
        style={ReactDOM.Style.make(
          ~justifyContent=isGuest && onDelete->Option.isSome ? "space-between" : "flex-end",
          (),
        )}>
        {isGuest && onDelete->Option.isSome
          ? <button
              type_="button"
              onClick={_ => {
                onDelete->Option.forEach(fn => fn())
                onClose()
              }}
              className="px-4 py-2 rounded-lg font-medium bg-red-600 text-white hover:bg-red-700 transition-colors shadow-md flex items-center gap-2">
              <Lucide.Trash2 className="w-4 h-4" />
              {t`Delete Guest`}
            </button>
          : React.null}
        <div className="flex items-center gap-3">
          <button
            type_="button"
            onClick={_ => onClose()}
            className="px-4 py-2 rounded-lg font-medium bg-white border border-slate-300 text-slate-700 hover:bg-slate-50 transition-colors">
            {t`Cancel`}
          </button>
          <button
            type_="button"
            onClick={_ => handleSave()}
            className="px-6 py-2 rounded-lg font-medium bg-blue-600 text-white hover:bg-blue-700 transition-colors shadow-md">
            {t`Save Changes`}
          </button>
        </div>
      </div>
    </div>
  </div>
}
