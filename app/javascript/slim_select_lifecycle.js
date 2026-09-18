// Shared SlimSelect connect/disconnect for Stimulus + Turbo morph.
// Turbo can morph the <select> and strip SlimSelect chrome without reconnecting Stimulus.

export function connectSlimSelect(controller, createSelect) {
  controller._createSlimSelect = createSelect
  controller._onBeforeMorph = () => destroySlimSelect(controller)
  controller._onMorph = () => initSlimSelect(controller)
  controller._onBeforeCache = () => destroySlimSelect(controller)

  controller.element.addEventListener('turbo:before-morph-element', controller._onBeforeMorph)
  controller.element.addEventListener('turbo:morph-element', controller._onMorph)
  document.addEventListener('turbo:before-cache', controller._onBeforeCache)

  initSlimSelect(controller)
}

export function disconnectSlimSelect(controller) {
  controller.element.removeEventListener('turbo:before-morph-element', controller._onBeforeMorph)
  controller.element.removeEventListener('turbo:morph-element', controller._onMorph)
  document.removeEventListener('turbo:before-cache', controller._onBeforeCache)
  destroySlimSelect(controller)
}

function initSlimSelect(controller) {
  if (!controller.element.isConnected) return

  destroySlimSelect(controller)
  try {
    controller.select = controller._createSlimSelect()
  } catch (_error) {
    controller.select = null
  }
}

function destroySlimSelect(controller) {
  if (!controller.select) return

  try {
    controller.select.destroy()
  } catch (_error) {
    // Morph may already have removed SlimSelect's generated nodes.
  }
  controller.select = null
}
