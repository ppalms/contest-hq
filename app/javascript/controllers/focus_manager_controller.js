import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="focus-manager"
export default class extends Controller {
  static targets = ["autofocus", "firstField", "errorField"]
  static values = { 
    delay: { type: Number, default: 100 },
    focusOnConnect: { type: Boolean, default: true },
    returnFocus: String
  }

  connect() {
    if (this.focusOnConnectValue) {
      this.setInitialFocus()
    }
    
    // Store the current focus for potential return
    this.storePreviousFocus()
  }

  disconnect() {
    // Clean up any stored focus references
    this.clearStoredFocus()
  }

  setInitialFocus() {
    // Use a small delay to ensure DOM is fully rendered and Turbo has finished
    setTimeout(() => {
      this.focusFirstAvailableElement()
    }, this.delayValue)
  }

  focusFirstAvailableElement() {
    // Priority order for focus:
    // 1. Element with autofocus target
    // 2. First error field (if any)
    // 3. First designated field
    // 4. First focusable element in the container

    const elementToFocus = this.getElementToFocus()
    
    if (elementToFocus) {
      this.focusElement(elementToFocus)
    }
  }

  getElementToFocus() {
    // Check for autofocus target first
    if (this.hasAutofocusTarget && this.isElementFocusable(this.autofocusTarget)) {
      return this.autofocusTarget
    }

    // Check for error fields
    if (this.hasErrorFieldTarget) {
      const errorField = this.errorFieldTargets.find(field => this.isElementFocusable(field))
      if (errorField) {
        return errorField
      }
    }

    // Check for designated first field
    if (this.hasFirstFieldTarget && this.isElementFocusable(this.firstFieldTarget)) {
      return this.firstFieldTarget
    }

    // Fall back to first focusable element
    return this.getFirstFocusableElement()
  }

  getFirstFocusableElement() {
    const focusableSelectors = [
      'input:not([disabled]):not([type="hidden"])',
      'select:not([disabled])',
      'textarea:not([disabled])',
      'button:not([disabled])',
      'a[href]',
      '[tabindex]:not([tabindex="-1"])'
    ]

    const focusableElements = this.element.querySelectorAll(focusableSelectors.join(', '))
    
    for (const element of focusableElements) {
      if (this.isElementFocusable(element)) {
        return element
      }
    }

    return null
  }

  isElementFocusable(element) {
    if (!element) return false
    
    // Check if element is visible and not disabled
    const style = window.getComputedStyle(element)
    const isVisible = style.display !== 'none' && 
                     style.visibility !== 'hidden' && 
                     element.offsetParent !== null
    
    const isEnabled = !element.disabled && 
                     element.getAttribute('aria-disabled') !== 'true'
    
    return isVisible && isEnabled
  }

  focusElement(element) {
    try {
      element.focus()
      
      // For text inputs, select all text for easier replacement
      if (element.type === 'text' || element.type === 'email' || element.tagName === 'TEXTAREA') {
        element.select()
      }
      
      // Scroll element into view if needed
      element.scrollIntoView({ 
        behavior: 'smooth', 
        block: 'center',
        inline: 'nearest'
      })
      
    } catch (error) {
      console.warn('Failed to focus element:', error)
    }
  }

  storePreviousFocus() {
    const activeElement = document.activeElement
    if (activeElement && activeElement !== document.body) {
      this.previousFocus = activeElement
    }
  }

  clearStoredFocus() {
    this.previousFocus = null
  }

  returnToPreviousFocus() {
    if (this.previousFocus && this.isElementFocusable(this.previousFocus)) {
      this.focusElement(this.previousFocus)
    }
  }

  // Action to manually set focus to a specific target
  focusTarget(event) {
    const targetName = event.params.target
    const target = this[`${targetName}Target`]
    
    if (target && this.isElementFocusable(target)) {
      this.focusElement(target)
    }
  }

  // Action to focus the first field
  focusFirst() {
    this.focusFirstAvailableElement()
  }

  // Action to return focus to previous element
  returnFocus() {
    this.returnToPreviousFocus()
  }
}