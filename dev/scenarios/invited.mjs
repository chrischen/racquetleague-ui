import { cast, directMessage, me, thursday, worldMocks } from "./_invites-world.mjs";

// The invitee's side of an invite. Aki has invited you (Mika) to Thursday
// Night Doubles with a note. Open:
// - the bell / /notifications: the unread note; clicking it opens the
//   conversation at /messages/User_aki, where you can reply;
// - /events/Event_thursday-doubles: you're listed under Invites, and the
//   footer's "Claim spot" accepts the invite (there is no decline control
//   yet). Leave event afterwards removes you.
export default {
  description:
    "You've been invited: Aki's note is unread in your inbox and opens your conversation with him (/messages/User_aki), and on Thursday Night Doubles you're under Invites with Claim spot to accept (/events/Event_thursday-doubles).",
  mocks: worldMocks({
    thursdayInvite: 2,
    inbox: [
      directMessage({
        id: "DM_aki_invite",
        copy: "received",
        from: cast.aki,
        to: me,
        about: thursday,
        invite: true,
        read: false,
        minutes: 25,
        body: "Hi Mika! We're one short for Thursday doubles at Shibaura, and your level would fit right in. Hope you can make it!",
      }),
    ],
  }),
};
