// PreformattedParagraph - Component that converts line breaks into separate paragraphs
@react.component
let make = (~text: string, ~className: string="mb-2 last:mb-0") => {
  Js.log(text)
  text
  ->Js.String2.split("\n")
  ->Array.map(paragraph => paragraph->Js.String2.trim)
  ->Array.filter(paragraph => paragraph !== "")
  ->Array.mapWithIndex((paragraph, index) =>
    <p key={index->Int.toString} className> {paragraph->React.string} </p>
  )
  ->React.array
}
