import { Controller } from "@hotwired/stimulus"

// Attack / defense roster: pick a slot, then a party sprite to fill it. Tap a filled slot to clear.
// Party taps without a focused slot only select details (other Stimulus action).
export default class extends Controller {
  static targets = ["slot", "roleButton", "hint", "partyButton", "sprite"]
  static values = {
    role: { type: String, default: "attack" },
    attackIds: { type: Array, default: [] },
    defenseIds: { type: Array, default: [] },
    size: { type: Number, default: 3 },
    url: String
  }

  connect() {
    this.rosters = {
      attack: this.attackIdsValue.map(Number),
      defense: this.defenseIdsValue.map(Number)
    }
    this.focusedSlot = null
    this.paint()
  }

  switchRole(event) {
    event.preventDefault()
    this.roleValue = event.params.role
    this.focusedSlot = null
    this.paint()
  }

  focusSlot(event) {
    event.preventDefault()
    const index = Number(event.params.index)
    const id = this.currentIds()[index]
    if (id) {
      const list = [...this.currentIds()]
      list.splice(index, 1)
      this.rosters[this.roleValue] = list
      this.focusedSlot = null
      this.paint()
      this.persist()
      return
    }

    this.focusedSlot = index
    this.paint()
  }

  assignPokemon(event) {
    if (this.focusedSlot == null) return

    const id = Number(event.params.id)
    if (!id) return

    const list = [...this.currentIds()]
    const existing = list.indexOf(id)
    if (existing >= 0) list.splice(existing, 1)
    while (list.length < this.focusedSlot) list.push(null)
    list[this.focusedSlot] = id
    this.rosters[this.roleValue] = list.filter(Boolean).slice(0, this.sizeValue)
    this.focusedSlot = null
    this.paint()
    this.persist()
  }

  currentIds() {
    return this.rosters[this.roleValue] || []
  }

  spriteFor(id) {
    return this.spriteTargets.find((img) => Number(img.dataset.pokemonId) === id)
  }

  paint() {
    if (this.hasRoleButtonTarget) {
      this.roleButtonTargets.forEach((button) => {
        const active = button.dataset.pokemonTeamRoleParam === this.roleValue
        button.setAttribute("aria-pressed", active ? "true" : "false")
        button.classList.toggle("text-fg", active)
        button.classList.toggle("text-fg-subtle", !active)
      })
    }

    if (this.hasHintTarget) {
      this.hintTarget.hidden = this.roleValue !== "defense"
    }

    if (this.hasSlotTarget) {
      this.slotTargets.forEach((slot, index) => {
        const id = this.currentIds()[index]
        const filled = Boolean(id)
        const focused = this.focusedSlot === index
        slot.dataset.pokemonId = id || ""
        slot.setAttribute("aria-pressed", focused ? "true" : "false")
        slot.classList.toggle("opacity-40", !filled && !focused)
        slot.classList.toggle("ring-2", focused)
        slot.classList.toggle("ring-brand", focused)
        const img = slot.querySelector("[data-pokemon-team-sprite]")
        const bank = id && this.spriteFor(id)
        if (img && bank) {
          img.src = bank.currentSrc || bank.src
          img.hidden = false
        } else if (img) {
          img.removeAttribute("src")
          img.hidden = true
        }
      })
    }

    if (this.hasPartyButtonTarget) {
      const onTeam = new Set(this.currentIds())
      this.partyButtonTargets.forEach((button) => {
        const id = Number(button.dataset.pokemonTeamIdParam)
        button.classList.toggle("ring-2", onTeam.has(id))
        button.classList.toggle("ring-brand", onTeam.has(id))
      })
    }
  }

  async persist() {
    const token = document.querySelector("meta[name='csrf-token']")?.content
    const body = new FormData()
    body.append("role", this.roleValue)
    this.currentIds().forEach((id) => body.append("user_pokemon_ids[]", id))

    await fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        Accept: "text/vnd.turbo-stream.html",
        ...(token && { "X-CSRF-Token": token })
      },
      body,
      credentials: "same-origin"
    })
  }
}
