// Rules for the note sent with an invite, checked in the composer only.
//
// They nudge organizers to write something for each person: long enough to
// say something, and not the note they just sent someone else. The server does
// not enforce them. They are a convenience, so the last note sent is kept in
// page state and forgotten on reload.

// The minimum, in weighted units (see weightedLength): 20 characters of
// English, or about 10 of Japanese, Chinese or Korean.
let minLength = 20

// Whether a code point is from a script that packs a word or more into each
// character: Chinese, Japanese and Korean, with their full-width punctuation
// and forms (and Yi, which sits inside the same block range).
let isWide = (cp: int) =>
  (cp >= 0x1100 && cp <= 0x11FF) || // Hangul Jamo
  (cp >= 0x2E80 && cp <= 0xA4CF) || // CJK radicals and symbols, kana, Bopomofo, CJK ideographs, Yi
  (cp >= 0xAC00 && cp <= 0xD7AF) || // Hangul syllables
  (cp >= 0xF900 && cp <= 0xFAFF) || // CJK compatibility ideographs
  (cp >= 0xFE30 && cp <= 0xFE4F) || // CJK compatibility forms
  (cp >= 0xFF00 && cp <= 0xFFEF) || // Half-width and full-width forms
  (cp >= 0x20000 && cp <= 0x3FFFF) // Supplementary ideographs

// The note's code points: an emoji or a rare ideograph outside the basic
// plane is one character, not the two UTF-16 units String.length counts.
let codePoints = (s: string): array<int> => {
  let points = []
  let i = ref(0)
  while i.contents < s->String.length {
    switch s->String.codePointAt(i.contents) {
    | Some(cp) =>
      points->Array.push(cp)
      i := i.contents + (cp > 0xFFFF ? 2 : 1)
    | None => i := s->String.length
    }
  }
  points
}

// The note's length with each Chinese, Japanese or Korean character counted
// as two and everything else as one, as Twitter/X weighs posts. A plain count
// would demand twice as much from a Japanese note as from an English one.
let weightedLength = (s: string): int =>
  s->codePoints->Array.reduce(0, (total, cp) => total + (isWide(cp) ? 2 : 1))

type problem =
  | Empty
  // How many more characters are needed, counted in the note's own script:
  // a note with Chinese, Japanese or Korean in it needs half as many.
  | TooShort(int)
  | SameAsPrevious

// Case and spacing are ignored, so a pasted note with a stray space or a
// changed capital still counts as a repeat.
let normalize = (s: string): string =>
  s->String.trim->String.toLowerCase->String.replaceRegExp(%re("/\s+/g"), " ")

let check = (~message: string, ~previous: option<string>): option<problem> => {
  let trimmed = message->String.trim
  let length = trimmed->weightedLength
  if trimmed == "" {
    Some(Empty)
  } else if length < minLength {
    let perCharacter = trimmed->codePoints->Array.some(isWide) ? 2 : 1
    let missing = minLength - length
    Some(TooShort((missing + perCharacter - 1) / perCharacter))
  } else if previous->Option.mapOr(false, p => normalize(p) == normalize(trimmed)) {
    Some(SameAsPrevious)
  } else {
    None
  }
}
