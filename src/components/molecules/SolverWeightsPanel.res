%%raw("import { t } from '@lingui/macro'")

// Weight controls for the solver-backed strategies.
//
// Deliberately does not expose raw `costWeights`: the user gets one semantic
// slider (competitive <-> mix players), with an advanced accordion for the five
// individual preferences. The guardrails — bye fairness, the anti-back-to-back
// tier, court fill, and every violation surcharge — are not configurable, so no
// slider position can stop a mode rotating players in.

let sliderPercent = (value: float): string =>
  (value *. 100.)->Js.Math.round->Float.toString

let fromPercent = (raw: string): float =>
  raw->Float.fromString->Option.getOr(50.)->(v => v /. 100.)->CostModel.clamp01

module Slider = {
  @react.component
  let make = (
    ~label: string,
    ~value: float,
    ~onChange: float => unit,
    ~leftHint: string="",
    ~rightHint: string="",
  ) =>
    <div className="flex flex-col gap-1">
      <div className="flex items-center justify-between text-xs text-slate-600">
        <span className="font-medium"> {label->React.string} </span>
      </div>
      <input
        type_="range"
        min="0"
        max="100"
        step=1.
        value={sliderPercent(value)}
        onChange={e => onChange(fromPercent((e->ReactEvent.Form.target)["value"]))}
        className="w-full accent-blue-600"
      />
      {leftHint == "" && rightHint == ""
        ? React.null
        : <div className="flex justify-between text-[10px] text-slate-400">
            <span> {leftHint->React.string} </span>
            <span> {rightHint->React.string} </span>
          </div>}
    </div>
}

module Toggle = {
  @react.component
  let make = (~label: string, ~checked: bool, ~onChange: bool => unit, ~hint: string="") =>
    <label className="flex items-start justify-between gap-3 cursor-pointer">
      <span className="flex flex-col">
        <span className="text-xs font-medium text-slate-600"> {label->React.string} </span>
        {hint == ""
          ? React.null
          : <span className="text-[10px] text-slate-400"> {hint->React.string} </span>}
      </span>
      <input
        type_="checkbox"
        checked
        onChange={e => onChange((e->ReactEvent.Form.target)["checked"])}
        className="mt-0.5 h-4 w-4 shrink-0 accent-blue-600"
      />
    </label>
}

@react.component
let make = (
  ~config: CostModel.uiWeightConfig,
  ~onChange: CostModel.uiWeightConfig => unit,
) => {
  let ts = Lingui.UtilString.t
  let (advancedOpen, setAdvancedOpen) = React.useState(() => config.advanced->Option.isSome)

  // When the user has not customised anything, the accordion shows the values
  // the primary slider implies rather than stale defaults.
  let advanced = switch config.advanced {
  | Some(a) => a
  | None => CostModel.advancedFromPrimary(config.qualityVsVariety)
  }

  let isCustom = config.advanced->Option.isSome

  // Moving the primary slider drops any customisation, which is what makes it
  // feel like a preset control rather than a sixth independent knob.
  let handlePrimary = value => onChange({CostModel.qualityVsVariety: value, advanced: None})

  let handleAdvanced = (next: CostModel.advancedWeights) =>
    onChange({...config, advanced: Some(next)})

  <div className="mt-4 pt-4 border-t border-slate-200">
    <Slider
      label={ts`Match style`}
      value={config.qualityVsVariety}
      onChange={handlePrimary}
      leftHint={ts`Mix players`}
      rightHint={ts`Competitive`}
    />
    <p className="mt-2 text-xs text-slate-500 italic">
      {(config.qualityVsVariety < 0.35
        ? ts`Prioritises fresh partners and opponents over evenly matched games.`
        : config.qualityVsVariety > 0.65
        ? ts`Prioritises evenly matched games over fresh partners.`
        : ts`Balances fresh partners against evenly matched games.`)->React.string}
    </p>
    <div className="mt-3">
      <button
        onClick={_ => setAdvancedOpen(prev => !prev)}
        className="flex items-center gap-1 text-xs font-medium text-slate-600 hover:text-slate-900">
        {advancedOpen
          ? <Lucide.ChevronUp className="w-4 h-4" />
          : <Lucide.ChevronDown className="w-4 h-4" />}
        {(ts`Advanced`)->React.string}
        {isCustom
          ? <span
              className="ml-1 px-1.5 py-0.5 rounded text-[10px] font-semibold bg-slate-200 text-slate-700">
              {(ts`Custom`)->React.string}
            </span>
          : React.null}
      </button>
      {advancedOpen
        ? <div className="mt-3 grid gap-3 sm:grid-cols-2">
            <Slider
              label={ts`Partner variety`}
              value={advanced.partnerVariety}
              onChange={v => handleAdvanced({...advanced, partnerVariety: v})}
            />
            <Slider
              label={ts`Opponent variety`}
              value={advanced.opponentVariety}
              onChange={v => handleAdvanced({...advanced, opponentVariety: v})}
            />
            <Slider
              label={ts`Similar-skill matches`}
              value={advanced.similarSkill}
              onChange={v => handleAdvanced({...advanced, similarSkill: v})}
              leftHint={ts`Any mix`}
              rightHint={ts`Tight bands`}
            />
            <Toggle
              label={ts`Balance teams`}
              hint={ts`Split each match into its most even teams`}
              checked={advanced.balanceTeams}
              onChange={v => handleAdvanced({...advanced, balanceTeams: v})}
            />
            <Slider
              label={ts`Avoid recent repeats`}
              value={advanced.avoidRecentRepeats}
              onChange={v => handleAdvanced({...advanced, avoidRecentRepeats: v})}
            />
            <Slider
              label={ts`Alternate favourite/underdog roles`}
              value={advanced.alternateFavored}
              onChange={v => handleAdvanced({...advanced, alternateFavored: v})}
            />
            {isCustom
              ? <button
                  onClick={_ => handlePrimary(config.qualityVsVariety)}
                  className="self-end text-xs font-medium text-blue-600 hover:text-blue-800">
                  {(ts`Reset to slider`)->React.string}
                </button>
              : React.null}
          </div>
        : React.null}
    </div>
    <p className="mt-3 text-[11px] text-slate-400">
      {(
        ts`Each strategy uses a tuned profile; adjusting any slider switches this event to a custom mix. Fair play time and rotation are always enforced and can't be turned down.`
      )->React.string}
    </p>
  </div>
}
