// A guest's reading record for one fiction, kept on this device (`guest_reading_store`). No DOM or storage
// access, so it runs under `node --test`. The rules mirror the server's for signed-in readers:
// - "engaged" moves the resume cursor to the chapter and stamps `resumeAt`; the previous chapter's position goes.
//   Engaging the chapter the cursor is already on only refreshes the position (a held capture sends none).
// - "position" is taken only by the chapter the cursor is on.
// - "completed" adds the chapter to the sparse read set and, on the cursor chapter, makes the position 100%.
//
// Record: { fictionId, chapterId, chapterPath, nextPath, locator, readChapterIds, resumeAt }.
// `locator` is what `reading-progress` captures: { percent, block_index, quote, digest }.

export const FINISHED_PERCENT = 90
export const BANNER_MIN_PERCENT = 1

// chapter: { id, fictionId, path, nextPath }. Returns the new record, or null when nothing changes.
export function applyReadingEvent(record, payload, chapter, now = new Date()) {
  switch (payload.event) {
    case "engaged": return engage(record, payload.locator, chapter, now)
    case "position": return position(record, payload.locator, chapter)
    case "completed": return complete(record, chapter, now)
    default: return null
  }
}

// Where the fiction page «Продовжити» goes, as `Reading::ContinueTarget` decides for signed-in readers.
// Null means keep «Читати»: nothing recorded, or the latest chapter already read.
export function continueTarget(record, { latestChapterId } = {}) {
  if (!record?.chapterId || !record.chapterPath) return null

  const read = new Set(record.readChapterIds)
  if (latestChapterId && read.has(latestChapterId)) return null

  const percent = record.locator?.percent
  const finished = read.has(record.chapterId) && (!Number.isFinite(percent) || percent >= FINISHED_PERCENT)
  if (finished && record.nextPath) return { path: record.nextPath, resume: false }

  return { path: `${record.chapterPath}?resume=1`, resume: true }
}

// The stored place in this chapter worth restoring: always on ?resume=1, otherwise only for the banner range.
export function resumeLocator(record, chapterId, { auto = false } = {}) {
  if (!record || record.chapterId !== chapterId) return null

  const locator = record.locator
  if (!Number.isFinite(locator?.percent)) return null
  if (auto) return locator

  return locator.percent >= BANNER_MIN_PERCENT && locator.percent < FINISHED_PERCENT ? locator : null
}

// The server merges at most this many records per request; the rest go on a later page.
export const MERGE_BATCH = 200

// After sign-in (`guest-reading-merge`): the records to post this time, and the body the server reads.
// `records` is null when the store can't be read.
export function mergeBatch(records) {
  const batch = (records ?? []).slice(0, MERGE_BATCH)
  const body = {
    records: batch.map((record) => ({
      fiction_id: record.fictionId,
      chapter_id: record.chapterId,
      resume_at: record.resumeAt,
      read_chapter_ids: record.readChapterIds,
      locator: record.locator
    }))
  }
  return { batch, body }
}

function engage(record, locator, chapter, now) {
  const base = record ?? emptyRecord(chapter)
  if (base.chapterId === chapter.id) {
    return locator ? { ...base, locator, nextPath: chapter.nextPath ?? base.nextPath } : null
  }

  return {
    ...base,
    chapterId: chapter.id,
    chapterPath: chapter.path,
    nextPath: chapter.nextPath ?? null,
    locator: locator ?? null,
    resumeAt: now.toISOString()
  }
}

function position(record, locator, chapter) {
  if (!record || !locator || record.chapterId !== chapter.id) return null

  return { ...record, locator }
}

function complete(record, chapter, now) {
  const base = record ?? emptyRecord(chapter)
  const readChapterIds = base.readChapterIds.includes(chapter.id)
    ? base.readChapterIds
    : [...base.readChapterIds, chapter.id]
  const next = { ...base, readChapterIds }
  // No record yet (the engaged write failed): this chapter becomes the resume point, as on the server.
  if (!record) {
    Object.assign(next, {
      chapterId: chapter.id, chapterPath: chapter.path, nextPath: chapter.nextPath ?? null, resumeAt: now.toISOString()
    })
  } else if (base.chapterId === chapter.id && base.locator) {
    next.locator = { ...base.locator, percent: 100 }
  }

  return next
}

function emptyRecord(chapter) {
  return {
    fictionId: chapter.fictionId,
    chapterId: null,
    chapterPath: null,
    nextPath: null,
    locator: null,
    readChapterIds: [],
    resumeAt: null
  }
}
