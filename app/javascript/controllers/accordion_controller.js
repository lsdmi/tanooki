import { Controller } from "@hotwired/stimulus";

export default class AccordionController extends Controller {
  initialize() {
    document.querySelectorAll('[data-accordion]').forEach(function ($accordionEl) {
      var alwaysOpen = $accordionEl.getAttribute('data-accordion');
      var activeClasses = $accordionEl.getAttribute('data-active-classes');
      var inactiveClasses = $accordionEl.getAttribute('data-inactive-classes');
      var items = [];
      $accordionEl
          .querySelectorAll('[data-accordion-target]')
          .forEach(function ($triggerEl) {
          var item = {
              id: $triggerEl.getAttribute('data-accordion-target'),
              triggerEl: $triggerEl,
              targetEl: document.querySelector($triggerEl.getAttribute('data-accordion-target')),
              iconEl: $triggerEl.querySelector('[data-accordion-icon]'),
              active: $triggerEl.getAttribute('aria-expanded') === 'true'
                  ? true
                  : false,
          };
          items.push(item);
      });
      new Accordion(items, {
          alwaysOpen: alwaysOpen === 'open' ? true : false,
          activeClasses: activeClasses
              ? activeClasses
              : 'bg-gray-100 text-gray-900',
          inactiveClasses: inactiveClasses
              ? inactiveClasses
              : 'text-gray-500',
      });
  });
  }
}
