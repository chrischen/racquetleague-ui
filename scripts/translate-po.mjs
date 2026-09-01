/**
 * Translation pipeline using pofile + Anthropic Claude
 *
 * Usage:
 *   node scripts/translate-po.mjs [locale...] [--refs <pattern>] [--force]
 *
 * Examples:
 *   node scripts/translate-po.mjs                  # translate all locales
 *   node scripts/translate-po.mjs ja ko            # translate specific locales
 *   node scripts/translate-po.mjs --refs MatchmakingReport --force
 *                                                  # re-translate one page's strings
 *
 * --refs limits the run to strings whose source references match the pattern
 * (a regex, matched against the `#:` comments). --force re-translates strings
 * that already have a translation; without it only empty ones are filled.
 *
 * Reads ANTHROPIC_API_KEY from .env.development (or existing env var).
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

// Load ANTHROPIC_API_KEY from .env.development if not already set
if (!process.env.ANTHROPIC_API_KEY) {
  const envPath = path.join(__dirname, '../.env.development')
  const envContent = readFileSync(envPath, 'utf8')
  const match = envContent.match(/^ANTHROPIC_API_KEY=(.+)$/m)
  if (match) process.env.ANTHROPIC_API_KEY = match[1].trim()
}

const LANGUAGE_NAMES = {
  ja: 'Japanese',
  ko: 'Korean',
  'zh-CN': 'Simplified Chinese',
  'zh-TW': 'Traditional Chinese',
  vi: 'Vietnamese',
  th: 'Thai',
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

// Structured output schema: forces the model to emit schema-valid JSON, so
// quotes/newlines inside translated strings are always escaped correctly.
const TRANSLATION_SCHEMA = {
  type: 'object',
  properties: {
    translations: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          index: { type: 'integer', description: '1-based index of the source string' },
          text: { type: 'string', description: 'the translated string' },
        },
        required: ['index', 'text'],
        additionalProperties: false,
      },
    },
  },
  required: ['translations'],
  additionalProperties: false,
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
- Return one entry per source string, using the same 1-based index shown below

Strings to translate:
${numbered}`

  // Streamed: Opus 5 thinks by default, so a batch can run long enough to hit
  // the non-streaming HTTP timeout.
  const response = await client.messages
    .stream({
      model: 'claude-opus-5',
      max_tokens: 32000,
      output_config: {
        effort: 'medium',
        format: { type: 'json_schema', schema: TRANSLATION_SCHEMA },
      },
      messages: [{ role: 'user', content: prompt }],
    })
    .finalMessage()

  if (response.stop_reason === 'max_tokens') {
    throw new Error('Response truncated at max_tokens; retry with a smaller batch')
  }

  // Find the text content block (skip thinking blocks)
  const textBlock = response.content.find(block => block.type === 'text')
  if (!textBlock) {
    console.error('No text block found in response:', JSON.stringify(response.content, null, 2))
    throw new Error('Claude API response missing text content')
  }

  let parsed
  try {
    parsed = JSON.parse(textBlock.text)
  } catch (err) {
    throw new Error(`Claude returned unparseable JSON (${err.message}):\n${textBlock.text}`)
  }

  const byIndex = new Map(parsed.translations.map(t => [t.index, t.text]))
  const result = {}
  msgids.forEach((id, i) => {
    const translation = byIndex.get(i + 1)
    if (translation) result[id] = translation
  })
  return result
}

const MAX_ATTEMPTS = 3

/**
 * translateBatch with retries, covering both failure modes seen in practice:
 * a whole batch erroring out (halve it and retry each half), and the model
 * silently skipping some entries (retry just the missing ones).
 */
async function translateBatchWithRetry(msgids, targetLanguage, locale, attempt = 1) {
  let result

  try {
    result = await translateBatch(msgids, targetLanguage)
  } catch (err) {
    if (attempt >= MAX_ATTEMPTS || msgids.length === 1) {
      console.error(`[${locale}] Giving up on ${msgids.length} string(s): ${err.message}`)
      return {}
    }
    console.warn(`[${locale}] Batch failed (${err.message}); retrying as two halves.`)
    const mid = Math.ceil(msgids.length / 2)
    const [a, b] = await Promise.all([
      translateBatchWithRetry(msgids.slice(0, mid), targetLanguage, locale, attempt + 1),
      translateBatchWithRetry(msgids.slice(mid), targetLanguage, locale, attempt + 1),
    ])
    return { ...a, ...b }
  }

  const missing = msgids.filter(id => !result[id])
  if (missing.length > 0 && attempt < MAX_ATTEMPTS) {
    console.warn(`[${locale}] ${missing.length} string(s) skipped by the model; retrying those.`)
    Object.assign(result, await translateBatchWithRetry(missing, targetLanguage, locale, attempt + 1))
  }
  return result
}

/**
 * Translate a .po file and save it. `refs` (a RegExp or null) limits the run to
 * strings from matching source files; `force` re-translates existing translations.
 */
async function translateFile(locale, { refs, force }) {
  const filePath = path.join(LOCALES_DIR, `${locale}.po`)
  const languageName = LANGUAGE_NAMES[locale]

  console.log(`\n[${locale}] Loading ${filePath}...`)
  const content = readFileSync(filePath, 'utf8')
  const po = PO.parse(content)
  const pending = po.items.filter(item => {
    if (item.obsolete) return false
    if (!item.msgid) return false
    if (refs && !(item.references || []).some(ref => refs.test(ref))) return false
    return force || !item.msgstr[0]
  })

  if (pending.length === 0) {
    console.log(`[${locale}] Nothing to translate, skipping.`)
    return
  }

  console.log(`[${locale}] Found ${pending.length} strings to translate.`)

  // Batch in groups of 30 to stay within token limits
  const BATCH_SIZE = 30
  let translated = 0

  for (let i = 0; i < pending.length; i += BATCH_SIZE) {
    const batch = pending.slice(i, i + BATCH_SIZE)
    const msgids = batch.map(item => item.msgid)

    console.log(
      `[${locale}] Translating batch ${Math.floor(i / BATCH_SIZE) + 1}/${Math.ceil(pending.length / BATCH_SIZE)} (${batch.length} strings)...`
    )

    const translations = await translateBatchWithRetry(msgids, languageName, locale)

    for (const item of batch) {
      if (translations[item.msgid]) {
        item.msgstr = [translations[item.msgid]]
        translated++
      } else {
        console.warn(`[${locale}] Warning: no translation returned for: ${item.msgid.slice(0, 60)}`)
      }
    }

    // Save after each batch so a later failure doesn't discard finished work.
    writeFileSync(filePath, po.toString())
  }

  console.log(`[${locale}] Saved. Translated ${translated}/${pending.length} strings.`)
}

async function main() {
  if (!process.env.ANTHROPIC_API_KEY) {
    console.error('Error: ANTHROPIC_API_KEY environment variable is not set.')
    process.exit(1)
  }

  const argv = process.argv.slice(2)
  const requested = []
  let refsPattern = null
  let force = false

  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === '--force') force = true
    else if (argv[i] === '--refs') refsPattern = argv[++i]
    else requested.push(argv[i])
  }

  if (refsPattern === undefined) {
    console.error('Error: --refs requires a pattern.')
    process.exit(1)
  }

  const locales = requested.length > 0 ? requested : ALL_LOCALES

  const invalid = locales.filter(l => !LANGUAGE_NAMES[l])
  if (invalid.length > 0) {
    console.error(`Unknown locale(s): ${invalid.join(', ')}`)
    console.error(`Valid locales: ${ALL_LOCALES.join(', ')}`)
    process.exit(1)
  }

  const refs = refsPattern ? new RegExp(refsPattern) : null

  console.log(`Translating locales: ${locales.join(', ')} (in parallel)`)
  if (refs) console.log(`Limited to strings from sources matching /${refsPattern}/`)
  if (force) console.log('Re-translating strings that already have translations')

  await Promise.all(locales.map(locale => translateFile(locale, { refs, force })))

  console.log('\nDone.')
}

main().catch(err => {
  console.error(err)
  process.exit(1)
})
