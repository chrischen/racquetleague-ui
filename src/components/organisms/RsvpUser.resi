
type props<'user, 'highlight, 'link, 'rating, 'ratingPercent> = {
  user: 'user,
  highlight?: 'highlight,
  link?: 'link,
  rating?: 'rating,
  ratingPercent?: 'ratingPercent,
}

let make: props<Rating.user, bool, string, float, float> => React.element
