type props<'user, 'highlight, 'link, 'sigmaPercent, 'ratingPercent> = {
  user: 'user,
  highlight?: 'highlight,
  link?: 'link,
  // rating?: 'rating,
  // sigma?: 'sigma,
  sigmaPercent?: 'sigmaPercent,
  ratingPercent?: 'ratingPercent,
}

let make: props<Rating.user, bool, string, float, float> => React.element
