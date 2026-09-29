// Guest reading records on this device: IndexedDB, one record per fiction (see `guest_reading`).
// Any failure (private mode, storage blocked or full, no IndexedDB, a closed connection) resolves to null and
// writes nothing, so the reader carries on untracked instead of erroring.
const DB_NAME = "baka-reading"
const DB_VERSION = 1
const STORE = "fictions"

let database = null

function openDatabase() {
  database ??= new Promise((resolve) => {
    try {
      const request = indexedDB.open(DB_NAME, DB_VERSION)
      request.onupgradeneeded = () => request.result.createObjectStore(STORE, { keyPath: "fictionId" })
      request.onsuccess = () => {
        const db = request.result
        db.onversionchange = () => {
          db.close()
          database = null
        }
        resolve(db)
      }
      request.onerror = () => resolve(null)
      request.onblocked = () => resolve(null)
    } catch {
      resolve(null)
    }
  })
  return database
}

function run(mode, work) {
  return openDatabase().then((db) => new Promise((resolve) => {
    if (!db) return resolve(null)

    try {
      const transaction = db.transaction(STORE, mode)
      let result = null
      transaction.oncomplete = () => resolve(result)
      transaction.onerror = () => resolve(null)
      transaction.onabort = () => resolve(null)
      work(transaction.objectStore(STORE), (value) => { result = value })
    } catch {
      resolve(null)
    }
  }))
}

export function readRecord(fictionId) {
  if (!fictionId) return Promise.resolve(null)

  return run("readonly", (store, done) => {
    const request = store.get(fictionId)
    request.onsuccess = () => done(request.result ?? null)
  })
}

// Read-modify-write in one transaction. `change` gets the stored record (or null) and returns the new one;
// returning null leaves the store as it was.
export function updateRecord(fictionId, change) {
  if (!fictionId) return Promise.resolve(null)

  return run("readwrite", (store, done) => {
    const request = store.get(fictionId)
    request.onsuccess = () => {
      const next = change(request.result ?? null)
      if (!next) return

      store.put(next)
      done(next)
    }
  })
}
