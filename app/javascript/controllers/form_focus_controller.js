import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="form-focus"
export default class extends Controller {
  static targets = ["field", "submit", "cancel"]
  static values = { 
    skipFirst: { type: Boolean, default: false },
    focusOnError: { type: Boolean, default: false }
  }

  connect() {
    this.setInitialFocus()
    this.setupFormHandlers()
  }

  setInitialFocus() {
    // Small delay to ensure DOM is ready
    setTimeout(() => {
      this.focusFirstField()
    }, 100)
  }

  setupFormHandlers() {
    // Listen for form submission errors
    this.element.addEventListener('turbo:frame-load', this.handleTurboFrameLoad.bind(this))
    
    // Listen for validation errors
    this.element.addEventListener('invalid', this.handleValidationError.bind(this), true)
  }

  focusFirstField() {
    if (this.skipFirstValue) {
      return
    }

    const firstField = this.getFirstFocusableField()
    if (firstField) {
      this.focusElement(firstField)
    }
  }

  getFirstFocusableField() {
    // Check for error fields first if focusOnError is enabled
    if (this.focusOnErrorValue) {
      const errorField = this.findFirstErrorField()
      if (errorField) {
        return errorField
      }
    }

    // Find first focusable field target
    const focusableField = this.fieldTargets.find(field => this.isElementFocusable(field))
    if (focusableField) {
      return focusableField
    }

    // Fall back to any focusable form element
    return this.findFirstFocusableFormElement()
  }

  findFirstErrorField() {
    // Look for fields with error classes or aria-invalid
    const errorSelectors = [
      '.field_with_errors input',
      '.field_with_errors select', 
      '.field_with_errors textarea',
      '[aria-invalid="true"]',
      '.error input',
      '.error select',
      '.error textarea'
    ]

    for (const selector of errorSelectors) {
      const errorField = this.element.querySelector(selector)
      if (errorField && this.isElementFocusable(errorField)) {
        return errorField
      }
    }

    return null
  }

  findFirstFocusableFormElement() {
    const formElements = this.element.querySelectorAll(
      'input:not([type="hidden"]):not([disabled]), select:not([disabled]), textarea:not([disabled])'
    )

    for (const element of formElements) {
      if (this.isElementFocusable(element)) {
        return element
      }
    }

    return null
  }

  isElementFocusable(element) {
    if (!element) return false
    
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
      
      // Select text for text inputs
      if (element.type === 'text' || element.type === 'email' || element.tagName === 'TEXTAREA') {
        element.select()
      }
      
      // Scroll into view
      element.scrollIntoView({ 
        behavior: 'smooth', 
        block: 'center',
        inline: 'nearest'
      })
      
    } catch (error) {
      console.warn('Failed to focus element:', error)
    }
  }

  handleTurboFrameLoad(event) {
    // If the form was reloaded due to errors, focus the first error field
    if (this.focusOnErrorValue) {
      setTimeout(() => {
        const errorField = this.findFirstErrorField()
        if (errorField) {
          this.focusElement(errorField)
        }
      }, 100)
    }
  }

  handleValidationError(event) {
    // Focus the field that failed validation
    if (this.focusOnErrorValue && event.target) {
      setTimeout(() => {
        this.focusElement(event.target)
      }, 50)
    }
  }

  // Action to focus next field in tab order
  focusNext(event) {
    const currentField = event.target
    const allFields = Array.from(this.element.querySelectorAll(
      'input:not([disabled]), select:not([disabled]), textarea:not([disabled]), button:not([disabled])'
    ))
    
    const currentIndex = allFields.indexOf(currentField)
    const nextField = allFields[currentIndex + 1]
    
    if (nextField && this.isElementFocusable(nextField)) {
      this.focusElement(nextField)
    }
  }

  // Action to focus previous field in tab order
  focusPrevious(event) {
    const currentField = event.target
    const allFields = Array.from(this.element.querySelectorAll(
      'input:not([disabled]), select:not([disabled]), textarea:not([disabled]), button:not([disabled])'
    ))
    
    const currentIndex = allFields.indexOf(currentField)
    const previousField = allFields[currentIndex - 1]
    
    if (previousField && this.isElementFocusable(previousField)) {
      this.focusElement(previousField)
    }
  }

  // Action to focus submit button
  focusSubmit() {
    if (this.hasSubmitTarget && this.isElementFocusable(this.submitTarget)) {
      this.focusElement(this.submitTarget)
    }
  }

  // Action to focus cancel button/link
  focusCancel() {
    if (this.hasCancelTarget && this.isElementFocusable(this.cancelTarget)) {
      this.focusElement(this.cancelTarget)
    }
  }
}