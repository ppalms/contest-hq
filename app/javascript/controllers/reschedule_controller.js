import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "daySelect",
    "timeSlotSelect", 
    "existingEntryInfo",
    "existingEntryDetails",
    "rescheduleMethodSection",
    "loadingIndicator"
  ]
  
  static values = {
    scheduleId: Number,
    contestEntryId: Number,
    currentTimeSlot: String,
    currentDayId: Number
  }
  
  connect() {
    // Find the submit button created by form_wrapper
    const submitBtn = this.element.querySelector('input[type="submit"]')
    if (submitBtn) {
      this.submitBtn = submitBtn
    }
    
    if (this.daySelectTarget.value) {
      this.dayChanged({ target: this.daySelectTarget })
    }
  }
  
  async dayChanged(event) {
    const dayId = event.target.value
    const selectedTimeSlot = this.timeSlotSelectTarget.dataset.selectedTimeSlot
    
    this.timeSlotSelectTarget.innerHTML = '<option value="">Choose a time slot</option>'
    this.timeSlotSelectTarget.disabled = true
    this.existingEntryInfoTarget.classList.add('hidden')
    this.rescheduleMethodSectionTarget.classList.add('hidden')
    
    this.enableSubmitButton()
    
    if (!dayId) return
    
    this.showLoading()
    
    try {
      const response = await fetch(
        `/schedules/${this.scheduleIdValue}/day_time_slots/${dayId}?contest_entry_id=${this.contestEntryIdValue}`
      )
      const data = await response.json()
      
      data.time_slots.forEach(slot => {
        const option = document.createElement('option')
        option.value = slot.time_value
        
        let displayText = `${slot.display}`
        if (slot.is_current) {
          displayText += ' (Current)'
        } else if (slot.available) {
          displayText += ' (Available)'
        } else {
          displayText += ' (Occupied)'
        }
        
        option.textContent = displayText
        option.dataset.entry = slot.entry ? JSON.stringify(slot.entry) : ''
        option.dataset.available = slot.available
        option.dataset.isCurrent = slot.is_current
        
        if (selectedTimeSlot && slot.time_value === selectedTimeSlot) {
          option.selected = true
        }
        
        this.timeSlotSelectTarget.appendChild(option)
      })
      
      this.timeSlotSelectTarget.disabled = false
      
      if (selectedTimeSlot) {
        this.timeSlotSelectTarget.dispatchEvent(new Event('change'))
      }
    } catch (error) {
      console.error('Error fetching time slots:', error)
      alert('Failed to load time slots. Please try again.')
    } finally {
      this.hideLoading()
    }
  }
  
  timeSlotChanged(event) {
    const selectedOption = event.target.selectedOptions[0]
    
    const isCurrentSlot = selectedOption && selectedOption.dataset.isCurrent === 'true'
    
    if (isCurrentSlot) {
      this.disableSubmitButton()
      this.existingEntryInfoTarget.classList.add('hidden')
      this.rescheduleMethodSectionTarget.classList.add('hidden')
      this.clearRescheduleMethod()
    } else if (selectedOption && selectedOption.dataset.entry) {
      this.enableSubmitButton()
      
      const entry = JSON.parse(selectedOption.dataset.entry)
      this.existingEntryDetailsTarget.innerHTML = `
        <p class="font-semibold">${entry.name}</p>
        <p>${entry.school}</p>
        ${entry.performance_class ? `<p>Class: ${entry.performance_class}</p>` : ''}
        ${entry.preferred_times ? 
          `<p class="mt-2"><strong>Preferred Times:</strong> ${entry.preferred_times}</p>` : 
          '<p class="text-gray-500 mt-2">No time preference specified</p>'}
      `
      this.existingEntryInfoTarget.classList.remove('hidden')
      this.rescheduleMethodSectionTarget.classList.remove('hidden')
      
      const swapRadio = this.element.querySelector('input[value="swap"]')
      if (swapRadio && !this.element.querySelector('input[name="reschedule_method"]:checked')) {
        swapRadio.checked = true
      }
    } else {
      this.enableSubmitButton()
      
      this.existingEntryInfoTarget.classList.add('hidden')
      this.rescheduleMethodSectionTarget.classList.add('hidden')
      this.clearRescheduleMethod()
    }
  }
  
  enableSubmitButton() {
    if (this.submitBtn) {
      this.submitBtn.disabled = false
      this.submitBtn.classList.remove('bg-gray-400', 'cursor-not-allowed')
      this.submitBtn.classList.add('btn-primary-sm')
    }
  }
  
  disableSubmitButton() {
    if (this.submitBtn) {
      this.submitBtn.disabled = true
      this.submitBtn.classList.remove('btn-primary-sm')
      this.submitBtn.classList.add('bg-gray-400', 'cursor-not-allowed')
    }
  }
  
  clearRescheduleMethod() {
    const checkedMethod = this.element.querySelector('input[name="reschedule_method"]:checked')
    if (checkedMethod) {
      checkedMethod.checked = false
    }
  }
  
  showLoading() {
    if (this.hasLoadingIndicatorTarget) {
      this.loadingIndicatorTarget.classList.remove('hidden')
    }
  }
  
  hideLoading() {
    if (this.hasLoadingIndicatorTarget) {
      this.loadingIndicatorTarget.classList.add('hidden')
    }
  }
}
