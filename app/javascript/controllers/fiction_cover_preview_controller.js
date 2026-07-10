import { Controller } from "@hotwired/stimulus";

export default class FictionCoverPreviewController extends Controller {
  static targets = ["input", "panel", "previewImage", "warnings", "success"];
  static values = {
    minWidth: { type: Number, default: 600 },
    minHeight: { type: Number, default: 800 },
    idealAspect: { type: Number, default: 0.75 },
    aspectTolerance: { type: Number, default: 0.1 },
    maxMegabytes: { type: Number, default: 2 },
    allowedTypes: Array
  };

  connect() {
    this.previewUrl = null;
  }

  disconnect() {
    this.revokePreviewUrl();
  }

  preview() {
    const file = this.inputTarget.files?.[0];

    if (!file) {
      this.clearPreview();
      return;
    }

    this.revokePreviewUrl();
    this.previewUrl = URL.createObjectURL(file);
    this.previewImageTarget.src = this.previewUrl;
    this.panelTarget.classList.remove("hidden");

    const probe = new Image();
    probe.onload = () => this.renderFeedback(file, probe.naturalWidth, probe.naturalHeight);
    probe.src = this.previewUrl;
  }

  clearPreview() {
    this.revokePreviewUrl();
    this.panelTarget.classList.add("hidden");
    this.previewImageTarget.removeAttribute("src");
    this.warningsTarget.replaceChildren();
    this.warningsTarget.classList.add("hidden");
    this.successTarget.classList.add("hidden");
  }

  renderFeedback(file, width, height) {
    const warnings = this.collectWarnings(file, width, height);

    this.warningsTarget.replaceChildren();
    this.warningsTarget.classList.toggle("hidden", warnings.length === 0);
    this.successTarget.classList.toggle("hidden", warnings.length > 0);

    warnings.forEach((message) => {
      const item = document.createElement("li");
      item.textContent = message;
      this.warningsTarget.appendChild(item);
    });
  }

  collectWarnings(file, width, height) {
    const warnings = [];

    if (!this.allowedTypesValue.includes(file.type)) {
      warnings.push("Обкладинка має бути у форматі WebP або AVIF.");
    }

    if (file.size > this.maxBytesValue) {
      warnings.push(`Розмір файлу обкладинки не може перевищувати ${this.maxMegabytesValue} МБ.`);
    }

    if (width < this.minWidthValue) {
      warnings.push(`Ширина обкладинки має бути не менше ${this.minWidthValue}px.`);
    }

    if (height < this.minHeightValue) {
      warnings.push(`Висота обкладинки має бути не менше ${this.minHeightValue}px.`);
    }

    const aspect = width / height;
    if (Math.abs(aspect - this.idealAspectValue) > this.aspectToleranceValue) {
      warnings.push("Співвідношення сторін має бути близько 3:4.");
    }

    return warnings;
  }

  get maxBytesValue() {
    return this.maxMegabytesValue * 1024 * 1024;
  }

  revokePreviewUrl() {
    if (!this.previewUrl) return;

    URL.revokeObjectURL(this.previewUrl);
    this.previewUrl = null;
  }
}
