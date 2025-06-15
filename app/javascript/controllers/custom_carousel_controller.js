import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["slides", "spinner", "indicator"];
  currentIndex = 0;
  intervalId = null;
  spinnerUsed = false; // Track if spinner was already used

  connect() {
    setTimeout(() => this.update(), 0);
    this.startAutoAdvance();
  }

  disconnect() {
    if (this.intervalId) clearInterval(this.intervalId);
  }

  startAutoAdvance() {
    this.intervalId = setInterval(() => this.next(), 5000);
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

  goTo(event) {
    const idx = parseInt(event.currentTarget.dataset.index, 10);
    this.currentIndex = idx;
    this.update();
  }  

  update() {
    const offset = -this.currentIndex * 100;
    this.slidesTarget.style.transform = `translateX(${offset}%)`;
  
    if (this.hasIndicatorTarget) {
      this.indicatorTargets.forEach((btn, idx) => {
        if (idx === this.currentIndex) {
          btn.classList.add("bg-cyan-700", "dark:!bg-white");
          btn.classList.remove("bg-gray-200", "dark:!bg-white/50");
        } else {
          btn.classList.remove("bg-cyan-700", "dark:!bg-white");
          btn.classList.add("bg-gray-200", "dark:!bg-white/50");
        }
      });
    }
  
    const activeSlide = this.slidesTarget.children[this.currentIndex];
    const lazyBg = activeSlide.querySelector('[data-controller="lazy-bg"]');
    if (lazyBg) {
      if (this.currentIndex === 0 && !this.spinnerUsed) {
        this.spinnerTarget.classList.remove("hidden");
        const onLoaded = () => {
          this.spinnerTarget.classList.add("hidden");
          this.spinnerUsed = true;
          lazyBg.removeEventListener("lazy-bg:loaded", onLoaded);
          lazyBg.removeEventListener("lazy-bg:error", onLoaded);
        };
        lazyBg.addEventListener("lazy-bg:loaded", onLoaded);
        lazyBg.addEventListener("lazy-bg:error", onLoaded);
      }
      lazyBg.dispatchEvent(new CustomEvent('lazy-bg:load', { bubbles: true }));
    }
  }  
}
