// // ActivityFeed component in ReScript React
// // Props: activities array with id, type, message, timestamp, user

// type activity = {
//   id: string,
//   type_: string,
//   message: string,
//   timestamp: string,
//   user: string,
// }

// @react.component
// let make = (~activities: array<activity>) => {
//   <div className="bg-white rounded-lg shadow-sm p-4 md:p-5 mt-4">
//     <h2 className="text-lg font-semibold mb-4"> {React.string("Activity")} </h2>
//     <div className="space-y-4">
//       {activities
//       ->Array.map(activity => {
//         // choose icon and wrapper based on type
//         let (iconElem, iconWrapperClass) = switch activity.type_ {
//         | "update" => (<Lucide.Bell className="size-4 text-blue-600" />, "bg-blue-100")
//         | _ => (<Lucide.User className="size-4 text-green-600" />, "bg-green-100")
//         }

//         let dt = activity.timestamp->Js.Date.fromString

//         <div key=activity.id className="flex">
//           <div className="mr-3 mt-1">
//             <div className={Util.cx([iconWrapperClass, "p-2 rounded-full"])}> {iconElem} </div>
//           </div>
//           <div className="flex-1">
//             <p className="text-gray-700"> {React.string(activity.message)} </p>
//             <p className="text-xs text-gray-500 mt-1">
//               {activity.user == "Organizer"
//                 ? <span className="font-medium text-blue-600"> {React.string("Organizer")} </span>
//                 : React.string(activity.user)}
//               {React.string(" • ")}
//               {<>
//                 <ReactIntl.FormattedDate value={dt} month=#short day=#numeric />
//                 {React.string(" ")}
//                 <ReactIntl.FormattedTime value={dt} />
//               </>}
//             </p>
//           </div>
//         </div>
//       })
//       ->React.array}
//     </div>
//   </div>
// }

