// Storybook support for SelfCheckinDisplay.stories.tsx; the app never imports
// this. The display is props-only: the URL the QR code points at (the event
// page) and a close callback. Without a URL it encodes the current page.

/** An event page, as PlayerCheckin passes it. */
@genType
let eventUrl = "https://www.pkuru.com/events/evt-story-thursday-doubles"

/** A long URL (tracking parameters, a Japanese club slug): a denser code. */
@genType
let longUrl =
  "https://www.pkuru.com/ja/clubs/%E6%B8%8B%E8%B0%B7%E3%83%94%E3%83%83%E3%82%AF%E3%83%AB%E3%83%9C%E3%83%BC%E3%83%AB/events/evt-story-thursday-doubles?utm_source=kiosk&utm_medium=qr&utm_campaign=self-checkin&court=4"

@genType @react.component
let make = (~url: option<string>=?, ~onClose=() => ()) => <SelfCheckinDisplay onClose ?url />
