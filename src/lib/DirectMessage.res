// Private messages as the inbox carries them.
//
// One sender, one recipient. The server stores each message twice under one
// id: the recipient's copy (topic "User_<id>.inbox.direct") and the sender's
// own copy ("User_<id>.sent.direct"). The server clears both out after 30
// days, so the inbox only holds recent ones. There is no group form: an
// event's messages already are one.
//
// A conversation is everything between the viewer and one other person. A
// reply answers the latest message they sent the viewer: today the server
// only accepts answers to a message the viewer received, back to its sender.
//
// Mirrors the backend's src/rl/message/topics/DirectMessage.re.

type copy = Received | Sent

type t = {
  id: string,
  copy: copy,
  createdAt: string,
  fromUserId: string,
  fromUserName: string,
  toUserId: string,
  toUserName: string,
  body: string,
  replyTo: option<string>,
  eventId: option<string>,
  eventName: option<string>,
  // What prompted it: "rsvp_invited" for an invite's note.
  context: option<string>,
}

let copyOfTopic = (topic: string): option<copy> =>
  switch topic->String.split(".") {
  | [_, "inbox", "direct"] => Some(Received)
  | [_, "sent", "direct"] => Some(Sent)
  | _ => None
  }


let isInvite = (t: t) => t.context == Some("rsvp_invited")

let decode = (~id: string, ~topic: string, ~payload: option<string>, ~createdAt: string): option<
  t,
> =>
  switch (copyOfTopic(topic), payload) {
  | (Some(copy), Some(payloadStr)) =>
    try {
      switch payloadStr->JSON.parseExn->JSON.Decode.object {
      | Some(d) =>
        let str = key => d->Dict.get(key)->Option.flatMap(JSON.Decode.string)
        switch (
          str("fromUserId"),
          str("fromUserName"),
          str("toUserId"),
          str("toUserName"),
          str("body"),
        ) {
        | (Some(fromUserId), Some(fromUserName), Some(toUserId), Some(toUserName), Some(body)) =>
          Some({
            id,
            copy,
            createdAt,
            fromUserId,
            fromUserName,
            toUserId,
            toUserName,
            body,
            replyTo: str("replyTo"),
            eventId: str("eventId"),
            eventName: str("eventName"),
            context: str("context"),
          })
        | _ => None
        }
      | None => None
      }
    } catch {
    | _ => None
    }
  | _ => None
  }

// The page holding the viewer's conversation with a person ("User_<uuid>").
let threadPath = (withUserId: string) => "/messages/" ++ withUserId

// The person on the other side, from the inbox owner's point of view.
let counterpart = (t: t): (string, string) =>
  switch t.copy {
  | Received => (t.fromUserId, t.fromUserName)
  | Sent => (t.toUserId, t.toUserName)
  }

type conversation = {
  withUserId: string,
  withUserName: string,
  // Oldest first, the order they are read in.
  messages: array<t>,
  // The latest message they sent the viewer: what a reply answers. None when
  // they have not written to the viewer, since the server only accepts
  // answers to a message the viewer received.
  replyTarget: option<t>,
  // The event the conversation is about, from its latest message that names one.
  event: option<(string, string)>,
  latestAt: string,
}

// One copy per id: a message the viewer just sent may also arrive from the
// server on the next load.
let dedupe = (messages: array<t>): array<t> => {
  let seen = Belt.MutableSet.String.make()
  messages->Array.filter(m =>
    if seen->Belt.MutableSet.String.has(m.id) {
      false
    } else {
      seen->Belt.MutableSet.String.add(m.id)
      true
    }
  )
}

// Groups messages by the other person, the most recently active first.
let conversations = (messages: array<t>): array<conversation> => {
  let byPerson: Dict.t<array<t>> = Dict.make()
  let order: array<string> = []
  messages
  ->dedupe
  ->Array.forEach(m => {
    let (withId, _) = counterpart(m)
    switch byPerson->Dict.get(withId) {
    | Some(existing) => existing->Array.push(m)
    | None =>
      byPerson->Dict.set(withId, [m])
      order->Array.push(withId)
    }
  })
  order
  ->Array.filterMap(withId =>
    byPerson
    ->Dict.get(withId)
    ->Option.map(msgs => {
      let sorted = msgs->Array.toSorted((a, b) => String.compare(a.createdAt, b.createdAt))
      let newestFirst = sorted->Array.toReversed
      let latest = newestFirst->Array.get(0)
      {
        withUserId: withId,
        // The name on the newest message, in case it changed.
        withUserName: latest->Option.map(m => snd(counterpart(m)))->Option.getOr(""),
        messages: sorted,
        replyTarget: newestFirst->Array.find(m => m.copy == Received),
        event: newestFirst->Array.findMap(m =>
          switch (m.eventId, m.eventName) {
          | (Some(id), Some(name)) => Some((id, name))
          | _ => None
          }
        ),
        latestAt: latest->Option.map(m => m.createdAt)->Option.getOr(""),
      }
    })
  )
  ->Array.toSorted((a, b) => String.compare(b.latestAt, a.latestAt))
}
