// Storybook support for MatchmakingReport.stories.tsx; the app never imports
// this. The report takes no props: it loads the first precomputed run named in
// public/matchmaking-lab/runs.json (which Storybook serves) and writes the
// article around its charts. MatchmakingReportPage adds a back link and the
// language switcher above it; those are page chrome and not drawn here.
@genType @react.component
let make = () => <MatchmakingReport />
