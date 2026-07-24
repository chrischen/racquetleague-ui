%%raw("import { t } from '@lingui/macro'")

// Top Player awards sponsor logo. Single source for the sponsor/prize info
// shared by the rankings banner and the event-page strip.
@module("./dallasflash.png") external sponsorLogo: string = "default"

// Next Top Player awards date. Rendered in UTC so this calendar date never
// shifts across time zones.
let awardDate = Js.Date.fromString("2026-07-31T00:00:00Z")
let awardDateChip =
  <ReactIntl.FormattedDate value={awardDate} year=#numeric month=#long day=#numeric timeZone="UTC" />

// Full banner — prizes distributed to the top 4 men and top 4 women players,
// presented by the current sponsor. Used on the rankings page.
module Banner = {
  open Lingui.Util
  let ts = Lingui.UtilString.t
  @react.component
  let make = () => {
    <div
      className="relative overflow-hidden rounded-xl border border-amber-300/70 dark:border-amber-500/30 bg-amber-50 dark:bg-amber-950/30 shadow-sm mb-5">
      <div
        className="absolute -top-16 -right-10 w-56 h-56 bg-amber-400/10 blur-3xl rounded-full pointer-events-none"
      />
      <div className="relative p-4 md:p-5 flex flex-col md:flex-row md:items-center gap-4 md:gap-5">
        // Award icon + cadence (desktop)
        <div
          className="flex-shrink-0 hidden sm:flex flex-col items-center justify-center gap-2 w-24 md:w-28 self-stretch">
          <Lucide.Award
            size={52} strokeWidth={1.25} className="text-amber-500 dark:text-amber-400"
          />
          <span
            className="inline-flex items-center gap-1 rounded-md bg-amber-400/15 border border-amber-400/40 px-2 py-1 text-[11px] font-bold text-amber-700 dark:text-amber-300 whitespace-nowrap">
            <Lucide.CalendarClock size={12} strokeWidth={2.5} />
            awardDateChip
          </span>
        </div>
        // Heading + award info
        <div className="min-w-0 flex-1">
          <div className="flex items-center flex-wrap gap-x-2 gap-y-1.5">
            <h2
              className="font-black uppercase italic tracking-tight text-base md:text-lg text-gray-900 dark:text-white leading-none flex items-center gap-1.5">
              <Lucide.Trophy
                size={18} className="text-amber-600 dark:text-amber-400" strokeWidth={2.5}
              />
              {t`Top Player Awards`}
              <Lucide.Sparkles
                size={14} className="text-amber-500 dark:text-amber-400" fill="currentColor"
              />
            </h2>
            // Cadence chip (mobile)
            <span
              className="sm:hidden inline-flex items-center gap-1 rounded-md bg-amber-400/15 border border-amber-400/40 px-2 py-0.5 text-[11px] font-bold text-amber-700 dark:text-amber-300 whitespace-nowrap">
              <Lucide.CalendarClock size={12} strokeWidth={2.5} />
              awardDateChip
            </span>
          </div>
          <p className="text-xs md:text-sm text-gray-600 dark:text-gray-300 mt-2 leading-snug">
            {t`The top 4 men and top 4 women players each earn a prize.`}
          </p>
        </div>
        // Prize + sponsor card
        <div
          className="flex-shrink-0 w-full md:w-52 rounded-lg border border-amber-400/50 bg-white dark:bg-[#1e1f23] overflow-hidden">
          <div
            className="flex items-center justify-between gap-2 px-3 py-2 border-b border-gray-100 dark:border-[#2a2b30] bg-gray-50 dark:bg-[#17181c]">
            <span
              className="font-mono text-[9px] font-bold uppercase tracking-wider text-gray-400 dark:text-gray-500">
              {t`Presented by`}
            </span>
            <img
              className="h-6 w-auto max-w-[110px] object-contain flex-shrink-0 rounded bg-white px-1 shadow-sm"
              src={sponsorLogo}
              alt={ts`Sponsor logo`}
            />
          </div>
          <div className="flex items-center gap-2.5 px-3 py-2.5">
            <div
              className="flex-shrink-0 w-8 h-8 rounded-lg bg-amber-400/20 border border-amber-400/50 flex items-center justify-center">
              <Lucide.Gift
                size={16} className="text-amber-600 dark:text-amber-400" strokeWidth={2.25}
              />
            </div>
            <div className="min-w-0">
              <div
                className="font-black font-mono text-lg md:text-xl leading-none text-amber-700 dark:text-amber-300">
                {t`Prizes`}
              </div>
              <div
                className="text-[11px] font-medium text-gray-500 dark:text-gray-400 mt-1 leading-tight">
                {t`Official Dallash Flash T-Shirts and Ball Caps`}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  }
}

