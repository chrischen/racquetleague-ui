import { cast, directMessage, eventNotice, expired, me, saturday, thursday, worldMocks } from "./_invites-world.mjs";

// Private messages in every state. Their rows are on /notifications and in
// the bell; each opens its conversation at /messages/<person>. You are
// Mika. A private message can only answer one you received, so every
// conversation starts with an invite note.
// - Aki (/messages/User_aki): invited you, you replied, Aki answered
//   (unread). Reply works.
// - Yui (/messages/User_yui): answered your invite with a long,
//   multi-line message (unread).
// - Ken (/messages/User_ken): you invited him and he hasn't written back:
//   no reply box yet. Only your sent note exists, which is not a
//   notification, so open his conversation by URL.
// - Daniel (/messages/User_daniel): his message is too old to answer;
//   sending a reply shows the
//   "no longer available" error.
// - Rina joined your Saturday game: an event notification among them.
export default {
  description:
    "Private conversations in every state: unread replies, a long message, one awaiting their reply, and one too old to answer. Their rows are on /notifications; each opens /messages/<person>.",
  mocks: worldMocks({
    thursdayInvite: 2,
    inbox: [
      directMessage({
        id: "DM_aki_followup",
        copy: "received",
        from: cast.aki,
        to: me,
        about: thursday,
        replyTo: "DM_mika_reply_aki",
        read: false,
        minutes: 2,
        body: "Great! I'll put you on court 2 with Lena to start. Bring indoor shoes.",
      }),
      directMessage({
        id: "DM_mika_reply_aki",
        copy: "sent",
        from: me,
        to: cast.aki,
        about: thursday,
        replyTo: "DM_aki_invite",
        minutes: 10,
        body: "Thanks Aki, I'd love to! Is it 7 sharp, or can I arrive at 7:15?",
      }),
      directMessage({
        id: "DM_aki_invite",
        copy: "received",
        from: cast.aki,
        to: me,
        about: thursday,
        invite: true,
        minutes: 25,
        body: "Hi Mika! We're one short for Thursday doubles at Shibaura, and your level would fit right in. Hope you can make it!",
      }),
      directMessage({
        id: "DM_yui_reply",
        copy: "received",
        from: cast.yui,
        to: me,
        about: saturday,
        replyTo: "DM_invite_yui",
        read: false,
        minutes: 40,
        body:
          "Thanks for the invite, Mika!\n\nI'm in if I can get to Toyosu by 9. Is there parking near the courts, or is the Yurikamome easier from Shimbashi?\n\nAlso happy to bring a spare paddle if anyone needs one.",
      }),
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
      eventNotice({ id: "Notice_rina_joined", about: saturday, activityType: "rsvp_created", actor: cast.rina, minutes: 5 * 60 }),
      expired(
        directMessage({
          id: "DM_daniel_late",
          copy: "received",
          from: cast.daniel,
          to: me,
          replyTo: "DM_invite_daniel",
          minutes: (29 * 24 + 22) * 60,
          body: "Sorry I missed Sunday, my flight got moved. Any games before the 20th?",
        }),
      ),
      directMessage({
        id: "DM_invite_daniel",
        copy: "sent",
        from: me,
        to: cast.daniel,
        invite: true,
        minutes: (29 * 24 + 23) * 60,
        body: "Hi Daniel, we have a Sunday game at Odaiba while you're in town. Would you like to come?",
      }),
    ],
  }),
};
