import { Controller } from "@hotwired/stimulus";

export default class DropzoneController extends Controller {
  static targets = ["input", "name", "preview", "placeholder"];

  disconnect() {
    this.revokePreview();
  }

  allowDrop(event) {
    event.preventDefault();
  }

  drop(event) {
    event.preventDefault();
    if (!this.hasInputTarget) return;

    const file = event.dataTransfer?.files?.[0];
    if (!file) return;

    const transfer = new DataTransfer();
    transfer.items.add(file);
    this.inputTarget.files = transfer.files;
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }));
  }

  update(event) {
    this.refreshName(event.target);
    this.refreshPreview(event.target);
  }

  refreshName(input) {
    if (!this.hasNameTarget) return;

    const file = input.files?.[0];
    if (!file) return;

    this.nameTarget.textContent = file.name.slice(0, 40);
    this.nameTarget.classList.remove("hidden");
  }

  refreshPreview(input) {
    if (!this.hasPreviewTarget) return;

    const file = input.files?.[0];
    if (!file || !file.type.startsWith("image/")) return;

    this.revokePreview();
    this.previewUrl = URL.createObjectURL(file);
    this.previewTarget.src = this.previewUrl;
    this.previewTarget.alt = file.name;
    this.previewTarget.classList.remove("hidden");
    if (this.hasPlaceholderTarget) this.placeholderTarget.classList.add("hidden");
  }

  revokePreview() {
    if (!this.previewUrl) return;

    URL.revokeObjectURL(this.previewUrl);
    this.previewUrl = null;
  }
}
