import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "item", "position", "deleteField", "titleField", "composerField", "deletions"]

  connect() {
    // Initialize button states on page load
    this.updatePositions()
    
    // Disable inputs in hidden add forms to prevent validation
    this.element.querySelectorAll('[data-slot] .add-form.hidden').forEach(addForm => {
      addForm.querySelectorAll('input[type="text"]').forEach(input => {
        input.disabled = true
      })
    })
  }

  moveUp(event) {
    event.preventDefault()
    const item = event.target.closest('[data-music-bulk-edit-target="item"]')
    let prev = item.previousElementSibling
    
    while (prev && prev.hasAttribute('data-slot')) {
      const prevPrev = prev.previousElementSibling
      if (!prevPrev) break
      prev = prevPrev
    }
    
    if (prev && prev.hasAttribute('data-music-bulk-edit-target')) {
      item.parentNode.insertBefore(item, prev)
      this.updatePositions()
    }
  }

  moveDown(event) {
    event.preventDefault()
    const item = event.target.closest('[data-music-bulk-edit-target="item"]')
    let next = item.nextElementSibling
    
    while (next && next.hasAttribute('data-slot')) {
      next = next.nextElementSibling
    }
    
    if (next && next.hasAttribute('data-music-bulk-edit-target')) {
      item.parentNode.insertBefore(next, item)
      this.updatePositions()
    }
  }

  updatePositions() {
    // Query DOM directly to get current order (don't use cached itemTargets)
    const container = this.hasListTarget ? this.listTarget : this.element
    const items = container.querySelectorAll('[data-music-bulk-edit-target="item"]')
    
    items.forEach((item, index) => {
      const positionInput = item.querySelector('[data-music-bulk-edit-target="position"]')
      if (positionInput) {
        positionInput.value = index + 1
      }
      
      // Enable/disable arrow buttons based on position
      const upBtn = item.querySelector('[data-action="music-bulk-edit#moveUp"]')
      const downBtn = item.querySelector('[data-action="music-bulk-edit#moveDown"]')
      if (upBtn) upBtn.disabled = index === 0
      if (downBtn) downBtn.disabled = index === items.length - 1
    })
  }

  markDeleted(event) {
    event.preventDefault()
    const item = event.target.closest('[data-music-bulk-edit-target="item"]')
    const idField = item.querySelector('input[name="music_selections[][id]"]')
    
    // If item has no ID, it's unsaved - just remove it from DOM
    if (!idField || !idField.value) {
      const position = item.dataset.slotPosition
      const slotType = item.dataset.prescribed === 'true' ? 'prescribed' : 'custom'
      
      const placeholder = document.createElement('div')
      placeholder.className = 'mb-4 rounded-lg border-2 border-dashed border-gray-300'
      placeholder.setAttribute('data-slot', '')
      placeholder.setAttribute('data-slot-type', slotType)
      placeholder.setAttribute('data-slot-position', position)
      
      if (slotType === 'prescribed') {
        placeholder.innerHTML = `
          <div class="placeholder p-6 text-center">
            <span class="inline-block mb-2 px-2 py-1 text-xs font-medium text-blue-800 bg-blue-100 rounded">Prescribed</span>
            <p class="text-gray-500 mb-3">Empty slot</p>
            <a href="${this.getPrescribedSelectUrl()}" class="btn-primary-sm" data-turbo-frame="music_slot_prescribed">Select Prescribed Music</a>
          </div>
        `
      } else {
        placeholder.innerHTML = `
          <div class="placeholder p-6 text-center">
            <p class="text-gray-500 mb-3">Empty slot</p>
            <button type="button" data-action="music-bulk-edit#showAddForm" class="btn-primary-sm">Add</button>
          </div>
          <div class="add-form hidden"></div>
        `
      }
      
      item.replaceWith(placeholder)
      this.updatePositions()
      return
    }
    
    // Item has ID - mark for deletion (existing behavior)
    const deleteField = item.querySelector('[data-music-bulk-edit-target="deleteField"]')
    const titleField = item.querySelector('[data-music-bulk-edit-target="titleField"]')
    const composerField = item.querySelector('[data-music-bulk-edit-target="composerField"]')
    
    if (deleteField) {
      deleteField.value = "1"
    }
    
    item.classList.add('bg-gray-100', 'opacity-60')
    
    if (titleField) {
      titleField.readOnly = true
      titleField.classList.add('bg-gray-100', 'cursor-not-allowed')
    }
    if (composerField) {
      composerField.readOnly = true
      composerField.classList.add('bg-gray-100', 'cursor-not-allowed')
    }
    
    const deleteBtn = item.querySelector('.delete-btn')
    const undoBtn = item.querySelector('.undo-btn')
    if (deleteBtn) deleteBtn.classList.add('hidden')
    if (undoBtn) undoBtn.classList.remove('hidden')
    
    // Add "Deleted" badge to top-right badge container
    let badgeContainer = item.querySelector('.absolute.top-4.right-4')
    if (!badgeContainer) {
      // Create badge container if it doesn't exist
      badgeContainer = document.createElement('div')
      badgeContainer.className = 'absolute top-4 right-4 flex flex-row-reverse items-center gap-2'
      item.insertBefore(badgeContainer, item.firstChild)
    }
    
    // Add "Deleted" badge (will appear on the right due to flex-row-reverse)
    const deletedBadge = document.createElement('span')
    deletedBadge.className = 'px-2 py-1 text-xs font-medium text-red-800 bg-red-100 rounded status-badge deleted-badge'
    deletedBadge.textContent = 'Deleted'
    badgeContainer.appendChild(deletedBadge)
    
    if (this.hasDeletionsTarget) {
      const deleteInput = document.createElement('input')
      deleteInput.type = 'hidden'
      deleteInput.name = 'music_selections_to_delete[]'
      deleteInput.value = idField.value
      this.deletionsTarget.appendChild(deleteInput)
    }
  }
  
  getPrescribedSelectUrl() {
    // Extract entry_id from the form action URL
    const form = this.element.querySelector('form')
    if (form) {
      const match = form.action.match(/entries\/(\d+)/)
      if (match) {
        return `/contests/entries/${match[1]}/selections/select_prescribed`
      }
    }
    return '#'
  }

  undoDelete(event) {
    event.preventDefault()
    const item = event.target.closest('[data-music-bulk-edit-target="item"]')
    const deleteField = item.querySelector('[data-music-bulk-edit-target="deleteField"]')
    const titleField = item.querySelector('[data-music-bulk-edit-target="titleField"]')
    const composerField = item.querySelector('[data-music-bulk-edit-target="composerField"]')
    
    if (deleteField) {
      deleteField.value = "0"
    }
    
    item.classList.remove('bg-gray-100', 'opacity-60')
    
    if (titleField) {
      titleField.readOnly = false
      titleField.classList.remove('bg-gray-100', 'cursor-not-allowed')
    }
    if (composerField) {
      composerField.readOnly = false
      composerField.classList.remove('bg-gray-100', 'cursor-not-allowed')
    }
    
    const deleteBtn = item.querySelector('.delete-btn')
    const undoBtn = item.querySelector('.undo-btn')
    if (deleteBtn) deleteBtn.classList.remove('hidden')
    if (undoBtn) undoBtn.classList.add('hidden')
    
    // Remove "Deleted" badge
    const deletedBadge = item.querySelector('.deleted-badge')
    if (deletedBadge) {
      deletedBadge.remove()
    }
    
    const idField = item.querySelector('input[name="music_selections[][id]"]')
    if (idField && this.hasDeletionsTarget) {
      const deleteInputs = this.deletionsTarget.querySelectorAll('input[name="music_selections_to_delete[]"]')
      deleteInputs.forEach(input => {
        if (input.value === idField.value) {
          input.remove()
        }
      })
    }
  }

  showAddForm(event) {
    event.preventDefault()
    const slot = event.target.closest('[data-slot]')
    const placeholder = slot.querySelector('.placeholder')
    const addForm = slot.querySelector('.add-form')
    
    if (placeholder) placeholder.classList.add('hidden')
    if (addForm) {
      addForm.classList.remove('hidden')
      // Enable inputs when showing the form
      addForm.querySelectorAll('input[type="text"]').forEach(input => input.disabled = false)
      const firstInput = addForm.querySelector('input[type="text"]')
      if (firstInput) firstInput.focus()
    }
  }

  cancelAdd(event) {
    event.preventDefault()
    const slot = event.target.closest('[data-slot]')
    const placeholder = slot.querySelector('.placeholder')
    const addForm = slot.querySelector('.add-form')
    
    if (placeholder) placeholder.classList.remove('hidden')
    if (addForm) {
      addForm.classList.add('hidden')
      // Disable inputs when hiding the form to prevent validation
      addForm.querySelectorAll('input[type="text"]').forEach(input => {
        input.value = ''
        input.disabled = true
      })
    }
  }

  confirmAdd(event) {
    event.preventDefault()
    const slot = event.target.closest('[data-slot]')
    const addForm = slot.querySelector('.add-form')
    const titleInput = addForm.querySelector('input[name="music_selections[][title]"]')
    const composerInput = addForm.querySelector('input[name="music_selections[][composer]"]')
    
    if (!titleInput.value || !composerInput.value) {
      alert('Please fill in both title and composer')
      return
    }
    
    const position = slot.dataset.slotPosition
    const newItem = this.createNewItemElement(titleInput.value, composerInput.value, position)
    
    slot.replaceWith(newItem)
    this.updatePositions()
  }

  createNewItemElement(title, composer, position) {
    const div = document.createElement('div')
    div.className = 'relative p-4 bg-green-50 rounded-lg border-2 border-green-300'
    div.setAttribute('data-music-bulk-edit-target', 'item')
    div.setAttribute('data-slot-position', position)
    
    div.innerHTML = `
      <div class="absolute top-4 right-4 flex flex-row-reverse items-center gap-2">
        <span class="px-2 py-1 text-xs font-medium text-green-800 bg-green-100 rounded status-badge">New</span>
      </div>
      
      <div class="space-y-3">
        <div class="flex items-start gap-4">
          <div class="flex flex-col gap-1">
            <button type="button" class="p-1 text-gray-500 hover:text-gray-700 disabled:opacity-30" data-action="music-bulk-edit#moveUp">▲</button>
            <button type="button" class="p-1 text-gray-500 hover:text-gray-700 disabled:opacity-30" data-action="music-bulk-edit#moveDown">▼</button>
          </div>
          
          <input type="hidden" name="music_selections[][position]" value="${position}" data-music-bulk-edit-target="position">
          
          <div class="flex-1 space-y-3 pr-24">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Title</label>
              <input type="text" name="music_selections[][title]" value="${title}" class="text-field w-full" data-music-bulk-edit-target="titleField">
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Composer</label>
              <input type="text" name="music_selections[][composer]" value="${composer}" class="text-field w-full" data-music-bulk-edit-target="composerField">
            </div>
          </div>
          
          <div class="flex items-end gap-2 pt-8">
            <button type="button" data-action="music-bulk-edit#removeNewItem" class="btn-danger-sm">Remove</button>
          </div>
        </div>
      </div>
    `
    
    return div
  }

  removeNewItem(event) {
    event.preventDefault()
    const item = event.target.closest('[data-music-bulk-edit-target="item"]')
    const position = item.dataset.slotPosition
    const slotType = item.dataset.prescribed === 'true' ? 'prescribed' : 'custom'
    
    const placeholder = document.createElement('div')
    placeholder.className = 'rounded-lg border-2 border-dashed border-gray-300'
    placeholder.setAttribute('data-slot', '')
    placeholder.setAttribute('data-slot-type', slotType)
    placeholder.setAttribute('data-slot-position', position)
    
    placeholder.innerHTML = `
      <div class="placeholder p-6 text-center">
        ${slotType === 'prescribed' ? '<span class="inline-block mb-2 px-2 py-1 text-xs font-medium text-blue-800 bg-blue-100 rounded">Prescribed</span>' : ''}
        <p class="text-gray-500 mb-3">Empty slot</p>
        <button type="button" data-action="music-bulk-edit#showAddForm" class="btn-primary-sm">Add</button>
      </div>
      <div class="add-form hidden"></div>
    `
    
    item.replaceWith(placeholder)
    this.updatePositions()
  }

  async saveStateAndNavigate(event) {
    event.preventDefault()
    
    const form = this.element.querySelector('form')
    const formData = new FormData(form)
    
    const saveStateUrl = form.action.replace('bulk_update', 'save_edit_state')
    
    try {
      await fetch(saveStateUrl, {
        method: 'POST',
        body: formData,
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'Accept': 'application/json'
        }
      })
      
      const targetFrame = event.target.dataset.turboFrame
      if (targetFrame && targetFrame !== '_top') {
        Turbo.visit(event.target.href, { frame: targetFrame })
      } else {
        window.location.href = event.target.href
      }
    } catch (error) {
      console.error('Failed to save state:', error)
      const targetFrame = event.target.dataset.turboFrame
      if (targetFrame && targetFrame !== '_top') {
        Turbo.visit(event.target.href, { frame: targetFrame })
      } else {
        window.location.href = event.target.href
      }
    }
  }
}
