import { cast, directMessage, eventNotice, me, saturday, worldMocks } from "./_invites-world.mjs";

// The host's side of invites. You (Mika) host Saturday Morning Drills: three
// going, Ken and Yui invited with notes, three seats open. Open
// /events/Event_saturday-drills to see the invited chips and the invite
// tools: available players for the day, ranked recommendations, the swipe
// deck and the note composer. Inviting someone adds them as invited.
// Yui has replied to her note (unread); Ken hasn't, so his conversation on
// /notifications waits for him to write back.
export default {
  description:
    "You host Saturday Morning Drills with open seats: invited chips, available and recommended players, the swipe deck and note composer (/events/Event_saturday-drills).",
  mocks: worldMocks({
    thursdayInvite: null,
    inbox: [
      directMessage({
        id: "DM_yui_reply",
        copy: "received",
        from: cast.yui,
        to: me,
        about: saturday,
        replyTo: "DM_invite_yui",
        read: false,
        minutes: 40,
        body: "Thanks Mika! I'm in if I can get to Toyosu by 9. Is there parking near the courts?",
      }),
      eventNotice({ id: "Notice_rina_joined", about: saturday, activityType: "rsvp_created", actor: cast.rina, minutes: 5 * 60 }),
      directMessage({
        id: "DM_invite_ken",
        copy: "sent",
        from: me,
        to: cast.ken,
        about: saturday,
        invite: true,
        minutes: 2 * 60,
        body: "Hi Ken, we run drills on Saturday mornings at Toyosu and have a spot open. Your level looks like a good fit. Join us?",
      }),
      directMessage({
        id: "DM_invite_yui",
        copy: "sent",
        from: me,
        to: cast.yui,
        about: saturday,
        invite: true,
        minutes: 3 * 60,
        body: "Yui! Saturday drills at Toyosu, 9 to 11. We need one more lefty to keep things interesting. Want in?",
      }),
    ],
  }),
};
