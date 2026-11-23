// Client-side mirror of FictionTags::Normalizer.name, so a name typed into the «Теґи» field looks the way the
// server will store it and matches an existing tag before submit. The server stays the authority on slugs
// (it transliterates), so tagKey is only a case-insensitive comparison, not a slug.

const APOSTROPHES = /['`ʼ‘´]/g

export function normalizeTagName(value) {
  return String(value ?? "")
    .normalize("NFC")
    .replace(APOSTROPHES, "’")
    .replace(/ё/g, "е")
    .replace(/Ё/g, "Е")
    .replace(/\s+/g, " ")
    .trim()
    .replace(/^#+/, "")
    .trim()
}

export function tagKey(value) {
  return normalizeTagName(value).toLocaleLowerCase("uk")
}

// The option whose value is the same tag as `name`, ignoring case, apostrophe style and ё/е.
export function findSameTag(optionValues, name) {
  const key = tagKey(name)
  return optionValues.find((value) => tagKey(value) === key)
}

// Why a typed name cannot become a tag, or null when it can. Mirrors Sync.name_error and the 10-tag limit.
export function tagNameProblem(name, { selectedCount, max, maxLength }) {
  if (!name) return "empty"
  if (name.length > maxLength) return "too_long"
  if (selectedCount >= max) return "too_many"
  return null
}
