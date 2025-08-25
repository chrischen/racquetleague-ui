import * as React from 'react'
import {motion, PanInfo, useAnimation} from 'framer-motion'

export interface SwipeActionProps {
  children: React.ReactNode
  /** Actions revealed when swiping right (dragging content to the right). Typically archive, flag, etc. Appears on the left side. */
  leftActions?: React.ReactNode
  /** Actions revealed when swiping left (dragging content to the left). Typically delete. Appears on the right side. */
  rightActions?: React.ReactNode
  /** Callback when a full swipe to the left (negative direction) is completed */
  onFullSwipeLeft?: () => void
  /** Callback when a full swipe to the right (positive direction) is completed */
  onFullSwipeRight?: () => void
  /** Distance in pixels needed to settle into a partial open state (default 56) */
  partialThreshold?: number
  /** Distance in pixels needed to trigger a full swipe action (default 160) */
  fullThreshold?: number
  /** Optional className for outer container */
  className?: string
  /** Optional className for the draggable content wrapper */
  contentClassName?: string
  /** Optional className applied to the underlying actions layer */
  actionsClassName?: string
  /** Disable the full swipe behavior */
  disableFullSwipe?: boolean
  /** Called when the partial state changes (left | right | null) */
  onPartialStateChange?: (state: 'left' | 'right' | null) => void
  /** Fired when the user performs a simple tap (mouse click / touch) without swiping */
  onTapped?: () => void
  /** If set, hovering the item will automatically open a partial swipe for the given side ("left" shows leftActions, "right" shows rightActions). */
  hoverPartialSide?: 'left' | 'right'
}

/**
 * SwipeAction (framer-motion)
 * - Drag horizontally to reveal actions
 * - Partial swipe (beyond partialThreshold) snaps open to show actions
 * - Full swipe (beyond fullThreshold) fires appropriate callback and animates item out
 * - Supports swiping either direction independently
 */
export const SwipeAction: React.FC<SwipeActionProps> = ({
  children,
  leftActions,
  rightActions,
  onFullSwipeLeft,
  onFullSwipeRight,
  partialThreshold = 56,
  fullThreshold = 160,
  className = '',
  contentClassName = '',
  actionsClassName = '',
  disableFullSwipe = false,
  onPartialStateChange,
  onTapped,
  hoverPartialSide,
}) => {
  const controls = useAnimation()
  const xRef = React.useRef(0)
  const containerRef = React.useRef<HTMLDivElement>(null)
  const leftRef = React.useRef<HTMLDivElement>(null)
  const rightRef = React.useRef<HTMLDivElement>(null)
  const [partialSide, setPartialSide] = React.useState<'left' | 'right' | null>(null)
  const fullTriggeredRef = React.useRef(false)
  const [shadowActive, setShadowActive] = React.useState(false)
  // Dynamic lateral-only box shadow (pure horizontal, no vertical spread)
  const [dynamicShadow, setDynamicShadow] = React.useState<string>('none')
  const isDraggingRef = React.useRef(false)
  // Tap detection refs
  const tapStartRef = React.useRef<{x: number; y: number} | null>(null)
  const tapMovedRef = React.useRef(false)
  const tapSlop = 8 // px threshold before we consider it a swipe/drag instead of tap
  const hoverAutoRef = React.useRef(false)
  const isCoarsePointer = React.useMemo(() => {
    if (typeof window === 'undefined' || typeof matchMedia === 'undefined') return false
    // coarse pointer usually indicates touch (mobile / tablet)
    try {
      return matchMedia('(pointer: coarse)').matches
    } catch { return false }
  }, [])

  const leftWidth = leftRef.current?.offsetWidth ?? 0
  const rightWidth = rightRef.current?.offsetWidth ?? 0

  const updatePartial = React.useCallback((side: 'left' | 'right' | null) => {
    setPartialSide(prev => {
      if (prev !== side) onPartialStateChange?.(side)
      return side
    })
  }, [onPartialStateChange])

  const animateTo = React.useCallback(async (target: number) => {
    await controls.start({x: target, transition: {type: 'spring', stiffness: 350, damping: 32}})
    xRef.current = target
    // Only mark active if not closed; clearing deferred to animation complete.
    if (Math.abs(target) >= 0.5) setShadowActive(true)
  }, [controls])

  const handleDragEnd = async (_: MouseEvent | TouchEvent | PointerEvent, info: PanInfo) => {
    if (fullTriggeredRef.current) return
    const {offset} = info
    const deltaX = offset.x
  isDraggingRef.current = false

    // Full swipe logic
    if (!disableFullSwipe) {
      if (deltaX <= -fullThreshold && onFullSwipeLeft) {
        fullTriggeredRef.current = true
        // Fire callback first (allows side-effects like showing toast)
        onFullSwipeLeft()
        // Bounce animation: push a bit further then snap back
        await controls.start({x: -fullThreshold, transition: {type: 'spring', stiffness: 400, damping: 30}})
        await controls.start({x: 0, transition: {type: 'spring', stiffness: 350, damping: 32}})
        xRef.current = 0
        updatePartial(null)
        fullTriggeredRef.current = false
        return
      }
      if (deltaX >= fullThreshold && onFullSwipeRight) {
        fullTriggeredRef.current = true
        onFullSwipeRight()
        await controls.start({x: fullThreshold, transition: {type: 'spring', stiffness: 400, damping: 30}})
        await controls.start({x: 0, transition: {type: 'spring', stiffness: 350, damping: 32}})
        xRef.current = 0
        updatePartial(null)
        fullTriggeredRef.current = false
        return
      }
    }

    // Partial swipe (open actions) logic
    if (deltaX <= -partialThreshold && rightActions) {
      updatePartial('right')
      // Ensure shadow persists after settling into partial open
      if (!shadowActive) setShadowActive(true)
      await animateTo(-Math.min(Math.max(partialThreshold, Math.min(rightWidth, Math.abs(deltaX))), rightWidth || partialThreshold))
      return
    }
    if (deltaX >= partialThreshold && leftActions) {
      updatePartial('left')
      if (!shadowActive) setShadowActive(true)
      await animateTo(Math.min(Math.max(partialThreshold, Math.min(leftWidth, deltaX)), leftWidth || partialThreshold))
      return
    }

    // Snap closed
    updatePartial(null)
  await animateTo(0)
  }

  const close = React.useCallback(() => {
    if (partialSide) {
      updatePartial(null)
      animateTo(0)
    }
  }, [partialSide, updatePartial, animateTo])

  // Close on outside click (basic)
  React.useEffect(() => {
    if (!partialSide) return
    const handler = (e: MouseEvent) => {
      if (!containerRef.current) return
      if (!containerRef.current.contains(e.target as Node)) close()
    }
    window.addEventListener('mousedown', handler)
    return () => window.removeEventListener('mousedown', handler)
  }, [partialSide, close])

  // Keep shadow in sync with partial open state even after animations settle
  React.useEffect(() => {
    if (partialSide) {
      if (!shadowActive) setShadowActive(true)
    } else if (xRef.current === 0) {
      setShadowActive(false)
    }
  }, [partialSide, shadowActive])

  return (
    <div
      ref={containerRef}
      className={`relative select-none ${className}`}
      onMouseEnter={() => {
        if (!hoverPartialSide) return
        if (isCoarsePointer) return // disable on mobile/touch
        if (isDraggingRef.current) return
        if (partialSide) return // don't override an existing manual partial state
        // Determine if the requested side has actions
        if (hoverPartialSide === 'left' && !leftActions) return
        if (hoverPartialSide === 'right' && !rightActions) return
        const side = hoverPartialSide
        const width = side === 'left' ? (leftRef.current?.offsetWidth || partialThreshold) : (rightRef.current?.offsetWidth || partialThreshold)
        const target = side === 'left' ? Math.min(Math.max(partialThreshold, width), width) : -Math.min(Math.max(partialThreshold, width), width)
        hoverAutoRef.current = true
        updatePartial(side)
        animateTo(target)
      }}
      onMouseLeave={() => {
        if (!hoverPartialSide) return
        if (isCoarsePointer) return
        if (!hoverAutoRef.current) return
        if (isDraggingRef.current) return
        // Only auto-close if the partial open was caused by hover and user hasn't interacted
        if (partialSide === hoverPartialSide) {
          hoverAutoRef.current = false
          updatePartial(null)
          animateTo(0)
        }
      }}
    >
      {/* Action layers */}
      {leftActions && (
        <div ref={leftRef} className={`absolute inset-y-0 left-0 flex items-center pl-2 pr-1 gap-1 z-10 pointer-events-auto ${actionsClassName}`}>
          {leftActions}
        </div>
      )}
      {rightActions && (
        <div ref={rightRef} className={`absolute inset-y-0 right-0 flex items-center pr-2 pl-1 gap-1 z-10 pointer-events-auto ${actionsClassName}`}>
          {rightActions}
        </div>
      )}
  {/* (No separate gradient element when using box-shadow) */}
      {/* Draggable content */}
      {/**
        We manage boxShadow inline instead of relying on Tailwind shadow classes because
        framer-motion's whileDrag boxShadow would otherwise override and clear the class-based
        shadow after the drag stops. This ensures persistence when partially open.
       */}
      {(() => { /* self-executing to allow local constants */
        // Edge-only shadow (no bottom drop) when partially open or dragging.
        // We maintain lateral shadows on the active edge only.
  // No static shadow when resting; only show dynamic lateral shadow while actively dragging.
  const boxShadow = (() => {
  if (isDraggingRef.current) return dynamicShadow
  const dist = Math.abs(xRef.current)
  const shouldShow = dist >= 0.5 || !!partialSide
  if (!shouldShow) return 'none'
  const maxVisualDist = Math.max(1, partialThreshold)
  const raw = Math.min(dist / maxVisualDist, 1)
  let intensity = Math.sqrt(raw)
  if (partialSide && intensity < 0.18) intensity = 0.18
  // Build elevated multi-layer shadow (all sides) scaling with intensity
  const y1 = 2 + 4 * intensity
  const blur1 = 4 + 10 * intensity
  const spread1 = -2
  const a1 = (0.22 * intensity).toFixed(3)
  const y2 = 6 + 10 * intensity
  const blur2 = 12 + 18 * intensity
  const spread2 = -4
  const a2 = (0.16 * intensity).toFixed(3)
  const y3 = 12 + 14 * intensity
  const blur3 = 24 + 26 * intensity
  const spread3 = -6
  const a3 = (0.12 * intensity).toFixed(3)
  return `0 ${y1.toFixed(1)}px ${blur1.toFixed(1)}px ${spread1}px rgba(0,0,0,${a1}), 0 ${y2.toFixed(1)}px ${blur2.toFixed(1)}px ${spread2}px rgba(0,0,0,${a2}), 0 ${y3.toFixed(1)}px ${blur3.toFixed(1)}px ${spread3}px rgba(0,0,0,${a3})`
  })()
        return (
      <div className="relative overflow-hidden">
      <motion.div
        drag="x"
        dragElastic={0.05}
        dragConstraints={{left: rightActions ? -((rightWidth || fullThreshold) * 1.25) : 0, right: leftActions ? (leftWidth || fullThreshold) * 1.25 : 0}}
        onDragEnd={handleDragEnd}
        onDragStart={() => {
          isDraggingRef.current = true
          if (!shadowActive) setShadowActive(true)
          setDynamicShadow('none')
        }}
        onPointerDown={(e) => {
          tapStartRef.current = {x: e.clientX, y: e.clientY}
          tapMovedRef.current = false
        }}
        onPointerMove={(e) => {
          if (!tapStartRef.current || tapMovedRef.current) return
          const dx = Math.abs(e.clientX - tapStartRef.current.x)
          const dy = Math.abs(e.clientY - tapStartRef.current.y)
          if (dx > tapSlop || dy > tapSlop) {
            tapMovedRef.current = true
          }
        }}
        onPointerUp={() => {
          if (onTapped && tapStartRef.current) {
            // Treat as tap if we didn't move beyond slop & not during an active full swipe
            if (!tapMovedRef.current && !fullTriggeredRef.current) {
              onTapped()
            }
          }
          tapStartRef.current = null
          tapMovedRef.current = false
        }}
        onDirectionLock={(axis) => axis !== 'x' && close()}
        animate={controls}
    onUpdate={(latest) => {
          // latest.x can be string or number; framer provides number
          const x = (latest as any).x as number | undefined
          if (typeof x === 'number') {
            // shadowActive toggling not needed for visibility (derived from position), but keep for backwards compatibility
            if (Math.abs(x) > 0.5 && !shadowActive) setShadowActive(true)
            if (isDraggingRef.current) {
              const dist = Math.abs(x)
              const maxVisualDist = Math.max(1, partialThreshold)
              const raw = Math.min(dist / maxVisualDist, 1)
              let intensity = Math.sqrt(raw)
              if (intensity < 0.02 && !partialSide) {
                if (dynamicShadow !== 'none') setDynamicShadow('none')
              } else {
                if (partialSide && intensity < 0.18) intensity = 0.18
                const y1 = 2 + 4 * intensity
                const blur1 = 4 + 10 * intensity
                const spread1 = -2
                const a1 = (0.22 * intensity).toFixed(3)
                const y2 = 6 + 10 * intensity
                const blur2 = 12 + 18 * intensity
                const spread2 = -4
                const a2 = (0.16 * intensity).toFixed(3)
                const y3 = 12 + 14 * intensity
                const blur3 = 24 + 26 * intensity
                const spread3 = -6
                const a3 = (0.12 * intensity).toFixed(3)
                const newShadow = `0 ${y1.toFixed(1)}px ${blur1.toFixed(1)}px ${spread1}px rgba(0,0,0,${a1}), 0 ${y2.toFixed(1)}px ${blur2.toFixed(1)}px ${spread2}px rgba(0,0,0,${a2}), 0 ${y3.toFixed(1)}px ${blur3.toFixed(1)}px ${spread3}px rgba(0,0,0,${a3})`
                setDynamicShadow(prev => prev === newShadow ? prev : newShadow)
              }
            }
          }
        }}
  className={`relative bg-white dark:bg-zinc-900 z-20 ${contentClassName}`}
  style={{touchAction: 'pan-y', boxShadow, transition: `box-shadow ${isDraggingRef.current ? '0s' : '0.16s'} ease`, position: 'relative'}}
        onAnimationComplete={() => {
          if (!partialSide && Math.abs(xRef.current) < 0.5) {
            setShadowActive(false)
            setDynamicShadow('none')
          } else if (Math.abs(xRef.current) >= 0.5 || partialSide) {
            setShadowActive(true)
          }
        }}
  onDragTransitionEnd={() => { isDraggingRef.current = false }}
      >
        {children}
      </motion.div>
      </div>
        )
      })()}
      {/* Overlay when open */}
      {partialSide && (
        <button
          aria-label="Close swipe actions"
          className="absolute inset-0 z-0 cursor-default"
          onClick={close}
        />
      )}
    </div>
  )
}

export default SwipeAction
