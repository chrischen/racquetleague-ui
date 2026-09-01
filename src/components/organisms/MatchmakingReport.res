%%raw("import { t } from '@lingui/macro'")

// Matchmaking strategies report.
//
// An infographic-style blog post built on the SAME data and chart machinery as
// the interactive lab: it loads the precomputed run (`SimLabArchive`) and
// renders the lab's Recharts series inline between sections of prose. Nothing
// here re-simulates or re-derives — every number in the text is readable off
// the charts beside it, and the charts read the artifact the lab ships.
//
// The prose is edited from the author's draft; numbers were reconciled against
// the artifact (24 players · 4 courts · 100 rounds · 7 seeds · 3 fields,
// summarised over the trailing 25 rounds at round 100).

module ML = MatchmakingLab

let ts = Lingui.UtilString.t
let t = Lingui.Util.t

// ---------------------------------------------------------------------------
// Typography
// ---------------------------------------------------------------------------

let serif = "Charter, Georgia, 'Iowan Old Style', 'Times New Roman', serif"

let proseStyle = ReactDOM.Style.make(
  ~fontFamily=serif,
  ~fontSize="17px",
  ~lineHeight="1.68",
  ~color=ML.ink,
  ~margin="0 0 18px",
  (),
)

module Para = {
  @react.component
  let make = (~children) => <p style={proseStyle}> children </p>
}

// Numbered section header, infographic style: a big mono index and a rule.
module Section = {
  @react.component
  let make = (~n: string, ~title: React.element) =>
    <div
      className="flex items-baseline gap-3"
      style={ReactDOM.Style.make(
        ~margin="46px 0 18px",
        ~paddingTop="18px",
        ~borderTop="2px solid " ++ ML.ink,
        (),
      )}>
      <span
        style={ReactDOM.Style.make(
          ~fontFamily=ML.monoFont,
          ~fontSize="13px",
          ~color=ML.mute,
          ~letterSpacing="0.08em",
          (),
        )}>
        {n->React.string}
      </span>
      <h2
        style={ReactDOM.Style.make(
          ~fontFamily=serif,
          ~fontSize="26px",
          ~fontWeight="700",
          ~color=ML.ink,
          ~margin="0",
          (),
        )}>
        {title}
      </h2>
    </div>
}

module SubHead = {
  @react.component
  let make = (~title: React.element) =>
    <h3
      style={ReactDOM.Style.make(
        ~fontFamily=ML.monoFont,
        ~fontSize="11px",
        ~fontWeight="600",
        ~letterSpacing="0.14em",
        ~textTransform="uppercase",
        ~color=ML.mute,
        ~margin="26px 0 10px",
        (),
      )}>
      {title}
    </h3>
}

// One term the article leans on.
module Term = {
  @react.component
  let make = (~term: React.element, ~def: React.element) =>
    <div
      style={ReactDOM.Style.make(
        ~background=ML.panel,
        ~border="1px solid " ++ ML.rule,
        ~padding="12px 14px",
        (),
      )}>
      <div
        style={ReactDOM.Style.make(
          ~fontFamily=ML.monoFont,
          ~fontSize="11px",
          ~fontWeight="600",
          ~letterSpacing="0.12em",
          ~textTransform="uppercase",
          ~color=ML.truthRed,
          ~marginBottom="6px",
          (),
        )}>
        {term}
      </div>
      <div
        style={ReactDOM.Style.make(
          ~fontFamily=serif,
          ~fontSize="14px",
          ~lineHeight="1.55",
          ~color=ML.ink,
          (),
        )}>
        {def}
      </div>
    </div>
}

// A big number with a caption — the infographic unit.
module Stat = {
  @react.component
  let make = (~value: string, ~label: React.element, ~color: string=ML.ink) =>
    <div style={ReactDOM.Style.make(~minWidth="120px", ())}>
      <div
        style={ReactDOM.Style.make(
          ~fontFamily=ML.monoFont,
          ~fontSize="34px",
          ~fontWeight="700",
          ~color,
          ~lineHeight="1.1",
          (),
        )}>
        {value->React.string}
      </div>
      <div
        style={ReactDOM.Style.make(
          ~fontFamily=ML.monoFont,
          ~fontSize="10px",
          ~letterSpacing="0.06em",
          ~color=ML.mute,
          ~marginTop="4px",
          ~maxWidth="150px",
          (),
        )}>
        {label}
      </div>
    </div>
}

module StatRow = {
  @react.component
  let make = (~children) =>
    <div
      className="flex flex-wrap gap-x-8 gap-y-4"
      style={ReactDOM.Style.make(
        ~background=ML.panel,
        ~border="1px solid " ++ ML.rule,
        ~borderLeft="4px solid " ++ ML.ink,
        ~padding="16px 18px",
        ~margin="6px 0 22px",
        (),
      )}>
      children
    </div>
}

// ---------------------------------------------------------------------------
// Charts
// ---------------------------------------------------------------------------

// Tooltip values carry full float precision from the seed averaging; one
// decimal is all a reader can use.
let roundForDisplay = (rows: array<Js.Json.t>) =>
  rows->Array.map(json =>
    switch Js.Json.decodeObject(json) {
    | None => json
    | Some(d) =>
      let out = Js.Dict.empty()
      d
      ->Js.Dict.entries
      ->Array.forEach(((k, v)) =>
        out->Js.Dict.set(
          k,
          switch Js.Json.decodeNumber(v) {
          | Some(n) if k != "round" => Js.Json.number(Js.Math.round(n *. 10.) /. 10.)
          | _ => v
          },
        )
      )
      out->Js.Json.object_
    }
  )

// One interactive chart: the lab's series with a clickable legend. Clicking a
// strategy isolates its line; clicking it again restores the field.
module ReportChart = {
  @react.component
  let make = (
    ~data: array<Js.Json.t>,
    ~runs: array<SimLab.strategyRun>,
    ~ids: array<string>,
    ~metric: ML.metric,
    ~title: React.element,
    ~unit: React.element,
    ~maxRound: int,
    ~yDomain: option<array<float>>=?,
    ~height: int=190,
    ~extra: React.element=React.null,
  ) => {
    let (focus, setFocus) = React.useState(() => None)
    let entries = ids->Array.filterMap(id => runs->Array.find(r => r.entry.id == id))
    let key = ML.metricKey(metric)

    <figure
      style={ReactDOM.Style.make(
        ~background=ML.panel,
        ~border="1px solid " ++ ML.rule,
        ~padding="12px 10px 8px 0",
        ~margin="6px 0 26px",
        (),
      )}>
      <div className="flex items-baseline gap-2 flex-wrap pl-4 pr-2 mb-1">
        <span
          style={ReactDOM.Style.make(
            ~fontFamily=ML.monoFont,
            ~fontSize="11px",
            ~fontWeight="600",
            ~letterSpacing="0.12em",
            ~textTransform="uppercase",
            ~color=ML.ink,
            (),
          )}>
          {title}
        </span>
        <span
          style={ReactDOM.Style.make(
            ~fontFamily=ML.monoFont,
            ~fontSize="10px",
            ~color=ML.mute,
            (),
          )}>
          {unit}
        </span>
        {extra}
      </div>
      <ML.ResponsiveContainer width="100%" height>
        <ML.LineChart data margin={ML.chartMargin}>
          <ML.CartesianGrid stroke={ML.ruleSoft} vertical={false} />
          <ML.XAxis
            dataKey="round"
            \"type"="number"
            domain=[1.0, maxRound->Int.toFloat]
            tick={ML.tickStyle}
            stroke={ML.rule}
            allowDecimals={false}
          />
          <ML.YAxis domain=?yDomain tick={ML.tickStyle} stroke={ML.rule} width=34 />
          <ML.Tooltip contentStyle={ML.tooltipStyle} />
          {entries
          ->Array.map(run => {
            let isFocus = focus == Some(run.entry.id)
            let dimmed = focus != None && !isFocus
            <ML.Line
              key={run.entry.id}
              \"type"="monotone"
              dataKey={key ++ "_" ++ run.entry.short}
              name={ML.strategyLabel(run.entry)}
              stroke={run.entry.color}
              strokeWidth={isFocus ? 2.6 : 1.6}
              strokeOpacity={dimmed ? 0.15 : 1.0}
              strokeDasharray={run.entry.isBaseline ? "4 3" : ""}
              dot={false}
              isAnimationActive={false}
              connectNulls={true}
            />
          })
          ->React.array}
        </ML.LineChart>
      </ML.ResponsiveContainer>
      <figcaption className="flex items-center gap-1 flex-wrap pl-4 pr-2 pt-1 pb-1">
        {entries
        ->Array.map(run => {
          let isFocus = focus == Some(run.entry.id)
          <button
            key={run.entry.id}
            onClick={_ => setFocus(f => f == Some(run.entry.id) ? None : Some(run.entry.id))}
            style={ReactDOM.Style.make(
              ~fontFamily=ML.monoFont,
              ~fontSize="10px",
              ~padding="3px 8px",
              ~border="1px solid " ++ (isFocus ? ML.ink : ML.rule),
              ~background=isFocus ? ML.ink : "transparent",
              ~color=isFocus ? ML.paper : ML.ink,
              ~cursor="pointer",
              ~display="inline-flex",
              ~alignItems="center",
              ~gap="5px",
              (),
            )}>
            <span
              style={ReactDOM.Style.make(
                ~width="8px",
                ~height="8px",
                ~background=run.entry.color,
                ~display="inline-block",
                (),
              )}
            />
            {ML.strategyLabel(run.entry)->React.string}
          </button>
        })
        ->React.array}
        <span
          style={ReactDOM.Style.make(
            ~fontFamily=ML.monoFont,
            ~fontSize="9px",
            ~color=ML.mute,
            ~marginLeft="auto",
            (),
          )}>
          {t`click a strategy to isolate it`}
        </span>
      </figcaption>
    </figure>
  }
}

// The conclusion's cross-field panel: one strategy, all three clubs. Its keys
// are club names rather than strategy shorts, so it draws its own lines
// instead of going through ReportChart.
module CrossFieldChart = {
  @react.component
  let make = (~data: array<Js.Json.t>, ~maxRound: int) => {
    let lines = [
      ("varied", ts`Varied club`, ML.truthRed),
      ("typical", ts`Typical club`, ML.warn),
      ("tight", ts`Tight club`, ML.ratingBlue),
    ]
    // Each club's avoid-repeats baseline, dashed in the club's own colour.
    let baselines = lines->Array.map(((k, label, color)) => (k ++ "Base", label, color))
    <figure
      style={ReactDOM.Style.make(
        ~background=ML.panel,
        ~border="1px solid " ++ ML.rule,
        ~padding="12px 10px 8px 0",
        ~margin="6px 0 26px",
        (),
      )}>
      <div className="flex items-baseline gap-2 flex-wrap pl-4 pr-2 mb-1">
        <span
          style={ReactDOM.Style.make(
            ~fontFamily=ML.monoFont,
            ~fontSize="11px",
            ~fontWeight="600",
            ~letterSpacing="0.12em",
            ~textTransform="uppercase",
            ~color=ML.ink,
            (),
          )}>
          {t`Competitive+ match quality, by club`}
        </span>
        <span
          style={ReactDOM.Style.make(
            ~fontFamily=ML.monoFont,
            ~fontSize="10px",
            ~color=ML.mute,
            (),
          )}>
          {t`· % chance the game ends level · solid: Competitive+ · dashed: random, avoid repeats`}
        </span>
      </div>
      <ML.ResponsiveContainer width="100%" height=190>
        <ML.LineChart data margin={ML.chartMargin}>
          <ML.CartesianGrid stroke={ML.ruleSoft} vertical={false} />
          <ML.XAxis
            dataKey="round"
            \"type"="number"
            domain=[1.0, maxRound->Int.toFloat]
            tick={ML.tickStyle}
            stroke={ML.rule}
            allowDecimals={false}
          />
          <ML.YAxis domain=[0.0, 100.0] tick={ML.tickStyle} stroke={ML.rule} width=34 />
          <ML.Tooltip contentStyle={ML.tooltipStyle} />
          {lines
          ->Array.map(((k, label, color)) =>
            <ML.Line
              key={k}
              \"type"="monotone"
              dataKey={k}
              name={label}
              stroke={color}
              strokeWidth=1.8
              dot={false}
              isAnimationActive={false}
              connectNulls={true}
            />
          )
          ->React.array}
          {baselines
          ->Array.map(((k, label, color)) =>
            <ML.Line
              key={k}
              \"type"="monotone"
              dataKey={k}
              name={label ++ " · " ++ (ts`random, avoid repeats`)}
              stroke={color}
              strokeWidth=1.1
              strokeOpacity=0.55
              strokeDasharray="4 3"
              dot={false}
              isAnimationActive={false}
              connectNulls={true}
            />
          )
          ->React.array}
        </ML.LineChart>
      </ML.ResponsiveContainer>
      <figcaption className="flex items-center gap-3 pl-4 pb-1">
        {lines
        ->Array.map(((k, label, color)) =>
          <span
            key={k}
            className="flex items-center gap-1"
            style={ReactDOM.Style.make(
              ~fontFamily=ML.monoFont,
              ~fontSize="10px",
              ~color=ML.ink,
              (),
            )}>
            <span
              style={ReactDOM.Style.make(
                ~width="8px",
                ~height="8px",
                ~background=color,
                ~display="inline-block",
                (),
              )}
            />
            {label->React.string}
          </span>
        )
        ->React.array}
      </figcaption>
    </figure>
  }
}

// ---------------------------------------------------------------------------
// The article
// ---------------------------------------------------------------------------

let fieldName = (f: int) =>
  switch f {
  | 0 => t`Varied club`
  | 1 => t`Typical club`
  | _ => t`Tight club`
  }

module Article = {
  @react.component
  let make = (~byField: array<array<SimLab.labResult>>) => {
    // Which strategies each chart compares. Ids are `SimLab.strategies` ids.
    // The rating-free baseline is random that AVOIDS repeats — what open play
    // actually deals, since nobody willingly replays the same match. Pure
    // random exists in the lab as a synthetic floor; measured, the two are
    // identical on quality and blowouts (novelty buys variety and faster
    // convergence, nothing else), so the comparison is unchanged in substance
    // and honest in name.
    let qualityIds = ["cpa", "cp", "rb", "rr", "rndnov", "jp", "us"]
    let convergenceIds = ["cpa", "cp", "rb", "rr"]
    let oracleIds = ["oracle", "cpa", "rb"]

    let first = byField->Array.getUnsafe(0)->Array.getUnsafe(0)
    let maxRound = first.numRounds
    let runsOf = (f: int) => (byField->Array.getUnsafe(f)->Array.getUnsafe(0)).runs

    // Chart rows per field, computed once. Same series the lab draws.
    let (dataVaried, dataTypical, dataTight) = React.useMemo1(() => {
      let build = f => roundForDisplay(ML.buildChartData(byField->Array.getUnsafe(f), ~window=5))
      (build(0), build(1), build(2))
    }, [byField])
    let dataOf = (f: int) =>
      switch f {
      | 0 => dataVaried
      | 1 => dataTypical
      | _ => dataTight
      }

    // Cross-field view for the conclusion: Competitive+ in all three clubs,
    // with each club's avoid-repeats baseline dashed beneath it, so the chart
    // reads as three before/after pairs rather than three bare lines.
    let crossFieldQuality = React.useMemo1(() => {
      let cpaIdx = first.runs->Array.findIndex(r => r.entry.id == "cpa")
      let baseIdx = first.runs->Array.findIndex(r => r.entry.id == "rndnov")
      Belt.Array.makeBy(maxRound, r => {
        let round = r + 1
        let row = Js.Dict.empty()
        row->Js.Dict.set("round", round->Int.toFloat->Js.Json.number)
        byField->Array.forEachWithIndex(
          (seeds, f) => {
            let club = switch f {
            | 0 => "varied"
            | 1 => "typical"
            | _ => "tight"
            }
            let put = (key, idx) =>
              switch ML.seriesAcross(seeds, ~idx, ~metric=Quality, ~round, ~window=5) {
              | Some(v) => row->Js.Dict.set(key, Js.Json.number(Js.Math.round(v *. 10.) /. 10.))
              | None => ()
              }
            put(club, cpaIdx)
            put(club ++ "Base", baseIdx)
          },
        )
        row->Js.Json.object_
      })
    }, [byField])

    // The blowout comparison offers all three clubs behind tabs.
    let (blowoutField, setBlowoutField) = React.useState(() => 0)

    let fieldTabs =
      <span className="ml-auto flex items-center gap-1">
        {[0, 1, 2]
        ->Array.map(f =>
          <button
            key={Int.toString(f)}
            onClick={_ => setBlowoutField(_ => f)}
            style={ReactDOM.Style.make(
              ~fontFamily=ML.monoFont,
              ~fontSize="10px",
              ~padding="2px 8px",
              ~border="1px solid " ++ (blowoutField == f ? ML.ink : ML.rule),
              ~background=blowoutField == f ? ML.ink : "transparent",
              ~color=blowoutField == f ? ML.paper : ML.ink,
              ~cursor="pointer",
              (),
            )}>
            {fieldName(f)}
          </button>
        )
        ->React.array}
      </span>

    let colorOf = (id: string) =>
      first.runs
      ->Array.find(r => r.entry.id == id)
      ->Option.mapOr(ML.ink, r => r.entry.color)

    <>
      // ------------------------------------------------------------- intro
      <Para>
        {t`Two things decide which matchmaking strategy is best: the skill spread of the club, and what you mean by “best”. Spread is how far apart your players are in real ability. “Best” splits into two goals — keeping everyone in tight, high-quality matches, and converging ratings to the truth quickly — and while ratings are still unknown — somewhere in the first fifteen rounds, about one session — you cannot have both. Faster convergence means injecting randomness into the matchmaking, which costs match quality now; optimising quality means trusting ratings that are still noise, which locks misrated players in place. Some early time must be spent in exploratory, suboptimal matches — unless you seed initial ratings by hand. Once ratings settle, the tension mostly dissolves: the same strategy can hold the best match quality in the field while converging as fast as anything else.`}
      </Para>
      <Para>
        {t`You have probably heard that to improve, you should play people better than you. The advice is not wrong — it is impractical. For you to play up, someone better than you has to play down. The only version of it that scales is playing people close to your level, with occasional games slightly up or slightly down. That is the goal of the Round Robin tool, and it is what these matchmaking algorithms are trying to accomplish.`}
      </Para>
      <SubHead title={t`Three terms worth pinning down`} />
      <div
        className="grid gap-3 md:grid-cols-3" style={ReactDOM.Style.make(~margin="0 0 22px", ())}>
        <Term
          term={t`Blowout`}
          def={t`A lopsided match that wastes one side's time. An 11–0 “pickle” is the canonical example.`}
        />
        <Term
          term={t`Inversion`}
          def={t`Ratings pointing the wrong way: a strong player rated low, a weak player rated high. Strong players who take it easy on beginners can invert their own rating — unintentional sandbagging.`}
        />
        <Term
          term={t`Oracle`}
          def={t`An organiser who knows everyone's true skill and rigs matches accordingly, overriding the ratings. Rigged matches starve the rating system: place a strong newcomer only against strong players and all the system sees is losses.`}
        />
      </div>
      <div
        style={ReactDOM.Style.make(
          ~background=ML.panel,
          ~border="1px solid " ++ ML.rule,
          ~padding="10px 14px",
          ~fontFamily=ML.monoFont,
          ~fontSize="11px",
          ~lineHeight="1.6",
          ~color=ML.mute,
          ~margin="0 0 10px",
          (),
        )}>
        {t`How the numbers were made: one simulation — 24 players, 4 courts, 100 rounds — replayed across 7 seeds in three synthetic clubs: varied (skills spread across the range, plus a ringer and a beginner), typical (about a 1.0 DUPR spread), and tight (a bunched pack). True skills are not frozen: as in a real club, about 20% of players improve gradually, one improves quickly — up to half a DUPR point, with gains tapering as they settle — and one slowly slips, the same players in every strategy's run so the comparison stays fair. Every round is a real solve through the same optimiser the app uses. Charts are 5-round rolling averages across all seeds; headline numbers summarise the last 25 rounds. Timescales: a real session is 12–14 rounds, so round 13 stands in for “one session” below, while the 100-round horizon — seven or eight sessions of persisted ratings — shows the system once everyone's rating is mature. Charts are interactive — hover for values, click a strategy to isolate its line.`}
      </div>
      // ------------------------------------------------------- tight spread
      <Section n="01" title={t`Tight skill spread`} />
      <SubHead title={t`Match quality`} />
      <Para>
        {t`A tight club here means everyone within about 0.68 DUPR points, most of the pack inside 0.4 — and it is where matchmaking should matter least. For the opening rounds it is: with everyone close, any way of dealing the courts produces playable games. But small differences still decide games, and the ratings learn them fast. Competitive+ holds a sustained lead over the avoid-repeats baseline from about round 5. One session in, it is blowing out 33% of games to the baseline's 44%; with mature ratings that becomes 8% against 46% — and Balanced Round Robin's 20%:`}
      </Para>
      <StatRow>
        <Stat value="8%" label={t`blowouts · Competitive+`} color={colorOf("cpa")} />
        <Stat value="46%" label={t`blowouts · random, no repeat`} color={colorOf("rndnov")} />
        <Stat value="79%" label={t`even games · Competitive+`} color={colorOf("cpa")} />
        <Stat value="64%" label={t`even games · random, no repeat`} color={colorOf("rndnov")} />
      </StatRow>
      <ReportChart
        data={dataOf(2)}
        runs={runsOf(2)}
        ids={qualityIds}
        metric={Quality}
        title={t`Match quality — tight club`}
        unit={t`· % chance the game ends level, by true skill · higher is better`}
        maxRound
        yDomain=[0.0, 100.0]
      />
      <SubHead title={t`Ratings convergence`} />
      <Para>
        {t`In a tight club even the static Competitive+ profile keeps up with Balanced Round Robin almost immediately: when everyone is close, a band drawn from noisy ratings is barely different from one drawn from true skill, so banding costs nothing here. The adaptive Competitive+ tracks Balanced Round Robin from the first round by construction — it runs it until ratings settle. The calibration phase earns its keep in the wider clubs below, where banding on noise genuinely restricts the movement that would fix the ratings.`}
      </Para>
      <ReportChart
        data={dataOf(2)}
        runs={runsOf(2)}
        ids={convergenceIds}
        metric={LadderError}
        title={t`Distance from truth — tight club`}
        unit={t`· mean ladder places off · lower is better`}
        maxRound
      />
      <Para>
        {t`In the real world assembling a tight club of similarly skilled players is challenging because on any given day a player's performance might fluctuate by 0.5 points or more. The rating system however can adjust for this variance within a few rounds of play.`}
      </Para>
      // ------------------------------------------------------- varied
      <Section n="02" title={t`Varied skill levels`} />
      <SubHead title={t`Match quality`} />
      <Para>
        {t`Most open-play sessions in Japan are more varied than the organiser likes to think: in the current pickleball scene it is hard to gather even one court of genuinely similar players at once if only simply due to day-to-day skill fluctuations.`}
      </Para>
      <Para>
        {t`The baseline here is what open play actually deals: random courts that avoid repeating partners and opponents. (Measured against pure random, avoiding repeats changes match quality not at all — novelty buys variety and a slightly faster ladder, nothing else.) From a cold start, Competitive+ pulls away from it within the first handful of rounds — by round 5 its games are already measurably better, because every result moves a cold rating a long way. Even a club of all-unrated players gets value inside their first session, though in this club the early gain is match quality; the blowouts barely move in one session, because preventing a varied club's worst games takes ratings accurate enough to see them coming. With mature ratings the gap is decisive:`}
      </Para>
      <StatRow>
        <Stat value="35%" label={t`blowouts · Competitive+`} color={colorOf("cpa")} />
        <Stat value="68%" label={t`blowouts · random, no repeat`} color={colorOf("rndnov")} />
        <Stat value="66%" label={t`even games · Competitive+`} color={colorOf("cpa")} />
        <Stat value="46%" label={t`even games · random, no repeat`} color={colorOf("rndnov")} />
      </StatRow>
      <ReportChart
        data={dataOf(0)}
        runs={runsOf(0)}
        ids={qualityIds}
        metric={Quality}
        title={t`Match quality — varied club`}
        unit={t`· % chance the game ends level, by true skill · higher is better`}
        maxRound
        yDomain=[0.0, 100.0]
      />
      <Para>
        {t`JP-style open play is the avoid-repeats baseline plus one intervention: a foursome is split when it is obviously lopsided — the pairs half a DUPR apart, the bar real organisers actually use. The surprise is that the intervention buys nothing measurable: JP lands within the error bars of its own baseline everywhere, a point or two of quality in this club at best. Splits that rare cannot move a session. Politeness that fixes only the egregious matches is worth almost nothing; the gains begin when every match is deliberately balanced, which is exactly what nobody does socially.`}
      </Para>
      <Para>
        {t`US-style open play — courts labelled by level, players choosing their own — does somewhat better: matches only form within the stronger or the weaker half of the club, so the skill gaps inside a match shrink. The simulation also models the format's social habits — about half of badly beaten teams run one revenge match, and close foursomes often stay on for another game; both mean replaying a match, and the games people choose to replay are usually the wrong ones. It nets out at 50% quality and 64% blowouts here, against the baseline's 46% and 68% — real, but a long way from matchmaking by rating, where Competitive+ reaches 66% and 35% in the same club. One caution for anyone submitting rated DUPR matches from such sessions: repeats and self-sorted courts carry little rating information, so they converge ratings poorly — the simulated ladder ends up more than two places off, against about one and a half for every other format.`}
      </Para>
      <SubHead title={t`Ratings convergence`} />
      <Para>
        {t`Balanced Round Robin converges best here too, but only by a hair over adaptive Competitive+ — and the two are effectively identical on quality and blowouts.`}
      </Para>
      <ReportChart
        data={dataOf(0)}
        runs={runsOf(0)}
        ids={convergenceIds}
        metric={LadderError}
        title={t`Distance from truth — varied club`}
        unit={t`· mean ladder places off · lower is better`}
        maxRound
      />
      <Para>
        {t`Early in my organising days I still switched from greedy, numerically balanced matches to banded Competitive+. Banding forces every match to come from a contiguous block of skill, even when that is numerically “unbalanced”. A rating cannot capture everything about a real game: the best and the worst player against two average players may balance mathematically, but in practice it plays worse than an “unbalanced” match of three 4.0s and a 5.0. Banding suppresses the measured quality score slightly because of this override — that is the price of never pairing a ringer with a total beginner just to make the numbers work out.`}
      </Para>
      // ------------------------------------------------------- typical
      <Section n="03" title={t`Typical 3.0–4.0 spread`} />
      <SubHead title={t`Match quality`} />
      <Para>
        {t`With a realistic 1.0-DUPR spread, Competitive+ pulls away from the baselines within the first handful of rounds, and one session in it already leads the avoid-repeats baseline by 9 points of quality and 10 points of blowouts. The full benefit arrives with mature ratings: 10% blowouts against the baseline's 62%, and a 78% chance of an even game against 53%. Those mature numbers match a hand-picked tight-skill club (79% and 8%) — the algorithm recovers by matchmaking what you would otherwise get by gatekeeping the roster:`}
      </Para>
      <StatRow>
        <Stat value="10%" label={t`blowouts · Competitive+`} color={colorOf("cpa")} />
        <Stat value="62%" label={t`blowouts · random, no repeat`} color={colorOf("rndnov")} />
        <Stat value="78%" label={t`even games · Competitive+`} color={colorOf("cpa")} />
        <Stat value="53%" label={t`even games · random, no repeat`} color={colorOf("rndnov")} />
      </StatRow>
      <ReportChart
        data={dataOf(1)}
        runs={runsOf(1)}
        ids={qualityIds}
        metric={Quality}
        title={t`Match quality — typical club`}
        unit={t`· % chance the game ends level, by true skill · higher is better`}
        maxRound
        yDomain=[0.0, 100.0]
      />
      <SubHead title={t`Ratings convergence`} />
      <Para>
        {t`Balanced Round Robin leads while ratings are still noise; the static Competitive+ profile catches it around round 13 — about one session — and the adaptive version never leaves its side. Once ratings are mature, every real strategy lands within about a quarter of a place of the same ladder — on accuracy they are tied inside the error bars, and the difference that remains is the quality of the games played along the way. The quality chart above shows the same trade-off from the other side: static banding matches Balanced Round Robin for the first ten rounds, falls behind by the end of the first session — 49% blowouts to its 40% at round 13, the cost of banding on ratings that are still noise — then overtakes for good around round 20 as the bands become real. The adaptive blend exists to take the better half of both.`}
      </Para>
      <ReportChart
        data={dataOf(1)}
        runs={runsOf(1)}
        ids={convergenceIds}
        metric={LadderError}
        title={t`Distance from truth — typical club`}
        unit={t`· mean ladder places off · lower is better`}
        maxRound
      />
      // ------------------------------------------------------- oracle
      <Section n="04" title={t`Why the Oracle never converges`} />
      <Para>
        {t`The Oracle knows everyone's real skill and hand-balances every match. It is in the field to demonstrate one thing: rigging matches by what you know prevents the ratings from ever learning it. Strong players are always split and cancel each other out, so no informative result ever arrives — the Oracle posts the best match quality of any strategy and the worst ladder accuracy, stuck around seven places off forever. US-style open play's starved ladder is the same effect arrived at by accident, in a milder dose.`}
      </Para>
      <Para>
        {t`The lesson for organisers: use manual seeding conservatively. The more you pre-place players at their true level, the slower their rating gets there on its own.`}
      </Para>
      <ReportChart
        data={dataOf(1)}
        runs={runsOf(1)}
        ids={oracleIds}
        metric={LadderError}
        title={t`Distance from truth — typical club, with the Oracle`}
        unit={t`· mean ladder places off · lower is better`}
        maxRound
      />
      // ------------------------------------------------------- conclusion
      <Section n="05" title={t`Conclusion`} />
      <Para>
        {t`Use Competitive+. The adaptive version opens with Balanced Round Robin while ratings are unknown, then switches to banded play as they settle — the fastest convergence available, with the best match quality in the field. Two-thirds of the gain arrives in the first session and most of the rest by the end of the second (63% → 73% → 79% quality in a typical club), and because ratings persist, each session starts where the last one left off.`}
      </Para>
      <Para>
        {t`What switching is worth, with mature ratings in a typical club: 23 points of match quality and blowouts cut from 59% to 10% against JP-style open play (which plays like dealing at random); 7 points and 18 fewer blowouts against a plain round-robin table; 17 points and 42 fewer against a curated private session run as open play.`}
      </Para>
      <CrossFieldChart data={crossFieldQuality} maxRound />
      <ReportChart
        data={dataOf(blowoutField)}
        runs={runsOf(blowoutField)}
        ids={qualityIds}
        metric={Blowouts}
        title={t`Blowout rate`}
        unit={t`· % of games decided by 9+ · lower is better`}
        maxRound
        yDomain=[0.0, 100.0]
        extra={fieldTabs}
      />
      <Para>
        {t`Blowouts fade more slowly than quality: 52% one session in, 30% after two, 19% by round 50, 8% by round 100 — most of the way to the Oracle's 5% floor. In a varied club they never fully go away: Competitive+ bottoms out near 35% and even the Oracle blows out 23%, because a ringer and a beginner make some matches unsaveable.`}
      </Para>
      <SubHead title={t`Level-controlled clubs`} />
      <Para>
        {t`A tight club gives the best floor — random dealing manages 64% quality there against 46% in a varied club — at some cost in ranking accuracy, since players who are genuinely close are hard to order. But controlling the roster does not control the matchups: dealt randomly, that same club still blows out 46% of its games; Competitive+ blows out 8% and holds 79% quality. The gap exists because skill is not a fixed number. Even hand-picked members fluctuate wildly day to day — improving in bursts, slumping, showing up tired — and a rating system accounts for that in real time, adjusting after every game, so each sessions' matches are built on current form rather than on the level everyone was admitted at. Pkuru keeps hidden ratings even for “unrated” events, so no one's public rating is at stake, and the same ratings pair you with the right drilling partner — even for drills, evenly matched partners matter. (I often prefer a wall: it beats most human drilling partners.)`}
      </Para>
      <SubHead title={t`Wide-level open plays`} />
      <Para>
        {t`This is where matchmaking lifts hardest. Blowouts are never fun — for the stronger team they are a waste of time — and members you subject to them often enough go elsewhere. Competitive+ prevents five of every six blowouts in a typical club, halves them in a genuinely varied one, and its banding lets a session holding a beginner group and an advanced group still resolve into good matches instead of carry games.`}
      </Para>
      <Para>
        {t`The idea that beginners and lower-rated players do not want balanced games is a myth — in the US and Vietnam, DUPR round robins run routinely at the 2.0–3.0 levels. Everyone benefits from an even match, and no rating needs to be at stake: the round robin tool can arrange matches by rating without submitting results.`}
      </Para>
      <SubHead title={t`Single-court events`} />
      <Para>
        {t`For a single court of five or six players, the rating system admittedly adds little. The tool still helps: it remembers who has partnered whom, keeps play counts even, and tracks each player's rating change round by round even with nothing submitted — the session runs fairly, and everyone sees how they actually did. People reliably overrate their own performance, even when they do not show it.`}
      </Para>
      <Para>
        {t`If you are going to use a round robin table at all, use the Pkuru Round Robin tool: the same table, better matches, every default tunable. And every simulation in this article can be rerun for a club shaped like yours.`}
      </Para>
      <a
        href="/matchmaking-lab"
        style={ReactDOM.Style.make(
          ~display="inline-block",
          ~fontFamily=ML.monoFont,
          ~fontSize="12px",
          ~letterSpacing="0.06em",
          ~fontWeight="600",
          ~color=ML.ink,
          ~border="1px solid " ++ ML.ink,
          ~padding="8px 14px",
          ~marginBottom="18px",
          (),
        )}>
        {t`Open the interactive Matchmaking Lab →`}
      </a>
      <Section n="06" title={t`Future improvements`} />
      <Para>
        {t`Ratings keep sharpening for 30–40 rounds — two to three sessions — and while the matchmaking is already better than the baseline by round 5, the first dozen rounds of a true cold start remain the roughest stretch of a club's life. I want to explore using score differentials to shorten them — potentially producing usable ratings within a round or two of an unrated player's first game. Currently the Round Robin tool already supports manually specified player rankings. The risk is that this is itself a form of oracle: reading more into a result than it actually says could tamper with convergence rather than speed it up.`}
      </Para>
      <Para>
        {t`Since we can simulate the match quality effects of adding a player into an event, we can create an RSVP system that admits player based on their impact to the session, rather than the simple first-come-first-serve setups most events have.`}
      </Para>
      <Para>
        {t`Our simulation currently handles players getting better and worse over time (change in their true underlying skill), but it doesn't handle random unrated drop in players that come back infrequently or never at all. It should also fluctuate a player's skill between sessions (about every 13 rounds) due to random day-to-day jitter in performance.`}
      </Para>
      <Para>
        {t`We have access to live match data from real sessions that use Round Robin tool, including match scores. That means I can calculate the effects of things like asymmetrical matches or the actual efficacy of the algorithms.`}
      </Para>
      <Para>
        {t`This is a live document, so I will be updating the modelling, data, and conclusions as they are discovered.`}
      </Para>
    </>
  }
}

// ---------------------------------------------------------------------------
// Page shell
// ---------------------------------------------------------------------------

@react.component
let make = () => {
  let (state, setState) = React.useState(() => None)

  React.useEffect0(() => {
    let _ = (
      async () => {
        switch await SimLabArchive.loadManifest() {
        | Error(e) => setState(_ => Some(Error(e)))
        | Ok(m) =>
          switch m.runs->Array.get(0) {
          | None => setState(_ => Some(Error(ts`No precomputed run is published.`)))
          | Some(entry) =>
            switch await SimLabArchive.loadRun(entry.file) {
            | Ok(l) => setState(_ => Some(Ok(l)))
            | Error(e) => setState(_ => Some(Error(e)))
            }
          }
        }
      }
    )()
    None
  })

  <div
    style={ReactDOM.Style.make(
      ~background=ML.paper,
      ~minHeight="100vh",
      ~padding="40px 16px 80px",
      (),
    )}>
    <article style={ReactDOM.Style.make(~maxWidth="760px", ~margin="0 auto", ())}>
      <div
        style={ReactDOM.Style.make(
          ~fontFamily=ML.monoFont,
          ~fontSize="11px",
          ~letterSpacing="0.16em",
          ~textTransform="uppercase",
          ~color=ML.mute,
          ~marginBottom="14px",
          (),
        )}>
        {t`Pkuru · matchmaking report`}
      </div>
      <h1
        style={ReactDOM.Style.make(
          ~fontFamily=serif,
          ~fontSize="42px",
          ~fontWeight="700",
          ~lineHeight="1.12",
          ~color=ML.ink,
          ~margin="0 0 14px",
          (),
        )}>
        {t`Matchmaking strategies, measured`}
      </h1>
      <p
        style={ReactDOM.Style.make(
          ~fontFamily=serif,
          ~fontSize="20px",
          ~fontStyle="italic",
          ~lineHeight="1.5",
          ~color=ML.mute,
          ~margin="0 0 18px",
          (),
        )}>
        {t`75,600 simulated games, nine strategies, three kinds of club — and one clear recommendation.`}
      </p>
      <div
        className="flex flex-wrap gap-x-5 gap-y-1"
        style={ReactDOM.Style.make(
          ~fontFamily=ML.monoFont,
          ~fontSize="10px",
          ~letterSpacing="0.05em",
          ~color=ML.mute,
          ~borderTop="1px solid " ++ ML.rule,
          ~borderBottom="1px solid " ++ ML.rule,
          ~padding="8px 0",
          ~marginBottom="30px",
          (),
        )}>
        <span> {t`18,900 rounds solved`} </span>
        <span> {t`24 players · 4 court`} </span>
        <span> {t`7 seeds per club`} </span>
        <span> {t`every round a real ILP solve`} </span>
      </div>
      {switch state {
      | None =>
        <div
          style={ReactDOM.Style.make(
            ~fontFamily=ML.monoFont,
            ~fontSize="12px",
            ~color=ML.mute,
            ~padding="40px 0",
            (),
          )}>
          {t`loading the precomputed run…`}
        </div>
      | Some(Error(e)) =>
        <div
          style={ReactDOM.Style.make(
            ~fontFamily=ML.monoFont,
            ~fontSize="12px",
            ~color=ML.ink,
            ~border="1px solid " ++ ML.rule,
            ~background=ML.panel,
            ~padding="14px 16px",
            (),
          )}>
          {t`Could not load the data behind this article: ${e}`}
        </div>
      | Some(Ok(loaded)) => <Article byField={loaded.byField} />
      }}
      <div
        style={ReactDOM.Style.make(
          ~borderTop="2px solid " ++ ML.ink,
          ~marginTop="46px",
          ~paddingTop="14px",
          (),
        )}>
        <a
          href="/matchmaking-lab"
          style={ReactDOM.Style.make(
            ~fontFamily=ML.monoFont,
            ~fontSize="11px",
            ~letterSpacing="0.06em",
            ~color=ML.ink,
            (),
          )}>
          {t`Run these simulations yourself in the interactive lab →`}
        </a>
      </div>
    </article>
  </div>
}
