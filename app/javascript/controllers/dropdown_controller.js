import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "button", "navMenu", "navMenuButton"]
  
  connect() {
    this.outsideClickHandler = this.closeIfOutsideClick.bind(this)
    document.addEventListener('click', this.outsideClickHandler)
  }

  disconnect() {
    document.removeEventListener('click', this.outsideClickHandler)
    this.menuTarget.classList.add("hidden")
    this.navMenuTarget.classList.add("hidden")
  }

  toggle() {
    this.menuTarget.classList.toggle("hidden")
  }

  toggleNavMenu() {
    this.navMenuButtonTarget.classList.toggle('is-active');
    this.navMenuTarget.classList.toggle('hidden');
  }

  closeIfOutsideClick(event) {
    if (!this.buttonTarget.contains(event.target) 
      && !this.menuTarget.contains(event.target)
    ) {
      this.menuTarget.classList.add("hidden")
    }

    if(!this.navMenuButtonTarget.contains(event.target)
      && !this.navMenuTarget.contains(event.target)
    ) {
      this.navMenuTarget.classList.add("hidden")
      this.navMenuButtonTarget.classList.remove('is-active');
    }
  }
}
