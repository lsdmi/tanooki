import { Controller } from "@hotwired/stimulus"

export default class FlowbiteController extends Controller {
  connect() {
    initFlowbite()
  }

  disconnect() {
    this.closeOpenDropdowns()
  }

  closeOpenDropdowns() {
    this.element.querySelectorAll("[data-dropdown-toggle][aria-expanded='true']").forEach((toggle) => {
      const menuId = toggle.getAttribute("data-dropdown-toggle")
      const menu = menuId ? document.getElementById(menuId) : null

      toggle.setAttribute("aria-expanded", "false")
      if (menu) {
        menu.classList.add("hidden")
        menu.classList.remove("block")
      }
    })
  }
}
