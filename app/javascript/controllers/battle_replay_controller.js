import { Controller } from "@hotwired/stimulus"

// Steps through a PokemonBattle event script: sprites, HP bars, callouts; skip / speed; reduced-motion → final state.
export default class extends Controller {
  static targets = [
    "attackerSprite", "defenderSprite", "attackerName", "defenderName",
    "attackerHp", "defenderHp", "attackerMeter", "defenderMeter",
    "attackerRing", "defenderRing",
    "callout", "turn", "round", "play", "speed", "stepBack", "stepForward"
  ]
  static values = { script: Object }

  connect() {
    this.index = 0
    this.speed = 1
    this.playing = false
    this.done = false
    this.pendingTraitCallouts = []
    this.hp = {}
    this.active = { attacker: null, defender: null }
    this.labels = this.scriptValue.labels || {}
    this.fighters = this.scriptValue.fighters || {}
    this.events = this.scriptValue.events || []
    this.useHp = Boolean(this.scriptValue.hp)
    this.syncSpeed()
    this.syncPlayLabel()
    this.syncStepButtons()

    if (this.reducedMotion) {
      this.finish()
      return
    }

    this.resetStage()
  }

  disconnect() {
    this.stopTimer()
  }

  togglePlay(event) {
    event?.preventDefault()
    if (this.done) {
      this.restart()
      return
    }
    this.playing ? this.pause() : this.play()
  }

  skip(event) {
    event?.preventDefault()
    this.finish()
  }

  stepForward(event) {
    event?.preventDefault()
    this.pause()
    if (this.done) return
    if (this.index >= this.events.length) {
      this.finish()
      return
    }

    this.advanceBeat()
    if (this.index >= this.events.length) {
      this.done = true
      this.syncPlayLabel()
    }
    this.syncStepButtons()
  }

  stepBack(event) {
    event?.preventDefault()
    this.pause()
    if (this.index <= 0) return

    this.index = this.previousBeatIndex(this.index)
    this.rebuildTo(this.index)
    this.done = false
    this.syncPlayLabel()
    this.syncStepButtons()
  }

  // One click / tick: traits that arm a hit (or heal) are shown together with that outcome — not as a second strike.
  advanceBeat() {
    if (this.index >= this.events.length) return

    const start = this.events[this.index]
    this.apply(this.events[this.index++])
    if (start.type !== "trait_triggered") return

    while (this.index < this.events.length && this.events[this.index].type === "trait_triggered") {
      this.apply(this.events[this.index++])
    }
    const next = this.events[this.index]
    if (next && (next.type === "hit" || next.type === "healed")) this.apply(this.events[this.index++])
  }

  previousBeatIndex(index) {
    let i = index - 1
    if (i < 0) return 0
    if (this.events[i]?.type === "hit" || this.events[i]?.type === "healed") {
      while (i > 0 && this.events[i - 1].type === "trait_triggered") i -= 1
    } else if (this.events[i]?.type === "trait_triggered") {
      while (i > 0 && this.events[i - 1].type === "trait_triggered") i -= 1
    }
    return i
  }

  cycleSpeed(event) {
    event?.preventDefault()
    this.speed = this.speed === 1 ? 2 : this.speed === 2 ? 4 : 1
    this.syncSpeed()
    if (this.playing) {
      this.stopTimer()
      this.queueNext()
    }
  }

  play() {
    if (this.done) return
    this.playing = true
    this.syncPlayLabel()
    this.queueNext()
  }

  pause() {
    this.playing = false
    this.stopTimer()
    this.syncPlayLabel()
  }

  restart() {
    this.stopTimer()
    this.index = 0
    this.done = false
    this.pendingTraitCallouts = []
    this.hp = {}
    this.active = { attacker: null, defender: null }
    this.resetStage()
    this.play()
  }

  finish() {
    this.stopTimer()
    this.playing = false
    while (this.index < this.events.length) this.advanceBeat()
    this.done = true
    this.syncPlayLabel()
    this.syncStepButtons()
  }

  rebuildTo(count) {
    this.hp = {}
    this.active = { attacker: null, defender: null }
    this.pendingTraitCallouts = []
    this.resetStage()
    for (let i = 0; i < count; i++) this.apply(this.events[i])
  }

  queueNext() {
    if (!this.playing) return
    if (this.index >= this.events.length) {
      this.finish()
      return
    }

    this.advanceBeat()
    this.syncStepButtons()
    this.timer = window.setTimeout(() => this.queueNext(), this.delayFor(this.events[this.index - 1]))
  }

  apply(event) {
    const type = event.type
    const data = event.data || {}

    switch (type) {
      case "round_started":
        this.showRound(event.round)
        this.mountSide("attacker", data.attacker)
        this.mountSide("defender", data.defender)
        this.clearStriker()
        this.clearTurn()
        this.pendingTraitCallouts = []
        this.clearCallout()
        break
      case "trait_triggered": {
        const line = this.traitCallout(data.combatant, data.trait)
        this.pendingTraitCallouts = this.pendingTraitCallouts || []
        this.pendingTraitCallouts.push(line)
        this.showCallout(this.pendingTraitCallouts.filter(Boolean).join(" · "))
        break
      }
      case "hit":
        this.applyHit(data)
        break
      case "healed":
        this.clearStriker()
        this.clearTurn()
        this.setHp(data.combatant, data.hp_left)
        this.showCallout(this.mergeCallout(this.namedLine(this.labels.healed, data.combatant)))
        break
      case "fainted":
        this.clearStriker()
        this.clearTurn()
        this.pendingTraitCallouts = []
        this.setHp(data.combatant, 0)
        this.dimSide(data.side)
        this.showCallout(this.namedLine(this.labels.fainted, data.combatant))
        break
      case "battle_won":
        this.clearStriker()
        this.clearTurn()
        this.pendingTraitCallouts = []
        this.clearCallout()
        break
      default:
        break
    }
  }

  applyHit(data) {
    this.markStriker(data.striker)
    this.showTurn(data.striker)
    this.setHp(data.target, data.hp_left)
    this.showCallout(this.mergeCallout(this.hitCallout(data)))
  }

  mergeCallout(line) {
    const traits = (this.pendingTraitCallouts || []).filter(Boolean)
    this.pendingTraitCallouts = []
    return [...traits, line].filter(Boolean).join(" · ")
  }

  showTurn(id) {
    if (!this.hasTurnTarget) return
    const template = this.labels.striking || "Б’є: %{name}"
    this.turnTarget.textContent = this.namedLine(template, id)
  }

  clearTurn() {
    if (this.hasTurnTarget) this.turnTarget.textContent = ""
  }

  markStriker(id) {
    this.clearStriker()
    const side = this.sideOf(id)
    if (!side) return
    const key = side === "attacker" ? "Attacker" : "Defender"
    if (!this[`has${key}RingTarget`]) return
    this[`${side}RingTarget`].classList.add("ring-brand")
  }

  clearStriker() {
    ;["attacker", "defender"].forEach((side) => {
      const key = side === "attacker" ? "Attacker" : "Defender"
      if (this[`has${key}RingTarget`]) this[`${side}RingTarget`].classList.remove("ring-brand")
    })
  }

  hitCallout(data) {
    if (data.dodged) return this.labels.dodged
    const bits = []
    if (data.crit) bits.push(this.labels.crit)
    if (data.effect === "super") bits.push(this.labels.super)
    if (data.effect === "weak") bits.push(this.labels.weak)
    return bits.filter(Boolean).join(" · ")
  }

  traitCallout(id, trait) {
    const line = this.labels.traitLines && this.labels.traitLines[trait]
    if (line) return this.namedLine(line, id)
    return (this.labels.traits && this.labels.traits[trait]) || trait
  }

  namedLine(template, id) {
    if (!template) return ""
    const name = (this.fighters[String(id)] || {}).name || ""
    return template.replaceAll("%{name}", name)
  }

  mountSide(side, id) {
    this.active[side] = id
    const fighter = this.fighters[String(id)] || {}
    const sprite = this[`${side}SpriteTarget`]
    const name = this[`${side}NameTarget`]

    if (fighter.sprite) {
      sprite.src = fighter.sprite
      sprite.alt = fighter.name || ""
      sprite.hidden = false
    } else {
      sprite.removeAttribute("src")
      sprite.alt = ""
      sprite.hidden = true
    }
    name.textContent = fighter.name || ""
    this.undimSide(side)

    if (this.useHp && fighter.maxHp != null) {
      if (this.hp[id] == null) this.hp[id] = fighter.maxHp
      this.paintHp(side, this.hp[id], fighter.maxHp)
    }
  }

  setHp(id, value) {
    this.hp[id] = value
    const side = this.sideOf(id)
    if (!side || !this.useHp) return
    const fighter = this.fighters[String(id)] || {}
    this.paintHp(side, value, fighter.maxHp)
  }

  paintHp(side, value, max) {
    const key = side === "attacker" ? "Attacker" : "Defender"
    if (!this[`has${key}HpTarget`] || max == null || max <= 0) return
    const pct = Math.max(0, Math.min(100, (Number(value) / Number(max)) * 100))
    this[`${side}HpTarget`].style.width = `${pct}%`
    if (this[`has${key}MeterTarget`]) {
      this[`${side}MeterTarget`].setAttribute("aria-valuenow", String(Math.round(pct)))
    }
  }

  dimSide(side) {
    this[`${side}SpriteTarget`]?.classList.add("opacity-50", "grayscale")
  }

  undimSide(side) {
    this[`${side}SpriteTarget`]?.classList.remove("opacity-50", "grayscale")
  }

  sideOf(id) {
    if (this.active.attacker === id) return "attacker"
    if (this.active.defender === id) return "defender"
    return null
  }

  showRound(number) {
    if (!this.hasRoundTarget) return
    this.roundTarget.textContent = (this.labels.round || "Раунд %{number}").replace("%{number}", String(number))
  }

  showCallout(text) {
    if (!this.hasCalloutTarget) return
    // Keep the middle grid cell in flow even when empty, so the two fighters stay in their columns.
    this.calloutTarget.textContent = text || ""
  }

  clearCallout() {
    this.showCallout("")
  }

  resetStage() {
    ;["attacker", "defender"].forEach((side) => {
      const sprite = this[`${side}SpriteTarget`]
      sprite.removeAttribute("src")
      sprite.alt = ""
      sprite.hidden = true
      this.undimSide(side)
      this[`${side}NameTarget`].textContent = ""
      if (this.useHp) this.paintHp(side, 1, 1)
    })
    this.clearStriker()
    this.clearTurn()
    this.pendingTraitCallouts = []
    this.clearCallout()
    if (this.hasRoundTarget) this.roundTarget.textContent = ""
  }

  delayFor(event) {
    const base = {
      round_started: 700,
      trait_triggered: 550,
      hit: 500,
      healed: 550,
      fainted: 750,
      battle_won: 200,
      round_resolved: 500,
      tired: 400
    }[event.type] || 400
    return base / this.speed
  }

  syncSpeed() {
    if (!this.hasSpeedTarget) return
    this.speedTarget.textContent = `${this.speed}×`
  }

  syncPlayLabel() {
    if (!this.hasPlayTarget) return
    if (this.done) {
      this.playTarget.textContent = this.labels.play
      return
    }
    this.playTarget.textContent = this.playing ? this.labels.pause : this.labels.play
  }

  syncStepButtons() {
    if (this.hasStepBackTarget) this.stepBackTarget.disabled = this.index <= 0
    if (this.hasStepForwardTarget) this.stepForwardTarget.disabled = this.done
  }

  stopTimer() {
    if (this.timer) window.clearTimeout(this.timer)
    this.timer = null
  }

  get reducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
