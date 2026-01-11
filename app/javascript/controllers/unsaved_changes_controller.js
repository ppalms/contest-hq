import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]
  
  connect() {
    this.isDirty = false
    this.allowNavigationFlag = false
    
    this.formTarget.addEventListener('input', () => {
      this.markDirty()
    })
    
    this.formTarget.addEventListener('click', (event) => {
      const modifyingActions = [
        'markDeleted',
        'undoDelete',
        'moveUp',
        'moveDown',
        'confirmAdd',
        'removeNewItem'
      ]
      
      const action = event.target.dataset.action
      if (action && modifyingActions.some(a => action.includes(a))) {
        this.markDirty()
      }
    })
    
    document.addEventListener('turbo:before-visit', this.handleBeforeVisit.bind(this))
  }
  
  disconnect() {
    document.removeEventListener('turbo:before-visit', this.handleBeforeVisit.bind(this))
  }
  
  markDirty() {
    this.isDirty = true
  }
  
  handleBeforeVisit(event) {
    if (this.allowNavigationFlag) {
      return
    }
    
    if (!this.isDirty) {
      return
    }
    
    const url = event.detail.url
    if (url.includes('/selections/select_prescribed') ||
        url.includes('/selections/select_custom') ||
        url.includes('/selections/bulk_edit') ||
        url.includes('/selections/save_edit_state')) {
      return
    }
    
    if (!confirm('You have unsaved changes. Are you sure you want to leave?')) {
      event.preventDefault()
    }
  }
  
  allowNavigation(event) {
    this.allowNavigationFlag = true
  }
}
