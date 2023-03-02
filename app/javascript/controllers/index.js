import { Application } from "@hotwired/stimulus";
import PreviewController from "./preview_controller";

const application = Application.start();
application.register("preview", PreviewController);
