import React, { useEffect, useRef, useState } from 'react'
import { createPortal } from 'react-dom'
import {
  AnimatePresence,
  motion,
  useMotionValue,
  useTransform,
} from 'framer-motion'
import type { PanInfo } from 'framer-motion'
import { CheckIcon, UserPlusIcon, XIcon } from 'lucide-react'
import { Trans, t } from '@lingui/macro'
import { useLingui } from '@lingui/react'

export interface InvitePlayer {
  id: string
  name: string
  picture?: string | null
}

interface PlayerInviteSwipeDeckProps {
  players: InvitePlayer[]
  eventTitle: string
  eventVenue: string
  eventTimeLabel: string
  onInvite: (playerId: string) => void
  onClose: () => void
}

interface SwipePlayerCardProps {
  player: InvitePlayer
  eventTitle: string
  eventVenue: string
  eventTimeLabel: string
  exitDirection: 'left' | 'right'
  onSwipe: (direction: 'left' | 'right') => void
}

function initialsOf(name: string): string {
  return name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0].toUpperCase())
    .join('')
}

export function PlayerInviteSwipeDeck({
  players,
  eventTitle,
  eventVenue,
  eventTimeLabel,
  onInvite,
  onClose,
}: PlayerInviteSwipeDeckProps) {
  useLingui()
  // Snapshot the queue at open so store updates from sent invites don't
  // reshuffle the remaining cards mid-review.
  const [reviewQueue] = useState(() => [...players])
  const [currentIndex, setCurrentIndex] = useState(0)
  const [exitDirection, setExitDirection] = useState<'left' | 'right'>('right')
  const overlayRef = useRef<HTMLDivElement>(null)
  const closeButtonRef = useRef<HTMLButtonElement>(null)
  const currentPlayer = reviewQueue[currentIndex]

  useEffect(() => {
    const previouslyFocused = document.activeElement as HTMLElement | null
    closeButtonRef.current?.focus()
    return () => {
      requestAnimationFrame(() => {
        if (previouslyFocused?.isConnected) previouslyFocused.focus()
      })
    }
  }, [])

  const handleSwipe = (direction: 'left' | 'right') => {
    if (!currentPlayer) return
    setExitDirection(direction)
    if (direction === 'right') onInvite(currentPlayer.id)
    setCurrentIndex((index) => index + 1)
  }

  const handleKeyDown = (event: React.KeyboardEvent<HTMLDivElement>) => {
    if (event.key === 'Escape') {
      event.preventDefault()
      event.stopPropagation()
      onClose()
      return
    }
    if (event.key !== 'Tab' || !overlayRef.current) return

    const focusable = Array.from(
      overlayRef.current.querySelectorAll<HTMLElement>(
        'button:not([disabled]), [href], [tabindex]:not([tabindex="-1"])',
      ),
    ).filter((element) => element.offsetParent !== null)
    if (focusable.length === 0) return

    const first = focusable[0]
    const last = focusable[focusable.length - 1]
    if (event.shiftKey && document.activeElement === first) {
      event.preventDefault()
      last.focus()
    } else if (!event.shiftKey && document.activeElement === last) {
      event.preventDefault()
      first.focus()
    }
  }

  return createPortal(
    <motion.div
      ref={overlayRef}
      role="dialog"
      aria-modal="true"
      aria-labelledby="player-invite-deck-title"
      onKeyDown={handleKeyDown}
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.2 }}
      className="fixed inset-0 z-[70] flex flex-col bg-white dark:bg-[#222326]"
    >
      <header className="flex flex-shrink-0 items-center justify-between gap-3 border-b border-gray-200 px-4 py-3 dark:border-[#2a2b30]">
        <button
          ref={closeButtonRef}
          type="button"
          onClick={onClose}
          className="-ml-1 rounded-lg p-2 text-gray-500 transition-colors hover:bg-gray-100 hover:text-gray-900 focus:outline-none focus-visible:ring-2 focus-visible:ring-violet-500 dark:text-gray-400 dark:hover:bg-[#2a2b30] dark:hover:text-gray-100"
          aria-label={t`Close swipe invitations`}
        >
          <XIcon size={19} aria-hidden="true" />
        </button>
        <div className="min-w-0 text-center">
          <h2
            id="player-invite-deck-title"
            className="truncate text-sm font-semibold text-gray-900 dark:text-gray-100"
          >
            <Trans>Invite players</Trans>
          </h2>
          <p className="truncate font-mono text-[10px] text-gray-500 dark:text-gray-400">
            {eventTitle} · {eventTimeLabel}
          </p>
        </div>
        <span
          className="w-12 text-right font-mono text-[10px] text-gray-400 dark:text-gray-500"
          aria-live="polite"
        >
          {currentPlayer
            ? `${currentIndex + 1}/${reviewQueue.length}`
            : `${reviewQueue.length}/${reviewQueue.length}`}
        </span>
      </header>

      <main className="flex flex-1 flex-col items-center justify-center overflow-hidden p-5">
        <div className="flex w-full max-w-[380px] flex-col items-center">
          <div className="relative aspect-[3/4] min-h-[380px] max-h-[520px] w-full">
            <AnimatePresence custom={exitDirection} mode="wait">
              {currentPlayer ? (
                <SwipePlayerCard
                  key={currentPlayer.id}
                  player={currentPlayer}
                  eventTitle={eventTitle}
                  eventVenue={eventVenue}
                  eventTimeLabel={eventTimeLabel}
                  exitDirection={exitDirection}
                  onSwipe={handleSwipe}
                />
              ) : (
                <motion.div
                  key="complete"
                  initial={{ opacity: 0, scale: 0.94 }}
                  animate={{ opacity: 1, scale: 1 }}
                  className="absolute inset-0 flex flex-col items-center justify-center rounded-2xl border border-gray-200 bg-gray-50 p-7 text-center dark:border-[#3a3b40] dark:bg-[#1e1f23]"
                >
                  <span className="mb-4 flex h-16 w-16 items-center justify-center rounded-full border border-violet-100 bg-white text-violet-500 shadow-sm dark:border-violet-900/50 dark:bg-[#2a2b30] dark:text-violet-300">
                    <CheckIcon size={30} aria-hidden="true" />
                  </span>
                  <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100">
                    <Trans>Everyone reviewed</Trans>
                  </h3>
                  <p className="mt-2 max-w-xs text-sm leading-relaxed text-gray-500 dark:text-gray-400">
                    <Trans>
                      Invited players have moved into the event’s invited list.
                    </Trans>
                  </p>
                  <button
                    type="button"
                    onClick={onClose}
                    className="mt-6 rounded-lg border border-gray-200 bg-white px-4 py-2 text-sm font-semibold text-gray-700 transition-colors hover:bg-gray-50 focus:outline-none focus-visible:ring-2 focus-visible:ring-violet-500 dark:border-[#3a3b40] dark:bg-[#2a2b30] dark:text-gray-200 dark:hover:bg-[#353640]"
                  >
                    <Trans>Back to event</Trans>
                  </button>
                </motion.div>
              )}
            </AnimatePresence>
          </div>

          {currentPlayer && (
            <motion.div
              initial={{ opacity: 0, y: 14 }}
              animate={{ opacity: 1, y: 0 }}
              className="mt-7 flex items-center gap-8"
            >
              <button
                type="button"
                onClick={() => handleSwipe('left')}
                className="flex h-14 w-14 items-center justify-center rounded-full border-2 border-gray-200 bg-white text-gray-400 shadow-md transition-transform hover:scale-105 hover:border-red-300 hover:bg-red-50 hover:text-red-500 focus:outline-none focus-visible:ring-2 focus-visible:ring-red-400 active:scale-95 dark:border-[#3a3b40] dark:bg-[#1e1f23] dark:hover:border-red-700 dark:hover:bg-red-950/20"
                aria-label={t`Skip ${currentPlayer.name}`}
              >
                <XIcon size={25} strokeWidth={2.5} aria-hidden="true" />
              </button>
              <button
                type="button"
                onClick={() => handleSwipe('right')}
                className="flex h-14 w-14 items-center justify-center rounded-full border-2 border-[#aee050] bg-[#bdf25d] text-black shadow-md transition-transform hover:scale-105 hover:bg-[#aee050] focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] focus-visible:ring-offset-2 active:scale-95"
                aria-label={t`Invite ${currentPlayer.name}`}
              >
                <UserPlusIcon size={25} strokeWidth={2.5} aria-hidden="true" />
              </button>
            </motion.div>
          )}
          {currentPlayer && (
            <p className="mt-3 font-mono text-[10px] text-gray-400 dark:text-gray-500">
              <Trans>Swipe left to skip · right to invite</Trans>
            </p>
          )}
        </div>
      </main>
    </motion.div>,
    document.body,
  )
}

const cardVariants = {
  initial: { scale: 0.96, opacity: 0 },
  animate: { scale: 1, opacity: 1 },
  exit: (direction: 'left' | 'right') => ({
    x: direction === 'left' ? -500 : 500,
    opacity: 0,
    transition: { duration: 0.2 },
  }),
}

function SwipePlayerCard({
  player,
  eventTitle,
  eventVenue,
  eventTimeLabel,
  exitDirection,
  onSwipe,
}: SwipePlayerCardProps) {
  const x = useMotionValue(0)
  const rotate = useTransform(x, [-200, 200], [-14, 14])
  const inviteOpacity = useTransform(x, [0, 100], [0, 1])
  const skipOpacity = useTransform(x, [0, -100], [0, 1])

  const handleDragEnd = (
    _event: MouseEvent | TouchEvent | PointerEvent,
    info: PanInfo,
  ) => {
    if (info.offset.x > 100) onSwipe('right')
    else if (info.offset.x < -100) onSwipe('left')
  }

  return (
    <motion.article
      custom={exitDirection}
      style={{ x, rotate }}
      drag="x"
      dragConstraints={{ left: 0, right: 0 }}
      dragElastic={0.75}
      onDragEnd={handleDragEnd}
      variants={cardVariants}
      initial="initial"
      animate="animate"
      exit="exit"
      className="absolute inset-0 flex cursor-grab touch-pan-y flex-col overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-xl active:cursor-grabbing dark:border-[#3a3b40] dark:bg-[#1e1f23]"
      aria-label={player.name}
    >
      <motion.div
        style={{ opacity: inviteOpacity }}
        className="pointer-events-none absolute inset-0 z-10 flex items-center justify-center bg-[#bdf25d]/10"
        aria-hidden="true"
      >
        <span className="-rotate-12 rounded-xl border-4 border-[#84b62c] bg-white/90 px-5 py-2 text-3xl font-black tracking-widest text-[#648d1c] shadow-sm dark:bg-[#1e1f23]/90 dark:text-[#bdf25d]">
          <Trans>INVITE</Trans>
        </span>
      </motion.div>
      <motion.div
        style={{ opacity: skipOpacity }}
        className="pointer-events-none absolute inset-0 z-10 flex items-center justify-center bg-gray-500/10"
        aria-hidden="true"
      >
        <span className="rotate-12 rounded-xl border-4 border-gray-500 bg-white/90 px-5 py-2 text-3xl font-black tracking-widest text-gray-500 shadow-sm dark:bg-[#1e1f23]/90">
          <Trans>SKIP</Trans>
        </span>
      </motion.div>

      <div className="flex flex-1 flex-col items-center overflow-y-auto p-7">
        <div className="flex h-20 w-20 items-center justify-center overflow-hidden rounded-full border border-gray-200 bg-gray-100 text-lg font-bold text-gray-700 dark:border-[#3a3b40] dark:bg-[#2a2b30] dark:text-gray-200">
          {player.picture ? (
            <img
              src={player.picture}
              alt=""
              className="h-full w-full object-cover"
              draggable={false}
            />
          ) : (
            initialsOf(player.name) || '?'
          )}
        </div>
        <h3 className="mt-5 text-2xl font-semibold text-gray-900 dark:text-gray-100">
          {player.name}
        </h3>
        <div className="mt-6 w-full rounded-xl border border-violet-100 bg-violet-50/70 p-4 dark:border-violet-900/50 dark:bg-violet-950/20">
          <p className="text-xs font-semibold text-violet-900 dark:text-violet-200">
            <Trans>Available for the full event</Trans>
          </p>
          <p className="mt-1 font-mono text-[10px] leading-relaxed text-violet-700 dark:text-violet-400">
            {eventTimeLabel} · {eventVenue}
          </p>
        </div>
        <p className="mt-5 w-full text-sm leading-relaxed text-gray-600 dark:text-gray-300">
          <Trans>
            A good availability match for {eventTitle}. Invite them now to
            reserve a place in the event conversation.
          </Trans>
        </p>
      </div>
      <footer className="flex-shrink-0 border-t border-gray-100 bg-gray-50 p-4 text-center text-xs font-medium text-gray-500 dark:border-[#3a3b40] dark:bg-[#2a2b30] dark:text-gray-400">
        <Trans>Invite to {eventTitle}</Trans>
      </footer>
    </motion.article>
  )
}
