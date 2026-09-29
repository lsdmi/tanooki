import { test } from "node:test"
import assert from "node:assert/strict"
import { applyReadingEvent, continueTarget, resumeLocator } from "../../app/javascript/guest_reading.js"

const NOW = new Date("2026-09-29T12:00:00Z")
const LATER = new Date("2026-09-29T13:00:00Z")
const chapter = (id, nextPath = `/chapters/c${id + 1}`) => ({ id, fictionId: 7, path: `/chapters/c${id}`, nextPath })
const locator = (percent) => ({ percent, block_index: 4, quote: "Він довго мовчав", digest: "0123456789abcdef" })
const engaged = (record, id, at = NOW, spot = locator(30)) =>
  applyReadingEvent(record, { event: "engaged", locator: spot }, chapter(id), at)

test("engaging a first chapter starts the record there", () => {
  const record = engaged(null, 3)

  assert.deepEqual(record, {
    fictionId: 7,
    chapterId: 3,
    chapterPath: "/chapters/c3",
    nextPath: "/chapters/c4",
    locator: locator(30),
    readChapterIds: [],
    resumeAt: NOW.toISOString()
  })
})

test("engaging another chapter moves the cursor, drops the old place and keeps the reads", () => {
  const read = applyReadingEvent(engaged(null, 3), { event: "completed" }, chapter(3), NOW)
  const record = engaged(read, 6, LATER, null)

  assert.equal(record.chapterId, 6)
  assert.equal(record.locator, null)
  assert.equal(record.resumeAt, LATER.toISOString())
  assert.deepEqual(record.readChapterIds, [3])
})

test("engaging the cursor chapter again refreshes the place only, and a held capture changes nothing", () => {
  const record = engaged(null, 3)

  assert.equal(engaged(record, 3, LATER, locator(55)).locator.percent, 55)
  assert.equal(engaged(record, 3, LATER, locator(55)).resumeAt, NOW.toISOString())
  assert.equal(engaged(record, 3, LATER, null), null)
})

test("positions are taken only on the cursor chapter", () => {
  const record = engaged(null, 3)

  assert.equal(applyReadingEvent(record, { event: "position", locator: locator(70) }, chapter(3)).locator.percent, 70)
  assert.equal(applyReadingEvent(record, { event: "position", locator: locator(70) }, chapter(4)), null)
  assert.equal(applyReadingEvent(null, { event: "position", locator: locator(70) }, chapter(3)), null)
})

test("completing reads sparsely: 3 then 6 stores exactly those two, once each", () => {
  let record = engaged(null, 3)
  record = applyReadingEvent(record, { event: "completed" }, chapter(3), NOW)
  record = engaged(record, 6)
  record = applyReadingEvent(record, { event: "completed" }, chapter(6), NOW)
  record = applyReadingEvent(record, { event: "completed" }, chapter(6), NOW)

  assert.deepEqual(record.readChapterIds, [3, 6])
})

test("completing the cursor chapter finishes its place; another chapter leaves the place alone", () => {
  const record = engaged(null, 3)

  assert.equal(applyReadingEvent(record, { event: "completed" }, chapter(3), NOW).locator.percent, 100)
  assert.equal(applyReadingEvent(record, { event: "completed" }, chapter(5), NOW).locator.percent, 30)
})

test("completing with no record makes that chapter the resume point", () => {
  const record = applyReadingEvent(null, { event: "completed" }, chapter(3), NOW)

  assert.equal(record.chapterId, 3)
  assert.deepEqual(record.readChapterIds, [3])
})

test("continue restores an unread cursor chapter and moves past a finished one", () => {
  const record = engaged(null, 3)
  const finished = applyReadingEvent(record, { event: "completed" }, chapter(3), NOW)

  assert.deepEqual(continueTarget(record, { latestChapterId: 9 }), { path: "/chapters/c3?resume=1", resume: true })
  assert.deepEqual(continueTarget(finished, { latestChapterId: 9 }), { path: "/chapters/c4", resume: false })
})

test("continue goes back into a read chapter being re-read and stays put when nothing follows", () => {
  const reread = { ...engaged(null, 3), readChapterIds: [3] }
  const latest = chapter(9, null)
  const started = applyReadingEvent(null, { event: "engaged", locator: locator(30) }, latest, NOW)
  const last = applyReadingEvent(started, { event: "completed" }, latest, NOW)

  assert.equal(continueTarget(reread, { latestChapterId: 12 }).path, "/chapters/c3?resume=1")
  assert.equal(continueTarget(last, { latestChapterId: 12 }).path, "/chapters/c9?resume=1")
})

test("continue keeps «Читати» with no record or once the latest chapter is read", () => {
  const record = applyReadingEvent(engaged(null, 9), { event: "completed" }, chapter(9), NOW)

  assert.equal(continueTarget(null, { latestChapterId: 9 }), null)
  assert.equal(continueTarget(record, { latestChapterId: 9 }), null)
})

test("resume restores anything on ?resume=1 but offers the banner only between 1% and 90%", () => {
  const at = (percent) => ({ ...engaged(null, 3), locator: locator(percent) })

  assert.equal(resumeLocator(at(0.4), 3, { auto: true }).percent, 0.4)
  assert.equal(resumeLocator(at(0.4), 3), null)
  assert.equal(resumeLocator(at(42), 3).percent, 42)
  assert.equal(resumeLocator(at(95), 3), null)
})

test("resume needs the cursor on this chapter and a stored percent", () => {
  assert.equal(resumeLocator(engaged(null, 3), 4, { auto: true }), null)
  assert.equal(resumeLocator(engaged(null, 3, NOW, null), 3, { auto: true }), null)
  assert.equal(resumeLocator(null, 3, { auto: true }), null)
})
