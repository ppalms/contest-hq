import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["panel", "message"];
  static values = { content: String };

  connect() {
    this.show();
  }

  show() {
    this.messageTarget.textContent = this.contentValue || "Notification";

    this.timeout = setTimeout(() => {
      this.hide();
    }, 5000);
  }

  hide() {
    // Clear the timeout if the user manually closes the notification
    if (this.timeout) clearTimeout(this.timeout);

    this.element.classList.add("opacity-0", "translate-y-2");

    setTimeout(() => {
      this.element.remove();
    }, 1000); // Allow time for the fade-out transition
  }
}
