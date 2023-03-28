import { Controller } from "@hotwired/stimulus";

export default class FlowbiteController extends Controller {
  initialize() {
    document
        .querySelectorAll('[data-dropdown-toggle]')
        .forEach(function ($triggerEl) {
        var dropdownId = $triggerEl.getAttribute('data-dropdown-toggle');
        var $dropdownEl = document.getElementById(dropdownId);
        if ($dropdownEl) {
            var placement = $triggerEl.getAttribute('data-dropdown-placement');
            var offsetSkidding = $triggerEl.getAttribute('data-dropdown-offset-skidding');
            var offsetDistance = $triggerEl.getAttribute('data-dropdown-offset-distance');
            var triggerType = $triggerEl.getAttribute('data-dropdown-trigger');
            var delay = $triggerEl.getAttribute('data-dropdown-delay');
            new Dropdown($dropdownEl, $triggerEl, {
                placement: placement ? placement : 'bottom',
                triggerType: triggerType
                    ? triggerType
                    : 'click',
                offsetSkidding: offsetSkidding
                    ? parseInt(offsetSkidding)
                    : 0,
                offsetDistance: offsetDistance
                    ? parseInt(offsetDistance)
                    : 10,
                delay: delay ? parseInt(delay) : 300,
            });
        }
        else {
            console.error("The dropdown element with id \"".concat(dropdownId, "\" does not exist. Please check the data-dropdown-toggle attribute."));
        }
    });
  }
}
