%%raw("import { t } from '@lingui/macro'")
open HeadlessUi
open HeroIcons
open Lingui.Util
let ts = Lingui.UtilString.t

type faq = {
  question: string,
  answer: string,
  image?: array<string>,
}

@module("./FairPlay/guide-1.webp")
external img1: string = "default"
@module("./FairPlay/guide-2.webp")
external img2: string = "default"
@module("./FairPlay/guide-3.webp")
external img3: string = "default"
@module("./FairPlay/guide-4.webp")
external img4: string = "default"
@module("./FairPlay/guide-5.webp")
external img5: string = "default"
@module("./FairPlay/guide-6.webp")
external img6: string = "default"
@module("./FairPlay/guide-7.webp")
external img7: string = "default"
@module("./FairPlay/guide-8.webp")
external img8: string = "default"
@module("./FairPlay/guide-9.webp")
external img9: string = "default"
@module("./FairPlay/guide-10.webp")
external img10: string = "default"
@module("./FairPlay/guide-11.webp")
external img11: string = "default"
@module("./FairPlay/guide-12.webp")
external img12: string = "default"
@module("./FairPlay/guide-13.webp")
external img13: string = "default"

let faqs: array<faq> = [
  {
    question: ts`Launching FairPlay`,
    answer: ts`The FairPlay system can be launched from any event page on Pkuru.com. The system will automatically load all signed up players, including those in the waitlist. Players who did not join the event can be added as a guest, but their ratings and results cannot be saved to Pkuru.com.`,
    image: [img1],
  },
  {
    question: ts`Start Screen`,
    answer: ts`Press the large blue button to launch the system. The 'Offline Mode' toggle should be used if there is no internet connection or if you want to test the system out without saving any results. In Offline mode, no submissions are made to Pkuru.com and if you delete the matches or close the web page there will be no permanent effects of your actions using the system. Additionally this screen shows the relative strengths of the players and at the bottom of the page there is a history of all the matches played.`,
    image: [img2],
  },
  {
    question: ts`Checkin Screen`,
    answer: ts`The system is composed of 3 main screns. The first is the checkin screen where you can enable/disable players for the session. Tap on a player's name to check them in. Green means the player is checked in. Check a player in if they are ready to play, and check them out if they are leaving early. If a player wants to take a break and it's not their turn yet, it's easiest to check them out and then check them back in next round.`,
    image: [img3],
  },
  {
    question: ts`Manage Courts and Player Breaks`,
    answer: ts`On the bottom left you can select the number of courts under management by the app. When it is set to a value greater than 0, the app will automatically track the number of times everyone has played and determine who should be taking a break. Players who should be taking a break will be highlighted in yellow. This is a suggestion, so you can still tap on them to select them for the next match.`,
    image: [img4],
  },
  {
    question: ts`Queue Screen`,
    answer: ts`The second screen is the Queue screen. This is where you can select players who want to play a match. On the bottom is a button to queue all players. This button will automatically select everyone and exclude the players who should be on break (highlighted in yellow). If you play matches in timed rounds, this is an easy way to select everyone who should participate in the next round of matches.`,
    image: [img5],
  },
  {
    question: ts`Generating Draws`,
    answer: ts`Once at least 4 players are selected (highlighted in green) from the Queue screen, you can generate draws with the blue button on the bottom right. The system will generate all possible combinations of matches for the given players based on the matchmaking strategy selected. Additionally it will show you the relative 'quality' of the matches and sort them from highest to lowest. Quality of the match means whether the match is going to be close or one-sided. The green highlighted match at the top is the 'recommended match' which uses some heuristics to select a match that balances quality while avoiding repeated teams or matches. The list of matches will also highlight previously played matches or pairs in yellow or red. This allows you as the organizer to determine whether to avoid repeated matches. Use the blue button to select a match which will then update the draws for the remaining players that were selected. Keep selecting matches until all players are in a match.`,
    image: [img6],
  },
  {
    question: ts`Matches Screen`,
    answer: ts`The third and final screen shows the active matches that are being played. The ordering of the teams is randomized, so you can use this to determine the serving team (usually the team on top).`,
    image: [img7],
  },
  {
    question: ts`Editing Matches`,
    answer: ts`The handlebars on the left side of each name can be used to drag and drop the players into a different match or re-arrange the teams. If you press the Enter Score button you can select the winner and/or enter the score. If you want to cancel the match you can press the '...' button.`,
    image: [img8],
  },
  {
    question: ts`Entering Results`,
    answer: ts`Tapping on the names on the left side can select the winner without entering scores. Optionally, the exact score can be entered into the number field on the right side of each match. Once the green border is around the winner, the entry is complete and you can leave it as it is. Once results are entered for all matches, you can use the blue button on the bottom right to submit all the results at once.If you enabled offline mode, no results are submitted to Pkuru.com, but ratings will still be updated locally on your device. Additionally the predicted winner is shown in the red bar at the bottom.`,
    image: [img9],
  },
  {
    question: ts`Match History`,
    answer: ts`By clicking on the Gear icon in the top left, you can go back to the start screen. At the bottom of this screen will be the match history.`,
    image: [img10],
  },
  {
    question: ts`Offline Mode`,
    answer: ts`If you enabled offline mode, you can go down this list and submit the results to Pkuru.com. Simply tap on the match, then click on the Submit button. Once the score shows 0 and 0 then it has successfully submitted. This step is not necessary if you did not enable offline mode. In normal Online Mode matches will be submitted as soon as you complete them from the Matches screen.`,
    image: [img11],
  },
  {
    question: ts`Player Options`,
    answer: ts`From the Queue screen you can select some players (highlighted in green) and take some special actions for them such as creating a team, anti-team, or setting their genders. The team feature is important if you have a group of players (2 minimum) who always want to play together, often called a 'fixed-pair.' The gender is important if you want to use the Gender-Mixed doubles option when choosing matches.`,
    image: [img12, img13],
  },
]

@react.component
let make = () => {
  <WaitForMessages>
    {_ =>
      <div className="bg-gray-900">
        <div className="mx-auto max-w-7xl px-6 py-24 sm:py-32 lg:px-8 lg:py-40">
          <div className="mx-auto max-w-4xl">
            <h2 className="text-4xl font-semibold tracking-tight text-white sm:text-5xl">
              {t`How to use FairPlay`}
            </h2>
            <dl className="mt-16 divide-y divide-white/10">
              {faqs
              ->Array.mapWithIndex((faq, i) =>
                <Disclosure key={Int.toString(i)} \"as"="div" className="py-6 first:pt-0 last:pb-0">
                  {_ => <>
                    <dt>
                      <DisclosureButton
                        className="group flex w-full items-start justify-between text-left text-white">
                        <span className="text-base/7 font-semibold">
                          {React.string(faq.question)}
                        </span>
                        <span className="ml-6 flex h-7 items-center">
                          <PlusSmallIcon
                            \"aria-hidden"="true" className="size-6 group-data-[open]:hidden"
                          />
                          <MinusSmallIcon
                            \"aria-hidden"="true"
                            className="size-6 group-[:not([data-open])]:hidden"
                          />
                        </span>
                      </DisclosureButton>
                    </dt>
                    <DisclosurePanel \"as"="dd" className="mt-2 pr-12">
                      <p className="text-base/7 text-gray-300"> {React.string(faq.answer)} </p>
                      <div className="w-1/2 mx-auto mt-4 flex justify-center">
                        {faq.image
                        ->Option.map(imgs =>
                          <div className="flex flex-row gap-2 justify-center items-center">
                            {imgs
                            ->Array.map(img => <img src=img className="w-full h-auto" />)
                            ->React.array}
                          </div>
                        )
                        ->Option.getOr(React.null)}
                      </div>
                    </DisclosurePanel>
                  </>}
                </Disclosure>
              )
              ->React.array}
            </dl>
          </div>
        </div>
      </div>}
  </WaitForMessages>
}
