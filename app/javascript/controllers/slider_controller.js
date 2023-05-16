import { Controller } from "@hotwired/stimulus";

export default class SliderController extends Controller {
  static targets = [ "scrollContainer", "image", "indicator" ];

  connect() {
    const leftButton = document.querySelector('#button-left');
    const rightButton = document.querySelector('#button-right');

    leftButton.classList.add('hidden');
    rightButton.classList.remove('hidden');

    this.handleResize();
  }

  constructor() {
    super();
    this.handleResize = this.handleResize.bind(this);
    window.addEventListener('resize', this.handleResize);
  }

  slideLeft() {
    const visibleElems = document.querySelectorAll('.gallery > [data-slider-target="image"]:not(.hidden)');
    const lastVisibleElem = visibleElems[visibleElems.length - 1];
    const index = parseInt(lastVisibleElem.dataset.sliderElement);
    const prevHiddenElem = document.querySelector(`[data-slider-element="${index - 5}"]`);
    const leftButton = document.querySelector('#button-left');
    const rightButton = document.querySelector('#button-right');

    lastVisibleElem.classList.add('hidden');
    if (prevHiddenElem) {
      prevHiddenElem.classList.remove('hidden');
      rightButton.classList.remove('hidden');
    }
    leftButton.classList.toggle('hidden', !document.querySelector(`[data-slider-element="${index - 6}"]`));
  }

  slideRight() {
    const firstVisibleElem = document.querySelector('.gallery > [data-slider-target="image"]:not(.hidden)');
    const index = parseInt(firstVisibleElem.dataset.sliderElement);
    const elementsOnPage = this.elementsOnPage();
    const nextHiddenElem = document.querySelector(`[data-slider-element="${index + elementsOnPage}"]`);
    const leftButton = document.querySelector('#button-left');
    const rightButton = document.querySelector('#button-right');

    firstVisibleElem.classList.add('hidden');
    if (nextHiddenElem) {
      nextHiddenElem.classList.remove('hidden');
      leftButton.classList.remove('hidden');
    }
    rightButton.classList.toggle('hidden', !document.querySelector(`[data-slider-element="${index + elementsOnPage + 1}"]`));
  }

  handleResize() {
    const elements = document.querySelectorAll('.gallery > [data-slider-target="image"]');
    const elementsOnPage = this.elementsOnPage();

    elements.forEach (element => { element.classList.add('hidden') });

    for (let i = 0; i < elementsOnPage; i++) {
      elements[i].classList.remove('hidden');
    }
  }

  elementsOnPage() {
    if (window.innerWidth > 1023) {
      return 5;
    } else if (window.innerWidth > 767) {
      return 4;
    } else {
      return document.querySelectorAll('.gallery > [data-slider-target="image"]').length;
    }
  }
}
