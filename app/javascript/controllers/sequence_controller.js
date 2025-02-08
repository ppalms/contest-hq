import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  static targets = ["steps", "template", "step", "destroy"]

  addStep(event) {
    event.preventDefault()
    const templateHTML = this.templateTarget.innerHTML
    const timestamp = new Date().getTime()
    const newStepHTML = templateHTML.replace(/NEW_RECORD/g, timestamp)
 
    this.stepsTarget.insertAdjacentHTML('beforeend', newStepHTML)
    this.updateOrdinals()
  }

  removeStep(event) {
    event.preventDefault()
 
    const stepElement = event.target.closest('[data-sequence-target="step"]')

    const isNewRecord = stepElement.dataset.newRecord === "true"
    if (isNewRecord) {
      // For new records, disable all form controls before removing
      const formControls = stepElement.querySelectorAll('input, select, textarea')
      formControls.forEach(control => {
        control.disabled = true
        control.required = false
      })

      setTimeout(() => {
        stepElement.remove()
        this.updateOrdinals()
      }, 0)
    } else {
      // For existing records, use the standard destroy pattern
      const destroyInput = stepElement.querySelector('[data-sequence-target="destroy"]')
      if (destroyInput) {
        destroyInput.value = '1'
        stepElement.style.display = 'none'
        this.updateOrdinals()
      } else {
        console.error('Could not find destroy input for step')
      }
    }
  }

  updateOrdinals() {
    const visibleSteps = this.stepTargets.filter(step => {
      if (step.style.display === 'none') return false
      const destroyInput = step.querySelector('[data-sequence-target="destroy"]')
      return !destroyInput || destroyInput.value !== '1'
    })
 
    visibleSteps.forEach((step, index) => {
      const ordinalInput = step.querySelector('input[name$="[ordinal]"]')
      if (ordinalInput) {
        ordinalInput.value = index + 1
      }
    })
  }
}
