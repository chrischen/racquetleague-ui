%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")

module Query = %relay(`
  query LeaguePageQuery($after: String, $first: Int, $before: String, $activitySlug: String!, $namespace: String!) {
    ... RatingListFragment @arguments(after: $after, first: $first, before: $before, activitySlug: $activitySlug, namespace: $namespace)
  }
`)

type loaderData = {
  pageKey: string,
  query: LeaguePageQuery_graphql.queryRef,
}
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

module PrizeInfo = {
  @module("./prize.jpg")
  external prizeImg: string = "default"
  open Lingui.Util
  open HeroIcons
  @react.component
  let make = () =>
    <div className="mx-auto max-w-7xl sm:px-6 lg:px-8 mb-24">
      <div
        className="relative isolate overflow-hidden bg-gray-900 px-6 py-20 sm:rounded-3xl sm:px-10 sm:py-24 lg:py-24 xl:px-24">
        <div
          className="mx-auto grid max-w-2xl grid-cols-1 gap-x-8 gap-y-16 sm:gap-y-20 lg:mx-0 lg:max-w-none lg:grid-cols-2 lg:items-center lg:gap-y-0">
          <div className="lg:row-start-2 lg:max-w-md">
            <h2 className="text-3xl font-bold tracking-tight text-white sm:text-4xl">
              {t`Next Prize: June 10`}
            </h2>
            <p className="mt-6 text-lg leading-8 text-gray-300">
              {t`This prize will be awarded to the top male and female players on this day.`}
            </p>
          </div>
          <img
            src={prizeImg}
            alt="Product screenshot"
            className="relative -z-20 min-w-full max-w-xl rounded-xl shadow-xl ring-1 ring-white/10 lg:row-span-4 lg:w-[64rem] lg:max-w-none"
            width="2432"
            height="1442"
          />
          <div
            className="max-w-xl lg:row-start-3 lg:mt-10 lg:max-w-md lg:border-t lg:border-white/10 lg:pt-10">
            <dl className="max-w-xl space-y-8 text-base leading-7 text-gray-300 lg:max-w-none">
              <div className="relative">
                <dt className="ml-9 inline-block font-semibold text-white">
                  <CloudArrowUpIcon
                    className="absolute left-1 top-1 h-5 w-5 text-indigo-500" \"aria-hidden"="true"
                  />
                  {t`Hesacore Grip`}
                </dt>
                {" "->React.string}
                <dd className="inline"> {t`Multiple colors available.`} </dd>
              </div>
            </dl>
          </div>
        </div>
        <div
          className="pointer-events-none absolute left-12 top-1/2 -z-10 -translate-y-1/2 transform-gpu blur-3xl lg:bottom-[-12rem] lg:top-auto lg:translate-y-0 lg:transform-gpu"
          ariaHidden=true>
          <div
            className="aspect-[1155/678] w-[72.1875rem] bg-gradient-to-tr from-[#ff80b5] to-[#9089fc] opacity-25"
            style={{
              clipPath: "polygon(74.1% 44.1%, 100% 61.6%, 97.5% 26.9%, 85.5% 0.1%, 80.7% 2%, 72.5% 32.5%, 60.2% 62.4%, 52.4% 68.1%, 47.5% 58.3%, 45.2% 34.5%, 27.5% 76.7%, 0.1% 64.9%, 17.9% 100%, 27.6% 76.8%, 76.1% 97.7%, 74.1% 44.1%)",
            }}
          />
        </div>
      </div>
    </div>
}

@genType @react.component
let make = () => {
  open Lingui.Util
  //let { fragmentRefs } = Fragment.use(events)
  let query = useLoaderData()
  Js.log(query.data.pageKey);
  // let viewer = GlobalQuery.useViewer()
  let {fragmentRefs} = Query.usePreloaded(~queryRef=query.data.query)

  let link = <a href="https://www.racquetleague.com"> {"Racquet League."->React.string} </a>
  <WaitForMessages>
    {() => {
      <>
        <PrizeInfo />
        <div className="py-10 text-white bg-leaguePrimary">
          <Layout.Container>
            <PageTitle>
              <span className="text-white font-extrabold text-3xl">
                {t`Recreational Doubles`}
              </span>
            </PageTitle>
            <p className="mt-5">
              {t`Play doubles games with different partners and receive an individual rating. Prizes are awarded monthly to top players.`}
            </p>
            <p>
              {t`Currently the league is in testing mode. To participate, please join the Pickleball events here:`}
              {" "->React.string}
              <a className="text-gray-200" href="https://www.racquetleague.com">
                {"> Racquet League <"->React.string}
              </a>
            </p>
          </Layout.Container>
        </div>
        <React.Suspense fallback={<Layout.Container> {t`Loading rankings...`} </Layout.Container>}>
          <RatingList ratings=fragmentRefs />
        </React.Suspense>
      </>
    }}
  </WaitForMessages>
}
