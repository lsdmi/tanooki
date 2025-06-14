import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["slides"];
  currentIndex = 0;

  connect() {
    setTimeout(() => this.update(), 0);
  }  

  next() {
    this.currentIndex = (this.currentIndex + 1) % this.slideCount();
    this.update();
  }

  prev() {
    this.currentIndex = (this.currentIndex - 1 + this.slideCount()) % this.slideCount();
    this.update();
  }

  slideCount() {
    return this.slidesTarget.children.length;
  }

  update() {
    const offset = -this.currentIndex * 100;
    this.slidesTarget.style.transform = `translateX(${offset}%)`;
  
    const activeSlide = this.slidesTarget.children[this.currentIndex];
    const lazyBg = activeSlide.querySelector('[data-controller="lazy-bg"]');
    if (lazyBg) {
      lazyBg.dispatchEvent(new CustomEvent('lazy-bg:load', { bubbles: true }));
    }
  }  
}
