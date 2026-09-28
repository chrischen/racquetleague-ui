// Storybook support for MatchmakingLab.stories.tsx; the app never imports this.
// The lab takes no props: it fetches the saved-run manifest from
// public/matchmaking-lab/ (which Storybook serves) and loads a run when one is
// picked. As on MatchmakingLabPage, it fills the screen.
@genType @react.component
let make = () =>
  <div className="min-h-screen">
    <MatchmakingLab />
  </div>
