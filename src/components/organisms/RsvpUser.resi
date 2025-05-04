type props<'user, 'highlight, 'link, 'secondaryText, 'sigmaPercent, 'ratingPercent> = {
  user: 'user,
  highlight?: 'highlight,
  link?: 'link,
  secondaryText?: 'secondaryText,
  // rating?: 'rating,
  // sigma?: 'sigma,
  sigmaPercent?: 'sigmaPercent,
  ratingPercent?: 'ratingPercent,
}

let make: props<Rating.user, bool, string, string, float, float> => React.element
