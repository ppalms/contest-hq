import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "item", "position"]

  moveUp(event) {
    event.preventDefault()
    const item = event.target.closest('[data-music-order-target="item"]')
    const prev = item.previousElementSibling
    if (prev) {
      item.parentNode.insertBefore(item, prev)
      this.updatePositions()
    }
  }

  moveDown(event) {
    event.preventDefault()
    const item = event.target.closest('[data-music-order-target="item"]')
    const next = item.nextElementSibling
    if (next) {
      item.parentNode.insertBefore(next, item)
      this.updatePositions()
    }
  }

  updatePositions() {
    this.itemTargets.forEach((item, index) => {
      const positionInput = item.querySelector('[data-music-order-target="position"]')
      if (positionInput) {
        positionInput.value = index + 1
      }

      const upBtn = item.querySelector('[data-action="music-order#moveUp"]')
      const downBtn = item.querySelector('[data-action="music-order#moveDown"]')
      if (upBtn) upBtn.disabled = index === 0
      if (downBtn) downBtn.disabled = index === this.itemTargets.length - 1
    })
  }
}
