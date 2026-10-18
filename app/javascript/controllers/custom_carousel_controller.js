import { Controller } from "@hotwired/stimulus";

const AUTO_MS = 5000;
const SWIPE_THRESHOLD_PX = 48;
const AXIS_LOCK_PX = 10;

export default class extends Controller {
  static targets = ["slides", "spinner", "indicator"];
  static values = { eagerFirstSlide: { type: Boolean, default: false } };

  currentIndex = 0;
  intervalId = null;
  spinnerUsed = false;
  drag = null;

  connect() {
    if (this.eagerFirstSlideValue) {
      this.spinnerTarget.classList.add("hidden");
      this.spinnerUsed = true;
    }
    this.element.style.touchAction = "pan-y";
    setTimeout(() => this.update(), 0);
    this.startAutoAdvance();
  }

  disconnect() {
    this.stopAutoAdvance();
    this.teardownDrag();
  }

  startAutoAdvance() {
    this.stopAutoAdvance();
    if (this.slideCount() <= 1) return;
    this.intervalId = setInterval(() => {
      this.currentIndex = (this.currentIndex + 1) % this.slideCount();
      this.update();
    }, AUTO_MS);
  }

  stopAutoAdvance() {
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
    }
  }

  slideCount() {
    return this.slidesTarget.children.length;
  }

  goTo(event) {
    const idx = parseInt(event.currentTarget.dataset.index, 10);
    this.currentIndex = idx;
    this.update();
    this.startAutoAdvance();
  }

  pointerDown(event) {
    if (!event.isPrimary || event.button > 0 || this.slideCount() <= 1) return;
    if (event.pointerType === "mouse") return;

    this.drag = {
      pointerId: event.pointerId,
      startX: event.clientX,
      startY: event.clientY,
      width: this.element.clientWidth || 1,
      axis: null,
      dx: 0
    };

    this.stopAutoAdvance();
    this.onPointerMove = this.pointerMove.bind(this);
    this.onPointerUp = this.pointerUp.bind(this);
    window.addEventListener("pointermove", this.onPointerMove, { passive: false });
    window.addEventListener("pointerup", this.onPointerUp);
    window.addEventListener("pointercancel", this.onPointerUp);
  }

  pointerMove(event) {
    if (!this.drag || event.pointerId !== this.drag.pointerId) return;

    const dx = event.clientX - this.drag.startX;
    const dy = event.clientY - this.drag.startY;

    if (!this.drag.axis) {
      if (Math.abs(dx) < AXIS_LOCK_PX && Math.abs(dy) < AXIS_LOCK_PX) return;
      this.drag.axis = Math.abs(dx) >= Math.abs(dy) ? "x" : "y";
      if (this.drag.axis === "y") {
        this.teardownDrag({ resumeAuto: true });
        return;
      }
      this.slidesTarget.style.transition = "none";
    }

    if (this.drag.axis !== "x") return;

    event.preventDefault();
    this.drag.dx = dx;
    const base = -this.currentIndex * 100;
    const dragPct = (dx / this.drag.width) * 100;
    this.slidesTarget.style.transform = `translateX(${base + dragPct}%)`;
  }

  pointerUp(event) {
    if (!this.drag || event.pointerId !== this.drag.pointerId) return;

    const { axis, dx } = this.drag;
    const swiped = axis === "x" && Math.abs(dx) >= SWIPE_THRESHOLD_PX;

    if (swiped) {
      const count = this.slideCount();
      if (dx < 0) {
        this.currentIndex = (this.currentIndex + 1) % count;
      } else {
        this.currentIndex = (this.currentIndex - 1 + count) % count;
      }
      this.suppressNextClick();
    }

    this.slidesTarget.style.transition = "";
    this.teardownDrag({ resumeAuto: true });
    this.update();
  }

  teardownDrag({ resumeAuto = false } = {}) {
    if (this.onPointerMove) {
      window.removeEventListener("pointermove", this.onPointerMove);
      window.removeEventListener("pointerup", this.onPointerUp);
      window.removeEventListener("pointercancel", this.onPointerUp);
      this.onPointerMove = null;
      this.onPointerUp = null;
    }
    this.drag = null;
    if (resumeAuto) this.startAutoAdvance();
  }

  suppressNextClick() {
    const suppress = (event) => {
      event.preventDefault();
      event.stopPropagation();
    };
    this.element.addEventListener("click", suppress, { capture: true, once: true });
  }

  update() {
    const offset = -this.currentIndex * 100;
    this.slidesTarget.style.transform = `translateX(${offset}%)`;

    if (this.hasIndicatorTarget) {
      // Keep in sync with _showcase_carousel indicator classes (theme ink on the veil).
      const inactive = ["w-1.5", "bg-fg/35", "hover:bg-fg/55", "dark:bg-white/45", "dark:hover:bg-white/70"];
      const active = ["w-6", "bg-fg", "dark:bg-white"];
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
      lazyBg.dispatchEvent(new CustomEvent("lazy-bg:load", { bubbles: true }));
    }
  }
}
