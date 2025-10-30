@react.component
let make = (~examples: array<string>, ~onExampleClick: string => unit) => {
  <div className="space-y-3">
    <p className="text-sm font-medium text-gray-700 dark:text-gray-300">
      {React.string("Try these examples:")}
    </p>
    <div className="flex flex-wrap gap-2">
      {examples
      ->Array.mapWithIndex((example, index) => {
        <button
          key={Int.toString(index)}
          onClick={_ => onExampleClick(example)}
          className="px-4 py-2 rounded-full bg-gray-100/80 dark:bg-gray-800/80 hover:bg-gray-200/80 dark:hover:bg-gray-700/80 text-sm text-gray-700 dark:text-gray-300 transition-colors backdrop-blur-sm border border-gray-200/50 dark:border-gray-700/50">
          {React.string(example)}
        </button>
      })
      ->React.array}
    </div>
  </div>
}
