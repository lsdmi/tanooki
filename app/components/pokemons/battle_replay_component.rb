# frozen_string_literal: true

module Pokemons
  # Battle log from a PokemonBattle's stored events. Non-legacy fights use +battle_replay_controller+ (sprites, HP,
  # callouts). A legacy battle has no events: a note and the result only. +folded+ hides the stage until the panel
  # unfolds; the result stays.
  class BattleReplayComponent < ViewComponent::Base
    include SpriteHelper

    SPRITE_RING = 'flex size-14 shrink-0 items-center justify-center rounded-full bg-main ' \
                  'ring-1 ring-inset ring-line sm:size-16'

    def initialize(battle:, folded: false)
      super()
      @battle = battle
      @folded = folded
    end

    private

    attr_reader :battle, :folded

    def script
      @script ||= BattleReplayScript.new(battle, view: helpers)
    end

    def stage_attributes
      data = { controller: 'battle-replay', battle_replay_script_value: script.as_json }
      data.merge!(PanelComponent.open_target) if folded
      attrs = { class: 'flex flex-col gap-3', data: }
      attrs[:hidden] = true if folded
      attrs
    end

    def rounds_count
      @rounds_count ||= battle.events_of(:round_started).size
    end

    def winner_name
      battle.winner.name
    end

    def loser_name
      (battle.attacker_won? ? battle.defender : battle.attacker).name
    end

    def hp_bars? = script.hp_bars?
  end
end
