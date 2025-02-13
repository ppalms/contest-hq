import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  static targets = [
    "tab", "pane", "phases", "template", "phase", "phaseName", "destroy"
  ]

  connect() {
    if (!this.tabTargets.find(tab => tab.classList.contains('active'))) {
      this.selectTab({ target: this.tabTargets[0] })
    }
  }

  selectTab(event) {
    const clickedTab = event.target
    const targetId = clickedTab.dataset.target

    this.tabTargets.forEach(tab => {
      tab.classList.toggle('active', tab === clickedTab)
    })

    this.paneTargets.forEach(pane => {
      const isTarget = pane.id === targetId
      pane.classList.toggle('active', isTarget)
      pane.classList.toggle('hidden', !isTarget)
    })
  }

  addPhase(event) {
    event.preventDefault()
    const templateHTML = this.templateTarget.innerHTML
    const timestamp = new Date().getTime()
    const newPhaseHTML = templateHTML.replace(/NEW_RECORD/g, timestamp)
 
    this.phasesTarget.insertAdjacentHTML('beforeend', newPhaseHTML)
    this.updateOrdinals()

    const newPhase = this.phasesTarget.lastElementChild
    const nameField = newPhase.querySelector('[data-contest-setup-target="phaseName"]')
    nameField.focus()
  }

  removePhase(event) {
    event.preventDefault()
 
    const phaseElement = event.target.closest('[data-contest-setup-target="phase"]')

    const isNewRecord = phaseElement.dataset.newRecord === "true"
    if (isNewRecord) {
      // For new records, disable all form controls before removing
      const formControls = phaseElement.querySelectorAll('input, select, textarea')
      formControls.forEach(control => {
        control.disabled = true
        control.required = false
      })

      setTimeout(() => {
        phaseElement.remove()
        this.updateOrdinals()
      }, 0)
    } else {
      // For existing records, use the standard destroy pattern
      const destroyInput = phaseElement.querySelector('[data-contest-setup-target="destroy"]')
      if (destroyInput) {
        destroyInput.value = '1'
        phaseElement.style.display = 'none'
        this.updateOrdinals()
      } else {
        console.error('Could not find destroy input for phase')
      }
    }
  }

  updateOrdinals() {
    const visiblePhases = this.phaseTargets.filter(phase => {
      if (phase.style.display === 'none') return false
      const destroyInput = phase.querySelector('[data-contest-setup-target="destroy"]')
      return !destroyInput || destroyInput.value !== '1'
    })
 
    visiblePhases.forEach((phase, index) => {
      const ordinalInput = phase.querySelector('input[name$="[ordinal]"]')
      if (ordinalInput) {
        ordinalInput.value = index + 1
      }
    })
  }
}
