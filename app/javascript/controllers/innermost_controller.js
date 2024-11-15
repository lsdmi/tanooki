import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    const content = this.element.querySelector('#user-content');
    this.findInnermostElements(content);
  }

  findInnermostElements(element) {
    const elements = element.querySelectorAll('span, p');
    for (let el of elements) {
      if (!el.querySelector('span') && !el.querySelector('p')) {
        el.classList.add('innermost-element');
      }
    }
  }
}
