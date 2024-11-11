import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["panel", "message"];
  static values = { content: String };

  connect() {
    console.log("Notification controller connected");
    this.show();
  }

  show() {
    console.log("Notification show method called");
    this.messageTarget.textContent = this.contentValue || "Notification";

    // Automatically hide after 3 seconds
    this.timeout = setTimeout(() => {
      this.hide();
    }, 5000);
  }

  hide() {
    console.log("Notification hide method called");
    
    // Clear the timeout if the user manually closes the notification
    if (this.timeout) clearTimeout(this.timeout);

    this.element.classList.add("opacity-0", "translate-y-2");
    setTimeout(() => {
      this.element.remove();
    }, 300); // Allow time for the fade-out transition
  }
}
