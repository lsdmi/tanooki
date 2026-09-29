import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Read toggles answer with a Turbo Stream, which leaves stale library and fiction snapshots in the Turbo cache.
export default class extends Controller {
  clearCache(event) {
    if (event.detail?.success) Turbo.cache.clear()
  }
}
