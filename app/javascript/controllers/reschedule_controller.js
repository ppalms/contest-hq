import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["swapSelect"]

  handleSwap(event) {
    const targetEntryId = event.target.value
    if (!targetEntryId) return

    const scheduleId = event.target.dataset.scheduleId
    const entryId = event.target.dataset.entryId
    
    // Reset the select after getting the values
    event.target.value = ""
    
    // Submit the swap request
    const form = document.createElement('form')
    form.method = 'POST'
    form.action = `/schedules/${scheduleId}/contest_entries/${entryId}/swap/${targetEntryId}`
    
    // Add CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]')
    if (csrfToken) {
      const tokenInput = document.createElement('input')
      tokenInput.type = 'hidden'
      tokenInput.name = 'authenticity_token'
      tokenInput.value = csrfToken.getAttribute('content')
      form.appendChild(tokenInput)
    }
    
    document.body.appendChild(form)
    form.submit()
    document.body.removeChild(form)
  }
}