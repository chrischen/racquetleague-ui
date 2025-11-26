%%raw("import { t } from '@lingui/macro'")
open HeadlessUi
open HeroIcons
let ts = Lingui.UtilString.t

type faq = {
  question: string,
  answer: React.element,
  image?: array<string>,
}

@react.component
let make = () => {
  open Lingui.Util
  <WaitForMessages>
    {_ => {
      let faqs: array<faq> = [
        {
          question: ts`Icons Guide`,
          answer: <div className="space-y-4">
            <p> {t`Here is a guide to the icons used in the Event Manager:`} </p>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="flex items-start gap-3 p-3 bg-slate-50 rounded-lg">
                <Lucide.UserCheck className="w-6 h-6 text-blue-600 flex-shrink-0 mt-1" />
                <div>
                  <div className="font-semibold text-slate-900"> {t`Player Check-in`} </div>
                  <div className="text-sm text-slate-600">
                    {t`Toggle player attendance. Green means checked in.`}
                  </div>
                </div>
              </div>
              <div className="flex items-start gap-3 p-3 bg-slate-50 rounded-lg">
                <Lucide.Shuffle className="w-6 h-6 text-blue-600 flex-shrink-0 mt-1" />
                <div>
                  <div className="font-semibold text-slate-900"> {t`Generate / Rebalance`} </div>
                  <div className="text-sm text-slate-600">
                    {t`Generate new draws or rebalance the round or match.`}
                  </div>
                </div>
              </div>
              <div className="flex items-start gap-3 p-3 bg-slate-50 rounded-lg">
                <Lucide.RotateCcw className="w-6 h-6 text-blue-600 flex-shrink-0 mt-1" />
                <div>
                  <div className="font-semibold text-slate-900"> {t`Reset`} </div>
                  <div className="text-sm text-slate-600">
                    {t`Reset a round to the original draw if you changed something.`}
                  </div>
                </div>
              </div>
              <div className="flex items-start gap-3 p-3 bg-slate-50 rounded-lg">
                <Lucide.Users className="w-6 h-6 text-slate-600 flex-shrink-0 mt-1" />
                <div>
                  <div className="font-semibold text-slate-900"> {t`Manage Teams`} </div>
                  <div className="text-sm text-slate-600">
                    {t`Create fixed teams or anti-teams (players who shouldn't play together).`}
                  </div>
                </div>
              </div>
              <div className="flex items-start gap-3 p-3 bg-slate-50 rounded-lg">
                <Lucide.Settings className="w-6 h-6 text-slate-500 flex-shrink-0 mt-1" />
                <div>
                  <div className="font-semibold text-slate-900"> {t`Player Settings`} </div>
                  <div className="text-sm text-slate-600">
                    {t`Edit player details like name, gender, or payment status.`}
                  </div>
                </div>
              </div>
              <div className="flex items-start gap-3 p-3 bg-slate-50 rounded-lg">
                <Lucide.ArrowUpNarrowWide className="w-6 h-6 text-blue-600 flex-shrink-0 mt-1" />
                <div>
                  <div className="font-semibold text-slate-900"> {t`Adjust Seeds`} </div>
                  <div className="text-sm text-slate-600">
                    {t`Manually adjust player ratings for the event.`}
                  </div>
                </div>
              </div>
              <div className="flex items-start gap-3 p-3 bg-slate-50 rounded-lg">
                <Lucide.Circle className="w-6 h-6 text-blue-500 fill-blue-500 flex-shrink-0 mt-1" />
                <div>
                  <div className="font-semibold text-slate-900"> {t`Service Indicator`} </div>
                  <div className="text-sm text-slate-600">
                    {t`Blue dot indicates the team that has service in the match.`}
                  </div>
                </div>
              </div>
            </div>
          </div>,
        },
        {
          question: ts`Generating Draws`,
          answer: <div className="space-y-3">
            <p>
              {t`The Draw Generator allows you to create matches based on different strategies:`}
            </p>
            <ul className="list-disc pl-5 space-y-2 text-slate-700">
              <li>
                <strong> {t`Competitive`} </strong>
                {t`: Players are divided into similar skill levels. Teams are balanced to create close matches.`}
              </li>
              <li>
                <strong> {t`Mixed`} </strong>
                {t`: Teams are balanced by skill, but players are not strictly separated by level.`}
              </li>
              <li>
                <strong> {t`Round-Robin`} </strong>
                {t`: Classic round-robin format where everyone plays with everyone.`}
              </li>
            </ul>
            <p>
              {t`In Competitive or Mixed mode, the system will regenerate future matches when you select the winner of the matches in the current or past rounds. This is recommended in order to optimize future rounds based on the new data. In Round-Robin mode, the future rounds will not change unless you manually change them.`}
            </p>
            <p>
              {t`You can also adjust the number of courts. The system requires 4 players per court.`}
            </p>
          </div>,
        },
        {
          question: ts`Round Management`,
          answer: <div className="space-y-3">
            <p> {t`Each round has several management options:`} </p>
            <div className="space-y-2">
              <div className="flex items-center gap-2">
                <Lucide.Shuffle className="w-4 h-4 text-blue-600" />
                <span className="font-semibold"> {t`Rebalance`} </span>
              </div>
              <p className="text-sm text-slate-600 ml-6">
                {t`Regenerates the current round with the same players but moves players around to balance the skill level of each court. This will aggressively optimize each court to have the highest chance of having a tie, but may not divide the court by level groups. Useful if you replace a player and need the matches to be balanced again.`}
              </p>
            </div>
            <div className="space-y-2">
              <div className="flex items-center gap-2">
                <Lucide.Mars className="w-4 h-4 text-blue-600" />
                <Lucide.Venus className="w-4 h-4 text-pink-600" />
                <span className="font-semibold"> {t`Reset (Mixed)`} </span>
              </div>
              <p className="text-sm text-slate-600 ml-6">
                {t`Resets the round and attempts to create mixed-gender pairs.`}
              </p>
            </div>
            <div className="space-y-2">
              <div className="flex items-center gap-2">
                <Lucide.RotateCcw className="w-4 h-4 text-red-600" />
                <span className="font-semibold"> {t`Reset (All)`} </span>
              </div>
              <p className="text-sm text-slate-600 ml-6">
                {t`Resets the round to the original matches.`}
              </p>
            </div>
          </div>,
        },
        {
          question: ts`Player Management`,
          answer: <div className="space-y-3">
            <p> {t`Manage players directly from the Check-in list:`} </p>
            <ul className="list-disc pl-5 space-y-2 text-slate-700">
              <li> {t`Click a player's name to toggle check-in status.`} </li>
              <li>
                {t`Use the`}
                <Lucide.Settings className="w-3 h-3 inline mx-1 text-slate-500" />
                {t`icon to edit player details (Name, Gender, Paid status).`}
              </li>
              <li>
                {t`Use`}
                <Lucide.Users className="w-3 h-3 inline mx-1 text-slate-600" />
                {t`to create Teams (always play together) or Anti-Teams (never play together on the same court).`}
              </li>
              <li>
                {t`Use`}
                <Lucide.ArrowUpNarrowWide className="w-3 h-3 inline mx-1 text-blue-600" />
                {t`to adjust player ratings (seeds) for the event. This affects matchmaking but not their permanent rating.`}
              </li>
            </ul>
          </div>,
        },
        {
          question: ts`Entering Results & Syncing`,
          answer: <div className="space-y-3">
            <p>
              {t`Enter scores directly on the match cards. Tap to select a winner, or press and hold to input the score as well.`}
            </p>
            <p>
              {t`Once matches are complete, use the`}
              <span
                className="inline-flex items-center gap-1 mx-1 px-2 py-0.5 rounded bg-blue-600 text-white text-xs font-bold">
                <Lucide.RotateCcw className="w-3 h-3" />
                {t`Sync Scores`}
              </span>
              {t`button at the bottom of the page to submit all results to the server.`}
            </p>
            <div className="flex items-center gap-2 text-sm text-amber-600 bg-amber-50 p-2 rounded">
              <Lucide.AlertCircle className="w-4 h-4" />
              {t`Scores are not saved permanently until you Sync.`}
            </div>
          </div>,
        },
        {
          question: ts`Offline Mode`,
          answer: <div className="space-y-3">
            <p> {t`The Event Manager works offline! All data is saved locally to your device.`} </p>
            <p>
              {t`You can run an entire event without internet. Just make sure to Sync Scores when you have a connection again to save the results.`}
            </p>
            <p className="text-sm text-slate-500">
              {t`Note: If you clear your browser data, local event data will be lost.`}
            </p>
          </div>,
        },
      ]

      <div className="max-w-4xl mx-auto px-4 py-8 pb-32">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-slate-900 mb-2"> {t`Event Manager Guide`} </h1>
          <p className="text-lg text-slate-600">
            {t`Complete guide to running events with the Event Manager.`}
          </p>
        </div>
        <div className="space-y-4">
          {faqs
          ->Array.mapWithIndex((faq, i) => {
            <Disclosure key={i->Int.toString}>
              {_ =>
                <div className="bg-white rounded-lg border border-slate-200 overflow-hidden">
                  <DisclosureButton
                    className="group w-full px-6 py-4 text-left flex items-center justify-between bg-white hover:bg-slate-50 transition-colors">
                    <span className="text-lg font-semibold text-slate-900">
                      {faq.question->React.string}
                    </span>
                    <ChevronDownIcon
                      className="w-5 h-5 text-slate-500 transition-transform group-data-[open]:rotate-180"
                    />
                  </DisclosureButton>
                  <DisclosurePanel className="px-6 pb-6 text-slate-600">
                    {faq.answer}
                    {switch faq.image {
                    | Some(images) =>
                      <div className="mt-4 grid gap-4">
                        {images
                        ->Array.mapWithIndex((img, j) =>
                          <img
                            key={j->Int.toString}
                            src=img
                            className="rounded-lg border border-slate-200 shadow-sm w-full"
                            loading=#"lazy"
                          />
                        )
                        ->React.array}
                      </div>
                    | None => React.null
                    }}
                  </DisclosurePanel>
                </div>}
            </Disclosure>
          })
          ->React.array}
        </div>
      </div>
    }}
  </WaitForMessages>
}
