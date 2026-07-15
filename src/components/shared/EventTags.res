// Shared level-tag → numeric minRating (mu) derivation. Mirrors the autofill in
// CreateLocationEventForm so events created via the bulk button and via the form
// agree on minRating. Skill level is encoded as a tag ("3.5+"); the create form
// derives the mu value from it, and so does the button.

let levelToRating = tag =>
  switch tag {
  | "2.5+" => Some(Rating.duprToMu(2.5))
  | "3.0+" => Some(Rating.duprToMu(3.0))
  | "3.5+" => Some(Rating.duprToMu(3.5))
  | "4.0+" => Some(Rating.duprToMu(4.0))
  | "4.5+" => Some(Rating.duprToMu(4.5))
  | "5.0+" => Some(Rating.duprToMu(5.0))
  | _ => None
  }

let specificLevels = ["2.5+", "3.0+", "3.5+", "4.0+", "4.5+", "5.0+"]

// The numeric minRating implied by a tag set: "all level" (or no level tag)
// means no floor; otherwise the lowest specific level tag present.
let minRatingFromTags = (tags: array<string>): option<float> =>
  if tags->Array.includes("all level") {
    None
  } else {
    specificLevels
    ->Array.find(level => tags->Array.includes(level))
    ->Option.flatMap(levelToRating)
  }
