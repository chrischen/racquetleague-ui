%%raw("import { css, cx } from '@linaria/core'")

@genType
let stringToElement: string => React.element = str => React.string(str)

// Binding like a global because cx is imported from escape hatch above
@variadic @val external cx: array<string> => string = "cx"

@val external env: string = "process.env.NODE_ENV"

let addLazyLoad = className => Util.cx(["lazyload", className])
module ReactCompareSlider = {
  @genType @react.component @module("react-compare-slider")
  external make: (
    ~itemOne: React.element,
    ~itemTwo: React.element,
    ~className: string=?,
  ) => React.element = "ReactCompareSlider"
}

module ReactCompareSliderImage = {
  @genType @react.component @module("react-compare-slider")
  external make: (
    ~src: string,
    ~alt: string,
    ~className: string=?,
    ~srcSet: string=?,
  ) => React.element = "ReactCompareSliderImage"
}
module ImgixParams = {
  @genType
  type t = {
    mutable auto: option<string>,
    mutable fit: option<string>,
    mutable crop: option<string>,
    @as("fp-z")
    mutable \"fp-z": option<string>,
    @as("fp-y")
    mutable \"fp-y": option<string>,
    @as("fp-x")
    mutable \"fp-x": option<string>,
    mutable ar: option<string>,
  }
  @genType @obj
  external make: (
    ~auto: string=?,
    ~fit: string=?,
    ~crop: string=?,
    ~\"fp-z": string=?,
    ~\"fp-x": string=?,
    ~\"fp-y": string=?,
    ~ar: string=?,
    unit,
  ) => t = ""

  let defaults = make(~fit="crop", ~crop="faces", ~auto="format", ())

  let addFormat = auto =>
    auto
    ->Belt.Option.map(auto => {
      let values = auto->String.split(",")
      switch values->Array.find(x => x == "format") {
      | Some(_) => auto
      | None => ["format"]->Array.concat(values)->Array.join(",")
      }
    })
    ->Belt.Option.getWithDefault("format")

  let addDefaults = (params: t) => {
    params.auto = params.auto->addFormat->Some
    params
  }
}
module Image = {
  @genType
  type t = {src: string, alt: string, imgixParams: option<ImgixParams.t>}
  let make = (~imgixParams: option<ImgixParams.t>=?, ~src: string, ~alt: string, ()) => {
    src: src,
    alt: alt,
    imgixParams: imgixParams,
  }
}
module Imgix = {
  type attributeConfig = {
    src: string,
    srcSet: string,
    sizes: string,
  }

  @genType @react.component @module("react-imgix")
  external make: (
    ~src: string,
    ~className: string=?,
    ~sizes: string=?,
    ~alt: string=?,
    ~attributeConfig: attributeConfig=?,
    ~imgixParams: ImgixParams.t=?,
    ~domain: string=?,
    ~width: int=?,
    ~height: int=?,
    ~disableLibraryParam: option<bool>=?,
  ) => React.element = "default"
}
module Source_Imgix = {
  @genType @react.component @module("react-imgix")
  external make: (
    ~src: string,
    ~className: string=?,
    ~sizes: string=?,
    ~alt: string=?,
    ~attributeConfig: Imgix.attributeConfig=?,
    ~imgixParams: ImgixParams.t=?,
    ~htmlAttributes: Js.t<{..}>=?,
    ~width: int=?,
    ~height: int=?,
    ~disableLibraryParam: bool=?,
  ) => React.element = "Source"
}

module Picture_Imgix = {
  @genType @react.component @module("react-imgix")
  external make: (~children: React.element) => React.element = "Picture"
}
/* module Source = {
  @react.component
  let make = (
    ~width: option<int>=?,
    ~height: option<int>=?,
    ~imgixParams: option<Js.t<{..}>>=?,
    ~htmlAttributes: Js.t<{..}>,
  ) => {
      <Source_Imgix ?src ?width ?height ?imgixParams htmlAttributes />,
  }
} */

module Breakpoints = {
  type t<'a, 'b> = {
    default: 'b,
    sm: option<'a>,
    md: option<'a>,
    lg: option<'a>,
    xl: option<'a>,
    xxl: option<'a>,
  }

  let toArray = breakpoints => {
    [
      (breakpoints.xxl, "1536"),
      (breakpoints.xl, "1280"),
      (breakpoints.lg, "1024"),
      (breakpoints.md, "768"),
      (breakpoints.sm, "640"),
    ]
  }
}
module Picture = {
  @genType
  type source<'attr> = {
    htmlAttributes: option<Js.t<{..} as 'attr>>,
    imgixParams: option<ImgixParams.t>,
    width: option<int>,
    height: option<int>,
    sizes: option<string>,
  }

  @genType
  type defaultSource = {
    width: option<int>,
    height: option<int>,
    sizes: option<string>,
    imgixParams: option<ImgixParams.t>,
  }

  type sources<'attr> = {
    sources: array<source<'attr>>,
    default: defaultSource,
  }
  /* type props<'attr, 'a> = {
    src: string,
    className: option<string>,
    sources: option<sources<'a>>,
    breakpoints: option<Breakpoints.t<source<'attr>, defaultSource>>,
    imgixParams: option<ImgixParams.t>,
    alt: option<string>,
    lazyLoad: bool,
  } */

  @genType @react.component
  let rec make = (
    /* {src, className, sources, breakpoints, imgixParams, alt, lazyLoad}: props<'attr, 'a>, */
    ~src: string,
    ~className: option<string>=?,
    ~sources: option<sources<'a>>=?,
    ~breakpoints: option<Breakpoints.t<source<'attr>, defaultSource>>=?,
    ~imgixParams: option<ImgixParams.t>=?,
    ~alt: option<string>=?,
    ~lazyLoad: bool=true,
  ) => {
    /* ~src: string,
    ~className: option<string>=?,
    ~sources: option<sources<'a>>=?,
    ~breakpoints: option<Breakpoints.t<source<'attr>, defaultSource>>=?,
    ~imgixParams: option<ImgixParams.t>=?,
    ~alt: option<string>=?,
    ~lazyLoad: bool=true, */

    let makeDefault = (source: defaultSource) =>
      <Imgix
        src
        className=?{lazyLoad
          ? className->Option.mapOr(""->addLazyLoad, addLazyLoad)->Some
          : className}
        imgixParams=?{Some(
          source.imgixParams->(
            params =>
              switch params {
              | None => imgixParams
              | a => a
              }
              ->// Spreading params create a new Js object with ALL the keys set,
              // including to null
              Belt.Option.map(ImgixParams.addDefaults)
              ->Belt.Option.getWithDefault(ImgixParams.defaults)
          ),
        )}
        ?alt
        sizes=?source.sizes
        width=?source.width
        height=?source.height
        attributeConfig=?{lazyLoad
          ? Some({
              Imgix.src: "data-src",
              srcSet: "data-srcset",
              sizes: "data-sizes",
            })
          : None}
        disableLibraryParam=Some(true)
      />
    let makeSource = (source: source<{..}>) =>
      <Source_Imgix
        src
        // @TODO: Use better key
        key={source.htmlAttributes
        ->Belt.Option.map(x => x["media"])
        ->Belt.Option.getWithDefault("")}
        htmlAttributes=?source.htmlAttributes
        width=?source.width
        height=?source.height
        sizes=?source.sizes
        imgixParams=?{Some(
          source.imgixParams->(
            params =>
              switch params {
              | None => imgixParams
              | a => a
              }
              ->Belt.Option.map(ImgixParams.addDefaults)
              ->Belt.Option.getWithDefault(ImgixParams.defaults)
          ),
        )}
        attributeConfig=?{lazyLoad
          ? Some({
              Imgix.src: "data-src",
              srcSet: "data-srcset",
              sizes: "data-sizes",
            })
          : None}
        disableLibraryParam=?Some(true)
      />

    <>
      {switch lazyLoad {
      | true =>
        <noscript>
          {React.createElement(
            make,
            {
              src,
              ?className,
              ?sources,
              ?breakpoints,
              ?imgixParams,
              ?alt,
              lazyLoad: false,
            },
          )}
        </noscript>
      | false => React.null
      }}
      {switch breakpoints {
      | Some(bp) => {
          let sources = []

          bp
          ->Breakpoints.toArray
          ->Js.Array2.forEach(((source, break)) => {
            source
            ->Belt.Option.map(source => {
              let source = {
                ...source,
                htmlAttributes: source.htmlAttributes
                ->Belt.Option.mapWithDefault(
                  {"media": `(min-width: ${break}px)`},
                  attrs => Js.Obj.assign({"media": `(min-width: ${break}px)`}, attrs),
                )
                ->Some,
              }
              sources->Js.Array2.push(makeSource(source))->ignore
            })
            ->ignore
          })

          <Picture_Imgix>
            {sources->React.array}
            {makeDefault(bp.default)}
          </Picture_Imgix>
        }
      | None =>
        sources
        ->Belt.Option.map(srcs => {
          <Picture_Imgix>
            {srcs.sources->Belt.Array.map(makeSource)->React.array}
            {makeDefault(srcs.default)}
          </Picture_Imgix>
        })
        ->Belt.Option.getWithDefault(React.null)
      }}
    </>
  }
}
module Img = {
  @genType @react.component
  let rec make = (
    ~src,
    ~className: option<string>=?,
    ~alt: option<string>=?,
    ~width: option<string>=?,
    ~height: option<string>=?,
    ~lazyLoad: bool=true,
  ) => {
    let base = <img ?width ?height ?alt />
    switch lazyLoad {
    | true =>
      <>
        <noscript>
          {React.createElement(
            make,
            {
              src,
              ?alt,
              ?className,
              ?width,
              ?height,
              lazyLoad: false,
            },
          )}
        </noscript>
        {React.cloneElement(
          base,
          {
            "src": None,
            "data-src": Some(src),
            "className": className->Option.mapOr(""->addLazyLoad, addLazyLoad),
          },
        )}
      </>
    | false =>
      React.cloneElement(
        base,
        {
          "src": Some(src),
          "data-src": None,
          "className": className,
        },
      )
    }
  }
}

module DImg = {
  @genType @react.component
  let rec make = (
    ~src: string,
    ~alt: option<string>=?,
    ~className: option<string>=?,
    ~imgixParams: option<ImgixParams.t>=?,
    ~domain: option<string>=?,
    ~sizes: option<string>=?,
    ~breakpoints: option<Breakpoints.t<string, string>>=?,
    ~width: option<int>=?,
    ~height: option<int>=?,
    ~lazyLoad: bool=true,
  ) => {
    let sizes = switch breakpoints {
    | Some(breakpoints) =>
      {
        let sizes =
          breakpoints
          ->Breakpoints.toArray
          ->Belt.Array.reduce("", (sizes, (value, size)) => {
            switch value {
            | Some(value) =>
              switch sizes {
              | "" => `(min-width: ${size}px) ` ++ value
              | _ => sizes ++ ", " ++ `(min-width: ${size}px) ` ++ value
              }
            | None => sizes
            }
          })
        sizes->Some
      }->Belt.Option.map(sizes =>
        switch sizes {
        | "" => breakpoints.default
        | _ => `${sizes}, ${breakpoints.default}`
        }
      )
    | None => sizes
    }
    <>
      {switch lazyLoad {
      | true =>
        <noscript>
          {React.createElement(
            make,
            {
              src,
              ?alt,
              ?className,
              ?imgixParams,
              ?domain,
              ?sizes,
              ?breakpoints,
              ?width,
              ?height,
              lazyLoad: false,
            },
          )}
        </noscript>
      | _ => React.null
      }}
      {env == "development"
        ? <Img
            ?className src ?alt lazyLoad
          />
        : <Imgix
            className=?{lazyLoad ? className->Option.mapOr(""->addLazyLoad, addLazyLoad)->Some : className}
            src
            ?alt
            imgixParams=?{Some(
              imgixParams
              ->Belt.Option.map(ImgixParams.addDefaults)
              ->Belt.Option.getWithDefault(ImgixParams.defaults),
            )}
            ?domain
            ?sizes
            ?width
            ?height
            attributeConfig=?{lazyLoad
              ? Some({Imgix.src: "data-src", srcSet: "data-srcset", sizes: "data-sizes"})
              : None}
            disableLibraryParam=Some(true)
          />}
    </>
  }
}

module ExclamationIcon = {
  module Icon = {
    @module("@heroicons/react/solid") @react.component
    external make: (~className: string, ~\"aria-hidden": string) => React.element =
      "ExclamationIcon"
  }
  let style = Util.cx(["h-5", "w-5", "text-yellow-400"])
  @genType @react.component
  let make = (~ariaHidden) => <Icon className={style} \"aria-hidden"=ariaHidden />
}

module Alert = {
  @genType @react.component
  let make = (~title, ~message) => {
    <div className={Util.cx(["rounded-md", "bg-yellow-50", "p-4", "mb-8"])}>
      <div className={%raw("cx('flex')")}>
        <div className={%raw("cx('flex-shrink-0')")}>
          <ExclamationIcon ariaHidden="true" />
        </div>
        <div className="ml-3">
          <h3 className="text-sm font-bold text-yellow-800"> {React.string(title)} </h3>
          <div
            className={%raw("cx(css`
              font-family: 'futura-pt', sans-serif;
          `, 'mt-2','text-sm', 'text-yellow-700')")}>
            <p> {React.string(message)} </p>
          </div>
        </div>
      </div>
    </div>
  }
}

module PageHeading = {
  let style = Util.cx(["py-8"])
  let actionStyle = Util.cx([
    %raw("css`
      a {
        font-family: 'futura-pt', Helvetica, sans-serif;
        @apply ml-3 inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-bold text-white bg-primary-900 hover:bg-primary-800 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-900;
      }
  `"),
    "mt-4",
    "flex",
    "md:mt-0",
    "md:ml-4",
  ])

  @genType @react.component
  let make = (~title, ~action, ~description) => {
    <div className="py-8">
      <div className={%raw("cx('md:flex', 'md:items-center', 'md:justify-between')")}>
        <div className={%raw("cx('flex-1', 'min-w-0')")}>
          <h1
            className={%raw(
              "cx('text-2xl', 'font-bold', 'leading-7', 'text-gray-900', 'sm:text-3xl', 'sm:truncate')"
            )}>
            {React.string(title)}
          </h1>
          /* <p className={%raw("cx('text-sm font-medium text-gray-500
           * mb-3')")}> {React.string("We stand with Ukraine.")} </p> */
          <p className={%raw("cx('mb-3')")}> {description} </p>
        </div>
        <div className={actionStyle}> {action} </div>
      </div>
    </div>
  }
}
module Press = {
  let style = Util.cx([
    %raw("css`
  img {
    @apply h-5;
  }`
  "),
    "mt-6",
    "grid",
    "grid-cols-2",
    "gap-8",
    "md:grid-cols-3",
    "lg:grid-cols-4",
  ])
  @genType @react.component
  let make = () => <>
    <p
      className={%raw(
        "cx('text-center','text-sm','font-semibold','uppercase','text-gray-500','tracking-wide')"
      )}>
      {React.string("Select mentions in the press")}
    </p>
    <div className={style}>
      <div
        className={%raw(
          "cx('col-span-1','flex','justify-center','md:col-span-1','lg:col-span-1')"
        )}>
        <a href="/press">
          <img
            src="//static3.instapainting.com/images/press/mini-logos/wired.png"
            srcSet="//static3.instapainting.com/images/press/mini-logos/wired@2x.png 2x"
            alt="Wired Magazine Instapainting Robo Painter"
          />
        </a>
      </div>
      <div
        className={%raw(
          "cx('col-span-1','flex','justify-center','md:col-span-1','lg:col-span-1')"
        )}>
        <a href="/press">
          <img
            src="//static3.instapainting.com/images/press/mini-logos/techcrunch.png"
            srcSet="//static3.instapainting.com/images/press/mini-logos/techcrunch.png 2x"
            alt="Instapainting.com on Techcrunch"
          />
        </a>
      </div>
      <div
        className={%raw(
          "cx('col-span-1','flex','justify-center','md:col-span-1','lg:col-span-1')"
        )}>
        <a href="/press">
          <img
            src="//static3.instapainting.com/images/press/mini-logos/engadget.png"
            srcSet="//static3.instapainting.com/images/press/mini-logos/engadget@2x.png 2x"
            alt="Instapainting.com AI Painter on Engadget"
          />
        </a>
      </div>
      <div
        className={%raw(
          "cx('col-span-1','flex','justify-center','md:col-span-1','lg:col-span-1')"
        )}>
        <a href="/press" rel="nofollow">
          <img
            src="//static3.instapainting.com/images/press/mini-logos/backchannel.png"
            srcSet="//static3.instapainting.com/images/press/mini-logos/backchannel@2x.png 2x"
            alt="Instapainting.com on Backchannel"
          />
        </a>
      </div>
      <div
        className={%raw(
          "cx('col-span-1','flex','justify-center','md:col-span-1','lg:col-span-1','lg:col-start-2')"
        )}>
        <a href="/press">
          <img
            src="//static3.instapainting.com/images/press/mini-logos/artnet.png"
            srcSet="//static3.instapainting.com/images/press/mini-logos/artnet@2x.png 2x"
            alt="Intrepid Robot Artist Creates 36-Hour Crowd-Sourced Painting"
          />
        </a>
      </div>
      <div
        className={%raw(
          "cx('col-span-1','flex','justify-center','md:col-span-1','lg:col-span-1')"
        )}>
        <a href="/press">
          <img
            src="//static3.instapainting.com/images/press/mini-logos/mental_floss.png"
            srcSet="//static3.instapainting.com/images/press/mini-logos/mental_floss@2x.png 2x"
            alt="A Robot Spent 36 Hours Painting This Abstract Masterpiece"
          />
        </a>
      </div>
    </div>
  </>
}

module Hero = {
  @genType @react.component
  let make = (
    ~title: string,
    ~title2: string,
    ~description: React.element,
    ~action1: React.element,
    ~action2: React.element,
    ~image: React.element,
  ) => {
    <>
      <div className={%raw("cx('relative','sm:pt-8')")}>
        <div className={%raw("cx('absolute','inset-x-0','bottom-0','h-1/2','bg-gray-100')")} />
        <div className={%raw("cx('max-w-screen-2xl','mx-auto','sm:px-6','lg:px-8')")}>
          <div className={%raw("cx('relative','shadow-xl','sm:rounded-2xl','sm:overflow-hidden')")}>
            <div className={%raw("cx('absolute','inset-0')")}>
              {React.cloneElement(
                image,
                {
                  "src": "https://images.instapainting.com/61ca669e008a00c2258b4596.jpg?auto=format&fit=crop,max&w=2830&q=80&sat=-100",
                  "className": %raw("cx('h-full','w-full','object-cover')"),
                },
              )}
              <div
                className={%raw("cx('absolute','inset-0','bg-primary-900','mix-blend-multiply')")}
              />
            </div>
            <div
              className={%raw(
                "cx('relative','px-4','py-16','sm:px-6','sm:py-24','lg:py-32','lg:px-8')"
              )}>
              <h1
                className={%raw(
                  "cx('text-center','text-4xl','font-extrabold','tracking-tight','sm:text-5xl','lg:text-6xl')"
                )}>
                <span className={%raw("cx('block','text-white')")}> {React.string(title)} </span>
                <span className={%raw("cx('block','text-primary-800')")}>
                  {React.string(title2)}
                </span>
              </h1>
              <p
                className={%raw(
                  "cx('mt-6','max-w-lg','mx-auto','text-center','text-xl','text-primary-900','sm:max-w-3xl')"
                )}>
                {description}
              </p>
              <div
                className={%raw(
                  "cx('mt-10','max-w-sm','mx-auto','sm:max-w-none','sm:flex','sm:justify-center')"
                )}>
                <div
                  className={%raw(
                    "cx('space-y-4','sm:space-y-0','sm:mx-auto','sm:inline-grid','sm:grid-cols-2','sm:gap-5')"
                  )}>
                  {React.cloneElement(
                    action1,
                    {
                      "className": %raw(
                        "cx('flex','items-center','justify-center','px-4','py-3','border','border-transparent','text-base','font-medium','rounded-md','shadow-sm','text-primary-900','bg-white','sm:px-8')"
                      ),
                    },
                  )}
                  {React.cloneElement(
                    action2,
                    {
                      "className": %raw(
                        "cx('flex items-center justify-center px-4 py-3 border border-transparent text-base font-medium rounded-md shadow-sm text-white bg-primary-900 bg-opacity-60 hover:bg-opacity-70 sm:px-8')"
                      ),
                    },
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div className={%raw("cx('bg-gray-100')")}>
        <div
          className={%raw("cx('max-w-screen-2xl','mx-auto','py-16','px-4','sm:px-6','lg:px-8')")}>
          <Press />
        </div>
      </div>
    </>
  }
}

module Hero2 = {
  @genType @react.component
  let make = (
    ~title: string,
    ~title2: string,
    ~description: React.element,
    ~action1: React.element,
    ~action2: React.element,
    ~image: React.element,
  ) =>
    <main className={%raw("cx('lg:relative')")}>
      <div
        className={%raw(
          "cx('mx-auto','max-w-7xl','w-full','pt-16','pb-20','text-center','lg:py-48','lg:text-left')"
        )}>
        <div className={%raw("cx('px-4','lg:w-1/2','sm:px-8','xl:pr-16')")}>
          <h1
            className={%raw(
              "cx('text-4xl','tracking-tight','font-extrabold','text-gray-900','sm:text-5xl','md:text-6xl','lg:text-5xl','xl:text-6xl')"
            )}>
            <span className={%raw("cx('block','xl:inline')")}> {React.string(title)} </span>
            <span className={%raw("cx('block','text-primary-900','xl:inline')")}>
              {React.string(title2)}
            </span>
          </h1>
          <p
            className={%raw(
              "cx('mt-3','max-w-md','mx-auto','text-lg','text-gray-500','sm:text-xl','md:mt-5','md:max-w-3xl')"
            )}>
            {description}
          </p>
          <div className={%raw("cx('mt-10','sm:flex','sm:justify-center','lg:justify-start')")}>
            <div className={%raw("cx('rounded-md','shadow')")}>
              {React.cloneElement(
                action1,
                {
                  "className": %raw(
                    "cx('w-full','flex','items-center','justify-center','px-8','py-3','border','border-transparent','text-base','font-medium','rounded-md','text-white','bg-primary-900','hover:bg-primary-800','md:py-4','md:text-lg','md:px-10')"
                  ),
                },
              )}
            </div>
            <div className={%raw("cx('mt-3','rounded-md','shadow','sm:mt-0','sm:ml-3')")}>
              {React.cloneElement(
                action2,
                {
                  "className": %raw(
                    "cx('w-full','flex','items-center','justify-center','px-8','py-3','border','border-transparent','text-base','font-medium','rounded-md','text-primary-900','bg-white','hover:bg-gray-50','md:py-4','md:text-lg','md:px-10')"
                  ),
                },
              )}
            </div>
          </div>
        </div>
      </div>
      <div
        className={%raw(
          "cx('relative','w-full','h-64','sm:h-72','md:h-96','lg:absolute','lg:inset-y-0','lg:right-0','lg:w-1/2','lg:h-full')"
        )}>
        {React.cloneElement(
          image,
          {"className": %raw("cx('absolute','inset-0','w-full','h-full','object-cover')")},
        )}
      </div>
    </main>
}
module HeroSlider = {
  @genType @react.component
  let make = (
    ~title: string,
    ~subtitle: option<string>=?,
    ~title2: string,
    ~description: React.element,
    ~action1: React.element,
    ~image1: Image.t,
    ~image2: Image.t,
  ) => {
    <div className={%raw("cx('relative','bg-white','overflow-hidden')")}>
      <div className={%raw("cx('hidden','lg:block','lg:absolute','lg:inset-0')")} ariaHidden=true>
        <svg
          className={%raw(
            "cx('absolute','top-0','left-1/2','transform','translate-x-64','-translate-y-8')"
          )}
          width={640->Belt.Int.toString}
          height={784->Belt.Int.toString}
          fill="none"
          viewBox="0 0 640 784">
          <defs>
            <pattern
              id="9ebea6f4-a1f5-4d96-8c4e-4c2abf658047"
              x={118->Belt.Int.toString}
              y={0->Belt.Int.toString}
              width={20->Belt.Int.toString}
              height={20->Belt.Int.toString}
              patternUnits="userSpaceOnUse">
              <rect
                x={0->Belt.Int.toString}
                y={0->Belt.Int.toString}
                width={4->Belt.Int.toString}
                height={4->Belt.Int.toString}
                className={%raw("cx('text-gray-200')")}
                fill="currentColor"
              />
            </pattern>
          </defs>
          <rect
            y={72->Belt.Int.toString}
            width={640->Belt.Int.toString}
            height={640->Belt.Int.toString}
            className={%raw("cx('text-gray-50')")}
            fill="currentColor"
          />
          <rect
            x={118->Belt.Int.toString}
            width={404->Belt.Int.toString}
            height={784->Belt.Int.toString}
            fill="url(#9ebea6f4-a1f5-4d96-8c4e-4c2abf658047)"
          />
        </svg>
      </div>
      <div className={%raw("cx('relative','pt-6','pb-16','sm:pb-24','lg:pb-32')")}>
        <Layout.Container>
          <main className={%raw("cx('mt-16','sm:mt-24','lg:mt-32')")}>
            <div className={%raw("cx('lg:grid','lg:grid-cols-12','lg:gap-8')")}>
              <div
                className={%raw(
                  "cx('sm:text-center','md:max-w-2xl','md:mx-auto','lg:col-span-6','lg:text-left')"
                )}>
                <h1>
                  <span
                    className={%raw(
                      "cx('mt-1','block','text-4xl','tracking-tight','font-extrabold','sm:text-5xl','xl:text-6xl')"
                    )}>
                    <span className={%raw("cx('block','text-gray-900')")}>
                      {React.string(title)}
                    </span>
                    <span className={%raw("cx('block','text-primary-900')")}>
                      {React.string(title2)}
                    </span>
                  </span>
                </h1>
                <h2>
                  <span
                    className={%raw(
                      "cx('block','text-sm','font-semibold','uppercase','tracking-wide','text-gray-500','sm:text-base','lg:text-sm','xl:text-base')"
                    )}>
                    {subtitle->Belt.Option.mapWithDefault(React.null, React.string)}
                  </span>
                </h2>
                <p
                  className={%raw(
                    "cx('mt-3','text-base','text-gray-500','sm:mt-5','sm:text-xl','lg:text-lg','xl:text-xl')"
                  )}>
                  {description}
                </p>
                <div
                  className={%raw(
                    "cx('mt-8','sm:max-w-lg','sm:mx-auto','sm:text-center','lg:text-left','lg:mx-0')"
                  )}>
                  <p className={%raw("cx('text-base','font-medium','text-gray-900')")} />
                  {React.cloneElement(
                    action1,
                    {
                      "className": %raw(
                        "cx('w-full','px-6','py-3','border','border-transparent','text-base','font-medium','rounded-md','text-white','bg-gray-800','shadow-sm','hover:bg-gray-900','focus:outline-none','focus:ring-2','focus:ring-offset-2','focus:ring-indigo-500',' sm:flex-shrink-0','sm:inline-flex','sm:items-center','sm:w-auto')"
                      ),
                    },
                  )}
                </div>
              </div>
              <div
                className={%raw(
                  "cx('mt-12','relative','sm:max-w-lg','sm:mx-auto','lg:mt-0','lg:max-w-none','lg:mx-0','lg:col-span-6','lg:flex','lg:items-center')"
                )}>
                <svg
                  className={%raw(
                    "cx('absolute','top-0','left-1/2','transform','-translate-x-1/2','-translate-y-8','scale-75','origin-top','sm:scale-100','lg:hidden')"
                  )}
                  width={640->Belt.Int.toString}
                  height={784->Belt.Int.toString}
                  fill="none"
                  viewBox="0 0 640 784"
                  ariaHidden=true>
                  <defs>
                    <pattern
                      id="4f4f415c-a0e9-44c2-9601-6ded5a34a13e"
                      x={118->Belt.Int.toString}
                      y={0->Belt.Int.toString}
                      width={20->Belt.Int.toString}
                      height={20->Belt.Int.toString}
                      patternUnits="userSpaceOnUse">
                      <rect
                        x={0->Belt.Int.toString}
                        y={0->Belt.Int.toString}
                        width={4->Belt.Int.toString}
                        height={4->Belt.Int.toString}
                        className={%raw("cx('text-gray-200')")}
                        fill="currentColor"
                      />
                    </pattern>
                  </defs>
                  <rect
                    y={72->Belt.Int.toString}
                    width={640->Belt.Int.toString}
                    height={640->Belt.Int.toString}
                    className={%raw("cx('text-gray-50')")}
                    fill="currentColor"
                  />
                  <rect
                    x={118->Belt.Int.toString}
                    width={404->Belt.Int.toString}
                    height={784->Belt.Int.toString}
                    fill="url(#4f4f415c-a0e9-44c2-9601-6ded5a34a13e)"
                  />
                </svg>
                <div
                  className={%raw(
                    "cx('relative','mx-auto','w-full','rounded-lg','shadow-lg','lg:max-w-md')"
                  )}>
                  <button
                    type_="button"
                    className={%raw(
                      "cx('relative','block','w-full','bg-white','rounded-lg','overflow-hidden','focus:outline-none','focus:ring-2','focus:ring-offset-2','focus:ring-indigo-500')"
                    )}>
                    <span className={%raw("cx('sr-only')")}>
                      {React.string(
                        "Drag the slider to compare between the original photo and the AI generated artistic style version",
                      )}
                    </span>
                    <div className={%raw("cx('w-full')")}>
                      <ReactCompareSlider
                        itemOne={<DImg
                          src=image1.src
                          breakpoints={
                            Breakpoints.default: "calc(100vw-(1rem*2))", // This item has a special 2rem padding on both sides
                            sm: Some("calc(640px - (1.5rem*3) - (1.5rem*2))"),
                            md: Some("calc(768px - (1.5rem*3) - (1.5rem*2))"),
                            lg: Some("calc(1024px - (1.5rem*3) - (2rem*2))"),
                            xl: Some("calc(1280px - (2rem*3) - (2rem*2))"),
                            xxl: Some("calc(1536px - (2rem*3) - (2rem*2))"),
                          }
                          lazyLoad=false
                          alt=image1.alt
                        />}
                        itemTwo={<DImg
                          src=image2.src
                          breakpoints={
                            default: "calc(100vw-(1rem*2))", // This item has a special 2rem padding on both sides
                            sm: Some("calc(640px - (1.5rem*3) - (1.5rem*2))"),
                            md: Some("calc(768px - (1.5rem*3) - (1.5rem*2))"),
                            lg: Some("calc(1024px - (1.5rem*3) - (2rem*2))"),
                            xl: Some("calc(1280px - (2rem*3) - (2rem*2))"),
                            xxl: Some("calc(1536px - (2rem*3) - (2rem*2))"),
                          }
                          lazyLoad=false
                          alt=image2.alt
                        />}
                      />
                    </div>
                  </button>
                </div>
              </div>
            </div>
          </main>
        </Layout.Container>
      </div>
    </div>
  }
}
module HalfBg = {
  let x = children =>
    <div className={%raw("cx('relative')")}>
      <div className={%raw("cx('absolute inset-0 flex flex-col z-0')")} ariaHidden=true>
        <div className={%raw("cx('flex-1')")} />
        <div className={%raw("cx('flex-1 w-full bg-gray-800')")} />
      </div>
      <div className={%raw("cx('max-w-7xl mx-auto px-4 sm:px-6 relative z-10')")}> {children} </div>
    </div>

  @genType @react.component
  let make = (~children, ~callToAction=?) =>
    switch callToAction {
    | None => x(children)
    | Some(cta) =>
      <>
        {x(children)}
        <div className={%raw("cx('bg-gray-800')")}>
          <div className={%raw("cx('max-w-7xl mx-auto pb-8 px-4 sm:pb-12 sm:px-6 lg:px-8')")}>
            {cta}
          </div>
        </div>
      </>
    }
}

module Domain = {
  module CarouselCard = {
    type t = {
      title: string,
      subtitle: string,
      src: string,
      imageAlt: string,
      link: string,
    }
  }
}
module CarouselCard = {
  let hoverStyle = %raw("css`
    --tw-transform: translateX(var(--tw-translate-x))
    translateY(var(--tw-translate-y)) rotate(var(--tw-rotate))
    skewX(var(--tw-skew-x)) skewY(var(--tw-skew-y))
    scaleX(var(--tw-scale-x)) scaleY(var(--tw-scale-y));

    @apply rounded-lg transition-transform hover:-translate-y-1 hover:bg-primary-900 duration-300;
    &:hover {
      /* transform: scaleX(1.05) scaleY(1.05); */
      @apply rounded-lg scale-105;
    }
  `")
  let cardText = %raw("cx('relative text-center text-white')")
  let titleStyle = cx([cardText, %raw("css`font-family: Georgia;`"), "mt-auto", "text-xl"])
  let subtitleStyle = cx([cardText, %raw("cx('italic text-sm')")])
  @react.component
  let make = (~card: Domain.CarouselCard.t) =>
    <a
      key={card.title}
      href={card.link}
      role="listitem"
      className={cx([
        %raw("cx('relative w-56 h-80 p-6 flex flex-col overflow-hidden')"),
        hoverStyle,
      ])}>
      <span ariaHidden=true className={%raw("cx('absolute inset-0')")}>
        <DImg
          className={%raw("cx('w-full h-full object-center object-cover rounded-lg')")}
          src={card.src}
          imgixParams={ImgixParams.make(~auto="format", ~fit="crop", ~crop="focalpoint", ())}
          width=224
          height=320
          alt={card.imageAlt}
          lazyLoad=true
        />
      </span>
      <span
        ariaHidden=true
        className={%raw(
          "cx('absolute inset-x-0 bottom-0 h-2/3 bg-gradient-to-t from-gray-800 opacity-50')"
        )}
      />
      <h2 className={titleStyle}> {React.string(card.title)} </h2>
      <h3 className={subtitleStyle}> {React.string(card.subtitle)} </h3>
    </a>
}
module CardCarousel = {
  @genType @react.component
  let make = (
    ~cards: array<Domain.CarouselCard.t>,
    ~title: string,
    ~moreText: string,
    ~moreLink: string,
  ) => {
    <div className={%raw("cx('xl:mx-auto xl:px-0')")}>
      <div
        className={%raw(
          "cx('px-0 sm:px-0 sm:flex sm:items-center sm:justify-between lg:px-0 xl:px-0')"
        )}>
        <h2 className={%raw("cx('text-2xl font-extrabold tracking-tight text-gray-900')")}>
          {React.string(title)}
        </h2>
        <a
          href=moreLink
          className={%raw(
            "cx('hidden text-sm font-semibold text-primary-900 hover:text-primary-900 sm:block')"
          )}>
          {React.string(moreText)}
          <span ariaHidden=true> {React.string(` \u2192`)} </span>
        </a>
      </div>
      <div className={%raw("cx('mt-4 flow-root')")}>
        <div className={%raw("cx('-my-2')")}>
          <div
            className={%raw(
              "cx('box-content -mx-8 py-2 relative h-96 overflow-x-auto overflow-y-hidden')"
            )}>
            <div className={%raw("cx('absolute py-6 px-8 min-w-full flex space-x-8')")} role="list">
              {cards->Belt.Array.map(card => <CarouselCard key={card.src} card />)->React.array}
            </div>
          </div>
        </div>
      </div>
      <div className={%raw("cx('mt-0 px-4 sm:hidden text-center')")}>
        <a
          href=moreLink
          className={%raw(
            "cx('block text-sm font-semibold text-primary-900 hover:text-primary-900')"
          )}>
          {React.string(moreText)}
          <span ariaHidden=true> {React.string(` \u2192`)} </span>
        </a>
      </div>
    </div>
  }
}
