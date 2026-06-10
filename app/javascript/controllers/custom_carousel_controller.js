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
    if (this.slideCount() <= 1) return;
    this.intervalId = setInterval(() => {
      this.currentIndex = (this.currentIndex + 1) % this.slideCount();
      this.update();
    }, 5000);
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
      const inactive = ["h-1.5", "w-3.5", "rounded-lg", "bg-white/35", "hover:bg-white/55"];
      const active = ["h-1.5", "w-8", "rounded-lg", "bg-cyan-500", "shadow-sm", "dark:bg-rose-500"];
      this.indicatorTargets.forEach((btn, idx) => {
        const isActive = idx === this.currentIndex;
        if (isActive) {
          btn.setAttribute("aria-current", "true");
          inactive.forEach((c) => btn.classList.remove(c));
          active.forEach((c) => btn.classList.add(c));
        } else {
          btn.removeAttribute("aria-current");
          active.forEach((c) => btn.classList.remove(c));
          inactive.forEach((c) => btn.classList.add(c));
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
