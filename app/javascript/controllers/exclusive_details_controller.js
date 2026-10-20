import { Controller } from "@hotwired/stimulus"

/**
 * One open <details> at a time within a group: opening a panel closes its peers.
 */
export default class extends Controller {
  static targets = ["panel"]

  sync(event) {
    const panel = event.target
    if (!(panel instanceof HTMLDetailsElement) || !panel.open) return

    this.panelTargets.forEach((peer) => {
      if (peer !== panel) peer.open = false
    })
  }
}
