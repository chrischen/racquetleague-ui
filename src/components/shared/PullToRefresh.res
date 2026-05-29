%%raw("import { t } from '@lingui/macro'")

// ─── DOM bindings ───────────────────────────────────────────────────────────

@val @scope(("window", "document")) external documentBody: Dom.element = "body"
@val @scope(("window", "document")) external documentElement: Dom.element = "documentElement"
@val @scope(("window", "document"))
external scrollingElement: Js.Nullable.t<Dom.element> = "scrollingElement"
@val @scope("window") external getComputedStyle: Dom.element => {..} = "getComputedStyle"
@get external parentElement: Dom.element => Js.Nullable.t<Dom.element> = "parentElement"
@get external scrollTop: Dom.element => float = "scrollTop"

type touchEvent
type touch
@get external touches: touchEvent => array<touch> = "touches"
@get external clientY: touch => float = "clientY"
@send external preventDefault: touchEvent => unit = "preventDefault"
@send
external addEventListener: (Dom.element, string, touchEvent => unit, {..}) => unit =
  "addEventListener"
@send
external removeEventListener: (Dom.element, string, touchEvent => unit) => unit =
  "removeEventListener"

// ─── Constants ──────────────────────────────────────────────────────────────

let threshold = 70.
let maxPull = 120.
let damping = 0.55
let indicatorRestHeight = 56.

// ─── Mutable drag state ─────────────────────────────────────────────────────

type dragState = {
  mutable pulling: bool,
  mutable captured: bool,
  mutable startY: float,
  mutable distance: float,
}

// ─── Scroll parent finder ───────────────────────────────────────────────────

let fallbackScrollEl = () => scrollingElement->Nullable.toOption->Option.getOr(documentElement)

let rec findScrollParent = (el: Dom.element): Dom.element =>
  switch el->parentElement->Nullable.toOption {
  | None => fallbackScrollEl()
  | Some(p) if p === documentBody => fallbackScrollEl()
  | Some(p) =>
    let overflow: string = getComputedStyle(p)["overflowY"]
    if overflow === "auto" || overflow === "scroll" || overflow === "overlay" {
      p
    } else {
      findScrollParent(p)
    }
  }

// ─── Types ──────────────────────────────────────────────────────────────────

type pullToRefreshResult = {
  pullDistance: float,
  isRefreshing: bool,
  isPullRefreshing: bool,
  triggerRefresh: unit => unit,
}

// ─── Hook ───────────────────────────────────────────────────────────────────

let usePullToRefresh = (
  anchorRef: React.ref<Js.Nullable.t<Dom.element>>,
  onRefresh: unit => Promise.t<unit>,
): pullToRefreshResult => {
  let (pullDistance, setPullDistance) = React.useState(() => 0.)
  let (isRefreshing, setIsRefreshing) = React.useState(() => false)
  let onRefreshRef = React.useRef(onRefresh)
  onRefreshRef.current = onRefresh
  let drag: React.ref<dragState> = React.useRef({
    pulling: false,
    captured: false,
    startY: 0.,
    distance: 0.,
  })
  let refreshingRef = React.useRef(false)
  let pullTriggeredRef = React.useRef(false)

  React.useEffect0(() => {
    switch anchorRef.current->Nullable.toOption {
    | None => None
    | Some(anchor) =>
      let el = findScrollParent(anchor)

      let handleStart = (e: touchEvent) => {
        if el->scrollTop > 0. {
          ()
        } else {
          switch e->touches->Array.get(0) {
          | None => ()
          | Some(t) =>
            drag.current = {pulling: true, captured: false, startY: t->clientY, distance: 0.}
          }
        }
      }

      let handleMove = (e: touchEvent) => {
        let d = drag.current
        if d.pulling {
          switch e->touches->Array.get(0) {
          | None => ()
          | Some(t) =>
            let raw = t->clientY -. d.startY
            if raw <= 0. {
              d.pulling = false
            } else {
              let v = raw *. damping
              let dampened = v < maxPull ? v : maxPull
              d.distance = dampened
              if !d.captured && el->scrollTop <= 0. {
                d.captured = true
              }
              if d.captured {
                e->preventDefault
                setPullDistance(_ => dampened)
              }
            }
          }
        }
      }

      let handleEnd = (_: touchEvent) => {
        let d = drag.current
        drag.current = {pulling: false, captured: false, startY: 0., distance: 0.}
        if !d.captured {
          setPullDistance(_ => 0.)
        } else if d.distance >= threshold {
          if !refreshingRef.current {
            refreshingRef.current = true
            pullTriggeredRef.current = true
            setIsRefreshing(_ => true)
            setPullDistance(_ => indicatorRestHeight)
            onRefreshRef.current()
            ->Promise.then(() => {
              refreshingRef.current = false
              pullTriggeredRef.current = false
              setIsRefreshing(_ => false)
              setPullDistance(_ => 0.)
              Promise.resolve()
            })
            ->Promise.catch(_ => {
              refreshingRef.current = false
              pullTriggeredRef.current = false
              setIsRefreshing(_ => false)
              setPullDistance(_ => 0.)
              Promise.resolve()
            })
            ->ignore
          }
        } else {
          setPullDistance(_ => 0.)
        }
      }

      el->addEventListener("touchstart", handleStart, {"passive": true})
      el->addEventListener("touchmove", handleMove, {"passive": false})
      el->addEventListener("touchend", handleEnd, {"passive": true})
      el->addEventListener("touchcancel", handleEnd, {"passive": true})

      Some(
        () => {
          el->removeEventListener("touchstart", handleStart)
          el->removeEventListener("touchmove", handleMove)
          el->removeEventListener("touchend", handleEnd)
          el->removeEventListener("touchcancel", handleEnd)
        },
      )
    }
  })

  let triggerRefresh = React.useCallback(() => {
    if !refreshingRef.current {
      refreshingRef.current = true
      setIsRefreshing(_ => true)
      onRefreshRef.current()
      ->Promise.then(() => {
        refreshingRef.current = false
        setIsRefreshing(_ => false)
        Promise.resolve()
      })
      ->Promise.catch(_ => {
        refreshingRef.current = false
        setIsRefreshing(_ => false)
        Promise.resolve()
      })
      ->ignore
    }
  }, [])

  let isPullRefreshing = isRefreshing && pullTriggeredRef.current
  {pullDistance, isRefreshing, isPullRefreshing, triggerRefresh}
}

// ─── Pull indicator component ────────────────────────────────────────────────

module Indicator = {
  @react.component
  let make = (~pullDistance: float, ~isRefreshing: bool) => {
    let ts = Lingui.UtilString.t
    let ready = pullDistance >= threshold
    let rotate = min(pullDistance /. threshold *. 180., 180.)
    let isResting = pullDistance == 0. && !isRefreshing
    let transition = if isResting {
      "height 280ms cubic-bezier(0.22, 1, 0.36, 1)"
    } else if isRefreshing {
      "height 200ms ease-out"
    } else {
      "none"
    }

    <WaitForMessages>
      {() =>
        <div
          style={ReactDOM.Style.make(
            ~height=`${pullDistance->Float.toFixed(~digits=0)}px`,
            ~transition,
            (),
          )}
          className="overflow-hidden flex items-end justify-center pointer-events-none">
          <div
            className="pb-3 flex items-center gap-1.5 text-[11px] font-mono text-gray-500 dark:text-gray-400 select-none">
            {isRefreshing
              ? <Lucide.Loader2
                  size=13 className="animate-spin text-[#65a30d] dark:text-[#bdf25d]"
                />
              : <span
                  style={ReactDOM.Style.make(
                    ~display="inline-flex",
                    ~transform=`rotate(${rotate->Float.toFixed(~digits=1)}deg)`,
                    ~transition="transform 120ms ease-out",
                    (),
                  )}>
                  <Lucide.ChevronDown
                    size=13 className={ready ? "text-[#65a30d] dark:text-[#bdf25d]" : ""}
                  />
                </span>}
            <span>
              {(
                isRefreshing
                  ? ts`Refreshing…`
                  : ready
                  ? ts`Release to refresh`
                  : ts`Pull to refresh`
              )->React.string}
            </span>
          </div>
        </div>}
    </WaitForMessages>
  }
}
