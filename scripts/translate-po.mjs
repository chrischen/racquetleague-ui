/**
 * Translation pipeline using pofile + Anthropic Claude
 *
 * Usage:
 *   node scripts/translate-po.mjs [locale...]
 *
 * Examples:
 *   node scripts/translate-po.mjs                  # translate all locales
 *   node scripts/translate-po.mjs ja ko            # translate specific locales
 *
 * Requires ANTHROPIC_API_KEY env var.
 */

import { readFileSync, writeFileSync } from 'fs'
import { createRequire } from 'module'
import path from 'path'
import { fileURLToPath } from 'url'

const require = createRequire(import.meta.url)
const PO = require('pofile')
const Anthropic = require('@anthropic-ai/sdk')

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const LOCALES_DIR = path.join(__dirname, '../src/locales')

const LANGUAGE_NAMES = {
  ja: 'Japanese',
  ko: 'Korean',
  'zh-CN': 'Simplified Chinese',
  'zh-TW': 'Traditional Chinese',
  vi: 'Vietnamese',
}

const ALL_LOCALES = Object.keys(LANGUAGE_NAMES)

const client = new Anthropic.default({ apiKey: process.env.ANTHROPIC_API_KEY })

/**
 * Load a .po file and return untranslated items (msgstr is empty, not obsolete)
 */
function getUntranslated(poFilePath) {
  const po = PO.load(poFilePath)
  return po.items.filter(item => {
    if (item.obsolete) return false
    if (!item.msgid) return false
    // msgstr is an array; empty translation means first element is empty string
    return !item.msgstr[0]
  })
}

/**
 * Send a batch of msgids to Claude and get back translations.
 * Returns an object mapping msgid -> translated string.
 */
async function translateBatch(msgids, targetLanguage) {
  const numbered = msgids.map((id, i) => `${i + 1}. ${JSON.stringify(id)}`).join('\n')

  const prompt = `You are a professional UI translator. Translate the following web application UI strings into ${targetLanguage}.

Rules:
- Preserve all placeholders exactly as-is (e.g. {0}, {name}, {viewerOrdinalStr}, \\n, \\\\n)
- Preserve all ICU plural syntax (e.g. {count, plural, one {...} other {...}})
- Keep translations concise and natural for a sports/pickleball app UI
- Return ONLY a JSON object mapping the 1-based index number (as string) to the translated string
- Do not add any explanation or extra text

Strings to translate:
${numbered}

Return format example: {"1": "translation one", "2": "translation two"}`

  const message = await client.messages.create({
    model: 'claude-sonnet-4-5',
    max_tokens: 4096,
    messages: [{ role: 'user', content: prompt }],
  })

  const raw = message.content[0].text.trim()
  // Extract JSON from the response (handle potential markdown code fences)
  const jsonMatch = raw.match(/\{[\s\S]*\}/)
  if (!jsonMatch) throw new Error(`Claude returned unexpected format:\n${raw}`)

  const indexed = JSON.parse(jsonMatch[0])
  const result = {}
  msgids.forEach((id, i) => {
    const translation = indexed[String(i + 1)]
    if (translation) result[id] = translation
  })
  return result
}

/**
 * Translate all untranslated strings in a .po file and save it.
 */
async function translateFile(locale) {
  const filePath = path.join(LOCALES_DIR, `${locale}.po`)
  const languageName = LANGUAGE_NAMES[locale]

  console.log(`\n[${locale}] Loading ${filePath}...`)
  const content = readFileSync(filePath, 'utf8')
  const po = PO.parse(content)
  const untranslated = po.items.filter(item => {
    if (item.obsolete) return false
    if (!item.msgid) return false
    return !item.msgstr[0]
  })

  if (untranslated.length === 0) {
    console.log(`[${locale}] All strings already translated, skipping.`)
    return
  }

  console.log(`[${locale}] Found ${untranslated.length} untranslated strings.`)

  // Batch in groups of 30 to stay within token limits
  const BATCH_SIZE = 30
  let translated = 0

  for (let i = 0; i < untranslated.length; i += BATCH_SIZE) {
    const batch = untranslated.slice(i, i + BATCH_SIZE)
    const msgids = batch.map(item => item.msgid)

    console.log(
      `[${locale}] Translating batch ${Math.floor(i / BATCH_SIZE) + 1} (${batch.length} strings)...`
    )

    const translations = await translateBatch(msgids, languageName)

    for (const item of batch) {
      if (translations[item.msgid]) {
        item.msgstr = [translations[item.msgid]]
        translated++
      } else {
        console.warn(`[${locale}] Warning: no translation returned for: ${item.msgid.slice(0, 60)}`)
      }
    }
  }

  writeFileSync(filePath, po.toString())
  console.log(`[${locale}] Saved. Translated ${translated}/${untranslated.length} strings.`)
}

async function main() {
  if (!process.env.ANTHROPIC_API_KEY) {
    console.error('Error: ANTHROPIC_API_KEY environment variable is not set.')
    process.exit(1)
  }

  const requested = process.argv.slice(2)
  const locales = requested.length > 0 ? requested : ALL_LOCALES

  const invalid = locales.filter(l => !LANGUAGE_NAMES[l])
  if (invalid.length > 0) {
    console.error(`Unknown locale(s): ${invalid.join(', ')}`)
    console.error(`Valid locales: ${ALL_LOCALES.join(', ')}`)
    process.exit(1)
  }

  console.log(`Translating locales: ${locales.join(', ')}`)

  for (const locale of locales) {
    await translateFile(locale)
  }

  console.log('\nDone.')
}

main().catch(err => {
  console.error(err)
  process.exit(1)
})
