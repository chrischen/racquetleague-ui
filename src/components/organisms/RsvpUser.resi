type props<'user, 'highlight, 'link, 'rating, 'sigma, 'sigmaPercent, 'ratingPercent> = {
  user: 'user,
  highlight?: 'highlight,
  link?: 'link,
  rating?: 'rating,
  sigma?: 'sigma,
  sigmaPercent?: 'sigmaPercent,
  ratingPercent?: 'ratingPercent,
}

let make: props<Rating.user, bool, string, float, float, float, float> => React.element
