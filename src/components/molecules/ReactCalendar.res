type tileCb = {activeStartDate: Js.Date.t, date: Js.Date.t, view: string}
@module("react-calendar") @react.component
external make: (
  ~value: Js.Date.t,
	~locale: string=?,
  ~className: string=?,
  ~calendarType: string=?,
  ~onChange: (Js.Date.t, 'event) => unit=?,
  ~onClickDay: (Js.Date.t, 'event) => unit=?,
  ~tileContent: tileCb => React.element=?,
  ~tileClassName: tileCb => option<string>=?,
) => React.element = "Calendar"
