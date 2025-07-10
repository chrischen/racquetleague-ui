// Type for a single data point (an array of numbers/coordinates)
type dataPoint = array<float>

// Type for the input dataset (an array of data points)
type dataSet = array<dataPoint> // This type alias is still useful for clarity

// Type for a single centroid (an array of numbers/coordinates)
type centroid = array<float>

// Type for the data points belonging to a single cluster
type clusterPoints = array<dataPoint>

// Type for the object representing a single cluster in the result
type clusterResult = {
  centroid: centroid,
  points: clusterPoints,
}

// Type for the overall result of the kMeans function (an array of clusters)
type kMeansOutput = array<clusterResult>

// --- Binding for kMeans ---
// Type for the options object passed to the kMeans function
type kMeansOptions = {
  data: dataSet, // data is now a field in the options object
  k: int, // Assuming 'K' for consistency, verify with library
  maxIterations?: int,
  tolerance?: float,
  // Add other potential options from the library if they exist
}

// External binding for the kMeans function.
// Now takes a single kMeansOptions argument.
@module("k-means-clustering-js")
external kMeans: kMeansOptions => kMeansOutput = "kMeans"

// --- Binding for runKMeansWithOptimalInertia ---
// Type for the options object passed to the runKMeansWithOptimalInertia function
type runKMeansOptions = {
  data: dataSet, // data is now a field in the options object
  k: int, // Assuming 'K' for consistency, verify with library
  numRuns?: int,
  maxIterations?: int,
  tolerance?: float,
  // Add other potential options from the library if they exist
}

// External binding for the runKMeansWithOptimalInertia function.
// Now takes a single runKMeansOptions argument.
@module("k-means-clustering-js")
external runKMeansWithOptimalInertia: runKMeansOptions => kMeansOutput =
  "runKMeansWithOptimalInertia"

module DataPoint = {
  type t = dataPoint
  let getAvg = (point: t) =>
    point->Array.reduce(0., (acc, value) => acc +. value) /. float(point->Array.length)
}
module ClusterResult = {
  type t = clusterResult
  let getMinMax = (cluster: t) => {
    let min =
      cluster.points->Array.reduce(100., (acc, pt) =>
        acc < pt->DataPoint.getAvg ? acc : pt->DataPoint.getAvg
      )
    let max =
      cluster.points->Array.reduce(0., (acc, pt) =>
        acc > pt->DataPoint.getAvg ? acc : pt->DataPoint.getAvg
      )
    (min, max)
  }
  let concat = (a: t, b: t): t => {
    {
      centroid: a.centroid->Array.concat(b.centroid),
      points: a.points->Array.concat(b.points),
    }
  }
}
module SortedClusters = {
  type t = Util.NonEmptyArray.t<clusterResult>
  let make = (t): t =>
    t
    ->Array.toSorted((a, b) => {
      let clusterA = a.centroid
      let clusterB = b.centroid
      clusterA < clusterB ? 1. : -1.
    })
    ->Util.NonEmptyArray.fromArray
  let getMin = (clusters: t) => {
    clusters
    ->Util.NonEmptyArray.toArray
    ->Array.get(0)
    ->Option.map(c => c->ClusterResult.getMinMax->fst)
    ->Option.getOr(0.)
  }
}
/*
Example Usage:

let sampleData: dataSet = [
  [1.0, 2.0, 3.0],
  [1.1, 2.1, 3.1],
  [1.2, 2.2, 3.2],
  [8.0, 9.0, 10.0],
  [8.1, 9.1, 10.1],
  [8.2, 9.2, 10.2],
  [15.0, 16.0, 17.0],
  [15.1, 16.1, 17.1],
]

let printClusterResult = (output: kMeansOutput, title: string) => {
  Js.log("--- " ++ title ++ " ---")
  output->Array.forEachWithIndex((cluster, i) => {
    Js.log("Cluster " ++ (i + 1)->Int.toString ++ ":")
    Js.log2("  Centroid:", cluster.centroid)
    Js.log("  Points in this cluster:")
    cluster.points->Array.forEach(point => {
      Js.log2("    - Point:", point)
    })
  })
}

// Example for kMeans
let kMeansRunOptions: kMeansOptions = {
  data: sampleData, // Pass data within the options object
  k: 3,
  maxIterations: Some(50),
  tolerance: Some(0.0001),
}

try {
  let resultKMeans = kMeans(kMeansRunOptions) // Call with single options object
  printClusterResult(resultKMeans, "kMeans Result")
} catch {
| Js.Exn.Error(obj) =>
  switch Js.Exn.message(obj) {
  | Some(message) => Js.Console.error2("kMeans Error:", message)
  | None => Js.Console.error("An unknown kMeans error occurred.")
  }
| _ => Js.Console.error("An unexpected error occurred during kMeans.")
}

// Example for runKMeansWithOptimalInertia
let optimalKMeansRunOptions: runKMeansOptions = {
  data: sampleData, // Pass data within the options object
  k: 3,
  numRuns: Some(20),
  maxIterations: Some(50),
  tolerance: Some(0.0001),
}

try {
  let resultOptimal = runKMeansWithOptimalInertia(optimalKMeansRunOptions) // Call with single options object
  printClusterResult(resultOptimal, "runKMeansWithOptimalInertia Result")
} catch {
| Js.Exn.Error(obj) =>
  switch Js.Exn.message(obj) {
  | Some(message) => Js.Console.error2("runKMeansWithOptimalInertia Error:", message)
  | None => Js.Console.error("An unknown runKMeansWithOptimalInertia error occurred.")
  }
| _ => Js.Console.error("An unexpected error occurred during runKMeansWithOptimalInertia.")
}

*/
