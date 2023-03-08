import { Controller } from "@hotwired/stimulus";

export default class PreviewController extends Controller {
  static targets = ["output"];

  connect() {
    console.log("PreviewController connected");
  }

  update(event) {
    const captionInput = document.querySelector("#advertisement_caption");
    const descriptionInput = document.querySelector("#advertisement_description");
    const previewImage = document.querySelector("#preview-image");
    const resourceInput = document.querySelector("#advertisement_resource");

    const caption = captionInput.value || "Заголовок";
    const description = descriptionInput.value.replace(/<\/?div[^>]*>/g, "") || "Деякий зміст оголошення для передогляду...";
    const imageSrc = previewImage.src;
    const resource = resourceInput.value;

    this.outputTarget.innerHTML = `
      <div class="col-span-1 ml-8">
        <div class="float-left relative w-full">
          <a href="${resource}" class="group relative block bg-black rounded-lg">
            <div class="relative w-80 h-80">
              <img id="preview-image" class="absolute h-full w-full object-cover opacity-90 transition-opacity group-hover:opacity-50 rounded-lg" src="${imageSrc}">
              <div class="absolute opacity-0 transition-opacity hover:opacity-100 relative p-1">
                <div class="mt-32 sm:mt-48 lg:mt-64">
                  <div class="translate-y-8 transform opacity-0 transition-all group-hover:translate-y-0 group-hover:opacity-100">
                    <p class="font-bold text-3xl font-oswald text-gray-100 float-left tracking-tight w-full mb-3 inline-block leading-none px-4 py-2 relative uppercase z-10 bg-rose-600 text-center opacity-[0.85] [text-shadow:_1px_1px_rgba(0,0,0,0.7)]">${caption}</p>
                    <p class="h-auto italic font-light text-gray-200 inline-block leading-none px-4 py-2 relative uppercase z-10 bg-rose-600 text-center opacity-[0.85] [text-shadow:_1px_1px_rgba(0,0,0,0.7)]">${description}</p>
                    <p class="h-4"></p>
                  </div>
                </div>
              </div>
          </a>
        </div>
      </div>
    `;

    this.previewImage(event);
  }

  previewImage(event) {
    const previewImage = document.querySelector("#preview-image");
    if (!previewImage) return;

    const input = event.target;
    if (input.files && input.files[0]) {
      const reader = new FileReader();
      reader.onload = () => {
        previewImage.src = reader.result;
        previewImage.style.display = "block";
      };
      reader.readAsDataURL(input.files[0]);
    }
  }
};
