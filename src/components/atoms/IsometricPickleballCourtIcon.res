// Isometric pickleball court glyph for the event page's location header.
// Draws in `currentColor`, so callers pick the colour with text-* classes.
@react.component
let make = (~className: string="") =>
  <svg viewBox="0 0 50 31" fill="none" className ariaHidden=true>
    <g transform="matrix(1 0.28 -0.55 0.5 27 1)">
      <rect
        x="0"
        y="0"
        width="20"
        height="44"
        stroke="currentColor"
        strokeWidth="1.6"
        vectorEffect="non-scaling-stroke"
      />
      /* Kitchen lines: seven feet from each side of the net. */
      <path
        d="M0 15H20M0 29H20"
        stroke="currentColor"
        strokeWidth="1.25"
        vectorEffect="non-scaling-stroke"
      />
      /* Net dividing the two sides of the court. */
      <path
        d="M0 22H20" stroke="currentColor" strokeWidth="1.6" vectorEffect="non-scaling-stroke"
      />
      /* Service center lines stop at the kitchen. */
      <path
        d="M10 0V15M10 29V44"
        stroke="currentColor"
        strokeWidth="1.25"
        vectorEffect="non-scaling-stroke"
      />
    </g>
  </svg>
