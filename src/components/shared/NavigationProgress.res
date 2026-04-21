@react.component
let make = () => {
  let navigation = Router.useNavigation()
  let isNavigating = navigation.state == "loading" || navigation.state == "submitting"

  let (progress, setProgress) = React.useState(_ => 0.0)
  let (visible, setVisible) = React.useState(_ => false)
  let timerRef = React.useRef(Js.Nullable.null)

  let clearTimer = () => {
    switch timerRef.current->Js.Nullable.toOption {
    | Some(id) => Js.Global.clearInterval(id)
    | None => ()
    }
    timerRef.current = Js.Nullable.null
  }

  React.useEffect1(() => {
    if isNavigating {
      setProgress(_ => 0.15)
      setVisible(_ => true)

      let id = Js.Global.setInterval(() => {
        setProgress(prev => {
          if prev < 0.9 {
            prev +. (0.9 -. prev) *. 0.1
          } else {
            prev
          }
        })
      }, 200)
      timerRef.current = Js.Nullable.return(id)
    } else if visible {
      clearTimer()
      setProgress(_ => 1.0)

      let _ = Js.Global.setTimeout(() => {
        setVisible(_ => false)
        setProgress(_ => 0.0)
      }, 300)
    }

    Some(clearTimer)
  }, [isNavigating])

  if !visible {
    React.null
  } else {
    <>
      <FramerMotion.DivCss
        className="fixed top-0 left-0 z-50 h-0.5 bg-primary"
        animate={{width: Float.toString(progress *. 100.0) ++ "%"}}
        initial={{width: "0%", opacity: 1.0}}
      />
      <FramerMotion.DivCss
        className="fixed inset-0 z-40 pointer-events-none bg-black/5"
        animate={{opacity: isNavigating ? 1.0 : 0.0}}
        initial={{opacity: 0.0}}
      />
    </>
  }
}
