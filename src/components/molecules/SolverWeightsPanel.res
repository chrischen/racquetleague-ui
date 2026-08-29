%%raw("import { t } from '@lingui/macro'")

// Weight controls for the solver-backed strategies.
//
// The advanced section speaks the engine's full preference vocabulary
// (`CostModel.advancedWeights`), and the presets are configs in that same
// vocabulary — so an untouched preset displays its real tuned values, and
// customising forks from exactly those values. Only the guardrails — bye
// fairness, the anti-back-to-back tier, court fill, and every violation
// surcharge — are not configurable, so no slider position can stop a mode
// rotating players in.
//
// The panel is two mutually exclusive sections — "Match style" (the slider,
// or Auto's live readout) and "Advanced" (the individual values). Opening one
// closes the other, mirroring the engine's own either/or: weights come from
// the slider curve or from explicit advanced values, never both. The slider
// still feeds the advanced view — with no overrides stored, the advanced
// values shown are the ones the slider position implies — and switching back
// to the slider from an advanced customisation hands control back to it.

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
    ~disabled: bool=false,
  ) =>
    <div className={disabled ? "flex flex-col gap-1 opacity-60" : "flex flex-col gap-1"}>
      {label == ""
        ? React.null
        : <div className="flex items-center justify-between text-xs text-slate-600">
            <span className="font-medium"> {label->React.string} </span>
          </div>}
      <input
        type_="range"
        min="0"
        max="100"
        step=1.
        value={sliderPercent(value)}
        disabled
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

// Team-split policy. The engine stores two booleans (`balanceTeams`,
// `splitBalanceFirst`), but the second is meaningless without the first, so
// the four combinations collapse to exactly three real states — presented as
// one choice so no label can promise more than the engine delivers.
module SplitMode = {
  type t = Free | BalancedFreshFirst | MostEven

  let fromWeights = (~balanceTeams: bool, ~splitBalanceFirst: bool): t =>
    !balanceTeams ? Free : splitBalanceFirst ? MostEven : BalancedFreshFirst

  @react.component
  let make = (
    ~label: string,
    ~value: t,
    ~onChange: t => unit,
    ~options: array<(t, string, string)>,
    ~disabled: bool=false,
  ) => {
    // Radio groups are scoped by name, and more than one panel can be mounted.
    let name = React.useId()
    <div
      className={disabled
        ? "flex flex-col gap-1 sm:col-span-2 opacity-60"
        : "flex flex-col gap-1 sm:col-span-2"}>
      <span className="text-xs font-medium text-slate-600"> {label->React.string} </span>
      <div className="flex flex-col gap-1.5">
        {options
        ->Array.map(((mode, title, hint)) =>
          <label
            key={title}
            className={disabled
              ? "flex items-start gap-2 cursor-default"
              : "flex items-start gap-2 cursor-pointer"}>
            <input
              type_="radio"
              name
              checked={mode == value}
              disabled
              onChange={_ => onChange(mode)}
              className="mt-0.5 h-4 w-4 shrink-0 accent-blue-600"
            />
            <span className="flex flex-col">
              <span className="text-xs font-medium text-slate-600"> {title->React.string} </span>
              <span className="text-[10px] text-slate-400"> {hint->React.string} </span>
            </span>
          </label>
        )
        ->React.array}
      </div>
    </div>
  }
}

// Which of the two mutually exclusive sections is open.
type view = StyleView | AdvancedView

@react.component
let make = (
  ~config: CostModel.uiWeightConfig,
  ~onChange: CostModel.uiWeightConfig => unit,
  // Whether `config` is a persisted customisation, as opposed to the current
  // strategy's preset. The panel cannot tell these apart on its own any more:
  // presets carry explicit advanced values too, precisely so the advanced
  // section shows the real tuned numbers.
  ~isCustom: bool=false,
  // The Auto preset's live blend position (0 = Random Balanced, 1 =
  // Competitive+), recomputed by the caller from the current ratings. Present
  // only while Auto is selected and uncustomised; the panel then displays the
  // blend's actual values instead of anything stored, so what's on screen is a
  // function of the pool's rating state — exactly what generation uses.
  ~autoBlendT: option<float>=?,
  // Clears the stored customisation, returning the event to the strategy's
  // tuned preset (and, for Auto, re-enabling the live blend).
  ~onReset: option<unit => unit>=?,
) => {
  let ts = Lingui.UtilString.t
  let hasAdvancedOverrides = isCustom && config.advanced->Option.isSome
  // An advanced customisation is driven by the advanced values, so that is the
  // section that greets you; everything else opens on the style slider.
  let (view, setView) = React.useState(() => hasAdvancedOverrides ? AdvancedView : StyleView)

  // Auto shows its live blend; otherwise a slider-only custom config shows the
  // values the primary slider implies.
  let advanced = switch (autoBlendT, config.advanced) {
  | (Some(t), _) => CostModel.advancedFromWeights(CostModel.autoWeightsAt(t))
  | (None, Some(a)) => a
  | (None, None) => CostModel.advancedFromPrimary(config.qualityVsVariety)
  }

  let isAuto = autoBlendT->Option.isSome
  // Auto's values rewrite themselves from the rating state; a stray drag would
  // silently freeze the blend, so customising it is an explicit action below.
  let locked = isAuto

  let handlePrimary = value => onChange({CostModel.qualityVsVariety: value, advanced: None})

  let handleAdvanced = (next: CostModel.advancedWeights) =>
    onChange({...config, advanced: Some(next)})

  // Freeze Auto's current blend into a fixed custom mix and unlock the panel.
  let handleCustomizeFromAuto = () => onChange({...config, advanced: Some(advanced)})

  // Reopening the style section is also a mode switch when advanced values
  // were in force: the slider takes over, dropping the overrides.
  let openStyle = () => {
    if hasAdvancedOverrides {
      handlePrimary(config.qualityVsVariety)
    }
    setView(_ => StyleView)
  }

  let sectionHeader = (~open_: bool, ~onClick, ~label: string, ~chip: React.element) =>
    <button
      onClick
      className="flex items-center gap-1 text-xs font-medium text-slate-600 hover:text-slate-900">
      {open_
        ? <Lucide.ChevronUp className="w-4 h-4" />
        : <Lucide.ChevronDown className="w-4 h-4" />}
      {label->React.string}
      chip
    </button>

  <div className="mt-4 pt-4 border-t border-slate-200">
    {sectionHeader(
      ~open_=view == StyleView,
      ~onClick=_ => openStyle(),
      ~label=ts`Match style`,
      ~chip=isAuto
        ? <span
            className="ml-1 px-1.5 py-0.5 rounded text-[10px] font-semibold bg-blue-100 text-blue-700">
            {(ts`Auto`)->React.string}
          </span>
        : React.null,
    )}
    {switch (view, autoBlendT) {
    | (AdvancedView, _) => React.null
    | (StyleView, Some(t)) => {
        // Auto has no fixed position on the variety<->quality axis: show where
        // the blend currently sits instead of a slider pretending it does.
        let percent = (t *. 100.)->Js.Math.round->Float.toString
        <div className="mt-2 flex flex-col gap-1">
          <div className="h-2 w-full rounded bg-slate-200 overflow-hidden">
            <div
              className="h-full bg-blue-600 rounded"
              style={ReactDOM.Style.make(~width=percent ++ "%", ())}
            />
          </div>
          <div className="flex justify-between text-[10px] text-slate-400">
            <span> {(ts`Calibrating`)->React.string} </span>
            <span> {(ts`Competitive`)->React.string} </span>
          </div>
          <p className="mt-1 text-xs text-slate-500 italic">
            {(
              ts`Ratings are ${percent}% settled — the mix adjusts automatically as scores come in.`
            )->React.string}
          </p>
        </div>
      }
    | (StyleView, None) =>
      <div className="mt-2">
        <Slider
          label=""
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
      </div>
    }}
    <div className="mt-3">
      {sectionHeader(
        ~open_=view == AdvancedView,
        ~onClick=_ => setView(_ => AdvancedView),
        ~label=ts`Advanced`,
        ~chip=isCustom
          ? <span
              className="ml-1 px-1.5 py-0.5 rounded text-[10px] font-semibold bg-slate-200 text-slate-700">
              {(ts`Custom`)->React.string}
            </span>
          : React.null,
      )}
      {view == AdvancedView && isAuto
        ? <div className="mt-3 flex flex-col gap-1">
            <button
              onClick={_ => handleCustomizeFromAuto()}
              className="self-start text-xs font-medium text-blue-600 hover:text-blue-800">
              {(ts`Customize from here`)->React.string}
            </button>
            <span className="text-[10px] text-slate-400">
              {(
                ts`Auto is adjusting these values — freeze the current mix to adjust them manually. Auto stops adapting for this event.`
              )->React.string}
            </span>
          </div>
        : React.null}
      {view == AdvancedView
        ? <div className="mt-3 grid gap-3 sm:grid-cols-2">
            <Slider
              label={ts`Partner variety`}
              value={advanced.partnerVariety}
              onChange={v => handleAdvanced({...advanced, partnerVariety: v})}
              disabled=locked
            />
            <Slider
              label={ts`Opponent variety`}
              value={advanced.opponentVariety}
              onChange={v => handleAdvanced({...advanced, opponentVariety: v})}
              disabled=locked
            />
            <Slider
              label={ts`Skill banding`}
              value={advanced.bandStrength}
              onChange={v => handleAdvanced({...advanced, bandStrength: v})}
              leftHint={ts`No preference`}
              rightHint={ts`Group by skill`}
              disabled=locked
            />
            <Slider
              label={ts`Band tolerance`}
              value={advanced.bandTolerance}
              onChange={v => handleAdvanced({...advanced, bandTolerance: v})}
              leftHint={ts`Tight bands`}
              rightHint={ts`Any mix is fine`}
              disabled=locked
            />
            <SplitMode
              label={ts`Team split`}
              value={SplitMode.fromWeights(
                ~balanceTeams=advanced.balanceTeams,
                ~splitBalanceFirst=advanced.splitBalanceFirst,
              )}
              onChange={mode =>
                handleAdvanced(
                  switch mode {
                  | SplitMode.Free => {...advanced, balanceTeams: false, splitBalanceFirst: false}
                  | SplitMode.BalancedFreshFirst => {
                      ...advanced,
                      balanceTeams: true,
                      splitBalanceFirst: false,
                    }
                  | SplitMode.MostEven => {...advanced, balanceTeams: true, splitBalanceFirst: true}
                  },
                )}
              options=[
                (
                  SplitMode.Free,
                  ts`Free`,
                  ts`Fresh matchups decide how teams split; splits can be uneven`,
                ),
                (
                  SplitMode.BalancedFreshFirst,
                  ts`Balanced, fresh partners first`,
                  ts`The most even split that avoids repeating a partnership`,
                ),
                (
                  SplitMode.MostEven,
                  ts`Most even always`,
                  ts`The most even split, even if a partnership repeats`,
                ),
              ]
              disabled=locked
            />
            <Slider
              label={ts`Avoid recent repeats`}
              value={advanced.avoidRecentRepeats}
              onChange={v => handleAdvanced({...advanced, avoidRecentRepeats: v})}
              disabled=locked
            />
            <Slider
              label={ts`Alternate favourite/underdog roles`}
              value={advanced.alternateFavored}
              onChange={v => handleAdvanced({...advanced, alternateFavored: v})}
              disabled=locked
            />
            <Slider
              label={ts`Shake-up`}
              value={advanced.shakeUp}
              onChange={v => handleAdvanced({...advanced, shakeUp: v})}
              leftHint={ts`Deterministic`}
              rightHint={ts`Random`}
              disabled=locked
            />
            <Slider
              label={ts`Rotate skill bands together`}
              value={advanced.cohortRotation}
              onChange={v => handleAdvanced({...advanced, cohortRotation: v})}
              leftHint={ts`Off`}
              rightHint={ts`Bands break together`}
              disabled=locked
            />
            {isCustom
              ? switch onReset {
                | Some(reset) =>
                  <button
                    onClick={_ => reset()}
                    className="self-end text-xs font-medium text-blue-600 hover:text-blue-800">
                    {(ts`Reset to preset`)->React.string}
                  </button>
                | None => React.null
                }
              : React.null}
          </div>
        : React.null}
    </div>
    <p className="mt-3 text-[11px] text-slate-400">
      {(
        ts`Each strategy uses a tuned profile; adjusting any value switches this event to a custom mix. Fair play time and rotation are always enforced and can't be turned down.`
      )->React.string}
    </p>
  </div>
}
