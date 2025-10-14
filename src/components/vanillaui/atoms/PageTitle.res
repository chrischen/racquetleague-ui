@genType @react.component
let make = (~children) => {
  <div className="md:flex md:items-center md:justify-between mb-4">
    <div className="min-w-0 flex-1">
      <h1
        className="text-2xl font-bold leading-7  sm:truncate sm:text-3xl sm:tracking-tight flex flex-row">
        {children}
      </h1>
    </div>
  </div>
}
