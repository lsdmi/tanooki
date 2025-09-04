import { Controller } from "@hotwired/stimulus";

// Minimal Tabs controller to satisfy Stimulus autoloading and optional future use
export default class extends Controller {
  static values = { activeTab: String };

  connect() {
    // No-op: server renders active tab styles. This exists to prevent autoload errors.
  }
}
