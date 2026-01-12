import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "item", "position", "deleteField", "titleField", "composerField", "deletions"]
  static values = { prescribedPosition: Number }

  moveUp(event) {
    event.preventDefault()
    const item = event.target.closest('[data-music-bulk-edit-target="item"]')
    const prev = item.previousElementSibling
    
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
    this.itemTargets.forEach((item, index) => {
      const positionInput = item.querySelector('[data-music-bulk-edit-target="position"]')
      if (positionInput) {
        positionInput.value = index + 1
      }

      const upBtn = item.querySelector('[data-action="music-bulk-edit#moveUp"]')
      const downBtn = item.querySelector('[data-action="music-bulk-edit#moveDown"]')
      if (upBtn) upBtn.disabled = index === 0
      if (downBtn) downBtn.disabled = index === this.itemTargets.length - 1
    })
  }

  markDeleted(event) {
    event.preventDefault()
    const item = event.target.closest('[data-music-bulk-edit-target="item"]')
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
    
    const badge = item.querySelector('.status-badge')
    if (badge) {
      badge.textContent = 'Deleted'
      badge.classList.remove('bg-blue-100', 'text-blue-800')
      badge.classList.add('bg-red-100', 'text-red-800')
    } else {
      const badgeContainer = item.querySelector('.flex.items-center.gap-2')
      if (badgeContainer) {
        const newBadge = document.createElement('span')
        newBadge.className = 'px-2 py-1 text-xs font-medium text-red-800 bg-red-100 rounded status-badge'
        newBadge.textContent = 'Deleted'
        badgeContainer.insertBefore(newBadge, badgeContainer.firstChild)
      }
    }
    
    const idField = item.querySelector('input[name="music_selections[][id]"]')
    if (idField && this.hasDeletionsTarget) {
      const deleteInput = document.createElement('input')
      deleteInput.type = 'hidden'
      deleteInput.name = 'music_selections_to_delete[]'
      deleteInput.value = idField.value
      this.deletionsTarget.appendChild(deleteInput)
    }
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
    
    const badge = item.querySelector('.status-badge')
    if (badge) {
      const isPrescribed = item.dataset.prescribed === 'true'
      if (isPrescribed) {
        badge.textContent = 'Prescribed'
        badge.classList.remove('bg-red-100', 'text-red-800')
        badge.classList.add('bg-blue-100', 'text-blue-800')
      } else {
        badge.remove()
      }
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
      addForm.querySelectorAll('input[type="text"]').forEach(input => input.value = '')
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
    div.className = 'p-4 bg-green-50 rounded-lg border-2 border-green-300'
    div.setAttribute('data-music-bulk-edit-target', 'item')
    div.setAttribute('data-slot-position', position)
    
    div.innerHTML = `
      <div class="flex items-center gap-4">
        <div class="flex flex-col gap-1">
          <button type="button" class="p-1 text-gray-500 hover:text-gray-700 disabled:opacity-30" data-action="music-bulk-edit#moveUp">▲</button>
          <button type="button" class="p-1 text-gray-500 hover:text-gray-700 disabled:opacity-30" data-action="music-bulk-edit#moveDown">▼</button>
        </div>
        
        <input type="hidden" name="music_selections[][position]" value="${position}" data-music-bulk-edit-target="position">
        
        <div class="flex-1 grid grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Title</label>
            <input type="text" name="music_selections[][title]" value="${title}" class="text-field w-full" data-music-bulk-edit-target="titleField">
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Composer</label>
            <input type="text" name="music_selections[][composer]" value="${composer}" class="text-field w-full" data-music-bulk-edit-target="composerField">
          </div>
        </div>
        
        <div class="flex items-center gap-2">
          <span class="px-2 py-1 text-xs font-medium text-green-800 bg-green-100 rounded status-badge">New</span>
          <button type="button" data-action="music-bulk-edit#removeNewItem" class="btn-danger-sm">Remove</button>
        </div>
      </div>
    `
    
    return div
  }

  removeNewItem(event) {
    event.preventDefault()
    const item = event.target.closest('[data-music-bulk-edit-target="item"]')
    const position = item.dataset.slotPosition
    const slotType = position === String(this.prescribedPositionValue) ? 'prescribed' : 'custom'
    
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
